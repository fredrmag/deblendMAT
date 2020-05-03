function [DATA1, DATA2, RES, nMaxiter] = Deblend(COPlane,nY,per,ditherArray, dt, sOutY, varargin)
%DEBLEND Deblends one CO plane with two sources with Cadzow and threshold filter in the frequency domain(TFDN). 
%User specification are specified below.
%   [DATA1, DATA2, RES] = Deblend(COPlane,ditherArray, dt, sOutY)
%
%   COPlane:        Input common offset(CO) plane with two blended sources
%   ditherArray:    Array containing all timeshifts for the second
%                   time-configuration.
%   dt:             Sample interval/rate      
%   sOutY:          Y index of first sample. Time-shifting will be
%                   different if we are in the top.
%
%Deblend parameters
%  'Rank', rankType, rankMin, rankMax, rankEvery
%  'Residual', ResChangePer
%  'Threshold', threshold
%  'Median', nXMedian, nYMedian, tFactor
%
%
%   'Rank', rankType, rankMin, rankMax, rankEvery
%      rankType: Following is valid: 'constant', 'incremental', 'cadzowMax'
%            constant:    Rank do not change during iterations. Exit 
%                         strategy is based on the residual change.
%            incremental: Rank changes every "rankEvery" iteration and goes
%                         from rank "rankMin" to "rankMax". Exit happens
%                         when "rankMax" has been reached.
%            cadzowMax:   Rank changes every "rankEvery" iteration and goes
%                         from rank "rankMin" to the maximum rank we have.
%                         Exit happens when maximum rank has been reached.
%      rankMin:   Minimum rank
%      rankMax:   Maximum rank
%      rankEvery: Rank will increment every # iteration.
%
%   'Residual', ResChangePer
%      ResChangePer: Change of residual for exit strategy. Only work
%                    with rankType: 'constant'
%   
%   'Threshold', thresholdPer, thresholdLastIter
%      thresholdPer:        Threshold value start, percentage of total 
%                           amplitude. Set to 80 % by default.
%      thresholdLastIter:   Number of iterations before threshold is zero.
%
%   'Median', nXMedian, nYMedian, tFactor
%   IF NOT SET, ONLY CADZOW WILL RUN. WILL RUN EVERY 4 ITER
%      nXMedian: Number of samples in median calculation. Odd number. [1 #].
%      nYMedian: Length of window which DFT is taken. #Sample. Should
%                correspond to ~500ms. Only the three middle samples will be 
%                kept from this time-window, and then we move the window down 
%                three samples. The window is multiplied with a hann window.
%      tFactor:  If abs(sample) > tFactor*median the value is replaced by the
%                median. Normally set to 3.
%
% Examples:
%   Example 1: Cadzow Only - Constant rank, with exit strategy as residual
%       [DATA1, DATA2, RES] = Deblend(COPlane,ditherArray, dt, sOutY, ...
%                                 'Rank', 'constant', 2,...
%                                 'Residual', 0.01);
%
%
%   Example 2: Cadzow Only - incremental rank every 1 iteration going from
%              rank 1 to 7, exits when max rank has been reached.
%       [DATA1, DATA2, RES] = Deblend(COPlane,ditherArray, dt, sOutY, ...
%                                     'Rank', 'incremental', 1,7,1);
%
%
%   Example 3: Hybrid filter with incremental rank on the cadzow:
%       [DATA1, DATA2, RES] = Deblend(COPlane,ditherArray, dt, sOutY, ...
%                                     'Rank', 'incremental', 1,7,1, ...
%                                     'Median', 5,64,3);
%

%% CHANGELOG
%  14.04.15
%      - Time-shifts whole time-column before estimating each window.
%      - Energy criteria set to primary target.
%  27.01.15
%      - Fixed bug regarding to threshold values.
%  22.01.15
%      - Median filter has been investigated further and now works better
%        for removing blending noise. Now works on DATA again.
%  08.01.15
%      - Threshold start is now operated by percentage of maximum
%        amplitude. By default it is set to 80 percent.
%      - Median filter only operates on estimation
%  16.12.14 - 0.0.2 
%      - Added median filter which operates in frequency domain.
%      - If rank is greater than possible, break.
%      - Added examples to the documentation
%
%  15.12.14 - 0.0.1 
%      - Structered the input/output: vargin
%      - Made documentation header
%
%   FM 2015 - fredrma@gmail.com
   
%% STANDARD PARAMETERS
% If nothing else are specified, the Deblend method are run with these
% parameters.
nMaxiter = 50;

% RANK PARAM
rankType        =   'incremental';
rankEvery       =   1;
rankMin         =   1;
rankMax         =   7;

% RESIDUAL PARAM
ResChangePer    =   0.01;

% This decided the exit criteria
Exit = 'ResChange';

% THRESHOLD PARAM
thresholdPer       =    0; % Percent
thresholdZeroAfter =    4; % iterations

% MEDIAN PARAM
nXMedian        =   5;
nYMedian        =   64;
tFactor         =   2;
runEveryIter    =   nMaxiter; % Will not run if not set by user.

% CHANGE PARAMETERS IF SPECIFIED
c = 1;
if (~isempty(varargin))
    % If input comes from DeblendData then varargin{1} is a cell array
    % containing all the parameters
    if(iscell(varargin{1}))
        varargin = varargin{1};
        n = nargin + length(varargin);
    else
        n = nargin;
    end
    
    while(c <= n-7)
        switch varargin{c}
            case {'Rank'}
                rankType = varargin{c+1};
                % check if rankType is valid:
                if(~strcmp(rankType,'constant') && ...
                   ~strcmp(rankType,'incremental') && ...
                   ~strcmp(rankType,'cadzowMax'))
                    error(['Rank type of "', varargin{c+1}, '" is not valid']);
                end
                rankMin = varargin{c+2};
                % RANK CONSTANT, DONT NEED TO CHANGE
                if(~strcmp(rankType,'constant'))
                    rankMax = varargin{c+3};
                    rankEvery = varargin{c+4};
                    c = c+2;
                end
                c = c+3;
            case {'Residual'}
                ResChangePer = varargin{c+1};
                c = c+2;  
            case {'Threshold'}
                thresholdPer = varargin{c+1};
                thresholdZeroAfter = varargin{c+2};
                if(thresholdPer > 100)
                    error('Threshold is given in percentage of maximum amplitude, should not be higher than 100.')
                end
                c = c+3;
            case {'Median'}
                nXMedian = varargin{c+1};
                nYMedian = varargin{c+2};
                tFactor = varargin{c+3};
                % IF tFactor > 1e3; --> Do not run
                runEveryIter = 6;
                if(tFactor >= 1e3)
                    runEveryIter = nMaxiter;
                end                
                c = c+4;
        otherwise         
            error(['Invalid optional argument, ', ...
                varargin{c}]);
        end % switch
    end % for
end % if


% ALLOCATION OF MEMORY
[nSamples, nShots] = size(COPlane);
EST1 = zeros(size(COPlane));                % Cadzow estimate of shot 1
EST1Out = EST1;
EST2 = EST1;                                % Cadzow estimate of shot 2
EST2Out = EST1; 
DATA1 = EST1;                               % COPlanenservat1ve estimate of shot 1
DATA2 = EST1;                               % COPlanenservat1ve estimate of shot 2
rankMax = ones(nMaxiter,1)*rankMax;
EnRes = zeros(nMaxiter,1);
% End allocation of memory

start = 0;
% Check if we are in top layer, as time-shifting are different
if(sOutY(1,1) == 1)
    start = 1;
end
rank = rankMin;

% set threshold
thresholdStart       =   max(max(abs(COPlane)))*(thresholdPer/100);
threshold = thresholdStart;

perNy = ceil(per*nY);
nCubesY = ceil(nSamples/nY);

%% PROCESSING
% Iterative estimation of a window inside a common offset section.
for i = 1:nMaxiter
    % MEDIAN FILTER in frequency domain will execute WHEN mod(i,runEveryIter) == 0
    % ELSE, normal Cadzow. NO Exit strategy tests are included.
    if(mod(i,runEveryIter) ~= 0)
        
        
        % Estimating energy from source 1 %
        DATA1 = COPlane - timeShiftCO(dt,(ditherArray*-1),nShots,EST2,start);
        for jj = 1:nCubesY
            [iInY,iOutY] = findIndeces( nSamples,nY,perNy,jj );
            [EST1Out(iOutY,:), rankMaxCadzow] = cadzow(DATA1(iOutY,:),rank);
            
            EST1(iInY,:) = EST1Out(iInY,:);
        end
        % Apply thresholding
        EST1 = thresh(EST1, threshold);
        
        % Estimating energy from source 2 %
        COPlane2 = COPlane - EST1;
        DATA2 = timeShiftCO(dt,ditherArray,nShots,(COPlane2),start);
        
        for jj = 1:nCubesY
            [iInY,iOutY] = findIndeces( nSamples,nY,perNy,jj );
            [EST2Out(iOutY,:), rankMaxCadzow] = cadzow(DATA2(iOutY,:),rank);
            
            EST2(iInY,:) = EST2Out(iInY,:);
        end
        % Apply threshold if set
        EST2 = thresh(EST2,threshold);

        % Residual of COPlanenservat1ve est1mate
        RES = COPlane-DATA1-timeShiftCO(dt,(ditherArray*-1),nShots,DATA2,start);
        
        % Calculate l2 norm
        % ll COPlane - (DATA1-T2(DATA2)) ll
        % l2norm = norm(COPlane-(EST1+timeShiftCO(dt,(ditherArray*-1),nShots,EST2,start)));
        
        if(strcmp(rankType, 'cadzowMax'))
            rankMax(i) = rankMaxCadzow;
        end

        %% EXIT STRATEGY
        % Energy criteria of Residual for ending for loop:
        % If percentage of residual change is less than ResChangePer -->
        % break iterative method.
        EnRes(i) = sum(sum(RES.^2));
        %
        if((i > 1 && abs((EnRes(i)-EnRes(i-1))/EnRes(i-1)) < ResChangePer) && (strcmp(rankType, 'constant') || strcmp(Exit, 'ResChange')))
            %disp([num2str(1),': iterations: ' , num2str(i)]);
            %disp('Energy Criteria')
            nMaxiter = i;
            break;
        end
        % If rank equals rank max or cadzowmax(so program will not brake!), --> break, else, update
        % Works for the situations: 'incremental' and 'cadzowMax'
        if((strcmp(rankType, 'incremental') || strcmp(rankType, 'cadzowMax')))
            if((rank == rankMax(i) || rank == rankMaxCadzow))
                %nMaxiter = i;
                if(strcmp(Exit, 'RankStop'))
                    break;
                end
            % IF rank has not exceeded limit, update!
            elseif(mod(i,rankEvery) == 0)
                rank = rank + 1;
            end
        end        
    else
        %% THRESHOLD MEDIAN FILTER TFDN
        DATA1 = COPlane - timeShiftCO(dt,(ditherArray*-1),nShots,EST2,start);
        EST1 = tMedFreq(DATA1,nXMedian,nYMedian,tFactor); 
        % Apply thresholding
        EST1 = thresh(EST1, threshold);

        % Estimating energy from source 2
        COPlane2 = COPlane - EST1;
        DATA2 = timeShiftCO(dt,ditherArray,nShots,(COPlane2),start);
        EST2 = tMedFreq(DATA2,nXMedian,nYMedian,tFactor);
        EST2 = thresh(EST2,threshold);

    end % if median   
    % Update parameters
        % threshold
        threshold = max(0, threshold - ceil(thresholdStart/thresholdZeroAfter));
end % for

end
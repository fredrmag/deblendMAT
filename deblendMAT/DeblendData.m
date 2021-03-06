function [CODeblended1, CODeblended2, avgIterations, ElapsedTime] = DeblendData(filename, varDeblend, varargin)
% DEBLENDDATA Deblends blended seismic data containing 2 sources. Data inputted must be sorted as shot gathers. Results get saved as .sgy and .mat files.
%   [CODeblended1, CODeblended2, avgIterations, ElapsedTime] 
%                                   = DeblendData(filename, varDeblend)
% 
%   Mother file in deblending. This is the function that controls 
%   everything that has to do with deblending 
% 
% ------------------------------------------------------------------------
%                                   INPUT
% ------------------------------------------------------------------------
%   filename:       Path to .sgy file sorted as shotgather to be deblended
%   varDeblend:     Variables related to the deblending --> See deblend.m
%                   header.
% 
% 
% DeblendData parameters
%   'Window', nX, nY, per
%   'FilePathOut', filePath
%   'Description', desc
%   'Flip', flip
%   'LoopingThrough', numberOfCOPlanes
%   'Save', save
%   
% 
%   'Window', nX, nY, per
%      Specicfies the overlappin window size of the calculation
% 
%      nX:      window size in X direction (horizontal)
%      nY:      window size in Y direction (vertical)
%      per:     decides the size of the outer window:
%               [nX-nX*per,nX+nX*per]
%               [nY-nY*per,nY+nY*per]
% 
%   'FilePathOut', filePath
%      filePath: Specifies the filePath where the results are stored.
% 
%   'Description', desc
%      desc:    Description of the run. Is saved in the outputted .txt file
%               generated by saveTXT.m
%   
%   'Flip', flip
%      flip:    boolean value which signals if data are flipped or not. 
%               Is automatically set to 0 if not set.
% 
%   'LoopingThrough', numberOfCOPlanes
%      numberOfCOPlanes: function can process a certain amount of common
%                        offset planes if not desirable to run through 
%                        whole dataset. THIS WILL NOT SAVE ANY DATA
%   'Save', save
%       save: boolean value, if data are going to be saved or not.
% 
% 
% ------------------------------------------------------------------------
%                                   OUTPUT
% ------------------------------------------------------------------------
%   This function will output four files with prefix:
%       filename = filepathOut/[rankMin,rankType,rankEvery,nX,nY,per
%                               ,flip,mute,resChangePer,nShots
%                               ,nTracesShotGatherLoopingThrough,threshold
%                               ,median,nXMedian,nYMedian',tFactor]date
%           filename.txt
%           filename.mat
%           filename_Source1.sgy
%           filename_Source2.sgy
% 
%  Examples:
%   
%       Example 1: Deblend 10 Common offset sections with a Cadzow and
%                  Median filter. Input data are not flipped
%
%           varDeblend = {'Rank', incremental, 3,7,1,...
%                         'Median', 3,64,3,...
%                         'Threshold', 6, 4...};
% 
%           DeblendData( filename, varDeblend,...
%                        'FilePathOut', /results/test_run/,...
%                        'Description', 'Test run on 10 CO planes.', ...
%                        'Window',25,300,0.25,...
%                        'LoopingThrough', 10);
% 
%      Example 2: Deblend full dataset with Cadzow only, without any
%                 threshold applied
%           
%           varDeblend = {'Rank', incremental, 1,7,1,...
%                         'Threshold', 0, 4...};
%            
%           DeblendData( filename, varDeblend...
%                        'FilePathOut', /results/,...
%                        'Description', 'Full run on dataset with Cadzow only', ...
%                        'Window',25,300,0.25);
%
%      Example 3: Deblend full dataset with Cadzow only using, without any
%                 threshold applied
%           
%           varDeblend = {'Rank', constant, 3,...
%                         'Residual', 0.001,... 
%                         'Threshold', 0, 4...};
%            
%           DeblendData( filename, varDeblend...
%                        'FilePathOut', /results/,...
%                        'Description', 'Full run on dataset with Cadzow only', ...
%                        'Window',25,300,0.25);    
%   
% See also DEBLEND

% Changelog
%   28.04.15
%       0.1.1 - User can add a second header file
%   14.04.15
%       0.1.0 - Time-shifting is conducted on whole time-column.
%   18.02.15
%       0.0.5 - Made documentation

% Get SEG-Y HEADER INFO!
[~, nTracesShotGather, nShots, dt, nSamples] = GetSegyHeaderInfo(filename);

% DEFAULT PARAMETERS
MUTE = 0;
flip = 0;
filepathOut = '/';
filename2 = filename;
Bandpass = 0;
fStart = 0;
fEnd = 0;

% Window param
nX = 25;
nY = 2e3/dt; % samples
per = 0.25;

desc = '';
nTracesShotGatherLoopingThrough = nTracesShotGather;

% SaveData = 1 --> Save .mat and .sgy file. IF = 0, dont save.
SaveData = 1;

% Write name : out.mat out_Source1.sgy out_Source2.sgy out.txt
simple = 1;

% CHANGE PARAMETERS IF SPECIFIED
c = 1;
if (~isempty(varargin))
    while(c <= nargin-2)
        switch varargin{c}
            case {'Window'}
                nX = varargin{c+1};
                nY = varargin{c+2};
                per = varargin{c+3};
                c = c+4;
            case {'FilePathOut'}
                filepathOut = varargin{c+1};
                c = c+2;
            case {'Description'}
                desc = varargin{c+1};
                c = c+2;
            case {'Flip'}
                flip = varargin{c+1};
                c = c+2;
            case {'LoopingThrough'}
                nTracesShotGatherLoopingThrough = varargin{c+1};
                c = c+2;  
            case {'Save'}
                SaveData = varargin{c+1};
                c = c+2;
            case {'Filename2'}
                filename2 = varargin{c+1};
                c = c+2;
            case {'Bandpass'}
                Bandpass = 1;
                fStart = varargin{c+1}
                fEnd = varargin{c+2}
                c = c+3;
        % (continued)
        otherwise         
            error(['Invalid optional argument, ', ...
                varargin{c}]);
        end % switch
    end % for
end % if

% PREALLOCATION FOR INFO TO SAVE
CODeblended1 = zeros(nSamples,nShots,nTracesShotGatherLoopingThrough);
CODeblended2 = zeros(nSamples,nShots,nTracesShotGatherLoopingThrough);
RESFinal = CODeblended2;

ditherArray = zeros(1,nShots);
ElapsedTime = zeros(1,nTracesShotGatherLoopingThrough);
avgIterations = zeros(1,nTracesShotGatherLoopingThrough);
PerEnResTotal = avgIterations;

% EnResPerIter = zeros(20,nTracesShotGatherLoopingThrough);
% END ALLOCATE

% CALCULATE muteCurve and extract ditherArray;
% Reads in nShots traces
iFirstShot = (0:nShots-1)*nTracesShotGather + 1;
[~,SegyTraceHeaders] = ReadSegy(filename, 'traces', iFirstShot);

for i = 1:nShots
    % Extract info from header
    ditherArray(i) = SegyTraceHeaders(i).UnassignedInt1;
end

%% PROCESSING
% Run through all Common offset planes:
parfor h = 1:nTracesShotGatherLoopingThrough
    % Start time measurement
    tic;
    %Allocate
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Inner windows
    DATA1 = zeros(nSamples,nShots,1);                           
    DATA2 = DATA1;                                
    RES  = DATA1;
    
    % Outer windows
    DATAOUTER1 = DATA1;
    DATAOUTER2 = DATA1;
    RESOUTER = DATA1;
    
    PerEn1 = 0;
    PerEn2 = 0;
    PerEnRes = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    jShot = (0:nShots-1)*nTracesShotGather + h;
    % Reads in nShots traces
    [Data] = ReadSegy(filename, 'traces', jShot);
    fclose('all'); % add due to bug in readSegy
    
    % If specific frequencies are set, specify it here
    if(Bandpass)
        Data = myFilter(Data,fStart,fEnd,dt*1e-3);
    end
    
    
    CO = Data;
    
    nCubesX = ceil(nShots/nX);
    % Allocate iter
    iterations = zeros(1,nCubesX);

    % Always integer values
    perNx = ceil(per*nX);

    EnTot = sum(sum(CO.^2));

    for i = 1:nCubesX
        disp(['cubeX ', num2str(i),'/',num2str(nCubesX)]);
        [iInX,iOutX] = findIndeces( nShots,nX,perNx,i );
        
        [tmpDATAOUTER1, tmpDATAOUTER2, tmpRESOUTER, iterations(i)] = ...
        Deblend(CO(:,iOutX),nY,per,ditherArray(iOutX), dt, 1,varDeblend);
        
        DATAOUTER1(:,iOutX) = tmpDATAOUTER1;
        DATAOUTER2(:,iOutX) = tmpDATAOUTER2;
        RESOUTER(:,iOutX) = tmpRESOUTER;
        
        % Get inner window from outer window
        DATA1(:,iInX) = DATAOUTER1(:,iInX);
        DATA2(:,iInX) = DATAOUTER2(:,iInX);
        RES(:,iInX)   = RESOUTER(:,iInX);
        
        % Energy calculations
        EnDATA1 = sum(sum(DATA1.^2));
        EnDATA2 = sum(sum(DATA2.^2));
        EnRES = sum(sum(RES.^2));

        PerEn1 = EnDATA1/EnTot*100;
        PerEn2 = EnDATA2/EnTot*100;
        PerEnRes = EnRES/EnTot*100;

        %disp(['Percentage: D_1: ',num2str(PerEn1),'% D_2: ',num2str(PerEn2),'% Res: ',num2str(PerEnRes),'%']);
        %disp(['Total: ',num2str(PerEn1+PerEn2+PerEnRes),'%'])
    end
    disp(['CO offset plane: ',num2str(h),'/',num2str(nTracesShotGatherLoopingThrough)]);
    % Data to be kept and stored in .txt file and as .mat file
    CODeblended1(:,:,h) = DATA1+RES;
    CODeblended2(:,:,h) = DATA2+RES;
    RESFinal(:,:,h)     = RES;
    
    ElapsedTime(h) = toc;
    avgIterations(h) = mean(iterations);
    PerEnSave1(h) = PerEn1;
    PerEnSave2(h) = PerEn2;
    PerEnResSave(h) = PerEnRes;
    PerEnResTotal(h) = PerEn1+PerEn2+PerEnRes;
end

%% SAVE
% Save the data
if(SaveData == 1)
    % Extract parameters from the varDeblend so it can be saved
    nMaxiter = 50;
    % RANK PARAM
    rankType        =   'incremental';
    rankEvery       =   1;
    rankMin         =   1;
    rankMax         =   7;
    thresholdPer       =   0;

    % RESIDUAL PARAM
    resChangePer    =   0.01;

    % MEDIAN PARAM
    nXMedian        =   0;
    nYMedian        =   0;
    tFactor         =   0;
    c = 1;
    while(c <= length(varDeblend))
        switch varDeblend{c}
            case {'Rank'}
                rankType = varDeblend{c+1};
                % check if rankType is valid:
                if(~strcmp(rankType,'constant') && ...
                   ~strcmp(rankType,'incremental') && ...
                   ~strcmp(rankType,'cadzowMax'))
                    error(['Rank type of "', varDeblend{c+1}, '" is not valid']);
                end
                rankMin = varDeblend{c+2};
                % RANK CONSTANT, DONT NEED TO CHANGE
                if(~strcmp(rankType,'constant'))
                    rankMax = varDeblend{c+3};
                    rankEvery = varDeblend{c+4};
                    c = c+2;
                end
                c = c+3;
            case {'Residual'}
                resChangePer = varDeblend{c+1};
                c = c+2;  
            case {'Threshold'}
                thresholdPer = varDeblend{c+1};
                thresholdZeroAfter = varDeblend{c+2};
                if(thresholdPer > 100)
                    error('Threshold is given in percentage of maximum amplitude, should not be higher than 100.')
                end
                c = c+3;
            case {'Median'}
                nXMedian = varDeblend{c+1};
                nYMedian = varDeblend{c+2};
                tFactor = varDeblend{c+3};
                % IF tFactor > 1e3; --> Do not run
                runEveryIter = 4;
                if(tFactor >= 1e3)
                    runEveryIter = nMaxiter;
                end                
                c = c+4;
        otherwise         
            error(['Invalid optional argument, ', ...
                varDeblend{c}]);
        end % switch
    end % for
    
    % Decide in input if output files should have complex names with all
    % parameters used, or if they should be simple with the prefix out
    if(simple)
        writetoname = 'out';
    else
        % Save .mat file with all parameters and output
        writetoname = [filepathOut,'[',num2str(rankMin),',',rankType,', Every',num2str(rankEvery),',',num2str(nX),'x',num2str(nY),',',...
                   num2str(per),',f',num2str(flip),',',num2str(resChangePer),',',num2str(nShots),',',...
                   num2str(nTracesShotGatherLoopingThrough),',thresh',num2str(thresholdPer),',med',num2str(nXMedian),',',num2str(nYMedian),',',num2str(tFactor),']',date,];
    end
    save([writetoname,'.mat'],'nX','nY','per','resChangePer','rankMin','rankMax','rankType','rankEvery','flip','MUTE','CODeblended1','CODeblended2','RESFinal', 'ElapsedTime','avgIterations','PerEnSave1','PerEnSave2','PerEnResSave', 'desc', 'nXMedian', 'nYMedian', 'tFactor');

    % Save to .txt file
    saveTXT(filename, [writetoname, '.txt'], nX,nY,per,rankMin, rankMax, rankType, rankEvery,nXMedian,nYMedian,tFactor, resChangePer,flip,MUTE, nShots, nSamples, nTracesShotGatherLoopingThrough, ElapsedTime, avgIterations, desc, PerEnResTotal);

    % Save to .sgy file
    % Convert from commmon offset to shot domain.
    % Convert to shot domain
    nShots = length(CODeblended1(1,:,1));
    nTraces = length(CODeblended1(:,1,1));
    nShotGather = length(CODeblended1(1,1,:));

    ShotDomain1 = zeros(nTraces,nShotGather,nShots);
    ShotDomain2 = ShotDomain1;

    Shot1 = zeros(nTraces,nShotGather*nShots);
    Shot2 = Shot1;


    for i = 1:length(CODeblended1(1,1,:))
        ShotDomain1(:,i,:) = CODeblended1(:,:,i);
        ShotDomain2(:,i,:) = CODeblended2(:,:,i);
    end

    for i = 1:nShots
        Shot1(:,(i-1)*nShotGather+1:(i*nShotGather)) = ShotDomain1(:,:,i);
        Shot2(:,(i-1)*nShotGather+1:(i*nShotGather)) = ShotDomain2(:,:,i);
        % FLIP THE FLIP for NMO correction.
    end

    % Which SEGY to get header information from
    [~, SegyTraceHeader, SegyHeader] = ReadSegy(filename,'traces',1:nShots*nShotGather);
    
    % Add possibility to write two SEGY headers to the different files.
    % This is important when comparing the unblended stacks with deblended
    % stacks.
    if(strcmp(filename2,filename))
        SegyTraceHeader2 = SegyTraceHeader;
        SegyHeader2 = SegyHeader;
    else
        [~, SegyTraceHeader2, SegyHeader2] = ReadSegy(filename2,'traces',1:nShots*nShotGather);
        
        % Change headers - Add timeshift, number of samples to the headers
        SegyHeader2.ns = SegyHeader.ns;
        for iii = 1:nShots*nShotGather
            SegyTraceHeader2(1,iii).ns = SegyHeader.ns;  
        end
    end

    WriteSegyStructure([writetoname,'_Source1.sgy'], SegyHeader, SegyTraceHeader, Shot1);
    WriteSegyStructure([writetoname,'_Source2.sgy'], SegyHeader2, SegyTraceHeader2, Shot2);
    disp('conversion is done')

    if(flip)
        disp('Writing FLIPPED FOR NMO')
        Shot3 = zeros(nTraces,nShotGather*nShots);

        for i = 1:nShots
            Shot3(:,(i-1)*nTracesShotGather+1:(i*nTracesShotGather)) = fliplr(ShotDomain2(:,:,i));
        end
        WriteSegyStructure([writetoname,'_Source2FLIPPEDFORNMO.sgy'], SegyHeader2, SegyTraceHeader2, Shot3);
    end
end

end


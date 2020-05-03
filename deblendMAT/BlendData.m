function BlendData(filenameIn, filenameOut,SaveEveryNthShot,loopIndeces,flip)
%BLENDDATA Blends every shot with itself 
% BlendData(filenameIn, filenameOut, tShiftArray,SaveEveryNthShot,loopIndeces,flip)
%
% Loops through every shot and blend with itself
% Assigns timeshift (in ms) value in the header value "UnassignedInt1"
%
% filenameIn:           Path to file you want to blend
% filenameOut:          Part of the outputfile:
%                       File output will be on the form filenameOut, num2str(SaveEveryNthShot)*k.segy
%                            where k = 1,2... n
% SaveEveryNthShot:     Save every Nth shot to a SEGY file
% loopIndeces:          Loop through a specific number of shots
% Flip:                 Flip == 1 NOFLIP == 0
%
% Examples:
%
%       Example 1: Blend 1000 shots and save in .sgy files with 50 shots
%                  each. Shots are not flipped.
%       ----------------------------------------------------------------
%       BlendData('data/PlutoOrig.sgy','dataout/PlutOrigBlended',50,1:1000,0);
%           - Loops through the shot nr. 1 to 1000 and the shot records are 
%             not flipped before blending. Saves every 50 shot and will be 
%             on the output: 
%                        dataout/PlutoOrigBlended50.sgy
%                        dataout/PlutoOrigBlended100.sgy 
%                        dataout/PlutoOrigBlended150.sgy
%                                   ...
%                        dataout/PlutoOrigBlended1000.sgy
%
%       Example 2: Save blended into one single file - flipped
%       -----------------------------------------------------------------
%       BlendData('data/PlutoOrig.sgy','dataout/PlutOrigBlended',1126,1:1126,1);
%
%

% Get info from the SegyHeader
[~, nTracesShotGather, nShots, dt, nSamples, SegyHeader] = GetSegyHeaderInfo(filenameIn);

% Create random timeShiftArray
% (min,max,n_backwards,+-M,nShots,dt)

maxTval = 248; % NEEDS TO BE DIVIDABLE BY sampling rate dt

tShiftArray = tShiftArrayMaker(-maxTval,maxTval,5,50,nShots,dt);

% Plot the first shot gather for the timeShiftArray for QC
% figure
% plot(1:nTracesShotGather,tShiftArray(1:nTracesShotGather), '*')

maxShift = maxTval/dt+1;
nSamplesNew = nSamples + maxShift;

% Update SegyHeader
SegyHeader.ns = nSamplesNew;
SegyHeader.ntraces = nTracesShotGather*SaveEveryNthShot;
    
% Allocate memory for data
DataOut = zeros((nSamplesNew),nTracesShotGather*SaveEveryNthShot);

% Allocate SegyHeader struct
[~,SegyTraceHeaders] = ReadSegy(filenameIn, 'traces',1:nTracesShotGather);
fclose('all'); % Add due to bug in ReadSegy

SegyTraceHeadersBlended = SegyTraceHeaders;
SegyTraceHeadersBlended(nTracesShotGather*SaveEveryNthShot).TraceNumber = 1;

disp('Starting to blend data...')

% index that have control over nShots in one SEGY file. Will be set 0 every
% time a SEGY file is saved.
h = 0;

for i = loopIndeces %nShots

    % Read one shot into the memory
    [Data,SegyTraceHeaders] = ReadSegy(filenameIn, 'traces',(1+nTracesShotGather*(i-1)):nTracesShotGather*i);
    fclose('all'); % Add due to bug in ReadSegy
    
    % Assign SegyTraceHeadervalue "UnassignedInt1" with the timeshift in ms
    for j = 1:nTracesShotGather
        SegyTraceHeaders(1,j).UnassignedInt1 = tShiftArray(i);
        SegyTraceHeaders(1,j).ns = nSamplesNew;
    end
    
    SegyTraceHeadersBlended(1,(1+nTracesShotGather*(h)):(nTracesShotGather*(h+1))) = SegyTraceHeaders;

    % nTraces to shift
    nTracesShift = tShiftArray(i)/dt;
    
    % Add maxShift zeros to the data to avoid that it comes to the top
    Data(nSamplesNew,:) = 0;

    % flip or not flip and blend
    if(flip == 1)
        FlippedData = fliplr(Data);
    else
        FlippedData = Data;
    end
    
    % Timeshift FlippedData nTracesShift
    % initialize subscripts
    idx = repmat({':'}, ndims(FlippedData), 1);
    
    % IF positive shift DOWN nTracesShift elements
    % IF negative shift UP nTracesShift elements
    if(nTracesShift > 0)
        % makes a set of indeces to timeshift the data with.
        idx{1} = [nSamplesNew-nTracesShift+1:nSamplesNew 1:nSamplesNew-nTracesShift];
    else
        k = abs(nTracesShift);
        idx{1} = [k+1:nSamplesNew 1:k];
    end
    
    % Timeshift with the indeces made and blend
    TimeShiftData = FlippedData(idx{:});
    
    indexTraces = (1+nTracesShotGather*(h)):(nTracesShotGather*(h+1));
    DataOut(:,indexTraces) = Data + TimeShiftData;
    
    h = h+1;
    % Save every 'saveN' shot
    if(mod(i,SaveEveryNthShot) == 0 )
        filenameWrite = [filenameOut, num2str(i),'.sgy'];
        WriteSegyStructure(filenameWrite,SegyHeader,SegyTraceHeadersBlended,DataOut);
        h = 0;
    end

    if(mod(i,50) == 0)
        disp(['Shot: ', num2str(i)])
    end
end

disp('Finished to blend data')

% Plot two shots for QC
% for u = 1:2
%     figure(u)
%     if(u == 2) u = saveN; end    
%     filename_plot = [filenameOut ,num2str(u), '.sgy'];
%     [Data,SegyTraceHeaders,SegyHeader] = ReadSegy(filename_plot,'traces',1:126); 
%     imagesc(Data,[-100 100])
%     colormap gray
% end

end
function BlendRealData(filenameIn,filenameIn2, filenameOut,flip)
% BLENDREALDATA Blends all the respective shot from two different files. 
% Ouputs a .sgy file with the sgy header of filename2.
% BlendRealData(filenameIn1, filenameIn2, filenameOut,flip)
% 
% Loops through every shot and blends filenameIn with filennameIn2
% Assigns timeshift (in ms) value in the header value "UnassignedInt1"
% 
%       filenameIn1:        Path to file 1 you want to blend in .sgy format
%       filenameIn2:        Path to file 2 you want to blend in .sgy format
%       filenameOut:        Name of the outputted file.  .sgy format
% 
% Example:
%    BlendRealData('IRP152015_s1_c5.sgy','IRP152015_s1_c1.sgy','IRP152015_blendedc1c5.sgy',0);
% 


% Get info from the SegyHeader
[~, nTracesShotGather, nShots, dt, nSamples, SegyHeader] = GetSegyHeaderInfo(filenameIn);

SaveEveryNthShot = nShots;
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
SegyTraceHeadersBlended = SegyTraceHeaders;
SegyTraceHeadersBlended(nTracesShotGather*SaveEveryNthShot).TraceNumber = 1;

disp('Starting to blend data...')

% index that have control over nShots in one SEGY file. Will be set 0 every
% time a SEGY file is saved.
h = 0;

for i = 1:nShots

    % Read one shot into the memory
    [Data,SegyTraceHeaders] = ReadSegy(filenameIn, 'traces',(1+nTracesShotGather*(i-1)):nTracesShotGather*i);
    [DataWide] = ReadSegy(filenameIn2, 'traces',(1+nTracesShotGather*(i-1)):nTracesShotGather*i);
    
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
    DataWide(nSamplesNew,:) = 0;
    Data(nSamplesNew,:) = 0;
    
    % Flip data if specified
     % flip or not flip and blend
    if(flip == 1)
        DataWide = fliplr(DataWide);
    end
    
    % Timeshift Data nTracesShift
    % initialize subscripts
    idx = repmat({':'}, ndims(DataWide), 1);
    
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
    TimeShiftData = DataWide(idx{:});
    
    indexTraces = (1+nTracesShotGather*(h)):(nTracesShotGather*(h+1));
    DataOut(:,indexTraces) = Data + TimeShiftData;
    
    h = h+1;
    % Save every 'saveN' shot
    if(mod(i,SaveEveryNthShot) == 0 )
        filenameWrite = filenameOut;
        WriteSegyStructure(filenameWrite,SegyHeader,SegyTraceHeadersBlended,DataOut);
        h = 0;
    end

    if(mod(i,20) == 0)
        disp(['Shot: ', num2str(i)])
    end
end

disp('Finished to blend data')

%Plot two shots for QC
for u = 1:2
    figure
    [Data] = ReadSegy(filenameOut,'traces',1+nTracesShotGather*(u-1):nTracesShotGather*u); 
    imagesc(Data,[-100 100])
    colormap gray
end

end
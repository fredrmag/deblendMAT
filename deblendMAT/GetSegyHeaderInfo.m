function [nTraces, nTracesShotGather, nShots, dt, nSamples, SegyHeader] = GetSegyHeaderInfo(filename)
%GETSEGYHEADERINFO Get basic information from the SegyHeader in the .sgy file
% [nTraces, nTracesShotGather, nShots, dt, nSamples, SegyHeader] = GetSegyHeaderInfo(filename)

% Read the header file and get parameters
[SegyHeader]=ReadSegyHeader(filename);

% Extract the info needed from the header
nTraces = SegyHeader.ntraces;
nTracesShotGather = SegyHeader.DataTracePerEnsemble;
nSamples = SegyHeader.ns;
dt = SegyHeader.dt/1000; % ms

% Calculate 
nShots = nTraces/nTracesShotGather;

end
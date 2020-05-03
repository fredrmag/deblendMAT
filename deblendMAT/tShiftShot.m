function [ DataOut, idx ] = tShiftShot( DataIn, nTracesShift )
%TSHIFTSHOT [ DataOut ] = tShiftShot( DataIn, nTracesShift )
%   Detailed explanation goes here

% initialize subscripts
idx = repmat({':'}, ndims(DataIn), 1);
nSamples = length(DataIn(:,1));

% IF positive shift UP nTracesShift elements
% IF negative shift DOWN nTracesShift elements
if(nTracesShift > 0)
    % makes a set of indeces to timeshift the data with.
    k = abs(nTracesShift);
    idx{1} = [nSamples-k+1:nSamples 1:nSamples-k];
else
    k = abs(nTracesShift);
    idx{1} = [k+1:nSamples 1:k];
end

DataOut = DataIn(idx{:});
end


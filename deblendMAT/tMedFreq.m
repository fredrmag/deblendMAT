function [ DataOut ] = tMedFreq( DataIn, nXMedian, nYMedian, tFactor )
%TMEDFREQ 1D Filter function that operates with a threshold in the frequency domain. 
%   [DataOut] = tMedFreq(DataIn, nXMedian, nYMedian, tFactor)
%
%   DataIn:   Data to be filtered.
%   nXMedian: Number of samples in median calculation. Odd number. [1 #].
%   nYMedian: Length of window which DFT is taken. #Sample. Should
%             correspond to ~500ms. Only the three middle samples will be 
%             kept from this time-window, and then we move the window down 
%             three samples. The window is multiplied with a hann window.
%   tFactor:  If abs(sample) > tFactor*median the value is replaced by the
%             median. Normally set to 3.
%
%
%Examples:
%      DataOut = tMedFreq(DataIn,5,64,3);
%      DataOut = tMedFreq(DataIn,9,64,5);

%   Changelog:
%       15.12.14: 0.0.1 - Function first created.

% ALGORITHM OVERVIEW
% [0] Calculate how many windows we will use window will go down one sample
% at the time -> Total number of samples - number of samples in one median
% window.
%
% [1] Take out 500 ms of the data for all shots and FFT it
% [2] Slide through 5 traces at the time and replace the value of the
% middle trace with the average median IF it is above the threshold of
% 3*average.
% [3] IFFT back and select the three middle traces - Put them into a new
% matrix.
%
% TODO: Interpolate the sides and the top so we will not have edge problems
%

% Parameter test and change of parameters!
% Make nXMedian an odd number as we would like to have equal amount of
% traces on both sides of the sample we are thresholding.
if(mod(nXMedian,2) == 0)
    msg = sprintf(['nXMedian should be an odd number \n ',...
        'nXMedian = ', num2str(nXMedian), ' overwritten to ', num2str(nXMedian+1)]); 
    disp(msg) 
    nXMedian = nXMedian + 1;
end
% Find closest power of 2 for Y-window as this will go into the fft:
nYWindMedian = 2^(nextpow2(nYMedian));

nXMedianMiddle = ceil(nXMedian/2);
nXMedianPad = nXMedian - nXMedianMiddle;

% Zero pad the data into all directions
% x-direction, Zeropad with nXMedianPad samples
DataIn = [zeros(length(DataIn(:,1)),nXMedianPad), DataIn, zeros(length(DataIn(:,1)),nXMedianPad)];
% y-direction
DataIn = [zeros(nYWindMedian/2+1,length(DataIn(1,:))); DataIn; zeros(nYWindMedian/2+1,length(DataIn(1,:)))];

% WINDOW CALCULATIONS %
% Total-nYMed
nWindows = length(DataIn(:,1))-nYWindMedian;

% Window function
W = hann(nYWindMedian);

% PREALLOCATE
DataOut = zeros(size(DataIn));

for i = 1:3:nWindows
    % [1] Take out 500 ms of the data for all shots and FFT it
    DataInPart = DataIn(i:(nYWindMedian+(i-1)),:);
    % multiply every column with window function
    for q = 1:length(DataInPart(1,:))
        DataInPart(:,q) = DataInPart(:,q).*W;
    end
    
    % thid will only hold the original values
    % is like a look up when calculating the median and get the samples
    DataInPartFFT = fft(DataInPart);
    % this will hold the replaced values aswell as the orignal
    DataInPartFilteredFFT = DataInPartFFT;
    
    % [3] Slide through 5 traces at the time and replace the value of the
    % middle trace with the average median IF it is above the threshold of
    % 3*abs(AOutMedian).
    %
    % N is even, due to nextpow2() function. --> nyquist frequency at N/2+1
    for k = 1:(nYWindMedian/2+1)
        for l = nXMedianMiddle:(length(DataIn(1,:))-nXMedianMiddle)
            % Read 5 traces from the data, AND threshold it!
            
            medianTraces = median(DataInPartFFT(k,l-nXMedianPad:l+nXMedianPad));
            sample = DataInPartFFT(k,l);
            
            if(abs(sample) > tFactor*abs(medianTraces))
                FAC = abs(sample)/abs(medianTraces);
                DataInPartFilteredFFT(k,l) = sample/FAC;
                
                %DataInPartFFT(k,l) = medianTraces;
            end
            
        end    
    end
    
    % Complete the calculation due to symmetry before taking ifft
    % IF N = Even Symmetry: F((N/2+1)+ 1:N,:)) = conj(F(N/2:-1:2,:));
    DataInPartFilteredFFT(nYWindMedian/2+2:nYWindMedian,:) = conj(DataInPartFilteredFFT(nYWindMedian/2:-1:2,:));
    
    % [4] IFFT back and select the three middle traces - Put them into a new
    % matrx.
    AOutPartFiltered = real(ifft(DataInPartFilteredFFT));
    index1 = (floor(nYWindMedian/2)+i-2):(floor(nYWindMedian/2)+i);
    index2 = (floor(nYWindMedian/2)-1):(floor(nYWindMedian/2)+1);
    
    DataOut(index1,:) = AOutPartFiltered(index2,:);
end

% Unpad the zeroes
DataOut = DataOut((nYMedian/2+2):(length(DataOut(:,1))-(nYMedian/2+1)),1+nXMedianPad:length(DataOut(1,:))-nXMedianPad);

end
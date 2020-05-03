function tShiftArray = tShiftArrayMaker(min,max,j,M,nShots,dt)
%TSHIFTARRAYMAKER Constructs a 'random' time shift for every shot
% tShiftArray = tShiftArrayMaker(min,max,j,M,nShots,dt)
%
%   INPUT:
%       min         - minumun timeshift in ms
%       max         - maximum timeshift in ms
%       j           - number of neighbors it should not be close to.
%       M           - 'close' are defined as +-M ms
%       nShots      - number of shots in dataset
%       dt          - sampling rate
%
%   OUTPUT:
%       tShiftArray - array containing nShots timeeshifts with the
%                     following conditions:
%                     1) Is between [-min , max] ms
%                     2) Is be dividable by the sampling rate, dt, in ms
%                     3) Do not have a close value(+-M) to the neighbours
%                        (-j indeces).
%                     4) Should not be zero
% 
if(mod(max,dt) ~= 0)
    error('max timeshift needs to be dividable by dt')
end

tShiftArray = zeros(1,nShots);

% similarity param
similarI = j;
similarN = M;

i = 1;
while i <= nShots
    rNumber = randi([min,max]);
    
    if( (rNumber ~= 0 ) && (mod(rNumber,dt) == 0))
         % Check if random number is a close value to its similarI
         % neighbours.
        if(i > similarI)
            if( ~any( abs(rNumber-tShiftArray(1,(i-similarI):(i-1))) < similarN) )
                tShiftArray(i) = rNumber;
                i = i+1;
            end
        elseif ( i > 1)
             if( ~any( abs(rNumber-tShiftArray) < similarN) )
                tShiftArray(i) = rNumber;
                i = i+1;
             end
        else
            tShiftArray(i) = rNumber;
            i = i+1;
        end
    end
end


end
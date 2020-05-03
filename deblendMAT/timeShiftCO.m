function timeShiftCO1 = timeShiftCO(dt,ditherArray,nShots,CO,start)
%TIMESHIFTCO Time shiftes every trace in a common offset plane with a specified number given in the ditherArray
% timeShiftCO(dt,ditherArray,nShots,CO,start)
% 
%       dt          - sampling rate in ms
%       ditherArray - array containing time-shift in ms for each trace
%       nShots      - number of shots/columns in input common offset plane
%       CO          - 2D matrix containing traces going to be timeshifted
%                     in each column.
%       start       - 1 if we are in the top of the dataset
%                     0 if we are not in the top of the dataset

% TODO: Add examples


ditherArraySamples = ditherArray/dt;

timeShiftCO1 = zeros(size(CO));

for i = 1:nShots
    CO1ROW = CO(:,i);
    % NEEDS TO SHIFT OPPOSITE OF WHAT BlendData DO!
    % IF positive --> shift up
    % IF negative --> shift down
    if(ditherArraySamples(i) < 0)
        k = abs(ditherArraySamples(i));
        timeShiftCO1(:,i) = CO1ROW([ end-k+1:end 1:end-k ]);
        
        if(start)
            timeShiftCO1(1:k,i) = 0;
        end
        
    else % shift up
        k = abs(ditherArraySamples(i));
        timeShiftCO1(:,i) = CO1ROW([ k+1:end 1:k]);
    end
end

end
function T = thresh(B, treshold)
%THRESH Applies a threshold to a 2D matrix
% T = thresh(B, treshold)
T = B;

for i = 1:length(T(:,1))
    for j = 1:length(T(1,:))
        if(abs(T(i,j)) < treshold )
            T(i,j) = 0;
        end
    end
end
end
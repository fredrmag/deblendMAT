function  [x, rankMax] = cadzow(X, rank)
%CADZOW Cadzow filter of a 2D matrix.
%   [x,rankMax] = cadzow(X,rank)
% Takes a 2D matrix X and output a filtered version x
% rank is the desired number of ranks one want to keep
% Also gives maximum rank.

[N,I] = size(X);
% m will be used to construct the hankel matrix
m = floor(0.5*I);

% Initialize variables
Y_filtered = zeros(N,I);

% [1] DFT our data
Y = fft(X);
% [2] For one frequency, pick out the values in the traces
% The frequency spectrum will be symmetric -> conjugate of the half of the
% side. Therefore it can be optimized by only computing the half and add
% the conjugate afterwards.

% Check if data has ODD or EVEN samples
% If N is even --> nyquist frequency at N/2+1, N --> odd, no nyquist
% frequency calculate up to 1:(N+1)/2
if(mod(N,2) == 0) % even
    J = 1:N/2+1; % loop index
    JStartSymmetry = N/2; % symmetry start index
else % odd
    J = 1:(N+1)/2; % loop index
    JStartSymmetry = (N+1)/2; % symmetry start index
end

% For every frequency
for j = J 
    % [3] put it into an hankel matrix 
    H = hankel(Y(j,1:m+1),Y(j,m+1:I));
    % [4] Rank reduce the hankel matrix using SVD
    [U,S,V] = svd(H);
    rankMax = length(S(1,:));
    
    if(mod(I,2) == 0)
        H_reduced = zeros(m+1,m);
    else
        H_reduced = zeros(m+1,m+1);
    end
    if(rank > rankMax)
        disp(['Rank of ',num2str(rank),' is higher than number of singular values ', num2str(rankMax)])
        rank = rankMax;
    end
    
    for k = 1:rank 
        H_reduced = H_reduced + S(k,k)*U(:,k)*V(:,k)';
    end
    % [5] Rebuild the Hankel structure and extract values   
    Y_filtered(j,:) = avgAntiDiag(H_reduced);
    
end
%%% OPTIMASATION %%%%%

% Add the uncomputed part to complete the symmetric part
% Symmetry: complex conjugated of the other one.
% IF N = Even Symmetry: F((N/2+1)+ 1, N) = conj(F(N/2:-1:2));
% IF N = Odd  Symmetry: F((N+1/2)+ 1, N) = conj(F((N+1)/2:-1:2));
% J Translated:         F( J(end)+ 1, N) = conj(F(JStartSymmetry:-1:2))
Y_filtered((J(end)+1):N,:) = conj(Y_filtered(JStartSymmetry:-1:2,:));

% [7] take the ifft of Y2 and get back the filtered signal
X_filtered = ifft(Y_filtered);

x = X_filtered;
end
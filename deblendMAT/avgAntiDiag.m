function V = avgAntiDiag(A)
%AVGANTIDIAG Averages the antidiagonals in a matrix.
% Puts the elements c1, c2 ... cm cm+1 ... cn into the vector V.
%   V = avgAntiDiag(A)
%
%   Relation between V and Hankel matrix, i.e. a matrix where all the
%   anti-diagonals are equal
%   
%        c(1)  c(2)   ...  c(n-m+1)
%   H =  c(2)  c(3)   ...  c(n-m+2)   
%         .     .     ...    .
%        c(m) c(m+1)  ...  c(n)
%
%   V = [c(1) c(2) ... c(m) c(m+1) ... c(n)] 
%
%Example:
%   A =
%
%        1     2     4
%        2     3     4
%        5     6     5
%
%   V = avgAntiDiag(A)
%
%   V =
%
%    1     2     4     5     5
%
%
% FM 2014

[n1,n2] = size(A);

V = zeros(1,n1+n2-1);
% Extract antidiagonals
V(1) = A(1,1);
k = 2;

for i = 2:size(A,2)
   V(k) = mean(diag(fliplr(A(:,1:i))));
   k = k+1;
end

for j = 1:size(A,1)-2
   V(k) = mean(diag(fliplr(A((j+1):end,(j):end))));
   k = k+1;
end
V(k) = A(end,end);
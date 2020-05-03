function [ iIn,iOut ] = findIndeces(nSamples,N,perN,jj )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
startOuterCube = max(1,(jj-1)*N-perN+1);
endOuterCube   = min(jj*N+perN, nSamples);

startInnerCube = max(1,(jj-1)*N+1);
endInnerCube = min(jj*N,nSamples);

iIn = startInnerCube:endInnerCube;
iOut = startOuterCube:endOuterCube;

end


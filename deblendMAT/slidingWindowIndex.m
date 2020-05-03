function [iInX,iInY,iOutX,iOutY] = slidingWindowIndex(nX,perNx,nY,perNy,nSamples,nShots,j,I)
%SLIDINGWINDOWINDEX Calculates the index range of the sliding window
%[iInX,iInY,iOutX,iOutY] = slidingWindowIndex(nX,perNx,nY,perNy,nSamples,nShots,j,I);


% OuterCube
startOuterCubeX = max(1,(j-1)*nX-perNx+1);
endOuterCubeX   = min(j*nX+perNx, nShots);

startOuterCubeY = max(1,(I-1)*nY-perNy+1);
endOuterCubeY   = min(I*nY+perNy, nSamples);

%InnerCube
startInnerCubeX = max(1,(j-1)*nX+1);
endInnerCubeX = min((j)*nX,nShots);

startInnerCubeY = max(1,(I-1)*nY+1);
endInnerCubeY = min(I*nY,nSamples);

iOutX = startOuterCubeX:endOuterCubeX;
iOutY = startOuterCubeY:endOuterCubeY;
iInX = startInnerCubeX:endInnerCubeX;
iInY = startInnerCubeY:endInnerCubeY;

end
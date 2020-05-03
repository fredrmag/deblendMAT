% DEBLEND
%
% Files
%   avgAntiDiag       	- 		Averages the antidiagonals in a matrix.
%   BlendData          	- 		Blends every shot with itself 
%   BlendRealData      	- 		Blends all the respective shot from two different files. 
%   cadzow             	- 		Cadzow filter of a 2D matrix.
%   Deblend            	- 		Deblends one CO plane with two sources with Cadzow and TFDN(optional)
%   DeblendData        	- 		Deblends blended seismic data containing 2 sources. Data inputted must be sorted as shot gathers. 							Results get saved as .sgy and .mat files.
%   findIndeces       	 - 		Find the indeces for the time-sliding window
%   GetSegyHeaderInfo  - 		Get basic information from the SegyHeader in the .sgy file
%   saveTXT            	- 		Saves the parameters and run times to a .txt file 
%   slidingWindowIndex - 		Calculates the index range of the sliding window
%   thresh             		- 		Applies a threshold to a 2D matrix
%   timeShiftCO        	- 		Time shiftes every trace in a common offset plane with a specified number given in the ditherArray
%   tMedFreq           	- 		1D Filter function that operates with a threshold in the frequency domain. 
%   tShiftArrayMaker   	- 		Constructs a 'random' time shift for every shot
%   tShiftShot         	-  		Timeshifts one shot

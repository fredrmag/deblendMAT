function saveTXT(filenameIn, filenameOut, nX,nY,per,rank,rankMax,rank_type,rankEvery,nXMedian,nYMedian,tFactor, resChangePer,flip,MUTE, nShots, nSamples, nTracesShotGatherLoopingThrough, ElapsedTime, avgIterations,desc,PerEnResTotal)
%SAVETXT Saves the parameters and run times to a .txt file 
% saveToTXT(filename, nX,nY,per,rank,rank_type,resChangePer,flip,MUTE, nShots, nSamples, nTracesShotGatherLoopingThrough, ElapsedTime, avgIterations)
% Saves results to txt file

% FM 2014

computername = getenv('computername');

A1 = [1:nTracesShotGatherLoopingThrough; ElapsedTime; avgIterations; PerEnResTotal];
Totaltime = sum(ElapsedTime);

fileID = fopen(filenameOut,'w');
fprintf(fileID,'-------------- HEADER --------------\r\n');
fprintf(fileID,'Date:        %s \r\n', date);
fprintf(fileID,'Matlab ver:  %s \r\n', version);
fprintf(fileID,'Computer:    %s \r\n \r\n', computername);
%fprintf(fileID,'Deblend ver: %s \r\n \r\n', num2str(deblendVer));
fprintf(fileID,'%s \r\n', desc);
fprintf(fileID,'-------------------------------------\r\n \r\n');
fprintf(fileID,'--------- START PARAMETERS ---------- \r\n');
fprintf(fileID,'filenameInput:     %s \r\n \r\n', filenameIn);
fprintf(fileID,'Inner window size: %i x %i \r\n',nX,nY);
fprintf(fileID,'Outer window size: %4.3f bigger \r\n \r\n', per);
fprintf(fileID,'Rank start:        %i; End: %i; Type: %s  Every %i; iteration \r\n \r\n',rank,rankMax,rank_type,rankEvery);
fprintf(fileID,'Median:            nXMed: %i; nYMed: %i; tFactor: %i \r\n \r\n',nXMedian,nYMedian,tFactor);
fprintf(fileID,'Percentage change: %3.2f \r\n',resChangePer);
fprintf(fileID,'Data is flipped:   %i \r\n',flip);
fprintf(fileID,'Data is muted:     %i \r\n',MUTE);
fprintf(fileID,'-------------------------------------\r\n \r\n');
fprintf(fileID,'------------ RUN TIMES -------------- \r\n');
fprintf(fileID,'nShots:                %i \r\n', nShots);
fprintf(fileID,'nSamples:              %i \r\n', nSamples);
fprintf(fileID,'nTracesShotGathers:    %i \r\n \r\n', nTracesShotGatherLoopingThrough);
fprintf(fileID,'CO | Comp time[s] | Avg. iter. per window | Total Energy \r\n');
fprintf(fileID,'%i    %10.4f        ~%4.2f              %5.2f \r\n',A1);
fprintf(fileID,'-------------------------------------\r\n');
fprintf(fileID,'Total:%10.4f s \r\n',Totaltime);
fprintf(fileID,'-------------------------------------\r\n \r\n');
fprintf(fileID,'-------- NAME OF .MAT FILE ---------- \r\n');
fprintf(fileID,'%s.mat \r\n',filenameOut(1:end-4));
fprintf(fileID,'-------------------------------------\r\n \r\n');
fclose(fileID);
end
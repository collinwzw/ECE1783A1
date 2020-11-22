function writeEntropyToTxt(inputEntropy,OutputLocEntropyFN)%,OutputLocPredictionFN)
fid = fopen(OutputLocEntropyFN, 'w');
fwrite(fid,inputEntropy.OutputBitstream); 
fclose(fid); 
% fid = fopen(OutputLocPredictionFN, 'w');
% fwrite(fid,inputEntropy.predictionVideo); 
% fclose(fid); 
end
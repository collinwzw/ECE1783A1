function writeEntropyToTxt(inputEntropy,OutputLocEntropyFN,OutputLocPredictionFN)
fid = fopen(OutputLocEntropyFN, 'w');
fwrite(fid,inputEntropy.entropyVideo); 
fclose(fid); 
fid = fopen(OutputLocPredictionFN, 'w');
fwrite(fid,inputEntropy.predictionVideo); 
fclose(fid); 
end
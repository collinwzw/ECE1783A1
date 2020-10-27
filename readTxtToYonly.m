function YOnlyR=readTxtToYonly(inputFilename,width,height)
    fid=fopen(inputFilename,'r');
             if (fid < 0) 
                error('Could not open the file!');
             end
    YOnlyR=YOnlyVideo(inputFilename,width,height);        
    fclose(fid);
end
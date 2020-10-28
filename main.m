systemSetUp();
% inputFilename = '.\data\akiyo_cif.yuv';
% outputFilename = '.\data\akiyoY_cif.yuv';
% v1 = YUVVideo(inputFilename, 352, 288, 420);
% y_only = true;
% v1.writeToFile(outputFilename, y_only);

matrix = [[-31,9,8,4];[-4,1,4,0];[-3,2,4,0];[4,0,-4,0]];
e = EntropyEngine(matrix,4,4);
e = e.encodeExpGolomblist();
bits = e.bitstream;
%try to write bit by bit into a file.

fid = fopen('.\output\Encodedfile.txt', 'w');
fwrite(fid,bits); 
fclose(fid); 
%read the bits files and put it into a varilable for decode
fid = fopen('.\output\Encodedfile.txt', 'r');
a=fread(fid,'*char');
a=transpose(a);
fclose(fid); 

index = 1;
list = [];
while index <= size(e.bitstream,2)
    [value, index] = dec_golomb(index,a);
    list = [list,value];
    
end
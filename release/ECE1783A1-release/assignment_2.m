clc; 
clear; 
close all;
% Set the video information
videoSequence = 'Z:\Semester 3\Design tradeoff\akiyo_cif.yuv';
width  = 352;
height = 288;
nFrame = 300;
% Read the video sequence
[Y,U,V] = yuvRead(videoSequence, width, height ,nFrame);
%blocksize
%size=2;
%size=8;
size=64;

[Y_New,average_block]=block_creation(width,height,Y,size);
filename="yuv_2a.yuv";
fid=fopen(filename,'w');
if (fid < 0) 
    error('Could not open the file!');
end
for i=1:1:300
    fwrite(fid,uint8(Y_New(:,:,i)),'uchar');
end
fclose(fid);

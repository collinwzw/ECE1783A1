clc; 
clear; 
close all;

% Set the video information
videoSequence = 'C:\Users\Administrator\Desktop\ба1\1783\Ece1783 Project 1\akiyo_cif.yuv';
width  = 352;
height = 288;
nFrame = 300;

% Read the video sequence
[Y,U,V] = yuvRead(videoSequence, width, height ,nFrame);

%Perform UpSampling
[Y1,U1,V1]=UpSampling(Y,U,V,2);


%Testing:
filename="yuv_image2.yuv";
fid=fopen(filename,'w');
if (fid < 0) 
    error('Could not open the file!');
end
 for i=1:300
    fwrite(fid,uint8(Y(:,:,i)),'uchar');
% fwrite(fid,Y(:,:,2));
    fwrite(fid,uint8(U1(:,:,i)),'uchar');
    fwrite(fid,uint8(V1(:,:,i)),'uchar');
 end
fclose(fid);
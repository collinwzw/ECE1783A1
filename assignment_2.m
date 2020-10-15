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

%%
%Taking i value as 8
Y_block8(1:8,1:8)=0;
for k=1:1:300
    for i=1:8:288
        for j=1:8:352
            Y_block8=Y(i:i+7,j:j+7,k);
            mean_value=round(mean(Y_block8,'all'));
            av_Y_8(i:i+7,j:j+7,k)=mean_value;
        end
    end
end

%%
%taking i value as 2
Y_block2(1:2,1:2)=0;
for k=1:1:300
    for i=1:2:288
        for j=1:2:352
            Y_block2=Y(i:i+1,j:j+1,k);
            mean_value=round(mean(Y_block2,'all'));
            av_Y_2(i:i+1,j:j+1,k)=mean_value;
        end
    end
end
%%
%Taking i value as 64
%padding 16 '127' values to row and 16 '127' values to col
Y_New=Y;
Y_New(353:384,289:320,:)=uint8(127);
Y_New(:,289:320,:)=uint8(127);
Y_New(353:384,:,:)=uint8(127);
filename="yuv_2a.yuv";
fid=fopen(filename,'w');
if (fid < 0) 
    error('Could not open the file!');
end
for i=1:1:300
    fwrite(fid,uint8(Y_New(:,:,i)),'uchar');
end
fclose(fid);
%%
for k=1:1:300
    for i=1:64:320
        for j=1:64:384
            Y_block2=Y(i:i+1,j:j+1,k);
            mean_value=round(mean(Y_block2,'all')); 
            av_Y_64(i:i+1,j:j+1,k)=mean_value;
        end
    end
end

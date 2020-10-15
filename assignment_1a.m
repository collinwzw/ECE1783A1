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
l=1;
m=1;
for k=1:1:300
    l=1;
    for i=1:1:176
        m=1;
        for j=1:1:144
            U_new(l,m,k)=U(i,j,k);
            U_new(l+1,m,k)=U(i,j,k);
            U_new(l,m+1,k)=U(i,j,k);
            U_new(l+1,m+1,k)=U(i,j,k);
            m=m+2;
        end
        l=l+2;
    end
       
end
a=1;
b=1;

for k=1:1:300
    a=1;
    for i=1:1:176
        b=1;
        for j=1:1:144
            V_new(a,b,k)=V(i,j,k);
            V_new(a+1,b,k)=V(i,j,k);
            V_new(a,b+1,k)=V(i,j,k);
            V_new(a+1,b+1,k)=V(i,j,k);
            b=b+2;
        end
        a=a+2;
    end
       
end
% Show sample frames
figure;
c = 0;  % counter
for iFrame = 25:25:300
    c = c + 1;
    subplot(4,5,c);
    imshow(Y(:,:,iFrame)); 
    title(['frame #', num2str(iFrame)]);
end
% filename1="U_full.txt";
% filename2="V_full.txt";
% filename3="Y_full.txt";
% writematrix(U_new,filename1);
% writematrix(V_new,filename2);
% writematrix(Y,filename3);
%%
filename="yuv_image1.yuv";
fid=fopen(filename,'w');
if (fid < 0) 
    error('Could not open the file!');
end
 for i=1:300
    fwrite(fid,uint8(Y(:,:,i)),'uchar');
% fwrite(fid,Y(:,:,2));
    fwrite(fid,uint8(U_new(:,:,i)),'uchar');
    fwrite(fid,uint8(V_new(:,:,i)),'uchar');
 end
fclose(fid);
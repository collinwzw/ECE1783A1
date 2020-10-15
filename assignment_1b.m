clc;
close all;
%clear all;
mult=[1.164 0 1.596
      1.164 -0.392 -0.813
      1.164 2.017 0];

for k=1:1:300
    for i=1:1:352
        for j=1:1:288
            n=[double(Y(i,j,k))-16;double(U_new(i,j,k))-128;double(V_new(i,j,k))-128];
            b=Y(i,j,k)-16;
            a=mult*n;
            R(i,j)=a(1);
            G(i,j)=a(2);
            B(i,j)=a(3);
        end
    end
    im(:,:,1)=R(:,:)';
    im(:,:,2)=G(:,:)';
    im(:,:,3)=B(:,:)';
    Image=uint8(im);
    imwrite(uint8(im),['Z:\Semester 3\Design tradeoff\Assignment1\Images_1b\rgb_image' int2str(k), '.png']);
end
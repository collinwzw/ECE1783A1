clc;
close all;
clear all;

% Set the video information
videoSequence = 'C:\Users\Administrator\Desktop\ба1\1783\Ece1783 Project 1\akiyo_cif.yuv';
width  = 352;
height = 288;
nFrame = 300;

% Read the video sequence
[Y,U,V] = yuvRead(videoSequence, width, height ,nFrame);

%Perform UpSampling
[Y1,U1,V1]=UpSampling(Y,U,V,2);

%Given Csc Formula has two parts of coeffient
mult1=[1.164 0 1.596
      1.164 -0.392 -0.813
      1.164 2.017 0];
mult2=[16
      128
      128];

OutputImageAddress='C:\Users\Administrator\Desktop\ба1\1783\Ece1783 Project 1\Images_1b\rgb_image'  

[R,G,B]=YUV_RGB_CSC(mult1,mult2,Y1,U1,V1,OutputImageAddress);


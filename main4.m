clc;
clear all;

systemSetUp();
inputFilename = '.\data\akiyo_cif.yuv';
outputFilename = '.\data\akiyoY_cif.yuv';
v1 = YUVVideo(inputFilename, 352, 288 , 420);
y_only = true;
v1.writeToFile(outputFilename, y_only);

inputFilename = '.\data\akiyoY_cif.yuv';
v1 = YOnlyVideo(inputFilename, 352, 288);
block_width = 8;
block_height = block_width;
% [v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

%I frame is 1
%P frame is 0


%parameter section
r = 1;
n = 3;
QP = 3;
I_Period = 10;
% video_width = 16;
% video_height = 24;
% v1.Y = v1.Y(1:video_height, 1:video_width);
e = Encoder(v1,block_width, block_height,r ,n, QP, I_Period);

% d = ReverseEntropyEngine(e.entropyVideo,block_width,block_height,video_width,video_height);
d = ReverseEntropyEngine(e.entropyVideo,block_width,block_height,v1.height, v1.width);

rescaledFrame = RescalingEngine(d.quantizedTransformedFrame,block_width, block_height, QP ).rescalingResult;
rescaledFrame = idct2(rescaledFrame);

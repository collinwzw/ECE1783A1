clc;
clear all;

systemSetUp();
inputFilename = 'C:\Users\Administrator\Desktop\ба1\1783\ECE1783A1\akiyo_cif.yuv';
outputFilename = 'C:\Users\Administrator\Desktop\ба1\1783\ECE1783A1\akiyoY_cif.yuv';
v1 = YUVVideo(inputFilename, 352, 288 , 420);
y_only = true;
v1.writeToFile(outputFilename, y_only);

inputFilename = 'C:\Users\Administrator\Desktop\ба1\1783\ECE1783A1\akiyoY_cif.yuv';
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
writeEntropyToTxt(e,'.\output\entropyVideo.txt','.\output\predictionVideo.txt');

fid = fopen('.\output\entropyVideo.txt', 'r');
entropyVideo=fread(fid,'*char');
entropyVideo=transpose(entropyVideo);
fclose(fid); 
fid = fopen('.\output\predictionVideo.txt', 'r');
predictionVideo=fread(fid,'*char');
predictionVideo=transpose(predictionVideo);
fclose(fid); 
% 
% 
dT = ReverseEntropyEngine(entropyVideo,block_width,block_height,v1.height, v1.width,QP);
% 
% 
 dB = ReverseEntropyPredictionInfoEngine(predictionVideo,block_width,block_height,v1.height, v1.width);
 d = MotionCompensationEngine(dT.residualVideo,dB.motionvector,dB.frameType,block_width, block_height,size(dT.residualVideo,1),size(dT.residualVideo,2),dB.motionvector_width,dB.motionvector_height,size(dT.residualVideo,3));

                subplot(2,5,1), imshow(uint8(d.Temp_v.Y(:,:,1)))
                subplot(2,5,2), imshow(uint8(d.Temp_v.Y(:,:,2)))
                subplot(2,5,3), imshow(uint8(d.Temp_v.Y(:,:,3)))
                subplot(2,5,4), imshow(uint8(d.Temp_v.Y(:,:,4)))
                subplot(2,5,5), imshow(uint8(d.Temp_v.Y(:,:,5))) 
                subplot(2,5,6), imshow(uint8(d.Temp_v.Y(:,:,7)))
                subplot(2,5,7), imshow(uint8(d.Temp_v.Y(:,:,8)))
                subplot(2,5,8), imshow(uint8(d.Temp_v.Y(:,:,9)))
                subplot(2,5,9), imshow(uint8(d.Temp_v.Y(:,:,10)))
                subplot(2,5,10), imshow(uint8(d.Temp_v.Y(:,:,11))) 
 
 % outputDecodeRefFilename = '.\output\akiyoYDecodedRefPart4.yuv';
% DecodedRefVideo = d.getDecodedRefVideo();
% DecodedRefVideo.writeToFile(outputDecodeRefFilename);


%d = ReverseEntropyEngine(e.entropyVideo,block_width,block_height,video_width,video_height);dT = ReverseEntropyEngine(e.entropyVideo,block_width,block_height,v1.height, v1.width);
% 
% rescaledFrame = RescalingEngine(d.quantizedTransformedFrame,block_width, block_height, QP ).rescalingResult;
% rescaledFrame = idct2(rescaledFrame);


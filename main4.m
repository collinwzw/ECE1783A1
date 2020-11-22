clc;
clear all;
systemSetUp();

tic
inputFilename = '.\data\foreman_cif.yuv';
outputFilename = '.\data\foremanY_cif.yuv';
v1 = YUVVideo(inputFilename, 352, 288 , 420);
y_only = true;
v1.writeToFile(outputFilename, y_only);

inputFilename = '.\data\foremanY_cif.yuv';
v1 = YOnlyVideo(inputFilename, 352, 288);




%I frame is 1
%P frame is 0

% %parameter section
block_width = 16;
block_height = block_width;
r = 2;
n = 3;
QP = 4;
I_Period = 8;
nRefFrame = 1;
FEMEnable = false;
FastME = false;
VBSEnable = true;
% 
%pad the video if necessary
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

%encode the video
e = Encoder(v1WithPadding,block_width, block_height,r ,n, QP, I_Period,nRefFrame, FEMEnable, FastME, VBSEnable);

c=ReverseEntropyEngine_Block(e.OutputBitstream,block_width,block_height,288,352);
BlockList = c.BlockList;
d=MotionCompensationEngine_Block(BlockList,block_width,block_height,288,352);
% 
% %write the residual bitstream and prediction info bitstream to file
% writeEntropyToTxt(e,'.\output\entropyVideo.txt','.\output\predictionVideo.txt');
% 
% %read the residual bitstream and prediction info bitstream from file
% fid = fopen('.\output\entropyVideo.txt', 'r');
% entropyVideo=fread(fid,'*char');
% entropyVideo=transpose(entropyVideo);
% fclose(fid); 
% 
% fid = fopen('.\output\predictionVideo.txt', 'r');
% predictionVideo=fread(fid,'*char');
% predictionVideo=transpose(predictionVideo);
% fclose(fid); 
%  
%  
% % reverse the residual data back to residual video
% dT = ReverseEntropyEngine(entropyVideo,block_width,block_height,v1.height, v1.width,QP);
% 
% % reverse the prediction info back to prediction video
% dB = ReverseEntropyPredictionInfoEngine(predictionVideo,block_width,block_height,v1.height, v1.width);
% 
% %combine the decoded resudual data and prediction infomation, generate
% %decoded video.
% d = MotionCompensationEngine(dT.residualVideo,dB.motionvector,dB.frameType,block_width, block_height,size(dT.residualVideo,1),size(dT.residualVideo,2),dB.motionvector_width,dB.motionvector_height,size(dT.residualVideo,3));
% 
% %                 subplot(2,5,1), imshow(uint8(d.Temp_v.Y(:,:,1)))
% %                 subplot(2,5,2), imshow(uint8(d.Temp_v.Y(:,:,2)))
% %                 subplot(2,5,3), imshow(uint8(d.Temp_v.Y(:,:,3)))
% %                 subplot(2,5,4), imshow(uint8(d.Temp_v.Y(:,:,4)))
% %                 subplot(2,5,5), imshow(uint8(d.Temp_v.Y(:,:,5))) 
% %                 subplot(2,5,6), imshow(uint8(d.Temp_v.Y(:,:,7)))
% %                 subplot(2,5,7), imshow(uint8(d.Temp_v.Y(:,:,8)))
% %                 subplot(2,5,8), imshow(uint8(d.Temp_v.Y(:,:,9)))
% %                 subplot(2,5,9), imshow(uint8(d.Temp_v.Y(:,:,10)))
% %                 subplot(2,5,10), imshow(uint8(d.Temp_v.Y(:,:,11))) 
%  
% outputDecodeRefFilename = '.\output\foremanY_cif.yuv';
% DecodedRefVideo = d.getDecodedRefVideo();
% DecodedRefVideo.writeToFile(outputDecodeRefFilename);
% 
% toc 
% acc_PSNR = 0;
% for k=1:1:10
%     acc_PSNR = acc_PSNR + psnr(DecodedRefVideo.Y(:,:,k),double(v1WithPadding.Y(:,:,k)));
% end
% 
% 
% totalBit = size(e.entropyVideo) + size(e.predictionVideo);
% fprintf(" configuration: i = %d, r = %d, QP = %d, IP = %d \n",block_width, r, QP, I_Period);
% fprintf(" PSNR = %d \n",acc_PSNR );
% fprintf(" number of bits for 10 frame = %d \n",totalBit );
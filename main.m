
% inputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyo_cif.yuv';
% outputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyoY_cif.yuv';
% v1 = YUVVideo(inputFilename, 352, 288, 420);
% y_only = true;
% v1.writeToFile(outputFilename, y_only);

inputFilename = 'C:\Users\Administrator\Desktop\ба1\1783\ECE1783A1\akiyoY_cif.yuv';


v1 = YOnlyVideo(inputFilename, 352, 288);
block_width = 8;
block_height = block_width;
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

m =  MotionEstimationVideo(v1WithPadding, 1, block_width, block_height,2)


% firstReferenceFrame(1:352,1:288) = uint8(127);
% %b = Block(v1.Y(:,:,1), 9,9, block_width, block_height, MotionVector(0,0));
% m = MotionEstimationFrames(1,v1WithPadding.Y(:,:,1), firstReferenceFrame, block_width, block_height);
% m = m.truncateBlock();
% secondReferenceFrame = m.residualFrame + m.predictedFrame
% m = MotionEstimationFrames(1,v1WithPadding.Y(:,:,2), secondReferenceFrame, block_width, block_height);
% m = m.truncateBlock();
% outputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyoYPadded_cif.yuv';
% v1WithPadding.writeToFile(outputFilename);
% outputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyoYAveraged_cif.yuv';
% v1Averaged.writeToFile(outputFilename);
%fprintf("%d\n",v2.width)
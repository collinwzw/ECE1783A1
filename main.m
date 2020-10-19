
% inputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyo_cif.yuv';
% outputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyoY_cif.yuv';
% v1 = YUVVideo(inputFilename, 352, 288, 420);
% y_only = true;
% v1.writeToFile(outputFilename, y_only);
% 
inputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyoY_cif.yuv';
v1 = YOnlyVideo(inputFilename, 352, 288);
block_width = 4;
block_height = block_width;
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height)
firstReferenceFrame(1:352,1:288) = uint8(127);
m = MotionEstimationFrames(1,v1WithPadding.Y(:,:,1), firstReferenceFrame, block_width, block_height);
m = m.truncateBlock()
% outputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyoYPadded_cif.yuv';
% v1WithPadding.writeToFile(outputFilename);
% outputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\akiyoYAveraged_cif.yuv';
% v1Averaged.writeToFile(outputFilename);
%fprintf("%d\n",v2.width)
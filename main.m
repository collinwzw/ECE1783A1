
% inputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\data\akiyo_cif.yuv';
% outputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\data\akiyoY_cif.yuv';
% v1 = YUVVideo(inputFilename, 352, 288, 420);
% y_only = true;
% v1.writeToFile(outputFilename, y_only);


inputFilename = 'C:\Users\Administrator\Desktop\研1\1783\ECE1783A1\akiyoY_cif.yuv';
%inputFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\data\akiyoY_cif.yuv';


v1 = YOnlyVideo(inputFilename, 352, 288);
block_width = 128;
block_height = block_width;
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

m =  MotionEstimationVideo(v1WithPadding, 1, block_width, block_height,2)
reconstructuredVideo = m.getReconstructuredVideo();
residualVideo = m.getResidualVideo();

outputResidualFilename = 'C:\Users\Administrator\Desktop\研1\1783\ECE1783A1\akiyoYResidual.txt';
%outputResidualFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\output\akiyoYResidual.txt';
residualVideo.writeToFile(outputResidualFilename);

%outputMVFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\output\akiyoYMV.txt';
outputMVFilename = 'C:\Users\Administrator\Desktop\研1\1783\ECE1783A1\akiyoYMV.txt';
m.motionVectorVideoWriteToFile(outputMVFilename);

%outputReconstructedFilename = 'C:\Users\ASUS\Matlab-worksapce\ECE1783A1\output\akiyoYReconstructed.yuv';
outputReconstructedFilename = 'C:\Users\Administrator\Desktop\研1\1783\ECE1783A1\akiyoYReconstructed.yuv';
reconstructuredVideo.writeToFile(outputReconstructedFilename);


de =  MotionCompensationVideo(residualVideo, m.motionVectorVideo, block_width, block_height,2);

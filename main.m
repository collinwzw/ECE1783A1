systemSetUp();
% inputFilename = '.\data\akiyo_cif.yuv';
% outputFilename = '.\data\akiyoY_cif.yuv';
% v1 = YUVVideo(inputFilename, 352, 288, 420);
% y_only = true;
% v1.writeToFile(outputFilename, y_only);
% 
% 
% inputFilename = '.\data\akiyoY_cif.yuv';
% 
% 
% v1 = YOnlyVideo(inputFilename, 352, 288);
% block_width = 64;
% block_height = block_width;
% [v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);
% 
% m =  MotionEstimationVideo(v1WithPadding, 1, block_width, block_height,2)
% reconstructuredVideo = m.getReconstructuredVideo();
% residualVideo = m.getResidualVideo();
% 
% outputResidualFilename = '.\output\akiyoYResidual.txt';
% residualVideo.writeToFile(outputResidualFilename);
% 
% outputMVFilename = '.\output\akiyoYMV.txt';
% m.motionVectorVideoWriteToFile(outputMVFilename);
% 
% outputReconstructedFilename = '.\output\akiyoYReconstructed.yuv';
% reconstructuredVideo.writeToFile(outputReconstructedFilename);
% 
% 
% %de =  MotionCompensationVideo(residualVideo, m.motionVectorVideo,
% block_width, block_height,2);
% matix = [[140,64];[89,4]];
% q = QuantizationEngine(matix,2,2,0)

matrix = [ [-31,9,8,4];[-4,1,4,0];[-3,2,4,0];[4,0,-4,0]];
r = EntropyEngine(matrix,4,4);
% 
%  inputFilename = 'Z:\Semester 3\Design tradeoff\foreman_cif.yuv';
%  outputFilename = 'Z:\Semester 3\Design tradeoff\Assignment1\Results\foremanY_cif.yuv';
%  v1 = YUVVideo(inputFilename, 352, 288, 420);
%  y_only = true;
%  v1.writeToFile(outputFilename, y_only);

% 
inputFilename = 'Z:\Semester 3\Design tradeoff\Assignment1\Results\foremanY_cif.yuv';
% 
v1 = YOnlyVideo(inputFilename, 352, 288);
block_width = 8;
block_height = block_width;
r_value=1;
n_value=3;
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

m =  MotionEstimationVideo(v1WithPadding, r_value, block_width, block_height,n_value);
% 
%%
 reconstructuredVideo = m.getReconstructuredVideo();
 residualVideo = m.getResidualVideo();
 outputResidualFilename = 'Z:\Semester 3\Design tradeoff\Assignment1\Results\foremanY_Residual.txt';
 residualVideo.writeToFile(outputResidualFilename);
 %%
 outputMVFilename = 'Z:\Semester 3\Design tradeoff\Assignment1\Results\Test_MV.txt';
 m.motionVectorVideoWriteToFile(outputMVFilename);
 %%
 outputReconstructedFilename = 'Z:\Semester 3\Design tradeoff\Assignment1\Results\foremanY_Reconstructed.yuv';
 reconstructuredVideo.writeToFile(outputReconstructedFilename);
figure;
m.getSAD_metric();
% 
% 

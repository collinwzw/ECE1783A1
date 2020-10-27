% systemSetUp();
% inputFilename = '.\data\akiyo_cif.yuv';
% outputFilename = '.\data\akiyoY_cif.yuv';
% v1 = YUVVideo(inputFilename, 352, 288, 420);
% y_only = true;
% v1.writeToFile(outputFilename, y_only);


inputFilename = '.\data\akiyoY_cif.yuv';


v1 = YOnlyVideo(inputFilename, 352, 288);
block_width = 128;
block_height = block_width;
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

m =  MotionEstimationVideo(v1WithPadding, 1, block_width, block_height,2)
reconstructuredVideo = m.getReconstructuredVideo();
residualVideo = m.getResidualVideo();

outputResidualFilename = '.\output\akiyoYResidual.txt';
residualVideo.writeToFile(outputResidualFilename);

outputMVFilename = '.\output\akiyoYMV.txt';
m.motionVectorVideoWriteToFile(outputMVFilename);

outputReconstructedFilename = '.\output\akiyoYReconstructed.yuv';
reconstructuredVideo.writeToFile(outputReconstructedFilename);

decoderwidth = residualVideo.width;
decoderheight = residualVideo.height;
[mvwidth,mvheight,~] = size(m.motionVectorVideo);
numberOfFrames = residualVideo.numberOfFrames;

de = MotionCompensationVideo('.\output\Residual.txt', '.\output\MotionVectors.txt', block_width, block_height,decoderwidth,decoderheight,mvwidth,mvheight,numberOfFrames);
outputDecodeRefFilename = '.\output\akiyoYDecodedRef.yuv';
DecodedRefVideo = de.getDecodedRefVideo();
DecodedRefVideo.writeToFile(outputDecodeRefFilename);
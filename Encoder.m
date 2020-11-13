classdef Encoder
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        inputvideo;
        r;
        n;
        QP;
        reconstructedVideo;
        modes;
        MV;
        diff_modes;
        diff_MV;
        I_Period;
        entropyVideo;
        predictionVideo;
        numberOfBitsList;
        nRefFrame;
    end
    
    methods (Access = 'public')
        function obj = Encoder(inputvideo,block_width, block_height,r ,n, QP, I_Period,nRefFrame)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.inputvideo = inputvideo;
            obj.I_Period = I_Period;
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.r=r;
            obj.n = n;
            obj.QP = QP;
            obj.nRefFrame=nRefFrame;
            obj = obj.encodeVideo();
        end
    
        function [processedBlock] = generateReconstructedFrame(obj,frameIndex, predicted_block,Diffencoded_frame)
            %calculating residual frame
            residualBlockData =  int16(obj.inputvideo.Y(predicted_block.top_height_index: predicted_block.top_height_index + predicted_block.block_height-1, predicted_block.left_width_index: predicted_block.left_width_index + predicted_block.block_width-1,frameIndex)) -int16(predicted_block.data);
            processedBlock = predicted_block;
            processedBlock.data = residualBlockData;
            
            %input alculated residual frame to transformation engine
            processedBlock.data = dct2(processedBlock.data);
            
            %input transformed frame to quantization engine
            processedBlock.data = QuantizationEngine(processedBlock).qtc;
            
            %call entropy engine to encode the quantized transformed frame
            %and save it.
            %entropyFrame = EntropyEngine();
%             if (rem(frameIndex - 1,obj.I_Period)) == 0
%                 %it's I frame
%                 entropyFrame = entropyFrame.EntropyEngineI(quantizedtransformedFrame,Diffencoded_frame.diff_modes, obj.block_width, obj.block_height,obj.QP);
%                 entropyQTC = entropyFrame.bitstream;
%                 entropyPredictionInfo = entropyFrame.predictionInfoBitstream;
%             else
%                 %it's P frame
%                 entropyFrame = entropyFrame.EntropyEngineP(quantizedResult,Diffencoded_frame.diff_motionvector, obj.block_width, obj.block_height,obj.QP);
%                 entropyQTCBlock = entropyFrame.bitstream;
%                 entropyPredictionInfoBlock = entropyFrame.predictionInfoBitstream;
%             end

            %input quantized transformed frame to rescaling engine    
            processedBlock.data = RescalingEngine(processedBlock).rescalingResult;
            %input rescal transformed frame to inverse transformation engine    
            processedBlock.data = idct2(processedBlock.data);
            %finally, add this frame to predicted frame
            reconstructedBlock = int16(predicted_block.data) + int16( processedBlock.data);
            processedBlock.data = reconstructedBlock;
        end
        
        function type = generateTypeMatrix(obj)
            type = zeros(1, obj.inputvideo.numberOfFrames);
            for i = 1: obj.I_Period:obj.inputvideo.numberOfFrames
                type(i) = 1;
            end
        end
        
        function obj = encodeVideo(obj)
            j = 1;
            k = 1;
            lastIFrame=-1;
            type = obj.generateTypeMatrix();
            %for i = 1: 1:obj.inputvideo.numberOfFrames
            for i = 1: 1:10
                if type(i) == 1
                    obj.reconstructedVideo.Y(:,:,i) = obj.inputvideo.Y(:,:,i);
                    lastIFrame = i;
                    %use intra prediction
%                     frame = IntraPredictionEngine(obj.inputvideo.Y(:,:,i),obj.block_width,obj.block_height);
%                     deframe = DifferentialEncodingEngine();
%                     deframe = deframe.differentialEncodingMode(frame.modeFrame);
%                     [reconstructedFrame,entropyQTC,entropyPredictionInfo] = obj.generateReconstructedFrame(i,frame,deframe );
%                     obj.reconstructedVideo(:,:,i) = uint8(reconstructedFrame);
%                     obj.entropyVideo = [obj.entropyVideo entropyQTC];
%                     obj.predictionVideo = [obj.predictionVideo entropyPredictionInfo];
%                     obj.diff_modes(:,:,j) = deframe.diff_modes;
%                     obj.modes(:,:,j)=frame.modeFrame;
                    j = j + 1;
                else
                    block_list = obj.truncateFrameToBlocks(i);           
                    length = size(block_list,2);
                    deframe = DifferentialEncodingEngine();
                    
                    %for loop to go through all blocks
                    for index=1:1:length
                         %RDO computation of block_list(index)
                         %if futher truncate
                         % if not do one time
                         %doing the truncation
                         %split or not
                         %
                         min_value = 9999999;
                         % for loop to go through multiple reference frame
                         % to get best matched block
                         for referenceframe_index = i - obj.nRefFrame: 1 : i-1
                             if referenceframe_index >= lastIFrame
                                ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width, obj.block_height);
                                if ME_result.differenceForBestMatchBlock < min_value
                                    min_value = ME_result.differenceForBestMatchBlock;
                                    bestMatchBlock = ME_result.bestMatchBlock;
                                    bestMatchBlock.referenceFrameIndex = referenceframe_index;
                                end               
                             end                      
                         end
                         bestMatchBlock = bestMatchBlock.setframeType(type(i));
                         processedBlock = obj.generateReconstructedFrame(i,bestMatchBlock,deframe );
                         obj.reconstructedVideo.Y(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                    end

%                     deframe = DifferentialEncodingEngine();
%                     deframe = deframe.differentialEncodingMotionVector(frame.blocks);
%                     [reconstructedFrame,entropyQTC,entropyPredictionInfo] = obj.generateReconstructedFrame(i,frame,deframe );
%                     obj.reconstructedVideo(:,:,i) = uint8(reconstructedFrame);
%                     obj.entropyVideo = [obj.entropyVideo entropyQTC];
%                     obj.predictionVideo = [obj.predictionVideo entropyPredictionInfo];
%                     obj.diff_MV(:,:,k) = deframe.diff_motionvector;
%                     obj.MV(:,:,k)=frame.blocks;
%                     k = k + 1;
                    % realationship between i, j, k
                end
%                obj.numberOfBitsList = [obj.numberOfBitsList size(entropyQTC,2) + size(entropyPredictionInfo,2) ];
                fprintf("frame number %d is done\n", i);
            end
        end

        function blockList = truncateFrameToBlocks(obj,frameIndex)
            %This function truncate the frame and to blocks.
            %from each truncated block in current frame, it gets the best
            % matched block from reference frame according to given r
            %then it gets the residualBlock from best matched block minus
            %current block.
            blockList = [];
            height = size(obj.inputvideo.Y(:,:,frameIndex),1);
            width = size(obj.inputvideo.Y(:,:,frameIndex),2);
            for i=1:obj.block_height:height
                for j=1:obj.block_width:width
                    currentBlock = Block(obj.inputvideo.Y(:,:,frameIndex), j,i, obj.block_width, obj.block_height );
                    currentBlock = currentBlock.setQP(obj.QP);
                    blockList = [blockList, currentBlock];
                end
            end
        end
    end
end
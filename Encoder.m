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
    end
    
    methods (Access = 'public')
        function obj = Encoder(inputvideo,block_width, block_height,r ,n, QP, I_Period)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.inputvideo = inputvideo;
            obj.I_Period = I_Period;
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.r=r;
            obj.n = n;
            obj.QP = QP;
            obj = obj.encodeVideo();
        end
    
        function [reconstructedBlock, entropyQTCBlock,entropyPredictionInfoBlock] = generateReconstructedFrame(obj,frameIndex, predicted_block,Diffencoded_frame)
            %calculating residual frame
            residualBlock =  int16(obj.inputvideo.Y(predicted_block.left_width_index: predicted_block.left_width_index + predicted_block.block_width-1, predicted_block.top_height_index: predicted_block.left_width_index + predicted_block.block_height-1,frameIndex)) -int16(predicted_block.data); 
            %input alculated residual frame to transformation engine
            transformedBlock = dct2(residualBlock);
            %input transformed frame to quantization engine
            quantizedResult = QuantizationEngine(transformedBlock,predicted_block.block_width, predicted_block.block_height, predicted_block.QP).qtc;
            
            %call entropy engine to encode the quantized transformed frame
            %and save it.
            entropyFrame = EntropyEngine();
            if (rem(frameIndex - 1,obj.I_Period)) == 0
                %it's I frame
                entropyFrame = entropyFrame.EntropyEngineI(quantizedResult,Diffencoded_frame.diff_modes, obj.block_width, obj.block_height,obj.QP);
                entropyQTCBlock = entropyFrame.bitstream;
                entropyPredictionInfoBlock = entropyFrame.predictionInfoBitstream;
            else
                %it's P frame
                entropyFrame = entropyFrame.EntropyEngineP(quantizedResult,Diffencoded_frame.diff_motionvector, obj.block_width, obj.block_height,obj.QP);
                entropyQTCBlock = entropyFrame.bitstream;
                entropyPredictionInfoBlock = entropyFrame.predictionInfoBitstream;
            end
            %input quantized transformed frame to rescaling engine    
            rescaledFrame = RescalingEngine(quantizedResult,obj.block_width, obj.block_height, obj.QP ).rescalingResult;
            %input rescal transformed frame to inverse transformation engine    
            rescaledFrame = idct2(rescaledFrame);
            %finally, add this frame to predicted frame
            reconstructedBlock = int16(predicted_block.predictedFrame(:,:,1)) + int16(rescaledFrame(:,:,1));
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
            type = obj.generateTypeMatrix();
            %for i = 1: 1:obj.inputvideo.numberOfFrames
            for i = 1: 1:10
                if type(i) == 1
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
                    for index=1:1:length
                         ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.inputvideo.Y(:,:,i)), obj.block_width, obj.block_height);
                         obj.generateReconstructedFrame(i,ME_result.bestMatchBlock,deframe )
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
            blockList = []
            height = size(obj.inputvideo.Y(:,:,frameIndex),1);
            width = size(obj.inputvideo.Y(:,:,frameIndex),2);
            for i=1:obj.block_height:height
                for j=1:obj.block_width:width
                    currentBlock = Block(obj.inputvideo.Y(:,:,frameIndex), j,i, obj.block_width, obj.block_height );
                    currentBlock = currentBlock.setQP(obj.QP);
                    blockList = [blockList, currentBlock] 
                end
            end          
        end
    end
end
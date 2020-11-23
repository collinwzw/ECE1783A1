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
        FEMEnable;
        FastME;
        OutputBitstream=[];
        VBSEnable;
        count = 0;
    end
    
    methods (Access = 'public')
        function obj = Encoder(inputvideo,block_width, block_height,r ,n, QP, I_Period,nRefFrame,FEMEnable,FastME, VBSEnable)
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
            obj.FEMEnable=FEMEnable;
            obj.FastME = FastME;
            obj.VBSEnable=VBSEnable;
            obj = obj.encodeVideo();

        end
    
        function [processedBlock, en] = generateReconstructedFrame(obj,frameIndex, predicted_block,Diffencoded_frame)
            %calculating residual frame
            residualBlockData =  int16(obj.inputvideo.Y(predicted_block.top_height_index: predicted_block.top_height_index + predicted_block.block_height-1, predicted_block.left_width_index: predicted_block.left_width_index + predicted_block.block_width-1,frameIndex)) -int16(predicted_block.data);
            processedBlock = predicted_block;
            processedBlock.data = residualBlockData;

            %input alculated residual frame to transformation engine
            processedBlock.data = dct2(processedBlock.data);

            %input transformed frame to quantization engine

            processedBlock.data= QuantizationEngine(processedBlock).qtc;
            
            %call entropy engine to encode the quantized transformed frame
            %and save it.
            en = EntropyEngine_Block(processedBlock);
            

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
%             obj.I_Period = 10;
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
            for i = 1: 1:2
                if type(i) == 1
                    obj.reconstructedVideo.Y(:,:,i) = zeros( obj.inputvideo.width , obj.inputvideo.height);
                    lastIFrame = i;
                    reference_frame1=[];
                    reference_frame4=[];
%                     %use intra prediction
                    deframe = DifferentialEncodingEngine();

                      block_list = obj.truncateFrameToBlocks(i);
                      length = size(block_list,2);
                      for index=1:1:length
                         intrapred=IntraPredictionEngine(block_list(index),obj.reconstructedVideo.Y(:,:,i));
                         intrapred=intrapred.block_creation();
                         if(obj.VBSEnable==0)
                             predicted_value=intrapred.blocks;
                             predicted_value.data=intrapred.predictedblock;
                             predicted_value.split=0;
                             predicted_value = predicted_value.setframeType(type(i));
                             [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_value,deframe );
                             obj.reconstructedVideo.Y(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                             obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
                         else
                             temp_bitstream1=[];
                             predicted_value=intrapred.blocks;
                             predicted_value.data=intrapred.predictedblock;
                             predicted_value.split=0;
                             predicted_value = predicted_value.setframeType(type(i));
                             [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_value,deframe );
                             reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                             temp_bitstream1=en.bitstream;
                              count=1;
                              SAD4=[];
                              mode4=[];
                              temp_bitstream4=[];
                             for row_i =1:1:2
                                for col_i=1:1:2
                                     intrapred_4=IntraPredictionEngine(block_list(index),reference_frame4);
                                     intrapred_4=intrapred_4.block_creation4(count);
                                     predicted_value_4=intrapred_4.blocks;
                                     predicted_value_4.data=intrapred_4.smallblock_4;
                                     predicted_value_4.split=1;
                                     predicted_value_4.QP=obj.QP-1;
                                     predicted_value_4 = predicted_value_4.setframeType(type(i));
                                     [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_value_4,deframe );
                                    temp_bitstream4=[temp_bitstream4 en.bitstream];
                                    curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                    curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                    predictedblock_4(curr_row,curr_col)=intrapred_4.smallblock_4;
                                    reference_frame4(predicted_value_4.top_height_index: predicted_value_4.top_height_index + predicted_value_4.block_height-1, predicted_value_4.left_width_index: predicted_value_4.left_width_index + predicted_value_4.block_width-1) = uint8(processedBlock.data);
                                    count=count+1;
                                    SAD4=[SAD4 intrapred_4.SAD_4];
                                    mode4=[mode4 predicted_value_4.Mode];

                                end
                             end
                             cost=RDO(predicted_value.data,predictedblock_4,obj.block_height,obj.block_width,intrapred.SAD,SAD4);
                             if(cost.flag==0)
                                 obj.reconstructedVideo.Y(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1,i) = reference_frame1(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                 obj.OutputBitstream = [obj.OutputBitstream temp_bitstream1];
                             else
                                 obj.reconstructedVideo.Y(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1,i) = reference_frame4(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                 obj.OutputBitstream = [obj.OutputBitstream temp_bitstream4];
                             end
%                              reference_frame(:,:)=obj.reconstructedVideo.Y;
                         end
                      end

                else
                    %inter
                    block_list = obj.truncateFrameToBlocks(i);
                    length = size(block_list,2);
                    deframe = DifferentialEncodingEngine();
                    previousMV = MotionVector(0,0);
                    previousFrameIndex = 0;
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
                             % check starts from last I frame or input parameter nRefFrame.
                             if referenceframe_index >= lastIFrame
                                ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                if ME_result.differenceForBestMatchBlock < min_value
                                    min_value = ME_result.differenceForBestMatchBlock;
                                    bestMatchBlock = ME_result.bestMatchBlock;
                                    bestMatchBlock.referenceFrameIndex = referenceframe_index;
                                end
                                if obj.VBSEnable == true
                                    % variable block size
                                    SAD4=0;
                                    SubBlockList = [];
                                    previousMVSubBlock = previousMV;
                                    for row_i =1:1:2
                                       for col_i=1:1:2
                                           %truncate the original block to
                                           %four sub blocks
                                           subBlock_list = obj.VBStruncate(block_list(index));
                                       end
                                    end
                                    for subBlockIndex = 1:1:size(subBlock_list,2)
                                        %for each block, doing the Motion
                                        %Estimation
                                        SubBlockME_result = MotionEstimationEngine(obj.r,subBlock_list(subBlockIndex), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
                                        SAD4 = SAD4 + SubBlockME_result.differenceForBestMatchBlock;
                                        SubBlockME_result.bestMatchBlock.referenceFrameIndex = referenceframe_index;
                                        SubBlockME_result.bestMatchBlock.split=1;
                                        previousMVSubBlock = SubBlockME_result.bestMatchBlock.MotionVector;
                                        SubBlockList = [SubBlockList SubBlockME_result.bestMatchBlock];
                                    end
                                    if SAD4 < min_value
                                        %compare to the minvalue
                                        min_value = SAD4;
                                        bestMatchBlock = SubBlockList;
                                    end
                                end
                             end
                         end

                         for bestMatchBlockIndex = 1:1:size(bestMatchBlock,2)
                                %set the frame type for the block
                                bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setframeType(type(i));

                                %differential encoding for motion vector
                                tempPreviousMV = bestMatchBlock(bestMatchBlockIndex).MotionVector;
                                bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setbitMotionVector( MotionVector(previousMV.x - bestMatchBlock(bestMatchBlockIndex).MotionVector.x, previousMV.y - bestMatchBlock(bestMatchBlockIndex).MotionVector.y));
                                previousMV = tempPreviousMV;

                                %differential encoding for reference frame index
                                tempPreviousFrameIndex = bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex = previousFrameIndex - bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                previousFrameIndex = tempPreviousFrameIndex;

                                [processedBlock, en] = obj.generateReconstructedFrame(i,bestMatchBlock(bestMatchBlockIndex),deframe );
                                obj.reconstructedVideo.Y(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(processedBlock.data);
                                obj.OutputBitstream = [obj.OutputBitstream en.bitstream];

                         end

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


        function subBlockList = VBStruncate(obj,blcok)
            %This function truncate the frame and to blocks.
            %from each truncated block in current frame, it gets the best
            % matched block from reference frame according to given r
            %then it gets the residualBlock from best matched block minus
            %current block.
            subBlockList = [];
            height = blcok.block_height;
            width = blcok.block_width;
            for i=1:obj.block_height/2:height
                for j=1:obj.block_width/2:width
                    currentSubBlock = Block(blcok.data, j,i, obj.block_width/2, obj.block_height/2 );
                    currentSubBlock = currentSubBlock.setQP(obj.QP - 1);
                    subBlockList = [subBlockList, currentSubBlock];
                end
            end
        end
    end
end
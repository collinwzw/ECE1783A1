classdef Encoder
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        inputvideo;
        r;
        n;
        QP;
        reconstructedVideo;
        I_Period;
        predictionVideo;
        nRefFrame;
        FEMEnable;
        FastME;
        OutputBitstream=[];
        VBSEnable;
        SADPerFrame;
        RCflag;
        bitBudget;
        blockList;
        ParallelMode;
    end
    
    methods (Access = 'public')
        function obj = Encoder(inputvideo,block_width, block_height,r , QP, I_Period,nRefFrame,FEMEnable,FastME, VBSEnable, RCflag, bitBudget, ParallelMode)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.inputvideo = inputvideo;
            obj.I_Period = I_Period;
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.r=r;
            obj.QP = QP;
            obj.nRefFrame=nRefFrame;
            obj.FEMEnable=FEMEnable;
            obj.FastME = FastME;
            obj.VBSEnable=VBSEnable;
            obj.RCflag = RCflag;
            obj.bitBudget = bitBudget;
            obj.SADPerFrame = [];
            obj.ParallelMode = ParallelMode;
            obj = obj.encodeVideo();
        end
    
        function [processedBlock, en] = generateReconstructedFrame(obj,frameIndex, predicted_block)
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
            en = EntropyEngine_Block(processedBlock,obj.QP,obj.RCflag);
            

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
            %initialize parameter for memorize the lastIFrame
            lastIFrame=-1;
            %generating the type list according to input parameter I_Period
            type = obj.generateTypeMatrix();
            
            %for i = 1: 1:obj.inputvideo.numberOfFrames
            % go through the each frame
            
            for i = 1: 1:2
                rowIndex = 1;
                actualBitSpentCurrentRow = 0;
                if type(i) == 1
                    intra = true;
                    %if intra frame
                    %initialized the empty reconstructed frame for current
                    %index i with zero.
                    obj.reconstructedVideo.Y(:,:,i) = zeros( obj.inputvideo.width , obj.inputvideo.height);
                    lastIFrame = i;
                    reference_frame1=[];
                    reference_frame4=[];
                    %truncate current frame to fix size block list
                    %according to the input block size
                    block_list = obj.truncateFrameToBlocks(i);
                    length = size(block_list,2);
                    for index=1:1:length
                        if obj.RCflag == 1
                            if block_list(index).top_height_index == rowIndex
                                obj.bitBudget = obj.bitBudget.computeQP(intra,actualBitSpentCurrentRow );
                                obj.QP = obj.bitBudget.QP;
                                rowIndex = rowIndex + obj.block_height;
                                actualBitSpentCurrentRow = 0;
                            end
                        end
                         intrapred=IntraPredictionEngine(block_list(index),obj.reconstructedVideo.Y(:,:,i));
                         intrapred=intrapred.block_creation();
                         if(obj.VBSEnable==0)
                             % if no VBS required, just direct do the intra
                             % prediction on the blocks
                             predicted_block=intrapred.blocks;
                             predicted_block.data=intrapred.predictedblock;
                             predicted_block.split=0;
                             predicted_block = predicted_block.setQP(obj.QP);
                             predicted_block = predicted_block.setframeType(type(i));
                             [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
                             obj.reconstructedVideo.Y(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                             obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
                         else
                             %VBS required
                             %first do the full block prediction
                             temp_bitstream1=[];
                             predicted_block=intrapred.blocks;
                             predicted_block.data=intrapred.predictedblock;
                             predicted_block.split=0;
                             predicted_block = predicted_block.setQP(obj.QP);
                             predicted_block = predicted_block.setframeType(type(i));
                             [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
                             reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                             temp_bitstream1=en.bitstream;
                             
                             %do the sub block prediction
                             count=1;
                             SAD4=zeros( 1 ,4);
                             mode4=zeros( 1 ,4);
                             temp_bitstream4=[];
                             predictedblock_4 = zeros( obj.block_width,obj.block_height);
                             reference_frame4 = obj.reconstructedVideo.Y(:,:,i);
                             for row_i =1:1:2
                                for col_i=1:1:2
                                    intrapred_4=IntraPredictionEngine(block_list(index),reference_frame4);
                                    intrapred_4=intrapred_4.block_creation4(count);
                                    predicted_sub_block=intrapred_4.blocks;
                                    predicted_sub_block.data=intrapred_4.smallblock_4;
                                    predicted_sub_block.split=1;
                                    if obj.QP >= 1
                                        predicted_sub_block.QP=obj.QP-1;
                                    else
                                        predicted_sub_block.QP=obj.QP;
                                    end
                                    predicted_sub_block = predicted_sub_block.setframeType(type(i));
                                    [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_sub_block );
                                    temp_bitstream4=[temp_bitstream4 en.bitstream];
                                    curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                    curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                    predictedblock_4(curr_row,curr_col)=intrapred_4.smallblock_4;
                                    reference_frame4(predicted_sub_block.top_height_index: predicted_sub_block.top_height_index + predicted_sub_block.block_height-1, predicted_sub_block.left_width_index: predicted_sub_block.left_width_index + predicted_sub_block.block_width-1) = uint8(processedBlock.data);
                                    SAD4(count)= intrapred_4.SAD_4;
                                    mode4(count)=predicted_sub_block.Mode;
                                    count=count+1;
                                end
                            end
                            cost=RDO(predicted_block.data,predictedblock_4,obj.block_height,obj.block_width,intrapred.SAD,SAD4,obj.QP);
                            if(cost.flag==0)
                                 obj.reconstructedVideo.Y(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1,i) = reference_frame1(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
                                 obj.OutputBitstream = [obj.OutputBitstream temp_bitstream1];
                                 actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_bitstream1,2);
                                 actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_bitstream4,2);%obj.predictionVideo(1:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predictedblock_4);
                                 obj.blockList = [obj.blockList predicted_block];
                                 %obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predicted_block.data);
                            else
                                 obj.reconstructedVideo.Y(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1,i) = reference_frame4(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
                                 obj.OutputBitstream = [obj.OutputBitstream temp_bitstream4];

                                 obj.blockList = [obj.blockList predicted_sub_block];
                                 obj.blockList = [obj.blockList predicted_sub_block];
                                 obj.blockList = [obj.blockList predicted_sub_block];
                                 obj.blockList = [obj.blockList predicted_sub_block];
                            end
                        end
                    end
                else
                    intra = false;
                    %inter
                    block_list = obj.truncateFrameToBlocks(i);
                    length = size(block_list,2);
                    previousMV = MotionVector(0,0);
                    previousFrameIndex = 0;
                    %for loop to go through all blocks
                    for index=1:1:length
                        if obj.RCflag == 1
                            if block_list(index).top_height_index == rowIndex
                                obj.bitBudget = obj.bitBudget.computeQP(intra,actualBitSpentCurrentRow );
                                obj.QP = obj.bitBudget.QP;
                                rowIndex = rowIndex + obj.block_height;
                                actualBitSpentCurrentRow = 0;
                            end
                        end
                         min_value = 9999999;
                         % for loop to go through multiple reference frame
                         % to get best matched block
                         for referenceframe_index = i - obj.nRefFrame: 1 : i-1
                             % check starts from last I frame or input parameter nRefFrame.
                             if referenceframe_index >= lastIFrame
                                if obj.VBSEnable == false
                                    ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                    if ME_result.differenceForBestMatchBlock < min_value
                                        min_value = ME_result.differenceForBestMatchBlock;
                                        bestMatchBlock = ME_result.bestMatchBlock;
                                        bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                        bestMatchBlock.split=0;
                                    end
                                else
                                    ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                    bestMatchBlockNoSplit = ME_result.bestMatchBlock;
                                    bestMatchBlockNoSplit.referenceFrameIndex = i - referenceframe_index;
                                    bestMatchBlockNoSplit.split = 0;
                                    % variable block size
                                    SAD4=zeros( 1 ,4);
                                    SubBlockList = [];
                                    previousMVSubBlock = previousMV;

                                   %truncate the original block to
                                   %four sub blocks
                                    subBlock_list = obj.VBStruncate(block_list(index));
                                    row_i = 1;
                                    col_i = 1;
                                    for subBlockIndex = 1:1:size(subBlock_list,2)
                                        %for each block, doing the Motion
                                        %Estimation
                                        SubBlockME_result = MotionEstimationEngine(obj.r,subBlock_list(subBlockIndex), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
                                        SAD4(col_i + (row_i - 1) * 2)= SubBlockME_result.differenceForBestMatchBlock;
                                        SubBlockME_result.bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                        SubBlockME_result.bestMatchBlock.split=1;
                                        previousMVSubBlock = SubBlockME_result.bestMatchBlock.MotionVector;    
                                        curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                        curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                        predictedblock_4(curr_row,curr_col)=SubBlockME_result.bestMatchBlock.data;
                                        SubBlockList = [SubBlockList SubBlockME_result.bestMatchBlock];
                                        col_i = col_i + 1;
                                        if col_i > 2
                                            row_i = row_i + 1;
                                            col_i = 1;
                                        end
                                    end                                    
                                    cost=RDO(bestMatchBlockNoSplit.data,predictedblock_4,obj.block_height,obj.block_width,ME_result.differenceForBestMatchBlock,SAD4,obj.QP);
                                    if(cost.flag~=0)
                                        % split has smaller RDO
                                        if cost.RDO_cost4 < min_value
                                            min_value = cost.RDO_cost4;
                                            bestMatchBlock = SubBlockList;
                                        end
                                    else
                                        % no split has smaller RDO
                                        if cost.RDO_cost1 < min_value
                                            min_value = cost.RDO_cost1;
                                            bestMatchBlock = bestMatchBlockNoSplit;
                                        end
                                    end
                                end
                             end
                         end

                         for bestMatchBlockIndex = 1:1:size(bestMatchBlock,2)
                                %set the frame type for the block
                                bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setframeType(type(i));
                                
                                if (size(bestMatchBlock,2) > 1) && obj.QP >= 1
                                    bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setQP(obj.QP - 1);
                                else
                                    bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setQP(obj.QP - 1);
                                end
                                %set QP for the block
                                if obj.ParallelMode == 0
                                    %differential encoding for motion vector
                                    tempPreviousMV = bestMatchBlock(bestMatchBlockIndex).MotionVector;
                                    bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setbitMotionVector( MotionVector(previousMV.x - bestMatchBlock(bestMatchBlockIndex).MotionVector.x, previousMV.y - bestMatchBlock(bestMatchBlockIndex).MotionVector.y));
                                    previousMV = tempPreviousMV;

                                    %differential encoding for reference frame index
                                    tempPreviousFrameIndex = bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                    bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex = previousFrameIndex - bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                    previousFrameIndex = tempPreviousFrameIndex;
                                end
                                if bestMatchBlock(bestMatchBlockIndex).top_height_index == 289
                                    a=1;
                                end
                                
                                obj.predictionVideo(bestMatchBlock(bestMatchBlockIndex).top_height_index:bestMatchBlock(bestMatchBlockIndex).top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,bestMatchBlock(bestMatchBlockIndex).left_width_index:bestMatchBlock(bestMatchBlockIndex).left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(bestMatchBlock(bestMatchBlockIndex).data);

                                [processedBlock, en] = obj.generateReconstructedFrame(i,bestMatchBlock(bestMatchBlockIndex) );
                                obj.blockList = [obj.blockList bestMatchBlock(bestMatchBlockIndex)];

                                obj.reconstructedVideo.Y(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(processedBlock.data);
                                obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
                                actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(en.bitstream,2);
                         end
                    end
                end
                obj.SADPerFrame = [obj.SADPerFrame abs(sum(obj.reconstructedVideo.Y(:,:,i), 'all') - sum(obj.inputvideo.Y(:,:,i), 'all'))];
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
                    %currentBlock = currentBlock.setQP(obj.QP);
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


            col = 0;
            for j=1:obj.block_width/2:width
                row = 0;
                for i=1:obj.block_height/2:height
                    currentSubBlock = Block(blcok.data, j,i, obj.block_width/2, obj.block_height/2 );
                    currentSubBlock.top_height_index = blcok.top_height_index + (col) * obj.block_width/2;
                    currentSubBlock.left_width_index = blcok.left_width_index + (row) * obj.block_height/2;
                    currentSubBlock = currentSubBlock.setQP(obj.QP - 1);
                    subBlockList = [subBlockList, currentSubBlock];
                    row = row + 1;
                end
                col = col + 1;
            end
        end
    end
end
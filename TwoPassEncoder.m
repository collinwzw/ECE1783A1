classdef TwoPassEncoder
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        inputvideo;
        r;
        n;
        QP;
        I_Period;
        RCflag;
        nRefFrame;
        FEMEnable;
        FastME;
        VBSEnable;
        OutputBitstream1=[];
        predictionVideo1;
        SADPerFrame1;
        reconstructedVideo1;
        bitCountVideo1;
        OutputBitstream2=[];
        predictionVideo2;
        SADPerFrame2;
        reconstructedVideo2;
        bitCountVideo2;
        lastIFrame;
        bitBudget;
        bitCountVideo;
        typelist;
        QPSumSecondPass;
        NumsBlocksSecondPass;
        bitPerFrame;
        OutputBitstream;
        blockList;
        splitList1;
        splitList2;
        motionVectorList1;
        searchRangeRC3;
    end
    
    methods (Access = 'public')
        function obj = TwoPassEncoder(inputvideo,block_width, block_height,r , QP, I_Period,nRefFrame,FEMEnable,FastME, VBSEnable,RCflag, bitBudget)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.inputvideo = inputvideo;
            obj.OutputBitstream = [];
            obj.I_Period = I_Period;
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.r=r;
            obj.QP = QP;
            obj.RCflag = RCflag;
            obj.nRefFrame=nRefFrame;
            obj.FEMEnable=FEMEnable;
            obj.FastME = FastME;
            obj.VBSEnable=VBSEnable;
            obj.bitBudget = bitBudget;
            obj.SADPerFrame1 = [];
            obj.motionVectorList1 = [];
            obj.SADPerFrame2 = [];
            obj.searchRangeRC3 = 2;
            obj.bitCountVideo1 = zeros(obj.inputvideo.width/block_width,obj.inputvideo.height/block_height, obj.inputvideo.numberOfFrames);
            obj.bitCountVideo2 = zeros(obj.inputvideo.width/block_width,obj.inputvideo.height/block_height, obj.inputvideo.numberOfFrames);
            obj.typelist = zeros( obj.inputvideo.numberOfFrames);
            obj.bitPerFrame = zeros( obj.inputvideo.numberOfFrames, 1);
            bitCountRowsVideo = zeros(obj.inputvideo.width/block_width, obj.inputvideo.numberOfFrames);
            TotalBitFirstPass= zeros(obj.inputvideo.numberOfFrames,1);
            TotalBitSecondPass = zeros(obj.inputvideo.numberOfFrames,1);
            QPList = zeros(obj.inputvideo.numberOfFrames);
            reconstructedVideo1 = zeros( obj.inputvideo.width , obj.inputvideo.height, obj.inputvideo.numberOfFrames);
            obj.reconstructedVideo2 = zeros( obj.inputvideo.width , obj.inputvideo.height, obj.inputvideo.numberOfFrames);
            lastIFrame = 1;
            lastQP = 0;
            diffference = zeros(obj.inputvideo.numberOfFrames,2);
            for i = 1:1:obj.inputvideo.numberOfFrames
                if i == 1
                    intra = true;
                else
                    intra = false;
                end
                e1 = obj.encodeFrameFirstPass(i,QP, reconstructedVideo1,  obj.bitBudget.RCflag);
                obj.bitPerFrame = e1.bitPerFrame;
                reconstructedVideo1 = e1.reconstructedVideo1;
                % compute sum bit count for each row 
                for row=1:1:obj.inputvideo.width/block_width
                    bitCountRowsVideo(row,i) = sum(e1.bitCountVideo1(row,:,i));
                end
                %compute the total bit count in current frame
                TotalBitFirstPass(i) = sum(bitCountRowsVideo(:,i));
                average = sum(bitCountRowsVideo(:,i))/size(bitCountRowsVideo,1);
                %change bit count to percentage
                for row=1:1:obj.inputvideo.width/block_width
                    bitCountRowsVideo(row,i) = bitCountRowsVideo(row,i)/TotalBitFirstPass(i);
                end
                
                if (i > 1)
                    if (lastQP == QP) 
                        if (TotalBitFirstPass(i)/TotalBitFirstPass(i-1) > 1.8 )
                            intra = true;
                            obj.typelist(i) = 1;
                        end
                        diffference(i,1) = TotalBitFirstPass(i)/TotalBitFirstPass(i-1);
                        diffference(i,2) = 1;
                    else
                        if ((TotalBitFirstPass(i) - TotalBitFirstPass(i-1))* (bitBudget.QPTableInter(lastQP+1)/bitBudget.QPTableInter(QP+1)) / TotalBitFirstPass(i-1) >7)
                            intra = true;
                            obj.typelist(i) = 1;
                        end
                        diffference(i,1) = (TotalBitFirstPass(i) - TotalBitFirstPass(i-1))* (bitBudget.QPTableInter(lastQP+1)/bitBudget.QPTableInter(QP+1)) / TotalBitFirstPass(i-1);
                        diffference(i,2) = 0;
                    end
                end
                
                obj.bitBudget = obj.bitBudget.rescalQPTable(intra, QP,average );
                obj.bitBudget.bitCountRowsVideo = bitCountRowsVideo;
                e2 = obj.encodeFrameSecondPass(i,intra, obj.bitBudget,obj.reconstructedVideo2,lastIFrame,e1.splitList1, e1.motionVectorList1);
%                 obj.blockList = [obj.blockList e2.blockList];
                obj.OutputBitstream = [obj.OutputBitstream e2.OutputBitstream2];
                lastQP = QP;
                QPList(i) = QP;
                QP = int16(e2.QPSumSecondPass/e2.NumsBlocksSecondPass) ;
                TotalBitSecondPass(i) = size(e2.OutputBitstream2,2);
                obj.reconstructedVideo2 = e2.reconstructedVideo2;
                lastIFrame = e2.lastIFrame;               
                obj.bitCountVideo(:,:,i) = e2.bitCountVideo2(:,:,i);
                
            end
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
            en = EntropyEngine_Block(processedBlock, predicted_block.QP, obj.RCflag);
            
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
        
        function obj = encodeFrameFirstPass(obj,i,QP,reconstructedVideo,RCflag)
            %initialize parameter for memorize the lastIFrame
            lastIFrame=1;
            %generating the type list according to input parameter I_Period
            obj.reconstructedVideo1 = reconstructedVideo;
            
            %for i = 1: 1:obj.inputvideo.numberOfFrames
            % go through the each frame

            if i == 1
                %if intra frame
                %initialized the empty reconstructed frame for current
                %index i with zero.
                reference_frame1=[];
                reference_frame4=[];
                %truncate current frame to fix size block list
                %according to the input block size
                block_list = obj.truncateFrameToBlocks(i, QP);
                length = size(block_list,2);
                for index=1:1:length
                     intrapred=IntraPredictionEngine(block_list(index),obj.reconstructedVideo1(:,:,i));
                     intrapred=intrapred.block_creation();
                     if(obj.VBSEnable==0)
                         % if no VBS required, just direct do the intra
                         % prediction on the blocks
                         predicted_block=intrapred.blocks;
                         predicted_block.data=intrapred.predictedblock;
                         predicted_block.split=0;
                         predicted_block = predicted_block.setframeType(1);
                         [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block);
                         obj.reconstructedVideo1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                         obj.OutputBitstream1 = [obj.OutputBitstream en.bitstream];
                     else
                         %VBS required
                         %first do the full block prediction
                         temp_bitstream1=[];
                         predicted_block=intrapred.blocks;
                         predicted_block.data=intrapred.predictedblock;
                         predicted_block.split=0;
                         predicted_block = predicted_block.setframeType(1);
                         [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
                         reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                         temp_bitstream1=en.bitstream;

                         %do the sub block prediction
                         count=1;
                         SAD4=zeros( 1 ,4);
                         mode4=zeros( 1 ,4);
                         temp_bitstream4=[];
                         predictedblock_4 = zeros( obj.block_width,obj.block_height);
                         reference_frame4 = obj.reconstructedVideo1(:,:,i);
                         for row_i =1:1:2
                            for col_i=1:1:2
                                intrapred_4=IntraPredictionEngine(block_list(index),reference_frame4);
                                intrapred_4=intrapred_4.block_creation4(count);
                                predicted_sub_block=intrapred_4.blocks;
                                predicted_sub_block.data=intrapred_4.smallblock_4;
                                predicted_sub_block = predicted_sub_block.setframeType(1);
                                predicted_sub_block.split=1;
                                predicted_sub_block.QP=QP-1;
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
                         cost=RDO(predicted_block.data,predictedblock_4,obj.block_height,obj.block_width,intrapred.SAD,SAD4,QP);
                        if(cost.flag==0)
                             obj.reconstructedVideo1(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1,i) = reference_frame1(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
                             obj.bitCountVideo1(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream1,2);
                             obj.OutputBitstream1 = [obj.OutputBitstream1 temp_bitstream1];
                             obj.bitPerFrame(i) = obj.bitPerFrame(i) + size(temp_bitstream1,2);
                             %obj.blockList = [obj.blockList predicted_block];
                             if RCflag == 3
                                obj.splitList1 = [obj.splitList1 0];
                             end
                             %obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predicted_block.data);
                        else
                             obj.reconstructedVideo1(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1,i) = reference_frame4(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
                             obj.bitCountVideo1(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream4,2);
                             obj.bitPerFrame(i) = obj.bitPerFrame(i) + size(temp_bitstream4,2);
                             obj.OutputBitstream1 = [obj.OutputBitstream1 temp_bitstream4];
%                              obj.blockList = [obj.blockList predicted_sub_block];
%                              obj.blockList = [obj.blockList predicted_sub_block];
%                              obj.blockList = [obj.blockList predicted_sub_block];
%                              obj.blockList = [obj.blockList predicted_sub_block];
                             if RCflag == 3
                                obj.splitList1 = [obj.splitList1 1];
                             end
                             %obj.predictionVideo(1:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predictedblock_4); 
                        end
                    end
                end
            else
                %inter
                block_list = obj.truncateFrameToBlocks(i,QP);
                length = size(block_list,2);
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
                            if obj.VBSEnable == false
                                ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo1(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                if ME_result.differenceForBestMatchBlock < min_value
                                    min_value = ME_result.differenceForBestMatchBlock;
                                    bestMatchBlock = ME_result.bestMatchBlock;
                                    bestMatchBlock.referenceFrameIndex = i - referenceframe_index;

                                end
                            else
                                ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo1(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                bestMatchBlockNoSplit = ME_result.bestMatchBlock;
                                bestMatchBlockNoSplit.referenceFrameIndex = i - referenceframe_index;

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
                                    SubBlockME_result = MotionEstimationEngine(obj.r,subBlock_list(subBlockIndex), uint8(obj.reconstructedVideo1(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
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
                                cost=RDO(bestMatchBlockNoSplit.data,predictedblock_4,obj.block_height,obj.block_width,ME_result.differenceForBestMatchBlock,SAD4,QP);
                                if(cost.flag~=0)
                                    % split has smaller RDO
                                    if cost.RDO_cost4 < min_value
                                        min_value = cost.RDO_cost4;
                                        bestMatchBlock = SubBlockList;
                                        if RCflag == 3
                                            obj.splitList1 = [obj.splitList1 1];
                                        end
                                    end
                                else
                                    % no split has smaller RDO
                                    if cost.RDO_cost1 < min_value
                                        min_value = cost.RDO_cost1;
                                        bestMatchBlock = bestMatchBlockNoSplit;
                                        if RCflag == 3
                                            obj.splitList1 = [obj.splitList1 0];
                                        end
                                    end
                                end
                            end
                         end
                     end
                     sumBitSize = 0;
                     for bestMatchBlockIndex = 1:1:size(bestMatchBlock,2)
                            %set the frame type for the block
                            bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setframeType(0);
                            %set QP for the block
                            if (size(bestMatchBlock,2) > 1) && QP >= 1
                                bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setQP(QP - 1);
                            else
                                bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setQP(QP);
                            end
                            %differential encoding for motion vector

                            tempPreviousMV = bestMatchBlock(bestMatchBlockIndex).MotionVector;
                            if RCflag == 3
                                obj.motionVectorList1 = [obj.motionVectorList1 tempPreviousMV];
                            end
                            bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setbitMotionVector( MotionVector(previousMV.x - bestMatchBlock(bestMatchBlockIndex).MotionVector.x, previousMV.y - bestMatchBlock(bestMatchBlockIndex).MotionVector.y));
                            previousMV = tempPreviousMV;

                            %differential encoding for reference frame index
                            tempPreviousFrameIndex = bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                            bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex = previousFrameIndex - bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                            previousFrameIndex = tempPreviousFrameIndex;
                            
                            obj.predictionVideo1(bestMatchBlock(bestMatchBlockIndex).top_height_index:bestMatchBlock(bestMatchBlockIndex).top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,bestMatchBlock(bestMatchBlockIndex).left_width_index:bestMatchBlock(bestMatchBlockIndex).left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(bestMatchBlock(bestMatchBlockIndex).data);
%                             obj.blockList = [obj.blockList bestMatchBlock(bestMatchBlockIndex)];
                            [processedBlock, en] = obj.generateReconstructedFrame(i,bestMatchBlock(bestMatchBlockIndex) );
                            obj.reconstructedVideo1(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(processedBlock.data);
                            obj.OutputBitstream1 = [obj.OutputBitstream1 en.bitstream];
                            sumBitSize = sumBitSize + size(en.bitstream,2);
                            obj.bitPerFrame(i) = obj.bitPerFrame(i) + size(en.bitstream,2);
                     end
                     obj.bitCountVideo1(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = sumBitSize;
                end
            end
            obj.SADPerFrame1 = [obj.SADPerFrame1 abs(sum(obj.reconstructedVideo1(:,:,i), 'all') - sum(obj.inputvideo.Y(:,:,i), 'all'))];
            fprintf("frame number %d is done\n", i);

        end
        
        function obj = encodeFrameSecondPass(obj, i, intra, bitBudget, reconstructedVideo,lastIFrame, splitList,motionVectorList)
            %initialize parameter for memorize the lastIFrame
            obj.reconstructedVideo2 = reconstructedVideo;
            obj.lastIFrame = lastIFrame;
            rowIndex = 1;
            obj.QPSumSecondPass = 0;
            obj.NumsBlocksSecondPass = 0;
            actualBitSpentCurrentRow = 0;
            obj.blockList = [];
            if intra == true
                obj.lastIFrame = i;
                %if intra frame
                %initialized the empty reconstructed frame for current
                %index i with zero.
                obj.reconstructedVideo2(:,:,i) = zeros( obj.inputvideo.width , obj.inputvideo.height);
                obj.lastIFrame = i;
                reference_frame1=[];
                reference_frame4=[];
                %truncate current frame to fix size block list
                %according to the input block size
                block_list = obj.truncateFrameToBlocks(i, obj.QP);
                length = size(block_list,2);
                for index=1:1:length
                    if block_list(index).top_height_index == rowIndex
                        obj.bitBudget = obj.bitBudget.computeQP(intra,actualBitSpentCurrentRow, i );
                        obj.QP = obj.bitBudget.QP;
                        rowIndex = rowIndex + obj.block_height;
                        actualBitSpentCurrentRow = 0;
                    end
                     intrapred=IntraPredictionEngine(block_list(index),obj.reconstructedVideo2(:,:,i));
                     intrapred=intrapred.block_creation();
                     if(obj.VBSEnable==0)
                         % if no VBS required, just direct do the intra
                         % prediction on the blocks
                         predicted_block=intrapred.blocks;
                         predicted_block.data=intrapred.predictedblock;
                         predicted_block.split=0;
                         predicted_block = predicted_block.setQP(obj.QP);
                         predicted_block = predicted_block.setframeType(1);
                         [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
                         obj.reconstructedVideo2(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                         obj.OutputBitstream2 = [obj.OutputBitstream2 en.bitstream];
                     else
                         %VBS required
                         %first do the full block prediction
                         if obj.bitBudget.RCflag == 2
                             temp_bitstream1=[];
                             predicted_block=intrapred.blocks;
                             predicted_block.data=intrapred.predictedblock;
                             predicted_block.split=0;
                             predicted_block = predicted_block.setframeType(1);
                             predicted_block = predicted_block.setQP(obj.QP);
                             [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
                             reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                             temp_bitstream1=en.bitstream;

                             %do the sub block prediction
                             count=1;
                             SAD4=zeros( 1 ,4);
                             mode4=zeros( 1 ,4);
                             temp_bitstream4=[];
                             predictedblock_4 = zeros( obj.block_width,obj.block_height);
                             reference_frame4 = obj.reconstructedVideo2(:,:,i);
                             for row_i =1:1:2
                                for col_i=1:1:2
                                    intrapred_4=IntraPredictionEngine(block_list(index),reference_frame4);
                                    intrapred_4=intrapred_4.block_creation4(count);
                                    predicted_sub_block=intrapred_4.blocks;
                                    predicted_sub_block.data=intrapred_4.smallblock_4;
                                    predicted_sub_block.split=1;
                                    predicted_sub_block.QP=obj.QP-1;
                                    predicted_sub_block = predicted_sub_block.setframeType(1);
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
                                 obj.reconstructedVideo2(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1,i) = reference_frame1(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
                                 obj.bitCountVideo2(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream1,2);
                                 obj.OutputBitstream2 = [obj.OutputBitstream2 temp_bitstream1];
                                 obj.QPSumSecondPass = obj.QPSumSecondPass + obj.QP;
                                 obj.NumsBlocksSecondPass = obj.NumsBlocksSecondPass + 1;
                                 actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_bitstream1,2);
%                                  obj.blockList = [obj.blockList predicted_block];
                                 %obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predicted_block.data);
                            else
                                 obj.reconstructedVideo2(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1,i) = reference_frame4(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
                                 obj.bitCountVideo2(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream4,2);

                                 obj.OutputBitstream2 = [obj.OutputBitstream2 temp_bitstream4];
                                 obj.QPSumSecondPass = obj.QPSumSecondPass + obj.QP * 4;
                                 obj.NumsBlocksSecondPass = obj.NumsBlocksSecondPass + 4;
                                 actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_bitstream4,2);
%                                 obj.blockList = [obj.blockList predicted_sub_block];
%                                  obj.blockList = [obj.blockList predicted_sub_block];
%                                  obj.blockList = [obj.blockList predicted_sub_block];
%                                  obj.blockList = [obj.blockList predicted_sub_block];
                                 %obj.predictionVideo(1:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predictedblock_4); 
                            end

                         else
                             %RCflag = 3

                             if (splitList(index) == 0)
                                 predicted_block=intrapred.blocks;
                                 predicted_block.data=intrapred.predictedblock;
                                 predicted_block.split=0;
                                 predicted_block = predicted_block.setQP(obj.QP);
                                 predicted_block = predicted_block.setframeType(1);
                                 [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
                                 reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                                 obj.reconstructedVideo2(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                                 obj.OutputBitstream2 = [obj.OutputBitstream2 en.bitstream];
                                 obj.reconstructedVideo2(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1,i) = reference_frame1(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
                                 obj.bitCountVideo2(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(en.bitstream,2);
                                 obj.OutputBitstream2 = [obj.OutputBitstream2 en.bitstream];
                                 obj.QPSumSecondPass = obj.QPSumSecondPass + obj.QP;
                                 obj.NumsBlocksSecondPass = obj.NumsBlocksSecondPass + 1;
                                 actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(en.bitstream,2);
%                                  obj.blockList = [obj.blockList predicted_block];
                             else
                                  %do the sub block prediction
                                 count=1;
                                 SAD4=zeros( 1 ,4);
                                 mode4=zeros( 1 ,4);
                                 temp_bitstream4=[];
                                 predictedblock_4 = zeros( obj.block_width,obj.block_height);
                                 reference_frame4 = obj.reconstructedVideo2(:,:,i);
                                 for row_i =1:1:2
                                    for col_i=1:1:2
                                        intrapred_4=IntraPredictionEngine(block_list(index),reference_frame4);
                                        intrapred_4=intrapred_4.block_creation4(count);
                                        predicted_sub_block=intrapred_4.blocks;
                                        predicted_sub_block.data=intrapred_4.smallblock_4;
                                        predicted_sub_block.split=1;
                                        predicted_sub_block.QP=obj.QP-1;
                                        predicted_sub_block = predicted_sub_block.setframeType(1);
                                        [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_sub_block );
                                        temp_bitstream4=[temp_bitstream4 en.bitstream];
                                        curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                        curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                        predictedblock_4(curr_row,curr_col)=intrapred_4.smallblock_4;
                                        reference_frame4(predicted_sub_block.top_height_index: predicted_sub_block.top_height_index + predicted_sub_block.block_height-1, predicted_sub_block.left_width_index: predicted_sub_block.left_width_index + predicted_sub_block.block_width-1) = uint8(processedBlock.data);
                                        SAD4(count)= intrapred_4.SAD_4;
                                        mode4(count)=predicted_sub_block.Mode;
                                        count=count+1;
                                        
                                         obj.reconstructedVideo2(intrapred.blocks.top_height_index:intrapred.blocks.top_height_index + obj.block_height-1,intrapred.blocks.left_width_index:intrapred.blocks.left_width_index + obj.block_width-1,i) = reference_frame4(intrapred.blocks.top_height_index:intrapred.blocks.top_height_index + obj.block_height-1,intrapred.blocks.left_width_index:intrapred.blocks.left_width_index + obj.block_width-1);
                                         obj.bitCountVideo2(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream4,2);

                                         obj.OutputBitstream2 = [obj.OutputBitstream2 temp_bitstream4];
                                         obj.QPSumSecondPass = obj.QPSumSecondPass + obj.QP * 4;
                                         obj.NumsBlocksSecondPass = obj.NumsBlocksSecondPass + 4;
                                         actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_bitstream4,2);
%                                          obj.blockList = [obj.blockList predicted_sub_block];
%                                          obj.blockList = [obj.blockList predicted_sub_block];
%                                          obj.blockList = [obj.blockList predicted_sub_block];
%                                          obj.blockList = [obj.blockList predicted_sub_block];
                                    end
                                end
                             end
                             
                         end          
                     end
                end
            else
                %inter
                
                block_list = obj.truncateFrameToBlocks(i,obj.QP);
                length = size(block_list,2);
                previousMV = MotionVector(0,0);
                previousFrameIndex = 0;
                count = 1;
                %for loop to go through all blocks
                for index=1:1:length
                    if block_list(index).top_height_index == rowIndex
                        obj.bitBudget = obj.bitBudget.computeQP(intra,actualBitSpentCurrentRow, i );
                        obj.QP = obj.bitBudget.QP;
                        rowIndex = rowIndex + obj.block_height;
                        actualBitSpentCurrentRow = 0;
                    end
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
                         if referenceframe_index >= obj.lastIFrame
                            if obj.VBSEnable == false
                                ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo2(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                if ME_result.differenceForBestMatchBlock < min_value
                                    min_value = ME_result.differenceForBestMatchBlock;
                                    bestMatchBlock = ME_result.bestMatchBlock;
                                    bestMatchBlock.referenceFrameIndex = i - referenceframe_index;

                                end
                            else
                                if obj.bitBudget.RCflag == 2
                                    ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo2(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                    bestMatchBlockNoSplit = ME_result.bestMatchBlock;
                                    bestMatchBlockNoSplit.referenceFrameIndex = i - referenceframe_index;

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
                                        SubBlockME_result = MotionEstimationEngine(obj.r,subBlock_list(subBlockIndex), uint8(obj.reconstructedVideo2(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
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
                                else
                                    %RCflag = 3
                                    if (splitList(index) == 0)
                                        motionVectorFirstPass = motionVectorList(count);
                                        originalBlock = block_list(index);
                                        originalBlock.left_width_index = originalBlock.left_width_index + motionVectorFirstPass.x;
                                        originalBlock.top_height_index = originalBlock.top_height_index + motionVectorFirstPass.y;
                                        ME_result = MotionEstimationEngine(obj.searchRangeRC3,originalBlock, uint8(obj.reconstructedVideo2(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                        bestMatchBlock = ME_result.bestMatchBlock;
                                        bestMatchBlock.left_width_index = originalBlock.left_width_index;
                                        bestMatchBlock.top_height_index = originalBlock.top_height_index;
                                        bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                        count = count + 1;
                                    else
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
                                            motionVectorFirstPass = motionVectorList(count);
                                            originalBlock = subBlock_list(subBlockIndex);
                                            originalBlock.left_width_index = originalBlock.left_width_index + motionVectorFirstPass.x;
                                            originalBlock.top_height_index = originalBlock.top_height_index + motionVectorFirstPass.y;
                                            SubBlockME_result = MotionEstimationEngine(obj.searchRangeRC3,originalBlock, uint8(obj.reconstructedVideo2(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
                                            
                                            SAD4(col_i + (row_i - 1) * 2)= SubBlockME_result.differenceForBestMatchBlock;
                                            SubBlockME_result.bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                            SubBlockME_result.bestMatchBlock.split=1;
                                            SubBlockME_result.bestMatchBlock.left_width_index = originalBlock.left_width_index;
                                            SubBlockME_result.bestMatchBlock.top_height_index = originalBlock.top_height_index;
                                            previousMVSubBlock = SubBlockME_result.bestMatchBlock.MotionVector;    
                                            curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                            curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                            predictedblock_4(curr_row,curr_col)=SubBlockME_result.bestMatchBlock.data;
                                            bestMatchBlock = [bestMatchBlock SubBlockME_result.bestMatchBlock];
                                            col_i = col_i + 1;
                                            count = count + 1;
                                            if col_i > 2
                                                row_i = row_i + 1;
                                                col_i = 1;
                                            end
                                        end  
                                    end    
                                end
                            end
                         end
                     end

                     for bestMatchBlockIndex = 1:1:size(bestMatchBlock,2)
                            %set the frame type for the block
                            bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setframeType(0);
                            %set QP for the block
                            if (size(bestMatchBlock,2) > 1) && obj.QP >= 1
                                bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setQP(obj.QP - 1);
                                obj.QPSumSecondPass = obj.QPSumSecondPass + obj.QP - 1;
                            else
                                bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setQP(obj.QP);
                                obj.QPSumSecondPass = obj.QPSumSecondPass + obj.QP;
                            end
                            %differential encoding for motion vector
                            tempPreviousMV = bestMatchBlock(bestMatchBlockIndex).MotionVector;
                            bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setbitMotionVector( MotionVector(previousMV.x - bestMatchBlock(bestMatchBlockIndex).MotionVector.x, previousMV.y - bestMatchBlock(bestMatchBlockIndex).MotionVector.y));
                            previousMV = tempPreviousMV;
                            
                            %differential encoding for reference frame index
                            tempPreviousFrameIndex = bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                            bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex = previousFrameIndex - bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                            previousFrameIndex = tempPreviousFrameIndex;

                            obj.predictionVideo2(bestMatchBlock(bestMatchBlockIndex).top_height_index:bestMatchBlock(bestMatchBlockIndex).top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,bestMatchBlock(bestMatchBlockIndex).left_width_index:bestMatchBlock(bestMatchBlockIndex).left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(bestMatchBlock(bestMatchBlockIndex).data);

                            [processedBlock, en] = obj.generateReconstructedFrame(i,bestMatchBlock(bestMatchBlockIndex) );
                            obj.reconstructedVideo2(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(processedBlock.data);
                            obj.OutputBitstream2 = [obj.OutputBitstream2 en.bitstream];
                            obj.bitCountVideo2(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(en.bitstream,2);
                            obj.NumsBlocksSecondPass = obj.NumsBlocksSecondPass + 1;
                            actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(en.bitstream,2);
%                             obj.blockList = [obj.blockList bestMatchBlock(bestMatchBlockIndex)];
                     end
                end
            end
            obj.SADPerFrame2 = [obj.SADPerFrame2 abs(sum(obj.reconstructedVideo2(:,:,i), 'all') - sum(obj.inputvideo.Y(:,:,i), 'all'))];
            fprintf("frame number %d is done\n", i);

        end

        function blockList = truncateFrameToBlocks(obj,frameIndex, QP)
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
                    currentBlock = currentBlock.setQP(QP);
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
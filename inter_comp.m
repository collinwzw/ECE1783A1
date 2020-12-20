function [new_frame,OutputBitstream] = inter_comp(obj,l,reference_frame,lastIFrame,type,start,stop)
block_list = obj.truncateFrameToBlocks(l);
length = size(block_list,2);
previousMV = MotionVector(0,0);
previousFrameIndex = 0;
OutputBitstream=[];
% disp(l)
%for loop to go through all blocks
for index=start:1:stop
    %RDO computation of block_list(index)
    %if futher truncate
    % if not do one time
    %doing the truncation
    %split or not
    %
    
    min_value = 9999999;
    % for loop to go through multiple reference frame
    % to get best matched block
    for referenceframe_index = l - obj.nRefFrame: 1 : l-1
        % check starts from last I frame or input parameter nRefFrame.
        if referenceframe_index >= lastIFrame
            if obj.VBSEnable == false
                ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(reference_frame(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                if ME_result.differenceForBestMatchBlock < min_value
                    min_value = ME_result.differenceForBestMatchBlock;
                    bestMatchBlock = ME_result.bestMatchBlock;
                    bestMatchBlock.referenceFrameIndex = l - referenceframe_index;
                    
                end
            else
                ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(reference_frame(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                bestMatchBlockNoSplit = ME_result.bestMatchBlock;
                bestMatchBlockNoSplit.referenceFrameIndex = l - referenceframe_index;
                
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
                    SubBlockME_result = MotionEstimationEngine(obj.r,subBlock_list(subBlockIndex), uint8(reference_frame(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
                    SAD4(col_i + (row_i - 1) * 2)= SubBlockME_result.differenceForBestMatchBlock;
                    SubBlockME_result.bestMatchBlock.referenceFrameIndex = l - referenceframe_index;
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
        bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setframeType(type(l));
        
        %differential encoding for motion vector
        tempPreviousMV = bestMatchBlock(bestMatchBlockIndex).MotionVector;
        bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setbitMotionVector( MotionVector(previousMV.x - bestMatchBlock(bestMatchBlockIndex).MotionVector.x, previousMV.y - bestMatchBlock(bestMatchBlockIndex).MotionVector.y));
        previousMV = tempPreviousMV;
        
        %differential encoding for reference frame index
        tempPreviousFrameIndex = bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
        bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex = previousFrameIndex - bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
        previousFrameIndex = tempPreviousFrameIndex;
        
        %                                 obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(bestMatchBlock(bestMatchBlockIndex).data);
        
        [processedBlock, en] = obj.generateReconstructedFrame(l,bestMatchBlock(bestMatchBlockIndex) );
        new_frame(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1) = uint8(processedBlock.data);
        OutputBitstream = [OutputBitstream en.bitstream];
    end
end
end


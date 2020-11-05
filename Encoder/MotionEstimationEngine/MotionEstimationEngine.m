classdef MotionEstimationEngine

    properties (GetAccess='public', SetAccess='public')
        r;
        block_width;
        block_height;
        currentBlock;
        referenceFrame;
        blocks;
        predictedFrame;
        reconstructed
        bestMatchBlock;
    end
    
    methods(Access = 'public')
        function obj = MotionEstimationEngine(r,currentBlock, referenceFrame, block_width, block_height)

            obj.r = r;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.currentBlock = currentBlock;
            obj.referenceFrame = referenceFrame; 
            referenceBlockList = obj.getAllBlocks( currentBlock.left_width_index, currentBlock.top_height_index); 
            bestMatchBlockUnprocessed = obj.findBestPredictedBlockSAD(referenceBlockList,currentBlock.getBlockSumValue());
            obj.bestMatchBlock = currentBlock;
            obj.bestMatchBlock.data = bestMatchBlockUnprocessed.data;
        end
        
%         function obj = truncateBlock(obj)
%             %This function truncate the frame and reference to blocks.
%             %from each truncated block in current frame, it gets the best
%             % matched block from reference frame according to given r
%             %then it gets the residualBlock from best matched block minus
%             %current block. 
%                 col = 1;
%                 row = 1;
%                 for i=1:obj.block_height:size(obj.currentFrame,1)  
%                     for j=1:obj.block_width:size(obj.currentFrame,2)
%                         currentBlock = Block(obj.currentFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
%                         referenceBlockList = obj.getAllBlocks( i, j  );
%                         bestMatchBlock = obj.findBestPredictedBlockSAD(referenceBlockList,currentBlock.getBlockSumValue());
%                         residualBlock =  int16(currentBlock.data) -int16(bestMatchBlock.data) ;                   
%                         obj.predictedFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = (obj.referenceFrame( bestMatchBlock.top_height_index: bestMatchBlock.top_height_index + obj.block_height - 1, bestMatchBlock.left_width_index: bestMatchBlock.left_width_index + obj.block_width -1));
%                         obj.residualFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = residualBlock;
%                         
%                         obj.blocks(row,col) = bestMatchBlock.MotionVector.x;
%                         obj.blocks(row,col+1) = bestMatchBlock.MotionVector.y;
%                         col = col + 2;
%                     end
%                     row = row + 1;
%                     col = 1;
%                 end        
%                 reconstructed_cal = int16(obj.predictedFrame(:,:,1)) + int16(obj.residualFrame(:,:,1));
%                 %reconstructed_cal = int8(obj.predictedFrame(:,:,1)) + uint8(obj.residualFrame(:,:,1));
%                 obj.reconstructed = uint8(reconstructed_cal);
%                 obj.predictedFrame = uint8(obj.predictedFrame);
%                 obj.residualFrame = uint8(obj.residualFrame);
%                 %obj.residualFrame = obj.residualFrame;
% %                 subplot(1,5,1), imshow(obj.currentFrame(:,:,1))
% %                 subplot(1,5,2), imshow(obj.referenceFrame(:,:,1))
% %                 subplot(1,5,3), imshow(obj.predictedFrame(:,:,1))
% %                 subplot(1,5,4), imshow(obj.residualFrame(:,:,1))
% %                 
% %                 subplot(1,5,5), imshow(obj.reconstructed(:,:,1))                
%         end
        
        function result = roundBlock(obj,r, n)
            mutliple = 2^n;
            result = r;
            for i=1:1:size(r,2)
                for j=1:1:size(r,1)
                        if mod(r(i,j), mutliple) ~= 0
                            if mod(r(i,j), mutliple)>= mutliple/2
                                %rounding up
                                result(i,j) = (mutliple - mod(r(i,j), mutliple)) + r(i,j);
                            else
                                %round down
                                result(i,j) = r(i,j) - mod(r(i,j), mutliple); 
                            end
                       
                        end
                        
                end
                   
                    end
                   
        
                end

        
        
        function blockList = getAllBlocks(obj, row, col )
            %according to the given position of (row,col), get all the
            %possible candidate blocks from reference frame
            % initialize i  and i end 
            if (row - obj.r < 1)
                i_start = 1;
                i_end = row + obj.r;
            else
                i_start = row - obj.r;
                if (row + obj.block_height + obj.r > size(obj.referenceFrame,1))
                    i_end = row;
                else
                    i_end = row + obj.r;
                end
            end
            % initialize j  and j end 
            if (col - obj.r < 1)
                j_start = 1;
                j_end = col + obj.r;
            else
                j_start = col - obj.r;
                
                if (col + obj.block_width + obj.r > size(obj.referenceFrame,2))
                    j_end = col;
                else
                    j_end = col + obj.r;
                end
            end

            blockList = [];
            for i=i_start:1:i_end
                    for j=j_start:1:j_end
                        b =  Block(obj.referenceFrame, j,i, obj.block_width, obj.block_height);
                        b= b.setbitMotionVector(MotionVector(i-row,j - col));
                        blockList = [blockList b];
                    end
            end      
        end
        
        function r = findBestPredictedBlockSAD(obj, referenceBlockList, currentBlockSum)
            minimumValue = 9999999;
            for i = 1: 1 : length(referenceBlockList)
                diff = abs( currentBlockSum - referenceBlockList(i).getBlockSumValue());
                if (diff < minimumValue)
                    minimumValue = diff;
                    r = referenceBlockList(i);
                elseif diff == minimumValue %case of tie
                    if (referenceBlockList(i).MotionVector.getL1Norm() < r.MotionVector.getL1Norm())
                        r = referenceBlockList(i);
                    elseif (referenceBlockList(i).MotionVector.getL1Norm() == r.MotionVector.getL1Norm())
                            if (referenceBlockList(i).left_width_index < r.left_width_index)
                                r = referenceBlockList(i);
                            end
                    end        
                end
            end
        end

        function result = calculateBlockSumValue(obj, frame)
            block = frame(obj.left_width_index: obj.left_width_index + obj.block_width, height_index: height_index + obj.block_height);
            result=round(mean(block,'all'));
        end
    end
    
end

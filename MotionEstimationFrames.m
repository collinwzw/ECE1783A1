classdef MotionEstimationFrames

    properties (GetAccess='public', SetAccess='public')
        r;
        block_width;
        block_height;
        currentFrame;
        referenceFrame;
        blocks;
        predictedFrame;
        residualFrame;
    end
    
    methods(Access = 'public')
        function obj = MotionEstimationFrames(r,currentFrame, referenceFrame, block_width, block_height)
            if ( size(currentFrame,2) ~= size(referenceFrame,2) || size(currentFrame,1) ~= size(referenceFrame,1) )
                    ME = MException('input currentframe size is not equal to referenceFrame size');
                    throw(ME)
            end
            
            obj.r = r;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.currentFrame = currentFrame;
            obj.referenceFrame = referenceFrame; 
            
        end
        
        function obj = truncateBlock(obj)
            %This function truncate the frame and reference to blocks.
            %from each truncated block in current frame, it gets the best
            % matched block from reference frame according to given r
            %then it gets the residualBlock from best matched block minus
            %current block. 
                for i=1:obj.block_height:size(obj.currentFrame,1)
                    for j=1:obj.block_width:size(obj.currentFrame,2)
                        currentBlock = Block(obj.currentFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
                        referenceBlockList = obj.getAllBlocks( i, j  );
                        bestMatchBlock = obj.findBestPredictedBlockSAD(referenceBlockList,currentBlock.getBlockSumValue());
                        residualBlock =  int32(bestMatchBlock.data) - int32(currentBlock.data);
                        residualBlock = uint8( abs(residualBlock));
                        r = obj.roundBlock(residualBlock);
                        obj.predictedFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = (obj.referenceFrame( bestMatchBlock.top_height_index: bestMatchBlock.top_height_index + obj.block_height - 1, bestMatchBlock.left_width_index: bestMatchBlock.left_width_index + obj.block_width -1));
                        obj.residualFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = r;
                        obj.blocks = [obj.blocks; currentBlock];
                    end
                end        
                obj.predictedFrame = uint8(obj.predictedFrame);
                obj.residualFrame = uint8(obj.residualFrame);
                
                subplot(1,5,1), imshow(obj.currentFrame(:,:,1))
                subplot(1,5,2), imshow(obj.referenceFrame(:,:,1))
                subplot(1,5,3), imshow(obj.predictedFrame(:,:,1))
                subplot(1,5,4), imshow(obj.residualFrame(:,:,1))
                reconstructed = obj.predictedFrame(:,:,1) + obj.residualFrame(:,:,1);
                subplot(1,5,5), imshow(reconstructed(:,:,1))                
        end
        
        function r = roundBlock(obj,residualBlock)
            p =  nextpow2(residualBlock);
            np2 = 2.^p;
            r = np2.*sign(residualBlock);
            for i=1:1:size(residualBlock,2)
                for j=1:1:size(residualBlock,1)
                    if ( abs(r(i,j) - residualBlock(i,j)) > abs(residualBlock(i,j) - r(i,j)/2) )   % -128 - (-90)= -38 > abs(-90 - (-64)) = 26
                        r(i,j) = r(i,j)/2;
                    else
                   
                    end
                   
        
                end
            end
        end
        
        
        function blockList = getAllBlocks(obj, row, col )
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
                        blockList = [blockList; Block(obj.referenceFrame, j,i, obj.block_width, obj.block_height, MotionVector(i-row,j - col) )];
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

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
            if ( width(currentFrame) ~= width(referenceFrame) || height(currentFrame) ~= height(referenceFrame) )
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
                for i=1:obj.block_height:height(obj.currentFrame)
                    for j=1:obj.block_width:width(obj.currentFrame)
                        currentBlock = Block(obj.currentFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
                        referenceBlockList = obj.getAllBlocks( i, j  );
                        bestMatchBlock = obj.findBestPredictedBlockSAD(referenceBlockList,currentBlock.getBlockSumValue())
                        residualBlock =  bestMatchBlock.data - currentBlock.data;
                        r = obj.roundBlock(residualBlock);
                        obj.predictedFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = (obj.referenceFrame( bestMatchBlock.top_height_index: bestMatchBlock.top_height_index + obj.block_height - 1, bestMatchBlock.left_width_index: bestMatchBlock.left_width_index + obj.block_width -1));
                        obj.residualFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = r;
                        obj.blocks = [obj.blocks; currentBlock];
                    end
                end        
                obj.predictedFrame = uint8(obj.predictedFrame);
                obj.residualFrame = uint8(obj.residualFrame);
        end
        
        function r = roundBlock(obj,residualBlock)
            p =  nextpow2(residualBlock);
            np2 = 2.^p;
            r = np2.*sign(residualBlock);
            for i=1:1:width(residualBlock)
                for j=1:1:height(residualBlock)
                    if ( abs(r(i,j) - residualBlock(i,j)) > abs(residualBlock(i,j) - r(i,j)/2) )   % -128 - (-90)= -38 > abs(-90 - (-64)) = 26
                        r(i,j) = r(i,j)/2;
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
                if (row + obj.block_height + obj.r > height(obj.referenceFrame))
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
                
                if (col + obj.block_width + obj.r > width(obj.referenceFrame))
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

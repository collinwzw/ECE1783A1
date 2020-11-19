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
        differenceForBestMatchBlock;
        FastME;
        
    end
    
    methods(Access = 'public')
        function obj = MotionEstimationEngine(r,currentBlock, referenceFrame, block_width, block_height, FEMEnable, FastME, MVP)
            obj.r = r;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.currentBlock = currentBlock;
            obj.referenceFrame = referenceFrame;
            
            if FastME == true
                obj.bestMatchBlock = obj.NNSearch(referenceFrame,currentBlock, MVP);     
                obj.differenceForBestMatchBlock = abs( currentBlock.getBlockSumValue() - obj.bestMatchBlock.getBlockSumValue());
            else
                if FEMEnable == false
                    referenceBlockList = obj.getAllBlocks( currentBlock.left_width_index, currentBlock.top_height_index); 
                else
                    referenceBlockList = obj.getAllBlocksFME( currentBlock.left_width_index, currentBlock.top_height_index); 
                end
                bestMatchBlockUnprocessed = obj.findBestPredictedBlockSAD(referenceBlockList,currentBlock.getBlockSumValue());
                obj.differenceForBestMatchBlock = abs( currentBlock.getBlockSumValue() - bestMatchBlockUnprocessed.getBlockSumValue());
                obj.bestMatchBlock = currentBlock;
                obj.bestMatchBlock.data = bestMatchBlockUnprocessed.data;
                obj.bestMatchBlock.MotionVector = referenceBlockList.MotionVector;
            end
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

        
        
        function blockList = getAllBlocks(obj,col, row )
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
                        b= b.setbitMotionVector(MotionVector(j - col,i-row));
                        blockList = [blockList b];
                    end
            end      
        end
        function result = getSearchWindow(obj, col, row)
            %according to the given position of (row,col), get the search
            %window
            if (row - obj.r < 1)
                i_start = 1;
                i_end = row + obj.block_height + obj.r - 1;
            else
                i_start = row - obj.r;
                if (row + obj.block_height + obj.r > size(obj.referenceFrame,1))
                    i_end = row + obj.block_height - 1 ;
                else
                    i_end = row + obj.r + obj.block_height - 1 ;
                end
            end
            % initialize j  and j end 
            if (col - obj.r < 1)
                j_start = 1;
                j_end = col + obj.block_width + obj.r - 1;
            else
                j_start = col - obj.r;
                
                if (col + obj.block_width + obj.r > size(obj.referenceFrame,2))
                    j_end = col + obj.block_width - 1;
                else
                    j_end = col + obj.block_width + obj.r - 1;
                end
            end
            result = obj.referenceFrame( i_start:i_end , j_start:j_end);
        end
        
        function blockList = getAllBlocksFME(obj,col, row )
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
                
                for i=i_start:1:i_end
                        for j=j_start:1:j_end
                            b =  Block(obj.referenceFrame, j,i, obj.block_width, obj.block_height);
                            b = b.setbitMotionVector(MotionVector(j - col,i-row));
                            originalblockMatrix(i- i_start + 1,j- j_start + 1).class =b;
                        end                        
                end      
        
            if (row - 2 * obj.r < 1)
                i_start = 1;
                i_end = row + 2 * obj.r;
            else
                i_start = row - 2 * obj.r;
                if (row + obj.block_height + 2 * obj.r > size(obj.referenceFrame,1))
                    i_end = row;
                else
                    i_end = row + 2 * obj.r;
                end
            end
            % initialize j  and j end 
            if (col - 2* obj.r < 1)
                j_start = 1;
                j_end = col + 2 * obj.r;
            else
                j_start = col - 2 * obj.r;
                
                if (col + obj.block_width + 2 * obj.r > size(obj.referenceFrame,2))
                    j_end = col;
                else
                    j_end = col + 2 * obj.r;
                end
            end
            
            i_count = 1;     
            for i=i_start:1:i_end
                j_count = 1;
                    for j=j_start:1:j_end
                        if rem( abs(i - row), 2)==0 && rem( abs(j - col), 2) == 0                        
                            blockMatrix(i - i_start + 1,j - j_start + 1)=originalblockMatrix(i_count,j_count);
                            blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector  = blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.changeY( blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.y * 2);
                            blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector  = blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.changeX( blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.x * 2);
                            if j_count < size(originalblockMatrix,2)
                                j_count = j_count + 1;
                            end
                        else                          
                        end                        
                    end
                    if i_count < size(originalblockMatrix,1)
                        i_count = i_count + 1;
                    end
            end 
            
            for i=i_start:1:i_end
                    for j=j_start:1:j_end
                        if rem( abs(i - row), 2)~=0 && rem( abs(j - col), 2) == 0                                  
                            blockMatrix(i - i_start + 1,j - j_start + 1) =blockMatrix(i - i_start,j - j_start + 1);
                            block1 = blockMatrix(i - i_start,j - j_start + 1).class.data;
                            block2 = blockMatrix(i - i_start + 2,j - j_start + 1).class.data;
                            blockMatrix(i - i_start + 1,j - j_start + 1).class = blockMatrix(i - i_start + 1,j - j_start + 1).class.setData(uint8((uint16(block1) + uint16(block2))/2));
                            blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector =blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.changeY( blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.y + 1);       
                        end 
                        if rem( abs(i - row), 2)==0 && rem( abs(j - col), 2) ~= 0                                  
                            blockMatrix(i - i_start + 1,j - j_start + 1) =blockMatrix(i - i_start + 1,j - j_start);      
                            block1 = blockMatrix(i - i_start + 1,j - j_start).class.data;
                            block2 = blockMatrix(i - i_start + 1,j - j_start + 2).class.data;
                            blockMatrix(i - i_start + 1,j - j_start + 1).class = blockMatrix(i - i_start + 1,j - j_start + 1).class.setData(uint8((uint16(block1) + uint16(block2))/2));
                            blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector =blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.changeX( blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.x + 1);
                        end    
                    end
            end 
            for i=i_start:1:i_end
                    for j=j_start:1:j_end
                        if rem( abs(i - row), 2)~=0 && rem( abs(j - col), 2) ~= 0                                  
                            blockMatrix(i - i_start + 1,j - j_start + 1) =blockMatrix(i - i_start,j - j_start + 1);
                            block1 = blockMatrix(i - i_start,j - j_start + 1).class.data;
                            block2 = blockMatrix(i - i_start + 2,j - j_start + 1).class.data;
                            block3 = blockMatrix(i - i_start + 1,j - j_start).class.data;
                            block4 = blockMatrix(i - i_start + 1,j - j_start + 2).class.data;
                            blockMatrix(i - i_start + 1,j - j_start + 1).class = blockMatrix(i - i_start + 1,j - j_start + 1).class.setData(uint8((uint16(block1) + uint16(block2) + (uint16(block3) + uint16(block4))/4)));
                            blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector =blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.changeY( blockMatrix(i - i_start + 1,j - j_start + 1).class.MotionVector.y + 1);       
                        end 
                    end
            end 
            blockList = [];
            for k=1:1:size(blockMatrix,1)
                    for l=1:1:size(blockMatrix,2)
                        blockList = [blockList blockMatrix(k,l).class];
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

        function r = withInSearchWindown(obj, Block,referenceFrame, MotionVector)
            startingX = Block.left_width_index + MotionVector.x;
            if startingX <= 0 || startingX + Block.block_width - 1 > size(referenceFrame,2)
                r = false;
                return;
            end
            startingY = Block.top_height_index + MotionVector.y;
            if startingY <= 0 || startingY + Block.block_height -1 > size(referenceFrame,1)
                r = false;
                return;
            end
            r= true;
        end

        function r = getReferenceBlockByMV(obj, currentBlock, referenceFrame, MotionVector)
            if obj.withInSearchWindown( currentBlock,referenceFrame, MotionVector) == false
                r = 0;
            else
            r = Block(referenceFrame, currentBlock.left_width_index + MotionVector.x ,currentBlock.top_height_index + MotionVector.y, currentBlock.block_width, currentBlock.block_height);
            r = r.setbitMotionVector(MotionVector);
            r = r.setQP(currentBlock.QP);   
            end
        end
            

        
        function r = NNSearch(obj, referenceFrame, currentBlock, MVP)
            %set up initial minimum value to (0,0)
            originBlock = obj.getReferenceBlockByMV(currentBlock, referenceFrame , MotionVector(0,0));
            minimumValue = abs(currentBlock.getBlockSumValue() -originBlock.getBlockSumValue());
            
            %set up offset array
            MV = MVP;
            MVOffset = [MotionVector(0,0),MotionVector(0,1),MotionVector(-1,0),MotionVector(1,0),MotionVector(0,-1)];
            %get the block from previous block Motion Vector
            
            while 1
                blockList = [];
                for i = 1:1:size(MVOffset,2)
                    MVoff = MVOffset(i);
                    blk = obj.getReferenceBlockByMV(currentBlock, referenceFrame , MotionVector(MV.x + MVoff.x, MV.y + MVoff.y));
                    if isobject(blk)== 1 
                        blockList  = [ blockList blk];
                    end
                    
                end
                
                bestBlock = obj.findBestPredictedBlockSAD(blockList, currentBlock.getBlockSumValue());
                if isobject(blk)== 1 
                    r = originBlock;
                    break;
                else
                    if abs(currentBlock.getBlockSumValue() -bestBlock.getBlockSumValue()) < minimumValue
                        minimumValue = abs(currentBlock.getBlockSumValue() -bestBlock.getBlockSumValue());
                        originBlock = bestBlock;
                        MV = originBlock.MotionVector;
                    else

                        r = originBlock;
                        break;
                    end
                end
                
            end
% 
%             if matchedBlock ~=None
%                 if (abs(currentBlock.getBlockSumValue() -matchedBlock.getBlockSumValue()) < minimumValue)
%                     minimumValue = abs(currentBlock.getBlockSumValue() -bestBlock.getBlockSumValue());
%                     bestBlock = matchedBlock;
%                 end
%                 
%                 while 
%                 end
%                 
%             else
%                 % if the previous Motion vector is out of range. might
%                 % happen in corner case
%                 r = matchedBlock;
%             end
%             while (size(MVStack,1) ~= 0)
%                 MV = MVStack.pop();
%                 matchedBlock = obj.getReferenceBLockByMV(currentBlock, referenceFrame , MV);
%                 if matchedBlock ~= None
%                     
%                     
%                     if (abs(currentBlock.getBlockSumValue() -matchedBlock.getBlockSumValue()) < minimumValue)
%                         minimumValue = abs(currentBlock.getBlockSumValue() -bestBlock.getBlockSumValue());
%                         bestBlock = 
%                     end
%                     
%                 end
%             end
%             for i = 1: 1 : length(referenceBlockList)
%                 diff = abs( currentBlockSum - referenceBlockList(i).getBlockSumValue());
%                 if (diff < minimumValue)
%                     minimumValue = diff;
%                     r = referenceBlockList(i);
%                 elseif diff == minimumValue %case of tie
%                     if (referenceBlockList(i).MotionVector.getL1Norm() < r.MotionVector.getL1Norm())
%                         r = referenceBlockList(i);
%                     elseif (referenceBlockList(i).MotionVector.getL1Norm() == r.MotionVector.getL1Norm())
%                             if (referenceBlockList(i).left_width_index < r.left_width_index)
%                                 r = referenceBlockList(i);
%                             end
%                     end        
%                 end
%             end
            
         end
        
        function result = calculateBlockSumValue(obj, frame)
            block = frame(obj.left_width_index: obj.left_width_index + obj.block_width, height_index: height_index + obj.block_height);
            result=round(mean(block,'all'));
        end
    end
    
end

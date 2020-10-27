classdef EntropyEngine
   properties (GetAccess='public', SetAccess='public')
        quantizedTransformedFrame; %type Frame
        qMatrix; %int[height][width]
        quantizationParameter; %int
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
        result; %Frame
    end
    
    methods(Access = 'public')
        function obj = EntropyEngine(quantizedTransformedFrame,block_width,block_height)
            obj.quantizedTransformedFrame = quantizedTransformedFrame;
            obj.block_width = block_width;
            obj.block_height = block_height;
            currentBlock = Block(obj.quantizedTransformedFrame, 1,1, obj.block_width, obj.block_height, MotionVector(0,0) );
            obj.result = obj.reorderBlock(currentBlock);
        end
        
        
    end
    methods(Access = 'private')
%         function entropilizeFrame()
%            for i=1:obj.block_height:size(obj.transformCoefficientFrame,1)  
%                 for j=1:obj.block_width:size(obj.transformCoefficientFrame,2)
%                         reorderedList = 
%                 end
%             end        
%         end
        
        function r = reorderBlock(obj,block)
                % reordering the element in a block
                r = {};
                %reordering upper left top part of block
                for y=1:1:obj.block_width
                    x = 1;
                    while y >=1
                        r = [r,block.data(x,y)];
                        y = y -1;
                        x = x + 1;
                    end
                end
                
                %reordering the element in right bottom part of block
                for x=2:1:obj.block_height
                    y = obj.block_width;
                    while x <= obj.block_height
                        r = [r,block.data(x,y)];
                        y = y - 1;
                        x = x + 1;
                    end
                end
            end
        end
    end

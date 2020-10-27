classdef EntropyEngine
   properties (GetAccess='public', SetAccess='public')
        quantizedTransformedFrame; %type Frame
        qMatrix; %int[height][width]
        quantizationParameter; %int
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
        reorderedList; %array
        encodereorderedList; %array
        bitstream;
    end
    
    methods(Access = 'public')
        function obj = EntropyEngine(quantizedTransformedFrame,block_width,block_height)
            obj.quantizedTransformedFrame = quantizedTransformedFrame;
            obj.block_width = block_width;
            obj.block_height = block_height;
            currentBlock = Block(obj.quantizedTransformedFrame, 1,1, obj.block_width, obj.block_height, MotionVector(0,0) );
            obj.reorderedList = obj.reorderBlock(currentBlock);
            obj = obj.encodeReorderedList();
            
        end
       function r = encodeExpGolombValue(~,value)
            if value > 0
                value = 2*value - 1;
            else
                value = -2 * value;
            end
            r = '';
            M = floor(log2(value + 1));
            info = dec2bin(value + 1 - 2^M,M);
            for j=1:M
                r = [r '0'];
            end
            r = [r '1'];
            r = [r info];
       end
        
      function obj = encodeExpGolomblist(obj)
           obj.bitstream = '';
           for i=1:1:size(obj.encodereorderedList,2)
               bits =  obj.encodeExpGolombValue((obj.encodereorderedList(i)));
               obj.bitstream = [obj.bitstream, bits];
           end
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
                r = [];
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
        
        function obj = encodeReorderedList(obj)
            %take reordered list and encode it
            left = 1;
            right = 1;
            count = 0;
            while right <= size(obj.reorderedList,2)
                if obj.isZero(obj.reorderedList(right)) ~= obj.isZero(obj.reorderedList(left))
                    noElements = right - left;
                    if obj.isZero(obj.reorderedList(left)) == 1
                        % the left pointer pointing at zero
                        if left == 1
                            obj.encodereorderedList = [noElements obj.encodereorderedList];
                        else
                            obj.encodereorderedList = [obj.encodereorderedList noElements];
                        end
                    else
                        % the left pointer pointing at non-zero element
                        if left == 1
                            obj.encodereorderedList = [-noElements obj.reorderedList(left:right - 1)];
                        else
                            obj.encodereorderedList = [obj.encodereorderedList -noElements obj.reorderedList(left:right - 1)];
                        end
                        
                    end
                    left = right;
                else
                    right = right + 1;

                end
            end
            %finish of while loop
            
            if left ~= right
                %in case left is not equal to right
               if  obj.isZero(obj.reorderedList(left)) == 1
                    obj.encodereorderedList = [obj.encodereorderedList 0];
               else
                   noElements = right - left;
                   obj.encodereorderedList = [obj.encodereorderedList -noElements obj.reorderedList(left:right - 1 )];
               end
            
            end
        end
        
        function r = isZero(~,value)
            %helper function to assert if a number is 0 or not. return 1 if
            %it's zero, return 0 if it's non zero
             r = value== 0
        end
        

       


    end
end

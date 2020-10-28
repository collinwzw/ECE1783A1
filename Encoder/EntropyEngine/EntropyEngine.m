classdef EntropyEngine
   properties (GetAccess='public', SetAccess='public')
        quantizedTransformedFrame; %type Frame
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
        bitstream;
    end
    
    methods(Access = 'public')
        function obj = EntropyEngine(quantizedTransformedFrame,block_width,block_height)
            obj.quantizedTransformedFrame = quantizedTransformedFrame;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj = obj.entropilizeFrame();

            
        end
       function r = encodeExpGolombValue(~,value)
            if value > 0
                value = 2*value - 1;
            else
                value = -2 * value;
            end
            r = '';
            M = floor(log2(double(value) + 1));
            info = dec2bin(value + 1 - 2^M,M);
            for j=1:M
                r = [r '0'];
            end
            r = [r '1'];
            r = [r info];
       end
        
      function bitstream = encodeExpGolomblist(obj, list)
           bitstream = '';
           for i=1:1:size(list,2)
               bits =  obj.encodeExpGolombValue((list(i)));
               bitstream = [bitstream, bits];
           end
      end
       
    end
    
    methods(Access = 'private')
        function obj = entropilizeFrame(obj)
           for i=1:obj.block_height:size(obj.quantizedTransformedFrame,1)  
                for j=1:obj.block_width:size(obj.quantizedTransformedFrame,2)
                    currentBlock = Block(obj.quantizedTransformedFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
                    reorderedList = obj.reorderBlock((currentBlock));
                    encodedReorderedList = obj.encodeReorderedList(reorderedList);
                    obj.bitstream = [obj.bitstream obj.encodeExpGolomblist(encodedReorderedList)];

                end
            end        
        end
        
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
        
        function encodeReorderedList = encodeReorderedList(obj, list)
            %take reordered list and encode it
            left = 1;
            right = 1;
            count = 0;
            encodeReorderedList = [];
            while right <= size(list,2)
                if obj.isZero(list(right)) ~= obj.isZero(list(left))
                    noElements = right - left;
                    if obj.isZero(list(left)) == 1
                        % the left pointer pointing at zero
                        if left == 1
                            encodeReorderedList = [noElements encodeReorderedList];
                        else
                            encodeReorderedList = [encodeReorderedList noElements];
                        end
                    else
                        % the left pointer pointing at non-zero element
                        if left == 1
                            encodeReorderedList = [-noElements list(left:right - 1)];
                        else
                            encodeReorderedList = [encodeReorderedList -noElements list(left:right - 1)];
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
               if  obj.isZero(list(left)) == 1
                    encodeReorderedList = [encodeReorderedList 0];
               else
                   noElements = right - left;
                   encodeReorderedList = [encodeReorderedList -noElements list(left:right - 1 )];
               end
            
            end
        end
        
        function r = isZero(~,value)
            %helper function to assert if a number is 0 or not. return 1 if
            %it's zero, return 0 if it's non zero
             r = value== 0;
        end
        

       


    end
end

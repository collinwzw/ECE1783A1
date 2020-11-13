classdef EntropyEngine_Block
   properties (GetAccess='public', SetAccess='public')
        quantizedTransformedFrame; %type Frame
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
        bitstream;
        predictionInfoBitstream;
        motionVector;
        mode;
        QP;
        splitList;
        BlockList;
        splitindex;
    end
    
    methods(Access = 'public')
        function obj = EntropyEngine_Block()
        end
        
        
        function obj = EntropyEngineI(obj,quantizedTransformedFrame, mode, block_width,block_height, QP)
            obj.mode = mode;
            obj.quantizedTransformedFrame = quantizedTransformedFrame;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.QP = QP;
            obj = obj.entropilizeFrame();
            obj = obj.entroplizeI();
        end
        
        function obj = EntropyEngineP(obj,quantizedTransformedFrame,motionVector, block_width,block_height,QP)
            obj.motionVector = motionVector;
            obj.quantizedTransformedFrame = quantizedTransformedFrame;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.QP = QP;
            obj = obj.entropilizeFrame();
            obj = obj.entroplizeP();
        end
        
        function obj = EntropyEngineB(obj,BlockList)
            obj.BlockList=BlockList;
            index=0;
            obj.splitindex=0;
            while index <= length(BlockList)
                B_left_width_index=BlockList[index].left_width_index;
                B_top_height_index=BlockList[index].top_height_index;
                B_block_width=BlockList[index].block_width;
                B_block_height=BlockList[index].block_height;
                B_MotionVector=BlockList[index].MotionVector;
                B_Mode=BlockList[index].Mode;
                B_BlockSumValue=BlockList[index].BlockSumValue;
                B_data=BlockList[index].data;
                B_QP=BlockList[index].QP;% QP value for quantization
                B_frameType=BlockList[index].frameType; % 
                B_bitStream=BlockList[index].bitStream;
                B_referenceFrameIndex=BlockList[index].referenceFrameIndex;
                B_split=BlockList[index].split;
                %Type
                obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_frameType)];
                %   Mode /   RefF+Mv
                if B_frameType==0
                    obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_referenceFrameIndex)];
                    obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_MotionVector(1,1))];
                    obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_MotionVector(1,2))];
                elseif B_frameType==1
                    obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_Mode)];
                    %%%%%%%%%%%%%
                    %%%%%%%%%%
                    %%%%%%%%%%%
                    %%%%%%%%%
                else
                    print("Error");
                end
                
                %Split
                if B_split ==1
                    obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_split)];
                    obj.splitindex=obj.splitindex+1;
                else 
                    obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_split)];
                    obj.splitindex=0;
                end
                
                %QP
                obj.bitstream = [obj.bitstream obj.encodeExpGolombValue(B_QP)];
                
                %Data
                currentBlock=B_data;
                reorderedList = obj.reorderBlock((currentBlock));
                encodedReorderedList = obj.encodeReorderedList(reorderedList);
                obj.bitstream = [obj.bitstream obj.encodeExpGolomblist(encodedReorderedList)];
            end
            index=index+1;
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
        function obj = entroplizeI(obj)
            paddedVideo = obj.addPadding(obj.mode);
            obj = obj.entropilizePredictionFrame(paddedVideo);
            %add one for intra
            obj.predictionInfoBitstream = [obj.encodeExpGolombValue(1) obj.predictionInfoBitstream];
            obj.predictionInfoBitstream = [obj.predictionInfoBitstream obj.encodeExpGolombValue(obj.QP)];
        end

        function obj = entroplizeP(obj)
            paddedVideo = obj.addPadding(obj.motionVector);
            obj = obj.entropilizePredictionFrame(paddedVideo);
            %add one for intra
            obj.predictionInfoBitstream = [obj.encodeExpGolombValue(0) obj.predictionInfoBitstream];
            obj.predictionInfoBitstream = [obj.predictionInfoBitstream obj.encodeExpGolombValue(obj.QP)];
        end
        
        function obj = entropilizePredictionFrame(obj,matrix)
           for i=1:obj.block_height:size(matrix,1)  
                for j=1:obj.block_width:size(matrix,2)
                    currentBlock = Block(matrix, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
                    reorderedList = obj.reorderBlock((currentBlock));
                    encodedReorderedList = obj.encodeReorderedList(reorderedList);
                    obj.predictionInfoBitstream = [obj.predictionInfoBitstream obj.encodeExpGolomblist(encodedReorderedList)];

                end
            end        
        end       
        
        function obj = entropilizeFrame(obj)
           for i=1:obj.block_height:size(obj.quantizedTransformedFrame,1)  
                for j=1:obj.block_width:size(obj.quantizedTransformedFrame,2)
                    if obj.splitList((i-1)/obj.block_height+1,(j-1)/obj.block_width)==0
                        obj.bitstream = [obj.bitstream 
                        
                        currentBlock = Block(obj.quantizedTransformedFrame, j,i, obj.block_width, obj.block_height);
                        reorderedList = obj.reorderBlock((currentBlock));
                        encodedReorderedList = obj.encodeReorderedList(reorderedList);
                        obj.bitstream = [obj.bitstream obj.encodeExpGolomblist(encodedReorderedList)];
                    else
                        
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
        
        function result = addPadding(obj,matrix)
            %UNTITLED Summary of this function goes here
            %   Detailed explanation goes here
            width = size(matrix,2);
            height = size(matrix,1);
            
            pad_width = 0;
            pad_height = 0;
            
            if(rem(width,obj.block_width)~=0)
                pad_width= obj.block_width -(rem(width,obj.block_width));             
            end
            
            if(rem(height,obj.block_height)~=0)
                pad_height = obj.block_height-(rem(height,obj.block_height));  
            end
            result = matrix;% 10 x 10
            
            result(height+1:height + pad_height, width+1:width + pad_width)=0;
            result(height + 1:height + pad_height,:)=0;
            result(:,width + 1:width + pad_width)=0;
            
            end
       


    end
end

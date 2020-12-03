classdef ReverseEntropyEngine_Block
   properties (GetAccess='public', SetAccess='public')
        quantizedTransformedFrame; %type Frame
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
       	video_width; %type int
        video_height; %type int, for square block_height = block_weight = i        
        bitstream;
        invRLEList;
        invReorderList;
        decodedList;
        %%%%%
        residualVideo;
        QP;
        %%%%%%
        count1 = 0;
        Split_block_width; %type int
        Split_block_height;%type int
        SplitList;
        NumofBlockinARow;
        NumofBlockinACol
        FirstBlockCounter;
        SubBlockCounter;
        BlockList;
        TypeLi;
        ModeLi;
        MotionVectorLi;
        RefLi;
        xLi;
        yLi;
        SplitLi;
        QPLi;
        DataLi;
        QPLiBig;
        QPLiSub;
    end
    
    methods(Access = 'public')
        function obj = ReverseEntropyEngine_Block(bitstream,block_width,block_height,video_width,video_height)
            obj.bitstream = bitstream;
            obj.block_width = block_width;
            obj.block_height = block_height;
            %%%%%%%%%%%%
            obj.Split_block_width = block_width / 2;
            obj.Split_block_height = block_height / 2;
            %%%%%%%%%%%
            obj.video_width = video_width;
            obj.video_height = video_height;
            %%%%%%%%%%%%%%%%%%
            obj.NumofBlockinARow = obj.video_width/obj.block_width;
            obj.NumofBlockinACol = obj.video_height/obj.block_height;
            %%%%%%%%%%%%%%%%%%%
            obj = obj.decodeBitstream();
            obj = obj.invRLE();
            obj = obj.generateFrameResInv();  
            %obj = obj.BlockIndex();
            %%%%%%%%%%%%%%%%%%%%%%%%
        end
        
        function obj = decodeBitstream(obj) 
            index = 1;
            obj.decodedList = [];

            while index <= size(obj.bitstream,2)
                [value, index] = dec_golomb(index,obj.bitstream);
                obj.decodedList = [obj.decodedList,value];
            end
        end
                
         function obj = generateFrameResInv(obj)
            for p = 1:1:size (obj.BlockList,2)
                r = RescalingEngine(obj.BlockList(p));
                obj.BlockList(p).data=idct2(r.rescalingResult);
                
%                 rescaledFrame = RescalingEngine(obj.residualVideo(:,:,p),obj.block_width, obj.block_height, obj.QP ).rescalingResult;
%                 rescaledFrame = idct2(rescaledFrame);
%                 obj.residualVideo(:,:,p) = rescaledFrame;
            end
         end
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        function block = invReorder(obj, list)
            block = zeros(obj.block_height, obj.block_width);
                            %reordering upper left top part of block
            count = 1;
            for y=1:1:obj.block_width
                x = 1;
                while y >=1
                    block(x,y) = list(count);
                    y = y -1;
                    x = x + 1;
                    count = count + 1;
                end
            end

            %reordering the element in right bottom part of block
            for x=2:1:obj.block_height
                y = obj.block_width;
                while x <= obj.block_height
                    block(x,y) = list(count);
                    y = y - 1;
                    x = x + 1;
                    count = count + 1;
                end
            end
        end
        
        function block = invReorder_Split(obj, list)
            block = zeros(obj.Split_block_height, obj.Split_block_width);
                            %reordering upper left top part of block
            count = 1;
            for y=1:1:obj.Split_block_width
                x = 1;
                while y >=1
                    block(x,y) = list(count);
                    y = y -1;
                    x = x + 1;
                    count = count + 1;
                end
            end

            %reordering the element in right bottom part of block
            for x=2:1:obj.Split_block_height
                y = obj.Split_block_width;
                while x <= obj.Split_block_height
                    block(x,y) = list(count);
                    y = y - 1;
                    x = x + 1;
                    count = count + 1;
                end
            end
        end
        
        function obj = invRLE(obj )
            
            %Temp Frame for generating temp block
            ReferenceFrame(1:obj.video_width,1:obj.video_height) = uint8(127);
            obj.FirstBlockCounter = 0;
            obj.SubBlockCounter = 0;
            obj.BlockList = [];
            PreviousQP = 0;
            while(isempty(obj.decodedList)~=1)
                obj.count1 = obj.count1 + 1;
                obj.TypeLi = 0;
                obj.ModeLi = 0;
                obj.MotionVectorLi = 0;
                obj.RefLi = 0;
                obj.SplitLi = 0;
                %obj.QPLi = 0;
                obj.DataLi = 0;
                
                obj.TypeLi=obj.decodedList(1);
                if obj.TypeLi==1
                obj.ModeLi=obj.decodedList(2);
                ind = 3;
                else
                obj.RefLi=obj.decodedList(2);
                obj.xLi=obj.decodedList(3);
                obj.yLi=obj.decodedList(4);
                ind = 5;
                end
          
                obj.SplitLi=obj.decodedList(ind);
                ind = ind +1;
                if obj.FirstBlockCounter==0 && obj.SubBlockCounter==0
                    obj.QPLi=obj.decodedList(ind);
                    ind = ind + 1;
                    %obj.QPLi = PreviousQP - obj.QPLi;
                    %PreviousQP = obj.QPLi;
                    if obj.SplitLi == 0 && obj.QPLi==0
                        obj.QPLiBig = obj.QPLi;
                        obj.QPLiSub = obj.QPLi;
                    elseif obj.SplitLi == 0 && obj.QPLi ~=0
                        obj.QPLiBig = obj.QPLi;
                        obj.QPLiSub = obj.QPLi - 1;
                    elseif obj.SplitLi == 1
                        obj.QPLiBig = obj.QPLi + 1;
                        obj.QPLiSub = obj.QPLi;
                    end
                end
                               
                obj.decodedList=obj.decodedList(ind:end);
                if obj.SplitLi == 0
                    obj.FirstBlockCounter = obj.FirstBlockCounter + 1;
                    if obj.FirstBlockCounter == obj.NumofBlockinARow
                        obj.FirstBlockCounter = 0;
                    end
                    
                    index_val=obj.block_width*obj.block_height;
                    tempBlock = Block(ReferenceFrame, 1,1, obj.block_width, obj.block_height);
               
                else
                    obj.SubBlockCounter = obj.SubBlockCounter + 1;
                    if obj.SubBlockCounter ==4
                        obj.FirstBlockCounter = obj.FirstBlockCounter + 1;
                        obj.SubBlockCounter = 0;
                    end
                    if obj.FirstBlockCounter == obj.NumofBlockinARow
                        obj.FirstBlockCounter = 0;
                    end
                    
                    index_val=obj.Split_block_width*obj.Split_block_height;
                    tempBlock = Block(ReferenceFrame, 1,1, obj.Split_block_width, obj.Split_block_height);
                end

               index = 1;
               obj.invRLEList = [];
               count = 0;

                while size(obj.invRLEList,2)<index_val
                    [invReorderedPatialList, index, count] = obj.invReorderValue(obj.decodedList,index, count);
                    obj.invRLEList = [obj.invRLEList,invReorderedPatialList];
                end
                
                if obj.SplitLi == 0
                    obj.DataLi=obj.invReorder(obj.invRLEList);
                else
                    obj.DataLi=obj.invReorder_Split(obj.invRLEList);
                end
                
                obj.decodedList=obj.decodedList(index:end);
                
                tempBlock.frameType = obj.TypeLi;
                tempBlock.Mode = obj.ModeLi;
                tempBlock.MotionVector.x = obj.xLi;
                tempBlock.MotionVector.y = obj.yLi;
                tempBlock.referenceFrameIndex = obj.RefLi;
                tempBlock.split = obj.SplitLi;
                
                if obj.SplitLi==0
                    tempBlock.QP = obj.QPLiBig;
                else
                    tempBlock.QP = obj.QPLiSub;
                end
                    
                tempBlock.data = obj.DataLi;
                
                obj.BlockList = [obj.BlockList tempBlock];
                tempBlock = 0;
            end
            
        end
            
        function [invRLEList,index, count] = invReorderValue(obj,decodedlist, index,count )
            noElement = decodedlist(index);
            invRLEList = [];
            if noElement == 0
               %this whole block is all 0
               invRLEList = zeros(1, obj.block_width * obj.block_height - count);
               index = index + 1;
               count  = 0;
            elseif noElement > 0
                %the first count number of element is zero
                invRLEList = [invRLEList zeros(1, noElement)];
                index = index + 1;
                count = count + noElement;
            else
                %first count number of element is non-zero

                invRLEList = [invRLEList decodedlist(index+1: index + (-noElement))];
                index = index + ( - noElement ) + 1;
                count = count + ( - noElement );
            end

            if count == obj.block_height * obj.block_width
                count = 0;
            end

        end
        

    
        
    end
    end

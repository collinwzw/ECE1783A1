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
        
        Split_block_width; %type int
        Split_block_height;%type int


        
        BlockList;
        TypeLi;
        ModeLi;
        MotionVectorLi;
        RefLi;
        SplitLi;
        QPLi;
        DataLi;
    end
    
    methods(Access = 'public')
        function obj = ReverseEntropyEngine_Block(bitstream,block_width,block_height,video_width,video_height,QP)
            obj.bitstream = bitstream;
            obj.block_width = block_width;
            obj.block_height = block_height;
            %%%%%%%%%%%%
            obj.Split_block_width = block_width / 2;
            obj.Split_block_height = block_height / 2;
            %%%%%%%%%%%
            obj.video_width = video_width;
            obj.video_height = video_height;
            obj.QP=QP;
            %%%%%%%%%%%%%%%%%%%
            obj = obj.decodeBitstream();
            obj = obj.invRLE();
              
            
              
%              fid = fopen('.\output\aaa.txt', 'r');
%              a=fread(fid,'double');
%              fclose(fid);
%             obj.invRLEList=transpose(a);   

% % % % fid = fopen('.\output\aaa.txt', 'w');
% % % % fwrite(fid,obj.invRLEList,'double');
% % % % fclose(fid);
%              obj = obj.generateFrame();
%              obj = generateFrameResInv(obj);
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
        

%         function obj = generateFrame(obj)
%             n_b_h = obj.video_height/obj.block_height;
%             n_b_w = obj.video_width/obj.block_width;
%             NumberofBlockperFrame = n_b_w * n_b_h; % total Block in a frame, 4 sub-blocks = 1 Block
%             matrixHeight = 1;
%             matrixWidth = 1;
%             BlockCount = 0;
%             subBlockCount = 0;
%             index = 0;
%             p = 1;
%             startingIndex = 1;
%             while index < length(obj.invRLEList)
%                 obj.TypeList = 0;
%                 obj.SplitList = 0;
%                 obj.QP_BList = 0;
%                 obj.mode_s0 = 0;
%                 obj.mode_s1 = 0;
%                 obj.mv_s0 = 0;
%                 obj.mv_s1 = 0;
%                 indexi=0;
%                 indexj=0;
%                 while BlockCount < NumberofBlockperFrame
%                     %Read Type
%                     type = obj.invRLEList(startingIndex);
%                     startingIndex = startingIndex+1;
%                     obj.TypeList = [obj.TypeList type];
%                     %Mode / RefF+MV
%                     if  type == 1
%                         mode = obj.invRLEList(startingIndex);
%                         startingIndex = startingIndex+1;
%                     else
%                         RefF = obj.invRLEList(startingIndex);
%                         mvx = obj.invRLEList(startingIndex+1);
%                         mvy = obj.invRLEList(startingIndex+2);
%                         startingIndex = startingIndex+3;
%                     end
% 
%                     %Split
%                     split = obj.invRLEList(startingIndex);
%                     startingIndex = startingIndex+1;
%                     obj.SplitList = [obj.SplitList split];
%                     
%                     %QP
%                     QP_B = obj.invRLEList(startingIndex);
%                     startingIndex = startingIndex+1;
%                     obj.QP_BList = [obj.QP_BList QP_B];
%                     
%                     %Data
%                     if split == 0  
%                         matrixHeight = (indexi) * obj.block_height + 1;
%                         matrixWidth = (indexj) * obj.block_width + 1;                     
%                         obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.block_height - 1, matrixWidth:matrixWidth + obj.block_width - 1) = obj.invReorder(obj.invRLEList(startingIndex:startingIndex + obj.block_width* obj.block_height - 1));
%                         startingIndex = startingIndex + obj.block_width* obj.block_height;
%                         if indexj < (n_b_w - 1)
%                             indexj = indexj + 1;
%                         else 
%                            indexj = 0;
%                            indexi = indexi +1;
%                         end
%                         BlockCount = BlockCount + 1;
%                         if type == 1
%                             obj.mode_s0 = [obj.mode_s0 mode];
%                         elseif type == 0
%                             obj.mv_s0 = [obj.mv_s0 RefF mvx mvy];
%                         end
%                     else %split==1
%                         matrixHeight = (indexi) * obj.block_height + 1;
%                         matrixWidth = (indexj) * obj.block_width + 1;   
%                         
%                         
%                         obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = obj.invReorder(obj.invRLEList(startingIndex:startingIndex + obj.Split_block_width* obj.Split_block_height - 1));
%                         startingIndex = startingIndex + obj.Split_block_width* obj.Split_block_height;
%                         matrixHeight = matrixHeight + obj.Split_block_height;
%                         matrixWidth = matrixWidth + obj.Split_block_width;
%                         subBlockCount = subBlockCount + 1;
%                         if subBlockCount ==4
%                             BlockCount = BlockCount + 1;
%                             subBlockCount = 0;
%                         end
%                         
%                         if type == 1
%                             obj.mode_s1 = [obj.mode_s1 mode];
%                         elseif type == 0
%                             obj.mv_s1 = [obj.mv_s1 RefF mvx mvy];
%                         end
%                     end
%                 end
%                 obj.TypeVideo(:,:,p) = obj.TypeList;
%                 obj.SplitVideo(:,:,p) = obj.SplitList;
%                 obj.QP_BVideo(:,:,p) = obj.QP_BList;
%                 obj.mode_s0Video(:,:,p) = obj.mode_s0;
%                 obj.mode_s1Video(:,:,p) = obj.mode_s1;
%                 obj.mv_s0Video(:,:,p) = obj.mv_s0;
%                 obj.mv_s1Video(:,:,p) = obj.mv_s1;
%                 obj.residualVideo(:,:,p) = obj.quantizedTransformedFrame;
%                 p = p + 1;
%             end
%         end
%       
%         
%           function obj = generateBlockList(obj)
%             n_b_h = obj.video_height/obj.block_height;
%             n_b_w = obj.video_width/obj.block_width;
%             NumberofBlockperFrame = n_b_w * n_b_h; % total Block in a frame, 4 sub-blocks = 1 Block
%             matrixHeight = 1;
%             matrixWidth = 1;
%             BlockCount = 0;
%             subBlockCount = 0;
%             index = 0;
%             p = 1;
%             startingIndex = 1;
%             while index < length(obj.invRLEList)
%                 obj.TypeList = 0;
%                 obj.SplitList = 0;
%                 obj.QP_BList = 0;
%                 obj.mode_s0 = 0;
%                 obj.mode_s1 = 0;
%                 obj.mv_s0 = 0;
%                 obj.mv_s1 = 0;
%                 while BlockCount < NumberofBlockperFrame
%                     %Read Type
%                     type = obj.invRLEList(startingIndex);
%                     startingIndex = startingIndex+1;
%                     obj.TypeList = [obj.TypeList type];
%                     %Mode / RefF+MV
%                     if  type == 1
%                         mode = obj.invRLEList(startingIndex);
%                         startingIndex = startingIndex+1;
%                     else
%                         RefF = obj.invRLEList(startingIndex);
%                         mvx = obj.invRLEList(startingIndex+1);
%                         mvy = obj.invRLEList(startingIndex+2);
%                         startingIndex = startingIndex+3;
%                     end
% 
%                     %Split
%                     split = obj.invRLEList(startingIndex);
%                     startingIndex = startingIndex+1;
%                     obj.SplitList = [obj.SplitList split];
%                     
%                     %QP
%                     QP_B = obj.invRLEList(startingIndex);
%                     startingIndex = startingIndex+1;
%                     obj.QP_BList = [obj.QP_BList QP_B];
%                     
%                     %Data
%                     if split == 0  
%                         obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.block_height - 1, matrixWidth:matrixWidth + obj.block_width - 1) = obj.invReorder(obj.invRLEList(startingIndex:startingIndex + obj.block_width* obj.block_height - 1));
%                         startingIndex = startingIndex + obj.block_width* obj.block_height;
%                         matrixHeight = matrixHeight + obj.block_height;
%                         matrixWidth = matrixWidth + obj.block_width;
%                         BlockCount = BlockCount + 1;
%                         if type == 1
%                             obj.mode_s0 = [obj.mode_s0 mode];
%                         elseif type == 0
%                             obj.mv_s0 = [obj.mv_s0 RefF mvx mvy];
%                         end
%                     else 
%                         obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = obj.invReorder(obj.invRLEList(startingIndex:startingIndex + obj.Split_block_width* obj.Split_block_height - 1));
%                         startingIndex = startingIndex + obj.Split_block_width* obj.Split_block_height;
%                         matrixHeight = matrixHeight + obj.Split_block_height;
%                         matrixWidth = matrixWidth + obj.Split_block_width;
%                         subBlockCount = subBlockCount + 1;
%                         if subBlockCount ==4
%                             BlockCount = BlockCount + 1;
%                             subBlockCount = 0;
%                         end
%                         
%                         if type == 1
%                             obj.mode_s1 = [obj.mode_s1 mode];
%                         elseif type == 0
%                             obj.mv_s1 = [obj.mv_s1 RefF mvx mvy];
%                         end
%                     end
%                 end
%                 obj.TypeVideo(:,:,p) = obj.TypeList;
%                 obj.SplitVideo(:,:,p) = obj.SplitList;
%                 obj.QP_BVideo(:,:,p) = obj.QP_BList;
%                 obj.mode_s0Video(:,:,p) = obj.mode_s0;
%                 obj.mode_s1Video(:,:,p) = obj.mode_s1;
%                 obj.mv_s0Video(:,:,p) = obj.mv_s0;
%                 obj.mv_s1Video(:,:,p) = obj.mv_s1;
%                 obj.residualVideo(:,:,p) = obj.quantizedTransformedFrame;
%                 p = p + 1;
%             end
%         end
%         
        
        
        
         function obj = generateFrameResInv(obj)
            for p = 1:1:size(obj.residualVideo,3)
                rescaledFrame = RescalingEngine(obj.residualVideo(:,:,p),obj.block_width, obj.block_height, obj.QP ).rescalingResult;
                rescaledFrame = idct2(rescaledFrame);
                obj.residualVideo(:,:,p) = rescaledFrame;
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
            
            obj.BlockList = [];
            while(isempty(obj.decodedList)~=1)
                
                obj.TypeLi = 0;
                obj.ModeLi = 0;
                obj.MotionVectorLi = 0;
                obj.RefLi = 0;
                obj.SplitLi = 0;
                obj.QPLi = 0;
                obj.DataLi = 0;
       
                obj.TypeLi=obj.decodedList(1);
                if obj.TypeLi==1
                obj.ModeLi=obj.decodedList(2);
                else
                obj.RefLi=obj.decodedList(2);
                end
          
                obj.SplitLi=obj.decodedList(3);
                obj.QPLi=obj.decodedList(4);
                obj.decodedList=obj.decodedList(5:end);
                if obj.SplitLi == 0
                    index_val=obj.block_width*obj.block_height;
                    tempBlock = Block(ReferenceFrame, 1,1, obj.block_width, obj.block_height);
                else
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
                tempBlock.MotionVector = obj.MotionVectorLi;
                tempBlock.referenceFrameIndex = obj.RefLi;
                tempBlock.split = obj.SplitLi;
                tempBlock.QP = obj.QPLi;
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

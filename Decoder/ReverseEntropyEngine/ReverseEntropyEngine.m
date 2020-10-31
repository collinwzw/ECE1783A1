classdef ReverseEntropyEngine
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
    end
    
    methods(Access = 'public')
        function obj = ReverseEntropyEngine(bitstream,block_width,block_height,video_width,video_height,QP)
            obj.bitstream = bitstream;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.video_width = video_width;
            obj.video_height = video_height;
            
            %%%%%%%%%%%%%%%%%%%
%            obj = obj.decodeBitstream();
%            obj = obj.invRLE();
             obj.QP=QP;
             fid = fopen('.\output\aaa.txt', 'r');
             a=fread(fid,'double');
             fclose(fid);
             obj.invRLEList=transpose(a);             
             obj = obj.generateFrame();
             obj = generateFrameResInv(obj);
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
% 
%             for i=0:1:(obj.video_height/obj.block_height) - 1
%                 for j=0:1:obj.video_width/(obj.block_width) -1
%                     matrixHeight = (i) * obj.block_height + 1;
%                     matrixWidth = (j) * obj.block_width + 1;
% 
%                     startingIndex = (i* obj.video_width/(obj.block_width) + j ) * obj.block_height * obj.block_width + 1;
%                     obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.block_height - 1, matrixWidth:matrixWidth + obj.block_width - 1) = obj.invReorder(obj.invRLEList(startingIndex:startingIndex + obj.block_width* obj.block_height - 1));
%                 end
%             end
%         end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = generateFrame(obj)
            index = 0;
            p = 1;
            while index < length(obj.invRLEList)
                for i=0:1:(obj.video_height/obj.block_height) - 1
                     for j=0:1:obj.video_width/(obj.block_width) -1
                        matrixHeight = (i) * obj.block_height + 1;
                        matrixWidth = (j) * obj.block_width + 1;

                        startingIndex = index + (i* obj.video_width/(obj.block_width) + j ) * obj.block_height * obj.block_width + 1;
                        obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.block_height - 1, matrixWidth:matrixWidth + obj.block_width - 1) = obj.invReorder(obj.invRLEList(startingIndex:startingIndex + obj.block_width* obj.block_height - 1));
                     end
                end
                obj.residualVideo(:,:,p) = obj.quantizedTransformedFrame;
                p = p + 1;
                index = startingIndex + obj.block_width * obj.block_height-1;
            end
        end
         
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
        
        function obj = invRLE(obj )
            index = 1;
            obj.invRLEList = [];
            count = 0;
            while index <= size(obj.decodedList,2)
                [invReorderedPatialList, index, count] = obj.invReorderValue(obj.decodedList,index, count);
                obj.invRLEList = [obj.invRLEList,invReorderedPatialList];
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
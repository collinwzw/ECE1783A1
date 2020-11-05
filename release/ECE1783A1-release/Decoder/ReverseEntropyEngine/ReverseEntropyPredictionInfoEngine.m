classdef ReverseEntropyPredictionInfoEngine
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
        QP;
        frameType;
        diff_mode;
        diff_motionvector;
        modes;
        perblocklength;
        motionvector;
        mode_height;
        mode_height_pad
        mode_width;
        mode_width_pad
        motionvector_height;
        motionvector_height_pad
        motionvector_width;
        motionvector_width_pad
        motionvectorframe;
        modevectorframe;
        number_of_frames;
    end
    
    methods(Access = 'public')
        function obj = ReverseEntropyPredictionInfoEngine(bitstream,block_width,block_height,video_width,video_height)
            obj.bitstream = bitstream;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.video_width = video_width;
            obj.video_height = video_height;
            
            obj.motionvector_height=obj.video_height/obj.block_height;
            obj.motionvector_height_pad=obj.motionvector_height+(obj.block_height -(rem(obj.motionvector_height,obj.block_height)));
            
            obj.motionvector_width=(obj.video_width/obj.block_width)*2;
            if(rem(obj.motionvector_width,obj.block_width)~=0)
                    obj.motionvector_width_pad=obj.motionvector_width+(obj.block_width -(rem(obj.motionvector_width,obj.block_width)));
            else
                obj.motionvector_width_pad=obj.motionvector_width;
            end        
            
            obj.mode_height=obj.video_height/obj.block_height;
            obj.mode_height_pad=obj.mode_height+(obj.block_height -(rem(obj.mode_height,obj.block_height)));
            
            obj.mode_width=(obj.video_width/obj.block_width);
            obj.mode_width_pad=obj.mode_width+(obj.block_width -(rem(obj.mode_width,obj.block_width)));
            
            obj = obj.decodeBitstream();

            %change start from here
            obj = obj.invRLE();
            
            obj = obj.generateFrame();

        end
        
        function value = removepadding(obj,block_height,block_width)
            value=obj.quantizedTransformedFrame(1:block_height,1:block_width);
        end

        function obj = decodeBitstream(obj) 
            index = 1;
            obj.decodedList = [];

            while index <= size(obj.bitstream,2)
                [value, index] = dec_golomb(index,obj.bitstream);
                obj.decodedList = [obj.decodedList,value];
            end
        end
        
        function obj = generateFrame(obj)
            motionvectorframe=1;
            modeframe=1;
            for f=1:1:obj.number_of_frames-1

                if(obj.frameType(f)==0)
                     k=0;
                     for i=0:1:(obj.motionvector_height_pad/obj.block_height)-1
                        for j=0:1:((obj.motionvector_width_pad/obj.block_width))-1
                        matrixHeight = (i) * obj.block_height + 1;
                        matrixWidth = (j) * obj.block_width + 1;

                        startingIndex = ( k ) * obj.block_height * obj.block_width + 1;
                        obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.block_height - 1, matrixWidth:matrixWidth + obj.block_width - 1) = obj.invReorder(obj.motionvectorframe(:,startingIndex:startingIndex + obj.block_width* obj.block_height - 1,motionvectorframe));
                        k=k+1;
                        end
                     end

                    obj.diff_motionvector(:,:,motionvectorframe)=obj.quantizedTransformedFrame(1:obj.motionvector_height,1:obj.motionvector_width);
                    diffencoder=DifferentialDecodingEngine();
                    motionvector_object=diffencoder.differentialDecodingMotionVector(obj.diff_motionvector(:,:,motionvectorframe));
                    obj.motionvector(:,:,motionvectorframe)=motionvector_object.motionvector;
                    motionvectorframe=motionvectorframe+1;

                elseif(obj.frameType(f)==1)
                         k=0;

                         for i=0:1:(obj.mode_height_pad/obj.block_height)-1
                            for j=0:1:(obj.mode_width_pad/obj.block_width)-1
                            matrixHeight = (i) * obj.block_height + 1;
                            matrixWidth = (j) * obj.block_width + 1;

                            startingIndex = ( k ) * obj.block_height * obj.block_width + 1;
                            obj.quantizedTransformedFrame(matrixHeight:matrixHeight+obj.block_height - 1, matrixWidth:matrixWidth + obj.block_width - 1) = obj.invReorder(obj.modevectorframe(:,startingIndex:startingIndex + obj.block_width* obj.block_height - 1,modeframe));
                            k=k+1;
                            end
                         end
                        
                        obj.diff_mode(:,:,modeframe)=obj.quantizedTransformedFrame(1:obj.mode_height,1:obj.mode_width);
                        diffencoder=DifferentialDecodingEngine();
                        mode_object=diffencoder.differentialDecodingMode(obj.diff_mode(:,:,modeframe));
                        obj.modes(:,:,modeframe)=mode_object.modes;
                        modeframe=modeframe+1;
                end
            end
                
        end
        
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
            % take a input list, truncate it into a bunch of list.
            index = 1;
            obj.invRLEList = [];
            count = 0;
            obj.number_of_frames=1;
            m=1;
            n=1;
%             obj.frameType(k)=obj.decodedList(1);
%             obj.decodedList=obj.decodedList(2:end);
            while(isempty(obj.decodedList)~=1)
            
%             obj.QP=obj.decodedList(size(obj.decodedList,2));
            obj.frameType(obj.number_of_frames)=obj.decodedList(1);
            obj.decodedList=obj.decodedList(2:end);
%             obj.decodedList(end)=[];
            
            if(obj.frameType(obj.number_of_frames)==0)
                index_val=obj.motionvector_height_pad*obj.motionvector_width_pad;
            elseif(obj.frameType(obj.number_of_frames)==1)
                index_val=obj.mode_height_pad*obj.mode_width_pad;
            end
            
%             while index <= size(obj.decodedList,2)
             while size(obj.invRLEList,2)<index_val
                [invReorderedPatialList, index, count] = obj.invReorderValue(obj.decodedList,index, count);
                obj.invRLEList = [obj.invRLEList,invReorderedPatialList];
             end
             
            if(obj.frameType(obj.number_of_frames)==0)
                obj.motionvectorframe(:,:,m)=obj.invRLEList;
                obj.QP(obj.number_of_frames)=obj.decodedList(index);
                obj.decodedList=obj.decodedList(index+1:end);
                m=m+1;
                obj.invRLEList = [];
            elseif(obj.frameType(obj.number_of_frames)==1)
                obj.modevectorframe(:,:,n)=obj.invRLEList;
                obj.QP(obj.number_of_frames)=obj.decodedList(index);
                obj.decodedList=obj.decodedList(index+1:end);
                n=n+1;
                obj.invRLEList = [];
            end
            obj.number_of_frames=obj.number_of_frames+1;
            index=1;
            end
        end
            
        function [invRLEList,index, count] = invReorderValue(obj,decodedlist, index,count )
            %take a list, extract 
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
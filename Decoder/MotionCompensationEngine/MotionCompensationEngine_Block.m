classdef MotionCompensationEngine_Block
    properties (GetAccess='public', SetAccess='public')
        
        block_width;
        block_height;
       	video_width; %type int
        video_height;
        residualVideo;
        residualFrame;
        video;
        referenceVideo;
        predictedFrame;
        r;
        vectors;
        v;
        x;
        y;
        dw; %Decoder Width
        dh; %Decoder height
        mvw; %MV Width
        mvh; %MV Width
        inputFilename;
        numberOfFrames;
        DecodedRefVideo;
        Temp_v;
        frametype;
        
        BlockList;
        BlockList_copy;
        TypeList;
        SplitList;
        Split_block_width;
        Split_block_height;
    end

    methods(Access = 'public')
        function obj = MotionCompensationEngine_Block(BlockList,block_width,block_height,video_width,video_height)
            obj.BlockList = BlockList;
            obj.BlockList_copy = BlockList;
            obj.block_width = block_width;
            obj.block_height = block_height;
            obj.Split_block_width = block_width / 2;
            obj.Split_block_height = block_height / 2;
            obj.video_width = video_width;
            obj.video_height = video_height;
            
            obj = obj.TypeListGenerator();
            obj = obj.SplitListGenerator();
            obj = obj.residualFrameGenerator();      
                    
%             inputFilename = 'Z:\Semester 3\Design tradeoff\foremanY_cif.yuv';
%             v1 = YOnlyVideo(inputFilename, 352, 288);
%             [v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);
%             ref1 = v1WithPadding.Y(:,:,1);
            referenceFrame=[];
            Blockcount = 0;
            Framecount = 0;
            Listindex = 1;
            while Framecount <obj.numberOfFrames
                                Previousmvx = 0;
                Previousmvy = 0;
                PreviousrefIn = 0;
                 while Blockcount < ((obj.video_height/obj.block_height))* (obj.video_width/(obj.block_width))
                    if obj.BlockList(1,Listindex).frameType ==0
                         if obj.BlockList(1,Listindex).split==0
                             %differential decoding for motion vector
                             mvx = obj.BlockList(1,Listindex).MotionVector.x;
                             mvy = obj.BlockList(1,Listindex).MotionVector.y;
                             mvx = Previousmvx - mvx;
                             mvy = Previousmvy - mvy;
                             Previousmvx = mvx;
                             Previousmvy = mvy;

                             %Filling block to frame
                             matrixHeight = obj.BlockList(1,Listindex).top_height_index;
                             matrixWidth = obj.BlockList(1,Listindex).left_width_index;
                             obj.predictedFrame(matrixHeight : matrixHeight+obj.block_height - 1, matrixWidth : matrixWidth + obj.block_width - 1) = ref1(matrixHeight+mvy:matrixHeight+mvy+obj.block_height - 1,matrixWidth+mvx:matrixWidth+mvx+obj.block_width - 1 );

                             Blockcount = Blockcount +1;
                             Listindex = Listindex +1;
                         else
                             for i =1:1:4
                                 %differential decoding for motion vector
                                 mvx = obj.BlockList(1,Listindex).MotionVector.x;
                                 mvy = obj.BlockList(1,Listindex).MotionVector.y;
                                 mvx = Previousmvx - mvx;
                                 mvy = Previousmvy - mvy;
                                 Previousmvx = mvx;
                                 Previousmvy = mvy;

                                 matrixHeight = obj.BlockList(1,Listindex).top_height_index;
                                 matrixWidth = obj.BlockList(1,Listindex).left_width_index;
                                 obj.predictedFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = ref1(matrixHeight+mvx:matrixHeight+mvx+obj.Split_block_height - 1,matrixWidth+mvy:matrixWidth+mvy+obj.Split_block_width - 1 );
                                 Listindex = Listindex +1;
                             end
                             Blockcount = Blockcount +1;    
                         end
                         
                    else %I frame
                        if obj.BlockList(1,Listindex).split==0
                             Intra_prediction=IntraPredictionEngine_decode(obj.BlockList(1,Listindex),referenceFrame);
                             Decoded_value=Intra_prediction.decoded_block;
                             matrixHeight = obj.BlockList(1,Listindex).top_height_index;
                             matrixWidth = obj.BlockList(1,Listindex).left_width_index;
                             obj.predictedFrame(matrixHeight : matrixHeight+obj.block_height - 1, matrixWidth : matrixWidth + obj.block_width - 1) = Decoded_value;
                             referenceFrame_cal(matrixHeight : matrixHeight+obj.block_height - 1, matrixWidth : matrixWidth + obj.block_width - 1)=int16(obj.predictedFrame(matrixHeight : matrixHeight+obj.block_height - 1, matrixWidth : matrixWidth + obj.block_width - 1))+int16(obj.residualVideo(matrixHeight : matrixHeight+obj.block_height - 1, matrixWidth : matrixWidth + obj.block_width - 1,Framecount+1));
                             referenceFrame=uint8(referenceFrame_cal);
                             Blockcount = Blockcount +1;
                             Listindex = Listindex +1;
                        else
                            for i=1:1:4
                            Intra_prediction=IntraPredictionEngine_decode(obj.BlockList(1,Listindex),referenceFrame);
                            Decoded_value=Intra_prediction.decoded_block;
                             matrixHeight = obj.BlockList(1,Listindex).top_height_index;
                             matrixWidth = obj.BlockList(1,Listindex).left_width_index;
                             obj.predictedFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = Decoded_value;
                             referenceFrame_cal(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1)=int16(obj.predictedFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1))+int16(abs(-obj.residualVideo(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1,Framecount+1));
                             referenceFrame=uint8(abs(referenceFrame_cal));
                             Listindex = Listindex +1;
                            end
                            Blockcount = Blockcount +1;
                        end
                         
                    end
                 end
            
            if obj.BlockList(1,Listindex-1).frameType ==0
                    referenceFrame_cal=int16(obj.predictedFrame)+int16(obj.residualVideo(:,:,Framecount+1));
                    referenceFrame=uint8(referenceFrame_cal);
            end
                    obj.DecodedRefVideo(:,:,Framecount+1) = referenceFrame;
                    ref1 = referenceFrame;
                    Framecount = Framecount +1;
                    Blockcount=0;
            end
            end
%             
%             index = 1;
%             count = 1;
%             for count < ((obj.video_height/obj.block_height))* (obj.video_width/(obj.block_width))
%                 if obj.TypeList(index)==0
%                     mvx = obj.BlockList_copy(1,index).MotionVector.x;
%                     mvy = obj.BlockList_copy(1,index).MotionVector.y;
%                 else
%                     
%                 end
%             end
        
          
%         end    
   
        function obj = residualFrameGenerator(obj)
            p=1;
            SplitList1 = obj.SplitList;
            BlockList1 =  obj.BlockList;
            index = 1;
            while (isempty(BlockList1)~=1) 
                Blockcount = 0;
                while Blockcount < ((obj.video_height/obj.block_height))* (obj.video_width/(obj.block_width))                   
                    if obj.BlockList(index).frameType ==0
                        %inter
                        for i=0:1:(obj.video_height/obj.block_height) - 1
                            for j=0:1:obj.video_width/(obj.block_width) -1
                                    if SplitList1(1) == 0
                                        matrixHeight = (i) * obj.block_height + 1;
                                        matrixWidth = (j) * obj.block_width + 1;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.block_height - 1, matrixWidth:matrixWidth + obj.block_width - 1) = BlockList1(1).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;
                                        BlockList1 =  BlockList1(2:end);
                                        SplitList1 =  SplitList1(2:end);
                                        Blockcount = Blockcount + 1 ;
                                    elseif SplitList1(1) == 1
                                        matrixHeight = (i) * obj.block_height + 1;
                                        matrixWidth = (j) * obj.block_width + 1;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(1).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;

                                        matrixWidth = matrixWidth + obj.Split_block_width;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(2).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;

                                        matrixHeight = matrixHeight + obj.Split_block_height;
                                        matrixWidth = matrixWidth - obj.Split_block_width;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(3).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;

                                        matrixWidth = matrixWidth + obj.Split_block_width;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(4).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;

                                        BlockList1 =  BlockList1(5:end);
                                        SplitList1 =  SplitList1(5:end);
                                        Blockcount = Blockcount + 1 ;
                                    end                
                            end
                        end
                        obj.residualVideo(:,:,p) = obj.residualFrame;
                        obj.numberOfFrames = p;
                        p = p + 1;
                    else % I frame
                        for i=0:1:(obj.video_height/obj.block_height) - 1
                            for j=0:1:obj.video_width/(obj.block_width) -1
                                    if SplitList1(1) == 0
                                        matrixHeight = (i) * obj.block_height + 1;
                                        matrixWidth = (j) * obj.block_width + 1;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.BlockList(index).block_height - 1, matrixWidth:matrixWidth + obj.BlockList(index).block_width - 1) = BlockList1(1).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;
                                        BlockList1 =  BlockList1(2:end);
                                        SplitList1 =  SplitList1(2:end);
                                        Blockcount = Blockcount + 1 ;
                                    else
                                       matrixHeight = (i) * obj.block_height + 1;
                                        matrixWidth = (j) * obj.block_width + 1;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(1).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;
                                        


                                        matrixWidth = matrixWidth + obj.Split_block_width;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(2).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;

                                        matrixHeight = matrixHeight + obj.Split_block_height;
                                        matrixWidth = matrixWidth - obj.Split_block_width;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(3).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;

                                        matrixWidth = matrixWidth + obj.Split_block_width;
                                        obj.residualFrame(matrixHeight:matrixHeight+obj.Split_block_height - 1, matrixWidth:matrixWidth + obj.Split_block_width - 1) = BlockList1(4).data;
                                        obj.BlockList(index).top_height_index = matrixHeight;
                                        obj.BlockList(index).left_width_index = matrixWidth;
                                        index = index +1;

                                        BlockList1 =  BlockList1(5:end);
                                        SplitList1 =  SplitList1(5:end);
                                        Blockcount = Blockcount + 1 ;
                                    end
                            end
                            
                        end
                        obj.residualVideo(:,:,p) = obj.residualFrame;
                        obj.numberOfFrames = p;
                        p = p + 1;
                    end
                end
            end
        end  
        
        
        function referenceVideo = getDecodedRefVideo(obj)
           referenceVideo =obj.Temp_v; 
        end   
        function obj = TypeListGenerator(obj)
            obj.TypeList = [];
            for p = 1:1:size (obj.BlockList,2)
                obj.TypeList = [obj.TypeList obj.BlockList(1, p).frameType];
            end
        end  
        function obj = SplitListGenerator(obj)
            obj.SplitList = [];
            for p = 1:1:size (obj.BlockList,2)
                obj.SplitList = [obj.SplitList obj.BlockList(1, p).split];
            end
        end   
      end
end


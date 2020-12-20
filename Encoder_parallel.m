classdef Encoder_parallel
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        inputvideo;
        r;
        n;
        QP;
        reconstructedVideo;
        I_Period;
        predictionVideo;
        nRefFrame;
        FEMEnable;
        FastME;
        OutputBitstream=[];
        VBSEnable;
        SADPerFrame;
        RCflag;
        bitBudget;
        blockList;
        ParallelMode;
        bitCountVideo;
    end
    
    methods (Access = 'public')
        function obj = Encoder_parallel(inputvideo,block_width, block_height,r , QP, I_Period,nRefFrame,FEMEnable,FastME, VBSEnable, RCflag, bitBudget, ParallelMode)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.inputvideo = inputvideo;
            obj.I_Period = I_Period;
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.r=r;
            obj.QP = QP;
            obj.nRefFrame=nRefFrame;
            obj.FEMEnable=FEMEnable;
            obj.FastME = FastME;
            obj.VBSEnable=VBSEnable;
            obj.RCflag = RCflag;
            obj.bitCountVideo = zeros(obj.inputvideo.width/block_width,obj.inputvideo.height/block_height, obj.inputvideo.numberOfFrames);
            obj.bitBudget = bitBudget;
            obj.SADPerFrame = [];
            obj.ParallelMode = ParallelMode;
            obj = obj.encodeVideo();
        end
    
        function [processedBlock, en] = generateReconstructedFrame(obj,frameIndex, predicted_block)
            %calculating residual frame
            residualBlockData =  int16(obj.inputvideo.Y(predicted_block.top_height_index: predicted_block.top_height_index + predicted_block.block_height-1, predicted_block.left_width_index: predicted_block.left_width_index + predicted_block.block_width-1,frameIndex)) -int16(predicted_block.data);
            processedBlock = predicted_block;
            processedBlock.data = residualBlockData;

            %input alculated residual frame to transformation engine
            processedBlock.data = dct2(processedBlock.data);

            %input transformed frame to quantization engine

            processedBlock.data= QuantizationEngine(processedBlock).qtc;
            
            %call entropy engine to encode the quantized transformed frame
            %and save it.
            en = EntropyEngine_Block(processedBlock,obj.QP,obj.RCflag);
            

%             if (rem(frameIndex - 1,obj.I_Period)) == 0
%                 %it's I frame
%                 entropyFrame = entropyFrame.EntropyEngineI(quantizedtransformedFrame,Diffencoded_frame.diff_modes, obj.block_width, obj.block_height,obj.QP);
%                 entropyQTC = entropyFrame.bitstream;
%                 entropyPredictionInfo = entropyFrame.predictionInfoBitstream;
%             else
%                 %it's P frame
%                 entropyFrame = entropyFrame.EntropyEngineP(quantizedResult,Diffencoded_frame.diff_motionvector, obj.block_width, obj.block_height,obj.QP);
%                 entropyQTCBlock = entropyFrame.bitstream;
%                 entropyPredictionInfoBlock = entropyFrame.predictionInfoBitstream;
%             end

            %input quantized transformed frame to rescaling engine    
            processedBlock.data = RescalingEngine(processedBlock).rescalingResult;
            %input rescal transformed frame to inverse transformation engine    
            processedBlock.data = idct2(processedBlock.data);
            %finally, add this frame to predicted frame
            reconstructedBlock = int16(predicted_block.data) + int16( processedBlock.data);
            processedBlock.data = reconstructedBlock;
        end
        
        function type = generateTypeMatrix(obj)
            type = zeros(1, obj.inputvideo.numberOfFrames);
%             obj.I_Period = 10;
            for i = 1: obj.I_Period:obj.inputvideo.numberOfFrames
                type(i) = 1;
            end
        end
        
        function obj = encodeVideo(obj)
            %initialize parameter for memorize the lastIFrame
            lastIFrame=-1;
            %generating the type list according to input parameter I_Period

            type = obj.generateTypeMatrix();

            
            while i<1
                rowIndex = 1;
                actualBitSpentCurrentRow = 0;
                i=i+1;
                if(obj.ParallelMode==1)
                    if(type(i)==1)
                        obj.reconstructedVideo.y(:,:,1)=128;
                        i=i+1;
                        continue;
                    end
                end
                        
                if type(i) == 1
                    obj.reconstructedVideo.Y(:,:,i) = zeros( obj.inputvideo.width , obj.inputvideo.height);
                    next_reconstructedVideo=zeros( obj.inputvideo.width , obj.inputvideo.height);
                    intra = true;
                    lastIFrame = i;
                    reference_frame1=[];
                    reference_frame4=[];
                    deframe = DifferentialEncodingEngine();
                    block_list = obj.truncateFrameToBlocks(i);
                    length = size(block_list,2);
                    length_temp=obj.inputvideo.height/obj.block_height;
                    index=0;
                    while index<=length-length_temp
                        %                       while index<length_temp
                        index=index+1;
                        
                        if(index==1)
                            if obj.RCflag == 1
                                if block_list(index).top_height_index == rowIndex
                                    obj.bitBudget = obj.bitBudget.computeQP(intra,actualBitSpentCurrentRow, i );
                                    obj.QP = obj.bitBudget.QP;
                                    rowIndex = rowIndex + obj.block_height;
                                    actualBitSpentCurrentRow = 0;
                                end
                            end
                            [predicted_value,SAD]=IP(block_list(index),obj.reconstructedVideo.Y(:,:,i));
                            predicted_value.split=0;
                            predicted_value = predicted_value.setframeType(type(i));
                            [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_value);
                            reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                            if(obj.VBSEnable==1)
                                count=1;
                                SAD4=[];
                                predictedblock_4=[];
                                mode4=[];
                                temp_bitstream4=[];
                                reference_frame4=obj.reconstructedVideo.Y(:,:,i);
                                for row_i =1:1:2
                                    for col_i=1:1:2
                                        [predicted_value_4,SAD_4]=IP_4(block_list(index),reference_frame4,count,obj.QP);
                                        [processedBlock_4, en] = obj.generateReconstructedFrame(i,predicted_value_4);
                                        temp_bitstream4=[temp_bitstream4 en.bitstream];
                                        curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                        curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                        predictedblock_4(curr_row,curr_col)=predicted_value_4.data;
                                        reference_frame4(predicted_value_4.top_height_index: predicted_value_4.top_height_index + predicted_value_4.block_height-1, predicted_value_4.left_width_index: predicted_value_4.left_width_index + predicted_value_4.block_width-1) = uint8(processedBlock_4.data);
                                        count=count+1;
                                        SAD4=[SAD4 SAD_4];
                                    end
                                end
                                cost=RDO(predicted_value.data,predictedblock_4,obj.block_height,obj.block_width,SAD,SAD4,obj.QP);
                                if(cost.flag==0)
                                    obj.reconstructedVideo.Y(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1,i) = reference_frame1(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                     obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
                                     actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(en.bitstream,2);
                                    %obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predicted_value.data);
                                    obj.bitCountVideo(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream1,2);
                                else
                                    obj.reconstructedVideo.Y(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1,i) = reference_frame4(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                     obj.OutputBitstream = [obj.OutputBitstream temp_bitstream4];
                                     actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_bitstream4,2);
                                    %obj.predictionVideo(1:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predictedblock_4);
                                    obj.bitCountVideo(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream4,2);
                                    
                                end
                                
                            else
                                obj.reconstructedVideo.Y(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                                obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
                            end
                            
                        elseif (index==length-length_temp)
                            if obj.RCflag == 1
                                if block_list(index).top_height_index == rowIndex
                                    obj.bitBudget = obj.bitBudget.computeQP(intra,actualBitSpentCurrentRow, i );
                                    obj.QP = obj.bitBudget.QP;
                                    rowIndex = rowIndex + obj.block_height;
                                    actualBitSpentCurrentRow = 0;
                                end
                            end
                            [predicted_value,SAD]=IP(block_list(index+length_temp),obj.reconstructedVideo.Y(:,:,i));
                            predicted_value.split=0;
                            predicted_value = predicted_value.setframeType(type(i));
                            [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_value);
                            final_stream=en.bitstream;
                            reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                            if(obj.VBSEnable==1)
                                count=1;
                                SAD4=[];
                                mode4=[];
                                predictedblock_4=[];
                                temp_bitstream4=[];
                                reference_frame4=obj.reconstructedVideo.Y(:,:,i);
                                for row_i =1:1:2
                                    for col_i=1:1:2
                                        [predicted_value_4,SAD_4]=IP_4(block_list(index+length_temp),reference_frame4,count,obj.QP);
                                        [processedBlock_4, en] = obj.generateReconstructedFrame(i,predicted_value_4);
                                        temp_bitstream4=[temp_bitstream4 en.bitstream];
                                        curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                        curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                        predictedblock_4(curr_row,curr_col)=predicted_value_4.data;
                                        reference_frame4(predicted_value_4.top_height_index: predicted_value_4.top_height_index + predicted_value_4.block_height-1, predicted_value_4.left_width_index: predicted_value_4.left_width_index + predicted_value_4.block_width-1) = uint8(processedBlock_4.data);
                                        count=count+1;
                                        SAD4=[SAD4 SAD_4];
                                    end
                                end
                                cost=RDO(predicted_value.data,predictedblock_4,obj.block_height,obj.block_width,SAD,SAD4,obj.QP);
                                if(cost.flag==0)
                                    obj.reconstructedVideo.Y(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1,i) = reference_frame1(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                    obj.OutputBitstream = [obj.OutputBitstream final_stream];
                                    %obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predicted_value.data);
                                    actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(en.bitstream,2);
                                    obj.bitCountVideo(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream1,2);
                                else
                                    obj.reconstructedVideo.Y(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1,i) = reference_frame4(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                    obj.OutputBitstream = [obj.OutputBitstream temp_bitstream4];
                                    %obj.predictionVideo(1:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predictedblock_4);
                                    actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(en.bitstream,2);
                                    obj.bitCountVideo(int16(block_list(index).top_height_index/obj.block_height) + 1, int16(block_list(index).left_width_index/obj.block_width) + 1, i ) = size(temp_bitstream4,2);
                                end
                            else
                                obj.reconstructedVideo.Y(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = uint8(processedBlock.data);
                                obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
                            end
                            index=index+length_temp;
                            if(obj.ParallelMode==3 && type(i+1)==0)
                                temp_reconVid=next_reconstructedVideo{2};
                                obj.reconstructedVideo.Y(:,:,i+1)=temp_reconVid(:,:);
                                start=1;
                                stop=length;
                                [p,nextstream1]=inter_comp(obj,i+1,obj.reconstructedVideo.Y,lastIFrame,type,start,stop);
                                obj.reconstructedVideo.Y(:,:,i+1)=obj.reconstructedVideo.Y(:,:,i+1)+double(p);
                                i=i+1;
                                obj.OutputBitstream=[obj.OutputBitstream nextstream1];
                            elseif (obj.ParallelMode==3 && type(i+1)==1)
                                temp=next_frame{3};                                
                                obj.reconstructedVideo.Y(:,:,i+1)=temp;
                                i=i+1;
                                obj.OutputBitstream=[obj.OutputBitstream nextstream{3}];
                            end

                        else
                            reconstructedVideo=obj.reconstructedVideo.Y;
                            reference_frame4_para=obj.reconstructedVideo.Y(:,:,i);
                            reference_frame1_para=obj.reconstructedVideo.Y(:,:,i);
                            temp_index=index;
                            para_stream=[];
                            k=0;
                            temp_stream=[];
                            initial=1;
                            n=2;
                            a1=obj;
                            
                            spmd
                                if labindex==1
%                                     while k<=0
                                    while k<=length-length_temp-temp_index
                                        if(mod(temp_index+k-1,length_temp)==0 )%performing operation on last block on next row
                                            new_index=temp_index+k+length_temp;
                                            k=k+length_temp+1;
                                        else
                                            new_index=temp_index+k;
                                            k=k+1;
                                            
                                        end
                                        if obj.RCflag == 1
                                            if block_list(index).top_height_index == rowIndex
                                                a.bitBudget = a.bitBudget.computeQP(intra,actualBitSpentCurrentRow, i );
                                                a.QP = a.bitBudget.QP;
                                                rowIndex = rowIndex + obj.block_height;
                                                actualBitSpentCurrentRow = 0;
                                            end
                                        end
                                        [predicted_value,SAD]=IP(block_list(new_index),reconstructedVideo(:,:,i));
                                        predicted_value.split=0;
                                        predicted_value = predicted_value.setframeType(type(i));
                                        [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_value);
                                        temp_stream=[temp_stream  en.bitstream];
                                        reference_frame1_para(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                                        if(obj.VBSEnable==1)
                                            count=1;
                                            temp_stream4=[];
                                            SAD4=[];
                                            reference_frame4_para=reconstructedVideo(:,:,i);
                                            
                                            for row_i =1:1:2
                                                for col_i=1:1:2
                                                    [predicted_value_4,SAD_4]=IP_4(block_list(new_index),reference_frame4_para,count,obj.QP);
                                                    [processedBlock_4, en] = obj.generateReconstructedFrame(i,predicted_value_4);
                                                    temp_stream4=[temp_stream4 en.bitstream];
                                                    %%disp('b');
                                                    curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                                    curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                                    predictedblock_4_para(curr_row,curr_col)=predicted_value_4.data;
                                                    reference_frame4_para(predicted_value_4.top_height_index: predicted_value_4.top_height_index + predicted_value_4.block_height-1, predicted_value_4.left_width_index: predicted_value_4.left_width_index + predicted_value_4.block_width-1) = uint8(processedBlock_4.data);
                                                    count=count+1;
                                                    SAD4=[SAD4 SAD_4];
                                                    %                                             mode4=[mode4 predicted_value_4.Mode];
                                                end
                                            end
                                            cost_para=RDO(predicted_value.data,predictedblock_4_para,obj.block_height,obj.block_width,SAD,SAD4,obj.QP);
                                            if(cost_para.flag==0)
                                                prev_value=reconstructedVideo(:,:,i);
                                                reconstructedVideo(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = reference_frame1_para(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                                %disp('o');
                                                reconstructedVideo(:,:,i)=abs(reconstructedVideo(:,:,i)-labReceive(2));
                                                reconstructedVideo(:,:,i)=prev_value+reconstructedVideo(:,:,i);
                                                labSend(reconstructedVideo(:,:,i),2);
                                                 actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_bitstream1,2);
                                                disp(new_index);
                                                if(mod(new_index-1,length_temp)==0)
                                                    %disp('g');
                                                    para_stream=[para_stream labReceive(2)];
                                                end
                                                para_stream=[para_stream temp_stream];
                                                %disp('e');
                                                if(new_index==length-length_temp)
                                                    para_stream=[para_stream labReceive(2)];
                                                end
                                                temp_stream=[];
                                            else
                                                prev_value=reconstructedVideo(:,:,i);
                                                %                                                  prev_value=reference_frame4_para;
                                                reference_frame4_para=abs(reference_frame4_para-labReceive(2));
                                                reference_frame4_para=prev_value+reference_frame4_para;
                                                labSend(reference_frame4_para,02);
                                                reconstructedVideo(:,:,i)=reference_frame4_para;
                                                 actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_stream4,2);
                                                if(mod(new_index-1,length_temp)==0)
                                                    %disp('g');
                                                    para_stream=[para_stream labReceive(2)];
                                                end
                                                para_stream=[para_stream temp_stream4];
                                               if(new_index==length-length_temp)
                                                    para_stream=[para_stream labReceive(2)];
                                                end
                                                temp_stream=[];
                                            end
                                        else
                                            prev_value=reconstructedVideo(:,:,i);
                                            reconstructedVideo(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = reference_frame1_para(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                            %disp('o');
                                            reconstructedVideo(:,:,i)=abs(reconstructedVideo(:,:,i)-labReceive(2));
                                            reconstructedVideo(:,:,i)=prev_value+reconstructedVideo(:,:,i);
                                             actualBitSpentCurrentRow = actualBitSpentCurrentRow + size(temp_stream,2);
                                            labSend(reconstructedVideo(:,:,i),2);                                            
                                            disp(new_index);
                                            if(mod(new_index-1,length_temp)==0)
                                                %disp('g');
                                                para_stream=[para_stream labReceive(2)];
                                            end
                                            para_stream=[para_stream temp_stream];
                                            %disp('e');
                                            if(new_index==length-length_temp)
                                                para_stream=[para_stream labReceive(2)];
                                            end
                                            temp_stream=[];
                                        end
                                    end
                                end
                                if labindex==2
                                    temp_stream_even=[];
%                                     while k<=0
                                    while k<=length-length_temp-temp_index
                                        %                                     for k=0:1:length_temp-1
                                        if(mod(temp_index+k-1,length_temp)==0)
                                            new_index=temp_index+k+length_temp-1;
                                            k=k+length_temp+1;
                                        else
                                            new_index=temp_index+k+length_temp-1;
                                            k=k+1;
                                        end
                                        %                                         disp(k)
%                                         disp(new_index)
%                                         temp_stream=[];
                                        [predicted_value,SAD]=IP(block_list(new_index),reconstructedVideo(:,:,i));
                                        predicted_value.split=0;
                                        predicted_value = predicted_value.setframeType(type(i));
                                        [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_value(1));
                                        reference_frame1_para(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
                                        temp_stream=[temp_stream en.bitstream];
                                        if(obj.VBSEnable==1)
                                            count=1;
                                            SAD4=[];
                                            temp_stream4=[];
                                            reference_frame4_para=reconstructedVideo(:,:,i);
                                            for row_i =1:1:2
                                                for col_i=1:1:2
                                                    [predicted_value_4,SAD_4]=IP_4(block_list(new_index),reference_frame4_para,count,obj.QP);
                                                    [processedBlock_4, en] = obj.generateReconstructedFrame(i,predicted_value_4 );
                                                    temp_stream4=[temp_stream4 en.bitstream];
                                                    curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                                    curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                                    predictedblock_4_para(curr_row,curr_col)=predicted_value_4.data;
                                                    reference_frame4_para(predicted_value_4.top_height_index: predicted_value_4.top_height_index + predicted_value_4.block_height-1, predicted_value_4.left_width_index: predicted_value_4.left_width_index + predicted_value_4.block_width-1) = uint8(processedBlock_4.data);
                                                    count=count+1;
                                                    SAD4=[SAD4 SAD_4];
                                                    %                                             mode4=[mode4 predicted_value_4.Mode];
                                                end
                                            end
                                            cost_para=RDO(predicted_value.data,predictedblock_4_para,obj.block_height,obj.block_width,SAD,SAD4,obj.QP);
                                            if(cost_para.flag==0 || obj.VBSEnable==0)
                                                reconstructedVideo(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = reference_frame1_para(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                                labSend(reconstructedVideo(:,:,i),1);
                                                reconstructedVideo(:,:,i)=labReceive(1);
                                                temp_stream_even=[temp_stream_even temp_stream];
                                                disp(new_index)
                                                temp_stream=[];
                                                %disp('qwer');
                                                if(mod(new_index,length_temp)==0)
                                                    %disp('z');
                                                    labSend(temp_stream_even,1);
                                                    temp_stream_even=[];
                                                end
                                                if(new_index==length-1)
                                                    %disp('i');
                                                    labSend(temp_stream_even,1);
                                                    temp_stream_even=[];
                                                end
                                            else
                                                labSend(reference_frame4_para,1);
                                                reference_frame4_para=labReceive(1);
                                                reconstructedVideo(:,:,i)=reference_frame4_para;
                                                temp_stream_even=[temp_stream_even temp_stream4];
                                                temp_stream=[];
                                                %disp('asdfgy');
                                                if(mod(new_index,length_temp)==0)
                                                    %disp('z');
                                                    labSend(temp_stream_even,1);
                                                    temp_stream_even=[];
                                                end
                                                if(new_index==length-1)
                                                    %disp('i');
                                                    labSend(temp_stream_even,1);
                                                    temp_stream_even=[];
                                                end
                                            end
                                        else
                                            reconstructedVideo(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1,i) = reference_frame1_para(predicted_value.top_height_index:predicted_value.top_height_index + obj.block_height-1,predicted_value.left_width_index:predicted_value.left_width_index + obj.block_width-1);
                                            labSend(reconstructedVideo(:,:,i),1);
                                            reconstructedVideo(:,:,i)=labReceive(1);
                                            temp_stream_even=[temp_stream_even en.bitstream];
                                            disp(new_index)                                
                                            %disp('dfg');
                                            if(mod(new_index,length_temp)==0)
                                                %disp('z');
                                                labSend(temp_stream_even,1);
                                                temp_stream_even=[];
                                            end
                                            if(new_index==length-1)
                                                %disp('i');
                                                labSend(temp_stream_even,1);
                                                 temp_stream_even=[];
                                            end
                                        end
                                        if(obj.ParallelMode==3 && type(i+1)==0)
%                                             if new_index==(obj.r)*length_temp
                                            if new_index>=(obj.r+2)*length_temp && mod(new_index,length_temp)==0
%                                             disp(new_index)
                                                block_list_next= obj.truncateFrameToBlocks(i+1);
                                                start=initial;
                                                stop=n*length_temp;
%                                                 recon_temp=reconstructedVideo;
                                                [data,nextstream]=inter_comp(obj,i+1,reconstructedVideo,lastIFrame,type,start,stop);
                                                next_reconstructedVideo(block_list_next(start).top_height_index:block_list_next(start).top_height_index + 2*obj.block_height-1,block_list_next(start).left_width_index:block_list_next(stop).left_width_index + obj.block_width-1)=data(block_list_next(start).top_height_index:block_list_next(start).top_height_index + 2*obj.block_height-1,block_list_next(start).left_width_index:block_list_next(stop).left_width_index + obj.block_width-1);
%                                                 next_reconstructedVideo=data;
        %                                             disp(size(g));
                                                initial=stop+1;
                                                n=n+2;
%                                                 disp(n)
                                            end
                                        end
                                        
                                    end
                                    
                                end
                                if(obj.ParallelMode==3 && type(i+1)==1)
                                    if labindex==3
                                        next_frame=zeros( obj.inputvideo.width , obj.inputvideo.height);
                                        [next_frame,nextstream]=intra_comp(obj,i+1,type);
                                    end
                                end
                            end
                            temp_value=reconstructedVideo{1};
                            obj.reconstructedVideo.Y(:,:,i)=temp_value(:,:,i);
                            obj.OutputBitstream = [obj.OutputBitstream para_stream{1}];
%                             if(obj.ParallelMode==3)
%                                 temp_reconVid=next_reconstructedVideo{2};
%                                 obj.reconstructedVideo.Y(:,:,i+1)=temp_reconVid(:,:);
%                                 start=16*length_temp+1;
%                                 stop=length;
%                                 p=inter_comp(obj,i+1,obj.reconstructedVideo.Y,lastIFrame,type,start,stop)
%                                 obj.reconstructedVideo.Y(:,:,i+1)=obj.reconstructedVideo.Y(:,:,i+1)+double(p);
%                             end
                            
                            index=index+k{1}-2;
                            reference_frame4=obj.reconstructedVideo.Y(:,:,i);
                            end
                    end
                else
                    %inter
                    disp(i)
                    block_list = obj.truncateFrameToBlocks(i);
                    length = size(block_list,2);
                    previousMV = MotionVector(0,0);
                    previousFrameIndex = 0;
                    %for loop to go through all blocks
                    reconstructedVideo=obj.reconstructedVideo.Y;
                    reconstructedVideo(:,:,i) = zeros( obj.inputvideo.width , obj.inputvideo.height);
                    length_temp=obj.inputvideo.height/obj.block_height;
                    index=0;
                    spmd
                        while index<length-length_temp
                            %                         while index<length_temp
                            index=index+1;
                            if(mod(index-1,length_temp)==0 && index~=1)
                                index=index+length_temp;
                            end
%                                                         disp(index)
%                                                         disp(index+length_temp)
%                                                     for index=1:1:length
%                             RDO computation of block_list(index)
%                             if futher truncate
%                             if not do one time
%                             doing the truncation
%                             split or not
%                             
                            min_value = 9999999;
                            outstream=[];
                            % for loop to go through multiple reference frame
                            % to get best matched block
                            if labindex==1
                                for referenceframe_index = i - obj.nRefFrame: 1 : i-1
                                    % check starts from last I frame or input parameter nRefFrame.
                                    if referenceframe_index >= lastIFrame
                                        if obj.VBSEnable == false
                                            ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(reconstructedVideo(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                            if ME_result.differenceForBestMatchBlock < min_value
                                                min_value = ME_result.differenceForBestMatchBlock;
                                                bestMatchBlock = ME_result.bestMatchBlock;
                                                bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                            end
                                        else
                                            ME_result = MotionEstimationEngine(obj.r,block_list(index), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                            bestMatchBlockNoSplit = ME_result.bestMatchBlock;
                                            bestMatchBlockNoSplit.referenceFrameIndex = i - referenceframe_index;
                                            
                                            % variable block size
                                            SAD4=zeros( 1 ,4);
                                            SubBlockList = [];
                                            previousMVSubBlock = previousMV;
                                            
                                            %truncate the original block to
                                            %four sub blocks
                                            subBlock_list = obj.VBStruncate(block_list(index));
                                            row_i = 1;
                                            col_i = 1;
                                            for subBlockIndex = 1:1:size(subBlock_list,2)
                                                %for each block, doing the Motion
                                                %Estimation
                                                SubBlockME_result = MotionEstimationEngine(obj.r,subBlock_list(subBlockIndex), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
                                                SAD4(col_i + (row_i - 1) * 2)= SubBlockME_result.differenceForBestMatchBlock;
                                                SubBlockME_result.bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                                SubBlockME_result.bestMatchBlock.split=1;
                                                previousMVSubBlock = SubBlockME_result.bestMatchBlock.MotionVector;
                                                curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                                curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                                predictedblock_4(curr_row,curr_col)=SubBlockME_result.bestMatchBlock.data;
                                                SubBlockList = [SubBlockList SubBlockME_result.bestMatchBlock];
                                                col_i = col_i + 1;
                                                if col_i > 2
                                                    row_i = row_i + 1;
                                                    col_i = 1;
                                                end
                                            end
                                            cost=RDO(bestMatchBlockNoSplit.data,predictedblock_4,obj.block_height,obj.block_width,ME_result.differenceForBestMatchBlock,SAD4,obj.QP);
                                            if(cost.flag~=0)
                                                % split has smaller RDO
                                                if cost.RDO_cost4 < min_value
                                                    min_value = cost.RDO_cost4;
                                                    bestMatchBlock = SubBlockList;
                                                end
                                            else
                                                % no split has smaller RDO
                                                if cost.RDO_cost1 < min_value
                                                    min_value = cost.RDO_cost1;
                                                    bestMatchBlock = bestMatchBlockNoSplit;
                                                end
                                            end
                                        end
                                    end
                                end
                                prev_value=reconstructedVideo(:,:,i);
                                for bestMatchBlockIndex = 1:1:size(bestMatchBlock,2)
                                    %set the frame type for the block
                                    bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setframeType(type(i));
                                    
                                    %differential encoding for motion vector
                                    tempPreviousMV = bestMatchBlock(bestMatchBlockIndex).MotionVector;
                                    bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setbitMotionVector( MotionVector(previousMV.x - bestMatchBlock(bestMatchBlockIndex).MotionVector.x, previousMV.y - bestMatchBlock(bestMatchBlockIndex).MotionVector.y));
                                    previousMV = tempPreviousMV;
                                    
                                    %differential encoding for reference frame index
                                    tempPreviousFrameIndex = bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                    bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex = previousFrameIndex - bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                    previousFrameIndex = tempPreviousFrameIndex;
                                    
                                    %                                         obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(bestMatchBlock(bestMatchBlockIndex).data);
                                    
                                    [processedBlock, en] = obj.generateReconstructedFrame(i,bestMatchBlock(bestMatchBlockIndex) );
                                    reconstructedVideo(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(processedBlock.data);
%                                     obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
                                    outstream=[outstream en.bitstream];
                                end
                                reconstructedVideo(:,:,i)=abs(reconstructedVideo(:,:,i)-labReceive(2));
                                reconstructedVideo(:,:,i)=reconstructedVideo(:,:,i)+prev_value;
                                labSend(reconstructedVideo,2);
                                if(mod(index,length_temp==0))
                                outstream=[outstream labReceive(2)];
                                end
                            end
                            if(labindex==2)
                                
                                for referenceframe_index = i - obj.nRefFrame: 1 : i-1
                                    % check starts from last I frame or input parameter nRefFrame.
                                    if referenceframe_index >= lastIFrame
                                        if obj.VBSEnable == false
                                            ME_result = MotionEstimationEngine(obj.r,block_list(index+length_temp), uint8(reconstructedVideo(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                            if ME_result.differenceForBestMatchBlock < min_value
                                                min_value = ME_result.differenceForBestMatchBlock;
                                                bestMatchBlock = ME_result.bestMatchBlock;
                                                bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                            end
                                        else
                                            ME_result = MotionEstimationEngine(obj.r,block_list(index+length_temp), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width, obj.block_height,obj.FEMEnable, obj.FastME, previousMV);
                                            bestMatchBlockNoSplit = ME_result.bestMatchBlock;
                                            bestMatchBlockNoSplit.referenceFrameIndex = i - referenceframe_index;
                                            
                                            % variable block size
                                            SAD4=zeros( 1 ,4);
                                            SubBlockList = [];
                                            previousMVSubBlock = previousMV;
                                            
                                            %truncate the original block to
                                            %four sub blocks
                                            subBlock_list = obj.VBStruncate(block_list(index+length_temp));
                                            row_i = 1;
                                            col_i = 1;
                                            for subBlockIndex = 1:1:size(subBlock_list,2)
                                                %for each block, doing the Motion
                                                %Estimation
                                                SubBlockME_result = MotionEstimationEngine(obj.r,subBlock_list(subBlockIndex), uint8(obj.reconstructedVideo.Y(:,:,referenceframe_index)), obj.block_width/2, obj.block_height/2,obj.FEMEnable, obj.FastME, previousMVSubBlock);
                                                SAD4(col_i + (row_i - 1) * 2)= SubBlockME_result.differenceForBestMatchBlock;
                                                SubBlockME_result.bestMatchBlock.referenceFrameIndex = i - referenceframe_index;
                                                SubBlockME_result.bestMatchBlock.split=1;
                                                previousMVSubBlock = SubBlockME_result.bestMatchBlock.MotionVector;
                                                curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                                                curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                                                predictedblock_4(curr_row,curr_col)=SubBlockME_result.bestMatchBlock.data;
                                                SubBlockList = [SubBlockList SubBlockME_result.bestMatchBlock];
                                                col_i = col_i + 1;
                                                if col_i > 2
                                                    row_i = row_i + 1;
                                                    col_i = 1;
                                                end
                                            end
                                            cost=RDO(bestMatchBlockNoSplit.data,predictedblock_4,obj.block_height,obj.block_width,ME_result.differenceForBestMatchBlock,SAD4,obj.QP);
                                            if(cost.flag~=0)
                                                % split has smaller RDO
                                                if cost.RDO_cost4 < min_value
                                                    min_value = cost.RDO_cost4;
                                                    bestMatchBlock = SubBlockList;
                                                end
                                            else
                                                % no split has smaller RDO
                                                if cost.RDO_cost1 < min_value
                                                    min_value = cost.RDO_cost1;
                                                    bestMatchBlock = bestMatchBlockNoSplit;
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                for bestMatchBlockIndex = 1:1:size(bestMatchBlock,2)
                                    %set the frame type for the block
                                    bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setframeType(type(i));
                                    
                                    %differential encoding for motion vector
                                    tempPreviousMV = bestMatchBlock(bestMatchBlockIndex).MotionVector;
                                    bestMatchBlock(bestMatchBlockIndex) = bestMatchBlock(bestMatchBlockIndex).setbitMotionVector( MotionVector(previousMV.x - bestMatchBlock(bestMatchBlockIndex).MotionVector.x, previousMV.y - bestMatchBlock(bestMatchBlockIndex).MotionVector.y));
                                    previousMV = tempPreviousMV;
                                    
                                    %differential encoding for reference frame index
                                    tempPreviousFrameIndex = bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                    bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex = previousFrameIndex - bestMatchBlock(bestMatchBlockIndex).referenceFrameIndex;
                                    previousFrameIndex = tempPreviousFrameIndex;
                                    
                                    %                                         obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(bestMatchBlock(bestMatchBlockIndex).data);
                                    
                                    [processedBlock, en] = obj.generateReconstructedFrame(i,bestMatchBlock(bestMatchBlockIndex) );
                                    reconstructedVideo(processedBlock.top_height_index:processedBlock.top_height_index + bestMatchBlock(bestMatchBlockIndex).block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + bestMatchBlock(bestMatchBlockIndex).block_width-1,i) = uint8(processedBlock.data);
                                    outstream = [outstream en.bitstream];
                                end
                                labSend(reconstructedVideo(:,:,i),1);
                                reconstructedVideo=labReceive(1);
                                if(mod(index,length_temp==0))
                                    labSend(outstream,1);
                                    outstream=[];
                                end

                                if(obj.ParallelMode==3 && type(i+1)==0)
%                                             if new_index==(obj.r)*length_temp
                                    if new_index>=(obj.r+2)*length_temp && mod(new_index,length_temp)==0
%                                             disp(new_index)
                                        block_list_next= obj.truncateFrameToBlocks(i+1);
                                        start=initial;
                                        stop=n*length_temp;
%                                                 recon_temp=reconstructedVideo;
                                        [data,nextstream]=inter_comp(obj,i+1,reconstructedVideo,lastIFrame,type,start,stop);
                                        next_reconstructedVideo(block_list_next(start).top_height_index:block_list_next(start).top_height_index + 2*obj.block_height-1,block_list_next(start).left_width_index:block_list_next(stop).left_width_index + obj.block_width-1)=data(block_list_next(start).top_height_index:block_list_next(start).top_height_index + 2*obj.block_height-1,block_list_next(start).left_width_index:block_list_next(stop).left_width_index + obj.block_width-1);
%                                                 next_reconstructedVideo=data;
%                                             disp(size(g));
                                        initial=stop+1;
                                        n=n+2;
                                                disp(n)
                                    end
                                end
                            end
                        end
                        if(obj.ParallelMode==3 && type(i+1)==1)
                            if labindex==3
                                next_frame=zeros( obj.inputvideo.width , obj.inputvideo.height);                   
                                [next_frame,nextstream]=intra_comp(obj,i+1,type);
                            end
                        end
                    end   
                    obj.OutputBitstream = [obj.OutputBitstream outstream{1}];
                    obj.reconstructedVideo.Y=reconstructedVideo{1};
                    if(obj.ParallelMode==3 && type(i+1)==1)
                        %disp('asd');
                        temp=next_frame{3};
                        obj.reconstructedVideo.Y(:,:,i+1)=temp;
                        i=i+1;
                        %disp('done')
                        obj.OutputBitstream = [obj.OutputBitstream next_frame{3}];
                    end
                    
                end
            end
        end
        

        function blockList = truncateFrameToBlocks(obj,frameIndex)
            %This function truncate the frame and to blocks.
            %from each truncated block in current frame, it gets the best
            % matched block from reference frame according to given r
            %then it gets the residualBlock from best matched block minus
            %current block.
            blockList = [];
            height = size(obj.inputvideo.Y(:,:,frameIndex),1);
            width = size(obj.inputvideo.Y(:,:,frameIndex),2);
            for i=1:obj.block_height:height
                for j=1:obj.block_width:width
                    currentBlock = Block(obj.inputvideo.Y(:,:,frameIndex), j,i, obj.block_width, obj.block_height );
                    %currentBlock = currentBlock.setQP(obj.QP);
                    blockList = [blockList, currentBlock];
                end
            end
        end


        function subBlockList = VBStruncate(obj,blcok)
            %This function truncate the frame and to blocks.
            %from each truncated block in current frame, it gets the best
            % matched block from reference frame according to given r
            %then it gets the residualBlock from best matched block minus
            %current block.
            subBlockList = [];
            height = blcok.block_height;
            width = blcok.block_width;


            col = 0;
            for j=1:obj.block_width/2:width
                row = 0;
                for i=1:obj.block_height/2:height
                    currentSubBlock = Block(blcok.data, j,i, obj.block_width/2, obj.block_height/2 );
                    currentSubBlock.top_height_index = blcok.top_height_index + (col) * obj.block_width/2;
                    currentSubBlock.left_width_index = blcok.left_width_index + (row) * obj.block_height/2;
                    currentSubBlock = currentSubBlock.setQP(obj.QP - 1);
                    subBlockList = [subBlockList, currentSubBlock];
                    row = row + 1;
                end
                col = col + 1;
            end
        end
    end
end
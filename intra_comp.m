function [next_frame,OutputBitstream] = intra_comp(obj,i,type)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
next_frame = zeros( obj.inputvideo.width , obj.inputvideo.height);
% lastIFrame = i;
reference_frame1=[];
reference_frame4=[];
%truncate current frame to fix size block list
%according to the input block size
block_list = obj.truncateFrameToBlocks(i);
length = size(block_list,2);
for index=1:1:length
    intrapred=IntraPredictionEngine(block_list(index),next_frame);
    intrapred=intrapred.block_creation();
    if(obj.VBSEnable==0)
        % if no VBS required, just direct do the intra
        % prediction on the blocks
        predicted_block=intrapred.blocks;
        predicted_block.data=intrapred.predictedblock;
        predicted_block.split=0;
        predicted_block = predicted_block.setframeType(type(i));
        [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
        next_frame(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
%         obj.OutputBitstream = [obj.OutputBitstream en.bitstream];
    else
        %VBS required
        %first do the full block prediction
        temp_bitstream1=[];
        predicted_block=intrapred.blocks;
        predicted_block.data=intrapred.predictedblock;
        predicted_block.split=0;
        predicted_block = predicted_block.setframeType(type(i));
        [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_block );
        reference_frame1(processedBlock.top_height_index:processedBlock.top_height_index + obj.block_height-1,processedBlock.left_width_index:processedBlock.left_width_index + obj.block_width-1) = uint8(processedBlock.data);
        temp_bitstream1=en.bitstream;
        
        %do the sub block prediction
        count=1;
        SAD4=zeros( 1 ,4);
        mode4=zeros( 1 ,4);
        temp_bitstream4=[];
        predictedblock_4 = zeros( obj.block_width,obj.block_height);
        reference_frame4 = next_frame;
        for row_i =1:1:2
            for col_i=1:1:2
                intrapred_4=IntraPredictionEngine(block_list(index),reference_frame4);
                intrapred_4=intrapred_4.block_creation4(count);
                predicted_sub_block=intrapred_4.blocks;
                predicted_sub_block.data=intrapred_4.smallblock_4;
                predicted_sub_block.split=1;
                predicted_sub_block.QP=obj.QP-1;
                predicted_sub_block = predicted_sub_block.setframeType(type(i));
                [processedBlock, en] = obj.generateReconstructedFrame(i,predicted_sub_block );
                temp_bitstream4=[temp_bitstream4 en.bitstream];
                curr_row=1+((row_i-1)*obj.block_height/2):(row_i)*obj.block_height/2;
                curr_col=1+((col_i-1)*obj.block_width/2):(col_i)*obj.block_width/2;
                predictedblock_4(curr_row,curr_col)=intrapred_4.smallblock_4;
                reference_frame4(predicted_sub_block.top_height_index: predicted_sub_block.top_height_index + predicted_sub_block.block_height-1, predicted_sub_block.left_width_index: predicted_sub_block.left_width_index + predicted_sub_block.block_width-1) = uint8(processedBlock.data);
                SAD4(count)= intrapred_4.SAD_4;
                mode4(count)=predicted_sub_block.Mode;
                count=count+1;
            end
        end
        cost=RDO(predicted_block.data,predictedblock_4,obj.block_height,obj.block_width,intrapred.SAD,SAD4,obj.QP);
        if(cost.flag==0)
            next_frame(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1) = reference_frame1(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
            OutputBitstream = [obj.OutputBitstream temp_bitstream1];
            %obj.predictionVideo(processedBlock.top_height_index:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predicted_block.data);
        else
            next_frame(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1) = reference_frame4(predicted_block.top_height_index:predicted_block.top_height_index + obj.block_height-1,predicted_block.left_width_index:predicted_block.left_width_index + obj.block_width-1);
            OutputBitstream = [obj.OutputBitstream temp_bitstream4];
            %obj.predictionVideo(1:processedBlock.top_height_index + 16-1,processedBlock.left_width_index:processedBlock.left_width_index + 16-1,i) = uint8(predictedblock_4);
        end
    end
end
end


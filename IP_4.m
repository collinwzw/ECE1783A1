function [output_block,SAD_4] = IP_4(block_list,reconstructedVideo,count,QP)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
intrapred=IntraPredictionEngine(block_list,reconstructedVideo(:,:));
intrapred=intrapred.block_creation4(count);
predicted_value=intrapred.blocks;
predicted_value.data=intrapred.smallblock_4;
predicted_value.split=1;
if obj.QP >= 1
    predicted_sub_block.QP=obj.QP-1;
else
    predicted_sub_block.QP=obj.QP;
end
predicted_value = predicted_value.setframeType(1);
output_block = predicted_value;
SAD_4=intrapred.SAD_4;
end



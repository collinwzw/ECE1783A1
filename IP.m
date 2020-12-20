function [output_block,SAD] = IP(block_list,reconstructedVideo)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
intrapred=IntraPredictionEngine(block_list,reconstructedVideo(:,:));
intrapred=intrapred.block_creation();
predicted_value=intrapred.blocks;
predicted_value.data=intrapred.predictedblock;
predicted_value.split=0;
% predicted_value = predicted_value.setframeType(1);
output_block = predicted_value;
SAD=intrapred.SAD;
end



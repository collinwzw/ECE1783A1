function [outputArg1,outputArg2] = block_creation(width,height,Y,size)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if(rem(width,size)==0)
    Y_block(1:size,1:size)=0;
else
    pad_len=size-(rem(width,size));
end

if(rem(height,size)==0)
    Y_block(1:size,1:size)=0;
else
    pad_height=size-(rem(height,size));
end
Y_New=Y;
Y_New(width+1:width+pad_len,height+1:height+pad_height,:)=uint8(127);
Y_New(:,height+1:height+pad_height,:)=uint8(127);
Y_New(width+1:width+pad_len,:,:)=uint8(127);
for k=1:1:300
    for i=1:size:width+pad_len
        for j=1:size:height+pad_height
            Y_block=Y_New(i:i+size-1,j:j+size-1,k);
            mean_value=round(mean(Y_block,'all'));
            av_Y(i:i+size-1,j:j+size-1,k)=mean_value;
        end
    end
end
outputArg1 = Y_New;
outputArg2 = av_Y;
end


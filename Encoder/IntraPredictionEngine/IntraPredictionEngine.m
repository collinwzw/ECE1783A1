classdef IntraPredictionEngine
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess='public', SetAccess='public')
        reference_frame;
        blocks;
        curr_block;
        mode;
        predictedblock;
        flag;
        smallblock_4;
        predictedblock_4;
        mode_4;
        SAD;
        SAD_4=[];
        final_frame;
        RDO_flag;
    end
    
    methods
        function obj = IntraPredictionEngine(block_list,frame)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.reference_frame=frame;
            obj.blocks=block_list;

        end
   
        function obj = block_creation(obj)
            obj.flag=0;
%             i_pos=(bl_i-1)*obj.block_height+1;
%             j_pos=(bl_j-1)*obj.block_width+1;
            if(obj.blocks.left_width_index==1 && obj.blocks.top_height_index==1)
                prev_col(1:obj.blocks.block_width,1)=128;
                prev_row(1,1:obj.blocks.block_height)=128;
            end
            if(obj.blocks.top_height_index==1)
                prev_row(1,1:obj.blocks.block_height)=128;
            end
            if(obj.blocks.left_width_index~=1)
                prev_col=obj.reference_frame(obj.blocks.top_height_index:obj.blocks.top_height_index+obj.blocks.block_height-1,obj.blocks.left_width_index-1);
            end
            if(obj.blocks.left_width_index==1)
                prev_col(1:obj.blocks.block_width,1)=128;
            end
            if(obj.blocks.top_height_index~=1)
                prev_row=obj.reference_frame(obj.blocks.top_height_index-1,obj.blocks.left_width_index:obj.blocks.left_width_index+obj.blocks.block_width-1);
            end
            obj.curr_block=obj.blocks.data;
            obj = obj.intraPredictBlock(obj.curr_block,prev_row,prev_col);
            
        end
        
        function obj = block_creation4(obj,count)
            obj.flag=1;
            obj.blocks.block_height=8;
            obj.blocks.block_width=8;
                    if(count==1)
                        bl4_i=obj.blocks.top_height_index;
                        bl4_j=obj.blocks.left_width_index;
                        row_i=1;
                        col_i=1;
                    end
                    if(count==2)
                        bl4_i=obj.blocks.top_height_index;
                        bl4_j=obj.blocks.left_width_index + obj.blocks.block_width;
                        row_i=1;
                        col_i=2;
                    end
                    if(count==3)
                        bl4_i=obj.blocks.top_height_index + obj.blocks.block_height;
                        bl4_j=obj.blocks.left_width_index;
                        row_i=2;
                        col_i=1;
                    end
                    if(count==4)
                        bl4_i=obj.blocks.top_height_index+obj.blocks.block_width;
                        bl4_j=obj.blocks.left_width_index+obj.blocks.block_height;
                        row_i=2;
                        col_i=2;
                    end
                    
                    
                    if(bl4_i==1)
                        prev_row(1,1:obj.blocks.block_height)=128;
                    end
                    if(bl4_j~=1)
                        prev_col=obj.reference_frame(bl4_i:bl4_i+(obj.blocks.block_height)-1,bl4_j-1);
                    end
                    if(bl4_j==1)
                        prev_col(1:obj.blocks.block_width,1)=128;
                    end
                    if(bl4_i~=1)
                        prev_row=obj.reference_frame(bl4_i-1,bl4_j:bl4_j+(obj.blocks.block_width)-1);
                    end
                    obj.curr_block=obj.blocks.data((row_i-1)*obj.blocks.block_height + 1: (row_i)*obj.blocks.block_height,(col_i-1)*obj.blocks.block_width + 1:(col_i-1)*obj.blocks.block_width + 1);
                    obj = obj.intraPredictBlock(obj.curr_block,prev_row,prev_col);
                    curr_row=1+((row_i-1)*obj.blocks.block_height):(row_i)*obj.blocks.block_height;
                    curr_col=1+((col_i-1)*obj.blocks.block_width):(col_i)*obj.blocks.block_width;
                    obj.predictedblock_4(curr_row,curr_col)=obj.smallblock_4;

                    obj.blocks.top_height_index=obj.blocks.top_height_index+((row_i-1)*obj.blocks.block_height);
                    obj.blocks.left_width_index=obj.blocks.left_width_index+((col_i-1)*obj.blocks.block_width);
                    
        end
   end
   methods(Access = 'private')
        function obj = intraPredictBlock(obj, block,prev_row,prev_col)
            pred_block_ver=obj.verprediction(block,prev_row);
            pred_block_hor=obj.horprediction(block,prev_col);
            obj = obj.prediction(pred_block_ver,pred_block_hor,obj.curr_block);
        end
        
        
        function vertical_prediction = verprediction(obj,block,prev_value)
            vertical_prediction=block;
            if(obj.flag==0)
                for j=1:size(prev_value,2)
                    vertical_prediction(1:obj.blocks.block_height,j)=prev_value(j);
                end
            else
                for j=1:size(prev_value,2)
                    vertical_prediction(1:obj.blocks.block_height,j)=prev_value(j);
                end
            end
        end
        
        function horizontal_prediction = horprediction(obj,block,prev_value)
            horizontal_prediction=block;
            if(obj.flag==0)
            for i=1:size(prev_value,1)
               horizontal_prediction(i,1:obj.blocks.block_width)=prev_value(i);
            end
            else
               for i=1:size(prev_value,1)
                horizontal_prediction(i,1:obj.blocks.block_width)=prev_value(i);
               end
            end
        end
        
        function obj = prediction(obj,pred_block_ver,pred_block_hor,actual_block)
            SAD_h=abs( sum(pred_block_hor,'all') - sum(actual_block,'all'));
            SAD_v=abs( sum(pred_block_ver,'all') - sum(actual_block,'all'));
            if(obj.flag==0)
                if(SAD_h<=SAD_v)
                    obj.blocks.Mode=0;
                    obj.predictedblock=pred_block_hor;
                    obj.SAD=SAD_h;
                else
                    obj.blocks.Mode=1;
                    obj.predictedblock=pred_block_ver;
                    obj.SAD=SAD_v;
                end
            elseif (obj.flag==1)
                if(SAD_h<=SAD_v)
                    obj.blocks.Mode=0;
                    obj.smallblock_4=pred_block_hor;
                    obj.SAD_4=[obj.SAD_4 SAD_h];
                else
                    obj.blocks.Mode=1;
                    obj.smallblock_4=pred_block_ver;
                    obj.SAD_4=[obj.SAD_4 SAD_v];
                end
            end
        
        end
        
    end
end


classdef IntraPredictionEngine
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        input_frame;
        curr_block;
        mode;
        predictedblock;
    end
    
    methods (Access = 'public')
        function obj = IntraPredictionEngine(frame,block_width, block_height,bl_i,bl_j)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.input_frame=frame;
            obj = obj.block_creation(bl_i,bl_j);
        end
    end
   methods(Access = 'private')
        function obj = block_creation(obj,bl_i,bl_j)
%             i_pos=(bl_i-1)*obj.block_height+1;
%             j_pos=(bl_j-1)*obj.block_width+1;
            if(bl_i==1 && bl_j==1)
                prev_col(1:obj.block_width,1)=128;
                prev_row(1,1:obj.block_height)=128;
            end
            if(bl_i==1)
                prev_row(1,1:obj.block_height)=128;
            end
            if(bl_j~=1)
                prev_col=obj.input_frame(bl_i:bl_i+obj.block_height-1,bl_j-1);
            end
            if(bl_j==1)
                prev_col(1:obj.block_width,1)=128;
            end
            if(bl_i~=1)
                prev_row=obj.input_frame(bl_i-1,bl_j:bl_j+obj.block_width-1);
            end
            obj.curr_block=obj.input_frame(bl_i:bl_i+obj.block_height-1,bl_j:bl_j+obj.block_height-1);
            obj = obj.intraPredictBlock(obj.curr_block,prev_row,prev_col);
            
        end
        
        
        function obj = intraPredictBlock(obj, block,prev_row,prev_col)
            pred_block_ver=obj.verprediction(block,prev_row);
            pred_block_hor=obj.horprediction(block,prev_col);
            obj = obj.prediction(pred_block_ver,pred_block_hor,obj.curr_block);
        end
        
        
        function vertical_prediction = verprediction(obj,block,prev_value)
            vertical_prediction=block;
                for j=1:size(prev_value,2)
                    vertical_prediction(1:obj.block_height,j)=prev_value(j);
                end
        end
        
        function horizontal_prediction = horprediction(obj,block,prev_value)
            horizontal_prediction=block;
            for i=1:size(prev_value,1)
               horizontal_prediction(i,1:obj.block_width)=prev_value(i);
            end
        end
        
        function obj = prediction(obj,pred_block_ver,pred_block_hor,actual_block)
            SAD_h=abs( sum(pred_block_hor,'all') - sum(actual_block,'all'));
            SAD_v=abs( sum(pred_block_ver,'all') - sum(actual_block,'all'));
    
            if(SAD_h>=SAD_v)
                obj.mode=0;
                obj.predictedblock=pred_block_hor;
            else
                obj.mode=1;
                obj.predictedblock=pred_block_ver;
            end
        
        end
        
    end
end


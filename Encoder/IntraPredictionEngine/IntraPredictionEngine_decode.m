classdef IntraPredictionEngine_decode
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        input_frame;
        curr_block;
        mode;
        predictedblock;
        decoded_frame;
        decoded_block;
    end
    
    methods (Access = 'public')
        function obj = IntraPredictionEngine_decode(frame,block_width, block_height,bl_i,bl_j,mode,ori_frame)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.input_frame=frame;
            obj.decoded_frame=ori_frame;
            obj.mode=mode;
            obj = obj.block_creation(bl_i,bl_j);

        end
    end
   methods(Access = 'private')
        function obj = block_creation(obj,bl_i,bl_j)
%             i_pos=(bl_i-1)*obj.block_height+1;
%             j_pos=(bl_j-1)*obj.block_width+1;
            if(bl_i==1)
                prev_row(1,1:obj.block_height)=128;
            end
            if(bl_j~=1)
                prev_col=obj.decoded_frame(bl_i:bl_i+obj.block_height-1,bl_j-1);
            end
            if(bl_j==1)
                prev_col(1:obj.block_width,1)=128;
            end
            if(bl_i~=1)
                prev_row=obj.decoded_frame(bl_i-1,bl_j:bl_j+obj.block_width-1);
            end
            obj.curr_block=obj.input_frame(bl_i:bl_i+obj.block_height-1,bl_j:bl_j+obj.block_height-1);
            obj = obj.intraPredictdecodeBlock(obj.curr_block,prev_row,prev_col);
            
        end
        
        
        function obj = intraPredictdecodeBlock(obj, block,prev_row,prev_col)
            if(obj.mode==0)
                pred_block_hor=obj.hordecode(block,prev_col);
                obj.decoded_block=pred_block_hor;
            elseif(obj.mode==1)
                pred_block_ver=obj.verdecode(block,prev_row);
                obj.decoded_block=pred_block_ver;
            end
            
        end
        
        
        function vertical_prediction = verdecode(obj,block,prev_value)
            vertical_prediction=block;
            for i=1:size(prev_value,1)
                for j=1:size(prev_value,2)
                vertical_prediction(1:obj.block_height,j)=prev_value(j)-obj.curr_block(1:obj.block_height,j);
                end
            end
        end
        
        function horizontal_prediction = hordecode(obj,block,prev_value)
            horizontal_prediction=block;
            for i=1:size(prev_value,1)
                for j=1:size(prev_value,2)
                horizontal_prediction(i,1:obj.block_width)=prev_value(i)-obj.curr_block(i,1:obj.block_width);
                end
            end
        end
        
    end
end


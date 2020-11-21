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
        blocks;
    end
    
    methods (Access = 'public')
        function obj = IntraPredictionEngine_decode(block,decoded_frame)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.blocks=block;
            obj.block_width=obj.blocks.block_width;
            obj.block_height=obj.blocks.block_height;
            obj.decoded_frame=decoded_frame;
            obj = obj.block_creation();

        end
    end
   methods(Access = 'private')
        function obj = block_creation(obj)
%             i_pos=(bl_i-1)*obj.block_height+1;
%             j_pos=(bl_j-1)*obj.block_width+1;
            if(obj.blocks.top_height_index==1)
                prev_row(1,1:obj.blocks.block_height)=128;
            end
            if(obj.blocks.left_width_index~=1)
                prev_col=obj.decoded_frame(obj.blocks.top_height_index:obj.blocks.top_height_index+obj.blocks.block_height-1,obj.blocks.left_width_index-1);
            end
            if(obj.blocks.left_width_index==1)
                prev_col(1:obj.blocks.block_width,1)=128;
            end
            if(obj.blocks.top_height_index~=1)
                prev_row=obj.decoded_frame(obj.blocks.top_height_index-1,obj.blocks.left_width_index:obj.blocks.left_width_index+obj.blocks.block_width-1);
            end
            obj = obj.intraPredictdecodeBlock(prev_row,prev_col);
            
        end
        
        
        function obj = intraPredictdecodeBlock(obj,prev_row,prev_col)
            if(obj.blocks.Mode==0)
                pred_block_hor=obj.horizontaldecode(prev_col);
                obj.decoded_block=pred_block_hor;
            elseif(obj.blocks.Mode==1)
                pred_block_ver=obj.verticaldecode(prev_row);
                obj.decoded_block=pred_block_ver;
            end
            
        end
        
        
        function vertical_prediction = verticaldecode(obj,prev_value)
            vertical_prediction=[];
            for i=1:size(prev_value,1)
                for j=1:size(prev_value,2)
                vertical_prediction(1:obj.block_height,j)=prev_value(j);
                end
            end
        end
        
        function horizontal_prediction = horizontaldecode(obj,prev_value)
            horizontal_prediction=[];
            for i=1:size(prev_value,1)
                for j=1:size(prev_value,2)
                horizontal_prediction(i,1:obj.block_width)=prev_value(i);
                end
            end
        end
        
    end
end


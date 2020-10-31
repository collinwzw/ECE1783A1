classdef IntraPredictionEngine
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess='public', SetAccess='public')
        block_width;
        block_height;
        input_frame;
        actual_block;
        modeFrame;
        predictedFrame;
    end
    
    methods (Access = 'public')
        function obj = IntraPredictionEngine(frame,block_width, block_height)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.block_width=block_width;
            obj.block_height=block_height;
            obj.input_frame=frame;
            obj = obj.intraPredictFrame();
        end
    end
   methods(Access = 'private')   
        function [mode,block] = intraPredictBlock(obj, block)
            pred_block_ver=obj.verprediction(block.data);
            pred_block_hor=obj.horprediction(block.data);
            [mode,block] = obj.prediction(pred_block_ver,pred_block_hor,block.data);
        end
        
        function obj = intraPredictFrame(obj)
            col = 1;
            row = 1;
            for i=1:obj.block_height:size(obj.input_frame,1)  
                for j=1:obj.block_width:size(obj.input_frame,2)
                        currentBlock = Block(obj.input_frame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
                        [mode, predictedBlock] = obj.intraPredictBlock(currentBlock);
                        obj.predictedFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = predictedBlock;
                        obj.modeFrame(row,col) = mode;
                        col = col + 1;
                end
                row = row + 1;
                col = 1;
            end
        end
        
        function vertical_prediction = verprediction(obj,block)
            vertical_prediction=block;
            for i=1:obj.block_width
                vertical_prediction(1:obj.block_height,i)=128;
            end
        end
        
        function horizontal_prediction = horprediction(obj,block)
            horizontal_prediction=block;
            for i=1:obj.block_height
                horizontal_prediction(i,1:obj.block_width)=128;
            end
        end
        
        function [mode,block] = prediction(~,pred_block_ver,pred_block_hor,actual_block)
            SAD_h=abs( sum(pred_block_hor,'all') - sum(actual_block,'all'));
            SAD_v=abs( sum(pred_block_ver,'all') - sum(actual_block,'all'));
    
            if(SAD_h>SAD_v)
                mode=0;
                block=pred_block_hor;
            else
                mode=1;
                block=pred_block_ver;
            end
        
        end
        
    end
end


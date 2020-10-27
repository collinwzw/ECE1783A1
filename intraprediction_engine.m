classdef intraprediction_engine
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess='public', SetAccess='public')
        blocksize;
        input_block;
        actual_block;
        pred_block_ver;
        pred_block_hor;
        mode;
        block
    end
    
    methods (Access = 'public')
        function obj = intraprediction_engine(input_block,actual_block,block_size)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.blocksize=block_size;
            obj.input_block=input_block;
            obj.actual_block=actual_block;
            obj.pred_block_ver=obj.verprediction();
            obj.pred_block_hor=obj.horprediction();
            [obj.mode,obj.block]=obj.prediction();
        end
    end
   methods(Access = 'private')     
        function vertical_prediction = verprediction(obj)
            vertical_prediction=obj.input_block;
            for i=2:obj.blocksize
                vertical_prediction(2:obj.blocksize,i)=obj.input_block(1,i);
            end
        end
        
        function horizontal_prediction = horprediction(obj)
            horizontal_prediction=obj.input_block;
            for i=2:obj.blocksize
                horizontal_prediction(i,2:obj.blocksize)=obj.input_block(i,1);
            end
        end
        
        function [mode,block] = prediction(obj)
            SAD_h=abs(sum(obj.pred_block_hor,'all')-sum(obj.actual_block,'all'));
            SAD_v=abs(sum(obj.pred_block_ver,'all')-sum(obj.actual_block,'all'));
    
            if(SAD_h>SAD_v)
                mode=0;
                block=obj.pred_block_hor;
            else
                mode=1;
                block=obj.pred_block_ver;
            end
        
        end
        
    end
end


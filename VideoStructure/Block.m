classdef Block
    properties (GetAccess='public', SetAccess='public')
        left_width_index;
        top_height_index;
        block_width;
        block_height;
        MotionVector;
        Mode;
        BlockSumValue;
        data;
        QP;% QP value for quantization
        frameType; % 
        bitStream;
        referenceFrameIndex;
        split;
    end
    
    methods(Access = 'public')
        function obj = Block(frame, left_width_index,top_height_index, block_width, block_height )
            obj.left_width_index = left_width_index;
            obj.top_height_index = top_height_index;
            obj.block_width = block_width;
            obj.block_height = block_height;

            obj.data = frame( obj.top_height_index: obj.top_height_index + obj.block_height -1, obj.left_width_index: obj.left_width_index + obj.block_width -1);
            obj = obj.calculateBlockSumValue(frame);
        end
        function obj = calculateBlockSumValue(obj, frame)
            block = frame( obj.top_height_index: obj.top_height_index + obj.block_height -1, obj.left_width_index: obj.left_width_index + obj.block_width -1);
            obj.BlockSumValue = round(sum(block,'all'));
        end
        function result = getBlockSumValue(obj)
            result=obj.BlockSumValue;
        end
        function r = getL1Norm(obj)
            r = obj.MotionVector.getL1Norm();
        end
        function obj = setQP(obj,QP)
            obj.QP = QP;
        end
        function obj = setbitStream(obj,bitstream)
            obj.bitstream = bitstream;
        end
        function obj = setbitReferenceFrameIndex(obj,referenceFrameIndex)
            obj.referenceFrameIndex = referenceFrameIndex;
        end
        function obj = setbitSplit(obj,split)
            obj.split = split;
        end
        function obj = setbitMotionVector(obj,MotionVector)
            obj.MotionVector = MotionVector;
        end
        function obj = setbitMode(obj,Mode)
            obj.Mode = Mode;
        end
    end
    
end
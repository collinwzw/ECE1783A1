classdef QuantizationEngine
   properties (GetAccess='public', SetAccess='public')
        transformCoefficientFrame; %type Frame
        qMatrix; %int[height][width]
        quantizationParameter; %int
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
        quantizationResult; %Frame
    end
    
    methods(Access = 'public')
        function obj = QuantizationEngine(transformCoefficientFrame,block_width, block_height,QP )
            obj.transformCoefficientFrame = transformCoefficientFrame;
            obj.block_width = block_width;
            obj.block_height = block_height;
            if QP > obj.calculateQPMax()
                    ME = MException("error, the input QP is largerer than the maximum allowed value");
                    throw(ME)
            end
            obj.quantizationParameter = QP;
            obj = obj.generateQMatrix();
            obj = obj.quantizeFrame();
        end
       
    end
    methods(Access = 'private')
        function maxValue = calculateQPMax(obj)
            %calculate maximum possible value for quantizationParameter
            maxValue = log2(obj.block_width);
        end
        
        function obj = generateQMatrix(obj)
            for x=1:1:obj.block_height
                for y=1:1:obj.block_width
                    if (x + y - 2 < obj.block_height - 1)
                        obj.qMatrix(x,y) = power(2, obj.quantizationParameter);
                    elseif(x + y - 2 == obj.block_height - 1)
                        obj.qMatrix(x,y) = power(2, obj.quantizationParameter + 1);
                    else
                        obj.qMatrix(x,y) = power(2, obj.quantizationParameter + 2);
                    end
                end
            end
        end
        
        function qtc = quantizeBlock(obj, block)
            for x=1:1:obj.block_height
                for y=1:1:obj.block_width
                    qtc(x,y) = round(block.data(x,y)/obj.qMatrix(x,y));
                end
            end
        end

        function obj = quantizeFrame(obj)
            for i=1:obj.block_height:size(obj.transformCoefficientFrame,1)  
                for j=1:obj.block_width:size(obj.transformCoefficientFrame,2)
                        currentBlock = Block(obj.transformCoefficientFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
                        qtc =  obj.quantizeBlock(currentBlock);
                        obj.quantizationResult(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = qtc;
                end
            end
            obj.quantizationResult = uint8(obj.quantizationResult);
        end     
       

        
    end
end

classdef QuantizationEngine
   properties (GetAccess='public', SetAccess='public')
        transformCoefficientFrame; %type Frame
        qMatrix; %int[height][width]
        quantizationParameter; %int
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
        quantizationResul; %Frame
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
        
        
       
    end
end

classdef RescalingEngine
   properties (GetAccess='public', SetAccess='public')
        qtcFrame; %type Frame
        qMatrix; %int[height][width]
        quantizationParameter; %int
        block_width; %type int
        block_height; %type int, for square block_height = block_weight = i
        rescalingResult; %Frame
    end
    
    methods(Access = 'public')
        function obj = RescalingEngine(qtcFrame,block_width, block_height,QP )
            obj.qtcFrame = qtcFrame;
            obj.block_width = block_width;
            obj.block_height = block_height;
            if QP > obj.calculateQPMax()
                    ME = MException("error, the input QP is largerer than the maximum allowed value");
                    throw(ME)
            end
            obj.quantizationParameter = QP;
            obj = obj.generateQMatrix();
            obj = obj.rescalingFrame();
        end
       
    end
    methods(Access = 'private')
        function maxValue = calculateQPMax(obj)
            %calculate maximum possible value for quantizationParameter
            maxValue = log2(obj.block_width)+7;
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
        
        function qt = rescalingBlock(obj, qtcblock)
            qt = zeros(obj.block_height, obj.block_width);
            for x=1:1:obj.block_height
                for y=1:1:obj.block_width
                    qt(x,y) = round(qtcblock.data(x,y) * obj.qMatrix(x,y));
                end
            end
        end

        function obj = rescalingFrame(obj)
            for i=1:obj.block_height:size(obj.qtcFrame,1)  
                for j=1:obj.block_width:size(obj.qtcFrame,2)
                        currentBlock = Block(obj.qtcFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
                        qt =  obj.rescalingBlock(currentBlock);
                        obj.rescalingResult(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = qt;
                end
            end
        end     
       

        
    end
end

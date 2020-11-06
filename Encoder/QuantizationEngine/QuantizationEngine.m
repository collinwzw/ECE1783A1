classdef QuantizationEngine
   properties (GetAccess='public', SetAccess='public')
        transformCoefficientBlock; %type Frame
        qMatrix; %int[height][width]
        qtc;
    end
    
    methods(Access = 'public')
        function obj = QuantizationEngine(transformCoefficientBlock)
            obj.transformCoefficientBlock = transformCoefficientBlock;
            obj = obj.generateQMatrix();
            obj = obj.quantizeBlock(transformCoefficientBlock.data);
        end
       
    end
    methods(Access = 'private')
        function maxValue = calculateQPMax(obj)
            %calculate maximum possible value for quantizationParameter
            maxValue = log2(obj.transformCoefficientBlock.block_width)+7;
        end
        
        function obj = generateQMatrix(obj)
            for x=1:1:obj.transformCoefficientBlock.block_height
                for y=1:1:obj.transformCoefficientBlock.block_width
                    if (x + y - 2 < obj.transformCoefficientBlock.block_height - 1)
                        obj.qMatrix(x,y) = power(2, obj.transformCoefficientBlock.QP);
                    elseif(x + y - 2 == obj.transformCoefficientBlock.block_height - 1)
                        obj.qMatrix(x,y) = power(2, obj.transformCoefficientBlock.QP + 1);
                    else
                        obj.qMatrix(x,y) = power(2, obj.transformCoefficientBlock.QP + 2);
                    end
                end
            end
        end
        
        function obj = quantizeBlock(obj, block)
            for x=1:1:obj.transformCoefficientBlock.block_height
                for y=1:1:obj.transformCoefficientBlock.block_width
                    obj.qtc(x,y) = round(block(x,y)/obj.qMatrix(x,y));
                end
            end
        end

%         function obj = quantizeFrame(obj)
%             for i=1:obj.block_height:size(obj.transformCoefficientFrame,1)  
%                 for j=1:obj.block_width:size(obj.transformCoefficientFrame,2)
%                         currentBlock = Block(obj.transformCoefficientFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
%                         qtc =  obj.quantizeBlock(currentBlock);
%                         obj.quantizationResult(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = qtc;
%                 end
% 
%             end
%            
%         end     
       

        
    end
end

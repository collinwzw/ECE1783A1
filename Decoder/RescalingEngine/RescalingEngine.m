classdef RescalingEngine
   properties (GetAccess='public', SetAccess='public')
        qtcBlock; %type Frame
        qMatrix; %int[height][width]
        rescalingResult; %Frame
    end
    
    methods(Access = 'public')
        function obj = RescalingEngine(qtcBlock )
            obj.qtcBlock = qtcBlock;
            obj = obj.generateQMatrix();
            obj.rescalingResult = obj.rescalingBlock();
        end
       
    end
    methods(Access = 'private')
        function maxValue = calculateQPMax(obj)
            %calculate maximum possible value for quantizationParameter
            maxValue = log2(obj.qtcBlock.block_width)+7;
        end
        
        function obj = generateQMatrix(obj)
            for x=1:1:obj.qtcBlock.block_height
                for y=1:1:obj.qtcBlock.block_width
                    if (x + y - 2 < obj.qtcBlock.block_height - 1)
                        obj.qMatrix(x,y) = power(2, obj.qtcBlock.QP);
                    elseif(x + y - 2 == obj.qtcBlock.block_height - 1)
                        obj.qMatrix(x,y) = power(2, obj.qtcBlock.QP + 1);
                    else
                        obj.qMatrix(x,y) = power(2, obj.qtcBlock.QP + 2);
                    end
                end
            end
        end
        
        function qt = rescalingBlock(obj)
            qt = zeros(obj.qtcBlock.block_height, obj.qtcBlock.block_width);
            for x=1:1:obj.qtcBlock.block_height
                for y=1:1:obj.qtcBlock.block_width
                    qt(x,y) = round(obj.qtcBlock.data(x,y) * obj.qMatrix(x,y));
                end
            end
        end
% 
%         function obj = rescalingFrame(obj)
%             for i=1:obj.block_height:size(obj.qtcFrame,1)  
%                 for j=1:obj.block_width:size(obj.qtcFrame,2)
%                         currentBlock = Block(obj.qtcFrame, j,i, obj.block_width, obj.block_height, MotionVector(0,0) );
%                         qt =  obj.rescalingBlock(currentBlock);
%                         obj.rescalingResult(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = qt;
%                 end
%             end
%         end     
       

        
    end
end

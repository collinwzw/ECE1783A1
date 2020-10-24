classdef MotionCompensationVideo
    properties (GetAccess='public', SetAccess='public')
        n;
        block_width;
        block_height;

        
        video;
        
        predictedFrame;
        residualFrame;
        vectors;
        v;
        x;
        y;

        
    end
    
    methods(Access = 'public')
        function obj = MotionCompensationVideo(residualVideo, mv, block_width, block_height,n)
            obj.n = n;
            obj.vectors = mv;
            obj.video = residualVideo;
            obj.block_width = block_width;
            obj.block_height = block_height;
            ReferenceFrame(1:residualVideo.width,1:residualVideo.height) = uint8(127);
            %ReferenceFrame(1:video.width,1:video.height) = obj.video.Y(:,:,1);
            
            for i = 1:1: obj.video.numberOfFrames
                obj.residualFrame=obj.video.Y(:,:,i);
                obj.v = obj.vectors(:,:,i);
                col=1;
                row=1;
                for i=1:obj.block_height:size(obj.residualFrame,1)
                 
                    for j=1:obj.block_width:size(obj.residualFrame,2)
                        obj.x = obj.v(col,row);
                        obj.y = obj.v(col+1,row);
        
                        obj.predictedFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = ReferenceFrame(i-(obj.y*obj.block_height):i-(obj.y*obj.block_height)+obj.block_height - 1, j-(obj.x*obj.block_width):j-(obj.x*obj.block_width)+obj.block_width -1 );
          
                        col = col + 2;
                    end
                    row = row + 1;
                    col = 1;     
                end
                ReferenceFrame=obj.predictedFrame+obj.residualFrame;
            end
        end
    end
end

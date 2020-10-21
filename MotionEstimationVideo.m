classdef MotionEstimationVideo
    properties (GetAccess='public', SetAccess='public')
        r;
        block_width;
        block_height;
        blocks;
        predictedFrame;
        residualFrame;
        video;
        residualData;
    end
    
    methods(Access = 'public')
        function obj = MotionEstimationVideo(video, r, block_width, block_height)
            obj.video = video;
            obj.r = r;
            obj.block_width = block_width;
            obj.block_height = block_height;
            ReferenceFrame(1:352,1:288) = uint8(127);
            %ReferenceFrame(1:352,1:288) = obj.video.Y(:,:,1);
            
            for i = 1:1: obj.video.numberOfFrames
                m = MotionEstimationFrames(1,obj.video.Y(:,:,i), ReferenceFrame, block_width, block_height);
                m = m.truncateBlock();
                ReferenceFrame = m.predictedFrame + m.residualFrame;
                obj.residualData = [obj.residualData , m.residualFrame];
                fprintf("the %d th frame has been processed\n",i);
                imshow(ReferenceFrame(:,:,1));
            end
                
        end
 
    end
    
end

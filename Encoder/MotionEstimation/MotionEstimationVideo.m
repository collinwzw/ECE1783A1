classdef MotionEstimationVideo
    properties (GetAccess='public', SetAccess='public')
        r;
        n;
        block_width;
        block_height;
        reconstructuredVideo;
        residualVideo;
        video;
        motionVectorVideo;
    end
    
    methods(Access = 'public')
        function obj = MotionEstimationVideo(video, r, block_width, block_height,n)
            obj.video = video;
            obj.r = r;
            obj.n = n;
            obj.block_width = block_width;
            obj.block_height = block_height;
            ReferenceFrame(1:video.width,1:video.height) = uint8(127);
            %ReferenceFrame(1:video.width,1:video.height) = obj.video.Y(:,:,1);
            
            for i = 1:1: obj.video.numberOfFrames
                m = MotionEstimationFrames(1,obj.video.Y(:,:,i), ReferenceFrame, block_width, block_height,n);
                m = m.truncateBlock();
                ReferenceFrame = m.reconstructed;
                obj.residualVideo(:,:,i) =  m.residualFrame;
                obj.reconstructuredVideo(:,:,i) = m.reconstructed;
                obj.motionVectorVideo(:,:,i) = m.blocks;
                
                
                fprintf("the %d th frame has been processed\n",i);

            end
                
        end
        
        function reconstructuredVideo = getReconstructuredVideo(obj)
            reconstructuredVideo = obj.video.clone();
            reconstructuredVideo.Y = obj.reconstructuredVideo;
        end
        
        function residualVideo = getResidualVideo(obj)
            residualVideo = obj.video.clone();
            residualVideo.Y = obj.residualVideo;
        end        
    
        function motionVectorVideoWriteToFile(obj, filename)

            fid=fopen(filename,'w');
            if (fid < 0) 
                error('Could not open the file!');
            end
             for i=1:obj.video.numberOfFrames
                fwrite(fid,uint8(obj.motionVectorVideo(:,:,i)),'uchar');
             end
            fclose(fid);
        end   
    end
    
end

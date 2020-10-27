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
            
            for i = 1:1:10%obj.video.numberOfFrames
                m = MotionEstimationFrames(r,obj.video.Y(:,:,i), ReferenceFrame, block_width, block_height,n);
                m = m.truncateBlock();
                ReferenceFrame = m.reconstructed;
                obj.residualVideo(:,:,i) =  m.residualFrame;
                obj.reconstructuredVideo(:,:,i) = m.reconstructed;
                obj.motionVectorVideo(:,:,i) = m.blocks;
                
                
                fprintf("the %d th frame has been processed\n",i);

            end
            fid = fopen('.\output\Residual.txt', 'w');
            fwrite(fid,int16(obj.residualVideo()),'int16'); 
            fclose(fid); 
            fid = fopen('.\output\MotionVectors.txt', 'w');
            fwrite(fid,int16(obj.motionVectorVideo()),'int16'); 
            fclose(fid); 
  
        end
        
        function reconstructuredVideo = getReconstructuredVideo(obj)
            reconstructuredVideo = obj.video.clone();
            reconstructuredVideo.Y = obj.reconstructuredVideo;
        end
        
        function residualVideo = getResidualVideo(obj)
            residualVideo = obj.video.clone();
            residualVideo.Y = obj.residualVideo;
        end        
    
        function getSAD_metric(obj)
            for i=1:1:10
                currentframe_sum= sum(double(obj.video.Y(:,:,i)),'all');
                reconstructed_sum=sum(double(obj.reconstructuredVideo(:,:,i)),'all');
                SAD(i)=abs(currentframe_sum-reconstructed_sum);
            end
            frame_number = linspace(1,10,10);
            plot(frame_number,SAD)
            title('SAD Metrix for ''i=8'',''r=4'',''n=3');
            xlabel('Frames')
            ylabel('SAD values')
        end
        function motionVectorVideoWriteToFile(obj, filename)

            fid=fopen(filename,'a');
            if (fid < 0) 
                error('Could not open the file!');
            end
             for i=1:10%obj.video.numberOfFrames
                fwrite(fid,int16(obj.motionVectorVideo(:,:,i)));
             end
            fclose(fid);
        end   
    end
    
end

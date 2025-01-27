classdef MotionCompensationVideo
    properties (GetAccess='public', SetAccess='public')
        
        block_width;
        block_height;
        residualVideo;
        residualFrame;
        video;
        referenceVideo;
        predictedFrame;
        r;
        vectors;
        v;
        x;
        y;
        dw; %Decoder Width
        dh; %Decoder height
        mvw; %MV Width
        mvh; %MV Width
        inputFilename;
        numberOfFrames;
        DecodedRefVideo;
        Temp_v;
    end

    methods(Access = 'public')
        function obj = MotionCompensationVideo(inputFilename1, inputFilename2, block_width, block_height,decoderwidth,decoderheight,mvwidth,mvheight,numberOfFrames)

            fid = fopen(inputFilename1, 'r');
            a=fread(fid,'int16');
            fclose(fid); 
            fid = fopen(inputFilename2, 'r');
            b=fread(fid,'int16');
            fclose(fid); 
            
            obj.dw=decoderwidth;
            obj.dh=decoderheight;
            obj.mvw=mvwidth;
            obj.mvh=mvheight;
           
            obj.inputFilename=inputFilename1;
            obj.numberOfFrames=numberOfFrames;
            
            residualVideo=permute(reshape(a,decoderwidth,decoderheight,numberOfFrames),[1,2,3]);
            mv=permute(reshape(b,mvwidth,mvheight,numberOfFrames),[1,2,3]);
            
            obj.vectors = mv;
            obj.video = residualVideo;
            obj.block_width = block_width;
            obj.block_height = block_height;
            referenceFrame(1:decoderwidth,1:decoderheight) = uint8(127);
            %ReferenceFrame(1:video.width,1:video.height) = obj.video.Y(:,:,1);
            obj.Temp_v = YOnlyVideo('.\output\akiyoYReconstructed.yuv', obj.dw,  obj.dh);
            for p = 1:1: numberOfFrames
                obj.residualFrame=residualVideo(:,:,p);
                obj.v = obj.vectors(:,:,p);
                col=1;
                row=1;
                for i=1:obj.block_height:size(obj.residualFrame,1)
                 
                    for j=1:obj.block_width:size(obj.residualFrame,2)
                        obj.x = obj.v(row,col);
                        obj.y = obj.v(row,col+1);
        
                        obj.predictedFrame(i:i+obj.block_height - 1, j:j+obj.block_width -1 ) = referenceFrame(i+(obj.x):i+(obj.x)+obj.block_height - 1, j+(obj.y):j+(obj.y)+obj.block_width -1 );
          
                        col = col + 2;
                    end
                    row = row + 1;
                    col = 1;     
                end
                referenceFrame_cal=int16(obj.predictedFrame)+int16(obj.residualFrame);
                referenceFrame=uint8(referenceFrame_cal);
                
                obj.Temp_v.Y(:,:,p)=referenceFrame;
                %obj.referenceVideo(:,:,p) = uint8(referenceFrame_cal);
               
%                  subplot(1,5,1), imshow(uint8(obj.predictedFrame(:,:,1)))
%                  subplot(1,5,2), imshow(uint8(obj.residualFrame(:,:,1)))
%                  subplot(1,5,3), imshow(referenceFrame)
%                  subplot(1,5,4), imshow(Temp_v.Y(:,:,p))
%                 
%                 subplot(1,5,5), imshow(obj.reconstructed(:,:,1))    
%                 
                
            end
%             obj.DecodedRefVideo=Temp_v.Y;
        end
        function referenceVideo = getDecodedRefVideo(obj)
%             Temp_v = YOnlyVideo('.\output\akiyoYReconstructed.yuv', obj.dw,  obj.dh);
%             for p = 1:1: obj.numberOfFrames
%                 Temp_v.Y(:,:,p)=uint8(obj.referenceVideo(:,:,p));
%             end
           referenceVideo =obj.Temp_v;
        end
                
                
                
           
            
        end
    end


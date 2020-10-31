classdef MotionCompensationEngine
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
        frametype;
        
    end

    methods(Access = 'public')
        function obj = MotionCompensationEngine(residualVideo,mv,frameType,block_width, block_height,decoderwidth,decoderheight,mvwidth,mvheight,numberOfFrames)

            
            obj.dw=decoderwidth;
            obj.dh=decoderheight;
            obj.mvw=mvwidth;
            obj.mvh=mvheight;
           
            obj.frametype=frameType;
            obj.numberOfFrames=numberOfFrames;
            
            obj.vectors = mv;
            obj.block_width = block_width;
            obj.block_height = block_height;
            referenceFrame(1:decoderwidth,1:decoderheight) = uint8(127);
            %ReferenceFrame(1:video.width,1:video.height) = obj.video.Y(:,:,1);
            obj.Temp_v = YOnlyVideo('\akiyoY_cif.yuv', obj.dw,  obj.dh);
            index = 0;
            for p = 1:1: numberOfFrames
                obj.residualFrame=residualVideo(:,:,p);
                
                if obj.frametype(p) == 1
                    referenceFrame_cal = int16(obj.residualFrame)+int16(referenceFrame);
                    %obj.referenceVideo(:,:,p) = uint8(referenceFrame_cal);
                    referenceFrame=uint8(referenceFrame_cal);
                    %obj.Temp_v.Y(:,:,p)=uint8(referenceFrame);
                    index = index+1;
                else
                    obj.v = obj.vectors(:,:,p-index);
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
%                     obj.referenceVideo(:,:,p) = uint8(referenceFrame_cal);
%                     obj.Temp_v.Y(:,:,p)=uint8(referenceFrame);
                %obj.referenceVideo(:,:,p) = uint8(referenceFrame_cal);
               
%                  subplot(1,5,1), imshow(uint8(obj.predictedFrame(:,:,p)))
                  %subplot(1,5,2), imshow(uint8(obj.residualFrame(:,:,p)))
%                   subplot(1,5,3), imshow(referenceFrame)
                  %subplot(1,5,4), imshow(obj.Temp_v.Y(:,:,p))
%                 
%                 subplot(1,5,5), imshow(obj.reconstructed(:,:,1))    
%                
                end
               obj.Temp_v.Y(:,:,p)=referenceFrame; 
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


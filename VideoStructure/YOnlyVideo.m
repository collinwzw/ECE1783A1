classdef YOnlyVideo
    properties (GetAccess='public', SetAccess='public')
        width; %
        height;
        numberOfFrames;
        Y;
    end
    methods(Access = 'public')
        function obj = YOnlyVideo(filename,width,height)
                %check the input width and height
                if (width <= 0 || height <= 0)
                    ME = MException('input video size can not be zero or negative');
                    throw(ME)
                else
                    obj.width = width;
                    obj.height = height;
                end

                %check file is exist
                if isfile(filename)
                    s = dir(filename);
                    filesize = s.bytes;  
                    try
                        obj = CalculateFrame(obj,filesize);
                        obj = yOnlyRead(obj,filename);
                    catch ME
                        throw(ME)
                    end
                else
                     % File does not exist.
                end

        end
        
        function copyobj = clone(obj)
                copyobj = obj;           
        end
        
        function obj = CalculateFrame(obj,filesize)
            nFrames = filesize/(obj.width * obj.height);
            if floor(nFrames) ~=  nFrames
                ME = MException('the number of frames is not integer according to input size');
                throw(ME)
            end
            obj.numberOfFrames = nFrames;
        end

        function obj = yOnlyRead(obj,filename)

            fid = fopen(filename,'r');           % Open the video file
            stream = fread(fid,'*uchar');    % Read the video file
            length =  obj.width * obj.height;  % Length of a single frame
            y = uint8(zeros(obj.width, obj.height,  obj.numberOfFrames));

            for iFrame = 1:obj.numberOfFrames
                frame = stream((iFrame-1)*length+1:iFrame*length);
                % Y component of the frame
                yImage = reshape(frame(1:obj.width*obj.height),obj.width, obj.height );
                y(:,:,iFrame) = uint8(yImage);
            end
            obj.Y = y;
        end
    
        function writeToFile(obj, filename)

            fid=fopen(filename,'w');
            if (fid < 0) 
                error('Could not open the file!');
            end
             for i=1:obj.numberOfFrames
                fwrite(fid,uint8(obj.Y(:,:,i)),'uchar');
             end
            fclose(fid);
        end
        
        function [paddedVideo,paddedAverageVideo] = block_creation(obj,Y,block_width, block_height)
            %UNTITLED Summary of this function goes here
            %   Detailed explanation goes here
            pad_len = 0;
            pad_height = 0;
            paddedVideo=obj.clone();
            if(rem(obj.width,block_width)==0)
                Y_block(1:block_width, 1:block_height)=0;
            else
                pad_len=block_width-(rem(obj.width,block_width));
                paddedVideo.width = obj.width+pad_len;               
            end
            
            if(rem(obj.height,block_height)==0)
                Y_block(1:block_width, 1:block_height)=0;
            else
                pad_height=block_height-(rem(obj.height,block_height));
                paddedVideo.height = obj.height+pad_height;  
            end
            paddedAverageVideo = paddedVideo.clone();
            Y_New=Y;
            Y_New(obj.width+1:obj.width+pad_len,obj.height+1:obj.height+pad_height,:)=uint8(127);
            Y_New(:,obj.height+1:obj.height+pad_height,:)=uint8(127);
            Y_New(obj.width+1:obj.width+pad_len,:,:)=uint8(127);
            
            for k=1:1:obj.numberOfFrames
                for i=1:block_width:obj.width+pad_len
                    for j=1:block_height:obj.height+pad_height
                        Y_block=Y_New(i:i+block_width-1,j:j+block_height-1,k);
                        mean_value=round(mean(Y_block,'all'));
                        av_Y(i:i+block_width-1,j:j+block_height-1,k)=uint8(mean_value);
                    end
                end
            end
            
            
            paddedVideo.Y= Y_New;
            paddedAverageVideo.Y = av_Y;
            end


    end
end

    

        
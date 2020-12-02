classdef CreateQPTable
    properties (GetAccess='public', SetAccess='public')
        QP_table;
        inputvideo;
        block_width;
        block_height;
    end
    
    methods (Access = 'public')
         function obj = CreateQPTable(inputvideo,block_width, block_height,r,nRefFrame,FEMEnable,FastME, VBSEnable, intra, CIF)
            obj.QP_table = zeros(1,12);
            obj.inputvideo = inputvideo;
            obj.block_width = block_width;
            obj.block_height = block_height;
            
            if intra == true && CIF == true
                I_Period = 1;
                %Creating I Frame QP table
                for QP = 0: 1 : 11
                    e = EncoderBuildQPTable(inputvideo,block_width, block_height,r , QP, I_Period,nRefFrame, FEMEnable, FastME, VBSEnable);
                    obj = obj.computeAverage( e.bitCountVideo, QP+1, intra);
                end
                % writing to the QP table to file
                filename = ".\result\CIFQPTableIntra.txt";
                fid=fopen(filename,'w');
                for i=1:1: size(obj.QP_table, 2)
                    fprintf(fid,"%d\n",int16(obj.QP_table(i)));
                end
                fclose(fid);
            end
            
            if intra == false && CIF == true
                I_Period = 21;
                %Creating I Frame QP table
                for QP = 0: 1 : 11
                    e = EncoderBuildQPTable(inputvideo,block_width, block_height,r , QP, I_Period,nRefFrame, FEMEnable, FastME, VBSEnable);
                    obj = obj.computeAverage( e.bitCountVideo, QP+1, intra);
                end
                % writing to the QP table to file
                filename = ".\result\CIFQPTableInter.txt";
                fid=fopen(filename,'w');
                for i=1:1: size(obj.QP_table, 2)
                    fprintf(fid,"%d\n",int16(obj.QP_table(i)));
                end
                fclose(fid);
            end
            
            
         end
         
         function obj = computeAverage(obj, bitCountVideo, QP, intra)
             rowAverage = zeros(1,obj.inputvideo.width/obj.block_width, obj.inputvideo.numberOfFrames);
             if intra == true
                 startFrameIndex = 1;
             else
                 startFrameIndex = 2;
             end
             %compute the average for each row of individual frame
             for frameindex = startFrameIndex:1:obj.inputvideo.numberOfFrames               
                 for i = 1:1:obj.inputvideo.width/obj.block_width
                     row_sum = 0;
                     for j = 1:1:obj.inputvideo.height/obj.block_height
                         row_sum = row_sum + bitCountVideo(i,j,frameindex);
                     end
                     rowAverage(1,i,frameindex) = row_sum / (obj.inputvideo.height/obj.block_height);  
                 end
             end
             
             %compute the average for each frame by sum up all rows and take average for individual frame
             frameAverage = zeros(1,1, obj.inputvideo.numberOfFrames);
             for frameindex = startFrameIndex:1:obj.inputvideo.numberOfFrames   
                 for i = 1:1:obj.inputvideo.width/obj.block_width
                    frameAverage(1,1,frameindex) = frameAverage(1,1,frameindex) + rowAverage(1,i,frameindex);
                 end
             end
             
             %compute the average row bit count by summing up all frames row average bit count 
             for frameindex = startFrameIndex:1:obj.inputvideo.numberOfFrames  
                 obj.QP_table(QP) = obj.QP_table(QP) + frameAverage(1,1,frameindex);
             end
             
             obj.QP_table(QP) = obj.QP_table(QP)/obj.inputvideo.numberOfFrames;
         end
    end
end
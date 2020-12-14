classdef BitBudget
    properties (GetAccess='public', SetAccess='public')
        bitBudgetPerFrame;
        numberOfRow;
        bitBudgetPerRow;
        QPTableInter;
        QPTableIntra;
        QPTableInterRescal;
        QPTableIntraRescal;
        curentRow;
        actualBitSpent;
        QP;
        RCflag;
        bitCountRowsVideo;
    end
    
    methods (Access = 'public')
        function obj = BitBudget(targetBPPerSecond, framePerSecond, videoHeight, block_height, QPTableInterFilename, QPTableIntraFilename, RCflag, bitCountRowsVideo )
            obj.bitBudgetPerFrame = targetBPPerSecond/framePerSecond;
            obj.numberOfRow = videoHeight/block_height; 
            obj.bitBudgetPerRow = obj.bitBudgetPerFrame/obj.numberOfRow;
            obj.QPTableInter = obj.readQPTable(QPTableInterFilename);
            obj.QPTableIntra = obj.readQPTable(QPTableIntraFilename);
            obj.RCflag = RCflag;         
            obj.bitCountRowsVideo = bitCountRowsVideo;
            obj.actualBitSpent = 0;
            obj.curentRow = 0;

        end
        
        function obj = rescalQPTable(obj, intra, firstPassQP, average)
                %rescal the QP table according to first pass
                if intra == true
                    multiplierIntra =  obj.QPTableIntra(firstPassQP + 1) / average;
                    for i=1:1:size(obj.QPTableIntra, 2)
                        obj.QPTableIntraRescal(i) = obj.QPTableIntra(i)/multiplierIntra;
                    end
                else
                    multiplierInter =  obj.QPTableInter(firstPassQP + 1) / average;
                    for i=1:1:size(obj.QPTableIntra, 2)
                        obj.QPTableInterRescal(i) = obj.QPTableInter(i)/multiplierInter;
                    end
                end
        end
            
        function r = readQPTable(obj, filename)
            fid = fopen(filename,'r');           % Open the video file
            tline = fgetl(fid);
            r = zeros(1,11);
            count = 1;
            while ischar(tline)
                r(count) = str2double(tline);
                count = count + 1;
                tline = fgetl(fid);
            end
        end
        
        function obj = computeQP(obj,intra,actualBitSpentCurrentRow, currentFrameIndex)
            if obj.RCflag < 2
                 obj.actualBitSpent = obj.actualBitSpent + actualBitSpentCurrentRow;
                 remainRow = obj.numberOfRow - obj.curentRow;
                 
                 bitBudgetPerRowForRemainRow = (obj.bitBudgetPerFrame - obj.actualBitSpent) /remainRow;
                 obj.QP = obj.lookUpQPTable(intra, bitBudgetPerRowForRemainRow);
            else
                obj.actualBitSpent = obj.actualBitSpent + actualBitSpentCurrentRow;
                bitBudgetCurrentRow = (obj.bitBudgetPerFrame - obj.actualBitSpent) * (obj.bitCountRowsVideo(obj.curentRow + 1,currentFrameIndex)/sum(obj.bitCountRowsVideo(obj.curentRow + 1:size(obj.bitCountRowsVideo,1),currentFrameIndex)));
                obj.QP = obj.lookUpRescaledQPTable(intra, bitBudgetCurrentRow);
                %obj.QP = obj.lookUpQPTable(intra, bitBudgetCurrentRow);
            end
            obj.curentRow = obj.curentRow + 1;
        end
        
        function selectedQP = lookUpQPTable(obj, intra, bitBudgetPerRow)
            count = 1;
            if intra
                while obj.QPTableIntra(count) > bitBudgetPerRow && count < 12
                    count = count + 1;
                end

            else
                while obj.QPTableInter(count) > bitBudgetPerRow && count < 12
                    count = count + 1;
                end
            end
            selectedQP = count - 1; %since QP table start from QP = 0
        end

        function selectedQP = lookUpRescaledQPTable(obj, intra, bitBudgetPerRow)
            count = 1;
            if intra
                while obj.QPTableIntraRescal(count) > bitBudgetPerRow  && count < 12
                    count = count + 1;
                end

            else
                while obj.QPTableInterRescal(count) > bitBudgetPerRow && count < 12
                    count = count + 1;
                end
            end
            selectedQP = count - 1; %since QP table start from QP = 0
        end
        

    end
    
   methods (Access = 'private')
        function obj = computeQPSecondPass(obj,intra,actualBitSpentCurrentRow, currentFrameIndex)
            if obj.RCflag < 2
                 obj.actualBitSpent = obj.actualBitSpent + actualBitSpentCurrentRow;
                 remainRow = obj.numberOfRow - obj.curentRow;
                 
                 bitBudgetPerRowForRemainRow = (obj.bitBudgetPerFrame - obj.actualBitSpent) /remainRow;
                 obj.QP = obj.lookUpQPTable(intra, bitBudgetPerRowForRemainRow);
            else
                bitBudgetCurrentRow = obj.bitBudgetPerFrame * obj.bitCountRowsVideo(obj.curentRow,currentFrameIndex);
                obj.QP = obj.lookUpQPTable(intra, bitBudgetCurrentRow);
            end
            obj.curentRow = obj.curentRow + 1;
        end
   end
end
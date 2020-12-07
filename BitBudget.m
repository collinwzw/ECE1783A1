classdef BitBudget
    properties (GetAccess='public', SetAccess='public')
        bitBudgetPerFrame;
        numberOfRow;
        bitBudgetPerRow;
        QPTableInter;
        QPTableIntra;
        curentRow;
        actualBitSpent;
        QP;
    end
    
    methods (Access = 'public')
        function obj = BitBudget(targetBPPerSecond, framePerSecond, videoHeight, block_height, QPTableInterFilename, QPTableIntraFilename)
            obj.bitBudgetPerFrame = targetBPPerSecond/framePerSecond;
            obj.numberOfRow = videoHeight/block_height; 
            obj.bitBudgetPerRow = obj.bitBudgetPerFrame/obj.numberOfRow;
            obj.QPTableInter = obj.readQPTable(QPTableInterFilename);
            obj.QPTableIntra = obj.readQPTable(QPTableIntraFilename);
            obj.actualBitSpent = 0;
            obj.curentRow = 0;

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
        
        function obj = computeQP(obj,intra,actualBitSpentCurrentRow)
             obj.actualBitSpent = obj.actualBitSpent + actualBitSpentCurrentRow;
             remainRow = obj.numberOfRow - 1;
             obj.curentRow = obj.curentRow + 1;
             bitBudgetPerRowForRemainRow = (obj.bitBudgetPerFrame - obj.actualBitSpent) /remainRow;
             obj.QP = obj.lookUpQPTable(intra, bitBudgetPerRowForRemainRow);
        end
        
        function selectedQP = lookUpQPTable(obj, intra, bitBudgetPerRow)
            count = 1;
            if intra
                while obj.QPTableIntra(count) > bitBudgetPerRow
                    count = count + 1;
                end

            else
                while obj.QPTableInter(count) > bitBudgetPerRow
                    count = count + 1;
                end
            end
            selectedQP = count - 1; %since QP table start from QP = 0
        end
        
        

    end
end
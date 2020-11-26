classdef createQPTable
    properties (GetAccess='public', SetAccess='public')
        intra_Q_table;
        inter_Q_table;
    end
    
    methods (Access = 'public')
         function obj = createQPTable(inputvideo,block_width, block_height,r,nRefFrame,FEMEnable,FastME, VBSEnable)

            
            I_Period = 1;
            %Creating I Frame QP table
            for QP = 0: 1 : 11
                e = EncoderBuildQPTable(v1WithPadding,block_width, block_height,r , QP, I_Period,nRefFrame, FEMEnable, FastME, VBSEnable);
            end
         end
    end
end
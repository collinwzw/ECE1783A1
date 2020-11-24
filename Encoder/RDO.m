classdef RDO
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        full_frame;
        small_frame;
        block_height;
        block_width;
        SAD;
        SAD_4;
        lambda;
        RDO_cost4;
        RDO_cost1;
        final_frame;
        flag;
        Qp;
        bits1;
        bits4;
    end
    
    methods
        function obj = RDO(frame_1,frame_4,block_height,block_width,SAD,SAD_4,Qp)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.full_frame=frame_1;
            obj.small_frame=frame_4;
            obj.block_height=block_height;
            obj.block_width=block_width;
            obj.SAD=SAD;
            obj.SAD_4=SAD_4;
            obj.Qp=Qp;
            obj.lambda=2^((Qp-12)/3);%used a random lambda value
            obj=obj.RDO_calculation();
        end
    end
    methods(Access = 'private')
        
        function obj = RDO_calculation(obj)
            obj =obj.full_framecalc();
            obj =obj.small_framecalc();
            if(obj.RDO_cost1<obj.RDO_cost4)
                obj.final_frame=obj.full_frame;
                obj.flag=0;
            else
                obj.final_frame=obj.small_frame;
                obj.flag=1;
            end
        end
        
        function obj = full_framecalc(obj)
            s=obj.full_frame;
            bits=[];
            for i=1:size(s,1)
                for j=1:1:size(s,2)
                    bits=[bits dec2bin(s(i,j))];
                end
            end
            bitsize=size(bits);
            %obj.RDO_cost1=obj.SAD+obj.lambda*bytes1.bytes;
            %bits used for testing
            obj.RDO_cost1=obj.SAD+obj.lambda*bitsize;
        end
        
        function obj = small_framecalc(obj)
            cost4=0;
            k=0;
            for i=1:1:2
                for j=1:1:2
                    bits=[];
                    k=k+1;
                    curr_row=1+((i-1)*obj.block_width/2):(i)*obj.block_width/2;
                    curr_col=1+((j-1)*obj.block_height/2):(j)*obj.block_height/2;
                    block=obj.small_frame(curr_row,curr_col);
                    for l=1:1:size(block,1)
                        for m=1:1:size(block,2)
                            bits=[bits dec2bin(block(l,m))];
                        end
                    end
                    bitsize4=size(bits);
                    %obj.RDO_cost4=obj.RDO_cost4+obj.SAD_4(k)+obj.lambda*bytes4.bytes;
                    cost4=cost4+obj.SAD_4(k)+obj.lambda*bitsize4;;
                end
            end
            obj.RDO_cost4=cost4;
        end
    end
end


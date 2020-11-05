classdef DifferentialDecodingEngine
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        motionvector;%input motion vectors
        diff_motionvector;%differentially encoded motion vectors
        modes;%input modes
        diff_modes;%differentially encoded modes
        mvlength;%length of the motionvector
        mvwidth;%width of the motionvector
        modelength;
        modewidth;
    end
    
    methods
        function obj = DifferentialDecodingEngine()
        end
        
        function obj = differentialDecodingMode(obj,diff_modes)
            obj.diff_modes=diff_modes;
            obj.modewidth=size(obj.diff_modes,2);
            obj.modelength=size(obj.diff_modes,1);
            obj.modes=obj.mode();
        end
        
        function obj = differentialDecodingMotionVector(obj,diff_motionvector)
            obj.diff_motionvector = diff_motionvector;
            obj.mvlength=size(obj.diff_motionvector,1);
            obj.mvwidth=size(obj.diff_motionvector,2);
            obj.motionvector=obj.motion_vector();
        end
    end
    
    methods(Access = 'private')      
        function motionvector = motion_vector(obj)
            first_mv=0;
            for j=1:1:obj.mvwidth
                for i=1:1:obj.mvlength
                    if(i==1)
                        motionvector(i,j)=first_mv-obj.diff_motionvector(i,j);
                        continue;
                    end
                    motionvector(i,j)=motionvector(i-1,j)-obj.diff_motionvector(i,j);
                end
            end
            
        end
        function modes = mode(obj)
            first_mode=0;
            for j=1:1:obj.modewidth
                for i=1:1:obj.modelength
                    if(i==1)
                        if(first_mode==obj.diff_modes(i,j))
                            modes(i,j)=0;
                        else
                            modes(i,j)=1;
                        end
                        continue
                    end
                    
                    if(obj.diff_modes(i,j)==0)
                        modes(i,j)=modes(i-1,j);
                    else if (modes(i-1,j)==0)
                            modes(i,j)=1;
                        else
                            modes(i,j)=0;
                        end
                    end
                end
            end
        end
    end
end


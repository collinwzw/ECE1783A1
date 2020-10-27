classdef DifferentialEncodingEngine
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
        modewidth
    end
    
    methods
        function obj = DifferentialEncodingEngine(motionvector,modes)
            obj.motionvector = motionvector;
            obj.modes=modes;
            obj.mvlength=size(obj.motionvector,1);
            obj.mvwidth=size(obj.motionvector,2);
            obj.modelength=size(obj.modes,1);
            obj.modewidth=size(obj.modes,2);
            obj.diff_motionvector=obj.differential_vector();
            obj.diff_modes=obj.differential_modes();
        end
    end
    
    methods(Access = 'private')      
        function diff_motionvector = differential_vector(obj)
            first_mv=0;
            for j=1:1:obj.mvwidth
                for i=1:1:obj.mvlength
                    if(i==1)
                        diff_motionvector(i,j)=first_mv-obj.motionvector(i,j);
                        continue;
                    end
                    diff_motionvector(i,j)=obj.motionvector(i-1,j)-obj.motionvector(i,j);
                end
            end
            
        end
        function diff_modes = differential_modes(obj)
            first_mode=0;
            
            for j=1:1:obj.modewidth
                for i=1:1:obj.modelength
                    if(i==1)
                        if(first_mode==obj.modes(i,j))
                            diff_modes(i,j)=0;
                        else
                            diff_modes(i,j)=-1;
                        end
                        continue
                    end
                    
                    if(obj.modes(i,j)==obj.modes(i-1,j))
                        diff_modes(i,j)=0;
                    else
                        diff_modes(i,j)=-1;
                    end
                end
            end
            
        end
    end
end


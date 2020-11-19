classdef MotionVector
    properties (GetAccess='public', SetAccess='public')
        x;
        y;
    end
    methods(Access = 'public')
        function obj = MotionVector(x,y)
            obj.x = x;
            obj.y = y;
        end
        
        function r = getL1Norm(obj)
            r = abs(obj.x) + abs(obj.y); 
        end
        
    end
    
end
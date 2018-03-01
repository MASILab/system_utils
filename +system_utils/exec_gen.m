classdef exec_gen < handle
% class used to generate full paths to executables

    properties (Access = private)
        dir_path
    end
        
    methods (Access = public)
        function obj = exec_gen(dir_path) 
            obj.dir_path = dir_path;
        end
        
        function exec_path = get_path(obj,exec)
            exec_path = fullfile(obj.dir_path,exec);
        end
    end
end
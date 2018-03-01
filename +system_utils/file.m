classdef file < handle
% class to deal with files    
    
    properties (Access = private)
        parent_dir
        name
        
        fileID  % Only set if file is "opened"
    end
    
    methods (Static, Access = public)
        function f = validate_path(file_path)
            % Checks if file exists and returns a file object
            
            [dir_path,base_name,ext] = fileparts(file_path);  
            f = system_utils.file(dir_path,[base_name ext]);
            if ~f.exist()
                error(['File doesnt exist: ' f.get_path() '.']);
            end        
        end
    end        
    
    methods (Access = public)
        function obj = file(varargin)  
            if nargin == 1
                % Its assumed this is a file path
                [dir_path,base_name,ext] = fileparts(varargin{1});  
                obj.parent_dir = system_utils.directory(dir_path);   
                obj.name = [base_name,ext];
            elseif nargin == 2
                % Its assumed first argument is either a directory object
                % or a directory path and the second argument is the
                % filename
                if ischar(varargin{1})
                    obj.parent_dir = system_utils.directory(varargin{1});
                else
                    obj.parent_dir = varargin{1};                    
                end 
                obj.name = varargin{2};
            else
                error('Only one or two arguments permitted for file class');
            end                
        end
        
        function parent_dir = get_dir(obj)
            parent_dir = obj.parent_dir;
        end
        
        function dir_path = get_dir_path(obj)
            dir_path = obj.get_dir().get_path();
        end        
        
        function name = get_name(obj)
            name = obj.name;
        end
        
        function base_name = get_base_name(obj)
            [~,base_name,~] = fileparts(obj.get_name());
        end
        
        function ext = get_ext(obj)
            [~,~,ext] = fileparts(obj.get_name());
        end
                
        function path = get_path(obj)            
            path = fullfile(obj.get_dir_path(),obj.get_name());
        end
                
        function status = exist(obj)
            % Returns true if file exists
            
            status = exist(obj.get_path(),'file') ~= 0;
        end
                                
        % File methods ---------------------------------------------------%
          
        function status = is_open(obj)
            status = ~isempty(obj.fileID) && ismember(obj.fileID,fopen('all'));
        end
        
        function open(obj, varargin)
            if obj.is_open()
                error(['Attempted to open file: ' obj.get_path() ', but it''s already open.']);
            end            
            
            [obj.fileID,errmsg] = fopen(obj.get_path(),varargin{:});            
            if obj.fileID == -1
                error(['Attempted to open file: ' obj.get_path() ', but failed. Reason: ' errmsg]);
            end
        end
        
        function A = read(obj, varargin)
            if ~obj.is_open()
                error(['Attempted to fread file: ' obj.get_path() ', but file was never opened.']);
            end
            
            A = fread(obj.fileID,varargin{:});
        end
        
        function write(obj, varargin)
            if ~obj.is_open()
                error(['Attempted to fwrite file: ' obj.get_path() ', but file was never opened.']);
            end
            
            fwrite(obj.fileID,varargin{:});
        end
        
        function printf(obj, varargin)
            if ~obj.is_open()
                error(['Attempted to fprintf to file: ' obj.get_path() ', but file was never opened.']);
            end
            
            fprintf(obj.fileID,varargin{:});
        end
        
        function dlmwrite(obj, varargin)          
            % File doesn't need to be open
            
            dlmwrite(obj.get_path(),varargin{:});
        end
                
        function C = textscan(obj, varargin)
            if ~obj.is_open()
                error(['Attempted to textscan file: ' obj.get_path() ', but file was never opened.']);
            end
            
            C = textscan(obj.fileID,varargin{:});
        end
        
        function M = dlmread(obj, varargin)          
            % File doesn't need to be open
            
            M = dlmread(obj.get_path(),varargin{:});
        end
        
        function close(obj)
            if ~obj.is_open()
                error(['Attempted to close file: ' obj.get_path() ', but file was never opened.']);
            end
                
            status = fclose(obj.fileID);   
            if status == -1
                error(['Attempted to close file: ' obj.get_path() ', but failed.']);
            end
        end
        
        % GZIP methods ---------------------------------------------------%
                
        function status = is_gzipped(obj)
            status = strcmp(obj.get_ext(),'.gz');            
        end
        
        function gzip(obj)
            % gzips file in-place.
            
            if ~obj.exist()
                error(['Attempted to gzip file: ' obj.get_path() ', but this file does not exist.']);
            end
            
            % Make sure file has not already been gzipped
            if obj.is_gzipped()
                error(['Attempted to gzip file: ' obj.get_path() ', but this file has already been gzipped.']);
            end
                        
            % gzip file
            gzip(obj.get_path());
            
            % Delete old file
            obj.rm();
            
            % Append gz extension to name
            obj.name = [obj.name '.gz'];              
        end        
        
        function gunzip(obj)
            % gunzips file in-place. 
            
            if ~obj.exist()
                error(['Attempted to gunzip file: ' obj.get_path() ', but this file does not exist.']);
            end
            
            % Check to make sure file is gzipped
            if ~obj.is_gzipped()
                error(['Attempted to gunzip file: ' obj.get_path() ', but this file has not been gzipped.']);
            end
                        
            % gunzip file
            gunzip(obj.get_path());
            
            % Delete old file
            obj.rm();
                        
            % remove gz extension from name
            obj.name = obj.get_base_name();          
        end
                
        % ZIP methods ----------------------------------------------------%
         
        function status = is_zipped(obj)
            status = strcmp(obj.get_ext(),'.zip');            
        end
        
        function unzip(obj)
            % unzips file
                             
            if ~obj.exist()
                error(['Attempted to unzip file: ' obj.get_path() ', but this file does not exist.']);
            end
            
            % Check to make sure file is zipped
            if ~obj.is_zipped()
                error(['Attempted to unzip file: ' obj.get_path() ', but this file has not been zipped.']);
            end
                        
            % unzip file
            unzip(obj.get_path(),obj.get_dir_path());
        end
        
        % TAR methods ----------------------------------------------------%
                 
        function status = is_tarred(obj)   
            % Must check for either .tgz, .tar, or .tar.gz
            base_name = obj.get_base_name();
            status = strcmp(obj.get_ext(),'.tgz') || ...
                     strcmp(obj.get_ext(),'.tar') || ...
                     (strcmp(obj.get_ext(),'.gz') && length(base_name) >= 4 && strcmp(base_name(end-3:end),'.tar'));            
        end
        
        function untar(obj)
            % untars file
                             
            if ~obj.exist()
                error(['Attempted to untar file: ' obj.get_path() ', but this file does not exist.']);
            end
            
            % Check to make sure file is tarred
            if ~obj.is_tarred()
                error(['Attempted to untar file: ' obj.get_path() ', but this file has not been tarred.']);
            end
                        
            % untar file
            untar(obj.get_path(),obj.get_dir_path());
        end        
        
        % System methods -------------------------------------------------%
        
        function mv(obj, parent_dir, n)     
            % Moves existing file to location specified by parent_dir and
            % n.
            
            if ischar(parent_dir)
                parent_dir = system_utils.directory(parent_dir);
            end
                        
            new_path = fullfile(parent_dir.get_path(),n);
            
            % Check to make sure file actually exists first
            if ~obj.exist()
                error(['Attempted to move file: ' obj.get_path() ' to path: ' new_path ', but this file does not exist.']);
            end            
                       
            % Check if this file and destination has the same path
            if strcmp(obj.get_path(),new_path)
                return % Do nothing
            end
            
            % Now move file
            [status,message,~] = movefile(obj.get_path(), new_path);
            if ~status
                error(['Attempted to move file: ' obj.get_path() ' to path: ' new_path ', but failed. Reason: ' message]);
            end
            
            % Set new properties
            obj.parent_dir = parent_dir;
            obj.name = n;            
        end
        
        function copied_file = cp(obj, parent_dir, n)     
            % Copies existing file to location specified by parent_dir and
            % n. Returns a new file object to the copied file.
            
            if ischar(parent_dir)
                parent_dir = system_utils.directory(parent_dir);
            end
            
            new_path = fullfile(parent_dir.get_path(),n);
            
            % Check to make sure file actually exists first
            if ~obj.exist()
                error(['Attempted to copy file: ' obj.get_path() ' to path: ' new_path ', but this file does not exist.']);
            end
                                 
            % Create file object
            copied_file = system_utils.file(parent_dir,n);
                               
            % Check if this file and destination has the same path
            if strcmp(obj.get_path(),new_path)
                return % Do nothing
            end
                                   
            % Copy file
            [status,message,~] = copyfile(obj.get_path(), new_path);
            if ~status
                error(['Attempted to copy file: ' obj.get_path() ' to path: ' new_path ', but failed. Reason: ' message]);
            end            
        end
                
        function rm(obj)
            % Deletes file if it exists
            if ~obj.exist()
                error(['Attempted to delete file: ' obj.get_path() ', but this file does not exist.']);
            end
            
            delete(obj.get_path());
        end
        
        function delete(obj)
            % If file is open, then close it
            if obj.is_open()
                obj.close();
            end
        end
    end    
end
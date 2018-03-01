function cmdout = system_with_errorcheck(cmd, err_msg)
    % Performs system call. Will display err_msg if non-zero exit code is
    % returned.
    
    % Display date and command 
    disp(['[' char(datetime) '] ' cmd]);

    % Do system call
    [status,cmdout] = system(cmd,'-echo');
    if status
        error(err_msg);
    end
end
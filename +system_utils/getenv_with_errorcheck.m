function env_val = getenv_with_errorcheck(env_name)
    % Returns environment variable specified by env_name. This assumes 
    % that if the environmental variable is empty, that it has not been 
    % defined on the system and will return an error.

    env_val = getenv(env_name);
    if isempty(env_val) 
        error([env_name ' environmental variable is not set.']);
    end
end 
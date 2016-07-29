function exp_params = parseArgs(exp_params, varargin)
for a = 1:2:length(varargin)
    argument = lower(cell2mat(varargin(a)));
    value = lower(cell2mat(varargin(a + 1)));
    if strcmp(value, 'yes') || strcmp(value, 'on')
        value = true;
    elseif strcmp(value, 'no') || strcmp(value, 'off')
        value = false;
    end
    % assign the value to a variable with the same name as the argument
    if isfield(exp_params, argument)
        exp_params = setfield(exp_params, argument, value);
    else
        error('unknown parameter: %s', argument);
    end
end
end

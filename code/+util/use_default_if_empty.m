%% Convenience function to set default values for empty arguments
%
% Example:
%     % If 'par' is empty, then the function uses a default value for 'par'.
%     function y = foo(par)
%         par = util.use_default_if_empty(par, 10);
%         % ...
%     end
%     foo([])
function y = use_default_if_empty(y, default_value)
    if isempty(y)
        y = default_value;
    end
end

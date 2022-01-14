% function NAMES = get_scene_paths(DIRECTORY, PATH, ROW, YEAR)
%   Returns a cell array of scene names.
%   DIRECTORY can be either a cell array with filenames to scene archives
%   or directories, or the name of a parent directory containing scene 
%   archives or directories.  If PATH and ROW are specified, the bounds
%   are limited to just those scenes from that path and row, as determined
%   from the archive filename.  Ditto for YEAR.
function names = get_scene_paths(directory, varargin)
% Collect Names
    if(iscell(directory))
        names = directory;
        file_path = '';
    elseif(strcmpi(directory(end-3:end), '.tar') || ...
           strcmpi(directory(end-5:end), '.tar.gz') || ...
           strcmpi(directory(end-3:end), '.mat'))
        names = {directory};
        return;
    else
        f = dir([directory '/LT4*']);
        f = [f; dir([directory '/LT5*'])];
        f = [f; dir([directory '/LE7*'])];
        f = [f; dir([directory '/LC8*'])];
        names = {f.name};
        file_path = directory;
        if(file_path(end) ~= '/' && file_path(end) ~= '\')
            file_path = [file_path '/'];
        end
    end
    
% Select those with PATH and ROW
    if(nargin >1)
        if ~isempty(varargin{1})
            pathrow = sprintf('%03d%03d', varargin{1}, varargin{2});
            keep = cellfun(@(x) strcmp(x(4:9),pathrow), names);
            names = names(keep);
        end
        
        if(nargin > 3)
            year = num2str(varargin{3});
            keep = cellfun(@(x) strcmp(x(10:13),year), names);
            names = names(keep);
        end
    end
    
    names = cellfun(@(x) [file_path  x], names, 'UniformOutput', false);
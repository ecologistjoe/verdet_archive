% function EXTENT = get_scene_bounds(DIRECTORY, PATH, ROW, YEAR)
%   Determine the minimal extent needed to contain all scenes specified.
%   DIRECTORY can be either a cell array with filenames to scene archives
%   or directories, or the name of a parent directory containing scene 
%   archives or directories.  If PATH and ROW are specified, the bounds
%   are limited to just those scenes from that path and row, as determined
%   from the archive filename.  Ditto for YEAR.
%   EXTENT is a 2x2 matrix specified as
%          [ LowerLeft_Northing   LowerLeft_Easting
%            UpperRight_Northing  UpperRight_Easting ]
function extent = get_scene_bounds(directory, varargin)


    names = get_scene_paths(directory, varargin{:})
    
    for i=1:length(names)
        M = readmetadata(names{i});
        LL(i, :) = [M.PRODUCT_LL_CORNER_MAPY   M.PRODUCT_LL_CORNER_MAPX];
        UR(i, :) = [M.PRODUCT_UR_CORNER_MAPY   M.PRODUCT_UR_CORNER_MAPX]; 
    end
  
    extent(1,:) = min(LL,[],1);
    extent(2,:) = max(UR,[],1);
    
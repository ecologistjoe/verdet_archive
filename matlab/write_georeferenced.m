function write_georeferenced(A,M, filename, bit_depth, MIN_MAX)

% MIN_MAX is an optional pair of values indicating that the data 
% is scaled such that 0 is MIN and 2^bits_per_sample is MAX
% Rescale Values if Desired
if nargin > 3
    if nargin < 5
        if isa(A, 'integer')
            MIN_MAX = [0 intmax(class(A))];
        else
            MIN_MAX = [min(A(:)) max(A(:))];
        end
    end

       
    %Scale data such that 0 becomes MIN and intmax(class) becomes MAX 
    switch bit_depth
    case 8
        if ~isa(A, 'uint8')
            A = uint8(255*(A-MIN_MAX(1))/diff(MIN_MAX));
        end
    case 16
        if ~isa(A, 'uint16')
            A = uint16(65535*(A-MIN_MAX(1)) / diff(MIN_MAX));
        end
    end
end
    
    if isfield(M, 'PIXEL_SIZE')
        res = M.PIXEL_SIZE;
    else
        res = 30;
    end
    
    ex = M.EXTENT + [0 0; 1 1]*res;
    ylims = ex(:,1)';
    xlims = ex(:,2)';
    
    % There is a backward-compatibility issue with some versions of Matlab.
    % Depending on version, one of these will work, the other won't.
    
    %R = maprasterref( ...
    %  'ColumnsStartFrom','north', ...
    %  'RasterSize', size(A), ...
    %  'YWorldLimits', ylims, ...
    %  'XWorldLimits', xlims);

    R = maprasterref( ...
      'ColumnsStartFrom','north', ...
      'RasterSize', size(A), ...
      'YLimWorld', ylims, ...
      'XLimWorld', xlims);
      
      
    Tags  = struct();
    Tags.Compression = Tiff.Compression.Deflate;
    if exist('MIN_MAX', 'var')
        Tags.XMP = sprintf('[%g %g]', MIN_MAX);        
    end
    
    M.PROJ.GTRasterTypeGeoKey = 1;
      
    geotiffwrite(filename, A, R, 'GeoKeyDirectoryTag', M.PROJ, 'TiffTags', Tags);

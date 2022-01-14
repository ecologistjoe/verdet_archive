function [A R] = read_georeferenced(filename)
    
    A = imread(filename);
    info = imfinfo(filename);
    
    
    % If a MIN_MAX field is present (in the XMP tag),
    % then make A a single and rescale it to the bounds
    if isfield(info, 'XMP')
        r = str2num(info.XMP);
        if length(r) == 2
            A = single(A)/single(intmax(class(A)))*diff(r)+r(1);
        end
    end
    
    gi = geotiffinfo(filename);
    R.PROJ = gi.GeoTIFFTags.GeoKeyDirectoryTag;
    R.PIXEL_SIZE = gi.PixelScale(1);
    R.EXTENT = fliplr(gi.BoundingBox) - [0 0; 1 1]*R.PIXEL_SIZE;
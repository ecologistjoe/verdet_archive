%function tile_landsat

%---------------------------------
    % Directory with tar.gz files to read in
    IN_DIR = 's:/smokies_usgs/';
    
    % Directory to write Tiles to
    OUT_DIR = 's:/smokies_blocks/';

    % Directory to store metadata files in
    META_OUT = 's:/smokies_metadata/';
    
    % Projection for output files.
    % This can be a PROJ.4 declaration (http://proj.maptools.org/gen_parms.html)
    %   eg: '+proj=latlong +datum=WGS84 +pm=madrid', or
    %       '+proj=utm +zone=17 +datum=WGS84'
    % or the location of a .prf / .prj file 
    % or anything else that gdalwarp can accept as a projection string
    PROJ = '+proj=utm +zone=17 +datum=WGS84';
    
    % Don't reproject scenes that are already in this zone, presumably
    % because this is the zone being projected into and they are already in
    % this projection.  Set to -999 to do all.
    SKIP_ZONE = 17;
   
    % Set if creating a single tile.  This should be in meters
    %[y*ysize x*xsize; (y+1)*ysize (x+1)*xsize]  - [0 0; 1 1]*OUT_RES
    SINGLE_TILE_BOUNDS = [3924000 255000; 3924000+45000-30 255000+60000-30];
  %  SINGLE_TILE_BOUNDS = [];
         
    % Otherwise, set Tile Size (in pixels)
    TILE_X = 1000;
    TILE_Y = 1000;
    
    % The buffer is a number of extra pixels in each direction from
    % neighboring tiles to include with each tile.
    % e.g. if a tile is 1000x1000 with a buffer of 50, then each cut-out
    % image will be 1100x1100 and that tile will be from (51:1050, 51:1050)
    % Buffers are useful to avoid edge effects and to reduce seems during
    % re-welding
    BUFFER = 100;
    
    % Set to true to generate cloud masks at the scene level and save with tiles
    MAKE_CLOUD_MASK = true;
    
    % Set to true to calculate the CLOUD MASK for the entire scene or for
    % each individual tile.
    CLOUD_MASK_OVER_SCENE = false;
   
    % Minimum percentage of tile with data to keep (values 0 to 1)
    MIN_COVER = 0.05;   % keep tiles with data in more than 5% of pixels
    
    % Output resolution; you should probably leave it at 30 
    OUT_RES = 30;
    
    % Tile numbering offset (used to prevent negative values, but not
    % necessary)
    TILE_NUM_X_OFF = 10;
    TILE_NUM_Y_OFF = 0;
       
%---------------------------------
    
    %Locations of 7-Zip and GDAL_WARP
    ZIP = './util/7z/7z ';
    GDAL = './util/gdal/';
    
    % A temporary directory for unzipping landsat data into.
    TMP = '__tartmp/';
    
%---------------------------------
        
    
    if ~exist(OUT_DIR, 'dir')
        [~,~] = mkdir(OUT_DIR);
    end
    if ~exist(META_OUT, 'dir')
        [~,~] = mkdir(META_OUT);
    end

    c = computer;
    if strcmp(c(1:2), 'PC')
        ZIP = strrep(ZIP, '/', '\');
        GDAL = strrep(GDAL, '/', '\');
    end

    GDAL_COMMAND = sprintf('%sgdalwarp --config GTIFF_POINT_GEO_IGNORE 1 -q -srcnodata 0 -tap -overwrite -t_srs "%s" -r cubic  -tr %d %d ', GDAL, PROJ, OUT_RES, OUT_RES) ;

    
    S = get_scene_paths(IN_DIR);

    for j = 1:length(S)
        fn = S{j};

        fprintf('%d: %s\n', j, fn);

        % Cleanup
        if(exist(TMP, 'file'))
            rmdir(TMP, 's');
        end

        % Extract TAR from TAR.GZ file
        if(strcmpi(fn(end-6:end),'.tar.gz'))
            [error,~] =system([ZIP ' e ' fn ' -aoa -o' TMP]);
            if error 
                disp(['The file could not be unzipped. 7z possibly not found']);
            end
            tarfile = dir([TMP '*tar']);
            fn = [TMP tarfile(1).name];
        end

        % Extract TIFFs from TAR file
        if(strcmpi(fn(end-3:end),'.tar'))
            [error,~]=system([ZIP ' e ' fn ' * -aoa -o' TMP]);
            if error 
                disp(['The file could not be untarred. 7z possibly not found']);
            end
        end

        M = readmetadata(TMP);

        landsat_name = tarfile(1).name(1:end-4);
        
        % Reproject
        [~,~] = mkdir([TMP 'reproj']);

        tiffs = dir([TMP '/*.TIF']);
        for b = 1:length(tiffs)
            fn = [TMP tiffs(b).name];

            if M.UTM_ZONE == SKIP_ZONE
                fn2{b} = fn;
            else
                fn2{b} = [TMP 'reproj/' tiffs(b).name];
                system([GDAL_COMMAND ' ' fn  ' ' fn2{b} ]);
            end
        end

        % Allocate Space for Data
        sz = [diff(M.EXTENT)/OUT_RES+1, 7];
        X = zeros(sz, M.DATA_TYPE);

        % Read Image Data
        for b = 1:length(fn2)
            R = imread(fn2{b});
            if all(size(R) == size(X(:,:,1)))
                X(:,:,b) = R;
            else
                X(:,:,b) = imresize(R, size(X(:,:,1)));
            end
        end
        
        is_data = all((X ~= M.DATA_FILL_VALUE), 3);
        switch M.DATA_TYPE
            case 'uint8'
                X = bsxfun(@times, X, uint8(is_data));
            case 'uint16'
                X = bsxfun(@times, X, uint16(is_data));
            case 'int16'
                X = bsxfun(@times, X, int16(is_data));
        end
           
        % Do DOS and save metadata
        if ~isfield(M, 'GAIN_SR');
            M = radiometric_normalization(M);
            M = darkobject_subtraction(X, M);
        end
        info = geotiffinfo(fn2{1});
        M.PROJ = info.GeoTIFFTags.GeoKeyDirectoryTag;
        save([META_OUT landsat_name '.mat'], 'M');
        
        if MAKE_CLOUD_MASK && CLOUD_MASK_OVER_SCENE
            O = reshape(single(X), [], 7);
            O = bsxfun(@plus, O*diag(M.GAIN_SR), M.OFFSET_SR);
            O = reshape(O, sz);
            O(O<=0) = 0.001;
            
            O = decloud(O, M);
        end
        
        % Get range of Tiles that this scene covers
        
        if SINGLE_TILE_BOUNDS
            gx = [1 1];
            gy = [1 1];
        else
            xsize = OUT_RES*TILE_X;
            ysize = OUT_RES*TILE_Y;
            gx = floor(M.EXTENT(:,2)/xsize);
            gy = floor(M.EXTENT(:,1)/ysize);
        end
        
        % Loop through tiles, clipping scene to the tile boundaries
        for y = gy(1):gy(2)
            for x = gx(1):gx(2)

                if SINGLE_TILE_BOUNDS
                    tile = SINGLE_TILE_BOUNDS;
                else
                    tile = [y*ysize x*xsize; (y+1)*ysize (x+1)*xsize] - [0 0; 1 1]*OUT_RES;   
                    tile = tile + [-1 -1; 1 1]*OUT_RES*BUFFER;        %add buffer
                end
                 
                % Clip data to tile extent
                A = align_scene(X, M.EXTENT, tile, OUT_RES);
                if MAKE_CLOUD_MASK
                    if ~CLOUD_MASK_OVER_SCENE
                        O = reshape(single(A), [], 7);
                        O = bsxfun(@plus, O*diag(M.GAIN_SR), M.OFFSET_SR);
                        O = reshape(O, size(A));
                        O(O<=0) = 0.001;
                        CLOUD = decloud(O, M);
                        clear O
                    else
                        CLOUD = align_scene(O, M.EXTENT, tile, OUT_RES);
                    end
                end
                
                % If less than or equal to MIN_COVER*100% of the pixels are
                % 0 (no data), then don't save this tile.
                if sum(A(:)>0) <= MIN_COVER * numel(A)
                    continue;
                end
                
                M.PIXEL_SIZE = OUT_RES;
                M.EXTENT = tile;

                path = sprintf('%s/%d_%d/', OUT_DIR, TILE_NUM_X_OFF+x, TILE_NUM_Y_OFF+y);
                if ~exist(path, 'dir')
                    mkdir(path)
                end
                
                if MAKE_CLOUD_MASK
                    save([path landsat_name '.mat'], 'A', 'M', 'CLOUD');
                else
                    save([path landsat_name '.mat'], 'A', 'M');
                end
            end
        end
        
    end




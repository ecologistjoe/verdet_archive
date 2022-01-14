function [X, META] = load_scene(fn, frame)
    ZIP = 'c:/projects/7z/7z ';
    TMP = 'c:/projects/__tartmptif/';
      
%** LOAD A .MAT FILE
    %If .mat file, load the scene and return
    if strcmpi(fn(end-3:end),'.mat')
        A=[]; X=[]; META=[];
        load(fn)
        
        % Check and see if a variable X or A was loaded
        if size(X, 3)== 7
            X = X;
        elseif size(A, 3) == 7
            X = A;
        end
       
        % If a variable called M was loaded, set output metadata to it
        if exist('M', 'var')
            META = M;
        end
        
        %If frame is provided, align scene
        if nargin > 2
            scene_extent = get_scene_bounds({fn});
            X = align_scene(X, scene_extent, frame);
        end
        
        % All done
        return
    end

    
%** LOAD .PNG CHIP SERIES
    % If .png file, load chip and return
    if strcmpi(fn(end-3:end),'.png')
        X = imread(fn);
        X = reshape(X, size(X,1), [], 7);
        
        %Chips don't have metadata or frames, so all done
        return
    end
    
    
%** LOAD DIRECTORY OF TIFFS

    % Cleanup old temporary files
    if(exist(TMP, 'file'))
        rmdir(TMP, 's');
    end

    % Extract TAR from TAR.GZ file
    if(strcmpi(fn(end-6:end),'.tar.gz'))
        [~,~]=system([ZIP 'e ' fn ' -aoa -o' TMP]);
        tarfile = dir([TMP '*tar']);
        fn = [TMP tarfile(1).name];
    end

    % Extract TIFFs from TAR file
    if(strcmpi(fn(end-3:end),'.tar'))
        [~,~]=system([ZIP 'e ' fn ' * -aoa -o' TMP]);
        fn = TMP;
    end


    % Read metadata and allocate space
    META = readmetadata(fn);
    in = geotiffinfo([fn META.FILENAMES{5}]);
    M.EXTENT = fliplr(in.BoundingBox);
    scene_size = diff(M.EXTENT)/30+1;
    if in.BitDepth == 16
        c = 'uint16';   %Landsat-8
    else
        c = 'uint8';
    end
    X = zeros([scene_size 7], c);
    
  
    % Read TIFFs into memory
    for i = 1:length(M.FILENAMES)
        f = M.FILENAMES{i};

        % Using LIBTiff is significantly faster than imread() when few strips
        tiffFile = Tiff([fn '/' f], 'r');
        if(tiffFile.numberOfStrips < 100)
            X(:,:,band) = tiffFile.read();
        else
            X(:,:,band) = imread([fn '/' f], 'tif');   
        end
        tiffFile.close();   
    end

    X = bsxfun(@times, X, all(X,3));
    
    if nargin>2
        X = align_scene(X, M.EXTENT, frame);
    end

    % Cleanup
    if(exist(TMP, 'dir'))
        rmdir(TMP, 's');
    end



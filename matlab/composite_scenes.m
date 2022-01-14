function [U,W,V] = composite_scenes(S, varargin)

    [CENTER_DAY, INPUT_DIR, META_DIR, CALC_NEW_MASK, OUTPUT_DIR, SUB_DIR, SKIP_NLAPS] = parse_inputs(S,varargin);
    
    W = 0;
    U = 0;
    V = 0;
            
    for i = 1:length(S)

       % fprintf(' %d ',i)
        fn = [INPUT_DIR '/' S{i}];

        date = regexp(fn,'L\w\d\d{3}\d{3}(\d{4})(\d{3}).*\.', 'tokens');
        day = str2num(date{1}{2});
        
        %Read metadata in case there's not on in the mat file
        %M = readmetadata(fn, META_DIR);
        
        % Get Image Data & Build Mask
        %[A, M] = load_scene(fn);
        
        %Read in A and M from .mat tile 
        load(fn, 'A', 'M');
        
        %Skip image if NLAPS processed -- Ground Control Issues
        if SKIP_NLAPS && strcmp(M.METAFORMAT, 'WO')
            continue;
        end
                
        if M.SPACECRAFT_ID == 4
            continue;
        end
                
        %Build Mask
        Mask = all(A,3);
        
        % Skip image if less than 5% coverage
        if sum(Mask(:)) / numel(Mask(:)) < 0.05
            continue;
        end
        
        %If not yet Dark Object Processed, do so now
        if ~isfield(M, 'GAIN_SR')
            % Build palette to convert image data to an approximation of surface reflectance
            M = radiometric_normalization(M,1);
            M = darkobject_subtraction(A, M);
        end
        
        sz = size(A);
        A = reshape(single(A), [], 7);
        A = bsxfun(@plus, A*diag(M.GAIN_SR), M.OFFSET_SR);
        A = reshape(A, sz);
        A(A<=0) = 0.001;
        
        % Calculate or Read Cloud Mask
        mask_file = sprintf('%s/masks/%s/mask_%s.tif', OUTPUT_DIR, SUB_DIR, S{i});
        if ~exist(mask_file,'file') || CALC_NEW_MASK
            if exist('CLOUD', 'var')
                O = CLOUD;
                clear CLOUD;
            else
                O = decloud(A, M);
            end
            K = O(:,:,3)+O(:,:,5);

            % Weight scenes more heavily that are closest to CENTER_DAY
            K = K.^2 .* exp(-((day- CENTER_DAY)/45).^4);
        else
            K = single(imread(mask_file));
        end
        K = K.*imerode(Mask, strel('disk', 5));


        % Accumulate Weights and weighted mean if cloud Mask isn't horrible
        if (sum(K(Mask)<0.01) / sum(Mask(:)) < 0.8)
            W = W + K;
            U = U + bsxfun(@times, A, K);
            
            if nargout > 2
                a = day/365*2*pi;
                V = V + bsxfun(@times, K, cat(3, sin(a), cos(a)));
            end
        end
        
         
        %Write a scene preview image and a mask file if OUTPUT_DIR is provided
        if ~isempty(OUTPUT_DIR)
            [~, ~] = mkdir([OUTPUT_DIR '/preview/' SUB_DIR]);
            [~, ~] = mkdir([OUTPUT_DIR '/masks/' SUB_DIR]);
        
            preview = cat(3, A(:,:,5)*1.5, A(:,:,[4 2]));
            preview_fn = sprintf('%s/preview/%s/pre_%s.tif', OUTPUT_DIR, SUB_DIR, S{i});
            %write_georeferenced(imresize(preview, 0.5), M, preview_fn);
            %write_georeferenced(K, M, mask_file);
        end
    end
    
    if ~exist('sz')
        sz = [1600 1600 7];
    end
    
    if ndims(U) < 3
        U = zeros(sz);
        W = zeros([sz(1:2), 1]);
        V = zeros([sz(1:2), 1]);
    else
        % Normalize 
        U = bsxfun(@rdivide, U, W+eps);
        if nargout > 2
            V = bsxfun(@rdivide, V, W+eps);
            V = (365/pi/2)*atan2(V(:,:,1), V(:,:,2));
            V = mod(V, 365);
        end
    end
    
    
% Parse paired inputs from VARARGIN 
function  [CENTER_DAY, INPUT_DIR, META_DIR, CALC_NEW_MASK, OUTPUT_DIR, SUB_DIR, SKIP_NLAPS] = parse_inputs(S,vin)

    k = max([strfind(S{1}, '/') strfind(S{1}, '\')]);
    
    % Defaults
    CENTER_DAY = 200;
    INPUT_DIR = S{1}(1:k);
    CALC_NEW_MASK = true;
    OUTPUT_DIR = '';
    SUB_DIR = '';
    META_DIR = '';
    SKIP_NLAPS = false;

    % User-specified
    for v = 1:2:length(vin)
        switch true
            case strcmpi(vin{v}, 'CENTER_DAY')
                CENTER_DAY = vin{v+1};
            case strcmpi(vin{v}, 'INPUT_DIR')
                INPUT_DIR = vin{v+1};
            case strcmpi(vin{v}, 'META_DIR')
                META_DIR = vin{v+1};
            case strcmpi(vin{v}, 'META_DIR')
                CALC_NEW_MASK = vin{v+1};
            case strcmpi(vin{v}, 'OUTPUT_DIR')
                OUTPUT_DIR = vin{v+1};
            case strcmpi(vin{v}, 'SUB_DIR')
                SUB_DIR = vin{v+1};
            case strcmpi(vin{v}, 'SKIP_NLAPS')
                SKIP_NLAPS = vin{v+1};
        end
    end
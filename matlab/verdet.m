function verdet(INPUT_DIR, varargin)


    [OUTPUT_DIR, CENTER_DAY, META_DIR, CALC_NEW_MASK, INDICES, DISTURBANCE_INDICES, CENTER_ONLY, CENTER_SIZE, SKIP_NLAPS, YEARS] = parse_inputs(varargin);
    

    [~, ~] = mkdir(OUTPUT_DIR);
    [~, ~] = mkdir([OUTPUT_DIR '/composites']);
    [~, ~] = mkdir([OUTPUT_DIR '/preview']);
    [~, ~] = mkdir([OUTPUT_DIR '/masks']);
    [~, ~] = mkdir([OUTPUT_DIR '/disturbed']);

    
    % Read filenames in this directory and get date info from landsat filename format
    S = dir([INPUT_DIR '/LT*']);
    S = {S.name};
    
    if isempty(S)
        return
    end
    
    for i = 1:length(S)
    	date = regexp(S{i},'L\w\d\d{3}\d{3}(\d{4})(\d{3}).*\.', 'tokens');
        years(i) = str2num(date{1}{1});
    end
    
     u = unique(years);
     u = intersect(u, YEARS);
     fprintf('\nCompositing scenes for year: ');
     for y = u
        
         % Composite scenes for this year
         fprintf(' %d', y);
         scenes = S(years==y);
         
         if ~isempty(scenes)
             [U,W,V] = composite_scenes(scenes, 'center_day', CENTER_DAY, ...
                     'meta_dir', META_DIR, 'sub_dir', num2str(y), 'input_dir', INPUT_DIR, ...
                     'calc_new_mask', CALC_NEW_MASK, 'output_dir', OUTPUT_DIR);
         else
             U = zeros(size(U));
             W = zeros(size(W));
             V = zeros(size(V));
         end    
 
         %Read metadata of one of the scenes for the spatial reference info
         load([INPUT_DIR '/' scenes{1}], 'M');
         
 
         % Write Means, Weights, and Indices to Disk
         %fprintf('\nWriting Means & Indices to disk: ')
         bmin = [0    0    0    0  0  200 0];
         bmax = [0.5  0.5  0.5  1  1  350  1];
         names = [{'b1', 'b2', 'b3', 'b4', 'b5',  'b6',  'b7', 'weights', 'avgday'} INDICES];
         
         for j = 1:length(names)
             idx = names{j};
             %fprintf(' %s, ', idx);
             
             if j < 8;
                 %continue;
                 X = U(:,:,j);
                 r = [0 bmax(j)];
             elseif j == 8;
                 X = W;
                 r = [0 16];
             elseif j == 9;
                 continue;  
                 X = V;
                 r = [0 365];
             else
                 [X, r] = band_index(U, idx);
             end
              
            % Save indices as 16bit GeoTIFFs
             [~, ~] = mkdir([OUTPUT_DIR '/composites/' idx]);
             out_fn = sprintf('%s/composites/%s/%s_%d.tif', OUTPUT_DIR, idx, idx, y);
             write_georeferenced(X, M, out_fn, 16, r);
         end
         
     end


    %fprintf('\nCompositing Complete!\n');

    %Finding Disturbances
    for idx = DISTURBANCE_INDICES
        fprintf('\nFinding disturbances for %s.\n', idx{1});
        find_disturbances(sprintf('%s/composites/', OUTPUT_DIR),  idx{1}, CENTER_SIZE, YEARS);
    end
    
    

% Parse paired inputs from VARARGIN 
function [OUTPUT_DIR, CENTER_DAY, META_DIR,CALC_NEW_MASK, INDICES, DISTURBANCE_INDICES, CENTER_ONLY, CENTER_SIZE, SKIP_NLAPS, YEARS] = parse_inputs(vin)
    % Defaults
    OUTPUT_DIR = INPUT_DIR;
    CENTER_DAY = 200;
    META_DIR = 'e:/metadata/';
    CALC_NEW_MASK = true;
    INDICES = {'ANGLE', 'NDVI'};
    CENTER_ONLY = false;
    CENTER_SIZE = 0;
    SKIP_NLAPS = false;
    YEARS = [];
    
    % User-specified
    for v = 1:2:length(vin)
        switch true
            case strcmpi(vin{v}, 'OUTPUT_DIR')
                OUTPUT_DIR = vin{v+1};
            case strcmpi(vin{v}, 'CENTER_DAY')
                CENTER_DAY = vin{v+1};
            case strcmpi(vin{v}, 'META_DIR')
                META_DIR = vin{v+1};
            case strcmpi(vin{v}, 'CALC_NEW_MASK')
                CALC_NEW_MASK = vin{v+1};
            case any(strcmpi(vin{v}, {'INDICES','INDEXES','INDEX'}))
                INDICES = vin{v+1};
            case any(strcmpi(vin{v}, {'DISTURBANCE_INDICES','DISTURBANCE_INDEXES'}))
                DISTURBANCE_INDICES = vin{v+1};
            case strcmpi(vin{v}, 'CENTER_ONLY')
                CENTER_ONLY = vin{v+1};
            case strcmpi(vin{v}, 'CENTER_SIZE')
                CENTER_SIZE = vin{v+1};
            case strcmpi(vin{v}, 'SKIP_NLAPS')
                SKIP_NLAPS = vin{v+1};
            case strcmpi(vin{v}, 'YEARS')
                YEARS = vin{v+1};
        end
    end
    
    if ~exist('DISTURBANCE_INDICES', 'var')
       DISTURBANCE_INDICES = INDICES;
    end
 
        
end
    
end
    
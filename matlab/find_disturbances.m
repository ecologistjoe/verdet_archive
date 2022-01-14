function find_disturbances(path, idx, center_size, years)
   
    tic
    if ~exist('center_size', 'var')
        center_size = 0;
    end
    
    % Construct years from imagery if not set (often passed as empty)
    if ~exist('years', 'var')
        years = [];
    end
    if isempty(years)
        d = dir([path '/' idx '/*.tif'])
        for i = 1:length(d)
            z = textscan(d(i).name, [idx '_%d.tif']);
            y(i) = z{1};
        end
        years = min(y):max(y);
    end        

    fprintf('Reading Data\n');
    % Read data for the given years.  The Metadata is only to spatially reference derived files.
    % All data should have the same spatial reference.
    for i = 1:length(years)
        year{i} = num2str(years(i));
        
        composite_fn = [path '/' idx '/' idx '_' year{i} '.tif'];
        if exist(composite_fn, 'file')
            [A(:,:,i), R] = read_georeferenced(composite_fn);
            W(:,:,i) = read_georeferenced([path '/weights/weights_' year{i} '.tif']);
        end
    end
 
    sz = size(A);
    if length(sz) == 2
        sz(3) = 1;
    end
    
    %Perform Inter-Year Interpolation on data
    A = weighted_interpolation(A,W);
    clear W
    
    
    % Do TVR filtering & calculate patch variances
    fprintf('Performing ROF & Patch variances: ');
    Z = zeros(sz,'single');
    V = zeros(sz,'single');
    P = zeros(sz,'uint16');
    
    % Patch Neighborhood
    k = single(getnhood(strel('disk',9)));
 
    for i = 1:sz(3)
        fprintf(' %d ', i);
        Z(:,:,i) = SplitBregmanROF(double(A(:,:,i)), 20, 1e-5);
        P(:,:,i) = make_patches(Z(:,:,i));
        V(:,:,i) = patch_variance(A(:,:,i), P(:,:,i), k); 
    end
    clear A
    V = n01(sqrt(V), 6);
    
    
    % Write ROF and Patch Variance images to disk
    fprintf('\n   Writing ROF & Variance images\n');
   
   % Make output path
    [~,~] = mkdir([path '/' idx '_TVR']);
    MIN_MAX = [min(V(:)) max(V(:))];
    for y = 1:sz(3)
        write_georeferenced(Z(:,:,y), R, [path '/' idx '_TVR/' idx '_Z_' year{y} '.tif'], 16, [-1 1]);
        write_georeferenced(V(:,:,y), R, [path '/' idx '_TVR/' idx '_var_' year{y} '.tif'], 16, MIN_MAX);
        write_georeferenced(uint16(P(:,:,y)), R, [path '/' idx '_TVR/' idx '_patches_' year{y} '.tif']);
    end
    clear P V;

    
    % Do 1st derivative TVR over each time step for both ROF and Patch
    % Variance image stacks
    fprintf('Detecting Changes\n');

    if center_size > 0
        c = center_size;
        [m, n, t] = size(Z);
        cm = min(c,m); cn = min(c,n);
        rows = floor(1+(m-cm)/2:(m+cm)/2);
        cols = floor(1+(n-cn)/2:(n+cn)/2);
        Z = Z(rows,cols,:);
        V = V(rows,cols,:);
    end

    %X = (Z ./ std(Z(:)) - V./std(V(:)))/2;
    X = Z;
    clear Z V;
    toc
    
    X(X<0) = 1e-5;
    X = fit_piecewise_linear(X);
    X = diff(X,[],3);
    MIN_MAX = [min(X(:)) max(X(:))];
    toc
    
    fprintf('   Writing Change Images\n');
    for y = 1:size(X,3)
        write_georeferenced(X(:,:,y), R, [path '../disturbed/' idx '_' year{y} '-' year{y+1} '.tif'], 16, MIN_MAX);
    end




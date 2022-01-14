function  summarize_data(path, tile, idx)
 
    if isnumeric(tile)
        tile = sprintf('%d_%d', tile);
    end
    
    if nargin < 2
        idx = 'NDMI'
    end
    
    
   % Get List of Files
    z = dir([path '/' tile '/composites/' idx '_TVR/' idx '_Z_*.tif']);
    d = dir([path '/' tile '/disturbed/' idx '*.tif']);

    % Read data.  The Metadata is only to spatially reference derived files.
    % All data should have the same spatial reference.
    for i = 1:length(z)
        [Z(:,:,i), R] = read_georeferenced([path '/' tile '/composites/' idx '_TVR/' z(i).name]);
    end
    for i = 1:length(d)
        D(:,:,i) = read_georeferenced([path '/' tile '/disturbed/' d(i).name]);
    end
    
    S = sort(Z,3,'descend');
    
    p{1}  = {'VEG',    [0,1],   @(D,S) mean(S,3)};
    p{2}  = {'VEGM',   [0,1],   @(D,S) median(S,3)};
    p{3}  = {'RANGE2', [0,1],   @(D,S) S(:,:,2)-S(:,:,end-1)};
    p{4}  = {'VEG_HI', [0,1],   @(D,S) S(:,:,2)};
    p{5}  = {'VEG_LO', [0,1],   @(D,S) S(:,:,end-1)};
    p{6}  = {'TREND',  [-1,1],  @(D,S) sum(D,3)};
    p{7}  = {'TREND1', [-1,1],  @(D,S) sum(abs(D).*D,3)};
    p{8}  = {'TREND2', [-1,1],  @(D,S) sum(sign(D).*((1+abs(D)).^2-1),3)};
    p{9}  = {'SKEW',   [-6,6],  @(D,S) skewness(D,0,3)};
    p{10} = {'CHANGE', [-1,1],  @(D,S) mean(abs(D),3)};
    p{11} = {'CHANGE2',[-1,1],  @(D,S) std(D,[],3)};
    p{12} = {'RANGE',  [0,1],   @(D,S) range(cumsum(D,3), 3)};
    p{13} = {'SEGS',   [0,255], @(D,S) uint8(sum(abs(diff(D,1,3))>1e-3,3))};
    
    for i = 1:length(p)
        fpath = [path '/summary_' idx '/' p{i}{1}];
        [~,~] = mkdir(fpath);
 
        V = p{i}{3}(D,S);
        if strcmp('uint8', class(V))
            bitdepth = 8;
        else
            bitdepth = 16;
        end
        write_georeferenced(V, R, [fpath '/' p{i}{1} '_' tile '.tif'], bitdepth, p{i}{2});
    end

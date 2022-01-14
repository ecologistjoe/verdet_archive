function make_band_index_special(block, idx)

%DELETE THIS FILE AFTER USING IT TO PATCH 10_80

    if isnumeric(block)
        if numel(block) == 1
            s = dir('/lustre/projects/verdet/blocks/*_*');
            block = s(block).name
        else
            block = sprintf('%d_%d', block);
        end
    end
    
        
    path = sprintf('/lustre/projects/verdet/verdet_out/%s/composites', block);

    w = dir([path '/weights/weights_*.png']);
    
    R = zeros([1600 1600 7], 'single');
    for y = 1984:2011
        fprintf('%d ', y)
    
        for b = 1:7
            band = sprintf('b%d', b);
            if exist([path '/' band '/' band '_' num2str(y) '.png'], 'file')
                Q = imread([path '/' band '/' band '_' num2str(y) '.png']);
                idx_r = load([path '/' band '/' band '_scaling.txt']);
                Q = single(Q)/65536*diff(idx_r)+idx_r(1);
            else
                Q = zeros(1600,1600, 'single');
            end
            
            R(:,:,b) = Q;
        end
        
        A(:,:,y-1983) = band_index(R, idx);
    end
    clear R Q
    fprintf('\n')
            
    % Read Weights
    for i = 1:length(w)
        W(:,:,i) = imread([path '/weights/' w(i).name]);
    end
    w_r = load([path '/weights/weights_scaling.txt']);
    W = single(W)/65536*diff(w_r)+w_r(1);

    
    A = weighted_interpolation(A, W);
    clear W;
    
    sz = size(A);
    
    % Do TVR filtering & calculate patch variances
    fprintf('Performing ROF & Patch variances: ');
    Z = zeros(sz,'single');
    V = zeros(sz,'single');
    P = zeros(sz,'uint16');
    k = single(getnhood(strel('disk',9)));
 
    for i = 1:sz(3)
        fprintf(' %d ', i);
        Z(:,:,i) = SplitBregmanROF(double(A(:,:,i)), 20, 1e-5);
        P(:,:,i) = make_patches(Z(:,:,i));
        V(:,:,i) = patch_variance(A(:,:,i), P(:,:,i), k); 
    end
    clear A
    V = n01(sqrt(V), 6);
    
    
    [~,~] = mkdir([path '/' idx '_TVR']);
    % Write ROF and Patch Variance images to disk
    fprintf('\n   Writing ROF & Variance images\n');
    mn = min(V(:));  mx = max(V(:));
    for y = 1:sz(3)
        year = num2str(1983+y);
        imwrite( uint16(65535*(Z(:,:,y)+1)  / 2),        [path '/' idx '_TVR/' idx '_Z_'   year '.png']);
    	imwrite( uint16(65535*(V(:,:,y)-mn) / (mx-mn)),  [path '/' idx '_TVR/' idx '_var_' year '.png']);
    	imwrite( uint16(P(:,:,y)),  [path '/' idx '_TVR/' idx '_patches_' year '.png']);
    end
    file_put_contents([path '/' idx '_TVR/' idx '_Z_scaling.txt'], '-1 1');
    file_put_contents([path '/' idx '_TVR/' idx '_var_scaling.txt'], num2str([mn mx]));
    
    
    

        


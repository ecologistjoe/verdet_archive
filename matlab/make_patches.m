function P = make_patches(Z, sigma)
% Z is the image to be patchified.  It should already be reasonably
% de-noised.  sigma is the strength of the gaussian filter during the
% zerocross Laplacian of Gaussian (LoG) stage.  It defaults to 1.5


    if nargin < 2
        sigma = 1.5;
    end

    [n, m] = size(Z);

    % Find Patches
    e = zerocross(Z, sigma);
    P = single(bwlabel(~e,4));


    % Put Edges of Zerocross into nearest-valued Patch
    ZZ = 10*ones(size(Z)+2);
    ee = zeros(size(e)+2);
    ZZ(2:end-1, 2:end-1) = Z;
    ee(2:end-1, 2:end-1) = e;

    f = find(e);

    I = bsxfun(@plus, find(ee), [-1 1 -(n+2) n+2]);
    Q = ZZ(I) + 100*ee(I);
    Q = bsxfun(@minus, Q, Z(f));
    [~, J] = min(Q,[],2);
    delta = [-1 1 -n n]';
    delta = delta(J);
    P(f) = P(f+delta);

    % Remove small objects and any residual edges from the Patches
    s = regionprops(P, 'Area', 'PixelIdxList'); 
    mask = false(size(Z));
    mask(cat(1,s([s.Area]<15).PixelIdxList)) = 1;
    mask = mask | (P==0);   %shouldn't be any, but just in case.
    [~, idx] = bwdist(~mask);
    P(mask) = P(idx(mask));
    
    % Renumber patches since some will have been removed
    [~,~,ic] = unique(P);
    P = reshape(ic, size(P));
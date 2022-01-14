function [X, range] = band_index(A, idx)

    tc= [ 0.2909  0.2493  0.4806  0.5568  0.4438 0 0.1706
          -0.2728 -0.2174 -0.5508  0.7221  0.0733 0 -0.1648
           0.1446  0.1761  0.3322  0.3396 -0.6210 0 -0.4186]';

    sz = size(A);
    
    range = [-1 1];
    switch true
        case any(strcmpi(idx, {'tasselcap', 'TC', 'tassel_cap'}))
            X = reshape(reshape(A, [],7)*tc,[sz(1:2) 3]);
            
        case any(strcmpi(idx, {'bright', 'brightness'}))
            X = reshape(reshape(A, [],7)*tc(:,1),[sz(1:2)]);
            
        case any(strcmpi(idx, {'green', 'greenness'}))
            X = reshape(reshape(A, [],7)*tc(:,2),[sz(1:2)]);
            
        case any(strcmpi(idx, {'wet', 'wetness'}))
            X = reshape(reshape(A, [],7)*tc(:,3),[sz(1:2)]);
            
        case strcmpi(idx, 'angle')
            TC = reshape(reshape(A, [],7)*tc(:,1:2),[sz(1:2) 2]);
            X = atan( TC(:,:,2) ./ (TC(:,:,1)+eps))/(pi/4);

        case strcmpi(idx, 'SARVI')
            X = (A(:,:,4) - 2*A(:,:,3) + A(:,:,1)) ./ (A(:,:,4) + 2*A(:,:,3) + A(:,:,1) +.5) *1.5;

        case strcmpi(idx, 'NDVI')
            X = ndi(A, 4, 3);
        case strcmpi(idx, 'NBR')
            X = ndi(A, 4, 7);
        case strcmpi(idx, 'NDSI')
            X = ndi(A, 2, 5);
        case strcmpi(idx, 'NDMI')
            X = ndi(A, 4, 5);
            
        case idx(1:3) == 'ndi'
            i = str2num(idx(4));
            j = str2num(idx(5));
            X = ndi(A, i, j);

    end
end

function X = ndi(A, i,j)
    X = (A(:,:,i) - A(:,:,j)) ./ (A(:,:,i) + A(:,:,j));
    X(isnan(X)) = 0;
end



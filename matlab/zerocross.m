function [e,b]= zerocross(X, sigma)

    
    fsize = ceil(sigma*4) * 2 + 1;  % choose an odd fsize > 6*sigma;
    
    k = fspecial('log',fsize,sigma);
    k = k - sum(k(:))/numel(k); % make the op to sum to zero
    b = imfilter(X,k,'replicate');
    
    s = sign(b);

    dx = imfilter(s, [-1 1],'replicate');
    dy = imfilter(s, [-1;1],'replicate');

    e = (dx>0) | (dy>0) ;
    e(:,2:end) = e(:,2:end) | (dx(:,1:end-1)<0);
    e(2:end,:) = e(2:end,:) | (dy(1:end-1,:)<0);

    e = bwmorph(e, 'thin');
    
    
    
    
    
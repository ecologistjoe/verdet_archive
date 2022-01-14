function x= n01(x, sigma)
    if nargin == 1
    % Rescale from 0 to 1
        m = min(x(:));
        r = range(x(:));
        x = (x-m) / r;
    
    else
    % Remove mean, and rescale from -sigma stds to +sigma stds, add the
    % mean back in
        m = mean(x(:));
        x = x-m;
        s = sigma * std(x(:));
        x(x<-s) = -s;
        x(x> s) = s;
        x = x+m;
    end
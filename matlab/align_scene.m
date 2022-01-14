function A = align_scene(X, s, f, pixel_size)
%[LL-N LL-E
% UR-N UR-E]


% Position Scene in Frame
    
    if(nargin < 4)
        pixel_size = 30;        %Landsat default
    end
    
   % Scale extents by the pixel size
    s = round(s/pixel_size);
    f = round(f/pixel_size);
    
   % Find sizes, in pixels, of extents
    sz = diff(s)+1;
    fz = round(diff(f)+1);

    A = zeros([fz size(X,3)], class(X));
    
   % Bounds for returned matrix of size fz
    Ti = max( f(2,1) - s(2,1), 0 ) + 1;
    Li = max( s(1,2) - f(1,2), 0) + 1;
    Bi = min(Ti + sz(1)-1, fz(1));
    Ri = min(Li + sz(2)-1, fz(2));
    
    if Ti>=Bi  || Li >= Ri
        return;
    end
    
    
    % Bounds indexing into given matix of size sz
    To = max( s(2,1) - f(2,1), 0 ) + 1;
    Lo = max( f(1,2) - s(1,2), 0) + 1;
    Bo = min(To + Bi-Ti, sz(1));
    Ro = min(Lo + Ri-Li, sz(2));

    if To>=Bo  || Lo >= Ro
        return;
    end
    
    if Bo == sz(1)
        Bi = Ti + Bo-To;
    end
    if Ro == sz(2)
        Ri = Li + Ro-Lo;
    end
    
    [Ti Bi Li Ri
     To Bo Lo Ro];
    
    [Bi-Ti Ri-Li
     Bo-To Ro-Lo]+1;
    
   % Make a matrix the size of the frame of type X, with as many bands as X
   % Then place some or all of X into the frame
   
   A(Ti:Bi, Li:Ri, :) = X(To:Bo, Lo:Ro,:);
    

    

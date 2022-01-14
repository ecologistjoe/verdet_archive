function [X, G] = fit_linear(B)

G = tv_1d_many(B, 1/30, 0.0001);

%rangeB = (max(B,[],3) - min(B,[],3));
%dx = median(rangeB(:))/30;
dx = 0.005;


Y = reshape(B,[],size(B,3))';
G = reshape(G,[],size(G,3))';

[n, m] = size(Y);

X = zeros(n, m);

for i = 1:m

    N = (1:n)';

    T = G(:,i);
    T1 = zeros(n,1);
    j = 0;
    YY = Y(:,i);
    while any(T1~=T) 
        j = j+1;
        T1 = T;
        dT = diff(T);
        Q = sqrt(dx + dT.^2);
        num = dT(1:end-1) .* dT(2:end);
        den =  Q(1:end-1) .*  Q(2:end);
        R = 1-(num+dx)./den;
        C = [1; R > 0.025; 1];                %Vector of Nodes

        f = [find(C); n+1];                 %Build Piece-wise Linear Model
        cc = cumsum(C);
        g = (N - f(cc)) ./ (f(cc+1)-f(cc));
        A = zeros(n, cc(end));
        A((cc-1)*n + N) = 1-g;
        A(cc(1:end-1)*n + N(1:end-1)) = g(1:end-1);
        
        b = A \ YY;                     %Find Y positions of Nodes
        T = A * b;         
    end
    
    X(:,i) = T;
end

X = reshape(X', size(B)); 
G = reshape(G', size(B)); 
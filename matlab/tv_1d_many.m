function O = tv_1d_many(X, alpha, tol)

sz = size(X);
X = reshape(X, [], sz(end))';
[n, m] = size(X);

if nargin < 3
    tol = 1e-4;
end

%Differentiation Matix
%D = -diag(ones(1,n)) + diag(ones(1,n-1), 1); 
%D(end,:) = [];

%Anti-Differentiation Matrix: A = -inv(D') 
A = tril(ones(n));
AtA = A'*A; %Save some math

O = zeros([n m]);
for j = 1:m
    
    f0 = X(1,j);
    f = X(:,j)-f0;
    
    Atf = A'*f;
    u = f;
    u1 = inf;

    % Iterate a maximum of 100 times
    for i  = 1:100
        
        E = alpha ./ (1e-6+abs(diff(u)));
        %L = D'*diag(E)*D;
        t = diag(E,1);
        L = diag([E(1);E(1:end-1)+E(2:end);E(end)]) - t - t';
        u = (AtA + L)\Atf;
        
        if all(abs(u1-u) < tol), break; end
        if any(isnan(u)); u=u1; break; end;
        u1 = u;
    end

    %Integrate U, adding f0 back in
    O(:,j) = A*u+f0;
end
    
O = reshape(O', sz);
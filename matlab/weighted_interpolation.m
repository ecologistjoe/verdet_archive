function O = weighted_interpolation(A, W)

[n, m, k] = size(A);
if k > 1
    A = reshape(A, [], k)';
    W = reshape(W, [], k)';
    n = k;
end

%Rescale weights that are 0-inf to 0-1
W = 2./(1+exp(-4*(W.*W)))-1;

% Build a spectral matrix for distance weights
D = triu(ones(n));
D = D*D;
D = D+tril(D',-1);
D = exp(-(D-1).^2/6);
D = bsxfun(@rdivide, D, sum(D,2));

% Find a Spectral Mean using weights and distances
M = (D*(A.*W)) ./ (D*W+eps);

% Build Output by adding in the amount of the spectral mean
O = (A.*W) + (1-W).*M;

if k > 1
    O = reshape(O', [],m, k);
end

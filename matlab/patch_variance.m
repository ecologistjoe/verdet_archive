function [V,M] = patch_variance(A, P, k)
% A contains values for which variance is measured.
% P contains uniquely-labled regions pixels that define 'patches' within
% which the variance is measured.
% k is a kernel.

if nargin < 3
    k = getnhood(strel('disk',9));
end
k = double(k);
classA = class(A);

P = single(P);

% Initialize zeros
zip = zeros(size(P),classA);
V = zip;
M = zip;
D_sum = zip;


k1 = zeros(size(k), 'double');

%loop through each pixel in the kernal
for i = 1:numel(k)

    if k(i) == 0, continue; end

    k1(i) = 1;  

    %Get values for current (i-th) pixel in kernel / moving window
    P_hat = conv2(P, k1, 'same');
    A_hat = conv2(A, k1, 'same');

    %kernel pixel is in same patch
    D = k(i) .* (P_hat==P);

    %Sum pixel values within patch
    M = M + D.*A_hat;
    V = V + D.*(A_hat.^2);

    % Get number of pixels contributing to mean
    D_sum = D_sum + D;

    k1(i) = 0;
end
% Calculate Mean & Variance
M = M./D_sum;   
V = V./D_sum - M.^2;
V(V<0) = 0;
function V = percentile(A,x)

A = sort(A, 'ascend');

n = ceil(size(A,1)*x/100);
V = A(n,:);

if isa(A, 'integer')

    V = double(V);
    for i = 1:numel(x)
        C = sum(bsxfun(@lt, A, V(i,:)));
        numV = sum(bsxfun(@eq, A, V(i,:)));

        V(i,:) = V(i,:) + (n(i)-C) / numV -1;
    end
        
end

R = kron(magic(3), ones(10)) / 10;
sz = size(R);

for m = 1:5
    for s = 1:5
    tic
        for i = 1:50
            for j = 1:50
                N = randn(sz)* m/10;
                N = imfilter(N, fspecial('gaussian',2*s-1), 'replicate');
                
                Y = SplitBregmanROF(R+N, 50/i, 1e-5);
                E = abs(Y-R);
                error(i,j) = mean(E(:));
                
            end
            fprintf('%d ', i);
        end
        fprintf('\n');
        e{m,s} = mean(error,2);
        [~,o] = min(imfilter(e{m,s}, [1 2 4 2 1]', 'replicate'));
        out(m, s) = o;
        o
    toc
    end
end

save('~/verdet/tvr_results.mat', 'out', 'e');
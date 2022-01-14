function [P W] = weld_map_composites(base, idx, year)

    BUFFER = 50;
    SCALE = 1;
    
    outdir = [base '/welded_disturbed/'];
    [~,~] = mkdir(outdir);
    [~,~] = mkdir([outdir 'full/']);
    [~,~] = mkdir([outdir 'half/']);
    [~,~] = mkdir([outdir 'quarter/']);
    [~,~] = mkdir([outdir '20ths/']);
    
    s = dir([base '2*_*']);
    s = s(:);
    t = regexp({s.name}, '(\d+)_(\d+)', 'tokens');
    
    name = [idx '_' year];
    for i = 1:length(t)
        if ~isempty(t{i})
            x(i) = str2num(t{i}{1}{1});
            y(i) = str2num(t{i}{1}{2});
        end
    end
    
    xlims = [min(x)-200 max(x)-199] * 45000 + [-1500 1500];
    ylims = [min(y)-200 max(y)-199] * 45000 + [-1500 1500];
   
    x = x-min(x);
    y = max(y)-y;
    %[A, R] = read_georeferenced([base '/' s(1).name '/disturbed/' name '.tif']);
    %A = downsize(A,SCALE);
    
    n = 1600; m = 1600;
    BUFFER = BUFFER /SCALE;
    
    P = zeros((n-2*BUFFER)*(max(y)+1)+2*BUFFER, (m-2*BUFFER)*(max(x)+1)+2*BUFFER, 'single');
    W = zeros(size(P), 'single');
    
    Q = zeros([n m], 'single');
    Q(1+BUFFER:end-BUFFER-1,1+BUFFER:end-BUFFER-1) = 1;
    Q = bwdist(Q);
    Q = max(0, (BUFFER-Q)/BUFFER);
    
    R = []; R1 = [];
    for i = 1:length(x)
        y0 = y(i)*(n-2*BUFFER)+1;
        y1 = y0+n-1;
        
        x0 = x(i)*(m-2*BUFFER)+1;
        x1 = x0+m-1;
        
        fn = [base '/' s(i).name '/disturbed/'  name '.tif']
        if exist(fn , 'file')
            [A, R1] = read_georeferenced(fn);
        
            if isempty(R)
                R = R1;
            else
                R.EXTENT(1,:) = min(R.EXTENT(1,:), R1.EXTENT(1,:));
                R.EXTENT(2,:) = max(R.EXTENT(2,:), R1.EXTENT(2,:));
            end

            P(y0:y1, x0:x1) = P(y0:y1, x0:x1) + A.*Q;
            W(y0:y1, x0:x1) = W(y0:y1, x0:x1) + Q;
        end
        
    end
    P = P./W;
    
    
    write_georeferenced(P, R, [outdir '/full/' name '.tif'])
 
    A = downsize(P,2);
    write_georeferenced(A, R, [outdir '/half/' name '-2.tif'])
   
    A = downsize(A,2);
    write_georeferenced(A, R, [outdir '/quarter/' name '-4.tif'])
    
    A = downsize(A,5);
    write_georeferenced(A, R, [outdir '/20ths/' name '-20.tif'])
    
function A = downsize(P, s)
    
    [n m] =size(P);
    A = mean(reshape(P, s, []));
    A = mean(reshape(reshape(A, n/s, m)', s, []));
    A = reshape(A, m/s, n/s)' ;
    
    
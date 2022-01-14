function  summarize_data(block, idx)
    base_path = '/lustre/projects/verdet/verdet_out';
 
    if isnumeric(block)
        if numel(block) == 1
            s = dir('/lustre/projects/verdet/blocks/*_*');
            block = s(block).name
        else
            block = sprintf('%d_%d', block);
        end
    end
    
    if nargin < 2
        idx = 'NDMI'
    end
    
    YEARS = 26;
  
    D = zeros([1600,1600,YEARS-1], 'uint16');
    Z = zeros([1600,1600,YEARS], 'uint16');
    
    path = sprintf('%s/%s/', base_path, block);
    
    ECO = imread(sprintf('/lustre/projects/verdet/ecoregions/ecoregion_%s.tif', block));
    
    % Read Data
    for i = 1:YEARS
        year = i+1984;
         Z(:,:,i) = imread(sprintf('%s/composites/%s_TVR/%s_Z_%d.png', path, idx, idx, year));
        if i < YEARS
        	%D(:,:,i) = imread(sprintf('%s/disturbed/%s_%d-%d.png', path, idx, year,year+1));
        end 
    end
    Z_r = load([path 'composites/' idx '_TVR/' idx '_Z_scaling.txt']);
   % D_r = load([path 'disturbed/' idx '_scaling.txt']);
    Z = single(Z)/65536*diff(Z_r)+Z_r(1);
   % D = single(D)/65536*diff(D_r)+D_r(1);
    
    % Amount of Vegetation
   % Z(Z<0) = 0;
    
    
    VEG = mean(Z,3);
   % RANGE2 = max(Z,[],3) - min(Z,[],3);
  %  VEG_SKEW = skewness(Z, 0, 3);
   % S = sort(reshape(Z, [], size(Z, 3))');
  %  VEG_LOW = reshape(S(2,:), size(VEG));
  %  VEG_HI = reshape(S(end-1,:), size(VEG));
    
    
    % Trend
   % TREND = sum(D,3);
   % TREND1 = sum(abs(D) .* D, 3);
   % TREND2 = sum(sign(D) .* ((1+abs(D)).^2-1), 3);
   % SKEW = skewness(D, 0, 3);
    
    % Change
   % CHANGE = mean(abs(D), 3);
   % CHANGE2 = std(D, [], 3);
    
    % Range
  %  C = cumsum(D,3);
  %  RANGE = max(C,[],3) - min(C,[],3);
    
    % Number of Segments
  %  D(abs(D)<1e-3) = 0;
  %  SEGS = sum(abs(diff(sign(D),[],3)), 3)/2 + 1;
    
  %  C = cumsum(cat(3, (Z(:,:,1) + Z(:,:,2))/2, D),3);
    
  %  veg = {}; trend = {}; change = {}; range = {}; seg = {}; sev = {}; veg2 ={}; trans = {};
    
  %  u = unique(ECO);
  %  u(u==0) = [];
  %  for i = 1:length(u)
  %      j = u(i);
  %      J = ECO(:)==j;
  %      JV = J & (VEG_HI(:) > .65);
  %      
  %      veg{j} = hist(VEG(J), 0:.05:1);
  %      trend{j} = hist(TREND(JV), -1:.05:1);
  %      change{j} = hist(CHANGE(JV), 0:.01:0.2);
  %      range{j} = hist(RANGE(JV), 0:.05:2);
  %      segs{j} = hist(SEGS(JV), 1:30);
  %      
  %      for y = 1:size(Z,3)
  %          ZZ = Z(:,:,y);
  %          veg2{j}(y,:) = hist(ZZ(JV), 0:.025:1);
  %      end
  %      
  %      for y = 1:size(D,3)
  %          DD = D(:,:,y);
  %          sev{j}(y,:) = hist(DD(JV), -1:.05:1);
  %      end
  %      
  %      for y = 2:size(C,3)
  %          C0 = min(10, max(1, ceil(C(:,:,y-1)*10)));
  %          C1 = min(10, max(1, ceil(C(:,:,y)*10)));
  %          
  %          C0 = bsxfun(@eq, C0(JV), 1:10);
  %          C1 = bsxfun(@eq, C1(JV), 1:10);
  %          
  %          T = double(C0)'*double(C1);
  %          
  %          trans{j}(:,:,y-1) = T';
  %      end
  %      
  %  end
    [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/veg']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/veg_hi']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/veg_low']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/veg_skew']);
  %  
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/trend']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/trend1']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/trend2']);
  %  
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/skew']);
    
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/change']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/change2']);
    
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/range']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/range2']);
    
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/segs']);
  %  [~,~] = mkdir(['/lustre/projects/verdet/summary_' idx '/stats']);
 
    imwrite(VEG, sprintf('/lustre/projects/verdet/summary_%s/veg/VEG_%s.png', idx, block));
  %  imwrite(VEG_HI, sprintf('/lustre/projects/verdet/summary_%s/veg_hi/VEG_HI_%s.png', idx, block));
  %  imwrite(VEG_LOW, sprintf('/lustre/projects/verdet/summary_%s/veg_low/VEG_LOW_%s.png', idx, block));
  %  imwrite((VEG_SKEW+4)/8, sprintf('/lustre/projects/verdet/summary_%s/veg_skew/VEG_SKEW_%s.png', idx, block));
    
  %  imwrite((TREND+1)/2, sprintf('/lustre/projects/verdet/summary_%s/trend/TREND_%s.png', idx, block));
  %  imwrite(TREND1*2+0.5, sprintf('/lustre/projects/verdet/summary_%s/trend1/TREND1_%s.png', idx, block));
  %  imwrite((TREND2+1)/2, sprintf('/lustre/projects/verdet/summary_%s/trend2/TREND2_%s.png', idx, block));
    
  %  imwrite((SKEW+6)/12, sprintf('/lustre/projects/verdet/summary_%s/skew/SKEW_%s.png', idx, block));
    
  %  imwrite(CHANGE*4, sprintf('/lustre/projects/verdet/summary_%s/change/CHANGE_%s.png', idx, block));
  %  imwrite(CHANGE2*4, sprintf('/lustre/projects/verdet/summary_%s/change2/CHANGE2_%s.png', idx, block));
    
  %  imwrite(RANGE/4, sprintf('/lustre/projects/verdet/summary_%s/range/RANGE_%s.png', idx, block));
  %  imwrite(RANGE2/4, sprintf('/lustre/projects/verdet/summary_%s/range2/RANGE2_%s.png', idx, block));
    
  %  imwrite(uint8(SEGS), sprintf('/lustre/projects/verdet/summary_%s/segs/SEGS_%s.png', idx, block));
    
  %  save(sprintf('/lustre/projects/verdet/summary_%s/stats/stats_%s.mat', idx, block), 'veg', 'trend', 'change', 'range', 'segs', 'sev', 'veg2', 'trans');
    

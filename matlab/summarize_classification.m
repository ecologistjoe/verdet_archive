function summarize_classification()

base_path = '/lustre/projects/verdet/';


%    s =[ 24 97; 14 86; 15 81; 27 101; 22 94; 16 86; 21 91; 27 99; 24 102;
%        14 90; 11 82; 23 95;  12 85; 25 102; 26 98; 30 101; 23 92; 15 92;
%        16 88; 17 88; 18 88; 19 88; 16 89; 17 89; 18 89; 19 89; 16 90; 17 90; 18 90; 19 90]; 

    s = dir('/lustre/projects/verdet/verdet_out/*_*');
    
ecoregions = [45 62 65 66 67 68 69 70];
%45 Piedmont
%62 North Central Appalachians
%64 Northern Piedmont
%65 Southeastern Plains
%66 Blue Ridge
%67 Ridge and Valley
%68 Southwestern Appalachians
%69 Central Appalachians
%70 Western Allegheny Plateau

classes = [ 0:9 16 32 64 128];
%0 No data
%1 Bark Beetles
%2 AGM
%3 HWA
%4 BBD
%5 Anthracnose
%6 Fire
%7 Weather
%8 Unknown
%9 Confused
%16 Stress
%32 Stable
%64 Regen
%128 Non-forest

    
C = zeros(24, length(classes), length(ecoregions));
    
for i = 1:length(s)
    block = s(i).name;
    
    fprintf('%d: %s\n', i, block);
    
    ECO = imread(sprintf('%s/ecoregions/ecoregion_%s.tif', base_path, block));
    
    % Read Data
    for year = 1986:2009
        y = year -1985;
        K = imread(sprintf('%s/classed/%s/CLASSED_%d.png', base_path, block, year));
        
        for i = 1:length(ecoregions)
            j = ecoregions(i);
            J = ECO(:)==j;
            
            C(y,:,i) = C(y,:,i) + sum(bsxfun(@eq, K(J), classes));
        end
    end        
end
    
save('/lustre/projects/verdet/classified_stats_all.mat', 'C');
    
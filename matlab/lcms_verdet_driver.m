function lcms_verdet_driver(i)

    w = 0;
    prs = dir('/lustre/projects/verdet/lcms/lcms_blocks/');
    for j = 3:length(prs)
        tiles =  dir(['/lustre/projects/verdet/lcms/lcms_blocks/' prs(j).name]);
        for k = 3:length(tiles)
            w = w+1;
            pr{w} = prs(j).name;
            a{w} = tiles(k).name;
        end
    end
    
    %pr = pr{i};
    %tile = a{i};
    
      
    %in_dir = sprintf('/lustre/projects/verdet/lcms/lcms_blocks/%s/%s',pr, tile);
    %out_dir = sprintf('/lustre/projects/verdet/lcms/verdet_out/%s/%s',pr, tile);
    %meta_dir = '/lustre/projects/verdet/lcms/lcms_metadata/';
    %fprintf('\n****** Tile %s: %s ****** \n', pr, tile)
    %verdet(in_dir, 'output_dir', out_dir,  'indexes', {'NDVI', 'NDMI'}, 'META_DIR', meta_dir, 'YEARS', [1982:2011]);
      
    %summarize_change(['/lustre/projects/verdet/lcms/verdet_out/' pr '/'], tile, 'NDMI');
    %summarize_change(['/lustre/projects/verdet/lcms/verdet_out/' pr '/'], tile, 'NDVI');
    
    d = mod(i-1,6)+1
    i = ceil(i/6)
    pr = prs(d+2).name
    
    if i <= 280
    exit;
        idxs = {'b1', 'b2', 'b3','b4', 'b5','b6','b7', 'NDMI', 'NDVI', 'weights'};
        years = 1984:2011;
        
        idx = idxs{ceil(i/28)}
        year = num2str(years(mod(i-1, 28)+1))
        
        weld_map_composites(['/lustre/projects/verdet/lcms/verdet_out/' pr '/'], idx, year);
            
    elseif i > 280 && i <= 334
        i = i -280;

        idxs = {'NDMI', 'NDVI'};
        years = 1984:2011;
        
        idx = idxs{ceil(i/27)}
        y = mod(i-1, 27)+1
        
        year = sprintf('%d-%d', years([y y+1]))
        
        weld_map_disturbed(['/lustre/projects/verdet/lcms/verdet_out/' pr '/'], idx, year);
    else
    exit;
        i = i - 334
            
        subdir = ['/lustre/projects/verdet/lcms/verdet_out/' pr '/summary_NDMI/']
        d = dir(subdir);
        d = d(3:end);

        weld_map([subdir d(i).name]);
        weld_map([subdir d(i).name]);    
    end
    
    exit;
    
end

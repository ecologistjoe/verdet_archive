function weld_summary_maps(i)

    i
    
    d = dir('/lustre/projects/verdet/seward/summary_NDMI');
    d = d(3:end);

    d(i).name
    
    weld_map(['/lustre/projects/verdet/seward/summary_NDMI/' d(i).name]);
    weld_map(['/lustre/projects/verdet/seward/summary_NDVI/' d(i).name]);
    

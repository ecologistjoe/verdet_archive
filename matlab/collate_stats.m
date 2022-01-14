
VEG = {}; TREND = {}; CHANGE={}; RANGE = {}; SEGS = {}; SEV = {}; VEG2 = {}; TRANS = {};



    s =dir('/lustre/projects/verdet/summary/stats/*.mat')



for i = 1:length(s);

    %if any(a==i), continue; end
    
    load(['/lustre/projects/verdet/summary/stats/' s(i).name]);
    
    F = find(~cellfun(@isempty, veg))
    
    for j = F
        if j > length(VEG) || isempty(VEG{j})
            
            VEG{j} = veg{j};
            CHANGE{j} = change{j};
            RANGE{j} = range{j};
            TREND{j} = trend{j};
            SEGS{j} = segs{j};
            SEV{j} = sev{j};
            VEG2{j} = veg2{j};
            TRANS{j} = trans{j};
        else
            VEG{j} = VEG{j} + veg{j};
            CHANGE{j} = CHANGE{j} + change{j};
            RANGE{j} = RANGE{j} + range{j};
            TREND{j} = TREND{j} + trend{j};
            SEGS{j} = SEGS{j} + segs{j};
            SEV{j} = SEV{j} + sev{j};
            VEG2{j} = VEG2{j} + veg2{j};
            TRANS{j} = TRANS{j} + trans{j};
        end
    end
end

save('/lustre/projects/verdet/summary/all_stats.mat', 'VEG', 'TREND', 'CHANGE', 'RANGE', 'SEGS', 'SEV', 'VEG2', 'TRANS');
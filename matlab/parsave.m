function parsave(fname,varargin)
for i = 1:length(varargin)
   eval([inputname(i+1),' = varargin{i};']);  
end

save(fname,inputname(2));
for i = 3:length(varargin)    
    save(fname,inputname(i),'-append');
end

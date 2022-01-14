%function M = readmetadata(FN)
%   FN should be a string containing the name of a _MTL or _WO text
%   file containing metadata or processing information, or the name
%   of a .TAR.GZ, .TAR, or directory containing one of those files.
function M = readmetadata(fn, metadir)
    ZIP = 'c:/projects/7z/7z ';
    TMP = 'c:/projects/__tartmpmeta/';
   
    % If given a metadir, then check for file there first
    if nargin == 2 && ~isempty(metadir)
        k = max([strfind(fn, '/') strfind(fn, '\')]);
        if isempty(k), k=0; end;

        if metadir(end) ~= '/'
            metadir = [metadir '/'];
        end

        fn = regexp(fn(1+k:end), '(L\w\d+)', 'tokens');
        
        meta = dir([metadir  fn{1}{1} '*']);
        fn = [metadir meta(1).name];
        
        %if directory contains a .mat file, load that structure and return
        if strcmpi(fn(end-3:end), '.mat')
            load(fn, 'M')
            return
        end
        
        %Otherwise continue processing (probably have a .txt file and will skip to last step
    end
    
    % Extract TAR from TAR.GZ file
    if(strcmpi(fn(end-6:end),'.tar.gz'))
        [~,~]=system([ZIP 'e ' fn ' -aoa -o' TMP]);
        tarfile = dir([TMP '*tar']);
        fn = [TMP tarfile(1).name];
    end

    % Extract metadata from TAR file
    if(strcmpi(fn(end-3:end),'.tar'))
        [~,~]=system([ZIP 'e ' fn ' *WO.txt -aoa -o' TMP]);
        [~,~]=system([ZIP 'e ' fn ' *MTL.txt -aoa -o' TMP]);
        meta = dir([TMP '*.txt']);
        fn = [TMP meta(1).name];
    end

        
    % If no .txt file found yet, see if FN contains the name of a directory
    if(~strcmpi(fn(end-3:end),'.txt'))
        meta = dir([fn '/*MTLold.txt']);
        meta = [meta; dir([fn '/*MTL*'])];
        meta = [meta; dir([fn '/*WO.txt'])];
        fn = [fn '/' meta(1).name];
    end

    % Read metadata
    if(strfind(lower(fn), '_wo.txt'))
        M = readNLAPSreport(fn);
    elseif(strfind(lower(fn), '_mtl'))      % should be old format
        M = readMTLmetadata(fn);
    end    

    if exist(TMP, 'dir')
        rmdir(TMP, 's');
    end

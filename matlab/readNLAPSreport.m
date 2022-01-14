function M = readNLAPSreport(fn)

fid = fopen(fn);
if(fid == -1)
    disp(['Cannot open file: ' fn]);
    return;
end
i = 0;
while(~feof(fid))
    i = i+1;
    A{i} = [fgetl(fid) ' '];
end
fclose(fid);

A = char(A);

M = struct();
M.METAFORMAT = 'WO';
M.DATA_TYPE = 'uint8';
M.DATA_FILL_VALUE = 0;

M.SPACECRAFT_ID           = strrep(strrep(A(8, 21:30), ' ', ''), '-' ,''); %remove spaces and '-'
M.SPACECRAFT_ID           = str2num(M.SPACECRAFT_ID(end));

M.UTM_ZONE                = str2num(A(16, 67:72));
M.SUN_ELEVATION           = str2num(A(36, 22:26));
M.SUN_AZIMUTH             = str2num(A(36, 67:76));
M.ACQUISITION_DATE        = strrep(A(37, 21:30), ' ', '-');
M.SCENE_CENTER_SCAN_TIME  = A(37, 68:80);
M.WRS_PATH                = str2num(A(28, 20:25));
M.WRS_ROW                 = str2num(A(28, 67:73));

pos_line = ceil( strfind(reshape(A', 1,[]), 'RADIOMETRIC CORRECTION') / size(A,2));
V = str2num(A(pos_line+(8:14), 20:40));
M.GAIN = V(:,1)';
M.OFFSET = V(:,2)';
    
% Image coordinates, corrected to be positions of pixel centers to match
%   LPGS processed files rather than upper left corners

pos_line = ceil( strfind(reshape(A', 1,[]), 'PRODUCT FORMATTING') / size(A,2));
M.PRODUCT_LL_CORNER_MAPX = str2num(A(pos_line+21, 10:20))+15;
M.PRODUCT_LL_CORNER_MAPY = str2num(A(pos_line+20, 10:20))-15;
M.PRODUCT_UR_CORNER_MAPX = str2num(A(pos_line+11, 65:75))+15;
M.PRODUCT_UR_CORNER_MAPY = str2num(A(pos_line+10, 65:75))-15;
M.EXTENT = [M.PRODUCT_LL_CORNER_MAPY M.PRODUCT_LL_CORNER_MAPX; M.PRODUCT_UR_CORNER_MAPY M.PRODUCT_UR_CORNER_MAPX]; 


slash = find('/'== fn, 1, 'last');
for b = 1:7
    M.FILENAMES{b,1} = [fn(slash+1:slash+16) '50_B' num2str(b) '.tif'];
end
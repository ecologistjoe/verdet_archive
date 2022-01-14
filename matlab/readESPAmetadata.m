function M = readESPAmetadata(fn)

A = xml2struct(fn);

G = A.espa_metadata.global_metadata;
B = A.espa_metadata.bands.band;


M = struct();
M.METAFORMAT = 'EPSA';

M.SPACECRAFT_ID           = str2num(G.satellite.Text(end));

M.UTM_ZONE                = str2num(G.projection_information.utm_proj_params.zone_code.Text);
M.SUN_ELEVATION           = 90-str2num(G.solar_angles.Attributes.zenith);
M.SUN_AZIMUTH             = str2num(G.solar_angles.Attributes.azimuth);
M.ACQUISITION_DATE        = G.acquisition_date.Text;
M.SCENE_CENTER_SCAN_TIME  = G.scene_center_time.Text;
M.WRS_PATH                = str2num(G.wrs.Attributes.path);
M.WRS_ROW                 = str2num(G.wrs.Attributes.row);


% Get extent, no support for when G.projection_information.grid_origin.Text does
% not equal "CENTER"
corner1 = G.projection_information.corner_point{1}.Attributes;
corner2 = G.projection_information.corner_point{2}.Attributes;
if strcmp(corner1.location, 'UL')
    UL = corner1;
    LR = corner2;
else
    UL = corner2;
    LR = corner1;
end
    
M.PRODUCT_LL_CORNER_MAPX = str2num(UL.x);
M.PRODUCT_LL_CORNER_MAPY = str2num(LR.y);
M.PRODUCT_UR_CORNER_MAPX = str2num(LR.x);
M.PRODUCT_UR_CORNER_MAPY = str2num(UL.y);
M.EXTENT = [M.PRODUCT_LL_CORNER_MAPY M.PRODUCT_LL_CORNER_MAPX; M.PRODUCT_UR_CORNER_MAPY M.PRODUCT_UR_CORNER_MAPX]; 

% Get Filenames of bands and their Gain / Offsets

for i = 1:length(B)
    if strcmp(B{i}.Attributes.product(1:7), 'sr_band')
        band_num = str2num(B{i}.Attributes.product(8));
        M.FILENAMES{band_num,1} = B{i}.file_name.Text;
        M.GAIN(band_num) = str2num(B{i}.Attributes.scale_factor);
        M.OFFSET(band_num) = str2num(B{i}.Attributes.add_offset);

        M.DATA_FILL_VALUE =  str2num(B{i}.Attributes.fill_value);
        M.DATA_TYPE =  B{i}.Attributes.data_type;
    end
end
M.GAIN_SR = M.GAIN;
M.OFFSET_SR = M.OFFSET;

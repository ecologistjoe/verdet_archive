function make_eastern_changescape(wart)
% T is a TREND, scaled 0 to 1
% C is a CHANGE, scaled 0 to 1
% V is a VEG, scaled 0 to 1
% W is a WATER, scaled 0 to 1

if nargin < 1
wart = '-2';
end

T = single(imread(['/lustre/projects/verdet/summary_NDMI/trend1/TREND1' wart '.tif']));
C = single(imread(['/lustre/projects/verdet/summary_NDMI/change/CHANGE' wart '.tif']));
V = single(imread(['/lustre/projects/verdet/summary_NDVI/veg/VEG' wart '.tif']));
%W = double(imread('/lustre/projects/verdet/summary_ANGLE/veg_hi_angle/VEG_HI-4.tif'));

T(isnan(T)) = 0;
C(isnan(C)) = 0;
V(isnan(V)) = 0;
%W(isnan(W)) = 0;

disp('data loaded');

T = T/255;
C = n01(C);
V = n01(V);
%W = n01(W);


V = V*2-1;
V =  tanh(2*V-.1) ./ tanh(2)/2+.5;
T = (T-.55).*1.6;;
T = tanh(4*T) ./ tanh(4);


val = (1-C).*V-abs(T)/4;
val = min(1, 1.1*val);
clear C;

sat = V .* (1+ 2*abs(T))/2;
sat = sat .* (1.1-val);
sat = min(1, sat);
clear V

hue = .6* (T/2+.5);
clear T


U = hsv2rgb(hue, sat, val);


%U = make_pretty_disturbance_map3(T,C,V);

disp('changescape created');

info = geotiffinfo(['/lustre/projects/verdet/summary_NDMI/trend1/TREND1' wart '.tif']);
X = info.BoundingBox(:,1)';
Y = info.BoundingBox(:,2)';

key.GTModelTypeGeoKey  = 1;  % Projected Coordinate System (PCS)
key.ProjectedCSTypeGeoKey = 32617;
R = maprasterref( ...
  'ColumnsStartFrom','north', ...
  'RasterSize', size(U), ...
  'XLimWorld', X, ...
  'YLimWorld', Y);
geotiffwrite(['/lustre/projects/verdet/changescape' wart '.tif'], uint8(U*255), R, 'GeoKeyDirectoryTag', key);

disp('saved!');
function r = distance_from_sun(date, format);

if(nargin<2)
    t = date;
else
    t = juliandate(date, format);
end

eccentricity = 0.01671;
epoch = 2451546.71;  %Jan 03, 2000 5:00
period = 365.259635864; % days in anomalous year 
semilatus_rectum = 0.999723237712583;

% Apply Kepler's Laws 1 & 2
M = (t-epoch) / period;
M = 2*pi* (M - floor(M));
E = fzero(@(x) x- eccentricity * sin(x) - M, 0);
theta = 2*atan(sqrt((1+eccentricity) / (1-eccentricity)) * tan(E/2));

% Calculate distance from the sun
r = semilatus_rectum ./ (1 + eccentricity * cos(theta));

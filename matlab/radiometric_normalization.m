% function [M P] = radiometric_normalization(A)
%   Generates a 255x7 table, P, of radiometric normalizations for a scene.
%   Also returns corrected GAIN and OFFSET in the metadata, M.
%   Additionally, P is added to the metadata as M.PALETTE
%   In P:
%     Each row has corrected values for the DNs as indexes.
%     Each column has corrections for the corresponding Landsat band.
%     To convert DN values stored in A representing band BAND use:
%           CORRECTED = reshape(P(A,BAND), size(A))
%   A is either a metadata structure generated with READMETADATA
%   or a string which is passed to READMETADATA containing the name
%   of a _MTL or _WO text file or the name of a .TAR.GZ, .TAR, or
%   directory containing one of those files.
function M = radiometric_normalization(A, norm_option)

    if nargin < 2
        norm_option = 1;
    end
    if nargin < 3
        return_temps = true;
    end
    
    
    if(isstruct(A))
        M = A;
    else
        M = readmetadata(A);
    end
    
    % Get Reflectance Gains & Offsets for older satellites
    if ~isfield(M, 'GAIN_REF')
        
        % Define ESUN Constants.  From G. Chander et al. 2009.  RSE:893-903
        switch M.SPACECRAFT_ID
           case 7
                M.ESUN=[1997, 1812, 1533, 1039, 230.8, 1, 84.90];
                M.K1 = 666.09;
                M.K2 = 1282.71;

           case 5
                M.ESUN=[1983, 1796, 1536, 1031, 220.0, 1, 83.44];
                M.K1 = 607.76;
                M.K2 = 1260.56;

           case 4
                M.ESUN=[1983, 1795, 1539, 1028, 219.8, 1, 83.49];
                M.K1 = 671.62;
                M.K2 = 1284.30;
        end

        scene_date   = [M.ACQUISITION_DATE ' ' M.SCENE_CENTER_SCAN_TIME];
        sun_distance = distance_from_sun(scene_date(1:19), 'yyyy-mm-dd HH:MM:SS');
    
        c = (pi*sun_distance^2 ./ M.ESUN);
        M.GAIN_REF   = c .* M.GAIN;
        M.OFFSET_REF = c .* M.OFFSET;
        M.GAIN_REF(6) = M.GAIN(6);
        M.OFFSET_REF(6) = M.OFFSET(6);
    end
    
    % Get correction for Sun Elevation
    cos_z = sin(M.SUN_ELEVATION/180*pi);
    
    % Select correction for atmospheric transmittance 
    switch norm_option
        case 1  %Simple, and empirically the best way!
            Tv = 1; Tz = 1;
        case 2
            Tv = 1; Tz = cos_z;
        case 3
            Tv = 1; Tz = [cos_z cos_z cos_z cos_z 1 1 1];
        case 4
            % Use optical thickness for Rayleigh scattering estimate from
            % Kaufman, 1989 as reported in Song et al. 2001 RSE: 230-244
            BAND_CENTERS = [483.74, 558.57, 659.32, 827.04,  1647, NaN, 2210.9]; %geometric means
            lam = BAND_CENTERS/1000;
            tau = 0.008569*lam.^-4 .*(1 + 0.0113*lam.^-2 + 0.00013*lam.^-4);
            Tv = exp(-tau/cos_z);  Tz = exp(-tau./cos_z);
    end    
    c = 1 ./(Tv .* Tz .* cos_z);
    
    M.GAIN_C    = c .* M.GAIN_REF;
    M.OFFSET_C  = c .* M.OFFSET_REF;
    M.GAIN_C(6) = M.GAIN(6);
    M.OFFSET_C(6) = M.OFFSET(6);
    
    
%     L1 = ones(256,1)*M.OFFSET + (0:255)'*M.GAIN;
%     P = ones(256,1)*correction .* L1;
%
%     %Find brightness temperature
%     if return_temps
%         P(:,6) = M.K2 ./ log(1 + M.K1./L1(:,6));
%     else
%         P(:,6) = L1(:,6);
%     end
    
%     %Remove Negative values to very low reflectances and Set index 0 to special value of 0
%     P(P<0) = 0.001;
%     P(1,:) = 0;
%     M.PALETTE = P;
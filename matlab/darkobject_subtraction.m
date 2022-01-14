function M = darkobject_subtraction(A, M)
  
    
    BAND_CENTERS = [483.74, 558.57, 659.32, 827.04,  1647,  2210.9]; %geometric means
    BAND_CENTERS = log(BAND_CENTERS);
    A = reshape(A,[],7);
    
    % Remove 0 values from A
    A = A(all(A,2),:);
    
    % Something's broken
    if size(A,1) == 0   
        return;
    end
    
    %if A is very large, it is sufficient to sample from A
    if size(A,1) > 2e7
        sample_factor = round(size(A,1) / 1e7);
        A = A(1:sample_factor:end,:);
    end
  
    L = percentile(A, [0.1;99.9]);
    Pmin = L(1,:) .* M.GAIN_C + M.OFFSET_C;
    too_low = Pmin<= M.GAIN_C/2;
    Pmin(too_low) = M.GAIN_C(too_low)/2;
    
    %** 'Chavez' Method, based on Chavez 1988
    % Regress minimums to enforce power-law scaling
    % b(2) will be -4 for a perfect Rayleigh atmosphere
    % real atmospheres should be between -4 and 0
    b = [ones(6,1) BAND_CENTERS'] \ log(Pmin([1 2 3 4 5 7]))';
    off = exp(b(1) + b(2).*BAND_CENTERS);
    off(off<0) = 0;
    off = [off(1:5) M.OFFSET_C(6) off(6)];
    
    bright = L(2,:) .* M.GAIN_C + M.OFFSET_C;
    bright_scaling = bright ./ (bright - off);
    
    gain = M.GAIN_C .* bright_scaling;
    off = (M.OFFSET_C - off) .* bright_scaling;
    
    gain(6) = M.GAIN_C(6);
    off(6) = M.OFFSET_C(6);
    
    %Old Formula. L(2) was untransformed.  Has to have been wrong?
    %gain = M.GAIN_C - (off - M.OFFSET_C) ./ L(2,:);
    
    
    % Update metadata
    M.DARK_MIN = [Pmin(1:5) 0 Pmin(7)];
    M.OFFSET_SR = off;
    M.GAIN_SR = gain;
    M.ATMOSPHERIC_SCALE = b(1);
    M.ATMOSPHERIC_ALPHA = b(2);
     
% Throw warnings if the atmospheric constant is not within expected bounds
%     if b(2) > -.5
%         warning('LandMat:HazyAtmosphere','Atmospheric scattering power is near 0 (%.3f).  Scene is probably too hazy to use.', b(2));
%     elseif b(2) < -4
%         warning('LandMat:WeirdAtmosphere', 'Atmospheric scattering power (%.3f) exceeds a theoretical Rayleigh-only atmosphere of -4.', b(2));
%     end
%     
    
    
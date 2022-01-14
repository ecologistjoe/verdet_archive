function O = decloud(A,M)
tic
    %pmem('start')
    
    load decloud_net;
    %[B1 B2 W1 W2] = cloudnet();

    [n, m, p] = size(A);
    A = reshape(A, [], 7);
    
    nn = n*m;
    O = zeros([nn 5], 'single');
    %pmem('make O')

    % Large scenes MUST be broken up for memory reasons.
    STEP = 2e6;
    for i = 0:STEP:nn
        i0 = i+1;
        i1 = min(i+STEP, nn);
        
        R = single(A(i0:i1,:));                 % Get data
        Mask = all(R,2);                        % Make a Mask where all data channels are present
        H = R(Mask,:);                          % Only do math on non-zeros

        H(:,6) = M.K2 ./ log(1 + M.K1./H(:,6)); % Convert to Brightness Temperature
        H(:,6) = H(:,6)/100 - 2;                % Arbitrarily re-scale;

        H = bsxfun(@plus, H*W1, B1);            % Inputs to Hidden Layer
        H = 2 ./ (1 + exp(-2*H)) - 1;           % tanh / sigmoidal tan transfer fcn.

        H = bsxfun(@plus, H*W2, B2);            % Hidden to Output layer
        H = bsxfun(@minus,H, max(H,[],2));      % softmax
        H = exp(H);
        H = bsxfun(@rdivide,H,sum(H,2)+eps);    % Normalize

        J =zeros([i1-i0+1 5], 'single');        % Masked-out areas are Zero
        J(Mask,:) = H;                          % Non-zeros are H
        O(i0:i1,:) = J;                         % Build output
    end
    %pmem('after NN')

    clear R H J;
    O = reshape(O, [n m 5]);

    %pmem('before postprocess')

   %% Post-Processing
    %Median Filtering
    O(:,:,1) = medfilt2(O(:,:,1), [3 3], 'symmetric');
    O(:,:,2) = medfilt2(O(:,:,2), [3 3], 'symmetric');

    O(O<0) = eps;
    O = bsxfun(@rdivide, O, sum(O,3)+eps);

    %pmem('after med filt')

    % Reduce cloud and shadow signal around large bodies of water
    % the transition zones tend to be classed as shadow or cloud
    wa = imopen(O(:,:,3), strel('disk', 15));
    wa = imdilate(wa, strel('disk', 3));
    wa = (1-max(wa, O(:,:,3))).^2; 
    O(:,:,[1 2 4]) = bsxfun(@times, O(:,:,[1 2 4]), wa);
    clear wa;
    O(O<0) = eps;
    O = bsxfun(@rdivide, O, sum(O,3)+eps);
    %pmem('after water edge')
    
    % Filter 5
    % Reduce cloud-shadow signal in areas without clouds

    % Remove very small cloud objects and apply soft threshold
    %cl = imerode(O(:,:,2), strel('square',2));
    cl = O(:,:,2);
    cl = 1./(1 + exp(-10*cl+5));
    %pmem('cloud proj 1')

    % Get offset of clouds
    tanELEV = tand(M.SUN_ELEVATION);
    d = 75/tanELEV;
    theta = 90-M.SUN_AZIMUTH;
    dx = d*cosd(theta);
    dy = -d*sind(theta);

    % Translate the cloud mask by the offset
    shift = strel('pair', round([dy dx])).getnhood;
    shift(2:end-1, 2:end-1) = 0;
    H = imfilter(cl, double(shift), 'replicate');
    H(H==-inf) = mean(cl(:));
    clear cl;
    %pmem('cloud proj 2')

    % Stretch the translated mask along a line that's parallel with
    % the sun angle, and then enlarge the mask
    a = strel('line', 15/tanELEV, theta).getnhood;
    a = imdilate(a, strel('disk', 10), 'full');
    H = imdilate(H, a);
    H = imfilter(H, 2.5*a/sum(a(:)), 'replicate');
    H = max(0, H-O(:,:,2));
    %pmem('cloud proj 3')

    % Expand the shadow mask slightly
    sh = imdilate(O(:,:,1)+O(:,:,3)/3, strel('disk',4));

    % Boost areas with shadow-land confusion
    sh = sh + (1- (sum(O(:,:,[2 3 4]),3) + abs(O(:,:,1)-O(:,:,5))).^2);
   
    %Apply
    sh = sh.*H;
    clear H;
    %pmem('cloud proj 4')

    wa_la = sum(O(:,:,[3 5]),3);
    t = O(:,:,1)-sh;
    t(t<=0) = eps;
    t = (t + wa_la) ./ wa_la;  
    O(:,:,3) = O(:,:,3).*t;
    O(:,:,5) = O(:,:,5).*t;

    O(:,:,1) = sh;

    clear sh wa_la t
    O(O<0) = eps;
    O = bsxfun(@rdivide, O, sum(O,3)+eps);
    %pmem('after cloud proj')


    % Remove interior ice from clouds
    cl = imopen(O(:,:,2), strel('disk', 6));
    cl = imclose(cl, strel('disk', 6));
    cl_ic = (sum(O(:,:,[1 3 5]),3) + abs(O(:,:,2)-O(:,:,4))).^2;
    O(:,:,4) = cl_ic.*O(:,:,4) + (1-cl_ic).*(O(:,:,2)-cl);
    O(:,:,2) = cl_ic.*O(:,:,2) + (1-cl_ic).*cl;
    clear cl cl_ic
    
    O(:,:,2) = imdilate(O(:,:,2), strel('disk',4));
    O(O<0) = eps;
    O = bsxfun(@rdivide, O, sum(O,3)+eps);
    %pmem('after ice')

    % Remove interior water from shadows
    sh = imclose(O(:,:,1), strel('disk', 15));
    sh_wa = (sum(O(:,:,[2 4 5]),3) + abs(O(:,:,1)-O(:,:,3))).^2;
    sh_wa = imclose(sh_wa, strel('disk', 2));
    O(:,:,3) = sh_wa.*O(:,:,3) + (1-sh_wa).*(O(:,:,1)-sh);
    O(:,:,1) = sh_wa.*O(:,:,1) + (1-sh_wa).*sh;
    
    clear sh sh_wa
    O(O<0) = eps;
    O = bsxfun(@rdivide, O, sum(O,3)+eps);
    %pmem('after shadow water')


    % Filter 6
    % Guess uncertain pixels from spatial averages

    V = var(O, [], 3)*5;
    MV = imfilter(V, fspecial('gaussian', 7,2), 'replicate')+eps;
    for i = 1:5;
    	S = imfilter(V.*O(:,:,i), fspecial('gaussian', 7, 2), 'replicate');
        S = S ./ MV;
        O(:,:,i) =  S + V.*(O(:,:,i)-S);
    end
    
    %pmem('after variance filter')

end
    
    
 
function pmem(note)
    %mem = memory;
    
    fprintf('MEM  %0.2f   TIME %0.2f    %s \n',  0/1024/1024/1024, toc, note);
    tic
end


function [B1 B2 W1 W2] = cloudnet()

B1 = [2.9416363
  -2.1918924
  -3.9578168
  -2.5894816
  -2.9707320
  -4.6393352
   1.7578974
  -0.2257878
   2.3279829
   0.5347939
   1.3855535
   0.4661481
  -1.2924201
  -5.1334143
  -1.0197093
   2.3544188
   1.4570639
   0.3036337
   1.8438547
   4.8178840
  -3.0644279
   5.3309288
   9.5805655
   0.0432455
  -0.7033547
  -3.5326798
   1.2099977
  -0.6300023
   2.4524164
   0.1170830]';
B2 = [-0.2563408   0.6539091  -0.6977157   0.3096068   0.9502448];

W1 = [  -3.3254728   1.6419770   2.9394016  -1.9789650   0.9934258  -0.2233480  -1.1689881
   2.3008173   1.0809025   0.4612475  -1.9473150  -2.6554456   0.7557199   2.4052997
   3.1616962  -2.0747011   0.4296328   1.9693263   0.0028539  -0.8709937   0.1031395
   1.6534539  -2.0489695   3.3139672  -1.1389096   0.0363286  -0.7072497  -0.5253730
   1.8919194  -0.0053575  -1.5097181   1.5440941  -3.3590183  -0.5526208   3.7714305
   3.1889279   4.3100214   3.3438931   0.5960006  -3.7160552   0.6979236   2.6941388
   0.3220651  -1.1397275   1.5835708   2.4625969  -4.4470997   0.4916628  -0.6617213
  -2.6292336  10.8748102  16.5742683  -5.9984431 -16.5669460  -0.1949835  -2.2500079
  -5.1998005  -1.3565786   3.3587685  -0.1756265  -3.8072271  -0.0984555   0.8010102
  -0.3608373   0.8366774   1.5821813  -9.0047684   0.6326212  -0.2358118  -0.6321021
  -5.0134659  -0.2292257  -1.1653425   3.2694426  -3.3507485  -0.0682587  -0.5262496
   0.6695105   0.8483806   1.4585428  -4.5514269   5.8051329   0.3304057   3.4025347
  -4.9430928   2.7106092  -3.4739361   7.2989173   4.8469424   0.1540810  -3.5949049
   1.2748953   4.3055081   3.8809805   2.0808372  -0.9131099  -0.2208101   2.0510440
   4.6057777   2.5658805  -1.0464023   5.6464539  -6.2633944  -0.2367916  -5.5491371
   3.5046747   2.1952875   2.9130688  -4.3534870  -4.7777114  -0.0267962  -3.9102061
  -4.6613441  -3.4196873  -1.4835761  -1.4401085   6.5768180  -0.0950362   0.3277138
   5.9560251  -1.2292656  -2.2314360  -0.4099677  -0.7247373   0.2824007  -1.4918809
  -3.9670136  -2.7251384  -3.3467972  -0.2098014  -2.2149537  -1.0219940   2.4664607
  -2.8427854   1.2184067  -3.6200283  -2.1844430  -0.6524705   1.0150177  -4.3229537
  -1.1324667  -1.8708394   2.1991658   1.9505987  -0.6355156   0.3611710   4.5156932
  -0.1229802   0.2960176  -4.2426391  -3.1857603  -2.4963050   0.1240424  -0.4524561
   1.2888728  -5.9201512  -2.4946055  -4.7379460  -3.2273910  -0.0391578  -5.1051497
  -2.6116607   4.4846888  -0.6329477  -1.3111829  -5.2853794   0.0104948   2.7405460
  -2.7188334  -0.3343498   2.8682034  -2.6481616  -3.0974848  -0.6099660   5.2843800
   0.0397067  -1.8471113  -1.4268618   2.2589295   4.5355320  -0.1190930  -0.0959144
   6.5258441  -3.9948285  -2.5301671   0.4462001   3.6452873  -1.5026264  -4.4790964
  13.4359837   4.5231333   3.0892689   1.1082363  -4.6462202   0.0134567  -3.2863886
   2.7293413   0.2669302   2.5023143  -1.7105799  -3.7762845   0.6527317  -0.3724926
  -8.6083536  -0.3724442   6.3817840   1.6969224  -1.3080144   0.6845468  -5.2651496]';
  
  W2 = [-0.3950182   0.4738890   0.2734481  -0.7738958  -0.7475531
  -0.4756818  -0.8343732  -0.0617840   0.4431828  -0.8053538
  -0.6674412   0.4304165  -0.7131677   1.0505998   0.4033969
  -0.2037346  -0.1165694  -0.0424464   0.1525086   0.6629518
  -0.0731682  -0.2078080  -0.3028004   0.2074113   0.2013528
   0.8908762  -0.6887048  -0.6981852   1.2020905  -0.7704601
   0.9751801   1.2065805   0.1552266  -0.9332128  -0.4933301
  -5.5045648  -0.9962759   4.8064160   2.3610384  -1.7073592
   0.0199518  -1.2791717   0.9938559   1.5019131   0.8549324
   2.3392959   0.8613535   2.7059729  -2.0210178  -4.5812402
  -0.8926181   0.2806301   1.3333724   2.0145500  -1.2587188
  -0.4655282   1.6123779   1.3751593  -1.1492227  -0.2883020
  -4.0231528   3.2290039  -1.0932707   0.0773638   0.4359489
   1.2307009  -0.0682837  -0.4815268   0.6827506  -0.9185330
   2.7557135  -1.5494016  -1.8051027   0.3386325  -1.9113848
   1.0718082  -0.6011210   3.1149497  -0.6257250  -1.6247000
  -1.8386441   0.3725639   1.7864523   1.5647268  -0.0957204
   0.4150142   1.0305479  -1.4333881  -0.9649854  -0.7517189
  -0.4328398   1.4656996   0.8647277  -1.6894513  -0.2373143
  -0.3345644  -1.0023609  -0.2237212   1.5627328   0.0388990
  -0.4618554  -1.0399765   1.0741681  -0.5204222  -0.6427405
   0.1520714  -1.0785056  -0.0818559   0.0362624   0.6747070
   2.5363894  -3.2958946   0.3400404   0.6237424  -0.3986331
  -0.9147661   0.7450285   0.8433674   1.6401813  -0.9280923
  -0.2497607  -0.3498425   1.9371450   0.4502973  -0.2454441
  -0.8557389  -1.0947307   1.1275601  -0.3802539  -0.7789382
   1.5430964   2.0052845  -1.5362579  -2.0921161   0.4231760
  -2.2092047   3.3530543  -0.6318281   3.5923193  -2.9062283
  -0.0787108  -0.0210797  -0.4093419  -0.3439945  -0.9507080
   0.9835824  -4.6082020   1.1879274   1.2130396   0.2938661];

end

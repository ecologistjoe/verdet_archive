function make_dark_object_metadata(my_pr)

base = '/lustre/projects/verdet/blocks/';

prs = [
'015033'
'015034'
'015035'
'015036'
'016033'
'016034'
'016035'
'016036'
'017033'
'017034'
'017035'
'017036'
'018033'
'018034'
'018035'
'018036'
'019033'
'019034'
'019036'
'020033'
'020034'
'020035'
'020036'
'015031'
'015032'
'015037'
'016031'
'016032'
'016037'
'017031'
'017032'
'017037'
'018031'
'018032'
'018037'
'019031'
'019032'
'019037'
'020031'
'020032'
'020037'
'019035'
];


blocks = dir([base '*_*']);

%scenes =[]
%for i = 1:size(blocks,1)
%    s = dir([base blocks(i).name '/LT*']);
%    f = [s(:).name];
%    f = reshape(f, length(s(1).name), [])';
%    scenes = [scenes; f];
%    scenes = unique(scenes, 'rows');
%end
%save('scenes.mat', 'scenes');

load scenes.mat;
f = bsxfun(@eq, scenes(:,4:9), prs(my_pr,:));
f = all(f,2);
scenes = scenes(f,:);

for j = 1:size(scenes, 1)

    b = 0;
    clear C
    for i = 1:size(blocks,1)
        if exist([base blocks(i).name '/' scenes(j,:)], 'file')
            b = b +1;
            A = load_scene([base blocks(i).name '/' scenes(j,:)]);
            C(:,:,b,:) = A; 
        end
    end
    C = reshape(C, 1600,[],7);
    
    M = readmetadata(scenes(j,:), [base '../metadata/']);
    M = radiometric_normalization(M,1); 
    M = darkobject_subtraction(C, M)
    
    
    save([base '../metadata_dos/' scenes(j,:)], 'M');

end


    
    
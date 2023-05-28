% [V,F,CData] = read3MF("C:\Users\Dimitrii Nikolaev\nextcloud - Home\_Dissertation\CAD\Robotermodell igm rte496 reduziert\exportiert\RAX_ROBAX3.3MF");
[V,F,CData] = read3MF("C:\Users\Dimitrii Nikolaev\nextcloud - Home\_Dissertation\CAD\Lasertracker Leica\exportiert\T-Probe_Stylus 100 mm.3MF");


%%
figure
patch_color( ...
    'EdgeColor',       'none',...
    'DisplayName',      'SMR Reflector', ...
    'Vertices',         V, ...
    'Faces',            F,...
    'CData',            CData ...
    ...'tform',            trvec2tform(tTablePointsCCR.tblPtsUpperFace_CCR{1,1:3})...
 );
axis equal;light
view(131,30)

%% Helpers
function p = patch_color(varargin,opt)
arguments(Repeating)
    varargin
end
arguments
    opt.Vertices
    opt.Faces
    opt.CData
    opt.tform   =   NaN
end
    % transform vertices if needed
    if ~isnan(opt.tform)
        opt.Vertices = (opt.tform * [opt.Vertices ones(length(opt.Vertices),1)]')';
        opt.Vertices = opt.Vertices(:,1:3);
    end

    p=patch('Vertices',opt.Vertices,'Faces', opt.Faces,...
        'FaceColor',        'flat',...
        'CData',            opt.CData, ...
        'FaceVertexCData',  opt.CData, ...
        'CDataMapping',     'direct',...
        varargin{:} ...
     );
    axis equal;
    view([-140 44])
    xlabel('X');ylabel('Y');zlabel('Z');
    hold on
    plot3([0 50],[0 0],[0 0],'r');
    plot3([0 0],[0 50],[0 0],'g');
    plot3([0 0],[0 0],[0 50],'b');
end
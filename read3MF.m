function [V,F,CData] = read3MF(fname)
%READ3MF Summary of this function goes here
%   Detailed explanation goes here
arguments
    fname   {mustBeFile(fname)} = "C:\Users\Dimitrii Nikolaev\nextcloud - Home\_Dissertation\CAD\Robotermodell igm rte496 reduziert\exportiert\RAX_ROBAX1.3MF"

end
    o.tmpFolder   =   "tmp__";
    V = [];
    F=[];
    CData = [];

    %% Cleanup temp files
    if isfolder(o.tmpFolder)
        rmdir(o.tmpFolder,'s');
    else
        mkdir(o.tmpFolder);
    end
    
    %% Unzip contents of .3MF
    [~,~,ext] = fileparts(fname);
    assert( ...
        matches(lower(ext),'.3mf'), ...
        'Input file should be of extension .3mf.'...
    );
    
    unzip(fname,o.tmpFolder);
    
    assert( ...
        exist("tmp__\3D\3dmodel.model",'file'), ...
        'No 3D model information found in %s file.', ...
        fname ...
    );
    
    %% read in dtructured xml
    S = readstruct( ...
        sprintf("%s/3D/3dmodel.model",o.tmpFolder), ...
        "FileType",             "xml", ...
        "AttributeSuffix",      "" ...
    );
    %% Parse objects
    % idRootComponent = find([S.resources.object.id]==1);
    % cRoot = S.resources.object(idRootComponent).components.component;

    %% 1) extract all components
    % for i=1:length(cRoot)
        % i_tform = double(regexpi(cRoot(i).transform,"([-]*\d+\.\d+)",'match'));
        % i_tform = [reshape(i_tform,[3,4]);[0 0 0 1]];
        [V,F,CData] = parseComponent_(S);

        % i_idxComp = find([S.resources.object.id]==cRoot(i).objectid);
        % i_idxMesh = find([S.resources.object.id]==S.resources.object(i_idxComp).components.component.objectid); %FIXME: can be nested
        % 
        % tMesh = S.resources.object(i_idxMesh);
        % %% 2)extract Faces, Vertices and colors
        % if ~ismissing(tMesh.pid)
        %     cDefault = resolveColor_(S,tMesh.pid);
        % else
        %     cDefault = [1 0 0]; %red
        % end
        % % vertices
        % iV = [[tMesh.mesh.vertices.vertex.x]', [tMesh.mesh.vertices.vertex.y]', [tMesh.mesh.vertices.vertex.z]'];
        % % Transform Vertices as defined for component
        % iV = i_tform*[iV ones(length(iV),1)]';
        % iV = iV(1:3,:)';
        % tFIdxOffset = 0;length(V);
        % V{i} = iV;
        % % faces
        % iF = [[tMesh.mesh.triangles.triangle.v1]', [tMesh.mesh.triangles.triangle.v2]', [tMesh.mesh.triangles.triangle.v3]'] + tFIdxOffset + 1;
        % F{i} = iF;
        % % color PID
        % iCData = repmat(cDefault,length(iF),1);
        % if isfield(tMesh.mesh.triangles.triangle,'pid')
        %     idxPID = ~ismissing([tMesh.mesh.triangles.triangle.pid]);
        %     colors = [tMesh.mesh.triangles.triangle(idxPID).pid]';
        %     t = resolveColor_(S,colors);
        %     iCData(idxPID,:) = t;
        % end
        % CData{i} = iCData;
    % end


    % %% merge all entries into a single one
    % VM = []; FM=[];CDataM = [];
    % for i=1:length(V)
    %     tFOffset = length(VM);
    %     VM = [VM;V{i}];
    %     FM = [FM;F{i}+tFOffset];
    %     CDataM = [CDataM;CData{i}];
    % end
    % CData = CDataM; V = VM; F = FM;
end

function CData = resolveColor_(S,id)
    % prepare color palet
    tIDs = [S.resources.m_colorgroup.id];
    tIDsBase = [S.resources.basematerials.id];
    propertyID = tIDs == id;
    for i = 1:length(tIDs)
        tC = S.resources.m_colorgroup(i).m_color;
        if ~ismissing(tC)
            cHex = regexpi(tC.color,'(?=#*)[A-F,0-9]{2}','match');
            C(tIDs(i),:) = hex2dec(cHex)/255;
        end
    end
    for i = 1:length(tIDsBase)
        tC = S.resources.basematerials(i).base;
        if ~ismissing(tC)
            cHex = regexpi(tC.displaycolor,'(?=#*)[A-F,0-9]{2}','match');
            C(tIDsBase(i),:) = hex2dec(cHex(1:3))/255;
        end
    end
    % assign colors
    CData(:,1:3) = C(id(1:end),:);

    % if ~any(propertyID)
    %     error("color not found among color groups");
    % end
    % [~,colIdx] = find(propertyID);
    % 
    % sColor = [S.resources.m_colorgroup(colIdx).m_color];
    % cHex = regexpi([sColor.color]','(?=#*)([A-F,0-9]{2}){3}','match');
    % if length(id) > 1
    %     CData = hex2dec([cHex{:}])/255;
    %     CData = reshape(CData,3,[])';
    % else
    %     CData = hex2dec(cHex)/255;
    % end
end

function [V,F,CData] = parseComponent_(S,id,tform)
arguments
    S
    id = 1
    tform = eye(4);
end
    V = [];
    F=[];
    CData = [];
    %--
    idxObj = find([S.resources.object.id]==id);
    Obj = S.resources.object(idxObj);
    % for i=1:length(Obj)
    if ismissing(Obj.mesh) && ~ismissing(Obj.components)
        % this is a container - do recursive call
        for i=1:length(Obj.components.component)
            if isfield(Obj.components.component,'transform')
                i_tform = double(regexpi(Obj.components.component(i).transform,"([-]*\d+\.\d+)",'match'));
                i_tform = [reshape(i_tform,[3,4]);[0 0 0 1]];
            else
                i_tform = eye(4);
            end
            [V{i},F{i},CData{i}] = parseComponent_(S,Obj.components.component(i).objectid,i_tform);
        end
        %% merge all entries into a single one
        if iscell(V)
            VM = []; FM=[];CDataM = [];
            for i=1:length(V)
                tFOffset = length(VM);
                VM = [VM;V{i}];
                FM = [FM;F{i}+tFOffset];
                CDataM = [CDataM;CData{i}];
            end
            CData = CDataM; V = VM; F = FM;
        end
        %% Apply component transformation
        V = tform*[V ones(length(V),1)]';
        V = V(1:3,:)';
    elseif ~ismissing(Obj.mesh) && ismissing(Obj.components)
        %proceed
        tMesh = Obj.mesh;
        %% 2)extract Faces, Vertices and colors
        if ~ismissing(Obj.pid)
            cDefault = resolveColor_(S,Obj.pid);
        else
            cDefault = [1 0 0]; %red
        end
        % vertices
        iV = [[tMesh.vertices.vertex.x]', [tMesh.vertices.vertex.y]', [tMesh.vertices.vertex.z]'];
        % Transform Vertices as defined for component
        iV = tform*[iV ones(length(iV),1)]';
        iV = iV(1:3,:)';
        tFIdxOffset = 0;length(V);
        V{end+1} = iV;
        % faces
        iF = [[tMesh.triangles.triangle.v1]', [tMesh.triangles.triangle.v2]', [tMesh.triangles.triangle.v3]'] + tFIdxOffset + 1;
        F{end+1} = iF;
        % color PID
        iCData = repmat(cDefault,length(iF),1);
        if isfield(tMesh.triangles.triangle,'pid')
            idxPID = ~ismissing([tMesh.triangles.triangle.pid]);
            colors = [tMesh.triangles.triangle(idxPID).pid]';
            t = resolveColor_(S,colors);
            iCData(idxPID,:) = t;
        end
        CData{end+1} = iCData;
    else
        error('WTF?')
    end
    % end



    %% merge all entries into a single one
    if iscell(V)
        VM = []; FM=[];CDataM = [];
        for i=1:length(V)
            tFOffset = length(VM);
            VM = [VM;V{i}];
            FM = [FM;F{i}+tFOffset];
            CDataM = [CDataM;CData{i}];
        end
        CData = CDataM; V = VM; F = FM;
    end
end

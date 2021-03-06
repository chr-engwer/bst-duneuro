function bst_view_tensor(iSubject)

%% SECTION 1 : Get the data
disp('view fem tensors')

%% Get the input data
% get the mesh
% get the EIG-DTI
% get the isotropic conductivity
% Get Protocol information
ProtocolInfo     = bst_get('ProtocolInfo');
ProtocolSubjects = bst_get('ProtocolSubjects');
% Default subject
if (iSubject == 0)
    sSubject = ProtocolSubjects.DefaultSubject;
    % Normal subject
else
    sSubject = ProtocolSubjects.Subject(iSubject);
end

%% Get the mesh file
% Get the conductivity values
FemFiles = file_fullpath(sSubject.Surface(sSubject.iFEM).FileName);
% Get name and the number of  layers
% Load the mesh
disp('load  the fem tensors')
femHead=  load(FemFiles);
numberOfLayer = length(femHead.TissueLabels);

%% Display the tensore within a mesh slice : defined by a plan
isQmeshcut = 0;
if isQmeshcut == 1
% define the cutting plan
z0 = mean(femHead.Vertices(:,3)); % range(femHead.Vertices(:,3))
z0 = 0.038;
plane = [min(femHead.Vertices(:,1)) min(femHead.Vertices(:,2)) (z0 + z0/2)
    min(femHead.Vertices(:,1)) max(femHead.Vertices(:,2)) (z0 + z0/2)
    max(femHead.Vertices(:,1)) min(femHead.Vertices(:,2)) (z0 + z0/2)];
% 
% y0 = 0.022;
% plane=[min(femHead.Vertices(:,1)) y0 min(femHead.Vertices(:,3))
%     min(femHead.Vertices(:,1)) y0 max(femHead.Vertices(:,3))
%     max(femHead.Vertices(:,1)) y0 min(femHead.Vertices(:,3))];
% 
% 
% x0 = 0.0;
% plane=[x0  min(femHead.Vertices(:,2))  min(femHead.Vertices(:,3))
%     x0  max(femHead.Vertices(:,2)) max(femHead.Vertices(:,3))
%     x0  min(femHead.Vertices(:,2)) min(femHead.Vertices(:,3))];

% run qmeshcut to get the cross-section information at z=mean(node(:,1))
% use the x-coordinates as the nodal values

[cutpos, cutvalue, facedata,elemid] = ...
                    qmeshcut(femHead.Elements,femHead.Vertices,zeros(length(femHead.Vertices),1),plane);
end

isGibbon = 1;
if isGibbon == 1
    
n=[0 0 0]; %Normal direction to plane
[res, isCancel] = java_dialog('radio', '<HTML><B> Direction of the plan where to cut <B>', ...
        'Select cut direction', [],{'x','y','z'}, 3);
if isCancel;         return;    end
n(res) = 1;


P=mean(femHead.Vertices,1); %Point on plane
[logicAt,logicAbove,logicBelow]=bst_meshCleave(femHead.Elements,femHead.Vertices,P,n);
% inclusiveSwitch=[1 1 ];
% [logicAt,logicAbove,logicBelow]=meshCleave(femHead.Elements,femHead.Vertices,P,n,inclusiveSwitch);
% figure, plotmesh(femHead.Vertices,[femHead.Elements(logicAt,:) femHead.Tissue(logicAt,:)])                
elemid =  find(logicAt);  
end
    

% figure;
% plotmesh(femHead.Vertices,[femHead.Elements femHead.Tissue], 'facealpha', 0.2,'edgecolor','none');
% hold on
%   ;
% view([0 0 90])
% title('Slice of mesh where the tensor will be displayed')

%% Display intererface
% 1- ask user which tissue to include
% ask for the layer to consider as anisotrop
[res, isCancel] = java_dialog('radio', ...
    '<HTML> Select the layers to consider for displaying the tensor <BR>', 'Select Tissues', [], ...
    [femHead.TissueLabels {'all'}], 1);
if isCancel;         return;    end
includedTissueIndex = (res);
if includedTissueIndex > length(unique(femHead.TissueLabels))
    includedTissueIndex = unique(femHead.Tissue);
end
elemToDisplay = num2str(length(find(femHead.Tissue(elemid) == includedTissueIndex')));

% linespace : equally spaced points between all the tensors 
[res, isCancel] = java_dialog(  'input' , ['step : equally space the '  num2str(elemToDisplay) ' tensor by a step =  ' ],...
    'Reduce the number of tensor to display' ,[],'10');
if isCancel;         return;    end
regularStep = str2double( res);


% display the head model
[res, isCancel] = java_dialog('radio', '<HTML><B> Display the head model (overlay with tensors) <B>', ...
        'Select Head Model', [],{'Yes','No'}, 1);
if isCancel;         return;    end
if res == 1
    displayHeadModel = 1;
else
    displayHeadModel = 0;
end

% display the tensors
[res, isCancel] = java_dialog('radio', '<HTML><B> Display the tenosr as <B>', ...
        'Select tensor view', [],{'Ellipse','Arrow (main eigen vector, useful only with anistropic case) '}, 1);
if isCancel;         return;    end
if res == 1
    displayAsEllipse = 1;
    displayAsArrow = 0;
    
else
    displayAsEllipse = 0;
    displayAsArrow = 1;
end

cfg = [];
cfg.node = femHead.Vertices; % list of nodes 
cfg.elem = [femHead.Elements femHead.Tissue] ; % list of element with lable 
cfg.elemid = elemid;
cfg.elemid = elemid(find(sum((femHead.Tissue(elemid) == includedTissueIndex'),2))); % reduced to the element to display

cfg.elemid = cfg.elemid(1:regularStep:end); % reduced to the element to display    find(cfg.elem(cfg.elemid,5) ==3)

m='t';  
if isfield(femHead,'tensors') && m == 't'
    cfg.eigen = femHead.tensors; % thei eigen data  
    cfg.elem_centroide = femHead.tensors.position; % the centoride of the element

elseif isfield(femHead,'Tensors') && m=='f'
    cfg.tensors = femHead.Tensors;
    % bst_progress('text', 'Computing elements centroids...');
        nElem = size(femHead.Elements, 1);
        nMesh = size(femHead.Elements, 2);
        ElemCenter = zeros(nElem, 3);
        for i = 1:3
            ElemCenter(:,i) = sum(reshape(femHead.Vertices(femHead.Elements,i), nElem, nMesh)')' / nMesh;
        end
    cfg.elem_centroide = ElemCenter;

else
    error('no tensor available ...')
end


cfg.ellipse = displayAsEllipse; % display as an ellipse 
cfg.arrow = displayAsArrow; % display as an arrow
cfg.plotMesh = displayHeadModel; % plot the head model
cfg.conversion_m2mm = 1000;
bst_display_fem_tensors(cfg) % the displaying function


% 
% view([0 -90 0])
axis([ min(cfg.node(:,1))  max(cfg.node(:,1)) ...
    min(cfg.node(:,2))  max(cfg.node(:,2)) ...
    0  max(cfg.node(:,3))])
% hold on
% plotmesh(femHead.Vertices,femHead.Elements(cfg.elemid,:),'facealpha',0.2,'edgecolor','none');
% plotmesh(femHead.Vertices,femHead.Elements(cfg.elemid,:),'facealpha',0.2,'edgecolor', [0.5 0.5 0.5]);
% plotmesh(femHead.Vertices,[femHead.Elements femHead.Tissue],'facealpha',0.2,'edgecolor', [0.5 0.5 0.5]);

% view([90 0 0])
% 
% hold on
% plotmesh(femHead.Vertices,femHead.Elements(:,:),'facealpha',0.2);
% 
% view([0 0 90])
% 
% 
% figure;
% plotmesh(femHead.Vertices,femHead.Elements,'facealpha',0.2,'edgecolor','none');
% view([0 0 90])

% 
% figure;
% plotmesh(femHead.Vertices,femHead.Elements(elemid,:),'facealpha',0.2);
% view([0 0 90])

end
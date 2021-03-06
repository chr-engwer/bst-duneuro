clc;clear all;close all;
restoredefaultpath;


%% 
% This code performs defacing of brain mri by first applying rigid 
% registration and then deforming the mask from BCI-DNI brain
%
%% INPUT: 
% This following code expects that the subject.mask.nii.ga and
% subject.bfc.nii.gz exist. These files are generated by running
% BrainSuite's first two steps.

% If these files do not exist, then
% first run BrainSuite sequence on the subject MRI till BSE and BFC (the
% first two steps of BrainSuite sequence).

%% OUTPUT:
% The output is stored at <subject>.deface.mask.nii.gz and <subject>.deface.nii.gz

%%
% This is the name of the subject mri that you want to deface
mriname = 'ADNI_T1fs_conform';
tmpDir =  'G:\My Drive\GitFolders\GitHub\mriDefacedata';

subbasename = fullfile(tmpDir,mriname); 
T1Nii = [subbasename '.nii'];
% ===== 1. BRAIN SURFACE EXTRACTOR (BSE) =====
    bst_progress('text', '1/3: Brain surface extractor...');
    strCall = [...
        'bse -i "' T1Nii '" --auto' ...
        ' -o "' fullfile(tmpDir, 'skull_stripped_mri.nii.gz"') ...
        ' --mask "' fullfile(tmpDir, [mriname '.mask.nii.gz"']) ...
        ' --cortex "' fullfile(tmpDir, 'bse_cortex_file.nii.gz"')];
    disp(['BST> System call: ' strCall]);
    status = system(strCall);
% Error handling
if (status ~= 0)
    errMsg = ['BrainSuite failed at step 1/3 (BSE).', 10, 'Check the Matlab command window for more information.'];
    return
end

% ===== 2. BIAS FIELD CORRECTION (BFC) =====
bst_progress('text', '2/3: Bias field correction...');
strCall = [...
    'bfc -i "' fullfile(tmpDir, 'skull_stripped_mri.nii.gz"') ...
    ' -o "' fullfile(tmpDir, [mriname '.bfc.nii.gz"']) ...
    ' -L 0.5 -U 1.5'];
disp(['BST> System call: ' strCall]);
status = system(strCall);
% Error handling
if (status ~= 0)
    errMsg = ['BrainSuite failed at step 2/3 (BFC).', 10, 'Check the Matlab command window for more information.'];
    return
end
    
    
% Location of BrainSuite's BCI-DNI atlas
atlasbasename = 'C:\Program Files\BrainSuite19b\svreg\BCI-DNI_brain_atlas\BCI-DNI_brain';

% Deface mask that is included with this script. It is in the same
% directory as this code.
atlas_deface_mask = fullfile(tmpDir, 'BCI-DNI_brain.deface.mask.nii.gz');

curDir =pwd;
cd('G:\My Drive\GitFolders\GitHub\mri_deface\deface_mri\private')
aa=tic;

deface_mri(subbasename,atlasbasename,atlas_deface_mask);

toc(aa)

cd(curDir)

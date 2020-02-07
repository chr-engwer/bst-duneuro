function cfg = bst_set_duneuro_cmd(cfg)
% Select the command line acording to the version of the cfg.BstDuneuroVersion
% cfg.BstDuneuroVersion = 1 : refers to the previous app generated before the combined version
% cfg.BstDuneuroVersion = 2 : refers to the new app generated by the new
% version of Juan + Tak modification to includ meeg
% cfg.BstDuneuroVersion = 3 : refers to the new app  that the modality is
% icluded within the ini file

% Author : Takfarinas MEDANI, November, 2019,
%               Update : change the version 2 from bst_duneuro to
%               bst_duneuro_meeg (all in one 'eeg','meg','meeg'),

if ~isfield(cfg,'BstDuneuroVersion');  cfg.BstDuneuroVersion = 2; end

% We keep this version for testing 
if cfg.BstDuneuroVersion == 1 
    if strcmp(cfg.modality,'eeg')
        if cfg.useTransferMatrix  == 1 % faster
            cmd = 'bst_eeg_transfer';
        else
            cmd = 'bst_eeg_forward';     % not recommended
        end
    elseif strcmp(cfg.modality,'meg')
        % other modalities meg, ieeg, seeg ...
        % TODO
    elseif strcmp(cfg.modality,'meeg')
        % other modalities meg, ieeg, seeg ...
        % TODO
    elseif strcmp(cfg.modality,'seeg')
        % other modalities meg, ieeg, seeg ...
        % TODO
    elseif strcmp(cfg.modality,'ieeg')
        % other modalities meg, ieeg, seeg ...
        % TODO
    elseif strcmp(cfg.modality,'ecog')
        % other modalities meg, ieeg, seeg ...
        % TODO
    end
end

if cfg.BstDuneuroVersion == 2 || cfg.BstDuneuroVersion == 3 % refers to the new version all in one
    % cmd = 'bst_duneuro_meeg';
    % Use new version of name generated from juan shell file, from
    % 1/24/2020
    str = dir(fullfile(cfg.pathOfDuneuroToolbox,'bin','*.exe'));
    [filepath,cmd, ext] =  fileparts(str(1).name);
end

cfg.cmd = fullfile(cfg.pathOfDuneuroToolbox,'bin', cmd);
end
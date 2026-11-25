%-------------------------------------------------------------------------
% Script to run multiple experimental scripts all in a row:

% Whole report for objects and colors 

%-------------------------------------------------------------------------
clear all;  % clear everything out!
close all;  % close existing figures
warning('off','MATLAB:dispatcher:InexactMatch');  % turn off the case mismatch warning (it's annoying)
dbstop if error  % tell us what the error is if there is one
AssertOpenGL;    % make sure openGL rendering is working (aka psychtoolbox is on the path)
%-------------------------------------------------------------------------
% Build a GUI to get subject numberxxcx
%-------------------------------------------------------------------------
prompt = {'Subject Number','Unique ID','Counterbalance','Age','Gender (1 = Female, 2 = Male, 3 = Other/ Non-binary, 4 = Choose not to respond)', 'Handedness (1 = Right, 2 = Left)'};            % what information do we want from the subject?
defAns = {'','','','','',''};                                           % fill in some stock answers - here the fields are left blank
box = inputdlg(prompt,'Enter Subject Info', 1, defAns);       % build the GUI
p.date_time_start = datetime('now'); % record time and date of the start of the sesssion !!

if length(box) == length(defAns)                            % check to make sure something was typed in
    p.subNum = str2num(box{1});
    p.uniqueID = str2num(box{2});
    p.counterbalance = str2num(box{3});
    p.age = str2num(box{4});
    p.gender = str2num(box{5});
    p.handedness = box{6};
else
    return;                                                 % if nothing was entered or the subject hit cancel, bail out
end

% Set the random seed
rng default
rng shuffle
p.rndSeed = rng;
%-------------------------------------------------------------------------
% Important options for all experiments
%-------------------------------------------------------------------------
p.is_PC = ispc;  % ispc function detects if it's a pc computer or not
p.windowed = 1; % 1 = small win for easy debugging!
p.startClick = 1; % in the discrete WR report experiment -- click to start trial if 1.
p.showInstruct = 0; % show instructions in the change detection task

%-------------------------------------------------------------------------
% Build an output directory & check to make sure it doesn't already exist
%-------------------------------------------------------------------------
p.root = pwd;
% if the subject data directory doesn't exist, make one!!
if ~exist([p.root,filesep,'Subject Data',filesep], 'dir')
    mkdir([p.root,filesep,'Subject Data',filesep]);
end
%-------------------------------------------------------------------------
% Build psychtoolbox window & hide the task bar
%-------------------------------------------------------------------------
win = openWindow(p);
%Manually hide the task bar so it doesn't pop up because of flipping
%the PTB screen during GetMouse:
if p.is_PC
    ShowHideWinTaskbarMex(0);
end

%% - CB: afc and wrt; previous exps showed no difference in color vs obj CB
%- and if this does, then run more participants for CB of 4 (2x2) 
%% counterbalance all 4 

if p.counterbalance==1
    %-------------------------------------------------------------------------
    % Generate participant unique stimuli for objects 
    stimObjs
   % ------------------------------------------------------------------------
    %Run
    ColAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColAFC_Blocked(p,win)
    % -----------------------------------------------------------------------
    %Run
    ObjAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjAFC_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColWRT_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Blocked(p,win)
    %-------------------------------------------------------------------------
elseif p.counterbalance==2
    %-------------------------------------------------------------------------
    % Generate participant unique stimuli for objects 
    stimObjs
    %-------------------------------------------------------------------------
    %Run
    ColWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColWRT_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColAFC_Blocked(p,win)
    % -----------------------------------------------------------------------
    %Run
    ObjAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjAFC_Blocked(p,win)
    %-------------------------------------------------------------------------
elseif p.counterbalance==3
    %-------------------------------------------------------------------------
    % Generate participant unique stimuli for objects 
    stimObjs
    %-------------------------------------------------------------------------
    %Run
    ObjAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjAFC_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColAFC_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Blocked(p,win)
    % -----------------------------------------------------------------------
    %Run
    ColWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColWRT_Blocked(p,win)
    %-------------------------------------------------------------------------
elseif p.counterbalance==4
    %-------------------------------------------------------------------------
    % Generate participant unique stimuli for objects 
    stimObjs
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjWRT_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColWRT_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColWRT_Blocked(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ObjAFC_Blocked(p,win)
    % -----------------------------------------------------------------------
    %Run
    ColAFC_Practice(p,win)
    %-------------------------------------------------------------------------
    %Run
    ColAFC_Blocked(p,win)
    %-------------------------------------------------------------------------

end

%-------------------------------------------------------------------------
% Close psychtoolbox window & Postpare the environment
%-------------------------------------------------------------------------
sca;
ListenChar(0);
if p.is_PC
    ShowHideWinTaskbarMex(1);
end
close all;
clear all;


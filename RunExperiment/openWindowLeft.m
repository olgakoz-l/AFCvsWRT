function win = openWindow(p) % open up the window! 

%PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
%Screen('Preference', 'SyncTestSettings',[0.002], [50], [0.1], [5])

if ~ispc % On mac's, it won't open a psychtoolbox window if it can't detect the refresh rate!!! Skip sync tests to avoid this.
    Screen('Preference','SkipSyncTests',1);
end

%   p.windowed = 0; %%% 1  == smaller screen for debugging; 0 === full-sized screen for experiment
if p.windowed
    win.screenNumber = min(Screen('Screens'));
    %win.screenNumber = min(Screen('Screen'));

    [win.onScreen, ~] = Screen('OpenWindow', win.screenNumber, [255 255 255],[0 0 1024 768],[],[],[]);
    win.screenX = 1024;
    win.screenY = 768;
    win.screenRect = [0 0 1024 768];
    win.centerX = (1024)/2; % center of screen in X direction
    win.centerY = (768)/2; % center of screen in Y direction
    win.centerXL = floor(mean([0 win.centerX])); % center of left half of screen in X direction
    win.centerXR = floor(mean([win.centerX win.screenX])); % center of right half of screen in X direction
    % % Compute foreground and fixation rectangles
    margin = 0.05;
    win.foreRect = round([0, 0, ...
        win.screenX * (1 - margin), ...
        win.screenY * (1 - margin)]);
    win.foreRect = CenterRect(win.foreRect, win.screenRect);
else
    win.screenNumber = min(Screen('Screens'));
    %win.screenNumber = max(Screen('Screen'));
    
    % Standard open screen
    [win.onScreen, rect] = Screen('OpenWindow', win.screenNumber, [255 255 255],[0 0 2560 1440],[],[],[]);
    [win.screenX, win.screenY] = Screen('WindowSize', win.onScreen); % check resolution
    win.screenRect  = [0 0 win.screenX win.screenY]; % screen rect
    win.centerX = win.screenX * 0.5; % center of screen in X direction
    win.centerY = win.screenY * 0.5; % center of screen in Y direction
    win.centerXL = floor(mean([0 win.centerX])); % center of left half of screen in X direction
    win.centerXR = floor(mean([win.centerX win.screenX])); % center of right half of screen in X direction
    % % Compute foreground and fixation rectangles
    margin = 0.30; % 5% margin (smaller margin = larger display area) %%%%%%%% One of the variables needed to adjust size of stimuli 
    win.foreRect = round([0, 0, ...
        win.screenX * (1 - margin), ...
        win.screenY * (1 - margin)]); % used to be: round([0 0 700 700]); stimuli around central area
    win.foreRect = CenterRect(win.foreRect,win.screenRect);

    HideCursor; % hide the cursor since we're not debugging
end

Screen('BlendFunction', win.onScreen, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% basic drawing and screen variables
win.black    = BlackIndex(win.onScreen);
win.white    = WhiteIndex(win.onScreen);
win.gray     = mean([win.black win.white]);

win.backColor = win.white;
win.foreColor = win.white;

win.backColorWRT = win.white;
win.foreColorWRT = win.white;

%%% 9 colors mat
win.colors_9 = [255 0 0; ... % red
    0 255 0; ...% green
    0 0 255; ...% blue
    255 255 0; ... % yellow
    255 0 255; ... % magenta
    0 255 255; ... % cyan 
    %255 255 255; ... % white
    1 1 1; ... %black
    255 128 0; ...% orange! 
    120 120 120];% % grey

%%%% 7 colors mat
win.colors_7 = [255 0 0;... % red
    0 255 0;... %green
    0 0 255;... % blue
    255 255 0;... % yellow
    255 0 255; ... % magenta
    255 255 255;... % white
    0 0 0]; % black

win.fontsize = 24;

% make a dummy call to GetSecs to load the .dll before we need it
dummy = GetSecs; clear dummy;
end
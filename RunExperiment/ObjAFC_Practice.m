%% Blocked 2AFC with real world objects
% Programmed by Olga Kozlova Feb 2025; edited Aug 2026

% -----------------------------------------------------------------------
function ObjAFC_Practice(p, win)

%-------------------------------------------------------------------------
% Build an output directory & check to make sure it doesn't already exist
%-------------------------------------------------------------------------
p.root = pwd;
fileName = [p.root,filesep,'Subject Data',filesep,num2str(p.subNum), '_ObjAFC_prac.mat'];
if p.subNum ~= 0
    if exist(fileName)
        Screen('CloseAll');
        msgbox('File already exists!', 'modal')
        return;
    end
end
%-------------------------------------------------------------------------

% Set up stuff for escape loop
while KbCheck; end
KbName('UnifyKeyNames');   % This command switches keyboard mappings to the OSX naming scheme, regardless of computer.
escape = KbName('ESCAPE');  % Mac == 'ESCAPE' % PC == 'esc'

%----------------------------------------------------
% Get screen params, build the display and load images
%----------------------------------------------------
commandwindow; % select the command win to avoid typing in open scripts
HideCursor;

prefs = getPreferences();  % function that grabs all of our preferences

% set up fixation point rect (b/c uses both prefs and win)
win.fixRect = [(win.centerX - prefs.fixationSize),(win.centerY - prefs.fixationSize), ...
    (win.centerX  + prefs.fixationSize), (win.centerY + prefs.fixationSize)];

% load images from stimObjs.m 

load('stimulusAssignments.mat','AFCpracObjs');

wmObjects = AFCpracObjs(1:12);% WM array objects 
novelObjects = AFCpracObjs(13:14); % novel objects at test

%%% create a vector of which objects for which trial numbers?
wmObjects = reshape(wmObjects, prefs.setSizes,prefs.numTrials,prefs.numBlocks); % essentially divides the WM Object photos into sets for each trial, so that we can call on a set rather than individual items
novelObjects =reshape(novelObjects, 1, prefs.numTrials,prefs.numBlocks); % same as above but for the novel photos used at test (i.e., our "lures")

%--------------------------------------------------------
% Preallocate some variable structures! :)
%--------------------------------------------------------

% Stimulus parameters:
data.setSize = NaN(prefs.numTrials,prefs.numBlocks);

data.trialAcc = NaN(prefs.numTrials,prefs.numBlocks); % aggregate trial acc

data.trialRT = NaN(prefs.numTrials,prefs.numBlocks); % full trial RT (from when placeholders/ test first appear to end of test phase)

data.confidence = NaN(prefs.numTrials,prefs.numBlocks);

data.wmObjects = cell(max(prefs.setSizes),prefs.numTrials,prefs.numBlocks);

data.novelObjects = cell(prefs.numTrials,prefs.numBlocks);

% 2AFC specific data
data.testedLocation = NaN(prefs.numTrials,prefs.numBlocks); %which location was probed

data.lureCorrect = NaN(prefs.numTrials,prefs.numBlocks); % 1 if selected old, 0 if selected new

data.lureRT = NaN(prefs.numTrials,prefs.numBlocks); %RT for 2AFC response

data.selectedObject2AFC = NaN(prefs.numTrials, prefs.numBlocks);

%--------------------------------------------------------
% Build new/ old object indices
%--------------------------------------------------------

data.wmObjects = wmObjects;

data.novelObjects = novelObjects;

% Track high score
data.highScore = NaN(prefs.numBlocks,1);

%  Put up instructions
instruct(win)

%---------------------------------------------------
% Begin Block loop
%---------------------------------------------------

for b = 1:prefs.numBlocks
    %%%% pick out the order of trials for this block, based on
    %%%% full Factorial Design
    ListenChar(2);
    data.setSize(:,b) = prefs.setSizes;

    t2 = 0; %2afc new lure count

    %-------------------------------------------------------
    % Begin Trial Loop
    %-------------------------------------------------------
    for t = 1:prefs.numTrials
        %--------------------------------------------------------
        % Figure out the conditions for this  trial!
        %--------------------------------------------------------
        nItems = data.setSize(t,b);

        currWMObjects = wmObjects(:, t, b);

        wmobjectImage = [];

        %---------------------------------------------------
        % FIXATION
        %---------------------------------------------------
        HideCursor;
        Screen('FillRect', win.onScreen, win.foreColor, win.foreRect);
        Screen('FillOval', win.onScreen, win.black, win.fixRect);
        Screen('Flip', win.onScreen);
        WaitSecs(prefs.fixationDuration);

        % calculate the object locations for this trial!
        [xPos,yPos] = randomArrayRects([0, 0, prefs.stimSize, prefs.stimSize], nItems, win, prefs);
        data.itemLocs{t,b} = [xPos;yPos];

        rect = [0, 0, prefs.stimSize, prefs.stimSize];
        coor = [xPos' yPos']; % set up nItems x 2 matrix of center coordinates
        rects = [coor(:, 1)-rect(3)/2 , coor(:, 2)-rect(3)/2, coor(:, 1)+rect(3)/2, coor(:, 2)+rect(3)/2]; %translate into rects based on stimSize (rect)
        rects = rects';

        % calculate the images needed for the trial (6 unique WM array)

        for imgLoadwmObjects = 1:length(currWMObjects)
            img = imread(fullfile('OBJECTSALL/', currWMObjects{imgLoadwmObjects}));
            wmobjectImage(imgLoadwmObjects) = Screen('MakeTexture', win.onScreen, img); % prepare images/ load textures
        end

        %---------------------------------------------------
        % MEMORY ARRAY
        %---------------------------------------------------
        Screen('FillRect', win.onScreen, win.foreColor, win.foreRect);
        Screen('FillOval', win.onScreen, win.black, win.fixRect);
        for array = 1:nItems
            Screen('DrawTexture', win.onScreen, wmobjectImage(array), [], rects(:,array));
        end
        Screen('Flip', win.onScreen);
        WaitSecs(prefs.stimulusDuration);

        %---------------------------------------------------
        % RETENTION
        %---------------------------------------------------
        Screen('FillRect', win.onScreen, win.foreColor, win.foreRect);
        Screen('FillOval', win.onScreen, win.black, win.fixRect);
        Screen('Flip', win.onScreen);
        WaitSecs(prefs.retentionInterval);

        %------------------------------------------------------------------
        % Begin response loop for all the items!!
        %------------------------------------------------------------------

        % select which location to test
        testLocation = randi(nItems);
        targetIndex = currWMObjects(testLocation);

        %afc count
        t2 = t2+1;

        currNovelObjects = novelObjects(:, t2, b);

        AFCtest = [targetIndex,currNovelObjects];
        testIMGS =[];
        for imgLure = 1:2
            img = imread(fullfile('OBJECTSALL/', AFCtest{imgLure}));
            testIMGS(imgLure) = Screen('MakeTexture', win.onScreen, img); % prepare images/ load textures
        end

        % Show placeholders (black circles) in used locations
        placeholderRects = rects;
        Screen('FillOval', win.onScreen, win.black, win.fixRect);

        for placeH = 1:nItems
            Screen('FrameOval', win.onScreen, win.black, placeholderRects(:,placeH), 4); % keep showing placeholders
        end
        Screen('Flip', win.onScreen);
        WaitSecs(prefs.showPlaceholders);

        % Record which location was tested
        data.testedLocation(t,b) = testLocation;

        % Show placeholder for the test location only
        % Screen('FillOval', win.onScreen, win.black, win.fixRect);
        % Screen('FrameOval', win.onScreen, win.black, rects(:,testLocation), 4);
        % Screen('Flip', win.onScreen);
        % WaitSecs(prefs.showTest);

        SetMouse(win.centerX, win.centerY);
        ShowCursor('Arrow', win.onScreen);
        %
        [x, y, buttons] = GetMouse(win.onScreen);

        trialRTStart = GetSecs;

        % Show 2AFC options
        objDistance = 200;

        option1X = win.centerX - objDistance;
        option2X = win.centerX + objDistance;
        optionY = win.centerY;

        option1Rect = [option1X-60, optionY-60, option1X+60, optionY+60];
        option2Rect = [option2X-60, optionY-60, option2X+60, optionY+60];

        % Randomly assign target to left or right
        if rand > 0.5
            leftImage = 1;%AFCtest(1);%targetIndex;
            rightImage = 2;%AFCtest(2);%currNovelObjects;
            targetLeft = true;
        else
            leftImage = 2;% AFCtest(2);%currNovelObjects;
            rightImage = 1;%AFCtest(1);%targetIndex;
            targetLeft = false;
        end

        Screen('DrawTexture', win.onScreen, testIMGS(leftImage), [], option1Rect);
        Screen('DrawTexture', win.onScreen, testIMGS(rightImage), [], option2Rect);
        Screen('Flip', win.onScreen);

        % Response phase
        responseMade = false;
        selectedObject = []; % Store which object was selected (target or lure)

        while ~responseMade
            [x, y, buttons] = GetMouse(win.onScreen);

            if any(buttons)
                if IsInRect(x, y, option1Rect) % Clicked LEFT option
                    data.lureRT(t,b) = GetSecs - trialRTStart;
                    clickLocAFC = 1;
                    if targetLeft % target on the left
                        data.lureCorrect(t,b) = 1; % correct target identification
                        selectedObject = 1;%targetIndex;
                    else % target on right (so left is lure)
                        data.lureCorrect(t,b) = 0; % incorrect
                        selectedObject = 2;%currNovelObjects;
                    end
                    responseMade = true;
                elseif IsInRect(x, y, option2Rect) % Clicked RIGHT option
                    data.lureRT(t,b) = GetSecs - trialRTStart;
                    clickLocAFC = 2;
                    if ~targetLeft % target on the right
                        data.lureCorrect(t,b) = 1; % correct target identification
                        selectedObject = 1;%targetIndex;
                    else % target on left (so right is lure)
                        data.lureCorrect(t,b) = 0; % incorrect
                        selectedObject = 2;%currNovelObjects;
                    end
                    responseMade = true;
                end
            end

            [~, ~, keyCode] = KbCheck;
            if keyCode(escape)
                ListenChar(0);
                save(fileName,'data','prefs','p','win');
                Screen('CloseAll');
                return;
            end
        end

        % selected obj: 
        if clickLocAFC==1%% left click, 
            objRect = option1Rect;

        elseif clickLocAFC==2 % right click
            objRect = option2Rect;

        end 


        % Show selected object
        Screen('DrawTexture', win.onScreen, testIMGS(selectedObject), [], objRect);
        Screen('Flip', win.onScreen);

        % confidence
        validKeyPressed = 0;
        while validKeyPressed == 0

            Screen('DrawTexture', win.onScreen, testIMGS(selectedObject), [], objRect);
            Screen('Flip', win.onScreen);

            [~, keyCode, ~] = KbWait([], 2);
            if keyCode(KbName('z')) % 100% not confident
                data.confidence(t, b) = 4; % only one response, so put in 1st dim
                validKeyPressed = 1;
            elseif keyCode(KbName('x')) % Kind of unconfident
                data.confidence(t, b) = 3;
                validKeyPressed = 1;
            elseif keyCode(KbName('c')) % Kind of confident
                data.confidence(t, b) = 2;
                validKeyPressed = 1;
            elseif keyCode(KbName('v')) % 100% confident
                data.confidence(t, b) = 1;
                validKeyPressed = 1;
            elseif keyCode(escape)
                ListenChar(0);
                save(fileName,'data','prefs','p','win');
                Screen('CloseAll');
                return;
            end
        end

       % WaitSecs(0.2);

        [~, ~, keyCode] = KbCheck;
        if keyCode(escape)
            ListenChar(0);
            save(fileName,'data','prefs','p','win');
            Screen('CloseAll');
            return;
        end

        data.trialRT(t,b) = GetSecs - trialRTStart;
        data.trialAcc(t,b) = data.lureCorrect(t,b);

        % Store which object was selected
        data.selectedObject2AFC(t,b) = selectedObject;

        HideCursor;


        % %---------------------------------------------------
        % % FEEDBACK
        % %---------------------------------------------------


        currentScore = data.lureCorrect(t,b);

        if currentScore==1
            text1 = sprintf('Correct!');
            text2 = sprintf('');
        else
            text1 = sprintf('Incorrect');
            text2 = sprintf('');
        end

        % Display feedback text
        Screen('FillRect', win.onScreen, win.foreColor, win.foreRect);
        Screen('TextSize',win.onScreen,50);
        Screen('TextFont',win.onScreen,'Arial');

        DrawFormattedText(win.onScreen, text1, win.centerX-100, win.centerY-50, win.black);
        DrawFormattedText(win.onScreen, text2, win.centerX-100, win.centerY+20, win.black);
        Screen('Flip', win.onScreen);
        WaitSecs(prefs.FBDuration)


        vKey = 0;
        % Loop until 1 second has passed or a trial click occurs
        while vKey==0
            if GetClicks(win.onScreen) % Check for mouse click
                vKey = 1;
                break; % Exit the loop if a trial click occurs
            end
            % Continue waiting for the trial click or 1 second duration
            WaitSecs(0.01); % Wait for a short duration to avoid high CPU usage
        end

        %--------------------------------------------------------------
        % escape loop!! if the esc key is pressed during the ITI save
        % everything. No lost data yay.
        %--------------------------------------------------------------
        Screen('FillRect', win.onScreen, win.foreColor, win.foreRect);
        Screen('FillOval', win.onScreen, win.black, win.fixRect);
        Screen('Flip', win.onScreen);
        tic
        while toc < prefs.ITI
            [~, ~, keyCode] = KbCheck;
            if keyCode(escape)
                ListenChar(0);
                save(fileName,'data','prefs','p','win');
                Screen('CloseAll');
                return;
            end
        end


    end % end trial loop

    % block information
    if b<prefs.numBlocks
        %%% SAVE EACH BLOCK %%%%%%%
        blockScore = round((nansum(data.lureCorrect(:,b))/prefs.nTrials)*100);
        data.highScore(b,1) = blockScore;
        save(fileName,'data','prefs','p');

        %%% WAIT BREAK LENGTH %%%%%%%
        Screen('TextSize',win.onScreen,50);
        Screen('TextFont',win.onScreen,'Arial');

        tic
        while toc < prefs.breakLength*60
            tocInd = round(toc);
            text3 = sprintf('Block Score: %d %%', data.highScore(b,1));
            Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
            %Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
            Screen(win.onScreen, 'DrawText', text3, win.centerX-160, win.centerY-40, [1 1 1]);
            Screen(win.onScreen, 'DrawText', 'Take a break.', win.centerX-190, win.centerY+60, [255 0 0]);
            Screen(win.onScreen, 'DrawText',['Time Remaining: ',char(num2str((prefs.breakLength*60)-tocInd))], win.centerX-190, win.centerY+140, [255 0 0 ]);
            Screen(win.onScreen, 'DrawText', ['Block ',num2str(b),' of ',num2str(prefs.numBlocks),' completed.'], win.centerX-190, win.centerY-100, [1 1 1]);
            Screen('Flip', win.onScreen);
        end

    end

    if b == prefs.numBlocks
        %%% SAVE EACH BLOCK %%%%%%%
        blockScore = round((nansum(data.lureCorrect(:,b))/prefs.nTrials)*100);
        data.highScore(b,1) = blockScore;

        Screen('TextSize',win.onScreen,60);
        Screen('TextFont',win.onScreen,'Arial');
        Screen(win.onScreen, 'DrawText', 'Finished practice!', win.centerX-200, win.centerY-10, [1 1 1]);

        text3 = sprintf('Highest Score: %d %%', max(data.highScore));
        Screen(win.onScreen, 'DrawText', text3, win.centerX-200, win.centerY+80, [1 1 1]);

        Screen('Flip', win.onScreen);
        GetClicks(win.onScreen);

        ListenChar(0);

    end

end % end block loop

%%%% SAVE again, just in case!
save(fileName,'data','prefs','p');

end % end experiment main loop function

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%  Functions embedded elsewhere in the script.
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function instruct(win)
InstructImage = imread([pwd, '/ObjAFC'], 'png', 'BackgroundColor', [win.white / 255, win.white / 255, win.white / 255]);

% Resize the image to 1000 × 400
desiredWidth = 600;
desiredHeight = 400;
InstructImage = imresize(InstructImage, [desiredHeight, desiredWidth]);

textOffset = 300;
textSize = 20;

sizeInstruct = size(InstructImage);
rectInstruct = [0 0 sizeInstruct(2) sizeInstruct(1)];
rectTestCoor = [win.centerX, win.centerY - (sizeInstruct(1) * 0.4)];

InstructText = ['Remember the objects at their locations!\n\n'...
    '   - One location will be tested\n'...
    '   - Choose the correct object!\n'...
    '   - Then rate your confidence (z/x/c/v keys)\n\n'...
    'Click the mouse to begin'];

% Show image again, but with explanatory text
Screen('FillRect', win.onScreen, win.white);
Screen('TextSize', win.onScreen, textSize); % 24 = number pixels
DrawFormattedText(win.onScreen, InstructText, 'center', win.centerY + (sizeInstruct(1) * 0.2), win.black);

Screen('PutImage', win.onScreen, InstructImage, CenterRectOnPoint(rectInstruct, rectTestCoor(1), rectTestCoor(2)));

Screen('Flip', win.onScreen);
GetClicks(win.onScreen);
end



%-------------------------------------------------------------------------

% Grabs the locations anywhere within the designated stimulus rect!
% function rects = randomArrayRects(rect, nItems, win, prefs)
function [xPos,yPos] = randomArrayRects(rect,nItems,win,prefs)
% segment the inner win into four quadrants - for xCoords, 1st
% row = positions in left half of display, 2nd row = right half.
% For yCoords - 1st row = top half, 2nd row = bottom half
xCoords = [linspace((win.foreRect(1)+prefs.stimSize/2),win.centerX-prefs.stimSize/2,300); linspace(win.centerX+prefs.stimSize/2,(win.foreRect(3)-prefs.stimSize/2),300)];
yCoords = [linspace((win.foreRect(2)+prefs.stimSize/2),win.centerY-prefs.stimSize/2,300); linspace(win.centerY+prefs.stimSize/2,(win.foreRect(4)-prefs.stimSize/2),300)];
xLocInd = randperm(size(xCoords,2)); yLocInd = randperm(size(yCoords,2));

% Pick x,y coords for drawing stimuli on this trial, making sure
% that all stimuli are seperated by >= prefs.minDist
if nItems ==1
    xPos = [xCoords(randi(2),xLocInd(1))];  % pick randomly from first and second x rows (L/R halves)
    yPos = [yCoords(randi(2),yLocInd(1))];  % pick randomly from first and second y rows (Top/Bottom).
elseif nItems ==2 % always bilateral without randomPosition
    %     randomPosition = randi(2);
    %     if randomPosition == 1
    xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2))]; % pick one left and one right item
    yPos = [yCoords(randi(2),yLocInd(1)),yCoords(randi(2),yLocInd(2))]; % pick randomly, top or bottom
    %     else
    %         xPos = [xCoords(randi(2),xLocInd(1)),xCoords(randi(2),xLocInd(2))]; % pick randomly, left or right!
    %         yPos = [yCoords(1,yLocInd(1)),yCoords(2,yLocInd(2))]; % pick one top, one bottom!
    %     end
elseif nItems ==3
    xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4))]; % one L one R
    yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4))]; % one top one bottom for e/ L/R
    % let's use the same scheme as 4 items, but randomly leave one
    % out!
    randomOrder = randperm(4);
    xPos = xPos(randomOrder(1:3));
    yPos = yPos(randomOrder(1:3));
elseif nItems ==4
    xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4))]; % one L one R
    yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4))]; % one top one bottom for e/ L/R
elseif nItems ==5
    randomPosition = randi(2); % pick one of two quadrants to stick the second item
    while 1
        if randomPosition == 1
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(1,xLocInd(5))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt(abs(xPos(1)-xPos(5))^2+abs(yPos(1)-yPos(5))^2)>prefs.minDist
                %             if sqrt((xPos(2)-xPos(6))^2+(yPos(2)-yPos(6))^2)>prefs.minDist
                break;
            end
        elseif randomPosition == 2
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(2,xLocInd(5))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt((xPos(2)-xPos(5))^2+(yPos(2)-yPos(5))^2)>prefs.minDist
                break;
            end
        end
    end
elseif nItems ==6
    randomPosition = randi(6); % put extra squares in top or bottom half;
    while 1
        if randomPosition == 1 % both in top
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(1,xLocInd(5)),xCoords(2,xLocInd(6))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5)),yCoords(1,yLocInd(6))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt(abs(xPos(1)-xPos(5))^2+abs(yPos(1)-yPos(5))^2)>prefs.minDist % both in left top
                if sqrt((xPos(2)-xPos(6))^2+(yPos(2)-yPos(6))^2)>prefs.minDist % both in right top
                    break;
                end
            end
        elseif randomPosition == 2 % both in bottom
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(1,xLocInd(5)),xCoords(2,xLocInd(6))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(2,yLocInd(5)),yCoords(2,yLocInd(6))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt(abs(xPos(3)-xPos(5))^2+abs(yPos(3)-yPos(5))^2)>prefs.minDist % both  in left bottom
                if sqrt((xPos(4)-xPos(6))^2+(yPos(4)-yPos(6))^2)>prefs.minDist   % both in right bottom
                    break;
                end
            end
        elseif randomPosition == 3 %both left
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(1,xLocInd(5)),xCoords(1,xLocInd(6))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5)),yCoords(2,yLocInd(6))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt(abs(xPos(1)-xPos(5))^2+abs(yPos(1)-yPos(5))^2)>prefs.minDist % both in left top
                if sqrt((xPos(3)-xPos(6))^2+(yPos(3)-yPos(6))^2)>prefs.minDist % both in left bottom
                    break;
                end
            end
        elseif randomPosition == 4 % both right
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(2,xLocInd(5)),xCoords(2,xLocInd(6))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5)),yCoords(2,yLocInd(6))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt(abs(xPos(2)-xPos(5))^2+abs(yPos(2)-yPos(5))^2)>prefs.minDist % both in right top
                if sqrt((xPos(4)-xPos(6))^2+(yPos(4)-yPos(6))^2)>prefs.minDist   % both in right bottom
                    break;
                end
            end
        elseif randomPosition == 5 % left up right down
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(1,xLocInd(5)),xCoords(2,xLocInd(6))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5)),yCoords(2,yLocInd(6))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt(abs(xPos(1)-xPos(5))^2+abs(yPos(1)-yPos(5))^2)>prefs.minDist % both in left top
                if sqrt((xPos(4)-xPos(6))^2+(yPos(4)-yPos(6))^2)>prefs.minDist  % both  in right bottom
                    break;
                end
            end
        elseif randomPosition == 6 %  right up left down
            xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
            xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(2,xLocInd(5)),xCoords(1,xLocInd(6))];
            yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5)),yCoords(2,yLocInd(6))];
            % make sure that w/in quadrant points satisfy the minimum
            % distance requirement
            if sqrt(abs(xPos(2)-xPos(5))^2+abs(yPos(2)-yPos(5))^2)>prefs.minDist % both in right top
                if sqrt((xPos(3)-xPos(6))^2+(yPos(3)-yPos(6))^2)>prefs.minDist  % both in left bottom
                    break;
                end
            end


        end
    end
elseif nItems == 8
    while 1
        xLocInd = Shuffle(xLocInd); yLocInd = Shuffle(yLocInd);
        xPos = [xCoords(1,xLocInd(1)),xCoords(2,xLocInd(2)),xCoords(1,xLocInd(3)),xCoords(2,xLocInd(4)),xCoords(1,xLocInd(5)),xCoords(2,xLocInd(6)),xCoords(1,xLocInd(7)),xCoords(2,xLocInd(8))];
        yPos = [yCoords(1,yLocInd(1)),yCoords(1,yLocInd(2)),yCoords(2,yLocInd(3)),yCoords(2,yLocInd(4)),yCoords(1,yLocInd(5)),yCoords(1,yLocInd(6)),yCoords(2,yLocInd(7)),yCoords(2,yLocInd(8))];
        % make sure that w/in quadrant points satisfy the minimum
        % distance requirement
        if sqrt(abs(xPos(1)-xPos(5))^2+abs(yPos(1)-yPos(5))^2)>prefs.minDist
            if sqrt((xPos(2)-xPos(6))^2+(yPos(2)-yPos(6))^2)>prefs.minDist
                if sqrt((xPos(3)-xPos(7))^2+(yPos(3)-yPos(7))^2)>prefs.minDist
                    if sqrt((xPos(4)-xPos(8))^2+(yPos(4)-yPos(8))^2)>prefs.minDist
                        break;
                    end
                end
            end
        end
    end
end
end

%-------------------------------------------------------------------------
%  CHANGE PREFERENCES!
%-------------------------------------------------------------------------
function prefs = getPreferences
%%%% Design conditions
prefs.numBlocks = 1; %1;
prefs.setSizes = 6;
prefs.nTrials = 2; %2 total trials

%%%%% timing
prefs.fixationDuration = .500;
prefs.stimulusDuration = 1.000;
prefs.retentionInterval = 1.000;
prefs.showPlaceholders = 0.800;
prefs.showTest = 0.500;
prefs.ITI = 1.000;
prefs.FBDuration = .500;
prefs.breakLength = .5;

%%%%% stimulus size & positions
prefs.stimSize = 180; % size of stimulus images (must be divisible by 6)
prefs.minDist = prefs.stimSize*1.5; % minimum distance between stimuli
prefs.fixationSize = 8;

%%%%% randomize trial order of full factorial design order
prefs.fullFactorialDesign = fullfact([length(prefs.setSizes), prefs.nTrials]);

%%%%% total number of trials in each fully-crossed block
prefs.numTrials = size(prefs.fullFactorialDesign, 1);
end
%% Blocked 2AFC
% Programmed by Olga Kozlova Feb 2025; edited Nov 2026

% -----------------------------------------------------------------------
function ColAFC_Practice(p, win)

%-------------------------------------------------------------------------
% Build an output directory & check to make sure it doesn't already exist
%-------------------------------------------------------------------------
p.root = pwd;
fileName = [p.root,filesep,'Subject Data',filesep,num2str(p.subNum), '_ColAFC_prac.mat'];
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
% Get screen params, build the display
%----------------------------------------------------
commandwindow; % select the command win to avoid typing in open scripts
HideCursor;

prefs = getPreferences();  % function that grabs all of our preferences

% set up fixation point rect (b/c uses both prefs and win)
win.fixRect = [(win.centerX - prefs.fixationSize),(win.centerY - prefs.fixationSize), ...
    (win.centerX  + prefs.fixationSize), (win.centerY + prefs.fixationSize)];

% load up response pad matix!
SquareResponsePadFunction(prefs);
load SquarePad.mat
responseMatrix = SquarePad.ResponsePad;
ResponsePadTexture = Screen('MakeTexture',win.onScreen,responseMatrix);

%--------------------------------------------------------
% Preallocate some variable structures! :)
%--------------------------------------------------------
% Stimulus parameters:
data.setSize = NaN(prefs.numTrials,prefs.numBlocks);

% Response params
data.testedLocation = NaN(prefs.numTrials,prefs.numBlocks); %which location was probed
data.lureCorrect = NaN(prefs.numTrials,prefs.numBlocks); % 1 if selected old, 0 if selected new
data.lureRT = NaN(prefs.numTrials,prefs.numBlocks); %RT for 2AFC response
data.selectedObject2AFC = NaN(prefs.numTrials, prefs.numBlocks);

data.trialAcc = NaN(prefs.numTrials,prefs.numBlocks);
data.rt = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks);

data.confidence = NaN(prefs.numTrials,prefs.numBlocks);

data.correctColor = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks); % contains correct color for all items (1 to nItems)

% Track high score
data.highScore = NaN(prefs.numBlocks,1);
%  Put up instructions
instruct(win)

%---------------------------------------------------
% Begin Block loop
%---------------------------------------------------
for b = 1:prefs.numBlocks

    ListenChar(2);
    data.setSize(:,b) = prefs.setSizes;

    %-------------------------------------------------------
    % Begin Trial Loop
    %-------------------------------------------------------
    for t = 1:prefs.numTrials
        %--------------------------------------------------------
        % Figure out the conditions for this  trial!
        %--------------------------------------------------------
        nItems = data.setSize(t,b);
        %trialType = data.trialType(t,b);
        HideCursor;

        % calculate the stimulus locations for this trial!
        [xPos,yPos] = randomArrayRects([0, 0, prefs.stimSize, prefs.stimSize], nItems, win, prefs);

        data.itemLocs{t,b} = [xPos;yPos];

        rect = [0, 0, prefs.stimSize, prefs.stimSize];
        coor = [xPos' yPos']; % set up nItemx X 2 matrix of center coordinates
        rects = [coor(:, 1)-rect(3)/2 , coor(:, 2)-rect(3)/2, coor(:, 1)+rect(3)/2, coor(:, 2)+rect(3)/2]; %translate into rects based on stimSize (rect)

        rects = rects';
        RECTS = rects;

        % calculate colors for the trial
        colorIndex = randperm(size(win.colors_9,1));
        data.correctColor(t,1:nItems,b) = colorIndex(1:nItems); % save colorindex order for this trial...

        colorsToDisplay = win.colors_9(colorIndex,:); % grab which colors to display from win.colors.
        colorsToDisplay = colorsToDisplay(1:nItems,:);
        colorsNotOnDisplay = colorIndex(nItems+1:end);
        afcColor = Shuffle(colorsNotOnDisplay); afcColor =afcColor(1);
        afcTestColor = win.colors_9(afcColor,:);

        data.colorList = win.colors_9;

        % Fixation period
        fixationDuration = prefs.fixationDuration;
        Screen('FillRect', win.onScreen, win.foreColorWRT, win.foreRect);
        Screen('FillOval', win.onScreen, win.black, win.fixRect);
        Screen('Flip', win.onScreen);
        WaitSecs(fixationDuration);


        % Draw squares on the main win
        Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
        Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
        Screen('FillRect',win.onScreen,colorsToDisplay',RECTS);
        Screen('DrawingFinished',win.onScreen);
        Screen('Flip',win.onScreen);


        % Wait the sample duration, then wipe the screen

        WaitSecs(prefs.stimulusDuration); % stimulus Dur + retention,

        Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
        Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
        Screen('DrawingFinished',win.onScreen);
        Screen('Flip',win.onScreen);

        % wait the ISI
        WaitSecs(prefs.retentionInterval);

        % select which location to test
        testLocation = randi(nItems);
        targetIndex = colorIndex(testLocation);
        targetColor = win.colors_9(targetIndex,:);

        testColors = [targetColor;afcTestColor];

        %------------------------------------------------------------------
            % Present colored masks
            %------------------------------------------------------------------
            Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
            Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
            Screen('DrawTextures',win.onScreen,ResponsePadTexture,[],RECTS,[],[],[]);
            Screen('DrawingFinished',win.onScreen);
            Screen('Flip',win.onScreen);
            WaitSecs(prefs.showPlaceholders);

            data.testedLocation(t,b) = testLocation;

            % Put test location in the middle of the screen 

            SetMouse(win.centerX, win.centerY);
            ShowCursor('Arrow', win.onScreen);

                [x, y, buttons] = GetMouse(win.onScreen);

                    locationClicked = true;
                    trialRTStart = GetSecs;
                    % Show 2AFC options
                    objDistance = 100; %200

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

                    Screen('FillRect',win.onScreen,testColors(leftImage,:), option1Rect);
                    Screen('FillRect', win.onScreen, testColors(rightImage,:), option2Rect);
                    Screen('DrawingFinished',win.onScreen);
                    Screen('Flip',win.onScreen);

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

                    
                    Screen('FillRect',win.onScreen,testColors(selectedObject,:),objRect);
                    Screen('Flip', win.onScreen);

                    % confidence
                    validKeyPressed = 0;
                    while validKeyPressed == 0

                        Screen('FillRect',win.onScreen,testColors(selectedObject,:),objRect);
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

                    WaitSecs(0.2);
 

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
        Screen('FillRect', win.onScreen, win.foreColorWRT, win.foreRect);
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
        Screen('FillRect', win.onScreen, win.foreColorWRT, win.foreRect);
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


    end % end trial loop index

    % block information
    if b<prefs.numBlocks
        blockScore = round((nansum(data.lureCorrect(:,b))/prefs.nTrialsPerCondition)*100);
        data.highScore(b,1) = blockScore;
        %%%% SAVE EACH BLOCK %%%%%%%
        save(fileName,'data','prefs','p');
        %%%% WAIT BREAK LENGTH %%%%%%%
        Screen('TextSize',win.onScreen,50);
        Screen('TextFont',win.onScreen,'Arial');

        tic
        while toc < prefs.breakLength*60
            tocInd = round(toc);
            text3 = sprintf('Block Score: %d %%', data.highScore(b,1));
            Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
            %Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
            Screen(win.onScreen, 'DrawText', text3, win.centerX-160, win.centerY-40, [1 1 1]);
            Screen(win.onScreen, 'DrawText', 'Take a break.', win.centerX-190, win.centerY+80, [255 0 0]);
            Screen(win.onScreen, 'DrawText',['Time Remaining: ',char(num2str((prefs.breakLength*60)-tocInd))], win.centerX-190, win.centerY+120, [255 0 0 ]);
            Screen(win.onScreen, 'DrawText', ['Block ',num2str(b),' of ',num2str(prefs.numBlocks),' completed.'], win.centerX-190, win.centerY-75, [1 1 1]);
            Screen('Flip', win.onScreen);
        end
    end

    if b == prefs.numBlocks
        %%%% SAVE EACH BLOCK %%%%%%%
        save(fileName,'data','prefs','p');
        blockScore = round((nansum(data.lureCorrect(:,b))/prefs.nTrialsPerCondition)*100);
        data.highScore(b,1) = blockScore;

        Screen('TextSize',win.onScreen,60);
        Screen('TextFont',win.onScreen,'Arial');
        Screen(win.onScreen, 'DrawText', 'Finished practice!', win.centerX-200, win.centerY-10, [1 1 1]);

        text3 = sprintf('Highest Score: %d %%', max(data.highScore));
        Screen(win.onScreen, 'DrawText', text3, win.centerX-200, win.centerY+80, [1 1 1]);

        Screen('Flip', win.onScreen);
        GetClicks(win.onScreen);
        %Screen('CloseAll');
        ListenChar(0);

    end
end % end block loop

%%%% SAVE again, just in case!
save(fileName,'data','prefs','p');
%         postpareEnvironment(p); % clear stuff
end % end experiment main loop function


%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%  Functions embedded elsewhere in the script.
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function instruct(win)
InstructImage = imread([pwd, '/ColAFC'], 'png', 'BackgroundColor', [win.white / 255, win.white / 255, win.white / 255]);

% Resize the image to 1000 × 400
desiredWidth = 600;
desiredHeight = 400;
InstructImage = imresize(InstructImage, [desiredHeight, desiredWidth]);


textOffset = 300;
textSize = 20;

sizeInstruct = size(InstructImage);
rectInstruct = [0 0 sizeInstruct(2) sizeInstruct(1)];
rectTestCoor = [win.centerX, win.centerY - (sizeInstruct(1) * 0.4)];


InstructText = ['Remember the colors at their locations!\n\n'...
    '   - One location will be tested\n'...
    '   - Choose the correct color!\n'...
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
xCoords = [linspace((win.foreRect(1)+prefs.stimSize),win.centerX-prefs.stimSize,300); linspace(win.centerX+prefs.stimSize,(win.foreRect(3)-prefs.stimSize),300)];
yCoords = [linspace((win.foreRect(2)+prefs.stimSize),win.centerY-prefs.stimSize,300); linspace(win.centerY+prefs.stimSize,(win.foreRect(4)-prefs.stimSize),300)];
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

%   coor = [xPos' yPos']; % set up nItemx X 2 matrix of center coordinates
%   rects = [coor(:, 1)-rect(3)/2 , coor(:, 2)-rect(3)/2, coor(:, 1)+rect(3)/2, coor(:, 2)+rect(3)/2]; %translate into rects based on stimSize (rect)

end

%-------------------------------------------------------------------------
function col = determineColorChosen(x,y,centerPoint,prefs) % determine color and accuracy

sixstimsize = prefs.stimSize / 6;
halfstimsize = prefs.stimSize / 2;

if (centerPoint(1)+sixstimsize) < x...
        && x < (centerPoint(1)+halfstimsize)...
        && (centerPoint(2)+sixstimsize) < y...
        && y < (centerPoint(2)+halfstimsize)
    col = 5; % lower left; magenta;
elseif (centerPoint(1)+sixstimsize) < x...
        && x < (centerPoint(1)+halfstimsize)...
        && (centerPoint(2)-halfstimsize) < y...
        && y < (centerPoint(2)-sixstimsize)
    col = 3; % upper left; blue;
elseif (centerPoint(1)-sixstimsize) < x...
        && x < (centerPoint(1)+sixstimsize) ...
        && (centerPoint(2)+sixstimsize) < y ...
        && y < (centerPoint(2)+halfstimsize)
    col = 6; % middle bottom, cyan;
elseif (centerPoint(1)-sixstimsize) < x...
        && x < (centerPoint(1)+sixstimsize) ...
        && (centerPoint(2)-halfstimsize) < y...
        && y < (centerPoint(2)-sixstimsize)
    col = 2; % middle top; green;
elseif (centerPoint(1)-halfstimsize) < x...
        && x < (centerPoint(1)-sixstimsize) ...
        && (centerPoint(2)+sixstimsize) < y ...
        && y < (centerPoint(2)+halfstimsize)
    col = 7; % lower left; white;
elseif (centerPoint(1)-halfstimsize) < x...
        && x < (centerPoint(1)-sixstimsize) ...
        && (centerPoint(2)-halfstimsize) < y...
        && y < (centerPoint(2)-sixstimsize)
    col = 1; % upper left; red;
elseif (centerPoint(1)-halfstimsize) < x...
        && x < (centerPoint(1)-sixstimsize) ...
        && (centerPoint(2)-sixstimsize) < y...
        && y < (centerPoint(2)+sixstimsize)
    col = 8; % middle left; black;
elseif (centerPoint(1)+sixstimsize) < x...
        && x < (centerPoint(1)+halfstimsize)...
        && (centerPoint(2)-sixstimsize)<y...
        && y < (centerPoint(2)+sixstimsize)
    col = 4; % middle right; yellow;
elseif (centerPoint(1)-sixstimsize) < x...
        && x < (centerPoint(1)+sixstimsize) ...
        && (centerPoint(2)-sixstimsize) < y ...
        && y < (centerPoint(2)+sixstimsize)
    col = 9; % middle middle; orange;
else
    col = 0; % just in case they accidentally click the line!!
end
end

%-------------------------------------------------------------------------
%  CHANGE PREFERENCES!
%-------------------------------------------------------------------------
function prefs = getPreferences
%%%% Design conditions
prefs.numBlocks = 1; %1;
prefs.nTrialsPerCondition = 2; % 2;
prefs.setSizes = 6;

%%%%% timing
prefs.fixationDuration = .500;
prefs.retentionInterval =  1.000;
prefs.stimulusDuration = 1.000;
prefs.showPlaceholders = 0.800;
prefs.showTest = 0.500;
prefs.ITI = 1.000;
prefs.FBDuration = .500;
prefs.breakLength = .5; %.5 number of minutes for block

%%%%% stimulus size & positions
prefs.stimSize = 90; % must be divisible by 6!!!
prefs.minDist = prefs.stimSize*1.5;
prefs.fixationSize = 8;

%%%%% randomize trial order of full factorial design order
prefs.fullFactorialDesign = fullfact([length(prefs.setSizes), ...
    length(prefs.retentionInterval), ...
    prefs.nTrialsPerCondition]);

%%%%% total number of trials in each fully-crossed block.
prefs.numTrials = size(prefs.fullFactorialDesign,1);
end
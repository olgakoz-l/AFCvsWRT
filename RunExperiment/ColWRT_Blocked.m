%% Blocked WRT 
% Programmed by Olga Kozlova Feb 2025; edited Aug 2026

% -----------------------------------------------------------------------
function ColWRT_Blocked(p, win)

%-------------------------------------------------------------------------
% Build an output directory & check to make sure it doesn't already exist
%-------------------------------------------------------------------------
p.root = pwd;
fileName = [p.root,filesep,'Subject Data',filesep,num2str(p.subNum), '_ColWRT.mat'];
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
%data.trialType = NaN(prefs.numTrials,prefs.numBlocks); % 1 = whole-report, 2 = 2AFC
data.testedLocation = NaN(prefs.numTrials,prefs.numBlocks); %which location was probed
data.lureCorrect = NaN(prefs.numTrials,prefs.numBlocks); % 1 if selected old, 0 if selected new
data.lureRT = NaN(prefs.numTrials,prefs.numBlocks); %RT for 2AFC response
data.selectedObject2AFC = NaN(prefs.numTrials, prefs.numBlocks);

data.acc = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks);
data.trialAcc = NaN(prefs.numTrials,prefs.numBlocks);
data.rt = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks);

data.confidence = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks);

data.itemChosen = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks); % order of item chosen
data.correctColor = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks); % contains correct color for all items (1 to nItems)
data.responseColor = NaN(prefs.numTrials,max(prefs.setSizes),prefs.numBlocks); % contains response color (in order of data.itemChosen)

% Track high score
data.highScore = zeros(prefs.numTrials,prefs.numBlocks);
%  Put up instructions
instruct(win)

%---------------------------------------------------
% Begin Block loop
%---------------------------------------------------
for b = 1:prefs.numBlocks

    ListenChar(2);
    data.setSize(:,b) = prefs.setSizes;
    %trialTypeList = [ones(1, prefs.numTrials/2), 2*ones(1, prefs.numTrials/2)];
    %data.trialType(:,b) = trialTypeList(randperm(prefs.numTrials));


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

        % send trial and block codes
        %if p.portCodes  % send some block and trial codes
        %  write_parallel(event_port,b+200);

        %  WaitSecs(.1);

        %  write_parallel(event_port,t+100);
        % end

        % Draw squares on the main win
        Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
        Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
        Screen('FillRect',win.onScreen,colorsToDisplay',RECTS);
        Screen('DrawingFinished',win.onScreen);
        Screen('Flip',win.onScreen);

        %   if p.portCodes % items appear port Code
        %     write_parallel(event_port,40+nItems);
        %  end

        % Wait the sample duration, then wipe the screen
        %         Screen('WaitBlanking',win.onScreen,prefs.stimulusDuration);
        WaitSecs(prefs.stimulusDuration); % stimulus Dur + retention,

        Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
        Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
        Screen('DrawingFinished',win.onScreen);
        Screen('Flip',win.onScreen);

        % wait the ISI
        %         Screen('WaitBlanking',win.onScreen,prefs.retentionInterval); % this   method uses frame rate instead ...
        WaitSecs(prefs.retentionInterval);


        %if trialType == 1 % WRT
            %------------------------------------------------------------------
            % Present colored masks
            %------------------------------------------------------------------
            Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
            Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
            Screen('DrawTextures',win.onScreen,ResponsePadTexture,[],RECTS,[],[],[]);
            Screen('DrawingFinished',win.onScreen);
            Screen('Flip',win.onScreen);

            %  if p.portCodes % end of retention, test square shown!!
            %    write_parallel(event_port,98);
            % end

            %------------------------------------------------------------------
            % Begin response loop for all the items!!
            %------------------------------------------------------------------
            startRT1 = GetSecs;

            % wait for click
            SetMouse(win.centerX, win.centerY);
            [x,y,buttons] = GetMouse(win.onScreen);
            ShowCursor('Arrow',win.onScreen);

            % index for which ones should be drawn as desaturated (clicked)
            % versus regular colors
            clickedInd = zeros(1,nItems);

            clickIndex = 1;

            while clickIndex < nItems+1 % changing to 2 from 1
                % Keep showing the masks.
                Screen('FillRect', win.onScreen, win.foreColorWRT, win.foreRect);
                Screen('FillOval', win.onScreen, win.black, win.fixRect);

                % Draw the response pad (not showing reported colors)
                % if ~isempty(RECTS(:, clickedInd == 0))
                %     Screen('DrawTextures', win.onScreen, ResponsePadTexture, [], RECTS(:, clickedInd == 0), [], [], []);
                % end
                % if ~isempty(RECTS(:, clickedInd == 1))
                %     Screen('DrawTextures', win.onScreen, win.colors_9(j), [], RECTS(:, clickedInd == 1), [], [], []);
                % end

                % Draw the response pad (shows reported color after)

                for colorDraw = 1:nItems
                    if clickedInd(colorDraw) == 0
                        Screen('DrawTextures', win.onScreen, ResponsePadTexture, [], RECTS(:, colorDraw));
                    else
                        responseOrder = find(data.itemChosen(t,:,b)==colorDraw,1);
                        chosenColor = data.responseColor(t,responseOrder,b);
                        if chosenColor ==0 %%%%%%%%% piloting
                            chosenColor = 1;
                        end
                        Screen('FillRect',win.onScreen,win.colors_9(chosenColor,:)',RECTS(:, colorDraw));
                    end
                end

                Screen('Flip', win.onScreen);

                % Wait for mouse click
                [x, y, buttons] = GetMouse(win.onScreen);


                if any(buttons)
                    for j = 1:nItems
                        if rects(1, j) <= x && x <= rects(3, j) && rects(2, j) <= y && y <= rects(4, j)
                            endRT1 = GetSecs;

                            clickedInd(j) = 1;

                            % Determine the chosen color and accuracy
                            [centerPoint(1), centerPoint(2)] = RectCenter(RECTS(:, j)); % b/c j = itemchosen!
                            col = determineColorChosen(x, y, centerPoint, prefs); % determine color and accuracy

                            data.responseColor(t, clickIndex, b) = col;
                            data.itemChosen(t, clickIndex, b) = j;

                            % Keep showing the masks.
                            Screen('FillRect', win.onScreen, win.foreColorWRT, win.foreRect);
                            Screen('FillOval', win.onScreen, win.black, win.fixRect);

                            % Draw the response pad (and reported colors)
                            for colorDraw = 1:nItems
                                if clickedInd(colorDraw) == 0
                                    Screen('DrawTextures', win.onScreen, ResponsePadTexture, [], RECTS(:, colorDraw));
                                else
                                    responseOrder = find(data.itemChosen(t,:,b)==colorDraw,1);
                                    chosenColor = data.responseColor(t,responseOrder,b);
                                    if chosenColor ==0 %%%%%%%%% piloting
                                        chosenColor = 1;
                                    end
                                    Screen('FillRect',win.onScreen,win.colors_9(chosenColor,:)',RECTS(:, colorDraw));
                                end
                            end


                            % % Draw the response pad (without reported colors)
                            % if ~isempty(RECTS(:, clickedInd == 0))
                            %     Screen('DrawTextures', win.onScreen, ResponsePadTexture, [], RECTS(:, clickedInd == 0), [], [], []);
                            % end
                            % if ~isempty(RECTS(:, clickedInd == 1))
                            %     Screen('DrawTextures', win.onScreen, win.colors_9(j), [], RECTS(:, clickedInd == 1), [], [], []);
                            % end

                            Screen('Flip', win.onScreen)


                            % Save confidence measures
                            validKeyPressed = 0;
                            while validKeyPressed == 0
                                [~, keyCode, ~] = KbWait([], 2);
                                if keyCode(KbName('z')) % 100% not confident
                                    confidence = 4;
                                    validKeyPressed = 1;
                                elseif keyCode(KbName('x')) % %50 not confident confidence
                                    confidence = 3;
                                    validKeyPressed = 1;
                                elseif keyCode(KbName('c')) % 50% confident
                                    confidence = 2;
                                    validKeyPressed = 1;
                                elseif keyCode(KbName('v')) % 100% high confidence
                                    confidence = 1;
                                    validKeyPressed = 1;
                                end
                            end

                            % Save data
                            if ~ismember(j, data.itemChosen(t, 1:clickIndex-1, b)) % should let me click the same color more than once
                                %~ismember(j, data.itemChosen(t, 1:nItems, b)) % make sure they haven't picked this item yet!!

                                data.rt(t, clickIndex, b) = endRT1 - startRT1;
                                % data.itemChosen(t, clickIndex, b) = j;
                                data.confidence(t, clickIndex, b) = confidence; % Save confidence measure

                                % % Determine the chosen color and accuracy
                                % [centerPoint(1), centerPoint(2)] = RectCenter(RECTS(:, j)); % b/c j = itemchosen!
                                % col = determineColorChosen(x, y, centerPoint, prefs); % determine color and accuracy

                                % data.responseColor(t, clickIndex, b) = col;
                                if data.responseColor(t, clickIndex, b) == data.correctColor(t, j, b) % see if it's the same as the order chosen...
                                    data.acc(t, clickIndex, b) = 1;
                                else
                                    data.acc(t, clickIndex, b) = 0;
                                end

                                clickIndex = clickIndex + 1;
                                break; % Exit the loop after processing the click
                            else
                                % Do nothing if the same item is chosen again
                            end

                        end
                    end
                end
            end %end while click
            HideCursor;

            % Save aggregate accuracy for the trial
            trialAcc = nansum(data.acc(t, :, b), 2);
            data.trialAcc(t, b) = trialAcc;

        % else %2AFC TRIAL!!!!
        %     % select which location to test
        %     testLocation = randi(nItems);
        %     targetIndex = colorIndex(testLocation);
        %     targetColor = win.colors_9(targetIndex,:);
        %     %lure is afcTestColor = win.colors_9(afcColor,:);
        % 
        %     testColors = [targetColor;afcTestColor];
        % 
        %     %------------------------------------------------------------------
        %     % Present colored masks
        %     %------------------------------------------------------------------
        %     Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);            % Draw the foreground win
        %     Screen('FillOval',win.onScreen,win.black,win.fixRect);           % Draw the fixation point
        %     Screen('DrawTextures',win.onScreen,ResponsePadTexture,[],RECTS,[],[],[]);
        %     Screen('DrawingFinished',win.onScreen);
        %     Screen('Flip',win.onScreen);
        %     WaitSecs(prefs.showPlaceholders);
        % 
        %     data.testedLocation(t,b) = testLocation;
        % 
        %     %show placeholder only at test loc
        %     Screen('FillRect',win.onScreen,win.foreColorWRT,win.foreRect);
        %     Screen('FillOval', win.onScreen, win.foreColorWRT, win.fixRect);
        %     Screen('FrameRect', win.onScreen, win.black, rects(:,testLocation), 4);
        %     Screen('Flip', win.onScreen);
        %     WaitSecs(prefs.showTest);
        % 
        %     SetMouse(win.centerX, win.centerY);
        %     ShowCursor('Arrow', win.onScreen);
        %    % locationClicked = false;
        % 
        %    %while ~locationClicked
        % 
        %         [x, y, buttons] = GetMouse(win.onScreen);
        % 
        % 
        %     %    if any(buttons) && IsInRect(x, y, rects(:,testLocation))
        %             locationClicked = true;
        %             trialRTStart = GetSecs;
        %             % Show 2AFC options
        %             objDistance = 100; %200
        % 
        %             option1X = xPos(testLocation) - objDistance;
        %             option2X = xPos(testLocation) + objDistance;
        %             optionY = yPos(testLocation);
        % 
        %             option1Rect = [option1X-60, optionY-60, option1X+60, optionY+60];
        %             option2Rect = [option2X-60, optionY-60, option2X+60, optionY+60];
        % 
        %             % Randomly assign target to left or right
        %             if rand > 0.5
        %                 leftImage = 1;%AFCtest(1);%targetIndex;
        %                 rightImage = 2;%AFCtest(2);%currNovelObjects;
        %                 targetLeft = true;
        %             else
        %                 leftImage = 2;% AFCtest(2);%currNovelObjects;
        %                 rightImage = 1;%AFCtest(1);%targetIndex;
        %                 targetLeft = false;
        %             end
        %             %Screen('FillRect',win.onScreen,colorsToDisplay',RECTS);
        %             Screen('FillRect',win.onScreen,testColors(leftImage,:), option1Rect);
        %             Screen('FillRect', win.onScreen, testColors(rightImage,:), option2Rect);
        %             Screen('DrawingFinished',win.onScreen);
        %             Screen('Flip',win.onScreen);
        % 
        %             % Response phase
        %             responseMade = false;
        %             selectedObject = []; % Store which object was selected (target or lure)
        % 
        %             while ~responseMade
        %                 [x, y, buttons] = GetMouse(win.onScreen);
        % 
        %                 if any(buttons)
        %                     if IsInRect(x, y, option1Rect) % Clicked LEFT option
        %                         data.lureRT(t,b) = GetSecs - trialRTStart;
        %                         if targetLeft % target on the left
        %                             data.lureCorrect(t,b) = 1; % correct target identification
        %                             selectedObject = 1;%targetIndex;
        %                         else % target on right (so left is lure)
        %                             data.lureCorrect(t,b) = 0; % incorrect
        %                             selectedObject = 2;%currNovelObjects;
        %                         end
        %                         responseMade = true;
        %                     elseif IsInRect(x, y, option2Rect) % Clicked RIGHT option
        %                         data.lureRT(t,b) = GetSecs - trialRTStart;
        %                         if ~targetLeft % target on the right
        %                             data.lureCorrect(t,b) = 1; % correct target identification
        %                             selectedObject = 1;%targetIndex;
        %                         else % target on left (so right is lure)
        %                             data.lureCorrect(t,b) = 0; % incorrect
        %                             selectedObject = 2;%currNovelObjects;
        %                         end
        %                         responseMade = true;
        %                     end
        %                 end
        % 
        %                 [~, ~, keyCode] = KbCheck;
        %                 if keyCode(escape)
        %                     ListenChar(0);
        %                     save(fileName,'data','prefs','p','win');
        %                     Screen('CloseAll');
        %                     return;
        %                 end
        %             end
        % 
        %             % Show selected object
        %             Screen('FillRect',win.onScreen,testColors(selectedObject,:),RECTS(:, testLocation));
        %             Screen('Flip', win.onScreen);
        % 
        %             % confidence
        %             validKeyPressed = 0;
        %             while validKeyPressed == 0
        % 
        %                 Screen('FillRect',win.onScreen,testColors(selectedObject,:),RECTS(:, testLocation));
        %                 Screen('Flip', win.onScreen);
        % 
        %                 [~, keyCode, ~] = KbWait([], 2);
        %                 if keyCode(KbName('z')) % 100% not confident
        %                     data.confidence(t, 1, b) = 4; % only one response, so put in 1st dim
        %                     validKeyPressed = 1;
        %                 elseif keyCode(KbName('x')) % Kind of unconfident
        %                     data.confidence(t, 1, b) = 3;
        %                     validKeyPressed = 1;
        %                 elseif keyCode(KbName('c')) % Kind of confident
        %                     data.confidence(t, 1, b) = 2;
        %                     validKeyPressed = 1;
        %                 elseif keyCode(KbName('v')) % 100% confident
        %                     data.confidence(t, 1, b) = 1;
        %                     validKeyPressed = 1;
        %                 elseif keyCode(escape)
        %                     ListenChar(0);
        %                     save(fileName,'data','prefs','p','win');
        %                     Screen('CloseAll');
        %                     return;
        %                 end
        %             end
        % 
        %             WaitSecs(0.2);
        %      %   end
        % 
        %         [~, ~, keyCode] = KbCheck;
        %         if keyCode(escape)
        %             ListenChar(0);
        %             save(fileName,'data','prefs','p','win');
        %             Screen('CloseAll');
        %             return;
        %         end
        %    % end
        % 
        %     data.trialRT(t,b) = GetSecs - trialRTStart;
        %     data.trialAcc(t,b) = data.lureCorrect(t,b);
        % 
        %     % Store which object was selected
        %     data.selectedObject2AFC(t,b) = selectedObject;
        % end

        HideCursor;


        % %---------------------------------------------------
        % % FEEDBACK
        % %---------------------------------------------------

        % if trialType == 1
            currentScore = nansum(data.acc(t, :, b), 2);
        % else
        %     currentScore = data.lureCorrect(t,b);
        % end

        % Update high score
        % if trialType == 1
            if currentScore > data.highScore
                data.highScore = currentScore;
                newHighScore = true;
            else
                newHighScore = false;
            end
        % end

        % if trialType == 1
            text1 = sprintf('%d Correct!', currentScore);
            if newHighScore
                text2 = sprintf('NEW HIGH SCORE!! %d', data.highScore);
            else
                text2 = sprintf('High Score: %d', data.highScore);
            end
        % else
        %     if currentScore==1
        %         text1 = sprintf('Correct!');
        %         text2 = sprintf('');
        %     else
        %         text1 = sprintf('Incorrect');
        %         text2 = sprintf('');
        %     end
        % end

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
        %%%% SAVE EACH BLOCK %%%%%%%
        
        save(fileName,'data','prefs','p');
        %%%% WAIT BREAK LENGTH %%%%%%%
        Screen('TextSize',win.onScreen,50);
        Screen('TextFont',win.onScreen,'Arial');

        tic
        while toc < prefs.breakLength*60
            tocInd = round(toc);
            text3 = sprintf('Highest Score: %d', data.highScore);
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
        %%%% SAVE EACH BLOCK %%%%%%%
        save(fileName,'data','prefs','p');

        Screen('TextSize',win.onScreen,60);
        Screen('TextFont',win.onScreen,'Arial');
        Screen(win.onScreen, 'DrawText', 'Finished! Please Ring Doorbell.', win.centerX-200, win.centerY-10, [1 1 1]);

        text3 = sprintf('Highest Score: %d', max(data.highScore));
        Screen(win.onScreen, 'DrawText', text3, win.centerX-75, win.centerY+50, [255 255 255]);

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
InstructImage = imread([pwd, '/ColWRT'], 'png', 'BackgroundColor', [win.white / 255, win.white / 255, win.white / 255]);

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
    '   - Click on a location and select the color you remember there\n'...
    '   - Then rate your confidence for the color (z/x/c/v keys)\n\n'...
    '   - Repeat until all 6 colors are filled out!\n\n'...
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
prefs.numBlocks = 4; %4;
prefs.nTrialsPerCondition = 27; % 27;
prefs.setSizes = 6;

%%%%% timing
prefs.fixationDuration = .500;
prefs.retentionInterval =  1.000;
prefs.stimulusDuration = 1.000;
prefs.showPlaceholders = 0.800;
prefs.showTest = 0.500;
prefs.ITI = 1.000;
prefs.FBDuration = .500;
prefs.breakLength = .1; % .5 number of minutes for block

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
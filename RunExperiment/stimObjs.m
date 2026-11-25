%% creating object image matrices so that there's no overlap in 2afc and WRT 
function stimObjs

objectImageDir = dir("OBJECTSALL/*.jpg");
objectImageDir = {objectImageDir.name}';
nTotal = length(objectImageDir);

% How many stimuli needed for each task?
% 108 trials per task x set size 6 = 648 

% 648 for WRT
% 756 = 648 + 108 novel objects for 2AFC 
% 2 practice trials/ task:
% 12 WRT prac 
% 14 objs for 2AFC prac 

% total = 1430/ 2400 unique object data set 
nWRTprac = 12;
nWRT = 648;
nAFCprac = 14;
nAFC = 648;
nAFCnovel = 108;

totalNeeded = nWRTprac + nWRT + nAFCprac + nAFC + nAFCnovel;

%select all stimuli
randOrder = randperm(nTotal);
allSelected = randOrder(1:totalNeeded);

WRTpracObjs = objectImageDir(allSelected(1:nWRTprac)); % 1 - 12
WRTObjs = objectImageDir(allSelected(nWRTprac+1:nWRTprac+nWRT)); % 13 : 660 
AFCpracObjs = objectImageDir(allSelected(nWRTprac+nWRT+1:nWRTprac+nWRT+nAFCprac)); %661 - 674
AFCObjs = objectImageDir(allSelected(nWRTprac+nWRT+nAFCprac+1:nWRTprac+nWRT+nAFCprac+nAFC)); % 675 - 1322 
AFCnovels = objectImageDir(allSelected(nWRTprac+nWRT+nAFCprac+nAFC+1:end));% 1323 - 1430 

% Save to a single file
save('stimulusAssignments.mat', 'WRTpracObjs', 'WRTObjs', 'AFCpracObjs', 'AFCObjs', 'AFCnovels');

end 
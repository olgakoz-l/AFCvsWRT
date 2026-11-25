function SquareResponsePadFunction(prefs)

%This file attempts to create bunch of spatial gratings

%First create the structure
SquarePad = struct();

%Define the parameters
SquarePad.radius = [prefs.stimSize]; %in pixels
SquarePad.miniSquare=(SquarePad.radius*2)/3;% overal we want a 3 by 3 array.

SquarePad.cycles = 2; %per 120 pixels
SquarePad.colors = [255 0 0; ... % red
    0 255 0; ...% green
    0 0 255; ...% blue
    255 255 0; ... % yellow
    255 0 255; ... % magenta
    0 255 255; ... % cyan 
   % 255 255 255; ... % white
    1 1 1; ... %black
    255 128 0; ... % orange! 
    120 120 120];% % grey
SquarePad.background=120;
SquarePad.CrossSize = 2;

%%
%First make the color pad
SquareMat=zeros(length(SquarePad.colors),SquarePad.radius*2,SquarePad.radius*2,3);%num colors, by width, by height, by RGB matrix
squaresize=SquarePad.miniSquare;
%%
SquareMat(1,1:squaresize, 1:squaresize, 1)=1;%Square at 1st loc=red

SquareMat(2, 1:squaresize,squaresize:squaresize*2, 2)=1;%Square at 2nd loc=green

SquareMat(3, 1:squaresize,squaresize*2:squaresize*3, 3)=1;%Square at 3rd loc=blue

SquareMat(4, squaresize:squaresize*2,squaresize*2:squaresize*3, 1) = 1;%Square 4th loc=yellow (red part of the rgb)
SquareMat(4, squaresize:squaresize*2,squaresize*2:squaresize*3, 2) = 1;%Square 4th loc=yellow (green part of the rgb)

SquareMat(5, squaresize*2:squaresize*3,squaresize*2:squaresize*3, 1)=1;%Square at 5th loc=magenta
SquareMat(5, squaresize*2:squaresize*3,squaresize*2:squaresize*3, 3)=1;%Square at 5th loc=magenta

SquareMat(6, squaresize*2:squaresize*3,squaresize:squaresize*2, 2)=1;%Square at 6th loc=cyan
SquareMat(6, squaresize*2:squaresize*3,squaresize:squaresize*2, 3)=1;%Square at 6th loc=cyan

SquareMat(7, squaresize:squaresize*2, squaresize:squaresize*2, 1)=1;%Square at 7th loc=black
SquareMat(7, squaresize:squaresize*2, squaresize:squaresize*2, 2)=3;%Square at 7th loc=black

% SquareMat(7, squaresize*2:squaresize*3,1:squaresize, 1)=1;%Square at 7th loc=white
% SquareMat(7, squaresize*2:squaresize*3,1:squaresize, 2)=1;%Square at 7th loc=white
% SquareMat(7, squaresize*2:squaresize*3,1:squaresize, 3)=1;%Square at 7th loc=white

SquareMat(8,squaresize:squaresize*2,1:squaresize,  1)=1;%Square at 8th loc=orange
SquareMat(8, squaresize:squaresize*2,1:squaresize, 2)=3;%Square at 8th loc=orange
%SquareMat(8, squaresize:squaresize*2,1:squaresize, 3)=2;%Square at 8th loc=black

% %make the middle grey!!
SquareMat(9, squaresize:squaresize*2, squaresize:squaresize*2, 1)=SquarePad.background;
SquareMat(9, squaresize:squaresize*2, squaresize:squaresize*2, 2)=SquarePad.background;
SquareMat(9, squaresize:squaresize*2, squaresize:squaresize*2, 3)=SquarePad.background;

%make the middle orange!! [255 128 0]
% SquareMat(9, squaresize:squaresize*2, squaresize:squaresize*2, 1)=1;%Square at 8th loc=black
% SquareMat(9, squaresize:squaresize*2, squaresize:squaresize*2, 2)=3;%Square at 8th loc=black

%Then save it!!!!!!!
SquarePad.stim(:,:,:,:)=SquareMat;
%%

%now overlay!
SquarePad.ResponsePad(:,:,1)=squeeze(SquarePad.stim(1,:,:,1))+squeeze(SquarePad.stim(4,:,:,1))...
    +squeeze(SquarePad.stim(5,:,:,1))+squeeze(SquarePad.stim(7,:,:,1))+squeeze(SquarePad.stim(8,:,:,1))+squeeze(SquarePad.stim(9,:,:,1));

SquarePad.ResponsePad(:,:,2)=squeeze(SquarePad.stim(2,:,:,2))+squeeze(SquarePad.stim(4,:,:,2))...
    +squeeze(SquarePad.stim(6,:,:,2))+squeeze(SquarePad.stim(7,:,:,2))+squeeze(SquarePad.stim(8,:,:,2))+squeeze(SquarePad.stim(9,:,:,2));

SquarePad.ResponsePad(:,:,3)=squeeze(SquarePad.stim(3,:,:,3))+squeeze(SquarePad.stim(5,:,:,3))...
    +squeeze(SquarePad.stim(6,:,:,3))+squeeze(SquarePad.stim(7,:,:,3))+squeeze(SquarePad.stim(8,:,:,3))+squeeze(SquarePad.stim(9,:,:,3));

%%
RGB=3;
for i=1:1:RGB
    
    for w=1:1:SquarePad.radius*2
        for h = 1:1:SquarePad.radius*2
            if SquarePad.ResponsePad(w,h,i)==1
                
                SquarePad.ResponsePad(w,h,i)=255;
                
            elseif SquarePad.ResponsePad(w,h,i)==2 
                
                SquarePad.ResponsePad(w,h,i)=1;
                
            elseif SquarePad.ResponsePad(w,h,i) == 3
                
                SquarePad.ResponsePad(w,h,i) = 128; % for the orange response pad... 
                
            elseif SquarePad.ResponsePad(w,h,i)==SquarePad.background
                
                SquarePad.ResponsePad(w,h,i)=SquarePad.background;
               
            end
        end
    end
end

%%
%Now add  allllll of the crosshairs
for w = squaresize - SquarePad.CrossSize + 1 : 1 : squaresize + SquarePad.CrossSize-1
    for h = 1:1:squaresize*3
        SquarePad.ResponsePad(w,h,:) = SquarePad.background-20;
    end
end
for h =squaresize - SquarePad.CrossSize + 1 : 1 : squaresize + SquarePad.CrossSize-1
    for w = 1:1:squaresize*3
        SquarePad.ResponsePad(w,h,:) = SquarePad.background-20;
    end
end
for w = squaresize*2 - SquarePad.CrossSize + 1 : 1 : squaresize*2 + SquarePad.CrossSize-1
    for h = 1:1:squaresize*3
        SquarePad.ResponsePad(w,h,:) = SquarePad.background-20;
    end
end
for h =squaresize*2 - SquarePad.CrossSize + 1 : 1 : squaresize*2 + SquarePad.CrossSize-1
    for w = 1:1:squaresize*3
        SquarePad.ResponsePad(w,h,:) = SquarePad.background-20;
    end
end
%%
save('SquarePad.mat', 'SquarePad');
end
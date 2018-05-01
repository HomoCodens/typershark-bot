%Set up actxserver object for communication with the game
h = actxserver('WScript.Shell');
h.AppActivate('Typer Shark Deluxe 1.02');
pause(0.05);
h.SendKeys(' ');

%load character templates
load patterns; 

%set misc parameters
stdPause = 0.5;
nmoves = 300;

%for n moves
for i = 1:nmoves
    %Grab a screenshot of the game window (position hardcoded...)
    rect = [5, 540, 1980-77-900-362, 1050-400-168];
    scr = getscreen(rect);
    scr = scr.cdata;

    %work ocr magic
    [typetext, endgame] = parseboard(scr, templates);
    %if bottom reached flag true, break
    if(endgame)
        break;
    end
    
    %if pure green is present we are at the bottom -> type as fast as
    %possible
    bottomMode = ~isempty(find(scr(:, :, 2) == 255 & scr(:, :, 3) == 0, 1));
    if(bottomMode)
        pausedur = 0;
    else
        pausedur = stdPause;
    end

    %activate game window
    h.AppActivate('Typer Shark Deluxe 1.02');
    
    %generate array of words from space seperated output string of
    %parseboard
    words = regexp(typetext, ' ', 'split');
    
    %pause 0,05 seconds between words
    wordPause = 0.05;
    
    %output whole string of recognized words
    if(~isempty(find(typetext ~= ' ', 1)))
        fprintf('Sending text %s... nao\n', typetext);
    end
    
    %send individual words
    for i = 1:length(words)-1
        h.SendKeys(words{i});
        pause(wordPause);
    end
    
    %wait a little between iterations
    pause(pausedur);
end
% takes an rgb screenshot of the game view and a struct of letter templates
% outputs a space separated string of recognized words and a flag for end
% of game

function [string, endgame] = parseboard(scr, templates)

endgame = false;
string = '';
bottomMode = ~isempty(find(scr(:, :, 2) == 255 & scr(:, :, 3) == 0, 1));

%convert rgb screen to grayscale
grayscr = rgb2gray(scr);
left = 80;

%if at bottom use smaller area and text to extract is white
if bottomMode
    top = 280;
    bottom = 330;
    gthresh = 245;
    left = 180;
    right = 470;
    bwscr = grayscr > gthresh;
    bwscr = bwscr(top:bottom, left:right);
% else text is black
else
    gthresh = 25;
    top = 25;
    bottom = 440;
    bwscr = grayscr < gthresh;
    bwscr = bwscr(top:bottom, left:end);
end

% set threshold for area on the right where letters are ignored (possibly
% incomplete words) and show binary image that will be examined
rightThresh = 545;
imshow(bwscr);
hold on;
plot([rightThresh, rightThresh], [0, size(scr, 1)], 'r', 'LineWidth', 4);
hold off;

% use matlab regionprops function to extract image, area and position of
% chunks of white (letters)
patterns = regionprops(bwscr, 'Image', 'Area', 'BoundingBox');

%if at bottom and no more text, level is over
if(bottomMode && isempty(patterns))
    endgame = true;
    return;
end

% this portion groups letters by line and word
lines = {};
lineHeights = [];
horPos = [];
horDist = 20;
for i = 1:length(patterns)
    if(patterns(i).BoundingBox(4) >= 9)
        lidx = find(abs(lineHeights - patterns(i).BoundingBox(2)) < 5, 1);
        if(~isempty(lidx))
            lines{lidx}{end+1} = patterns(i);
        else
            lineHeights = [lineHeights; patterns(i).BoundingBox(2)];
            lines{end+1}{1} = patterns(i);
        end
    else
        %special treatment for lowercase s which is split in two by
        %regionprops
        sCandSize = size(patterns(i).Image);
        if(sCandSize(1) == 5 && sCandSize(2) == 8 && isequal(patterns(i).Image(1, 3:6), true(1, 4)))
            lidx = find(abs(lineHeights - patterns(i).BoundingBox(2)) < 5, 1);
            if(~isempty(lidx))
                lines{lidx}{end+1} = patterns(i);
            else
                lineHeights = [lineHeights; patterns(i).BoundingBox(2)];
                lines{end+1}{1} = patterns(i);
            end
        end
    end
end


% filter out (possibly) incomplete words
nlines = length(lines);
tlines = {};
widx = 1;
tword = {};
for i = 1:nlines
        if(i == 8)
        b = true;
    end
    nletters = length(lines{i});
    if(nletters > 1)
        tword = {lines{i}{1}.Image};
        for j = 2:nletters
            if(abs(lines{i}{j-1}.BoundingBox(1)+lines{i}{j-1}.BoundingBox(3) - lines{i}{j}.BoundingBox(1)) <= 15)
                tword{end+1} = lines{i}{j}.Image;
            else
                if(lines{i}{j-1}.BoundingBox(1)+lines{i}{j-1}.BoundingBox(3) <= rightThresh)
                    tlines{end+1} = tword;
                    tword = {lines{i}{j}.Image};
                end
            end
        end
        if(lines{i}{j}.BoundingBox(1)+lines{i}{j}.BoundingBox(3) <= rightThresh)
            tlines{end+1} = tword;
        end
    else
        if(lines{i}{1}.BoundingBox(1)+lines{i}{1}.BoundingBox(3) <= rightThresh)
            tlines{end+1} = {lines{i}{1}.Image};
        end
    end
end

lines = tlines;

nlines = length(lines);
string = [];
lidxs = [];
for i = 1:nlines
    nletters = length(lines{i});
    for j = 1:nletters
        letterHeight = size(lines{i}{j}, 1);
        if(letterHeight <= 10)
            %jellyusfish, does not work so well yet
            letterWidth = size(lines{i}{j}, 2);
            if(letterWidth > 5)
                corrs = zeros(length(templates), 1);
                if(size(lines{i}{j}, 1) > 5)
                    for k = 27:52 %1:length(templates)
                        % skip I and J for special treatment below
                        if(k == 9 || k == 10)
                            continue;
                        end
                        [m, n] = size(lines{i}{j});
                        [o, p] = size(templates{k});
                        pattern = lines{i}{j};
                        template = imresize(templates{k}, [m, n]);
                        corrs(k) = max(max(normxcorr2(template, pattern)));
                    end
                    [~, idx] = max(corrs);
                    lidxs = [lidxs idx];
                else
                    if(isequal(size(lines{i}{j}), [5, 8]))
                        lidxs = [lidxs 19];
                    end
                end
            else
                if(letterWidth <= 3)
                        lidxs = [lidxs 9];
                else
                    lidxs = [lidxs 10];
                end
            end
        elseif(letterHeight <= 24)
            letterWidth = size(lines{i}{j}, 2);
            if(letterWidth > 5  && letterWidth <= 15)
                corrs = zeros(length(templates), 1);
                for k = [1:26 53:56]%1:length(templates)
                    % skip I and J for special treatment below
                    if(k == 9 || k == 10)
                        continue;
                    end
                    [m, n] = size(lines{i}{j});
                    [o, p] = size(templates{k});
                    pattern = lines{i}{j};
                    template = imresize(templates{k}, [m, n]);
                    corrs(k) = max(max(normxcorr2(template, pattern)));
                end
                [~, idx] = max(corrs);
                lidxs = [lidxs idx];
            else
                if(letterWidth <= 3)
                    if(sum(lines{i}{j} == 0) <= 3)
                        lidxs = [lidxs 9];
                    else
                        if(lidxs(end) ~= 13)
                            lidxs = [lidxs 13];
                        end
                    end
                elseif(letterWidth <= 10)
                    lidxs = [lidxs 10];
                else
                    lidxs = [lidxs 3 20];
                end
            end
        else
            %bottom
            letterWidth = size(lines{i}{j}, 2);
            if(letterWidth > 7)
                corrs = zeros(length(templates), 1);
                for k = 57:82
                    % skip I and J for special treatment below
                    if(k == 65)
                        continue;
                    end
                    [m, n] = size(lines{i}{j});
                    [o, p] = size(templates{k});
                    if(isequal([o, p], [0 0]))
                        %not recorded yet
                        continue;
                    end
                    pattern = lines{i}{j};
                    template = imresize(templates{k}, [m, n]);
                    corrs(k) = max(max(normxcorr2(template, pattern)));
                end
                [~, idx] = max(corrs);
                lidxs = [lidxs idx];
            else
                if(letterWidth <= 3)
                    lidxs = [lidxs 65];
                end
            end
        end
    end
    lidxs = [lidxs 83];
end
letters = 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzijpwabcdefghijklmnopqrstuvwxyz ';
string = letters(lidxs);
%helper function to split a given screenshot into indivitual letters and
%insert them at the correct position of the letters template structure

function letters = helpcatalog(scr, letters)
bottomMode = ~isempty(find(scr(:, :, 2) == 255 & scr(:, :, 3) == 0, 1));

grayscr = rgb2gray(scr);
left = 80;
if bottomMode
    top = 280;
    bottom = 330;
    gthresh = 245;
    bwscr = grayscr > gthresh;
    bwscr = bwscr(top:bottom, left:end);
else
    gthresh = 25;
    top = 25;
    bottom = 440;
    bwscr = grayscr < gthresh;
    bwscr = bwscr(top:bottom, left:end);
end
imshow(bwscr);
figure;
patterns = regionprops(bwscr, 'Image', 'Area', 'BoundingBox');
if(nargin == 1)
    letters = cell(26, 1);
end

for i = 1:length(patterns)
    imshow(patterns(i).Image);
    id = input('Where to insert? (0 to skip)\n');
    if(id > 0 && id <= 26)
        letters{id} = patterns(i).Image;
    end
end
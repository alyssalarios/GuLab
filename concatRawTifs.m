% takes a folder with tiff movies as input and concatenates them from top
% to bottom in the third dimmension to make one large tiff movie. Deposits
% this concatenated tif in the same folder with '_cat' appended

%files will be concatenated in the order they are found in the file, so
%make sure that chronologically first movie is at top of file (matlab inverts this 
%order so look in computer's finder 

%% choose file and make list of tifs
fprintf('Select a folder containing tifs\n');
filename = uigetdir();

cd(filename);
tiflist = dir(fullfile(filename,'*.tif'));

% loop through list and append each element
catTif = [];

for i = 1:length(tiflist)
    fprintf('Loading %s\n',tiflist(i).name);
    movieChunk = loadtiff(tiflist(i).name);
    catTif = cat(3,catTif,movieChunk);
end

% save to datafolder
fprintf('saving concatenated file\n');
saveastiff(catTif, [tiflist(1).name(1:end-6),'_cat.tif']);

    
    
    
% Specify the folder containing the images
image_folder = 'C:\Users\seohy\Documents\EECS351\eecs351-sfm\Images';  % Replace with your folder path

% Check if the folder exists
if ~isfolder(image_folder)
    error('The specified folder does not exist.');
end

% Load all JPG images from the folder
image_files = dir(fullfile(image_folder, '*.jpg'));
if isempty(image_files)
    error('No JPG images found in the specified folder');
end

% Sort files by name to ensure correct order
[~, idx] = sort({image_files.name});
image_files = image_files(idx);

% Read the first image to initialize
img1 = imread(fullfile(image_folder, image_files(1).name));
gray1 = rgb2gray(img1);

figure; imshow(img1);

%objectRegion=[44, 33, 340, 360];

points1 = detectMinEigenFeatures(im2gray(img1), MinQuality=0.001);

pointImage = insertMarker(img1,points1.selectStrongest(500).Location,'+','MarkerColor','white');
figure;
imshow(pointImage);
title('Detected interest points');

tracker = vision.PointTracker('MaxBidirectionalError',1);

num_points = 500;
points1 = points1.selectStrongest(500).Location;
initialize(tracker,points1,gray1);

img2 = imread(fullfile(image_folder, image_files(2).name));
gray2 = rgb2gray(img2);
[points2,validity] = tracker(gray2);
out = insertMarker(img2,points2(validity, :),'+');
figure;
imshow(out);
title('Detected interest points');


num_frames = length(image_files);
measurement_matrix = NaN(2 * num_frames, num_points);
measurement_matrix(1:2, :) = points1';

%%
for i = 2:num_frames
    % Read the next image
    img = imread(fullfile(image_folder, image_files(i).name));
    gray = rgb2gray(img);
    
    % Track points
    [points, validity] = tracker(gray);
    out = insertMarker(img,points(validity, :),'+');
    figure;
    imshow(out);
    title('Detected interest points');

end


%%
[tform,inlierIdx] = estgeotform2d(points1,points2, "rigid");
inlier1 = points1(inlierIdx,:);
inlier2 = points2(inlierIdx,:);
figure;
showMatchedFeatures(img1, img2, inlier1, inlier2);
title("Matched Inlier Points")

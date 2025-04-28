function videoTo3DModelFromEnhanced()
    %% Parameters
    enhancedFramesDir = 'enhanced_frames';   % Folder of enhanced frames
    maxFrames = 165;                         % Max frames to process
    
    % Camera intrinsics (assumed parameters)
    focalLength = [1500, 1500];
    principalPoint = [640, 360];  
    imageSize = [720, 1280];
    intrinsics = cameraIntrinsics(focalLength, principalPoint, imageSize);
    
    %% Load enhanced frames
    if ~exist(enhancedFramesDir, 'dir')
        error('Enhanced frames folder does not exist: %s', enhancedFramesDir);
    end
    
    imageFiles = dir(fullfile(enhancedFramesDir, '*.jpg'));
    numFrames = min(maxFrames, length(imageFiles));
    
    images = cell(1, numFrames);
    points = cell(1, numFrames);
    features = cell(1, numFrames);
    
    disp('Loading enhanced frames and detecting SURF features...');
    for i = 1:numFrames
        imgPath = fullfile(enhancedFramesDir, imageFiles(i).name);
        images{i} = imread(imgPath);  
        
        points{i} = detectSURFFeatures(images{i});
        [features{i}, points{i}] = extractFeatures(images{i}, points{i});
        
        fprintf('Frame %d/%d: %d features\n', i, numFrames, length(points{i}));
    end
    
    %% Build viewSet and estimate poses
    disp('Building view set and estimating poses...');
    vSet = viewSet;
    vSet = addView(vSet, 1, 'Points', points{1}, 'Orientation', eye(3), 'Location', [0 0 0]);
    
    for i = 2:numFrames
        % Match features
        indexPairs = matchFeatures(features{i-1}, features{i}, 'Unique', true, 'MaxRatio', 0.8);
        matchedPoints1 = points{i-1}(indexPairs(:,1));
        matchedPoints2 = points{i}(indexPairs(:,2));
        
        if size(matchedPoints1, 1) >= 6
            [relOrient, relLoc, inlierIdx] = helperEstimateRelativePose(...
                matchedPoints1, matchedPoints2, intrinsics);
            
            vSet = addView(vSet, i, 'Points', points{i});
            vSet = addConnection(vSet, i-1, i, 'Matches', indexPairs(inlierIdx,:));
            
            prevPose = poses(vSet, i-1);
            %absOrient = prevPose.Orientation{1} * relOrient;
            absOrient = prevPose.Orientation{1};
            absOrient = absOrient* relOrient;
            absLoc = prevPose.Location{1} + relLoc * prevPose.Orientation{1};
            
            vSet = updateView(vSet, i, 'Orientation', absOrient, 'Location', absLoc);
        else
            warning('Frame %d skipped due to insufficient matches.', i);
        end
    end
    
    %% Triangulate points
    disp('Triangulating 3D points...');
    tracks = findTracks(vSet);
    camPoses = poses(vSet);
    
    [xyzPoints, reprojectionErrors] = triangulateMultiview(tracks, camPoses, intrinsics);
    goodPoints = reprojectionErrors < 5;
    xyzPoints = xyzPoints(goodPoints, :);
    
    %% Show and save 3D model
    if ~isempty(xyzPoints)
        ptCloud = pointCloud(xyzPoints);
        
        figure;
        pcshow(ptCloud, 'VerticalAxis', 'Y', 'VerticalAxisDir', 'Down', 'MarkerSize', 45);
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('3D Reconstruction from Enhanced Frames');
        grid on;
        
        pcwrite(ptCloud, 'reconstructed_model_enhanced.ply', 'PLYFormat', 'binary');
        disp('Saved 3D model to reconstructed_model_enhanced.ply');
    else
        disp('No 3D points reconstructed.');
    end
end

function [orientation, location, inlierIdx] = helperEstimateRelativePose(matchedPoints1, matchedPoints2, intrinsics)
    % Estimate relative pose between two views
    [E, inlierIdx] = estimateEssentialMatrix(...
        matchedPoints1, matchedPoints2, intrinsics, ...
        'Confidence', 99.9, 'MaxDistance', 1);
    
    [orientation, location] = relativeCameraPose(E, intrinsics, ...
        matchedPoints1(inlierIdx,:), matchedPoints2(inlierIdx,:));
end

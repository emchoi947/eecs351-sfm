global imageFolder blockSize k threshold
imageFolder = "Images";
blockSize = 11;
k = 0.06;
threshold = 1e+7;

image = "0013.png";

points = getPointsHarris(image);

function points = getPointsHarris(image)
    global imageFolder blockSize k threshold

    padDepth = floor(blockSize/2);

    Dx = [
        -1 0 1;
        -2 0 2;
        -1 0 1
    ];

    Dy = [
        -1 -2 -1;
         0  0  0;
         1  2  1
    ];

    imgRaw = imread(fullfile(imageFolder, image));
    
    img = im2gray(imgRaw);

    imgOut = zeros(size(img));

    for y=(1+padDepth):(size(img,1)-padDepth)
        for x=(1+padDepth):(size(img,2)-padDepth)
            window = double(img(y-padDepth:y+padDepth, x-padDepth:x+padDepth));

            Ix = conv2(window, Dx, "valid");
            Iy = conv2(window, Dy, "valid");

            H = [
                sum(Ix.^2, "all") sum(Ix.*Iy, "all"); 
                sum(Ix.*Iy, "all") sum(Iy.^2, "all")
            ];

            imgOut(y, x) = det(H) - k * trace(H)^2;
        end
    end

    imgCorners = zeros(size(img));
    for y=(1+7):(size(img,1)-7)
        for x=(1+7):(size(img,2)-7)
            window = double(imgOut(y-7:y+7, x-7:x+7));

            imgCorners(y, x) = (maxk(window(:), 1) == imgOut(y, x)) & (imgOut(y, x) > threshold);
        end
    end

    idx = find(imgCorners);

    y = mod(idx, size(imgOut, 1));
    x = ceil(idx/size(imgOut, 1));

    corners = single([x, y]);

    points = corners(1, :);
    for i=2:length(corners)
        newPoint = corners(i, :);

        if min((points(:, 1) - newPoint(1)).^2 + (points(:, 2) - newPoint(2)).^2) > 100
            points = [points; newPoint];
        end
    end

    imshow(imgRaw); hold on;
    scatter(points(:, 1), points(:, 2), "linewidth", 2)
end
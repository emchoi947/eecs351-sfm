input_folder = 'elephant';
output_folder = 'enhanced';

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

image_files = dir(fullfile(input_folder, '*.JPG'));

for k = 1:length(image_files)
    filename = image_files(k).name;
    filepath = fullfile(input_folder, filename);

    %  Read and convert to grayscale
    img_color = imread(filepath);
    img_gray = im2double(rgb2gray(img_color));

    %  Perform FFT on the grayscale image
    F = fft2(img_gray);            % FFT of the image
    Fshift = fftshift(F);         % Shift zero-frequency component to the center

    [M, N] = size(F);
    [X, Y] = meshgrid(1:N, 1:M);
    cx = N / 2; cy = M / 2;
    D = sqrt((X - cx).^2 + (Y - cy).^2);  % Create frequency distance map

    % Bandpass filter (adjust parameters as needed)
    low_cutoff = 15;  % suppress very low frequencies
    high_cutoff = 85; % suppress very high frequencies
    bandpass_filter = (D > low_cutoff) & (D < high_cutoff);  % Bandpass filter mask

    % Apply bandpass filter
    F_filtered = Fshift .* bandpass_filter;

    %  Inverse FFT to get the enhanced image
    F_ishift = ifftshift(F_filtered);  % Reverse shift
    img_enhanced = real(ifft2(F_ishift));  % Inverse FFT to get the enhanced image

    % Normalize to [0, 1] range for the enhanced image
    img_enhanced = img_enhanced - min(img_enhanced(:));
    img_enhanced = img_enhanced / max(img_enhanced(:));

    % Save the enhanced image
    output_path = fullfile(output_folder, filename);
    imwrite(img_enhanced, output_path);
    fprintf('Saved: %s\n', output_path);
end

clc;

fprintf('===========================================================================\n');
fprintf('=============================== H I D I N G ===============================\n');
fprintf('===========================================================================\n\n');

% Step H1: Load the cover image and change the data type to int16.
cover_image         = int16(imread("E:\Research\Sample Images\Baboon.tiff"));

% Step H2: Compute the size of the cover image (width and height) and also resize into 1D array.
cover_image_size    = size(cover_image);
width               = cover_image_size(2);         
height              = cover_image_size(1);

cover_image_1d      = reshape(cover_image, 1, []);
stego_image_1d      = cover_image_1d;
size_1d             = width * height;

% Step H3: Store the first pixel of each block in cover image into an array named P1.
p1                  = zeros(1, size_1d);
d_arr               = zeros(1, size_1d);
block_size          = 4;
block_num           = 0;
counter             = 1;  

for i = 1:size_1d
    if mod(i, 4) == 1
        p1(counter) = cover_image_1d(i);
        counter     = counter + 1;
        block_num   = block_num + 1;
    end
end

remaining_pixels = mod(size_1d, 4);
if remaining_pixels ~= 0
    for i = 1:remaining_pixels
        p1(block_num * block_size + i) = 10;
    end
end

% Step H4: Compute the differences between all the pixels by P1 and save all the differences in an array named d_arr.
for i = 1:block_num
    block_index = (i - 1) * block_size + 1;

    p_0 = cover_image_1d(block_index);
    p_1 = cover_image_1d(block_index + 1);
    p_2 = cover_image_1d(block_index + 3);
    p_3 = cover_image_1d(block_index + 2);

    d_0 = p_1 - p_0;
    d_1 = p_2 - p_0;
    d_2 = p_3 - p_0;

    d_arr(block_index)      = d_0;
    d_arr(block_index + 1)  = d_1;
    d_arr(block_index + 2)  = d_2;
    d_arr(block_index + 3)  = 10;
end

% Step H5: Set a new table (a matrix of same size as image) as the key with default values (zeros).
muh_key             = zeros(1, size_1d);

% Step H6: Load the secret bits as payload and change the data type to int16.
payload             = readmatrix("E:\Research\Sample Payloads\random-binary_100Kb.txt");
payload_s           = int16(payload);

% Step H7: Consider the difference between -1 and +1 for data hiding (means: -1 ≤ D ≤ +1). 
diff_min            = -1;
diff_max            = 1;

% Step H8: Embedding process happen if the d_arr value is between -1 and +1. If true, then the embedding process will be done as follows:
% a) Add the secret bit to the difference value (D) and store the result in the stego image (SI).
% b) If the secret bit is 0, then the value of the key table is 1. If the secret bit is 1, then the value of the key table is 2.
% c) If the d_arr value is not between -1 and +1, then the value of the key table is 0.
payload_capacity    = 0;
counter             = 1;

fprintf('Embedding Payload Process Start...\n');
tic

for i = 1:size_1d
    if d_arr(i) >= diff_min && d_arr(i) <= diff_max
        if counter <= length(payload_s)
            stego_image_1d(i) = cover_image_1d(i) + d_arr(i) + payload_s(counter);

            if payload_s(counter) == 0
                muh_key(i)  = 1;
            elseif payload_s(counter) == 1
                muh_key(i)  = 2;
            end

            counter = counter + 1;
        end

        payload_capacity = payload_capacity + 1;
    else
        muh_key(i) = 0;
    end
end

elapsed_time = toc;
fprintf(['Embedding Payload Process Done with Elapsed Time: ' num2str(elapsed_time) ' s\n\n']);

% Step H9: Reshape the stego image (SI) into 2D array and display the cover image and stego image.
stego_image         = reshape(stego_image_1d, height, width);

figure; image(cover_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Cover Image (Hiding)');

figure; image(stego_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Stego image (Hiding)');

% Step H10: Analysis the payload capacity, payload capacity per pixel, and PSNR.
fprintf('Payload Capacity (uncast)\t\t\t: %d\n', payload_capacity);
fprintf('Payload Capacity per Pixel (uncast)\t: %f\n', payload_capacity / (width * height));
fprintf('PSNR (uncast)\t\t\t\t\t\t: %f\n\n', psnr(stego_image, cover_image));

cover_image         = cast(cover_image, 'uint8');
stego_image         = cast(stego_image, 'uint8');

fprintf('Payload Capacity (uint8)\t\t\t: %d\n', payload_capacity);
fprintf('Payload Capacity per Pixel (uint8)\t: %f\n', payload_capacity / (width * height));
fprintf('PSNR (uint8)\t\t\t\t\t\t: %f\n\n', psnr(stego_image, cover_image));

% Step H11: Export the stego image and the key table.
output_stego_path   = 'E:\Research\Hiding Result\stego_image_nur.tiff';
imwrite(stego_image, output_stego_path, 'tiff');

output_key_path = 'E:\Research\Hiding Result\key_nur.txt';
dlmwrite(output_key_path, reshape(muh_key, 1, []), 'precision','%d');

fprintf('End of Data Hiding Process\n\n\n\n');
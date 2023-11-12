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



% =============================================================================================== %%



fprintf('===========================================================================\n');
fprintf('=========================== E X T R A C T I O N ===========================\n');
fprintf('===========================================================================\n\n');

fprintf('Start of Data Hiding Extraction\n\n');

% Step E1: Import the key file.
key_file = 'E:\Research\Hiding Result\key_nur.txt';
key_data = dlmread(key_file);
[m, n] = size(key_data);
extract_key = reshape(key_data, [m, n]);

% Step E2: Import the stego image, then compute the size of the stego image (width and height) and also resize into 1D array.
stego_image = imread('E:\Research\Hiding Result\stego_image_nur.tiff');
extract_stego_image = int16(reshape(stego_image, 1, []));

fprintf('Data Hiding Extraction Process Start...\n');
tic

% Step E3: Store the first pixel of each block in stego image into an array named P1.
extract_p1              = zeros(1, size_1d);
extract_si_muh_arr      = zeros(1, size_1d);
extract_block_size      = 4;
extract_block_num       = 0;
extract_counter         = 1;

for i = 1:size_1d
    if mod(i, 4) == 1
        extract_p1(extract_counter) = extract_stego_image(i);
        extract_counter             = extract_counter + 1;
        extract_block_num           = extract_block_num + 1;
    end
end

% Step E4: Compute the differences between all the pixels by P1 and save all the differences in an array named extract_si_muh_arr.
for i = 1:extract_block_num
    extract_block_index = (i - 1) * extract_block_size + 1;

    extract_p_0 = extract_stego_image(extract_block_index);
    extract_p_1 = extract_stego_image(extract_block_index + 1);
    extract_p_2 = extract_stego_image(extract_block_index + 3);
    extract_p_3 = extract_stego_image(extract_block_index + 2);

    extract_d_0 = extract_p_1 - extract_p_0;
    extract_d_1 = extract_p_2 - extract_p_0;
    extract_d_2 = extract_p_3 - extract_p_0;

    extract_si_muh_arr(extract_block_index)     = extract_d_0;
    extract_si_muh_arr(extract_block_index + 1) = extract_d_1;
    extract_si_muh_arr(extract_block_index + 2) = extract_d_2;
    extract_si_muh_arr(extract_block_index + 3) = 10;
end

% Step E5: Extraction process happen if the key value is 1 or 2. If true, then the extraction process will be done as follows:
% a) Subtract the secret bit from the difference value (D) and store the result in the cover image (CI).
% b) If the key value is 1, then the secret bit is 0. If the key value is 2, then the secret bit is 1.
% c) If the key value is 0, then the value of the cover image is the same as the stego image.
extract_cover_image    = zeros(1, size_1d);
extract_payload_size   = 0;

for i = 1:length(extract_key)
    if extract_key(i) ~= 0
        extract_payload_size = extract_payload_size + 1;
    end
end

extract_payload        = int16(zeros(1, extract_payload_size)); 
counter                = 1;

for i = 1:size_1d
    if mod(i, 4) == 1
        extract_cover_image(i) = 10;
    end
  
    if extract_key(i) == 1 || extract_key(i) == 2
        extract_cover_image(i) = extract_stego_image(i) - ceil(mod(extract_si_muh_arr(i), 2));
  
        if extract_key(i) == 1
            extract_payload(counter) = 0;
        elseif extract_key(i) == 2
            extract_payload(counter) = 1;
        end
        
        counter = counter + 1;
    else
        extract_cover_image(i) = extract_stego_image(i);
    end
end

% Step E6: Export the secret data.
file_name           = 'E:\Research\Extraction Result\secret_data_final.txt';
extract_file_id     = fopen(file_name, 'w');

if extract_file_id == -1
    error('Unable to open the file for writing.');
else
    for i = 1:length(extract_payload)
        fprintf(extract_file_id, '%d\t', extract_payload(i));
    end

    fclose(extract_file_id);
    disp(['Secret data has been saved to ' file_name]);
end

% Step E7: Reshape the cover image and stego image into 2D array and display the cover image and stego image.
extract_cover_image = reshape(extract_cover_image, height, width);
extract_stego_image = reshape(extract_stego_image, height, width);

extract_cover_image = cast(extract_cover_image, 'uint8');
extract_stego_image = cast(extract_stego_image, 'uint8');

figure; image(extract_cover_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Cover Image (Extracted)');

figure; image(extract_stego_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Stego image (Extracted)');

% Step E8: Analysis the elapsed time, secret data differences, and PSNR.
elapsed_time        = toc;
fprintf(['Data Hiding Extraction Process Done with Elapsed Time: ' num2str(elapsed_time) ' s\n\n']);

file1               = dlmread('E:\Research\Sample Payloads\random-binary_1Kb.txt');
file2               = dlmread('E:\Research\Extraction Result\secret_data_final.txt');
num_diff_bits       = 0;

for i = 1:length(file1)
    if file1(i) ~= file2(i)
        num_diff_bits = num_diff_bits + 1; 
    end
end

fprintf('Secret Data Differences\t\t\t\t: %d\n', num_diff_bits);
fprintf('PSNR (Compare Cover Image)\t\t\t: %f\n\n', psnr(extract_cover_image, cover_image));

% Step E9: Export the cover image.
output_cover_path   = 'E:\Research\Extraction Result\cover_image_nur.tiff';
imwrite(extract_cover_image, output_cover_path, 'tiff');

fprintf('End of Data Hiding Extraction\n\n');
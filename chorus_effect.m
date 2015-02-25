close all; clear all; clc

% Load effect parameters from parameters file
chorus_effect_parameters;

[input, sample_rate] = audioread(filename);

delay_length_samples     = round(delay_length * sample_rate);
modulation_depth_samples = round(modulation_depth * sample_rate);

modulated_output = zeros(length(input), 1);
delay_buffer     = zeros(delay_length_samples + modulation_depth_samples, 1);

%%

% Argument for sin() modulation function. Converts the loop's control variable into 
% the appropriate argument in radians to achieve the specified modulation rate
modulation_argument = 2 * pi * modulation_rate / sample_rate;

tic
for i = 1:(length(input))
	% Find index to read from for modulated output
	modulated_sample = modulation_depth_samples * sin(modulation_argument * i);
	modulated_sample = modulated_sample + delay_length_samples;

	% Get values to interpolate between
	interpolation_values = [delay_buffer(floor(modulated_sample)), ...
	                        delay_buffer( ceil(modulated_sample))];

	query_sample = modulated_sample - floor(modulated_sample) + 1;
	modulated_output(i) = interp1(interpolation_values, query_sample);

	% Save the input's current value in the ring buffer and advance to the next value
	new_sample = (input(i) + modulated_output(i) * feedback);
	delay_buffer = [ new_sample; delay_buffer(1 : length(delay_buffer)-1) ];
end
toc

summed_output = ((1 - dry_wet_balance) * input(:, 1) ) + (dry_wet_balance * modulated_output);


% Plot the input, modulated signal, and summed output signal
xmin =  1; xmax = length(input);
ymin = -1; ymax = 1;

subplot(3, 1, 1); plot(input, 'b'); axis([xmin, xmax, ymin, ymax]);
title('input signal');

subplot(3, 1, 2); plot(modulated_output, 'r'); axis([xmin, xmax, ymin, ymax]);
title('modulated signal');

subplot(3, 1, 3); plot(summed_output, 'g');  axis([xmin, xmax, ymin, ymax]);
title('summed input and modulation');


if play_output
	sound(summed_output, sample_rate)
end

audiowrite(output_filename, summed_output, sample_rate);

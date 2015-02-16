close all; clear all; clc

%% Parameters

filename = 'Joey sassy guitar.wav';
delay_length     = 0.030;  % sec
modulation_depth = 0.008;  % sec
modulation_rate  = 0.25;   % Hz
dry_wet_balance  = 0.40;   % 0.0 for all dry, 1.0 for all wet

%%

[input, sample_rate] = audioread(filename);

% If below uncommented, only use first two seconds of input
% input = input(1:sample_rate*2);

delay_length_samples     = round(delay_length * sample_rate);
modulation_depth_samples = round(modulation_depth * sample_rate);

modulated_output = zeros(length(input), 1);
delay_buffer     = zeros(1, delay_length_samples + modulation_depth_samples);

delay_buffer_index = 1;

%%

delay_buffer_indicies = 1:length(delay_buffer);

for i = 1:(length(input))

	modulated_sample = round(modulation_depth_samples * sin(2 * pi * i * modulation_rate / sample_rate) + delay_buffer_index) - modulation_depth_samples;

	modulated_sample = mod(modulated_sample, length(delay_buffer));
	if (modulated_sample == 0)
		modulated_sample = 1;
	end

	modulated_output(i) = delay_buffer(modulated_sample);

	delay_buffer(delay_buffer_index) = input(i);

	% Advance the buffer index
	delay_buffer_index = 1 + delay_buffer_index;
	if (delay_buffer_index > length(delay_buffer))
		delay_buffer_index = 1;
	end

end

summed_output = ((1 - dry_wet_balance) * input(:, 1) ) + (dry_wet_balance * modulated_output);

xmin = 1; xmax = length(input);
ymin = -1; ymax = 1;

subplot(3, 1, 1); plot(input, 'b'); axis([xmin, xmax, ymin, ymax]);
title('input signal');

subplot(3, 1, 2); plot(modulated_output, 'r'); axis([xmin, xmax, ymin, ymax]);
title('modulated signal');

subplot(3, 1, 3); plot(summed_output, 'g');  axis([xmin, xmax, ymin, ymax]);
title('summed input and modulation');


% Uncomment below to play the summed output
sound(summed_output, sample_rate)

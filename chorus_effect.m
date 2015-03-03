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

if loop_timer
	tic
end

for i = 1:(length(input))
	% Find index to read from for modulated output
	modulated_sample = modulation_depth_samples * sin(modulation_argument * i);
	modulated_sample = modulated_sample + delay_length_samples;

	% Get values to interpolate between
	interp_y1 = delay_buffer(floor(modulated_sample));
	interp_y2 = delay_buffer( ceil(modulated_sample));

	query_sample = modulated_sample - floor(modulated_sample);

	% Interpolate to find the output value
	modulated_output(i) = interp_y1 + (interp_y2 - interp_y1) * (query_sample);

	% Save the input's current value in the ring buffer and advance to the next value
	new_sample = (input(i) + modulated_output(i) * feedback);
	delay_buffer = [ new_sample; delay_buffer(1 : length(delay_buffer)-1) ];
end

if loop_timer
	toc
end

%% Create low shelf filter
% Shout out to http://www.musicdsp.org/files/Audio-EQ-Cookbook.txt
w0     = 2 * pi * low_shelf_freq / sample_rate;
S      = 0.5;
A      = 10 ^ (low_shelf_gain / 40);
alpha  = sin(w0) / 2 * sqrt( (A + 1/A) * (1/S - 1) + 2 );

b0 =    A*( (A+1) - (A-1)*cos(w0) + 2*sqrt(A)*alpha );
b1 =  2*A*( (A-1) - (A+1)*cos(w0)                   );
b2 =    A*( (A+1) - (A-1)*cos(w0) - 2*sqrt(A)*alpha );
a0 =        (A+1) + (A-1)*cos(w0) + 2*sqrt(A)*alpha;
a1 =   -2*( (A-1) + (A+1)*cos(w0)                   );
a2 =        (A+1) + (A-1)*cos(w0) - 2*sqrt(A)*alpha;

% Find and plot the EQ's frequency response in the Z domain
[H, W] = freqz([b0, b1, b2], [a0, a1, a2], 500);
f = W / (2 * pi) * sample_rate;

H_dB = 20*log10(abs(H));

figure('Position',[25, 50, 750, 600])

subplot(2, 1, 1); semilogx(f, H_dB); axis([20, 20e3, min(H_dB), max(H_dB)])
title('Frequency response of low shelf EQ')
ylabel('Gain (dB)')
xlabel('Frequency (Hz)')

len = length(modulated_output);

	NFFT = 2^nextpow2(len); % Next power of 2 from length of y
	f = sample_rate / 2 * linspace(0, 1, NFFT/2+1);

	Mod_FFT = fft(modulated_output,NFFT) / len;

	% Plot single-sided amplitude spectrum.
	subplot(2, 1, 2); semilogx(f, abs(Mod_FFT(1:NFFT/2+1)));

% Apply low shelf EQ to the modulated signal
modulated_output = filter([b0, b1, b2], [a0, a1, a2], modulated_output);

Mod_EQ_FFT = fft(modulated_output,NFFT) / len;

	% Plot single-sided amplitude spectrum.
	hold; semilogx(f, abs(Mod_EQ_FFT(1:NFFT/2+1)), 'r'); axis([20, 20e3, 0, max(abs(Mod_FFT))]);
	title('Single-Sided Spectrum')
	xlabel('Frequency (Hz)')
	ylabel('|Y(f)| (dB)')
	legend('Modulated', 'Modulated & EQed')


% Add the dry and wet signals to get the final mixed version
summed_output = ((1 - dry_wet_balance) * input(:, 1) ) + (dry_wet_balance * modulated_output);


% Plot the input, modulated signal, and summed output signal
xmin =  1; xmax = length(input);
ymin = -1; ymax = 1;

figure('Position', [700, 50, 600, 600])
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

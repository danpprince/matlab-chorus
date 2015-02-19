close all; clear all; clc;

rb = RingBuffer(5);

rb.set(1);
rb.increment;
rb.set(2);
rb.increment;
rb.set(3);
rb.increment;
rb.set(4);
rb.increment;
rb.set(5);
rb.increment;

rb.set(6);

n = -20:20;

for i = 1:length(n)
	ringbuffer_access(i) = rb.access(n(i));
end

stem(n, ringbuffer_access)
xlabel('Access index'); ylabel('Return value')

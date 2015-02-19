classdef RingBuffer < handle

	properties
		buffer
		index
	end

	methods
		function obj = RingBuffer(length)
			obj.buffer = zeros(length, 1);
			obj.index = 1;
		end

		function value = get(obj)
			value = obj.buffer(index);
		end

		function value = set(obj, value)
			obj.buffer(obj.index) = value;
		end

		function value = increment(obj)
			obj.index = obj.index + 1;

			if (obj.index > length(obj.buffer))
				obj.index = 1;
			end
		end

		function value = decrement(obj)
			obj.index = obj.index - 1;

			if (obj.index < 1)
				obj.index = length(obj.buffer);
			end
		end

		function value = access(obj, i)

			if (i + obj.index > length(obj.buffer))
				% Requested address is past the end of the buffer
				value = obj.buffer( mod(i + obj.index - 1, length(obj.buffer)) + 1);

			elseif (i + obj.index < length(obj.buffer))
				% Requested address is before the beginning of the buffer
				value = obj.buffer( mod(i + obj.index - 1, length(obj.buffer)) + 1 );

			else
				value = obj.buffer( obj.index + i );
			end

		end

	end

end

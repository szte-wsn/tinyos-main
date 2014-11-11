/*
 * Copyright (c) 2014, University of Szeged
 *
 * Author: Miklos Maroti
 */

module MeasureWave2P {
	provides interface MeasureWave;

	uses interface DiagMsg;
#ifdef MEASUREWAVE_PROFILER
	uses interface LocalTime<TMicro>;
#endif
}

implementation {

	enum {
		ERR_NONE = 0,
		ERR_START_NOT_FOUND = 101,
		ERR_SMALL_MINMAX_RANGE = 102,
		ERR_FEW_ZERO_CROSSINGS = 103,
		ERR_LARGE_PERIOD = 104,
		ERR_PERIOD_MISMATCH = 105,
		ERR_ZERO_PERIOD = 106
	};

	uint8_t err;

	enum {
		INPUT_LENGTH = 480,
		FIND_TX_LEVEL = 4,
		FIND_TX_START = 1,	// first byte is usually non-zero
		FIND_TX_END = 80,	// tx must start before
		FILTER_START_DELAY = 40,
		FILTER_TRIPLETS = (INPUT_LENGTH - FIND_TX_END - FILTER_START_DELAY - 2) / 3,
		FILTERED_LENGTH = FILTER_TRIPLETS * 3,
		ZERO_CROSSINGS = 3,
		APPROX_WINDOW = 4
	};

	// finds the start of the real transmission (where it becomes non-zero)
	// returns 0 if the start could not be found
	// we modify the byte input[length] and restore it

	uint8_t tx_start;
	void find_tx_start(uint8_t *input, uint8_t length) {
		uint8_t *pos1 = input, *pos2 = input + length;
		uint8_t overwritten;

		overwritten = *pos2;
		*pos2 = 255;

		--pos1;
		while (*(++pos1) <= FIND_TX_LEVEL)
			;

		*pos2 = overwritten;

		if (pos1 != input && pos1 != pos2) {
			//while (*(--pos2) > FIND_TX_LEVEL)
			//	;

			//if (pos2 + 1 == pos1) {
				tx_start = pos1 - input;
				return;
			//}
		}

		tx_start = 0;
		err = ERR_START_NOT_FOUND;
	}

	// Calculates the [1,2,3,2,1] filter in place for triplets * 3
	// many input samples, it looks 4 samples back into the input
	// it also calculates the min and max filtered values

	uint8_t filter3_min, filter3_max;
	void filter3(uint8_t *input, uint16_t triplets) {
		uint8_t x0 = input[-3];
		uint8_t x1 = input[-2];
		uint8_t x2 = input[-1];

		uint8_t y0 = input[-4] + x0;
		uint8_t y1 = y0 + x1;
		uint8_t y2 = x0 + x1 + x2;

		uint8_t z = y0 + y1 + y2;

		uint8_t min = 255;
		uint8_t max = 0;

		do {
			z -= y0;
			y0 = y2 - x0;
			x0 = *input;
			y0 += x0;
			z += y0;
			*(input++) = z;

			if (z < min)
				min = z;
			if (z > max)
				max = z;

			z -= y1;
			y1 = y0 - x1;
			x1 = *input;
			y1 += x1;
			z += y1;
			*(input++) = z;

			if (z < min)
				min = z;
			if (z > max)
				max = z;

			z -= y2;
			y2 = y1 - x2;
			x2 = *input;
			y2 += x2;
			z += y2;
			*(input++) = z;

			if (z < min)
				min = z;
			if (z > max)
				max = z;
		} while (--triplets != 0);

		filter3_min = min;
		filter3_max = max;

		if (filter3_max - filter3_min < 9)
			err = ERR_SMALL_MINMAX_RANGE;
	}

	// finds the positive zero corssings and stores them in a vector
	// it overwrites input[length] and input[length+1] and restores them

	int16_t zero_crossings[ZERO_CROSSINGS];
	void find_zero_crossings(uint8_t *input, uint16_t length, uint8_t low, uint8_t high) {
		uint8_t *start = input, *last;
		uint8_t over1, over2, count, a;
		int16_t pos1, pos2;

		over1 = start[length];
		over2 = start[length + 1];

		start[length] = low;
		start[length + 1] = high;

		--input;
		for (count = 0; count < ZERO_CROSSINGS; count++) {
			while (*(++input) > low)
				;

			last = input;

			for(;;) {
				a = *(++input);
				if (a <= low)
					last = input;
				else if (a >= high)
					break;
			}

			pos1 = last - start;
			if (pos1 >= length) {
				err = ERR_FEW_ZERO_CROSSINGS;
				break;
			}

			pos2 = input - start;

			zero_crossings[count] = (pos1 + pos2) >> 1;
		}

		start[length] = over1;
		start[length + 1] = over2;
	}

	inline bool approx(uint8_t a, uint8_t b) {
		return a <= b + APPROX_WINDOW && b <= a + APPROX_WINDOW;
	}

	uint8_t period;
	uint16_t phase;

	void find_period3() {
		uint8_t a, b, n, m;
		uint16_t t;

		// period = 0;
		err = ERR_LARGE_PERIOD;

		t = zero_crossings[1] - zero_crossings[0];
		if (t > 255)
			return;
		a = t;

		t = zero_crossings[2] - zero_crossings[1];
		if (t > 255)
			return;
		b = t;

		err = ERR_PERIOD_MISMATCH;

		if (approx(a, b)) {
			n = 1 + 1;
			m = 1 + 2;
		}
		else if (approx(a >> 1, b)) {
			n = 2 + 1;
			m = 2 + 3;
		}
		else if (approx(a, b >> 1)) {
			n = 1 + 2;
			m = 1 + 3;
		}
//		else if (approx(a/3, b)) {
//			n = 3 + 1;
//			m = 3 + 4;
//		}
//		else if (approx(a, b/3)) {
//			n = 1 + 3;
//			m = 1 + 4;
//		}
		else
			return;

		t = zero_crossings[2] - zero_crossings[0] + 1;

		if (n == 2)
			period = t >> 1;
		else if (n == 3)
			period = t / 3;
		else
			period = t >> 2;

		if (period == 0) {
			err = ERR_ZERO_PERIOD;
			return;
		}

		err = ERR_NONE;

		t = zero_crossings[0] + zero_crossings[1] + zero_crossings[2];
		t -= period * m;
		phase = (t + 1) / 3;
	}

	void find_period4() {
		uint8_t a, b, c, n, m;
		uint16_t t;

		// period = 0;
		err = ERR_LARGE_PERIOD;

		t = zero_crossings[1] - zero_crossings[0];
		if (t > 255)
			return;
		a = t;

		t = zero_crossings[2] - zero_crossings[1];
		if (t > 255)
			return;
		b = t;

		t = zero_crossings[3] - zero_crossings[2];
		if (t > 255)
			return;
		c = t;

		err = ERR_PERIOD_MISMATCH;

		if (approx(a, b)) {
			if (approx(b, c)) {
				n = 1 + 1 + 1;
				m = 1 + 2 + 3;
			}
			else if (approx(b, c >> 1)) {
				n = 1 + 1 + 2;
				m = 1 + 2 + 4;
			}
			else if (approx(b >> 1, c)) {
				n = 2 + 2 + 1;
				m = 2 + 4 + 5;
			}
			else
				return;
		}
		else if (approx(a >> 1, b)) {
			if (approx(b, c)) {
				n = 2 + 1 + 1;
				m = 2 + 3 + 4;
			}
			else if (approx(b, c >> 1)) {
				n = 2 + 1 + 2;
				m = 2 + 3 + 5;
			}
			else
				return;
		}
		else if (approx(a, b >> 1)) {
			if (approx(b >> 1, c)) {
				n = 1 + 2 + 1;
				m = 1 + 3 + 4;
			}
			else if (approx(b >> 1, c >> 1)) {
				n = 1 + 2 + 2;
				m = 1 + 3 + 5;
			}
			else
				return;
		}
		else
			return;

		t = zero_crossings[3] - zero_crossings[0] + (n >> 1);

		if (n == 3)
			period = t / 3;
		else if (n == 4)
			period = t >> 2;
		else
			period = t / 5;

		if (period == 0) {
			err = ERR_ZERO_PERIOD;
			return;
		}

		err = ERR_NONE;

		t = zero_crossings[0] + zero_crossings[1] + zero_crossings[2] + zero_crossings[3];
		t -= ((uint16_t) period) * m;
		phase = (t + 2) >> 2;
	}

	// processes the input buffer, calculates the period and phase
	// if the period is zero, then the phase contains the error code

	void process(unsigned char *input) {
		uint8_t a, b;
		err = ERR_NONE;

		find_tx_start(input + FIND_TX_START, FIND_TX_END - FIND_TX_START);
		if (err != ERR_NONE)
			return;

		input += tx_start + FILTER_START_DELAY;

		filter3(input, FILTER_TRIPLETS);
		if (err != ERR_NONE)
			return;

		a = (((uint16_t) filter3_min) + ((uint16_t) filter3_max)) >> 1;
		b = (filter3_max - filter3_min) >> 3;
		find_zero_crossings(input, FILTERED_LENGTH, a-b, a+b);
		if (err != ERR_NONE)
			return;

		if (ZERO_CROSSINGS == 3)
			find_period3();
		else
			find_period4();
		if (err != ERR_NONE)
			return;

		phase %= period;
	}

// ------- MeasureWave interface

	command void MeasureWave.changeData(uint8_t *newData, uint16_t newLen) {
#ifdef MEASUREWAVE_PROFILER
		uint32_t starttime = call LocalTime.get();
#endif
		phase=period=filter3_max=filter3_min=tx_start=255;
		process(newData);
#ifdef MEASUREWAVE_PROFILER
		starttime = call LocalTime.get() - starttime;
		if( call DiagMsg.record() ) {
			call DiagMsg.uint32(starttime);
			call DiagMsg.uint8(err);
			call DiagMsg.uint8(period);
			call DiagMsg.uint8(phase);
			call DiagMsg.send();
		}
#endif
	}

	command uint8_t MeasureWave.getPhaseRef() {
		return tx_start;
	}

	command void MeasureWave.filter() {
	}

	command uint8_t MeasureWave.getMinAmplitude() {
		return filter3_min;
	}

	command uint8_t MeasureWave.getMaxAmplitude() {
		return filter3_max;
	}

	command uint16_t MeasureWave.getPeriod() {
		return err == ERR_NONE ? period : 0;
	}

	command uint8_t MeasureWave.getPhase() {
		return err == ERR_NONE ? phase : err;
	}
}

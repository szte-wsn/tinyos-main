#include <stdio.h>
#include <stdint.h>
#include <byteswap.h>
#include <libgen.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

	enum {
		ERR_NONE = 0,
		ERR_NO_SILENCE1 = 101,
		ERR_NO_SILENCE2 = 102,
		ERR_SMALL_MINMAX_RANGE = 103,
		ERR_FEW_ZERO_CROSSINGS = 104,
		ERR_LARGE_PERIOD = 105,
		ERR_PERIOD_MISMATCH = 106,
		ERR_ZERO_PERIOD = 107
	};

	uint8_t err;

	enum {
		INPUT_LENGTH = 480,
		SILENCE1_START = 0,
		SILENCE1_END = 10,
		TRANSMIT1_START = 30,
		TRANSMIT1_END = 60,
		FILTER_START = 150,
		FILTER_END = 400,
		TRANSMIT2_START = 430,
		TRANSMIT2_END = 460,
		SILENCE2_START = 470,
		SILENCE2_END = 480,
		SILENCE_LIMIT = 5,
		FILTER_MINMAX_RANGE = 7,
		FILTER_TRIPLETS = (FILTER_END - FILTER_START) / 3,
		FILTERED_LENGTH = FILTER_TRIPLETS * 3,
		ZERO_CROSSINGS = 3,
		APPROX_WINDOW = 4
	};

	uint16_t get_sum(uint8_t *input, uint8_t len) {
		uint16_t a = 0;

		do {
			a += *(input++);
		} while (--len != 0);

		return a;
	}

	uint8_t tx1_avg, tx2_avg;
	void check_levels(uint8_t *input) {
		uint8_t avg;

		avg = get_sum(input + SILENCE1_START, SILENCE1_END - SILENCE1_START) / (SILENCE1_END - SILENCE1_START);
		if (avg > SILENCE_LIMIT) {
			err = ERR_NO_SILENCE1;
			return;
		}

		avg = get_sum(input + SILENCE2_START, SILENCE2_END - SILENCE2_START) / (SILENCE2_END - SILENCE2_START);
		if (avg > SILENCE_LIMIT) {
			err = ERR_NO_SILENCE2;
			return;
		}

		tx1_avg = get_sum(input + TRANSMIT1_START, TRANSMIT1_END - TRANSMIT1_START) / (TRANSMIT1_END - TRANSMIT1_START);
		tx2_avg = get_sum(input + TRANSMIT2_START, TRANSMIT2_END - TRANSMIT2_START) / (TRANSMIT2_END - TRANSMIT2_START);
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

		if (filter3_max - filter3_min < FILTER_MINMAX_RANGE)
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

		check_levels(input);
		if (err != ERR_NONE)
			return;

		filter3(input + FILTER_START, FILTER_TRIPLETS);
		if (err != ERR_NONE)
			return;

		a = (((uint16_t) filter3_min) + ((uint16_t) filter3_max)) >> 1;
		b = (filter3_max - filter3_min + 2) >> 3;
		find_zero_crossings(input + FILTER_START, FILTERED_LENGTH, a-b, a+b);
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

// --- testing

uint8_t samples[512];
uint16_t read_samples(const char *filename) {
	FILE *file;
	uint32_t len = 0;
	size_t count;

	if (filename == NULL)
		file = stdin;
	else {
		file = fopen(filename, "rb");
		if (file == NULL) {
			fprintf(stderr, "Could not open file %s\n", filename);
			return 0;
		}
	}

	count = fread(&len, 4, 1, file);
	len = __bswap_32(len);

	if (count == 1 && len <= 512) {
		count = fread(samples, 1, len, file);
		if (count != len)
			len = 0;
	}

	if (filename != NULL)
		fclose(file);

	return len;
}

void print_samples(uint8_t *input, uint16_t length) {
	uint16_t i;
	for (i = 0; i < length; i++)
		printf("%u ", (unsigned int) input[i]);
	printf("\n");
}

void test_filter3() {
	uint8_t input[16];
	uint8_t s,i;

	for (s = 0; s < 16; s++) {
		for (i = 0; i < 16; i++)
			input[i] = 0;
		input[s] = 1;
		filter3(input + 4, (16-4)/3);

		for (i = 0; i < 16; i++)
			printf("%u ", (unsigned int) input[i]);
		printf("- %d %u %u\n", (int) err, (unsigned int) filter3_min, (unsigned int) filter3_max);
	}
}

void test_zero_crossings() {
	uint8_t i;
	uint8_t input[] = {0, 1, 1, 2, 1, 0, 2, 1, 2, 0, 1, 2, 0, 1, -1, -1};

	for (i = 0; i < sizeof(input) - 2; i++)
		printf("%u ", (unsigned int) input[i]);
	printf("\n");

	err = ERR_NONE;
	find_zero_crossings(input, sizeof(input) - 2, 0, 1);
	printf("%d : ", (int) err);
	for (i = 0; i < ZERO_CROSSINGS; i++)
		printf("%d ", (int) zero_crossings[i]);
	printf("\n");

	err = ERR_NONE;
	find_zero_crossings(input, sizeof(input) - 2, 1, 2);
	printf("%d : ", (int) err);
	for (i = 0; i < ZERO_CROSSINGS; i++)
		printf("%d ", (int) zero_crossings[i]);
	printf("\n");

	err = ERR_NONE;
	find_zero_crossings(input, sizeof(input) - 2, 0, 2);
	printf("%d : ", (int) err);
	for (i = 0; i < ZERO_CROSSINGS; i++)
		printf("%d ", (int) zero_crossings[i]);
	printf("\n");
}

void test_process(int argc, char **argv) {
	int i, j;
	int hist[10];

	for (i = 0; i < 10; i++)
		hist[i] = 0;

	for (i = 1; i < argc; i++) {
		const char *filename = argv[i];

		uint16_t count = read_samples(filename);
		if (count != INPUT_LENGTH) {
			fprintf(stderr, "incorrect sample length %d of %s\n", count, filename);
			continue;
		}

		for (j = 0; j < ZERO_CROSSINGS; j++)
			zero_crossings[j] = 0;

		process(samples);

		char *filename_dup = strdup(filename);
		char *filename_bas = basename(filename_dup);

		printf("%s process %d %d %d filter %d %d xing", filename_bas,
			(int) err, (int) period, (int) phase,
			(int) filter3_min, (int) filter3_max);
		for (j = 1; j < ZERO_CROSSINGS; j++)
			printf(" %d", (int) (zero_crossings[j] - zero_crossings[j-1]));
		printf("\n");

		// print_samples(samples, INPUT_LENGTH);

		free(filename_dup);

		if (err == 0)
			;
		else if (101 <= err && err <= 108)
			err = err - 100;
		else
			err = 109;

		hist[err] += 1;
	}

	printf("error codes:");
	for (i = 0; i < 10; i++)
		printf(" %d", hist[i]);
	printf("\n");
}

void main(int argc, char **argv) {
	// test_filter3();
	// test_zero_crossings();
	test_process(argc, argv);
}

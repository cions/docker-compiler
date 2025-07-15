#include <stdio.h>
#include <stdlib.h>
#include <stdatomic.h>

int main(void) {
	printf("Hello, C world!\n");

	atomic_flag flag = ATOMIC_FLAG_INIT;
	atomic_flag_test_and_set(&flag);

	exit(EXIT_SUCCESS);
}

#include <atomic>
#include <iostream>
#include <stdexcept>
#include <thread>
#include <vector>

int main() {
	std::cout << "Hello, C++ world!" << std::endl;

	try {
		throw std::runtime_error("exception");
	} catch (const std::exception&) {
		std::cout << "an exception was caught" << std::endl;
	}

	std::atomic<int> aint(1);

	std::vector<std::thread> threads;
	for (int i = 0; i < 16; ++i) {
		threads.emplace_back([&]() {
			int expected = aint.load(std::memory_order_seq_cst);
			while (!aint.compare_exchange_strong(expected, expected * 2, std::memory_order_seq_cst));
		});
	}
	for (auto && t : threads) {
		t.join();
	}

	int expected = 65536;
	int actual = aint.load(std::memory_order_seq_cst);
	std::cout << "expected: " << expected << ", actual: " << actual << std::endl;
	if (actual != expected) {
		return 1;
	}

	return 0;
}

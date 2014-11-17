/*
 * Copyright (c) 2014, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 */

#include <cassert>
#include <mutex>
#include <condition_variable>
#include <vector>
#include <algorithm>
#include <iostream>
#include <deque>
#include <thread>
#include <atomic>
#include <string>

template <class DATA> class Producer;

template <class DATA> class Consumer {
private:
	std::string name;
	std::atomic<int> conn_count;

public:
	Consumer(const char *name) : name(name), conn_count(0) {
	}

	~Consumer() {
		if (conn_count != 0)
			throw std::runtime_error(name + " is not disconnected");
	}

	virtual void work(DATA data) = 0;

private:
	friend class Producer<DATA>;

	void connected() {
		assert(conn_count >= 0);
		conn_count++;
	}

	void disconnected() {
		assert(conn_count > 0);
		conn_count--;
	}
};

template <class DATA> class Printer: public Consumer<DATA> {
private:
	std::mutex printer_mutex;

public:
	Printer(const char *name = "Printer")
		: Consumer<DATA>(name) {
	}

	virtual void work(DATA data) {
		std::lock_guard<std::mutex> lock(printer_mutex);
		std::cout << data << std::endl;
	}
};

template <class DATA> class Producer {
private:
	std::vector<Consumer<DATA>*> consumers;

	std::mutex producer_mutex;

public:
	~Producer() {
		disconnect_all();
	}

	void send(DATA data) {
		std::lock_guard<std::mutex> lock(producer_mutex);
		for(Consumer<DATA> *c : consumers)
			c->work(data);
	}

	void connect(Consumer<DATA> &c) {
		std::lock_guard<std::mutex> lock(producer_mutex);
		consumers.push_back(&c);
		c.connected();
	}

	void disconnect(Consumer<DATA> &c) {
		std::lock_guard<std::mutex> lock(producer_mutex);

		auto it = std::find(consumers.begin(), consumers.end(), &c);
		if (it == consumers.end())
			throw std::invalid_argument("consumer not found");

		*it = consumers.back();
		consumers.pop_back();

		c.disconnected();
	}

	void disconnect_all() {
		std::lock_guard<std::mutex> lock(producer_mutex);
		for(Consumer<DATA> *c : consumers)
			c->disconnected();

		consumers.clear();
	}
};

template <class DATA> class Buffer: public Consumer<DATA>, public Producer<DATA> {
private:
	std::deque<DATA> queue;

	std::mutex buffer_mutex;
	bool buffer_exit = false;
	std::condition_variable buffer_cond;
	std::thread buffer_thread;

public:
	Buffer(const char *name = "Buffer")
		: Consumer<DATA>(name),
		buffer_thread(&Buffer<DATA>::pump, this) {
	}

	~Buffer() {
		{
			std::lock_guard<std::mutex> lock(buffer_mutex);
			buffer_exit = true;
			buffer_cond.notify_one();
		}
		buffer_thread.join();
	}

	void work(DATA data) {
		std::lock_guard<std::mutex> lock(buffer_mutex);
		queue.push_back(data);
		buffer_cond.notify_one();
	}

private:
	void pump() {
		for (;;) {
			std::unique_lock<std::mutex> lock(buffer_mutex);

			if (queue.empty()) {
				if (buffer_exit)
					break;

				buffer_cond.wait(lock);

				if (buffer_exit)
					break;
			}

			DATA data = queue.front();
			queue.pop_front();

			lock.unlock();

			this->send(data);
		}
	};
};

template <class INPUT, class OUTPUT> class Block: public Consumer<INPUT>, public Producer<OUTPUT> {
};

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

#include <stdexcept>
#include <deque>
#include <vector>
#include <algorithm>
#include <mutex>
#include <condition_variable>

template<class DATA> class Consumer;

template<class DATA> class Producer {
private:
	std::mutex mutex;
	std::vector<Consumer<DATA>*> consumers;

	friend class Consumer<DATA>;

public:
	Producer() {
	}

	~Producer() {
		std::lock_guard<std::mutex> lock1(mutex);
		for (Consumer<DATA>* c : consumers) {
			std::lock_guard<std::mutex> lock2(c->mutex);
			c->remove(this);
		}
	}

	void connect(Consumer<DATA> &c) {
		std::lock_guard<std::mutex> lock1(mutex);
		if (std::find(consumers.cbegin(), consumers.cend(), &c) != consumers.cend())
			throw std::invalid_argument("already connected");

		std::lock_guard<std::mutex> lock2(c.mutex);

		c.producers.push_back(this);
		consumers.push_back(&c);
	}

	void disconnect(Consumer<DATA> &c) {
		std::lock_guard<std::mutex> lock1(mutex);
		consumers.erase(std::remove(consumers.begin(), consumers.end(), &c), consumers.end());

		std::lock_guard<std::mutex> lock2(c.mutex);
		c.remove(this);
	}

	void send(DATA data) {
		std::lock_guard<std::mutex> lock(mutex);
		for (Consumer<DATA>* c : consumers)
			c->send(data);
	}
};

template<class DATA> class Consumer {
private:
	std::mutex mutex;
	std::condition_variable condition;
	std::vector<Producer<DATA>*> producers;
	std::deque<DATA> queue;

	friend class Producer<DATA>;

public:
	Consumer() {
	}

	Consumer(Producer<DATA> &p) {
		p.connect(*this);
	}

	~Consumer() {
		// must be careful of lock ordering to prevent deadlock
		for (;;) {
			mutex.lock();
			Producer<DATA>* p = producers.empty() ? NULL : producers.back();
			mutex.unlock();

			if (p != NULL)
				p->disconnect(*this);
			else
				break;
		}
	}

	DATA receive() {
		std::unique_lock<std::mutex> lock(mutex);
		if (queue.empty()) {
			condition.wait(lock);
			if (queue.empty())
				throw std::runtime_error("interrupted");
		}

		return queue.pop_front();
	}

private:
	void send(DATA msg) {
		std::lock_guard<std::mutex> lock(mutex);

		queue.push_back(msg);
		condition.notify_one();
	}

	void remove(Producer<DATA> *p) {
		producers.erase(std::remove(producers.begin(), producers.end(), p), producers.end());
	}
};

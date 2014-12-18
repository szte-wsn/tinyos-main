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

#ifndef __BLOCK_HPP__
#define __BLOCK_HPP__

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
#include <functional>

class Block {
public:
	template <typename CLASS, typename DATA>
	std::function<void (const DATA&)> bind(void (CLASS::*handler)(const DATA&), CLASS *that) {
		return std::bind(handler, that, std::placeholders::_1);
	}

	template <typename DATA> class Output;

	template <typename DATA>
	class Input final {
	public:
		Input(const std::function<void (const DATA&)> &h) : handler(h), refcount(0) {
		}

		~Input() {
			if (refcount != 0)
				throw std::runtime_error("Input is not disconnected");
		}

	private:
		std::function<void (const DATA&h)> handler;
		std::atomic<int> refcount;
		std::mutex mutex;

		friend class Output<DATA>;

		void work(const DATA &data) {
			std::lock_guard<std::mutex> lock(mutex);
			handler(data);
		}

		void addref() {
			assert(refcount >= 0);
			refcount++;
		}

		void release() {
			assert(refcount > 0);
			refcount--;
		}
	};

	template <typename DATA>
	class Output final {
	public:
		~Output() {
			disconnect_all();
		}

		void send(const DATA &data) {
			std::lock_guard<std::mutex> lock(mutex);
			for(Input<DATA> *input : inputs)
				input->work(data);
		}

		void connect(Input<DATA> &input) {
			std::lock_guard<std::mutex> lock(mutex);
			inputs.push_back(&input);
			input.addref();
		}

		void disconnect(Input<DATA> &input) {
			std::lock_guard<std::mutex> lock(mutex);

			auto it = std::find(inputs.begin(), inputs.end(), &input);
			if (it == inputs.end())
				throw std::invalid_argument("Input not found");

			*it = inputs.back();
			inputs.pop_back();

			input.release();
		}

		void disconnect_all() {
			std::lock_guard<std::mutex> lock(mutex);
			for(Input<DATA> *input : inputs)
				input->release();

			inputs.clear();
		}

	private:
		std::mutex mutex;
		std::vector<Input<DATA>*> inputs;
	};
};

template <typename DATA>
void connect(Block::Output<DATA> &output, Block::Input<DATA> &input) {
	output.connect(input);
}

template <typename DATA> class Printer: public Block {
public:
	Input<DATA> in;

	Printer() : in(bind(&Printer::work, this)) {
	}

	void work(const DATA &data) {
		std::cout << data << std::endl;
	}
};

std::ostream& operator <<(std::ostream& output, const std::vector<unsigned char> &vector);

template <typename DATA> class Buffer : Block {
public:
	Input<DATA> in;
	Output<DATA> out;

	Buffer() : buffer_thread(&Buffer<DATA>::pump, this),
		in(bind(&Buffer<DATA>::work, this)) {
	}

	~Buffer() {
		{
			std::lock_guard<std::mutex> lock(buffer_mutex);
			buffer_exit = true;
			buffer_cond.notify_one();
		}
		buffer_thread.join();
	}

private:
	std::deque<DATA> queue;

	std::mutex buffer_mutex;
	bool buffer_exit = false;
	std::condition_variable buffer_cond;
	std::thread buffer_thread;

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

			out.send(data);
		}
	};

	void work(const DATA &data) {
		std::lock_guard<std::mutex> lock(buffer_mutex);
		queue.push_back(data);
		buffer_cond.notify_one();
	}
};

#endif//__BLOCK_HPP__

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

		friend class Output<DATA>;

		void work(const DATA &data) {
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

template <typename DATA> class Writer : public Block {
public:
	Input<DATA> in;

	Writer(std::ostream &stream = std::cout) : in(bind(&Writer::work, this)), stream(stream) {
	}

private:
	std::ostream &stream;
	std::mutex mutex;

	void work(const DATA &data) {
		std::lock_guard<std::mutex> lock(mutex);
		stream << data << std::endl;
	}
};

template <typename DATA> class Reader : Block {
public:
	Output<DATA> out;

	Reader(std::istream &stream = std::cin) : stream(stream) {
	}

	void start() {
		if (thread == NULL)
			thread = std::unique_ptr<std::thread>(new std::thread(&Reader<DATA>::pump, this));
	}

	~Reader() {
		if (thread != NULL)
			thread->join();
	}

private:
	std::istream &stream;
	std::unique_ptr<std::thread> thread;

	void pump() {
		stream.clear();
		while (stream.good()) {
			DATA data;
			stream >> data;
			if (!stream.fail())
				out.send(data);
			else if (!stream.eof()) {
				stream.clear();

				std::string s;
				stream >> s;
				std::cerr << "Unexpected token: " << s << std::endl;
				break;
			}
		}
	};
};

std::ostream& operator <<(std::ostream& stream, const std::vector<unsigned char> &vector);
std::istream& operator >>(std::istream& stream, std::vector<unsigned char> &vector);

template <typename DATA> class Buffer : Block {
public:
	Input<DATA> in;
	Output<DATA> out;

	Buffer() : thread(&Buffer<DATA>::pump, this),
		in(bind(&Buffer<DATA>::work, this)) {
	}

	~Buffer() {
		{
			std::lock_guard<std::mutex> lock(mutex);
			exitflag = true;
			condvar.notify_one();
		}
		thread.join();
	}

private:
	std::deque<DATA> queue;

	std::mutex mutex;
	bool exitflag = false;
	std::condition_variable condvar;
	std::thread thread;

	void pump() {
		for (;;) {
			std::unique_lock<std::mutex> lock(mutex);

			if (queue.empty()) {
				if (exitflag)
					break;

				condvar.wait(lock);

				if (exitflag)
					break;
			}

			DATA data = queue.front();
			queue.pop_front();

			lock.unlock();

			out.send(data);
		}
	};

	void work(const DATA &data) {
		std::lock_guard<std::mutex> lock(mutex);
		queue.push_back(data);
		condvar.notify_one();
	}
};

#endif//__BLOCK_HPP__

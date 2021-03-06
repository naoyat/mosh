/*
 * ByteArrayBinaryOutputPort.h - <byte-array-binary-input-port>
 *
 *   Copyright (c) 2009  Higepon(Taro Minowa)  <higepon@users.sourceforge.jp>
 *
 *   Redistribution and use in source and binary forms, with or without
 *   modification, are permitted provided that the following conditions
 *   are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  $Id: ByteArrayBinaryOutputPort.h 1301 2009-03-09 14:59:07Z higepon $
 */

#ifndef SCHEME_BYTE_ARRAY_BINARY_OUTPUT_PORT_
#define SCHEME_BYTE_ARRAY_BINARY_OUTPUT_PORT_

#include "ucs4string.h"
#include "BinaryOutputPort.h"

namespace scheme {

class ByteArrayBinaryOutputPort : public BinaryOutputPort
{
public:
    ByteArrayBinaryOutputPort();
    virtual ~ByteArrayBinaryOutputPort();

    int putU8(uint8_t v);
    int64_t putU8(uint8_t* v, int64_t size);
    int64_t putByteVector(ByteVector* bv, int64_t start = 0);
    int64_t putByteVector(ByteVector* bv, int64_t start, int64_t count);
    int open();
    int close();
    int pseudoClose();
    bool isClosed() const;
    void flush();
    ucs4string toString();
    bool hasPosition() const;
    bool hasSetPosition() const;
    Object position() const;
    bool setPosition(int64_t position);
    ByteVector* toByteVector();
    File* getFile();
    ucs4string getLastErrorMessage()
    {
        return UC("");
    }


protected:
    gc_vector<uint8_t> buffer_;
    uintptr_t position_;
    bool isClosed_;
    bool isPseudoClosed_;
};

} // namespace scheme

#endif // SCHEME_BYTE_ARRAY_BINARY_OUTPUT_PORT_

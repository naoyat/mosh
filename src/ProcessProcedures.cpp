/*
 * ProcessProcedures.cpp -
 *
 *   Copyright (c) 2008  Higepon(Taro Minowa)  <higepon@users.sourceforge.jp>
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
 *  $Id: ProcessProcedures.cpp 183 2008-07-04 06:19:28Z higepon $
 */

#ifdef _WIN32
    #include <stdlib.h>
    #include <io.h>
    #include <direct.h>
    #include <process.h>
#else
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/wait.h>
#endif
#include <sys/types.h>
#include "Object.h"
#include "Object-inl.h"
#include "Pair.h"
#include "Pair-inl.h"
#include "SString.h"
#include "scheme.h"
#include "EqHashTable.h"
#include "VM.h"
#include "ProcessProcedures.h"
#include "ProcedureMacro.h"
#include "BinaryOutputPort.h"
#include "BinaryInputPort.h"
#include "Bignum.h"
#include "OSCompat.h"


using namespace scheme;

Object scheme::currentDirectoryEx(VM* theVM, int argc, const Object* argv)
{
    DeclareProcedureName("current-directory");
    checkArgumentLength(0);
    const Object path = getCurrentDirectory();
    if (path.isFalse()) {
        callAssertionViolationAfter(theVM, procedureName, "current-directory failed", L1(getLastErrorMessage()));
        return Object::Undef;
    } else {
        return path;
    }
}

Object scheme::setCurrentDirectoryDEx(VM* theVM, int argc, const Object* argv)
{
    DeclareProcedureName("set-current-directory!");
    checkArgumentLength(1);
    argumentAsString(0, path);
    if (setCurrentDirectory(path->data())) {
        return Object::Undef;
    } else {
        callAssertionViolationAfter(theVM, procedureName, "set-current-directory! failed", L2(getLastErrorMessage(), argv[0]));
        return Object::Undef;
    }
}


Object scheme::internalForkEx(VM* theVM, int argc, const Object* argv)
{
    DeclareProcedureName("%fork");
#ifdef _WIN32
    callAssertionViolationAfter(theVM, procedureName, "can't fork");
    return Object::makeString(UC("<not-supported>"));
#else
    checkArgumentLength(0);
    const pid_t pid = fork();
    if (-1 == pid) {
        callAssertionViolationAfter(theVM, procedureName, "can't fork", L1(getLastErrorMessage()));
        return Object::Undef;
    }

//     // for Shell mode.
//     // VM(=parent) ignores SIGINT, but child use default handler
//     if (pid == 0) {
//         signal(SIGINT, SIG_DFL);
//     }
    return Bignum::makeIntegerFromU64(pid);
#endif
}

Object scheme::internalWaitpidEx(VM* theVM, int argc, const Object* argv)
{
    DeclareProcedureName("%waitpid");
#ifdef _WIN32
    callAssertionViolationAfter(theVM, procedureName, "failed");
    return Object::makeString(UC("<not-supported>"));
#else
    checkArgumentLength(1);
    argumentCheckIntegerValued(0, pid);
    MOSH_ASSERT(pid.isBignum() || pid.isFixnum());
    pid_t target;
    if (pid.isBignum()) {
        target = pid.toBignum()->toU64();
    } else {
        target = pid.toFixnum();
    }
    int status;
    pid_t child = waitpid(target, &status, 0);
    if (-1 == child) {
        callAssertionViolationAfter(theVM, procedureName, "failed", L2(argv[0], getLastErrorMessage()));
        return Object::Undef;
    }

    return theVM->values2(Bignum::makeIntegerFromU64(child),
                          Bignum::makeInteger(WEXITSTATUS(status)));
#endif
}

Object scheme::internalPipeEx(VM* theVM, int argc, const Object* argv)
{
    DeclareProcedureName("%pipe");
#ifdef _WIN32
    callAssertionViolationAfter(theVM, procedureName, "pipe() failed");
    return Object::makeString(UC("<not-supported>"));
#else
    checkArgumentLength(0);
    int fds[2];
    if (-1 == pipe(fds)) {
        callAssertionViolationAfter(theVM, procedureName, "pipe() failed");
        return Object::Undef;
    }
    const Object fds_0 = Object::makeBinaryInputPort(new File(fds[0]));
    const Object fds_1 = Object::makeBinaryOutputPort(new File(fds[1]));
    theVM->registerPort(fds_1);
    return theVM->values2(fds_0, fds_1);
#endif
}

// (%exec command args in out err)
// in : binary input port or #f. #f means "Use stdin".
Object scheme::internalExecEx(VM* theVM, int argc, const Object* argv)
{
    DeclareProcedureName("%exec");
    checkArgumentLength(5);
    argumentAsString(0, command);
    argumentCheckList(1, args);

    const Object in  = argv[2];
    const Object out = argv[3];
    const Object err = argv[4];
    if (in.isBinaryInputPort()) {
        File* file = in.toBinaryInputPort()->getFile();
        if (NULL == file) {
            callAssertionViolationAfter(theVM, procedureName, "output port is not file port", L1(argv[2]));
            return Object::Undef;
        }

        if (!file->dup(File::STANDARD_IN)) {
            callAssertionViolationAfter(theVM, procedureName, "dup failed", L1(file->getLastErrorMessage()));
            return Object::Undef;
        }
    }

    if (out.isBinaryOutputPort()) {
        File* file = out.toBinaryOutputPort()->getFile();
        if (NULL == file) {
            callAssertionViolationAfter(theVM, procedureName, "output port is not file port", L1(argv[2]));
            return Object::Undef;
        }

        if (!file->dup(File::STANDARD_OUT)) {
            callAssertionViolationAfter(theVM, procedureName, "dup failed", L1(file->getLastErrorMessage()));
            return Object::Undef;
        }
    }

    if (err.isBinaryOutputPort()) {
        File* file = err.toBinaryOutputPort()->getFile();
        if (NULL == file) {
            callAssertionViolationAfter(theVM, procedureName, "output port is not file port", L1(argv[2]));
            return Object::Undef;
        }

        if (!file->dup(File::STANDARD_ERR)) {
            callAssertionViolationAfter(theVM, procedureName, "dup failed", L1(file->getLastErrorMessage()));
            return Object::Undef;
        }
    }

    const int length = Pair::length(args);
    char** p = new(GC) char*[length + 2];
    p[0] = command->data().ascii_c_str();
    Object pair = args;
    for (int i = 1; i <= length; i++) {
        p[i] = pair.car().toString()->data().ascii_c_str();
        pair = pair.cdr();
    }
    p[length + 1] = (char*)NULL;
    const int ret = execvp(command->data().ascii_c_str(), p);

    if (-1 == ret) {
        callAssertionViolationImmidiaImmediately(theVM, procedureName, "failed", L2(argv[0], getLastErrorMessage()));
        exit(-1);
        return Object::Undef;
    }

    // this procedure doesn't return
    return Object::Undef;
}

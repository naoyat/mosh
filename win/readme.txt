
requirements
Microsoft Visual Stduio 2008 SP1

Debug    ; for debug
ReleaseT ; release(fast compile version)
Release  ; release(full optimized version)

getopt.(h|c) ; copied from PostgreSQL

precompiled binary
gmp          ; 4.1.0
onigruma     ; 5.9.1
gc           ; in mosh

ToDo:
some functions are not supported(FFI, fork, ...)
check warning by VC
run test
use onigruma in mosh repository
gmp binary is slow (without asm)
remove warning 4996 (for POSIX name) in common property

*memo
http://wiki.monaos.org/pukiwiki.php?Mosh%2F%B3%AB%C8%AF%B4%C4%B6%AD%C0%B0%A4%A8%A4%EB

getrusage => use GetSystemTimes


*how to build gc

>cd win/gc
>make_gc

*installer
win/installer/innosetup.iss
see http://www.jrsoftware.org/

<how to make setup.exe>
1. download isetup-5.2.3.exe and install
2. download http://www.jrsoftware.org/files/istrans/Japanese-5/Japanese-5-5.1.11.isl
   and save it as Japanese.isl in C:\Program Files\Inno Setup 5\Languages .
3. double click win/installer/innosetup.iss
4. bulid

*test

ok:
clos.scm
condition.scm
exception.scm
input-port.scm
io-error.scm
output-port.scm
record.scm
srfi19.scm
srfi8.scm
unicode.scm
srfi-misc.scm
input-output-port.scm

ng:
dbi.scm
ffi.scm

mysql.scm
;shell.scm
;stack-trace1.scm
;stack-trace2.scm
;stack-trace3.scm
use-foo.scm

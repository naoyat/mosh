; ffi.ss - Foreign Function Interface.
;
;   Copyright (c) 2009  Higepon(Taro Minowa)  <higepon@users.sourceforge.jp>
;
;   Redistribution and use in source and binary forms, with or without
;   modification, are permitted provided that the following conditions
;   are met:
;
;   1. Redistributions of source code must retain the above copyright
;      notice, this list of conditions and the following disclaimer.
;
;   2. Redistributions in binary form must reproduce the above copyright
;      notice, this list of conditions and the following disclaimer in the
;      documentation and/or other materials provided with the distribution.
;
;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;  $Id: ffi.ss 621 2008-11-09 06:22:47Z higepon $

;  A part of FFI functions are originally from Ypsilon Scheme by Yoshikatsu Fujita.
;  They are ported or modified for Mosh.

#|
    Title: Foreign Function Interface

    What is FFI?:
    Mosh provides a general Foreign Function Interface (FFI) methods.

    With these methods, you can load shared library, call C-function in it and get a result of function call.


    Example:
    (start code)
    ;; use mysql client library
    (let* ([libmysqlclient (open-shared-library "libmysqlclient.so.15")]
           [mysql-init     (c-function libmysqlclient void* mysql_init void*)])
      (display (mysql-init 0)))
    (end code)

    (start code)
    ;; generate png image with Cairo library.
    (import (rnrs)
            (mosh ffi))

    (let* ((libcairo (open-shared-library "libcairo.so"))
             (cairo-image-surface-create (c-function libcairo void* cairo_image_surface_create int int int))
             (cairo-surface-write-to-png (c-function libcairo int cairo_surface_write_to_png void* char*))
             (cairo-create (c-function libcairo void* cairo_create void*))
             (set-line-width (c-function libcairo void cairo_set_line_width void* double))
             (rgba (c-function libcairo void cairo_set_source_rgba void* double double double double))
             (move-to (c-function libcairo void cairo_move_to void* double double))
             (line-to (c-function libcairo void cairo_line_to void* double double))
             (TOY-show-text (c-function libcairo void cairo_show_text void* char*))
             (stroke (c-function libcairo void cairo_stroke void*)))

           (let* ((surface (cairo-image-surface-create 1 300 300))
                  (ctx (cairo-create surface)))
             (rgba ctx 1.0 1.0 1.0 1.0)
             (set-line-width ctx 8.0)
             (move-to ctx 10.0 10.0)
             (line-to ctx 10.0 290.0)
             (line-to ctx 290.0 290.0)
             (line-to ctx 290.0 10.0)
             (line-to ctx 10.0 10.0)
             (move-to ctx 100.0 150.0)
             (TOY-show-text ctx "mosh")
             (stroke ctx)
             (display (cairo-surface-write-to-png surface "test.png"))))
    (end code)

    (start code)
    ;; callback example
    (import
     (mosh)
     (mosh ffi)
     (rnrs))

    (define array (u8-list->bytevector '(6 5 3 4 1 7 2)))

    (let* ([libc (open-shared-library "libc.so.6")] ;; Ubuntu
           [qsort (c-function libc void qsort void* int int callback)]
           [compare (c-callback int (void* void*) (lambda (x y) (if (> (pointer-ref-c-uint8 x 0)
                                                                       (pointer-ref-c-uint8 y 0)) 1 0)))])
        (qsort array (bytevector-length array) 1 compare)
        (display array)
        (free-c-callback qsort))
    (end code)


    library: (mosh ffi)

    Foreign Function Interface Library
|#
(library (mosh ffi)
  (export make-c-function c-function open-shared-library find-shared-library (rename (%ffi-lookup lookup-shared-library))
          pointer->string pointer->c-function
          (rename (%ffi-supported? ffi-supported?) (%ffi-malloc malloc) (%ffi-free free))
          size-of-bool size-of-short size-of-unsigned-short size-of-int size-of-unsigned-int size-of-long size-of-unsigned-long
          size-of-long-long size-of-void* size-of-size_t size-of-pointer size-of-unsigned-long-long
          size-of-float size-of-double
          align-of-bool align-of-short align-of-int align-of-long align-of-long-long align-of-void* align-of-size_t align-of-float
          align-of-double align-of-int8_t align-of-int16_t align-of-int32_t align-of-int64_t align-of-unsigned-long-long align-of-unsigned-long
          on-darwin on-linux on-freebsd on-openbsd on-windows
          shared-errno make-c-callback c-callback free-c-callback
          make-c-callback-trampoline ;; exported for test
          make-callback-signature    ;; exported for test
          pointer?
          pointer->integer
          integer->pointer ;; temp
          pointer-set-c-int8!
          pointer-set-c-int16!
          pointer-set-c-int32!
          pointer-set-c-int64!
          pointer-set-c-uint8!
          pointer-set-c-uint16!
          pointer-set-c-uint32!
          pointer-set-c-uint64!
          pointer-ref-c-uint8
          pointer-ref-c-uint16
          pointer-ref-c-uint32
          pointer-ref-c-uint64
          pointer-ref-c-int8
          pointer-ref-c-int16
          pointer-ref-c-int32
          pointer-ref-c-int64
          pointer-ref-c-signed-char
          pointer-ref-c-unsigned-char
          pointer-ref-c-signed-short
          pointer-ref-c-unsigned-short
          pointer-ref-c-signed-int
          pointer-ref-c-unsigned-int
          pointer-ref-c-signed-long
          pointer-ref-c-unsigned-long
          pointer-ref-c-signed-long-long
          pointer-ref-c-unsigned-long-long
          pointer-ref-c-float
          pointer-ref-c-double
          pointer-ref-c-pointer
          pointer-set-c-char!
          pointer-set-c-short!
          pointer-set-c-int!
          pointer-set-c-long!
          pointer-set-c-long-long!
          pointer-set-c-float!
          pointer-set-c-double!
          pointer-set-c-pointer!
          pointer-null
          pointer-null?
          pointer-diff
          pointer-add
          pointer=?
          pointer<?
          pointer>?
          pointer<=?
          pointer>=?
          pointer<>?
          null-terminated-bytevector->string
          null-terminated-utf8->string)
  (import (only (rnrs) display define define-syntax syntax-case lambda map let syntax exists string=? string
                       quasiquote unless assertion-violation quote = length and number? assq => cdr assoc
                       for-each apply hashtable-ref unquote integer? string? ... or zero? filter list list->string case
                       for-all procedure? flonum? fixnum? cond else inexact guard file-exists? find > < >= <= not syntax-rules -
                       + case-lambda cons let* make-string char->integer integer->char if bytevector?)
          (only (rnrs mutable-strings) string-set!)
          (only (mosh) alist->eq-hash-table format os-constant host-os)
          (rename (system) (%ffi-open open-shared-library) (%ffi-make-c-callback-trampoline make-c-callback-trampoline) (%ffi-free-c-callback-trampoline free-c-callback))
          (only (system) directory-list %ffi-lookup %ffi-call
                shared-errno
                null-terminated-utf8->string
                null-terminated-bytevector->string
                pointer?
                pointer->integer
                integer->pointer ;; temp
                pointer-ref-c-signed-char
                pointer-ref-c-unsigned-char
                pointer-ref-c-signed-short
                pointer-ref-c-unsigned-short
                pointer-ref-c-signed-int
                pointer-ref-c-unsigned-int
                pointer-ref-c-signed-long
                pointer-ref-c-unsigned-long
                pointer-ref-c-signed-long-long
                pointer-ref-c-unsigned-long-long
                pointer-ref-c-float
                pointer-ref-c-double
                pointer-ref-c-pointer
                pointer-set-c-char!
                pointer-set-c-short!
                pointer-set-c-int!
                pointer-set-c-long!
                pointer-set-c-long-long!
                pointer-set-c-float!
                pointer-set-c-double!
                pointer-set-c-pointer!
                pointer-set-c-int8!
                pointer-set-c-int16!
                pointer-set-c-int32!
                pointer-set-c-int64!
                pointer-set-c-uint8!
                pointer-set-c-uint16!
                pointer-set-c-uint32!
                pointer-set-c-uint64!
                pointer-ref-c-uint8
                pointer-ref-c-uint16
                pointer-ref-c-uint32
                pointer-ref-c-uint64
                pointer-ref-c-int8
                pointer-ref-c-int16
                pointer-ref-c-int32
                pointer-ref-c-int64
                ))
#|
    Function: ffi-supported?

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (ffi-supported?)

    Returns:

      #t when ffi is supported, otherwise #f.
|#

#|
    Function: shared-errno

    When invoked with no argument, returns errno (On Windows getLastError()).
    Invoked with one argument, set value to errno.

    Prototype:
    > (shared-errno . value)

    Returns:

      errno
|#

#|
    Function: pointer?

    Returns #t if obj is pointer, otherwise #f

    Prototype:
    > (pointer? obj)

    Returns:

      #t if obj is pointer, otherwise #f
|#

#|
    Function: pointer->integer

    convert pointer to integer

    Prototype:
    > (pointer->integer pointer)

    Returns:

      integer represention of pointer.
|#

#|
    Function: pointer->string

    Returns string value at which pointer points.

    Prototype:
    > (pointer->string pointer)

    Parameters:

      pointer - integer valued pointer. When not-pointer integer is passed, it may cause crash.

    Returns:

      string value at which pointer points.
|#
(define (pointer->string pointer)
  (define nul (char->integer #\nul))
  (define (c-strlen pointer)
    (let loop ([index 0]
               [c (pointer-ref-c-signed-char pointer 0)])
      (cond
       [(= c nul) index]
       [else
        (loop (+ index 1) (pointer-ref-c-signed-char pointer (+ index 1)))])))
  (let* ([len (c-strlen pointer)]
         [str (make-string len)])
    (let loop ([i 0])
      (cond
       [(= len i) str]
       [else
        (string-set! str i (integer->char (pointer-ref-c-signed-char pointer i)))
        (loop (+ i 1))]))))

#|
    Function: open-shared-library

    Open shared library.

    Prototype:
    > (open-shared-library library)

    Parameters:

      library - Path to library.

    Returns:

      Loaded shared library object.

    Errors:
      Raise error when can't load library
|#


#|
    Function: c-function

    Make foreign c-function closure.

    Prototype:
    > (c-function lib ret func . arg)

    Parameters:

      lib - library object returned by <open-shared-library>
      ret - return type of c-function. bool, int, char, double, float, void, char*, long-long, long, unsigned-long-long, unsigned-long, unsigned-int, unsigned-short, short, size_t, uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t and void* are supported.
      func - name of c-function as symbol
      arg - list of argument types. void*, int, double and char* are supported.

    Returns:

      Foreign function closure
|#
(define-syntax c-function
  (lambda (x)
    (syntax-case x ()
      [(_ lib ret func arg ...)
       #'(make-c-function lib 'ret 'func '(arg ...)))]))

#|
    Function: make-c-callback

    Make c-callback. c-callback object should be free-ed with <<free-c-callback>>.

    Prototype:
    > (make-c-callback return-type arg-type* proc)

    Parameters:

      return-tupe - return value type as symbol. bool, void, char, short, int, long, long-long, unsigned-short, unsigned-int, unsigned-long, unsigned-long-long, int8_t, int16_t, int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t, float, double, size_t and void* are supported.
      arg-type* - arguments type as list of symbols. bool, void, char, short, int, long, long-long, unsigned-short, unsigned-int, unsigned-long, unsigned-long-long, int8_t, int16_t, int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t, float, double, size_t and void* are supported.
      proc - procedure

    Returns:

      A pointer of c-callback
|#
(define (make-c-callback ret args proc)
  (cond [(assq ret callback-return-type-alist)
         => (lambda (type)
              (make-c-callback-trampoline (cdr type)
                                          (make-callback-signature 'make-c-callback ret args proc)
                                          proc))]
        [else
         (assertion-violation 'make-c-callback (format "invalid return type ~a" ret) (list ret args proc))]))

#|
    Function: c-callback

    Make c-callback

    Prototype:
    > (c-callback return-type arg-type* proc)

    Parameters:

      return-tupe - Same as make-c-callback but should not be quoted.
      arg-type* - Same as make-c-callback but should not be quoted.
      proc - procedure

    Returns:

      A pointer of c-callback
|#
(define-syntax c-callback
  (lambda (x)
    (syntax-case x ()
      [(_ ret args proc)
       #'(make-c-callback 'ret 'args proc)])))

#|
    Function: free-c-callback

    Free c-callback object.

    Prototype:
    > (free-c-callback callback)

    Parameters:

      callback - callback object as pointer.
|#

(define (make-callback-signature name ret args proc)
  (apply string
         (map (lambda (a)
                (cond ((assq a callback-argument-type-class) => cdr)
                      (else (assertion-violation name (format "invalid argument type ~u" a) (list ret args proc)))))
              args)))

#|
    Function: malloc

    Allocate n bytes of memory. Allocated memory will never collected by GC. Use <<free>> procedure.

    Prototype:
    > (malloc n)

    Parameters:

      n - n bytes of memory to allocate.

    Returns:

      A pointer to the allocated memory.
|#

#|
    Function: free

    Frees the memory allocated by <<malloc>>.

    Prototype:
    > (free p)

    Parameters:

      p - the pointer allocated by <<malloc>.

|#

(define (find-shared-library regex)
  (exists
   (lambda (path)
     (find regex (guard [c (#t '())] (directory-list path))))
   (filter file-exists? '("/lib" "/usr/lib/" "/usr/local/lib"))))

#|
    Function: pointer->c-function

    Make foreign c-function closure from pointer.

    Prototype:
    > (pointer->c-function pointer ret-type name arg-types)

    Parameters:

      pointer - pointer to c-function which is lookuped by <<lookup-shared-library>>.
      ret-type - return type of c-function. void*, char*, void, double and int are supported.
      name - name of c-function as symbol
      arg-types- list of argument types. bool, int, char, double, float, void, char*, long-long, long, unsigned-long-long, unsigned-long, unsigned-int, unsigned-short, short, size_t, uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t and void* are supported.

    Returns:

      Foreign function closure
|#
(define (pointer->c-function pointer ret-type name arg-types)
  (let ([stub-ret-type (assoc ret-type c-function-return-type-alist)]
        [signatures (list->string (make-sigunatures arg-types))])
    (unless stub-ret-type
      (assertion-violation 'c-function "wrong return type" ret-type))
    (lambda args
      (unless (= (length arg-types) (length args))
        (assertion-violation name (format "wrong arguments number ~d required, but got ~d"
                                          (length arg-types)
                                          (length args)) args))
      (apply %ffi-call
             (cdr stub-ret-type)  ;; return type
             signatures           ;; signatures of arguments as string
             pointer              ;; function address
             args))))

(define (make-sigunatures arg-types)
  (map (lambda (arg-type)
         (case arg-type
           [(char short int long unsigned-short unsigned-int unsigned-long int8_t int16_t int32_t uint8_t uint16_t uint32_t size_t)
            #\i]
           [(int64_t uint64_t long-long unsigned-long-long)
            #\x]
           [(bool) #\b]
           [(void* char* callback) #\p]
           [(float) #\f]
           [(double) #\d]
           [else (assertion-violation 'make-sigunatures "invalid argument type" arg-type)]))
       arg-types))


#|
    Function: make-c-function

    Make foreign c-function closure by lookuping a function named "name" in "lib" library.

    Prototype:
    > (make-c-function lib ret-type name arg-types)

    Parameters:

      lib - library
      ret-type - return type of c-function. bool, int, char, double, float, void, char*, long-long, long, unsigned-long-long, unsigned-long, unsigned-int, unsigned-short, short, size_t, uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t and void* are supported.
      name - name of c-function as symbol
      arg-types- list of argument types. bool, int, char, double, float, void, char*, long-long, long, unsigned-long-long, unsigned-long, unsigned-int, unsigned-short, short, size_t, uint8_t, uint16_t, uint32_t, uint64_t, int8_t, int16_t, int32_t, int64_t and void* are supported.

    Returns:

      Foreign function closure
|#
(define (make-c-function lib ret-type name arg-types)
  (let ([func (%ffi-lookup lib name)])
    (unless func
      (assertion-violation 'c-function "c-function not found" name))
    (pointer->c-function func ret-type name arg-types)))

#|
    Function: null-terminated-bytevector->string

    Returns a newly allocated (unless empty) string whose character sequence is encoded by the given null(\0) terminated bytevector.
    This is useful for converting "C" string to Scheme string.

    (start code)
    (bytevector->string '#vu8(65 66 67 0 65 66 67) (native-transcoder)) => "ABC\x0;ABC"
    (null-terminated-bytevector->string '#vu8(65 66 67 0 65 66 67)) (native-transcoder) => "ABC"
    (end code)

    Prototype:
    > (null-terminated-bytevector->string bv transcoder)

    Parameters:

      bv - null(\0) terminated bytevector.
      transcoder - transcoder

    Returns:
      decoded string.
|#

#|
    Function: null-terminated-utf8->string

    Returns a newly allocated (unless empty) string whose character sequence is encoded by the given null(\0) terminated bytevector.
    This is useful for converting "C" string to Scheme string.

    (start code)
    (utf8->string '#vu8(65 66 67 0 65 66 67)) => "ABC\x0;ABC"
    (null-terminated-utf8->string '#vu8(65 66 67 0 65 66 67)) => "ABC"
    (end code)

    Prototype:
    > (null-terminated-bytevector->string bv transcoder)

    Parameters:

      bv - null(\0) terminated bytevector.
      transcoder - transcoder

    Returns:
      decoded string.
|#

#|
    Function: pointer-ref-c-uint16

    Get a value from pointer + offset as uint16.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as uint16.
|#
#|
    Function: pointer-ref-c-uint32

    Get a value from pointer + offset as uint32.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as uint32.
|#
#|
    Function: pointer-ref-c-uint64

    Get a value from pointer + offset as uint64.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as uint64.
|#
#|
    Function: pointer-ref-c-int8

    Get a value from pointer + offset as int8.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as int8.
|#
#|
    Function: pointer-ref-c-int16

    Get a value from pointer + offset as int16.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as int16.
|#
#|
    Function: pointer-ref-c-int32

    Get a value from pointer + offset as int32.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as int32.
|#
#|
    Function: pointer-ref-c-int64

    Get a value from pointer + offset as int64.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as int64.
|#
#|
    Function: pointer-ref-c-signed-char

    Get a value from pointer + offset as signed-char.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as signed-char.
|#
#|
    Function: pointer-ref-c-unsigned-char

    Get a value from pointer + offset as unsigned-char.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as unsigned-char.
|#
#|
    Function: pointer-ref-c-signed-short

    Get a value from pointer + offset as signed-short.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as signed-short.
|#
#|
    Function: pointer-ref-c-unsigned-short

    Get a value from pointer + offset as unsigned-short.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as unsigned-short.
|#
#|
    Function: pointer-ref-c-signed-int

    Get a value from pointer + offset as signed-int.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as signed-int.
|#
#|
    Function: pointer-ref-c-unsigned-int

    Get a value from pointer + offset as unsigned-int.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as unsigned-int.
|#
#|
    Function: pointer-ref-c-signed-long

    Get a value from pointer + offset as signed-long.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as signed-long.
|#
#|
    Function: pointer-ref-c-unsigned-long

    Get a value from pointer + offset as unsigned-long.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as unsigned-long.
|#
#|
    Function: pointer-ref-c-signed-long-long

    Get a value from pointer + offset as signed-long-long.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as signed-long-long.
|#
#|
    Function: pointer-ref-c-unsigned-long-long

    Get a value from pointer + offset as unsigned-long-long.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as unsigned-long-long.
|#
#|
    Function: pointer-ref-c-float

    Get a value from pointer + offset as float.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as float.
|#
#|
    Function: pointer-ref-c-double

    Get a value from pointer + offset as double.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as double.
|#
#|
    Function: pointer-ref-c-pointer

    Get a value from pointer + offset as pointer.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.

    Returns:
      A value from pointer + offset as pointer.
|#

#|
    Function: pointer-set-c-char!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-char! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#
#|
    Function: pointer-set-c-short!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-short! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#
#|
    Function: pointer-set-c-int!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-int! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#
#|
    Function: pointer-set-c-long!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-long! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-long-long!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-long-long! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-float!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-float! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#


#|
    Function: pointer-set-c-double!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-double! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#


#|
    Function: pointer-set-c-int8!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-int8! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-int16!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-int16! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-int32!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-int32! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-int64!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-int64! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-uint8!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-uint8! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-uint16!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-uint16! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-uint32!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-uint32! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Function: pointer-set-c-uint64!

    Returns #t when ffi is supported, otherwise #f.

    Prototype:
    > (pointer-set-c-uint64! pointer offset value)

    Parameters:

      pointer - pointer.
      offset - offset from pointer.
      value - value to set.
|#

#|
    Constant: size-of-bool

    sizeof(bool)
|#
(define size-of-bool (os-constant 'size-of-bool))

#|
    Constant: size-of-short

    sizeof(short)
|#
(define size-of-short (os-constant 'size-of-short))

#|
    Constant: size-of-unsigned-short

    sizeof(unsigned short)
|#
(define size-of-unsigned-short (os-constant 'size-of-unsigned-short))

#|
    Constant: size-of-int

    sizeof(int)
|#
(define size-of-int (os-constant 'size-of-int))

#|
    Constant: size-of-unsigned-int

    sizeof(unsigned int)
|#
(define size-of-unsigned-int (os-constant 'size-of-unsigned-int))

#|
    Constant: size-of-long

    sizeof(long)
|#
(define size-of-long (os-constant 'size-of-long))

#|
    Constant: size-of-unsigned-long

    sizeof(unsigned long)
|#
(define size-of-unsigned-long (os-constant 'size-of-unsigned-long))

#|
    Constant: size-of-unsigned-long-long

    sizeof(unsigned long long)
|#
(define size-of-unsigned-long-long (os-constant 'size-of-unsigned-long-long))

#|
    Constant: size-of-long-long

    sizeof(long long)
|#
(define size-of-long-long (os-constant 'size-of-long-long))


#|
    Constant: size-of-void*

    sizeof(void*)
|#
(define size-of-void* (os-constant 'size-of-void*))

#|
    Constant: size-of-pointer

    alias for sizeof(void*)
|#
(define size-of-pointer (os-constant 'size-of-void*))

#|
    Constant: size-of-size_t

    sizeof(size_t)
|#
(define size-of-size_t (os-constant 'size-of-size_t))

#|
    Constant: size-of-float

    sizeof(float)
|#
(define size-of-float (os-constant 'size-of-float))

#|
    Constant: size-of-double

    sizeof(double)
|#
(define size-of-double (os-constant 'size-of-double))

#|
    Constant: align-of-bool

    struct x { char y; bool z; };

    -offset-of(x, z)
|#
(define align-of-bool (os-constant 'align-of-bool))

#|
    Constant: align-of-short

    struct x { char y; short z; };

    -offset-of(x, z)
|#
(define align-of-short (os-constant 'align-of-short))

#|
    Constant: align-of-int

    struct x { char y; int z; };

    -offset-of(x, z)
|#
(define align-of-int (os-constant 'align-of-int))

#|
    Constant: align-of-long

    struct x { char y; long z; };

    -offset-of(x, z)
|#
(define align-of-long (os-constant 'align-of-long))

#|
    Constant: align-of-long-long

    struct x { char y; long long z; };

    -offset-of(x, z)
|#
(define align-of-long-long (os-constant 'align-of-long-long))

#|
    Constant: align-of-unsigned-long

    struct x { char y; unsigned long z; };

    -offset-of(x, z)
|#
(define align-of-unsigned-long (os-constant 'align-of-unsigned-long))

#|
    Constant: align-of-unsigned-long-long

    struct x { char y; unsigned-long long z; };

    -offset-of(x, z)
|#
(define align-of-unsigned-long-long (os-constant 'align-of-unsigned-long-long))

#|
    Constant: align-of-void*

    struct x { char y; void* z; };

    -offset-of(x, z)
|#
(define align-of-void* (os-constant 'align-of-void*))

#|
    Constant: align-of-size_t

    struct x { char y; size_t z; };

    -offset-of(x, z)
|#
(define align-of-size_t (os-constant 'align-of-size_t))

#|
    Constant: align-of-float

    struct x { char y; float z; };

    -offset-of(x, z)
|#
(define align-of-float (os-constant 'align-of-float))

#|
    Constant: align-of-double

    struct x { char y; double z; };

    -offset-of(x, z)
|#
(define align-of-double (os-constant 'align-of-double))

#|
    Constant: align-of-int8_t

    struct x { char y; int8_t z; };

    -offset-of(x, z)
|#
(define align-of-int8_t (os-constant 'align-of-int8_t))

#|
    Constant: align-of-int16_t

    struct x { char y; int16_t z; };

    -offset-of(x, z)
|#
(define align-of-int16_t (os-constant 'align-of-int16_t))

#|
    Constant: align-of-int32_t

    struct x { char y; int32_t z; };

    -offset-of(x, z)
|#
(define align-of-int32_t (os-constant 'align-of-int32_t))

#|
    Constant: align-of-int64_t

    struct x { char y; int64_t z; };

    -offset-of(x, z)
|#
(define align-of-int64_t (os-constant 'align-of-int64_t))

#|
    Constant: on-darwin
|#
(define on-darwin        (string=? (host-os) "darwin"))

#|
    Constant: on-linux
|#
(define on-linux         (string=? (host-os) "linux"))

#|
    Constant: on-freebsd
|#
(define on-freebsd       (string=? (host-os) "freebsd"))

#|
    Constant: on-openbsd
|#
(define on-openbsd       (string=? (host-os) "openbsd"))

#|
    Constant: on-windows
|#
(define on-windows       (string=? (host-os) "windows"))

(define callback-argument-type-class
    `((bool               . #\L)
      (char               . #\U)
      (short              . #\b)
      (int                . ,(if (= size-of-int 4) #\q #\o))
      (long               . ,(if (= size-of-long 4) #\q #\o))
      (long-long          . #\o)
      (unsigned-short     . #\B)
      (unsigned-int       . ,(if (= size-of-int 4) #\Q #\O))
      (unsigned-long      . ,(if (= size-of-long 4) #\Q #\O))
      (unsigned-long-long . #\O)
      (int8_t             . #\u)
      (int16_t            . #\b)
      (int32_t            . #\q)
      (int64_t            . #\o)
      (uint8_t            . #\U)
      (uint16_t           . #\B)
      (uint32_t           . #\Q)
      (uint64_t           . #\O)
      (float              . #\f)
      (double             . #\d)
      (size_t             . ,(if (= size-of-size_t 4) #\Q #\O))
      (void*              . #\P)))

  (define callback-return-type-alist
    '((bool               . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (void               . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (char               . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (short              . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (int                . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (long               . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (long-long          . #x01)    ; CALLBACK_RETURN_TYPE_INT64_T
      (unsigned-short     . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (unsigned-int       . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (unsigned-long      . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (unsigned-long-long . #x01)    ; CALLBACK_RETURN_TYPE_INT64_T
      (int8_t             . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (int16_t            . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (int32_t            . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (int64_t            . #x01)    ; CALLBACK_RETURN_TYPE_INT64_T
      (uint8_t            . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (uint16_t           . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (uint32_t           . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (uint64_t           . #x01)    ; CALLBACK_RETURN_TYPE_INT64_T
      (float              . #x02)    ; CALLBACK_RETURN_TYPE_FLOAT
      (double             . #x03)    ; CALLBACK_RETURN_TYPE_DOUBLE
      (size_t             . #x00)    ; CALLBACK_RETURN_TYPE_INTPTR
      (void*              . #x00)))  ; CALLBACK_RETURN_TYPE_INTPTR

  (define c-function-return-type-alist
    '((void               . #x00)    ; FFI_RETURN_TYPE_VOID
      (bool               . #x01)    ; FFI_RETURN_TYPE_BOOL
      (char               . #x0c)    ; FFI_RETURN_TYPE_INT8_T
      (short              . #x02)    ; FFI_RETURN_TYPE_SHORT
      (int                . #x03)    ; FFI_RETURN_TYPE_INT
      (long               . #x04)    ; FFI_RETURN_TYPE_INTPTR
      (long-long          . #x12)    ; FFI_RETURN_TYPE_INT64_T
      (unsigned-short     . #x05)    ; FFI_RETURN_TYPE_USHORT
      (unsigned-int       . #x06)    ; FFI_RETURN_TYPE_UINT
      (unsigned-long      . #x07)    ; FFI_RETURN_TYPE_UINTPTR
      (unsigned-long-long . #x13)    ; FFI_RETURN_TYPE_UINT64_T
      (float              . #x08)    ; FFI_RETURN_TYPE_FLOAT
      (double             . #x09)    ; FFI_RETURN_TYPE_DOUBLE
      (void*              . #x14)    ; FFI_RETURN_TYPE_POINTER
      (char*              . #x0a)    ; FFI_RETURN_TYPE_STRING
      (size_t             . #x0b)    ; FFI_RETURN_TYPE_SIZE_T
      (int8_t             . #x0c)    ; FFI_RETURN_TYPE_INT8_T
      (uint8_t            . #x0d)    ; FFI_RETURN_TYPE_UINT8_T
      (int16_t            . #x0e)    ; FFI_RETURN_TYPE_INT16_T
      (uint16_t           . #x0f)    ; FFI_RETURN_TYPE_UINT16_T
      (int32_t            . #x10)    ; FFI_RETURN_TYPE_INT32_T
      (uint32_t           . #x11)    ; FFI_RETURN_TYPE_UINT32_T
      (int64_t            . #x12)    ; FFI_RETURN_TYPE_INT64_T
      (uint64_t           . #x13)))  ; FFI_RETURN_TYPE_UINT64_T



(define pointer-null
  (integer->pointer 0))

(define (pointer-null? pointer)
  (and (pointer? pointer) (= 0 (pointer->integer pointer))))

(define (pointer-diff pointer-1 pointer-2)
  (- (pointer->integer pointer-1)
     (pointer->integer pointer-2)))

(define (pointer-add pointer offset)
  (integer->pointer (+ (pointer->integer pointer)
                       offset)))

(define-syntax define-pointer-comparison
  (syntax-rules ()
    ((_ ?name ?func)
     (define ?name
       (case-lambda
        (()
         #f)
        ((pointer)
         #t)
        ((pointer-a pointer-b)
         (?func (pointer->integer pointer-a)
                (pointer->integer pointer-b)))
        ((pointer-a pointer-b . pointers)
         (apply ?func (map pointer->integer
                           (cons pointer-a (cons pointer-b pointers))))))))))

(define-pointer-comparison pointer=? =)
(define-pointer-comparison pointer<? <)
(define-pointer-comparison pointer>? >)
(define-pointer-comparison pointer<=? <=)
(define-pointer-comparison pointer>=? >=)

(define pointer<>?
  (case-lambda
   (()
    #f)
   ((pointer . pointers)
    (not (apply pointer=? pointer pointers)))))


)

(import (rnrs)
        (mosh)
        (system)
        (mosh queue)
        (mosh concurrent)
        (mosh test))

(let ([cv (make-condition-variable)]
      [mutex (make-mutex)])
  (mutex-lock! mutex)
  (condition-variable-wait! cv mutex 1)
  (mutex-unlock! mutex)
  (test-true #t))

(let ([pid (spawn
             (lambda (x)
               (test-eqv 'hello
                         (receive
                          [('apple)
                           (test-false #t)]
                          [('greeting what)
                           what]))

               (test-equal '(some hello)
                           (receive
                            [x x]))

               (test-equal 'good
                           (receive
                            ['good 'good]))

               (test-eqv 'hello2
                         (receive
                          [('greeting what)
                           what]))

               (test-eqv 'hello3
                         (receive
                          [('greeting what)
                           what]))

               (test-equal '(a . pen)
                           (let-values ([(x y) (receive
                                                [('this 'is x y) (values x y)])])
                             (cons x y)))

               ;; timeout
               (test-eqv 'time-out
                         (receive
                          [('greeting what) what]
                          [after 1
                                 'time-out]))

               (register 'sub (self))
               ;; doesn't work yet
              (receive
                 [('register from name)
                  (! from `(ok ,name))])
              (time (receive
                 [('register from name)
                  (! from `(ok ,name))]))

               (test-results)
;               (process-exit 'normal)
;               (error 'hoge "hage")

               )
             '()
             '((rnrs) (mosh concurrent) (mosh) (mosh test))
            )])

(link pid)
(! pid '(some hello))
(! pid '(greeting hello))
(! pid '(greeting hello2))
(! pid '(greeting hello3))
(! pid 'good)
(! pid '(this is a pen))

(! pid `(register ,(self) "higepon"))

(receive
    [('ok name) (test-equal "higepon" name)])
(! 'sub `(register ,(self) "higepon"))
(receive
    [('ok name) (test-equal "higepon" name)])

(receive
    [('exit why) (test-equal 'normal why)])
(join! pid)
)

(let ([pid2 (spawn-link (lambda (arg) (error 'unknown "hogehoge2")) '() '((rnrs) (mosh concurrent)))])
  (receive
      [('exit why) (test-true (error? why))
       #;(raise why)]))

(let ([pid (spawn (lambda (arg) (test-eq 1234 arg) (test-results)) 1234 '((rnrs) (mosh test) (mosh concurrent)))])
  (join! pid))
(test-results)




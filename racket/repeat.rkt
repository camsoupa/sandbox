#lang racket

; repeatedly calls a function
; if param is null, calls function without params
(define (repeat func param times)
  (if (> times 0)
      (repeat func 
              (if (null? param)
                       (begin
                         (func)
                         null)
                       (func param))
              (- times 1))
      param))

(repeat cdr (list 1 2 3 4 5 6) 3)

(repeat (λ () (display "hi")) null 3)
;;
;; Test hash table
;;

;; $Id: hash.scm,v 1.5 2003-01-09 11:45:10 shirok Exp $

(use gauche.test)
(use srfi-1)

(test-start "hash tables")

;;------------------------------------------------------------------
(test-section "eq?-hash")

(define h-eq (make-hash-table))

(test* "make-hash-table" #t
       (hash-table? h-eq))

(test* "a => 8" 8
       (begin
         (hash-table-put! h-eq 'a 8)
         (hash-table-get  h-eq 'a)))

(test* "b => non" #t
       (hash-table-get  h-eq 'b #t))

(test* "b => error" *test-error*
       (hash-table-get h-eq 'b))

(test* "b => \"b\"" "b"
       (begin
         (hash-table-put! h-eq 'b "b")
         (hash-table-get  h-eq 'b)))

(test* "c => #\C" #\C
       (begin
         (hash-table-put! h-eq 'c #\C)
         (hash-table-get  h-eq 'c)))

(test* "c => #\c" #\c
       (begin
         (hash-table-put! h-eq 'c #\c)
         (hash-table-get  h-eq 'c)))

(test* "eq? test" 5
       (begin
         (hash-table-put! h-eq (string #\d) 4)
         (hash-table-put! h-eq (string #\d) 5)
         (length (hash-table-keys h-eq))))

(test* "hash-table-values" #t
       (lset= equal? (hash-table-values h-eq) '(8 "b" #\c 4 5)))

(test* "delete!" #f
       (begin
         (hash-table-delete! h-eq 'c)
         (hash-table-get h-eq 'c #f)))

;;------------------------------------------------------------------
(test-section "eqv?-hash")

(define h-eqv (make-hash-table 'eqv?))

(test* "make-hash-table" #t
       (hash-table? h-eqv))

(test* "a => 8" 8
       (begin
         (hash-table-put! h-eqv 'a 8)
         (hash-table-get  h-eqv 'a)))

(test* "b => non" #t
       (hash-table-get  h-eqv 'b #t))

(test* "b => error" *test-error*
       (hash-table-get  h-eqv 'b))

(test* "b => \"b\"" "b"
       (begin
         (hash-table-put! h-eqv 'b "b")
         (hash-table-get  h-eqv 'b)))

(test* "2.0 => #\C" #\C
       (begin
         (hash-table-put! h-eqv 2.0 #\C)
         (hash-table-get  h-eqv 2.0)))

(test* "2.0 => #\c" #\c
       (begin
         (hash-table-put! h-eqv 2.0 #\c)
         (hash-table-get  h-eqv 2.0)))

(test* "87592876592374659237845692374523694756 => 0" 0
       (begin
         (hash-table-put! h-eqv 87592876592374659237845692374523694756 0)
         (hash-table-get  h-eqv 87592876592374659237845692374523694756)))

(test* "87592876592374659237845692374523694756 => -1" -1
       (begin
         (hash-table-put! h-eqv 87592876592374659237845692374523694756 -1)
         (hash-table-get  h-eqv 87592876592374659237845692374523694756)))

(test* "eqv? test" 6
       (begin
         (hash-table-put! h-eqv (string #\d) 4)
         (hash-table-put! h-eqv (string #\d) 5)
         (length (hash-table-keys h-eqv))))

(test* "hash-table-values" #t
       (lset= equal? (hash-table-values h-eqv) '(8 "b" #\c -1 4 5)))

(test* "delete!" #f
       (begin
         (hash-table-delete! h-eqv 87592876592374659237845692374523694756)
         (hash-table-get h-eqv 87592876592374659237845692374523694756 #f)))

;;------------------------------------------------------------------
(test-section "equal?-hash")

(define h-equal (make-hash-table 'equal?))

(test* "make-hash-table" #t
       (hash-table? h-equal))

(test* "a => 8" 8
       (begin
         (hash-table-put! h-equal 'a 8)
         (hash-table-get  h-equal 'a)))

(test* "b => non" #t
       (hash-table-get  h-equal 'b #t))

(test* "b => error" *test-error*
       (hash-table-get  h-equal 'b))

(test* "b => \"b\"" "b"
       (begin
         (hash-table-put! h-equal 'b "b")
         (hash-table-get  h-equal 'b)))

(test* "2.0 => #\C" #\C
       (begin
         (hash-table-put! h-equal 2.0 #\C)
         (hash-table-get  h-equal 2.0)))

(test* "2.0 => #\c" #\c
       (begin
         (hash-table-put! h-equal 2.0 #\c)
         (hash-table-get  h-equal 2.0)))

(test* "87592876592374659237845692374523694756 => 0" 0
       (begin
         (hash-table-put! h-equal 87592876592374659237845692374523694756 0)
         (hash-table-get  h-equal 87592876592374659237845692374523694756)))

(test* "87592876592374659237845692374523694756 => -1" -1
       (begin
         (hash-table-put! h-equal 87592876592374659237845692374523694756 -1)
         (hash-table-get  h-equal 87592876592374659237845692374523694756)))

(test* "equal? test" 5
       (begin
         (hash-table-put! h-equal (string #\d) 4)
         (hash-table-put! h-equal (string #\d) 5)
         (length (hash-table-keys h-equal))))

(test* "equal? test" 6
       (begin
         (hash-table-put! h-equal (cons 'a 'b) 6)
         (hash-table-put! h-equal (cons 'a 'b) 7)
         (length (hash-table-keys h-equal))))

(test* "equal? test" 7
       (begin
         (hash-table-put! h-equal (vector (cons 'a 'b) 3+3i) 60)
         (hash-table-put! h-equal (vector (cons 'a 'b) 3+3i) 61)
         (length (hash-table-keys h-equal))))

(test* "hash-table-values" #t
       (lset= equal? (hash-table-values h-equal) '(8 "b" #\c -1 5 7 61)))

(test* "delete!" #f
       (begin
         (hash-table-delete! h-equal (vector (cons 'a 'b) 3+3i))
         (hash-table-get h-equal (vector (cons 'a 'b) 3+3i) #f)))

;;------------------------------------------------------------------
(test-section "string?-hash")

(define h-string (make-hash-table 'string=?))

(test* "make-hash-table" #t
       (hash-table? h-string))

(test* "\"a\" => 8" 8
       (begin
         (hash-table-put! h-string "a" 8)
         (hash-table-get  h-string "a")))

(test* "\"b\" => non" #t
       (hash-table-get  h-string "b" #t))

(test* "\"b\" => non" *test-error*
       (hash-table-get  h-string "b"))

(test* "\"b\" => \"b\"" "b"
       (begin
         (hash-table-put! h-string "b" "b")
         (hash-table-get  h-string "b")))

(test* "string=? test" 3
       (begin
         (hash-table-put! h-string (string #\d) 4)
         (hash-table-put! h-string (string #\d) 5)
         (length (hash-table-keys h-string))))

(test* "hash-table-values" #t
       (lset= equal? (hash-table-values h-string) '(8 "b" 5)))

(test* "delete!" #f
       (begin
         (hash-table-delete! h-string "d")
         (hash-table-get h-string "d" #f)))

;;------------------------------------------------------------------
(test-section "iterators")

(define h-it (hash-table 'eq?
                         '(a . 3)
                         '(c . 8)
                         '(b . 4)
                         '(d . 10)))

(test* "hash-table"
       '(a b c d)
       (hash-table-keys h-it)
       (lambda (a b) (lset= equal? a b)))

(test* "hash-table-map"
       '((a . 3) (b . 4) (c . 8) (d . 10))
       (hash-table-map h-it cons)
       (lambda (a b) (lset= equal? a b)))

(test* "hash-table-for-each"
       '((a . 3) (b . 4) (c . 8) (d . 10))
       (let ((r '()))
         (hash-table-for-each h-it (lambda (k v) (push! r (cons k v))))
         r)
       (lambda (a b) (lset= equal? a b)))

(test* "hash-table-fold"
       '((a . 3) (b . 4) (c . 8) (d . 10))
       (hash-table-fold h-it acons '())
       (lambda (a b) (lset= equal? a b)))

(test-module 'gauche.hashutil) ; autoloaded module

(test-end)

;;;
;;; gauche/listener - listerner utility
;;;
;;;  Copyright(C) 2002 by Shiro Kawai (shiro@acm.org)
;;;
;;;  Permission to use, copy, modify, distribute this software and
;;;  accompanying documentation for any purpose is hereby granted,
;;;  provided that existing copyright notices are retained in all
;;;  copies and that this notice is included verbatim in all
;;;  distributions.
;;;  This software is provided as is, without express or implied
;;;  warranty.  In no circumstances the author(s) shall be liable
;;;  for any damages arising out of the use of this software.
;;;
;;;  $Id: listener.scm,v 1.3 2002-10-23 08:01:41 shirok Exp $
;;;

;; provides functions useful to implement a repl listener

(define-module gauche.listener
  (use srfi-13)
  (export <listener>
          listener-read-handler
          listener-show-prompt
          complete-sexp?)
  )
(select-module gauche.listener)

;; Listener class
;;
;;   <listener> is a single-buffered, that is, only the input is
;;   buffered until it consists a valid S-expression.  The output
;;   is directly sent to the output port.  It's enough to handle
;;   usual situation.
;;
;;   A possible variant of <listener> is a double-buffered listener,
;;   that buffers output as well, which will be sent to the output
;;   port whenever it is ready.

(define-class <listener> ()
  ((input-port  :init-keyword :input-port  :init-form (current-input-port))
   (ouptut-port :init-keyword :output-port :init-form (current-output-port))
   (error-port  :init-keyword :error-port  :init-form (current-error-port))
   (reader      :init-keyword :reader    :init-form read)
   (evaluator   :init-keyword :evaluator :init-form eval)
   (printer     :init-keyword :printer
                :init-form (lambda args
                             (for-each (lambda (r) (write r) (newline)) args)))
   (prompter    :init-keyword :prompter
                :init-form (lambda () (display "listener> ")))
   (environment :init-keyword :environment
                :init-form (interaction-environment))
   (finalizer   :init-keyword :finalizer :init-form #f)
   (error-handler :init-keyword :error-handler
                :init-form (lambda (e) (report-error e)))
   (rbuf        :init-value "")
   ))

(define-method listener-show-prompt ((self <listener>))
  (with-output-to-port (ref self 'ouptut-port)
    (lambda ()
      ((ref self 'prompter))
      (flush))))

(define-method listener-read-handler ((self <listener>))
  (define (repl)
    (let ((istr (ref self 'rbuf)))
      (string-incomplete->complete! istr)
      (when (complete-sexp? istr)
        (with-input-from-string istr
          (lambda ()
            (with-error-handler
                (ref self 'error-handler) 
              (lambda ()
                (let* ((env  (ref self 'environment))
                       (expr ((ref self 'reader))))
                  (with-output-to-port (ref self 'ouptut-port)
                    (lambda ()
                      (call-with-values
                          (lambda () ((ref self 'evaluator) expr env))
                        (ref self 'printer)))))))
            (set! (ref self 'rbuf)
                  (port->string (current-input-port)))
            (listener-show-prompt self)
            (when (string-skip (ref self 'rbuf) #[\s]) (repl))
            )))
      ))

  (lambda ()
    (let ((chunk (read-block 8192 (ref self 'input-port))))
      (if (eof-object? chunk)
          (cond ((ref self 'finalizer) => (lambda (f) (f))))
          (begin
            (update! (ref self 'rbuf) (cut string-append <> chunk))
            (with-error-to-port (ref self 'error-port) repl)))))
  )

;; Check if the given string can be parsed as a complete sexp.
;; Note that this test doesn't rule out all invalid sexprs.
(define (complete-sexp? str)
  (with-input-from-string str
    (lambda ()
      ;; charset that delimits token
      (define special-chars #[\x00-\x20\"\'()\,\;\[\\\]\`{|}\x7f])

      ;; main loop
      (define (rec closer)
        (let1 ch (read-char)
          (cond ((eof-object? ch) (if closer #f #t))
                ((eqv? closer ch) #t)
                ((eqv? #\( ch) (and (rec #\) ) (rec closer)))
                ((eqv? #\[ ch) (and (rec #\] ) (rec closer)))
                ((eqv? #\{ ch) (and (rec #\} ) (rec closer)))
                ((eqv? #\" ch) (and (rec-escaped #\") (rec closer)))
                ((eqv? #\| ch) (and (rec-escaped #\|) (rec closer)))
                ((eqv? #\; ch) (skip-to-nl) (rec closer))
                ((eqv? #\# ch)
                 (let1 c2 (read-char)
                   (cond ((eof-object? c2) #f)
                         ((eqv? c2 #\\)
                          (and (not (eof-object? (read-char)))
                               (begin (skip-token) (rec closer))))
                         ((eqv? c2 #\/) (and (rec-escaped #\/) (rec closer)))
                         ((eqv? c2 #\[) (and (rec-escaped #\]) (rec closer)))
                         ((eqv? c2 #\,)
                          (let1 c3 (skip-ws)
                            (cond ((eof-object? c3) #f)
                                  ((eqv? #\( c3) (and (rec #\) ) (rec closer)))
                                  ((eqv? #\[ c3) (and (rec #\] ) (rec closer)))
                                  ((eqv? #\{ c3) (and (rec #\} ) (rec closer)))
                                  (else (skip-token) (rec closer)))))
                         ((eqv? c2 #\() (and (rec #\)) (rec closer)))
                         ((eqv? c2 #\<)
                          (errorf "unreadable sequence #<~a..."
                                  (read-block 10)))
                         (else (rec closer)))))
                (else (rec closer)))))
      
      (define (rec-escaped closer)
        (let1 ch (read-char)
          (cond ((eof-object? ch) #f)
                ((eqv? closer ch) #t)
                ((eqv? #\\ ch) (read-char) (rec-escaped closer))
                (else (rec-escaped closer)))))

      (define (skip-token)
        (let loop ((ch (peek-char)))
          (unless (or (eof-object? ch)
                      (char-set-contains? special-chars ch))
            (read-char)
            (loop (peek-char)))))

      (define (skip-ws)
        (let loop ((ch (read-char)))
          (if (or (eof-object? ch)
                  (char-set-contains? #[\S] ch))
              ch
              (loop (read-char)))))

      (define (skip-to-nl)
        (let loop ((ch (read-char)))
          (unless (or (eof-object? ch)
                      (eqv? ch #\newline))
            (loop (read-char)))))

      ;; body
      (rec #f)
      )))

(provide "gauche/listener")

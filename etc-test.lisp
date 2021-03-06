;;; Copyright 2020 Google LLC
;;;
;;; Use of this source code is governed by an MIT-style
;;; license that can be found in the LICENSE file or at
;;; https://opensource.org/licenses/MIT.

;;;;
;;;; Test for defglobal.
;;;;

(cl:defpackage #:ace.core.etc-test
  (:use #:common-lisp
        #:ace.core.etc
        #:ace.test))

(cl:in-package #:ace.core.etc-test)

(defglobal* *global* 10)

(deftest test-global ()
  (setf *global* 10)
  (expect (= 10 *global*))
  (setf *global* 11)
  (expect (= 11 *global*)))


;; Test that this constant will never warn.
(define-constant +truly-random-constant+ (1+ (random 6))
  :test (constantly t)
  :documentation "A truly random number. Chosen using a random generator.")

(define-constant +constant-list+ '(1 2 3 "4")
  :test #'equal
  :documentation "A constant list using equal as comparison.")

(deftest test-define-constant ()
  (expect (constantp '+truly-random-constant+))
  (expect (<= 1 +truly-random-constant+ 6))

  (expect (constantp '+constant-list+))
  (expect (equal '(1 2 3 "4") +constant-list+)))

(define-constant +42+ 42)
(define-constant +42+ 42)

(deftest test-43 ()
  (expect (= 42 +42+))
  (handler-case
      (define-constant +42+ 43)
    (error (e)
      (check e))
    (:no-error (v) (declare (ignore v))
      (check nil "Should have signaled an error.")))
  (expect (= 42 +42+)))

(define-constant +oreally?+ (random 42) :test (constantly t))
(define-constant +oreally?+ 23 :test (constantly t))

(deftest test-not-really-constant ()
  (expect (= 23 +oreally?+)))

(define-numerals
  zero one two)

(deftest test-numerals ()
  (expect (= 0 zero))
  (expect (= 1 one))
  (expect (= 2 two)))

(defstruct struct1
  a b c)

(deftest test-reader-value-bind ()
  (let ((o1 (make-struct1 :a 10 :b nil)))
    (reader-value-bind (a b c) (the struct1 o1)
      (expect (= a 10))
      (expect (not (or b c))))))

(deftest orf-test ()
  (let ((a 1))
    (expect (eq 1 (orf a 2 3)))
    (expect (eq 1 a)))
  (let ((a nil))
    (expect (eq 2 (orf a 2 3)))
    (expect (eq 2 a)))
  (let ((a (list 1 2 3)))
    (expect (eq 1 (orf (car a) 2 3)))
    (expect (eq 1 (car a))))
  (let ((c 0)
        (a (list 1 2 3)))
    (flet ((id (a) (incf c) a))
      (expect (eq 1 (orf (car (id a)) 2 (id 3))))
      (expect (eq 1 (car a)))
      (expect (= 1 c))))
  (let ((c 0)
        (a (list nil 2 3)))
    (flet ((id (a) (incf c) a))
      (expect (eq 2 (orf (car (id a)) (id 2) (id 3))))
      (expect (eq 2 (car a)))
      (expect (= 2 c))))
  (let ((c 0)
        (a (list nil 2 3)))
    (flet ((id (a) (incf c) a))
      (expect (eq 3 (orf (car (id a)) (id nil) (id 3))))
      (expect (eq 3 (car a)))
      (expect (= 3 c)))))

(deftest orf-test2 ()
  (let ((a 1)
        (b 2))
    (expect (equal '(1 2) (multiple-value-list (orf (values a b) (values 3 4)))))
    (expect (= 1 a))
    (expect (= 2 b)))
  (let ((a nil)
        (b 2))
    (expect (equal '(3 4) (multiple-value-list (orf (values a b) (values 3 4)))))
    (expect (= 3 a))
    (expect (= 4 b)))
  (let ((a nil)
        (b 2))
    (expect (equal '(nil 4) (multiple-value-list (orf (values a b) (values nil 4)))))
    (expect (eq nil a))
    (expect (= 4 b))))

(deftest andf-test ()
  (let ((a 1))
    (expect (eq 3 (andf a 2 3)))
    (expect (eq 3 a)))
  (let ((a 1))
    (expect (eq nil (andf a 2 nil)))
    (expect (eq nil a)))
  (let ((a 1))
    (expect (eq nil (andf a 2 3 nil 5)))
    (expect (eq nil a)))
  (let ((a nil))
    (expect (eq nil (andf a 2 3)))
    (expect (eq nil a)))
  (let ((a (list 1 2 3)))
    (expect (eq 3 (andf (car a) 2 3)))
    (expect (eq 3 (car a))))
  (let ((c 0)
        (a (list 1 2 3)))
    (flet ((id (a) (incf c) a))
      (expect (eq 3 (andf (car (id a)) 2 3)))
      (expect (eq 3 (car a)))
      (expect (= 1 c))))
  (let ((c 0)
        (a (list 1 2 3)))
    (flet ((id (a) (incf c) a))
      (expect (eq nil (andf (car (id a)) 2 (id 3) nil)))
      (expect (eq nil (car a)))
      (expect (= 2 c))))
  (let ((c 0)
        (a (list nil 2 3)))
    (flet ((id (a) (incf c) a))
      (expect (eq nil (andf (car (id a)) 2 (id 3))))
      (expect (eq nil (car a)))
      (expect (= 1 c))))
  (let ((c 0)
        (a (list nil 2 3)))
    (flet ((id (a) (incf c) a))
      (expect (eq nil (andf (car (id a)) 2 (id 3) nil)))
      (expect (eq nil (car a)))
      (expect (= 1 c)))))

(deftest andf-test2 ()
  (let ((a 1)
        (b 2))
    (expect (equal '(nil 4) (multiple-value-list (andf (values a b) (values nil 4)))))
    (expect (eq nil a))
    (expect (= 4 b)))
  (let ((a nil)
        (b 2))
    (expect (equal '(nil 2) (multiple-value-list (andf (values a b) (values nil 4)))))
    (expect (eq nil a))
    (expect (= 2 b)))
  (let ((a 1)
        (b 2))
    (expect (equal '(3 4) (multiple-value-list (andf (values a b) (values 3 4)))))
    (expect (= 3 a))
    (expect (= 4 b))))

(deftest test-clet ()
  (clet (things
         (a (1+ 2))
         (c (push a things)
            'foo)
         ((d) 1)
         ((a b)
          (push a things)
          (truncate a 3)))
    (declare (ignore c d))
    (expect (equal '(3 3) things))
    (expect (= a 1))
    (expect (= b 0)))
  (clet (foo)
    (check (not foo))))

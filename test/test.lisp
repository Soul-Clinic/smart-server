(in-package :smart-server/test)

(defparameter test-server (create-smartor :port 7878))


(smart+ mysql ()
  (json (apply 'concatenate 'vector (coerce (query-value-list "select name from user where id < 5") 'list))))
;; (json (destructuring-bind ((x . fields) &rest other-tables)
;;           (cl-mysql:query "select id, name, phone from user where id <= 4")
;;         (declare (ignore fields other-tables))
;;         (coerce (mapcar $(coerce * 'vector) x) 'vector))))
(smart+ postgres ()
  (query-json-objects "select id, host, extract(epoch FROM time) * 1000 as timestamp, 'Hello' as hi  from visit"))

(progn
  (setf *neverland* nil)
  ;; (smart=> "/get/it" "Hello World")

  (smart+ so-so (number name)
    (setf (content-type*) "text/json")	;; optional, client/browser will handle it intelligently
    (io "Number!!! ~a, <br/>~% 💸 Can: ~a" number name))

  (smart+ just-so (name number)
    (io "Number: ~a, <br/>~%Name: ~a" number name))


  (smart=> ("/#age/$name/#number/$love")
           just-so
           so-so
           mysql
           postgres))
;; "1234"))
;; (list :apple (io " ** 😆  ~a !!! ~a ~a zzz ~a" age number name love))))
;; 1234))

(smart=> "/$number/$name"
         just-so
         so-so
         (io "xxx~a ~a zzz" number name))
;; @next)

(start test-server)

(setf (acceptor-access-log-destination test-server) nil) ;;*standard-output*) ;; To hide the log in SLIME

(setf *show-lisp-errors-p* t)
(setf *show-lisp-backtraces-p* t)

(setf *catch-errors-p* nil) ;; Catch and stop on your slime
(setf *catch-errors-p* t)	;; Default, won't catch on your slime


(smart+ upcase (fruit* apple)
  (setf (return-code*) 400)	;; Set return code and return immediately, for user auth parsing...
  (abort-request-handler
   (io "Upcase~~ Fruit: ~a ~a" (mapcar #'string-upcase fruit*) apple)))






(smart=> ("/$apple/$fruit*")
         (io "Fruit:xxxx ~a ~a......☎️ " apple fruit*)
         upcase
         @next)


(smart=> ("/love/$xx")
         love-you)
;; Can run before the smart+, because I use: 'fn instead of #'fn !!!
(smart+ love-you (xx)
  (time (to-json (headers-in*))))

sbcl --eval="(+ 1 2 3)"

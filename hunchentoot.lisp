(ql:quickload '(:hunchentoot :postmodern :hunchentoot-test :cl-json :drakma))
(load "start")
(defpackage :web-server
  (:use :cl :hunchentoot :postmodern :celwk)
  (:nicknames :ws :server)
  (:export :start-server
           :fetch-location
           :try-fetch-location))

(in-package :web-server)
(use-package :celwk)
(load "database")
(load "location")	;; TODO: ASDF

;; (defparameter *server* (start (make-instance 'easy-acceptor :port 9990)))
(defparameter +running-servers+ nil)
(defparameter *server* nil)

(defun start-server (port)
  (push (setf *server* (start (make-instance 'easy-acceptor :port port))) +running-servers+))


;; (setf *dispatch-table* nil)  ;; For testing

(defun create-smart-dispatcher (pattern handler &optional (method :GET))
  (^(request)
    (if (find method (list :BOTH :ALL (request-method*)))
        (multiple-value-bind (params bound??)
            (compute-paremeters pattern (script-name request))
          (if bound??
              #$(apply handler params))))))	;; TODO: With non-arguments?

(defmacro define-smart-handler ((pattern method) &body body)
  `(push (create-smart-dispatcher ,pattern
                                  (^(&key ,@(route-parameter-names pattern))
                                    ,@body)
                                  ,method)
         *dispatch-table*))


(defmacro define-smart-get (pattern &body body)
  `(define-smart-handler (,pattern :GET) ,@body))

;; (defmacro combine-smart-gets (pattern &rest fns)
  
;;   (body))



(defparameter -last- (get-universal-time))
(defun $stop-request (&key (content "Error") (code +http-not-acceptable+))
  (setf (return-code*) code)
  (abort-request-handler content))



(define-smart-get "/wish/$name/#age"
  ;; (setf (content-type*) "text/json") ;; Default to text/html
  (setf (aux-request-value 'test) "Just a test") ;; A variable for next handler fot this request

  ($stop-request :content "$stop-request" :code 200) ; :content "Nothing Happen" :code 200)
  (handle-if-modified-since -last-)
  (output "Handling~%")
  (setf (header-out 'last-modified) (rfc-1123-date -last-))
  
  ;; (setf (header-out :location) "http://celwk.com")
  ;; (setf (return-code*) +http-moved-temporarily+)
  ;; (output "Abort")
  ;; (abort-request-handler)
  ;; (output "Not executed...")

  ;; (query-to-json "select * from visit"))
  ;; (no-cache) => Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0
  (input "<h1>GET: 🎉 I wish ~a is in ~a ~%~a</h1><h2>~a</h2>" name age (aux-request-value 'test)
         (query-to-json "select * from agent")))

(define-smart-get "/wish"
  "I wish you love me")


(defmacro define-smart-post (pattern &body body)
  `(define-smart-handler (,pattern :POST) ,@body))



;; 1970-01-01 00:00:00 => 2208988800000

(define-smart-post "/wish/$name/#age"
  (declare (ignore name age))
  (setf (content-type*) "text/json")
  (query-to-json "select * from visit"))
  ;; (input "POST: Wish you ~a is in ~a ~%~s" name age (pomo:query "select host, url, coalesce(to_char(time, 'YYYY/MM/DD HH24:MI:SS'), '') as date, time from visit")))

(define-smart-get "/love/$name/:xx"
  (love name xx))

;; (smart-defun love (name age)
;;   (setf (content-type*) "text/plain")
;;   (input "I love ~a at age ~a~%~a" name age (headers-in*)))

;; TODO: What about multiple functions for a single request?
;; Answer: (abort-request-handler) !

(push (create-smart-dispatcher "/yosh/$name/#age/:symbol"
                               (^(&key name age symbol)
                                 (input "name: ~a age: ~a symbol: ~a~%~a" name age symbol (headers-in* ))))
      *dispatch-table*)


(define-easy-handler (cool :uri "/cool") ((name :real-name "xx" :parameter-type 'integer))
  (declare (ignore name))
  (setf (content-type*) "text/plain")
  (set-cookie "name" :value "Savior--Can")
  (string-join (mapcar #'write-to-string 
                       (list (get-parameters*) 
                             (headers-in*)  
                             (real-remote-addr)
                             (remote-port*)
                             (headers-out*)
                             (mapcar (^(cookie) (input "~a => ~a" (car cookie) (cookie-value (cdr cookie)))) (cookies-out*))
                             (cookies-in*)
                             (query "select * from visit")
                             (string-join (mapcar #'car (query "select name from agent")) "
 ")
                             (server-protocol*)))
	(input "~%~a~%" (string-repeat "=" 100))))



(define-easy-handler (love :uri "/love") ()
  "I love you")

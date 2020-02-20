(in-package :smart-server)

(defconst @continue (gensym) "Go on for next matching route parser")
(defconst @next (always~ @continue) 
  "Go to next route parser, of course should be the end of the handler list")
(defun& @next)

(defparameter *neverland* ()
  "Global list for dispatcher, default for all acceptors, unless you set the acceptor-names
list for allowed acceptors *handlers* ")

(defclass smart-acceptor (acceptor)
  ()
  (:documentation "This is a smart acceptor, parse route more wisely than easy-acceptor ."))

(defparameter *smart-acceptors* '()
  "Global smart acceptor list, collect for testing *host* ")

(defun create-smartor (&rest args)	;; port is needed
  (push (apply #'make-instance 'smart-acceptor args) *smart-acceptors*)
  (car *smart-acceptors*))

(defmethod acceptor-dispatch-request ((smartor smart-acceptor) request)
  ;; ($output "~a~2%~a~%~%~a~&" (script-name*) (headers-in*) (headers-out*))
  (mapc (^(router)
          (multiple-value-bind (value processed)
              (call (fourth router) request)
            ;; ($output "~a~%~a" value processed)
            (when (and processed (not (eq value @continue)))
              ;; todo: Maybe optimize this when value likes:
              ;; '(200 (:content-type "text/plain") ("Hello, World")))
              ;; (output "Gonna send: ~a~%" value)
              (unless (string? value)
                (setf value (com.gigamonkeys.json:json value)))
              ;; (setf value (celwk:to-json value)))
              ;; (output "Ready => ~a~%" value)
              ;; (if (string? value) value (to-json value))
              (return-from acceptor-dispatch-request (and "😂 " value)))))
        *neverland*)
  (call-next-method))

(defmethod define-smart-route ((smartor smart-acceptor) uri &key (acceptor-names t) method  handlers)
  "URI has NO query string, handler function MUST has &KEY and &ALLOW-OTHER-KEYS"
  (setq *neverland*
        (delete-if (^(info)
                     (destructuring-bind ($uri $method $acceptor-names $handler) info
                       (declare (ignore $handler))
                       (and (string-equal uri $uri)
                            (eql method $method)
                            (or (eq acceptor-names t)
                                (intersection acceptor-names $acceptor-names)))))
                                        ; Maybe not totally equal, as long as one shared acceptor
	               *neverland*))
  `(io "~a" *neverland*)
  (insert* (list uri method acceptor-names
                 (^(request)	;; route filter 
                   (multiple-value-bind (params bound??)                 
                       (match-parameters uri (script-name request))
                     (if (and bound??
                              (or (not method) (eql method (request-method request))))
                         (let ($return)
                           (dolist (handler handlers (values $return t)) ;;go-on
                             ;; (vprint handler (fn? handler) (eql :function (bound-type handler)))
                             (setf $return (apply handler params))))
                         (values nil nil)))))
           *neverland*))

(defmacro smart+ (name (&rest keys) &body body)
  "Define function for smart router,
 whoes arguments are relative to the router arguments with same name,
 and with the data type of the prefix char"
  `(defun ,name (&key ,@keys &allow-other-keys)
     ,@body))

(defmacro smart=> (info &rest handlers)
  "Define the smart routes"
  (destructuring-bind (uri &key (acceptor '(car *smart-acceptors*)) (acceptor-names t) &allow-other-keys)
      (mklist info)
    `(define-smart-route ,acceptor ,uri
       :acceptor-names ,acceptor-names
       :handlers (list ,@(mapcar #$(if (atom? $1)
                                      (if (symbol? $1) (quoted-symbol $1) (always~ $1))
                                      `(^(&key ,@(route-parameter-names uri) &allow-other-keys) ,$1))
                                 handlers)))))

(defun delete-smart-routes (&rest uris)
  (delete-if (^(info)
               (destructuring-bind ($uri . $needless)	;; The dot rejects using #$(...)
                   info
                 (declare (ignore $needless))
                 (find $uri uris :test #'string-equal)))
             *neverland*))

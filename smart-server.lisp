(in-package :smart-server)

(defconst @continue (gensym) "Go on for next matching route parser")
(defconst @next (always~ @continue) 
  "Go to next route parser, of course should be the end of the handler list")
(defun& @next)

(defparameter *last-request* nil
  "The last request for debugging")

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

(defparameter *debug?* t)

(defmethod acceptor-dispatch-request ((smartor smart-acceptor) request)
  (and *debug?* (output+ (script-name*) (headers-in*) (headers-out*)))
  ;; (output+ "~a~2%~a~%~%~a~&" (script-name*) (headers-in*) (headers-out*))
  ;; (push *request* *last-request*)
  (let1 (begin-time (get-internal-real-time))
    (mapc (^(router)
            (multiple-value-bind (value processed)
                (call (fourth router) request)
              (when (and processed (not (eq value @continue)))
                (unless (string? value)
                  (setf value (com.gigamonkeys.json:json value)))
                (and *debug?* (output "~&Send Content:~%~A~%" value))
                (setf (header-out :duration) (input "~dms"(- (get-internal-real-time) begin-time)))
                (return-from acceptor-dispatch-request value))))
          *neverland*))
  (call-next-method))

(defmethod define-smart-route ((smartor smart-acceptor) uri &key (acceptor-names t) method handlers)
  "URI has NO query string, handler function MUST has &KEY and &ALLOW-OTHER-KEYS"
  
  (setq *neverland*
        (delete-if λ(destructuring-bind ($uri $method $acceptor-names $handler) _
                      (declare (ignore $handler))
                      ;; (vprint $uri $method $acceptor-names)
                      (and (string-equal uri $uri)
                           (eql method $method)
                           (or (eq acceptor-names t)
                               (intersection acceptor-names $acceptor-names))))
                                        ; Maybe not totally equal, as long as one shared acceptor
	               *neverland*))
  ;; (vprint *neverland*)
  (insert* (list uri method acceptor-names		;; Defined later, will be test later
                 (^(request)	;; route filter 
                   (multiple-value-bind (params bound??)                 
                       (match-parameters uri (script-name request))
                     (if (and bound??
                              (or (not method)
                                  (eql method :all)
                                  (eql method (request-method request))))
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
  (destructuring-bind (uri &key (acceptor '(car *smart-acceptors*)) (acceptor-names t) (method :get) &allow-other-keys)
      (mklist info);; (vprint uri method uri)
    `(define-smart-route ,acceptor ,uri
       :acceptor-names ,acceptor-names
       :method ,method
       :handlers (list ,@(mapcar λ(if (atom? _)
                                      (if (symbol? _)
                                          (quoted-symbol _)
                                          (always~ _))
                                      `(^(&key ,@(route-parameter-names uri) &allow-other-keys) ,_))
                                 handlers)))))

(<=> create-smartor create-land)	;; neverland
(alias land=> smart=>)
(alias land+ smart+)

(defun delete-smart-routes (&rest uris)
  (delete-if λ(destructuring-bind ($uri . $needless)
                  _
                (declare (ignore $needless))
                (find $uri uris :test #'string-equal))
             *neverland*))

#|
Test the server
(hunchentoot:start (make-instance 'hunchentoot:easy-acceptor :port 4242))
(hunchentoot-test:test-hunchentoot "http://localhost:4242")
|#

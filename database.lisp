(in-package :smart-server)

(defun connect-postgres (&key database user password host)
  (pomo:disconnect-toplevel)
  (pomo:connect-toplevel (aesthetic database) user password host))

(defmacro pooled-query ((&key database user password host) &body codes)
  `(pomo:with-connection ',(list database user password host :pooled-p t)
     ,@codes))

(defun disconnect-postgres ()
  (pomo:disconnect-toplevel)
  (pomo:clear-connection-pool))



(defmacro query-arrays (sql)
  "Rows of values only => an array for every row"
  `(json (apply 'vector (mapcar $(coerce * 'vector) (pomo:query ,sql)))))

(defmacro query-json (sql)	; postmodern + com.gigamonkeys.json
  "Rows of keys and values, an object for every row, maybe cache dynamically ?
(query-json (:select '* :from 'agent :where (:>= 'id 2) ))?"  
  `(json (apply 'vector (pomo:query ,sql :plists))))


(defparameter *query-type* :plists)

(defmacro sql=> ((&rest sql->args) type)
  "(sql~> ((:select * :from client)
           (:order-by ~ (:desc id))
           (:limit ~ 3 1))
          :alists)"
  `(progn
     (setf *query-type* ,type)	;; use (let ((*query-type* ...))) won't work ...)
     (sql-> ,@sql->args)))

(defmacro <=sql ((&rest codes<~sql) type)
  "(<~sql ((:limit ~ 3 1) 
          (:order-by ~ (:desc id))
          (:select id title :distinct :from product))
          :alists)"
  `(sql=> ,(reverse codes<~sql) ,type))

(defmacro sql-> (first &rest others)
  (unless others
    (return-from sql-> `(pomo:query ,(deep-map λ(if (or (keyword? _) (cons? _)) _ `',_) first) ,*query-type*)))
  ;; (return-from sql-> `(query-json ,(deep-map λ(if (or (keyword? _) (cons? _)) _ `',_) first))))
  (destructuring-bind (next . rest) others
    `(sql-> ,(substitute first ~ next) ,@rest)))

#|
(sql-> (:select * :from client)
       (:order-by ~ (:desc id))
       (:limit ~ 3 1))
;; (sql-> (:limit (:order-by (:select * :from client) (:desc id)) 3 1))
;; SELECT * FROM client ORDER BY id DESC) LIMIT 3 OFFSET 1
(<-sql (:limit ~ 3 1) 
       (:order-by ~ (:desc id))
       (:select id title :distinct :from product))xs
|#
(defmacro <-sql (&rest codes)
  `(sql-> ,@(reverse codes)))

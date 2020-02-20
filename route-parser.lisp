(in-package :smart-server)

(defvar +type-chars+
  `((#\# . ,'parse-integer)
    (#\% . ,'parse-float)
    (#\: . ,'read-from-string)			;; Convert to symbol.	Invert => string-downcase/upcase
    (#\$ . ,'do-urlencode:urldecode)))	;; For some non-English string like Chinese

(defun first-char (string)
  (unless (empty-string? string)
    (char string 0)))

(defun last-char (string)
  (unless (empty-string? string)
    (char string (1- (length string)))))

(defun route-parameter-names (pattern &key (spliter "/") (type 'symbol) (prefix "#%:$"))
  "(route-parameter-names `/$name/#num/hello/world/:good') => (name num good)
   (route-parameter-names `/$name/#num/hello/world/:good' :type 'key) => (:name :num :good)"
  (mapcar #$(call (if (eql type 'symbol)
                     'read-from-string
                     'symbol-to-key)
                 (subseq $1 1))
          (where #$(find (char $1 0) prefix)
                 (trim-list (split spliter pattern)))))

(defun parse-parameter (fmt str
                        &aux (name (subseq fmt 1)))
  "aa aa => t  $aa bb => (aa . \"bb\")  #aa bb => nil  #aa 123 => (aa . 123) "
  (if* (cdr (assoc (first-char fmt) +type-chars+))
       (ignore-errors
         (list (symbol-to-key name);;(read-from-string name)
               (and str
                    (call (if (list? str) 'mapcar 'call)
                          it str))))
       (string-equal fmt str)))

(defun alist-to-key-plist (alst)	;; No need
  "((age . 123) (name . 55.67)) => (:age 123 :name 55.67)"
  (mapcan #$(list (symbol-to-key (car $1)) (cdr $1)) alst))

;; http://uint32t.blogspot.com/2007/12/restful-handlers-with-hunchentoot.html

;; "Maybe not matched, return nil, else matched parameters in alist.
;;  Examples:
;;  (parse-pattern-path `/home/#next/$float/$name/:love' `/Home/886/4.234/EriK/Uncle')
;;  => ((love . uncle) (name . `EriK') (float . 4.234) (next . 886) (:path `/Home/886/4.234/EriK/Uncle') )
;;  /home/$name/:level? /home/Can  => ((name . `Can') (level . nil)) ? => optional
;;  /home/$name/:level* /home/Can  => ((name . `Can') (level . nil)) * => rest
;;  /home/$name/$level* /home/Can/1.4/2/3  => ((name . `Can') (level . '(1.4 2.0 3.0)))
;; Updated:
;; ((name . `Can') (level . nil)) => (:name `Can' :level nil)  Use alist-to-key-plist 
;;  `?|*' MUST be at end if exists, and they can exist together."

(defun parse-pattern-path (pattern path)
  " /home/$name/$level*  /home/Can/1.4/2/3  => (:name `Can' :level* '(1.4 2.0 3.0))"
  (destructuring-bind (fmts items) (mapcar #$(trim-list (split "/" $1))
                                           (list pattern path))
    (let ((min (or (position-if (bind~ #'ends-with? '("?" "*")) fmts)  ;; => #$(ends-with? '("?" "*") $1)
                   (length fmts)))
          (max (length (if (find-if (bind~ #'ends-with? "*") fmts)
                           items	;; unlimited
                           fmts)))
          ($bound-list `()))
      ;; (vprint min max items fmts)
      (when (scope? min max (length items))
        (dotimes (i (length fmts)
                  (values $bound-list t))
          (let* ((fmt (nth i fmts))
                 (str (if (ends-with? "*" fmt)
                          (nthcdr i items)
                          (nth i items))))
            ;; (vprint fmt str (parse-parameter fmt str))
            (if* (parse-parameter fmt str)
                 (or (eq t it)
                     (setf $bound-list (nconc $bound-list it)))
                 (return (values nil nil)))))))))


(build-memorized match-parameters parse-pattern-path)


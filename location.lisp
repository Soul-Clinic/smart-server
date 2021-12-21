(in-package :smart-server)

;; (defconstant +address+ (make-hash-table :test #'equal) "City location of the IP")
(defconst +app-key+ "YOUR-APP-KEY***")


(defun ip-location (ip)
  (when (string= ip "127.0.0.1")
    (return-from ip-location "本地"))
  (multiple-value-bind (binary-data code)
      (drakma:http-request #"http://api.map.baidu.com/location/ip?&ak=$[+app-key+]&ip=$[ip]"#)
    (cond ((= code +http-ok+)
           (or (ignore-errors
                (=> (octets-to-string binary-data :external-format :utf-8)
                    'parse-json
                    (gesh |content address| ~)))
               "~"))
          (:otherwise "--"))))


(defun parse-string-plist (lst)
  (if (atom? lst)
      lst
      (let ((i 0) glst)
        (dolist (x lst (nreverse glst))
          (incf i)
          (push (if (odd? i)
                    (read-from-string x)
                    (parse-string-plist x))
                glst)))))

(build-memorized fetch-location ip-location)

(defun try-fetch-location (ip &optional (timeout 1.5) (default "-"))
  "(try-fetch-location \"121.11.241.179\") => 广东 惠州 [电信]"
  (when (or (string= ip "127.0.0.1") (null? ip))
    (return-from try-fetch-location "本地IP"))
  (limit-time-call timeout 'fetch-location :default-value default :arguments (list ip)))




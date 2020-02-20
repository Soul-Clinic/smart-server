(in-package :smart-server)

;; (defconstant +address+ (make-hash-table :test #'equal) "City location of the IP")
(defconst +ip-clound-authorization+ "APPCODE ***")

(defun ip-location (ip)
  (multiple-value-bind (binary-data code)
      (drakma:http-request (input "http://jisuip.market.alicloudapi.com/ip/location?ip=~a" ip)
                           :additional-headers `((:authorization . ,+ip-clound-authorization+)))
    (when (= code +http-ok+)
      (let ((data (with-input-from-string (s (octets-to-string binary-data
                                                               :external-format :utf-8))
                    (cl-json:decode-json s))))
        (let ((result (cdr (assoc :result data))))
          (input "~{~a [~a]~}" (mapcar #$(cdr (assoc $1 result)) '(:area :type))))))))

(defun area-of-ip (ip)
  (multiple-value-bind (binary-data code)
      (drakma:http-request (input "http://jisuip.market.alicloudapi.com/ip/location?ip=~a" ip)
                           :additional-headers `((:authorization . ,+ip-clound-authorization+)))
    (when (= code +http-ok+)
      ;; (vprint (parse-json (octets-to-string binary-data :external-format :utf-8)))
      (time (>> (octets-to-string binary-data :external-format :utf-8)
                'parse-json
                'parse-string-plist
                (*~ #'fetch-plist-value ~ 'result 'area))))))

(defun ip-city (ip)
  (multiple-value-bind (binary-data code)
      (drakma:http-request (input "http://jisuip.market.alicloudapi.com/ip/location?ip=~a" ip)
                           :additional-headers `((:authorization . ,+ip-clound-authorization+)))
    (when (= code +http-ok+)
      (time (<< (fetch-plist-value ~ 'result 'area)                
                'parse-string-plist		; Or #'parse-string-plist  parse-string-plist
                'parse-json
                (octets-to-string binary-data :external-format :utf-8))))))

(defun ip-address (ip)
  (multiple-value-bind (binary-data code)
      (drakma:http-request (input "http://jisuip.market.alicloudapi.com/ip/location?ip=~a" ip)
                           :additional-headers `((:authorization . ,+ip-clound-authorization+)))
    (when (= code +http-ok+)
      (time (=> (octets-to-string binary-data :external-format :utf-8)
                'parse-json
                'parse-string-plist
                (fetch-plist-value ~ 'result 'area))))))

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

(defun fetch-plist-value (plist &rest keys &aux (x plist))
  (dolist (key keys x)
    (setf x (getf x key))))
#|
("status" 0 "msg" "ok" "result"
("ip" "123.11.241.121" "area" "河南 南阳" "type" "联通" "country" "中国" "province"
"河南" "city" "南阳" "town" :null))
(area-of-ip "123.11.241.151") => "河南 南阳"
|#

;; (output "~s~%" data)
;; (mine:vprint data)
;; ((status . 0)
;;  (msg . ok)
;;  (result (ip . 121.11.243.50) (area . 广东 惠州) (type . 电信) (country . 中国)
;;          (province . 广东) (city . 惠州) (town)))
#|
(let ((stream (drakma:http-request "https://api.github.com/orgs/edicl/public_members"
:want-stream t)))
(setf (flexi-streams:flexi-stream-external-format stream) :utf-8)
(yason:parse stream :object-as :plist))
|#

(build-memorized fetch-location ip-location)

(defun try-fetch-location (ip &optional (timeout 1.5) (default "-"))
  "(try-fetch-location \"121.11.241.179\") => 广东 惠州 [电信]"
  (limit-time-call timeout 'fetch-location :default-value default :arguments (list ip)))


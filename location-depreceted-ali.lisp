(in-package :smart-server)

;; (defconstant +address+ (make-hash-table :test #'equal) "City location of the IP")
(defconst +ip-clound-authorization+ "APPCODE 06ed284120f3474295ec9d0d8a7401e7")

(defun ip-location (ip)
  (multiple-value-bind (binary-data code)
      (drakma:http-request (input "http://jisuip.market.alicloudapi.com/ip/location?ip=~a" ip)
                           :additional-headers `((:authorization . ,+ip-clound-authorization+)))
    (cond ((= code +http-ok+)
           (let ((data (with-input-from-string (s (octets-to-string binary-data
                                                                    :external-format :utf-8))
                         (cl-json:decode-json s))))
             (let ((result (cdr (assoc :result data))))
               (input "~{~a [~a]~}" (mapcar λ(cdr (assoc _ result)) '(:area :type))))))
          (:otherwise
           "-"))))

(defun area-of-ip (ip)
  (multiple-value-bind (binary-data code)
      (drakma:http-request (input "http://jisuip.market.alicloudapi.com/ip/location?ip=~a" ip)
                           :additional-headers `((:authorization . ,+ip-clound-authorization+)))
    (when (= code +http-ok+)
      (let ((*object-type* :vector))
        (=> (octets-to-string binary-data :external-format :utf-8)
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

(build-memorized fetch-location ip-location)

(defun try-fetch-location (ip &optional (timeout 1.5) (default "-"))
  "(try-fetch-location \"121.11.241.179\") => 广东 惠州 [电信]"
  (when (or (string= ip "127.0.0.1") (null? ip))
    (return-from try-fetch-location "本地IP"))
  (limit-time-call timeout 'fetch-location :default-value default :arguments (list ip)))



(defconst +express-authorization+ "APPCODE 06ed284120f3474295ec9d0d8a7401e7")
;; curl -i --get --include 'http://kdwlcxf.market.alicloudapi.com/kdwlcx?no=780098068058&type=zto'  -H 'Authorization:APPCODE 你自己的AppCode'

;; build-memorized =>  Build a optimize version which will can set the timeout option? If there is one inside the timeout, return it, otherwise request it
;; SELECT id, status#>>'{result, list, 0, status}' as status FROM express;
(defun express-status-json (express-no &optional (type "")) 
  "https://market.aliyun.com/products/56928004/cmapi022273.html?spm=5176.2020520132.101.3.2ac27218WjGjQh#sku=yuncode1627300000
  TODO: Invoket this everyday of undone express?"
  ;; smart-server/express.api.txt
  (vprint express-no)
  (multiple-value-bind (binary-data code)
      (drakma:http-request #/http://kdwlcxf.market.alicloudapi.com/kdwlcx?no=$[express-no]&type=$[type]/#
                           :additional-headers `((:authorization . ,+express-authorization+)))
                                        ; (list (cons :authorization +express-authorization+))
    (when (= code +http-ok+)
                                        ; Maybe express fail, depends on its status
                                        ; {"status":"205","msg":"没有信息","result":{"number": "JDVC03062966736","type": "JD","list":[]}}
      (octets-to-string binary-data :external-format :utf-8))))

#|
https://market.aliyun.com/products/56928004/cmapi022273.html?spm=5176.2020520132.101.2.2ac27218YHjm6P#sku=yuncode1627300000
msg: "ok"
result:
courier: ""
courierPhone: "13202333962"
deliverystatus: "3"
expName: "中通快递"
expPhone: "95311"
expSite: "www.zto.com "
issign: "1"
list: Array(9)
0: {time: "2020-06-22 13:29:58", status: "快件已在 【惠州江北】 签收, 签收人: 保安室E架, 如有疑问请电联:（13202333962）,…雨里去, 只为客官您满意。上有老下有小, 赏个好评好不好？【请在评价快递员处帮忙点亮五颗星星哦~】"}
1: {time: "2020-06-22 06:51:11", status: "【惠州江北】 的谭海波（13202333962） 正在第1次派件, 请保持电话畅通,并耐心等待（95720为中通快递员外呼专属号码，请放心接听）"}
2: {time: "2020-06-22 06:50:05", status: "快件已经到达 【惠州江北】"}
3: {time: "2020-06-22 02:09:45", status: "快件离开 【东莞中心】 已发往 【惠州江北】"}
4: {time: "2020-06-22 00:55:45", status: "快件已经到达 【东莞中心】"}
5: {time: "2020-06-20 21:15:27", status: "快件离开 【淮安中转】 已发往 【东莞中心】"}
6: {time: "2020-06-20 21:12:41", status: "快件已经到达 【淮安中转】"}
7: {time: "2020-06-20 17:34:21", status: "快件离开 【盐城】 已发往 【淮安中转】"}
8: {time: "2020-06-20 13:35:04", status: "【盐城】（0515-88355806、0515-88339666） 的 金邦（15105108372） 已揽收"}
length: 9
__proto__: Array(0)
logo: "https://img3.fegine.com/express/zto.jpg"
number: "546501244696"
takeTime: "1天23小时54分"
type: "ZTO"
updateTime: "2020-06-22 13:29:58"
status: "0"
|#
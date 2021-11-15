(in-package :smart-server)
(defconst +express-authorization+ "APPCODE *****")
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


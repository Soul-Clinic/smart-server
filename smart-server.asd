(in-package :cl-user)

(defpackage :smart-server-asd
  (:use :cl :asdf))
(in-package :smart-server-asd)

(defsystem :smart-server
  :name "Can's Smart WebServer System"
  :version "0.1"
  :author "Can"
  :maintainer "Can EriK Lu"
  :description "Web Serevr based upon Hunchentoot"
  :long-description "More powerful than Express/Koa in node.js?"
  :depends-on (:celwk
               :hunchentoot
               :hunchensocket
               :do-urlencode
               :drakma
               :com.gigamonkeys.json
               :postmodern)
  :serial t
  :components ((:file "package")
               (:file "route-parser")
               (:file "location")
               (:file "express")
               (:file "smart-server")
               (:file "database")))

(defsystem :smart-server/test
  :description "Just for testing"
  :serial t
  :depends-on (:celwk
               :smart-server)
  :components ((:file "test/package")))
               ;; (:file "test/smart-test")))

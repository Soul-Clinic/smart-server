(in-package :cl)

(defpackage :smart-server
  (:nicknames :ws :server :smart :ss)
  (:use :cl
        :celwk
        :hunchentoot
        :hunchensocket
        :cl-ppcre
        :do-urlencode
        :flexi-streams)
  (:export #:*neverland*
           #:try-fetch-location
           #:create-smartor
           #:smart+
           #:smart=>
           #:smart-acceptor
           #:query-json-arrays
           #:query-json-objects
           #:query
           #:area-of-ip
           #:ip-location
           #:delete-smart-routes))


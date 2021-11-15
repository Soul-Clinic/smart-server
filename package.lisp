(in-package :cl)

(defpackage :smart-server	;; TODO: Change to neverland ?
  (:nicknames :server :smart :ss :neverland)
  (:use #:cl
        #:celwk
        #:hunchentoot
        #:hunchensocket
        #:cl-ppcre
        #:do-urlencode
        #:flexi-streams
        #:com.gigamonkeys.json)
  (:export #:*neverland*
           #:*smart-acceptors*
           #:*last-request*
           #:try-fetch-location
           #:express-status-json 
           #:create-smartor
           #:create-land
           #:smart+
           #:smart=>
           #:smart-acceptor
           #:land+
           #:land=>
           #:@next
           #:@continue
           #:land-acceptor
           #:ip-location
           #:delete-smart-routes
           #:connect-postgres
           #:disconnect-postgres
           #:pooled-query
           #:query-arrays
           #:query-json
           #:<-sql
           #:<=sql
           #:sql->
           #:sql=>
           #:*query-type*))


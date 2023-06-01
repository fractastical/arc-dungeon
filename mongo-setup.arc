(define m (create-mongo))
(define d (make-mongo-db m "arc-dungeon"))
(current-mongo-db d)
(define-mongo-struct post "room"
  ([id #:required]
   [description #:required]
   [exits #:set-add #:pull]
   [ascii-art #:push #:pull]
 
(define p
  (make-room #:id "starter"
             #:description "You have entered an empty room. All is dark."))

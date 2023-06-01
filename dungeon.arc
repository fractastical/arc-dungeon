(require db/mongodb)

(define (generate-room nextRoomName direction)
  (define prompt (format "Generate a room for a dungeon game in JSON format with description and exits. The room should be connected to \"~a\" from the \"~a\". Please provide the following data: room name, room description, exits (as a list of direction-room pairs), and the room position (as a x, y, z coordinate)." nextRoomName direction))

(define (game-loop current-room)
  (while t
    (display (format "You are in ~a. ~a\n"
                     (assoc-ref current-room "name")
                     (assoc-ref current-room "description")))

    (display "Exits: ")
    (for-each (lambda (exit)
                (display (format "~a: ~a, "
                                 (car exit)
                                 (cdr exit))))
              (assoc-ref current-room "exits"))
    (newline)

    (display "Where would you like to go? ")
    (let ((direction (read-line)))
      (let ((next-room (assoc direction (assoc-ref current-room "exits") eq?)))
        (if next-room
            (set! current-room (get-room-from-db next-room))  ; You need to define this function to get the room from MongoDB
            (set! current-room (generate-room next-room direction)))))))

  (define response
    (call/input-url 
      "https://api.openai.com/v1/engines/davinci-codex/completions"
      (curry post-pure-port
            `(("Authorization" . ,(format "Bearer ~a" openai-api-key))
              ("Content-Type" . "application/json"))
            (jsexpr->string `(("prompt" . ,prompt) ("max_tokens" . 200))))
      port->string))
  
  (define roomData
    (with-handlers ([exn:fail? (lambda (exn) (displayln "Invalid JSON format") #f)])
      (string->jsexpr (alist-ref 'text (string->jsexpr response) eq?))))

  (define required-fields '("name" "description" "exits" "position"))
  (unless (andmap (lambda (field) (assoc field roomData eq?)) required-fields)
    (displayln "Missing required field")
    #f)


  (define nextRoom `(("name" . ,(assoc-ref roomData "name"))
                     ("description" . ,(assoc-ref roomData "description"))
                     ("exits" . ,(assoc-ref roomData "exits"))
                     ("position" . ,(assoc-ref roomData "position"))))

  ;; Then save `nextRoom` in MongoDB
  nextRoom)

(define (generate-room nextRoomName direction)
  (define prompt (format "Generate a room for a dungeon game in JSON format with description and exits. The room should be connected to \"~a\" from the \"~a\". Please provide the following data: room name, room description, exits (as a list of direction-room pairs), and the room position (as a x, y, z coordinate)." nextRoomName direction))

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

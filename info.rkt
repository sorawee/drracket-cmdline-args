#lang info
(define collection "drracket-cmdline-args")
(define deps '("drracket-plugin-lib"
               "gui-lib"
               "shlex"
               "base"))
(define build-deps '("scribble-lib" "racket-doc"))
(define scribblings '(("scribblings/drracket-cmdline-args.scrbl" ())))
(define pkg-desc "Command-line arguments for DrRacket")
(define version "0.0")
(define pkg-authors '(sorawee))

(define drracket-tool-names (list "Command-line arguments"))
(define drracket-tools (list (list "tool.rkt")))

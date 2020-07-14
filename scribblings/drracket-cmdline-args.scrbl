#lang scribble/manual
@require[@for-label[racket/base]
        racket/runtime-path]

@title{drracket-cmdline-args: Accessible Command-Line Arguments for DrRacket}
@author[@author+email["Sorawee Porncharoenwase" "sorawee.pwase@gmail.com"]]

This DrRacket plugin adds a text field to DrRacket
for inputting command-line arguments.
The command-line arguments then will be available via the parameter
@racket[current-command-line-arguments].

Note that it requires users to run a program for a change to take its effect in
the interactions window.

The current limitation of this plugin is that it only works with @hash-lang[]
languages. It will not work with HtDP languages, for example.
The background color of the text field will turn yellow to warn that
the command-line arguments have no effect in this case.

When there is a syntax error (unterminated quote or escape code),
the background color of the text field will turn red, and
@racket[current-command-line-arguments] will be set to @racket[#()].

@(define-runtime-path screenshot "screenshot.png")

@image[screenshot]{The screenshot of the plugin}

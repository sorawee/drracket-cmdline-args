#lang racket/base
(require drracket/tool
         shlex
         framework
         racket/class
         racket/match
         racket/gui/base
         racket/unit
         mrlib/panel-wob)
(provide tool@)

(define DRRACKET-CMDLINE-ARGS:SHOW 'drracket-cmdline-args:show)
(define DRRACKET-CMDLINE-ARGS:VALUE 'drracket-cmdline-args:value)

(preferences:set-default DRRACKET-CMDLINE-ARGS:SHOW
                         #t
                         boolean?)

(preferences:set-default DRRACKET-CMDLINE-ARGS:VALUE
                         ""
                         string?)

(define warning-color
  (if (white-on-black-panel-scheme?)
      "olive"
      "yellow"))

(define error-color
  (if (white-on-black-panel-scheme?)
      "firebrick"
      "pink"))

(define container #f)
(define menu-item #f)
(define text-field #f)

(define tool@
  (unit
    (import drracket:tool^)
    (export drracket:tool-exports^)

    (define drracket:preferences
      (drracket:language-configuration:get-settings-preferences-symbol))

    (define unit-frame-mixin
      (mixin (drracket:unit:frame<%>) ()
        (super-new)
        (inherit get-show-menu
                 get-definitions-text)

        (define/private (update-config! xs)
          (match-define (drracket:language-configuration:language-settings language settings)
            (send (get-definitions-text) get-next-settings))

          ;; here's a poor man's way to detect whether languages support
          ;; current-command-line-arguments
          ;; (*SL for instance does not support it).
          (match (send language marshall-settings settings)
            [(list simple-settings
                   collection-paths
                   (vector (? string?) ...)
                   auto-text
                   compilation-on?
                   full-trace?
                   submodules-to-run
                   enforce-module-constraints)

             (define setting-val
                (send language unmarshall-settings
                      (list simple-settings
                            collection-paths
                            (list->vector xs)
                            auto-text
                            compilation-on?
                            full-trace?
                            submodules-to-run
                            enforce-module-constraints)))

              ;; somehow, set-next-settings on setting-val directly won't work.
              ;; workaround the issue by preferences:set it first and then
              ;; preferences:get
              (preferences:set
               drracket:preferences
               (drracket:language-configuration:language-settings
                language
                setting-val))

              (send (get-definitions-text)
                    set-next-settings
                    (preferences:get drracket:preferences))]

            [_ (send text-field set-field-background
                     (make-object color% warning-color))]))

        (define/private (update-text-field!)
          (define s (send text-field get-value))
          (preferences:set DRRACKET-CMDLINE-ARGS:VALUE s)
          (with-handlers ([exn:fail:read:eof?
                           (λ (ex)
                             (send text-field
                                   set-field-background
                                   (make-object color% error-color))
                             (update-config! '()))])
            (define xs (split s))
            (send text-field set-field-background #f)
            (update-config! xs)))

        (define/private (update-gui!)
          (send menu-item set-label
                (if (preferences:get DRRACKET-CMDLINE-ARGS:SHOW)
                    "Hide Command-Line Arguments"
                    "Show Command-Line Arguments"))

          (cond
            [(preferences:get DRRACKET-CMDLINE-ARGS:SHOW)
             (set! text-field
                   (new text-field%
                        [label "Command-line arguments"]
                        [parent container]
                        [init-value (preferences:get DRRACKET-CMDLINE-ARGS:VALUE)]
                        [callback
                         (λ (t e) (update-text-field!))]))
             (send container change-children
                   (λ (xs) (cons text-field (remove text-field xs))))
             (update-text-field!)]
            [else
             (when text-field
               (send container delete-child text-field)
               (set! text-field #f))]))

        (define/augment (on-tab-change _1 _2)
          (when (preferences:get DRRACKET-CMDLINE-ARGS:SHOW)
            (update-text-field!)))

        (define/override (get-definitions/interactions-panel-parent)
          (set! container (super get-definitions/interactions-panel-parent))
          (set! menu-item
                (new menu-item%
                     [label ""]
                     [callback
                      (λ (c e)
                        (cond
                          [(preferences:get DRRACKET-CMDLINE-ARGS:SHOW)
                           (preferences:set DRRACKET-CMDLINE-ARGS:SHOW #f)]
                          [else (preferences:set DRRACKET-CMDLINE-ARGS:SHOW #t)])
                        (update-gui!))]
                     [parent (get-show-menu)]))
          (update-gui!)
          container)))

    (define phase1 void)
    (define phase2 void)
    (drracket:get/extend:extend-unit-frame unit-frame-mixin)))

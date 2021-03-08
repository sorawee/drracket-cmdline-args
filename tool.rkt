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

(define tool@
  (unit
    (import drracket:tool^)
    (export drracket:tool-exports^)

    (define drracket:preferences
      (drracket:language-configuration:get-settings-preferences-symbol))

    (define unit-frame-mixin
      (mixin (drracket:unit:frame<%>) ()

        (define text-field #f)
        (define show? (preferences:get DRRACKET-CMDLINE-ARGS:SHOW))
        (define value (preferences:get DRRACKET-CMDLINE-ARGS:VALUE))

        (super-new)
        (inherit get-show-menu get-definitions-text)

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
          (set! value s)
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

        (define/private (update-gui! container)
          (cond
            [show?
             (unless text-field
               (set! text-field
                     (new text-field%
                          [label "Command-line arguments"]
                          [parent container]
                          [init-value value]
                          [callback (λ (t e) (update-text-field!))]))
               (send container change-children
                     (λ (xs) (cons text-field (remove text-field xs))))
               (update-text-field!))]
            [else
             (when text-field
               (send container delete-child text-field)
               (set! text-field #f))]))

        ;; we can potentially switch to non-module tab, so we need to update
        ;; the text field background
        (define/augment (on-tab-change _1 _2)
          (when show? (update-text-field!)))

        (define/override (get-definitions/interactions-panel-parent)
          (define container (super get-definitions/interactions-panel-parent))
          (new menu-item%
               [label ""]
               [demand-callback
                (λ (self)
                  (send self set-label
                        (if show?
                            "Hide Command-Line Arguments"
                            "Show Command-Line Arguments")))]
               [callback
                (λ (c e)
                  (set! show? (not show?))
                  (preferences:set DRRACKET-CMDLINE-ARGS:SHOW show?)
                  (update-gui! container))]
               [parent (get-show-menu)])
          (update-gui! container)
          container)))

    (define phase1 void)
    (define phase2 void)
    (drracket:get/extend:extend-unit-frame unit-frame-mixin)))

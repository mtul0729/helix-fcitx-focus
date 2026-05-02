(require "helix/components.scm")
(require "helix/editor.scm")
(require "helix/misc.scm")
(#%require-dylib "libhelix_fcitx_focus"
  (only-in fcitx-save
           fcitx-close
           fcitx-save-and-close
           fcitx-restore))

;; Cache Helix's insert-mode value once, so later predicates do not depend on
;; string comparisons or repeated mode construction.
(define insert-mode (string->editor-mode "insert"))

;; Helix exposes modes as opaque mode values, so compare against the cached
;; insert-mode value instead of comparing strings.
(define (insert-mode? mode)
  (equal? mode insert-mode))

;; Terminal focus can return while Helix is still in insert mode. In that case
;; restoring is better than blindly closing fcitx; otherwise normal/select mode
;; should always force English.
(define (close-or-restore-fcitx)
  (if (insert-mode? (editor-mode))
      (fcitx-restore)
      (fcitx-close)))

;; Mode switches implement the main Vim-style behavior:
;; leaving insert records the current input method and closes it, while entering
;; insert restores the recorded input method only if it was active before.
(register-hook 'on-mode-switch
  (lambda (event)
    (let ([old-mode (mode-switch-old event)]
          [new-mode (mode-switch-new event)])
      (cond
        [(and (insert-mode? old-mode) (not (insert-mode? new-mode)))
         (fcitx-save-and-close)]
        [(and (not (insert-mode? old-mode)) (insert-mode? new-mode))
         (fcitx-restore)]))))

;; Dynamic components receive terminal focus events. This supplements the mode
;; hook because switching windows does not necessarily change Helix's mode.
(define (handle-fcitx-focus-event _ event)
  (cond
    [(focus-gained-event? event)
     (close-or-restore-fcitx)
     event-result/ignore]
    [(and (focus-lost-event? event) (insert-mode? (editor-mode)))
     ;; If focus leaves while still in insert mode, remember the active input
     ;; method but do not close it. The next focus-gained event can restore it.
     (fcitx-save)
     event-result/ignore]
    [else event-result/ignore]))

;; Reloading init.scm may evaluate this file again. Remove the previous dynamic
;; component first so focus events do not run the handler multiple times.
(pop-last-component-by-name! "fcitx-focus")
(push-component!
  (new-component!
    "fcitx-focus"
    #f
    #f
    (hash "handle_event" handle-fcitx-focus-event)))

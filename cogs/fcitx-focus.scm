(require "helix/editor.scm")
(require "helix/misc.scm")
(#%require-dylib "libhelix_fcitx_focus"
  (only-in fcitx-save
           fcitx-save-external
           fcitx-close
           fcitx-save-and-close
           fcitx-restore
           fcitx-restore-external))

;; Restore the input method state that was active before Helix gained focus.
;; Disable this if you prefer Helix's forced-English state to remain active
;; after switching away.
(define restore-external-on-focus-lost? #t)

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

;; Terminal focus supplements the mode hook because switching windows does not
;; necessarily change Helix's mode.
(register-hook 'terminal-focus-gained
  (lambda ()
    (fcitx-save-external)
    (close-or-restore-fcitx)))

(register-hook 'terminal-focus-lost
  (lambda ()
    ;; If focus leaves while still in insert mode, remember the active input
    ;; method but do not close it. The next focus-gained event can restore it.
    (when (insert-mode? (editor-mode))
      (fcitx-save))
    (when restore-external-on-focus-lost?
      (fcitx-restore-external))))

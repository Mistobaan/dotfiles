;;;
;;;; Keys binding
;;;;
;;(global-set-key 'delete                    'delete-char)
;;(global-set-key '(control h)               'delete-backward-char)

;(global-set-key '(meta control down)       'end-of-defun)
;(global-set-key '(meta control left)       'backward-sexp)
;(global-set-key '(meta control right)      'forward-sexp)
;(global-set-key '[(control x) (control r)] 'revert-buffer)

;(global-set-key '(kp-left)                 'scroll-left)
;(global-set-key '(kp-right)                'scroll-right)
;(global-set-key '(kp-up)                   'scroll-up)
;(global-set-key '(kp-down)                 'scroll-down)

;(global-set-key 'f4                        'next-error)
;(global-set-key 'f7                        'my-manual-entry)
;(global-set-key 'f8                        'ispell-region)
;(global-set-key 'f9                        'repeat-complex-command)
;(global-set-key 'f10                       'grep)
;(global-set-key 'f5                        'compile)
;(global-set-key '(control f11)             'compile-current-buffer)
;(global-set-key 'f12                       'dl-find-other-file-bis)

;(global-set-key '(button3)                 'imouse-drag-display)
;(global-set-key '(control button3)         'popup-mode-menu)
;(global-set-key '(meta control button1)    'my-mouse-track-kill)

;(global-set-key 'kp-subtract               'kill-this-line )

;(if (equal system-type `windows-nt)
;    (progn 
;      (global-set-key '(button1)         'my-windows-mouse-track-and-copy-to-clipboard)
;      (global-set-key '(button2)         'my-windows-mouse-yank)
 ;     )
;    (progn 
;      (global-set-key '(button1)         'mouse-track-and-copy-to-cutbuffer)
;      )
;  )


;(add-hook 
; 'c-mode-common-hook 
; '(lambda()

    ;; Set TAB key to indent at beginning of line, insert TAB
    ;; elsewhere.
;    (setq c-tab-always-indent nil)

    ;; Enter key reindents
;    (define-key c-mode-map '(control m)
;      'reindent-then-newline-and-indent)
;    (define-key c-mode-map '(return)
;      'reindent-then-newline-and-indent)
;    (define-key c++-mode-map '(control m)
;      'reindent-then-newline-and-indent)
;    (define-key c++-mode-map '(return)
;      'reindent-then-newline-and-indent)
;    (define-key c++-mode-map '(control meta N)
;      'c++-align-parameters)
;    (define-key c++-mode-map '(control meta S)
;      'c++-align-data-members)
;    )
; )
	  

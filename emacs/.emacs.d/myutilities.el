;; Miscellaneous Utilities
;; =======================

;;
;;  Chose right mode for each file extension
;;
(setq auto-mode-alist
      (append '(("\\.h$" . c++-mode)
		("\\.c?$" . c++-mode)
		("\\.C?$" . c++-mode)
		("\\.cpp$" . c++-mode)
		("\\.cc$" . c++-mode)
		("\\.hh$" . c++-mode)
		("\\.mk$" . makefile-mode)
		("\\.options$" . makefile-mode)
		("\\.h@@/main/.*$" . c++-mode)
		("\\.c@@/main/.*$" . c++-mode)
		("\\.C@@/main/.*$" . c++-mode)
		("\\.cpp@@/main/.*$" . c++-mode)
		("\\.cc@@/main/.*$" . c++-mode)
		("\\.hh@@/main/.*$" . c++-mode)
		("\\.mk@@/main/.*$" . makefile-mode)
		("\\.options@@/main/.*$" . makefile-mode)
		("\\<Makefile.gen$" . makefile-mode)
		)
	      auto-mode-alist))

;;
;; Auto-saving
;;
(setq auto-save-interval 7500)

;;
;; Various settings
;;

;; Emacs knows nothing about terms
(setenv "TERM" "dumb")

;; Always have line and column numbers
(line-number-mode 1)
;;(display-column-mode 1)
;;(require 'paren)
;;(paren-set-mode 'paren)

;; Always add finale newline
;; Always inser spaces instead of tabs 
(setq-default require-final-newline t)
;;(setq indent-tabs-mode    nil)
;;(turn-on-pending-delete)
(setq default-buffer-file-coding-system `undecided-unix)

;; (if (equal system-type `windows-nt)
;;    ()
;;  (progn
(setq find-file-compare-truenames t)
(setq find-file-use-truenames t)

;; ))

;; Use iswitchb
;(iswitchb-default-keybindings)

;;
;; Customize C/C++ mode
;;
(add-hook 
 'c-mode-common-hook 
 '(lambda()
    
    ;; Maximum decoration
    (setq font-lock-maximum-decoration t)

    ;; Turn on auto-fill and hungry-delete minor modes
    (c-toggle-auto-hungry-state 1)

    ;; Set tab width to 4
    (setq tab-width 2)

    )
 )

;;
;; Disable motion-hook in compile-mode
;;
;(add-hook 
; 'compilation-mode-hook 
; '(lambda()
    
    ;; Maximum decoration
;    (setq mode-motion-hook nil)
;  )
;)

;;
;; Enables font-locking.
;;
(add-hook 'emacs-lisp-mode-hook 'turn-on-font-lock)
(add-hook 'lisp-mode-hook       'turn-on-font-lock)
(add-hook 'c-mode-hook          'turn-on-font-lock)
(add-hook 'c++-mode-hook        'turn-on-font-lock)
(add-hook 'perl-mode-hook       'turn-on-font-lock)
(add-hook 'tex-mode-hook        'turn-on-font-lock)
(add-hook 'texinfo-mode-hook    'turn-on-font-lock)
(add-hook 'postscript-mode-hook 'turn-on-font-lock)
(add-hook 'dired-mode-hook      'turn-on-font-lock)
(add-hook 'ada-mode-hook        'turn-on-font-lock)

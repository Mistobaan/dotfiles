;;
;; Customisations
;;   --Fabrice Jaubert
;;

;; Compilation command
(global-set-key "\M-s" 'compile)

;; Make the sequence "C-x w" execute the `what-line' command, 
;; which prints the current line number in the echo area.
;; And print line number too.
(global-set-key "\C-xw" 'what-line)
(line-number-mode 1)

;; Consider all .h and .inc files are C++
(setq auto-mode-alist
      (append '(("\\.h$" . c++-mode)
		("\\.c?$" . c++-mode)
		("\\.C?$" . c++-mode)
		("\\.cpp$" . c++-mode)
		("\\.cc$" . c++-mode)
		("\\.hh$" . c++-mode)
		("\\.hpp$" . c++-mode)
		("\\.mk$" . makefile-mode)
		("\\.options$" . makefile-mode)
		("\\.pl$" . cperl-mode)
		("\\.perl$" . cperl-mode)
		)
	      auto-mode-alist))

;; Tell cc-mode not to check for old-style (K&R) function declarations.
;; This speeds up indenting a lot.
(setq c-recognize-knr-p nil)

;; reset terminal: avoids garbage in shell windows
(setenv "TERM" "dumb")

;; Basic offset is 4 chars, in keeping with Avid coding standards
(setq c-basic-offset 4)

;; And make the tabs 4 chars wide
(setq-default tab-width 4)

;; Don't indent the brace if it is on its own line
(c-set-offset 'substatement-open 0)

;; No stupid ^M end-of-line anywhere, please!
(setq default-buffer-file-coding-system 'iso-latin-1-unix)

;; Key for switching between source and header files
(global-set-key [f12]                       'fj-find-other-file)

;; Other useful key bindings
(global-set-key "\M-g" 'goto-line)
(global-set-key [end] 'end-of-line)
(global-set-key [\C-end] 'end-of-buffer)
(global-set-key [home] 'beginning-of-line)
(global-set-key [\C-home] 'beginning-of-buffer)

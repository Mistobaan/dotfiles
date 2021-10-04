;;------------------------------------------------------------------------------
(add-to-list 'load-path "~/.emacs.d")
(load "~/.emacs.d/fjAbbrevs")
(load "~/.emacs.d/fjFileUtils")
(load "~/.emacs.d/fjUtils")
(load "~/.emacs.d/dlStyleGuide.el")
(load "~/.emacs.d/iswitch-buffer.el")
(load "~/.emacs.d/igrep")
(load "~/.emacs.d/python-mode.el")
(load "~/.emacs.d/auto-complete-config.el")
(load "~/.emacs.d/go-autocomplete.el")

;;------------------------------------------------------------------------------
;; TAB to indent while programming

(defun indent-or-expand (arg)
  "Either indent according to mode, or expand the word preceding point."
  (interactive "*P")
  (if (and
       (or (bobp) (= ?w (char-syntax (char-before))))
       (or (eobp) (not (= ?w (char-syntax (char-after))))))
      (dabbrev-expand arg)
    (indent-according-to-mode)))

(defun my-tab-fix ()
  (local-set-key [tab] 'indent-or-expand))

(setq auto-mode-alist
      (cons '("SConstruct" . python-mode) auto-mode-alist))
(setq auto-mode-alist
      (cons '("SConscript" . python-mode) auto-mode-alist))
 
; automatic completion
(setq c-tab-always-indent nil)
(setq-default indent-tabs-mode nil)
(setq c-insert-tab-function '(lambda () (call-interactively 'dabbrev-expand)))

(add-hook 'c-mode-hook          'my-tab-fix)
(add-hook 'c++-mode-hook          'my-tab-fix)
(add-hook 'python-mode-hook     'my-tab-fix)

(if (>= emacs-major-version 23)
    (set-default-font "Monospace-16"))

;; Define the return key to avoid problems on MacOS X
;(define-key function-key-map [return] [13])

(define-key global-map "\C-c\C-v" 'uncomment-region)
 (defun uncomment-region (beg end)
  "...Uncomment selected region"
  (interactive "r")
  (comment-region beg end -1))

(defun show-whitespace () "Show tabs and trailing whitespace"
  (if (not (eq major-mode 'Buffer-menu-mode))
      (setq font-lock-keywords
            (append font-lock-keywords
                    '(("[\t]+"  (0 'tab-face t))
                      ("[ \t]+$" (0 'trailing-space-face t)))))))

;; hilight tabs and useless trailing whitespace
;; make a face for tabs

;;(make-face 'tab-face)
;;(make-face 'trailing-space-face)
;;(set-face-background 'tab-face "Gray15")
;;(set-face-background 'trailing-space-face "Gray25")

(add-hook 'font-lock-mode-hook 'show-whitespace) 

;; Matching paren highlight
(show-paren-mode t)
(setq blink-matching-paren t)

(setq default-frame-alist
      '((top . 200) (left . 400)
       (width . 80) (height . 48)
        (cursor-color . "white")
        (cursor-type . box)
        (foreground-color . "gray75")
        (background-color . "gray25")
     ;   (font . "-*-courier-*-*-*-*-20-*-*-*-*-*-*-*")
))

;;------------------------------------------------------------------------------
(require 'iswitch-buffer)

;;------------------------------------------------------------------------------

(setq auto-mode-alist (cons '("\\.py$" . python-mode) auto-mode-alist))
(setq interpreter-mode-alist (cons '("python" . python-mode)
                                   interpreter-mode-alist))
(autoload 'python-mode "python-mode" "Python editing mode." t)
(global-font-lock-mode t)
(setq font-lock-maximum-decoration t)

;;------------------------------------------------------------------------------
;; Turn off most GUI items

(menu-bar-mode nil)
(tool-bar-mode nil)
(scroll-bar-mode nil)


(transient-mark-mode 1)

(mouse-wheel-mode t)

;; ========== Place Backup Files in Specific Directory ==========

;; Enable backup files.
(setq make-backup-files t)

;; Enable versioning with default values (keep five last versions, I think!)
(setq version-control t)

;; Save all backup file in this directory.
;;(setq backup-directory-alist (quote ((".*" . "~/.emacs_backups/"))))

;; ========== Enable Line and Column Numbering ==========

;; Show line-number in the mode line
(line-number-mode 1)

;; Show column-number in the mode line
(column-number-mode 1)

;; ========== Set the fill column ==========

;; Enable backup files.
(setq-default fill-column 72)

;; ===== Turn on Auto Fill mode automatically in all modes =====

;; Auto-fill-mode the the automatic wrapping of lines and insertion of
;; newlines when the cursor goes over the column limit.

;; This should actually turn on auto-fill-mode by default in all major
;; modes. The other way to do this is to turn on the fill for specific modes
;; via hooks.

(setq auto-fill-mode 1)

(setq blink-matching-paren t)

(global-set-key [f7] 'compile) 
(global-set-key [f6] 'next-error) 


(add-to-list 'load-path (expand-file-name "~/.emacs.d/scripts/"))
(load "pyrex-mode")

(setq tab-width 4)
(setq indent-tabs-mode nil)

(line-number-mode 1)
(column-number-mode 1)
(setq make-backup-files nil)
(setq auto-mode-alist (cons '("\\.pyx\\'" . pyrex-mode) auto-mode-alist)) 
(setq auto-mode-alist (cons '("\\.pxd\\'" . pyrex-mode) auto-mode-alist)) 
(setq auto-mode-alist (cons '("\\.pxi\\'" . pyrex-mode) auto-mode-alist))
(put 'narrow-to-region 'disabled nil)


;; Xrefactory configuration part ;;
;; some Xrefactory defaults can be set here
(defvar xref-current-project nil) ;; can be also "my_project_name"
(defvar xref-key-binding 'global) ;; can be also 'local or 'none
(setq load-path (cons "~/.emacs.d/xref/emacs" load-path))
(setq exec-path (cons "~/.emacs.d/xref" exec-path))
(load "xrefactory")
;; end of Xrefactory configuration part ;;
(message "xrefactory loaded")


(load "~/.emacs.d/cmake-mode.el")
(load "~/.emacs.d/go-mode-load.el")
(load "~/.emacs.d/go-mode.el")


;; Autocomplete 
(require 'go-autocomplete)
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d//ac-dict")
(ac-config-default)
(define-key ac-mode-map (kbd "M-TAB") 'auto-complete)


; Start the Server
(server-start)


;; -*- mode: lisp-interaction -*-
;;
;; Author: Martin Blais
;; Date: 2000-06-29 15:28:10 blais

;;
;; External declarations.
;;

;;
;; Integration of dlValidate script with emacs.
;;

(defvar dl-validate-program "dlValidate"
  "Name of program to run for validation.")

(defvar dl-validate-args "--errors"
  "Arguments for program to run for validation.")

(defvar dl-validate-files "*.h *.cpp"
  "Files to list for to validation program.  If set to `nil', insert the visited
buffer file name.")

(defun dl-validate-compile ()
  "Runs the validation command."
  (interactive)
  (if (buffer-modified-p (current-buffer))
      (map-y-or-n-p
       (format "Save file %s? " (buffer-file-name (current-buffer)))
       (function (lambda (buffer) (save-buffer)))
       (list (current-buffer))))
  (let ((compile-command 
	 (concat dl-validate-program " " dl-validate-args " " 
		 (if dl-validate-files
		     dl-validate-files
		   (buffer-file-name))
		 ;;(buffer-file-name)
		 )))
    (call-interactively 'compile)) )

(defvar dl-validate-compile-error-regexp
 (list 
  "\\(ERROR\\|WARNING\\|REMARK\\) File = \\([^,\n]+\\), Line = \\([0-9]+\\)" 
  2 3)
 "Regexp for parsing validate script output.")


;;
;; Add regexp for compilation buffer parsing of dlValidate error messages.
;;
(require 'compile)
(add-to-list 'compilation-error-regexp-alist
	     dl-validate-compile-error-regexp)


;;
;; Access bindings.
;;

(defun dl-validate-setup-keys ()
  "Key setup for dlValidate eilsp functions"
  (local-set-key [(control c)(?7)] 'dl-validate-compile) )

;; Let the user bind the keys if he wants to.  Like this:
;;(add-hook 'c-mode-common-hook 'dl-validate-setup-keys)



;; Provide the package.
(provide 'dlValidate)

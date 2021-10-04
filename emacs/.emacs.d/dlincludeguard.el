;;; -*- mode: lisp-interaction -*-
;;*****************************************************************************/
;; Copyright (c) 2001 Discreet Logic, Inc.
;;
;; These coded instructions, statements, and computer programs contain
;; unpublished proprietary information written by Discreet Logic and
;; are protected by Federal copyright law. They may not be disclosed
;; to third parties or copied or duplicated in any form, in whole or
;; in part, without the prior written consent of Discreet Logic.
;;*****************************************************************************/

;;
;; This package adds some include guard smarts.
;;

;; Use it like this in your .emacs:
;; (require 'dlIncludeGuard)
;; (add-hook 
;;  'c-mode-common-hook 
;;  '(lambda()
;;     (local-set-key [(control c)(i)] 'dl-update-include-guard)))


(defun dl-split-include-filename (filename)
  "Splits the components of an include filename in the toxik vobs and splits
it returning a list of (layer package filename)."

  (let ((strd "\\([^/]+\\)")
	(strn "\\([^/.]+\\)"))
    (cond
     ((string-match
       (concat "^" strn "/" strn "/" "\\(src\\|test\\)" "/" strd "$") filename)
      (list (match-string 1 filename)
	    (match-string 2 filename)
	    (match-string 4 filename)))

     ((string-match
       (concat "^" strn "/" strn "/" strd "$") filename)
      (list (match-string 1 filename)
	    (match-string 2 filename)
	    (match-string 3 filename)))

     ((string-match
       (concat "^" strn "/" strd "$") filename)
      (list (match-string 1 filename)
	    nil
	    (match-string 2 filename)))

     ((string-match
       (concat "^" strd "$") filename)
      (list nil
	    nil
	    (match-string 1 filename)))
     )))

(defun dl-find-next-include-guard ()
  "Find the next include line and returns a pair with the include filename and
the point to the beginning of the line of the include directive."

  (save-excursion
    (beginning-of-line)
    (re-search-forward "#\\s-*include\\s-*[\"\<]\\(.*\\)[\"\>]\\s-*$")
    (goto-char (match-beginning 1))
    (list
     (buffer-substring-no-properties (match-beginning 1) (match-end 1))
     (line-beginning-position))))

(defun dl-update-include-guard ()
  "Updates or corrects the include guard around #include directive which is
around point."
  (interactive)

  (let* ((minc (dl-find-next-include-guard))
	 (sinc (car minc))
	 (begpos (cadr minc))
	 (ps (dl-split-include-filename sinc))
	 (layer (car ps))
	 (std (not layer))
	 ;;(package (cadr ps))
	 (file (caddr ps))
	 (sfile nil)
	 (tag nil)
	 (prefix "DL_INCL_")
	 (rbeg begpos)
	 (rend nil)
	 )
    (save-excursion
      
      (goto-char begpos)
      (setq rend (line-end-position))
      
      ;;
      ;; Find the whole the include guard region to replace.
      ;;
      (if (and 
	   (re-search-backward "^#\s-*ifndef[^\n]*\n[\s-\n]*" (- rbeg 500) t)
	   (equal (match-end 0) rbeg))
	  (setq rbeg (match-beginning 0)))

      ;; Skip the std define.
      (goto-char rend)
      (if (and 
	   (re-search-forward "[\s-\n]*#\s-*define[^\n]*$" (+ rend 500) t)
	   (equal (match-beginning 0) rend))
	  (goto-char (setq rend (match-end 0)))
	(goto-char rend) )

      (if (and 
	   (re-search-forward "[\s-\n]*#\\s-*endif[^\n]*$" (+ rend 500) t)
	   (equal (match-beginning 0) rend))
	  (setq rend (match-end 0)))
      ) ;; save-excursion

      (if (not layer)
	  (setq layer "std"))
      
      (setq sfile
	    (let ((trname (upcase (file-name-sans-extension file))) )
	      (if (string-match "\\." trname)
		  (replace-match "_" nil t trname)
		trname)))
      
      (setq tag (concat prefix (upcase layer) "_" sfile))

      ;; Insert the whole thing.
      (delete-region rbeg rend) 
      (goto-char rbeg)

      (insert "#ifndef " tag "\n")
      (insert "#include <" sinc ">\n")
      (if std (insert "#define " tag "\n") )
      (insert "#endif")

      ;; Move the cursor back onto include line.
      (previous-line 1)
      (beginning-of-line)
    ))


(provide 'dlIncludeGuard)

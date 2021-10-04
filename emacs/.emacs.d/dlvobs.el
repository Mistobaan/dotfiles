;;; -*- mode: lisp-interaction -*-
;;*****************************************************************************/
;; Copyright (c) 1999,2000 Discreet Logic, Inc.
;;
;; These coded instructions, statements, and computer programs contain
;; unpublished proprietary information written by Discreet Logic and
;; are protected by Federal copyright law. They may not be disclosed
;; to third parties or copied or duplicated in any form, in whole or
;; in part, without the prior written consent of Discreet Logic.
;;*****************************************************************************/

;;
;; The dl-vobs package allows you to find vob files more easily.
;;

(defvar dl-vobs-find-file-vobs
  (list "/vobs/ng/nucleus/src")
  "List of [vob] roots to try when loading a file using dl-vobs-find-file.
To add your own project, add the following to your .emacs:

(add-to-list 'dl-vobs-find-file-vobs \"/vobs/ng/your_project/src\")
")

(defun dl-vobs-search-filename (filename)
  "If the given include filename exists, returns it, otherwise look for in a
list of vobs and layers.  If it isn't found there, return nil, otherwise return
the full found filename."
  ;; Also look for layers.
  (let ((foundlist nil))
    (cond 
     ((file-exists-p filename) filename)
     ((setq foundlist
	    (filter 
	     (lambda (x) (file-exists-p (concat x "/" filename)))
	     (filter
	      (lambda (x) 
		(and (file-directory-p x) 
		     (not (equal (file-name-nondirectory x) "lost+found"))
		     (not (equal (file-name-nondirectory x) "makefiles"))))
	      (apply 'append
		     dl-vobs-find-file-vobs
		     (mapcar 
		      (lambda (x) (directory-files x 'fullname "[^.]$" 'nosort))
		      dl-vobs-find-file-vobs)))))
      (concat (car foundlist) "/" filename))
     (nil)) ))

(defun dl-vobs-split-filename (filename)
  "Splits the components of a filename in the nextgen vobs and splits it
returning a list of (vobs layer package filename)."
  ;; Expand name if this is a link
  (while (file-symlink-p filename)
    (setq filename 
	  (expand-file-name (file-symlink-p filename) 
			    (file-name-directory filename))))
  ;; Match interesting components of it.
  (if (string-match "/vobs/ng/\\([^/]+\\)/src/\\([^/]+\\)/\\(.*\\)$" filename)
      (let ((vob (match-string 1 filename))
	    (layer (match-string 2 filename))
	    (package nil)
	    (file (match-string 3 filename)))
	(if (or (string-match "\\([^/]+\\)/src/\\([^/]+\\)" file)
		(string-match "\\([^/]+\\)/test/\\([^/]+\\)" file)
		(string-match "\\([^/]+\\)/\\([^/]+\\)" file) )
	    (progn
	      (setq package (match-string 1 file))
	      (setq file (match-string 2 file)) ))
	(list vob layer package file)) ))

(defun dl-vobs-query-file-name (filename)
  "Interactive query of filename for DL vobs."
  (interactive "FDL file: ")
  (let ((dname nil))
    (cond ((and (setq dname (dl-vobs-search-filename filename))
		(file-directory-p dname) )
	    (read-file-name "DL file (bis): " (concat dname "/")))
	  (dname dname)
	  ((message "File not found in DL vobs, sorry.") filename)) ))

(defun dl-vobs-find-file ()
  "find-file for discreet vobs.

If the file doesn't exist, look for filename appended to a predefined list of
vob roots, and search into layers as well.  This allows you to load up a file
using a \"LAYER/...\" or \"PACKAGE/...\" syntax.  Recommended binding:

 (global-set-key [(control c) (control x) (control f)] 'dl-vobs-find-file)

Note: when a directory is entered, this function will set the current path in
the requested directory instead of opening the directory."
  (interactive)
  (find-file (call-interactively 'dl-vobs-query-file-name)))

(defun dl-vobs-find-file-other-frame (filename)
  "find-file-other-frame for discreet vobs.
See dl-vobs-find-file description for details."
  (interactive)
  (find-file-other-frame (call-interactively 'dl-vobs-query-file-name)))

(defun dl-vobs-find-alternate-file ()
  "find-alternate-file for discreet vobs.
See dl-vobs-find-file description for details."
  (interactive)
  (find-alternate-file (call-interactively 'dl-vobs-query-file-name)))

(defun dl-vobs-insert-file (filename)
  "insert-file for discreet vobs.
See dl-vobs-find-file description for details."
  (interactive)
  (insert-file (call-interactively 'dl-vobs-query-file-name)))

(defun dl-vobs-insert-include (filename)
  "Asks the user for a filename to include, with completion, and inserts the
appropriate include guard for that file, at point."
  (interactive "FDL include file: ")
  ;; FIXME todo, add support for STD includes.
  (let* ((dname nil)
	 (foundname (call-interactively 'dl-vobs-query-file-name))
	 (complist (dl-vobs-split-filename foundname))
	 (vob (car complist))
	 (layer (car (cdr complist)))
	 (package (car (cddr complist)))
	 (file (car (cddr (cdr complist)))) )
  
    (insert "#ifndef DL_INCL_" (upcase layer)
	    "_" (let ((trname 
		       (upcase (file-name-sans-extension file))) )
		  (if (string-match "\\." trname)
		      (replace-match "_" nil t trname)
		    trname)) "\n")
    (insert "#include <" layer "/" file ">\n")
    (insert "#endif\n") ))

;(defun dl-include-fill-layer ()
;  "Call this on an include line with \"#include <file.h>\" and the layer prefix
;will be added automagically."
;  (interactive)
;  
;  (dl-vobs-find-file-vobs
;  

(provide 'dlVobs)

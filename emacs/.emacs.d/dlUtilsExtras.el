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

;;; TODO:
;;; - redefine dl-find-other-file to use ff-find-other-file if on a line that
;;;   contains an include directive

(require 'dlUtils)

;; We need basic functional programming primitives!
(if (not (fboundp 'filter))
    (defun filter (pred list)
	"Returns a list of all the elements fulfilling the pred requirement 
(that is for which (pred elem) is true)"
  (if list
	(let ((head (car list))
	      (tail (filter pred (cdr list))))
	  (if (funcall pred head)
	      (cons head tail)
	      tail)))))


(if (not (string-match "20\.3" emacs-version))
    (progn

      (require 'find-file)
      
      (defun dl-find-other-file-bis ()
	"Cycles through the header, inline, implementation and source files
of a given component.  If the cursor is on a line that contains an 
include directive, search for that file instead (similar to 
ff-find-other-file)."
	(interactive)
	(save-excursion
	  (beginning-of-line 1)
	  (setq speccc (ff-treat-as-special)))
	(if (not (eq speccc nil))
	    ;; call normal algo
	    (ff-find-other-file)
	  (dl-find-other-file)))

      ))

(defvar dl-c++-file-extensions
  '(".h" ".inline.h" ".imp.h" ".cpp" ".y" ".lex" ".res")
  "List of extensions to look for when searching for related files")

(defun dl-lex-file-p ( file-name )
  "Returns true if the given file name is a lex tokenizer file."
  (string-match "\\.lex$" file-name))

(defun dl-yacc-file-p ( file-name )
  "Returns true if the given file name is a yacc grammar file."
  (string-match "\\.y$" file-name))

(defun dl-res-file-p ( file-name )
  "Returns true if the given file name is a Dante resources file."
  (string-match "\\.res$" file-name))

(defun dl-is-c++-filename (lfn)
  "Returns true if this file has the Discreet Logic C++ file extensions."
  (or (dl-header-file-p lfn)
      (dl-inline-file-p lfn)
      (dl-imp-file-p lfn)
      (dl-source-file-p lfn)
      (dl-lex-file-p lfn)
      (dl-yacc-file-p lfn)
      (dl-res-file-p lfn) ))


(defun dl-file-name-sans-extension (filename)
  "Return FILENAME sans final \"extension\"
The extension, in a file name, is the part that follows the last `.',
or without an ending .imp.h, .inline.h"
  (let ((lfn filename))
    (if (or (dl-inline-file-p lfn)
	    (dl-imp-file-p lfn))
	(setq lfn (file-name-sans-extension filename)))
    (file-name-sans-extension lfn)))

(defun dl-find-other-file-mouse-menu (event)
  (interactive "e")
  (dl-find-other-file-mouse-menu-imp event 'find-file))
      
(defun dl-find-other-file-mouse-menu-alternate (event)
  (interactive "e")
  (dl-find-other-file-mouse-menu-imp event 'find-alternate-file))
      
(defun dl-find-other-file-mouse-menu-imp (event find-func)
  (if (buffer-file-name)
      (progn
	(let* ((fname (file-name-nondirectory 
		       (dl-file-name-sans-extension (buffer-file-name))))
	       (dir (file-name-directory (buffer-file-name)))
	       (filelist nil)
	       (filemenu nil)
	       (title "Related files")
	       (tag-prefix "   "))
	  (progn 
	    ;; Build list of existing filenames
	    (mapcar 
	     (function 
	      (lambda (ext)
		(if (file-exists-p (concat dir fname ext))
		    (setq filelist 
			  (append filelist
				  (list (concat tag-prefix fname ext))))
		  ;; also peek in the src directory
		  (if (file-exists-p (concat dir "src/" fname ext))
		      (setq filelist
			    (append filelist 
				    (list (concat tag-prefix "src/" fname ext))))
		    ))))
	     dl-c++-file-extensions)
		  
	    ;; Check which files are already loaded and insert a tag in the name
	    ;; if so
	    (mapcar 
	     (function
	      (lambda (name)
		(if (get-buffer (substring name 3))
		    (store-substring name 1 "*"))
		))
	     filelist)
		  
	    ;; Note: we could use easymenu.el to help portability here.
	    ;; Build menu
	    (if filelist
		(progn
		  (if (string-match "GNU Emacs" (emacs-version))
			    
		      ;; GNU emacs
		      (progn 
			(setq filemenu
			      (list title (cons ""
						(mapcar (function 
							 (lambda (i) (cons i i)))
							filelist))))
			(let ((chosen (x-popup-menu event filemenu)))
			  (if chosen
			      (funcall find-func (substring chosen 3)))
			  )
			)

		    ;; Xemacs
		    (progn 
		      (setq filemenu
			    (append (list title)
				    (mapcar (function 
					     (lambda (i) 
					       (vconcat 
						(list i (list 'find-file i) t))))
					    filelist)))
		      ;; Aarrrg!  FIXME There's a bug here, I can't get it
		      ;; to load the freakin' file!

		      ;; Call menu
		      (popup-menu filemenu)
		      )
		    )))
	    )
	  )
	)
    ))


(defun dl-realign-variables ()
  "Aligns the variables in a parameter declaration list between parentheses."
  (interactive)
  (save-excursion
    (let ((end-pos (search-forward ")" (+ 1000 (point))))
	  (start-pos (search-backward "(" (- 2000 (point))))
	  (offset-list nil)
	  (max-offset nil)
	  )
      (next-line 1)
      (end-of-line)
      (while (< (point) end-pos)
	(re-search-backward "=" (line-beginning-position) t)
	(backward-char 1)
	(backward-sexp)
	(re-search-backward "\\S-" (line-beginning-position))
	(forward-char 1)
	(setq offset-list 
	      (append offset-list 
		      (list (current-column))))
	(next-line 1)
	(end-of-line)
	)
      (defun maxl (lis)
	(if lis
	    (max (car lis) (maxl (cdr lis)))
	  0
	  ))
      (setq max-offset (+ 1 (maxl offset-list)))
      (goto-char start-pos)
      (mapcar (function (lambda (posit)
			  (next-line 1)
			  (move-to-column posit)
			  (delete-horizontal-space)
			  (indent-to max-offset) ))
	      offset-list) )))


(defun dl-insert-trace-variable (varname)
  "Inserts a trace statement for tracing a variable"
  (interactive "sInsert trace variable: ")
  ;;(indent-according-to-mode)
  (insert (concat 
	   "DL_TRACE_MAIN( \"" varname "=\" << " varname " );\n")))


(defun dl-file-to-string (file &optional oneline args)
  "Read the content of FILE and return it as a string.
If ONELINE is t, only the first line (no \\n) will be returned.
If ARGS is non-nil, the file will be executed with ARGS as its
arguments.  If ARGS is not a list, no argument will be passed."
  (let ((tmp-buf (generate-new-buffer "tmp")))
    (prog1
	(save-excursion
	  (set-buffer tmp-buf)
	  (condition-case nil
	      (progn
		(if args
		    (apply 'call-process
			   file nil t nil (when (listp args) args))
		  (insert-file-contents file))
		(goto-char (point-min))
		(buffer-substring (point)
				  (if oneline
				      (progn (end-of-line) (point))
				    (point-max))))
	    (file-error nil)))
      (kill-buffer tmp-buf))))

(defun dl-guess-branch ()
  "Guess which branch this process is running in.  If not running within a
clearcase view, returns nil."
  (let ((proc-output (dl-file-to-string "DL_guess_branch" t t)))
    (if (and proc-output 
	     (string-match "cleartool" proc-output)
	     (string-match "Error" proc-output))
	nil
      proc-output)))


(defvar dl-comment-headers-big-c
  '("DOCUMENTATION" 
    "CLASS "
    "FORWARD DECLARATIONS"
    "EXTERNAL DECLARATIONS"
    ;; "TYPEDEFS"
    ;; "GLOBAL FUNCTIONS"
    ;; "MACROS"
    ;; "NAMESPACE "
    )
  "Legal comment headers for big Discreet Logic C-style headers.")

(defvar dl-comment-headers-big-c++
  '("EXTERNAL DECLARATIONS" 
    "FORWARD DECLARATIONS"
    "LOCAL DECLARATIONS" 
    "LOCAL FUNCTIONS" 
    "LOCAL CLASS " 
    "PUBLIC FUNCTIONS" 
    "CLASS "
    "TEMPLATE INSTANTIATIONS"
    "TEMPLATE SPECIALISATIONS"
    "EXTERNAL DECLARATIONS"
    ;; "MAIN PROGRAM"
    ;; "MACROS"
    )
  "Legal comment headers for big Discreet Logic C++-style headers.")

(defvar dl-comment-headers-small
  '("constants"
    "types and enumerations"
    "classes"
    "static member functions"
    "member functions"
    "data members"
    "function prototypes"
    "friends"
    "variables")
  "Legal comment headers for small Discreet Logic C-style headers.")

(defun dl-insert-big-comment-header (name)
  "Inserts a discreet comment header at the cursor.  With prefix arg 0,
inserts a big C-style comment header, with prefix arg 1, inserts a big
C++-style comment header, with prefix arg 2, insert a small separator 
comment."
  (interactive 
   (list 
    (completing-read 
     "Header:" 
     (mapcar 'list
	     (cond ((or (equal current-prefix-arg nil) 
			(equal current-prefix-arg 1))
		    dl-comment-headers-big-c)
		   ((equal current-prefix-arg 2)
		    dl-comment-headers-big-c++)
		   ((equal current-prefix-arg 3) 
		    dl-comment-headers-small)))
     nil)
    ))
  (cond ((or (equal current-prefix-arg nil) 
	     (equal current-prefix-arg 1))
	 (progn 
	   (beginning-of-line)
	   (insert "/*") (insert-char ?= 78) (insert "\n")
	   (insert " * \n" )
	   (insert " *") (insert-char ?= 76) (insert "*/\n")
	   (previous-line 2)
	   (end-of-line)
	   ))
	((equal current-prefix-arg 2)
	 (progn 
	 (beginning-of-line)
	 (insert "//") (insert-char ?= 78) (insert "\n")
	 (insert "// \n" )
	 (insert "//") (insert-char ?= 78) (insert "\n")
	 (previous-line 2)
	 (end-of-line)
	 ))
	((equal current-prefix-arg 3)
	 (progn 
	 (indent-for-tab-command)
	 (insert "/*-----  -----*/\n")
	 (backward-char 9)
	 ))
	)
  (insert name))


(defvar dl-auto-mode-alist
  '(("\\.mk$" . makefile-mode)
    ("\\.options$" . makefile-mode)
    ("\\.h@@/main/.*$" . c++-mode)
    ("\\.c@@/main/.*$" . c++-mode)
    ("\\.C@@/main/.*$" . c++-mode)
    ("\\.cpp@@/main/.*$" . c++-mode)
    ("\\.cc@@/main/.*$" . c++-mode)
    ("\\.hh@@/main/.*$" . c++-mode)
    ("\\.y@@/main/.*$" . c-mode)
    ("\\.lex@@/main/.*$" . c-mode)
    ("\\.mk@@/main/.*$" . makefile-mode)
    ("\\.options@@/main/.*$" . makefile-mode)
    ("\\<Makefile.gen$" . makefile-mode))
    "Auto-mode alist of discreet file types")

;; Copyright stuff
;; ---------------

(defvar dl-copyright-beginning-year 1997
  "Beginning year that copyright notices should start from, if nothing else.")

(defun dl-update-copyright ()
  "Searches for a discreet copyright notice at the top of the file and if
one is found there, updates it with the current date-range, unless the current
date-range already contains the current year, in which case we assume it has
already been updated appropriately.  Return value is 't if replacement occured.
If there was no year found in the copyright notice, this functions uses
dl-copyright-beginning-year instead."
  (interactive)
  (save-excursion
    (let ((curyear (nth 5 (decode-time))))
      (beginning-of-buffer)
      (if (search-forward-regexp 
	   "Copyright (\\(c\\|C\\)) \\(.*\\) Discreet" 
	   (save-excursion (goto-line 10) (point)) t)
	  (if (not (string-match 
		    (number-to-string curyear) (match-string 2)))
	      (progn
		(let ((dmb (match-beginning 2))
		      (dme (match-end 2))
		      (me 0)
		      (ll nil)
		      (minele nil)
		      (sss (match-string 2))
		      (smallest-year nil))
		  ;; Find out the smallest year.
		  (while (string-match "[0-9][0-9][0-9][0-9]" sss me)
		    (add-to-list 'll (string-to-number (match-string 0 sss)))
		    (setq me (match-end 0)))
		  (setq smallest-year (if ll (apply 'min ll) 
					dl-copyright-beginning-year))

		  ;; Apply the change
		  (delete-region dmb dme)
		  (goto-char dmb)
		  (insert (concat smallest-year "-" curyear)) 
		  )
		't))) )))

(defvar dl-vobs-find-file-vobs
  (list "/vobs/ng/nucleus/src")
  "List of [vob] roots to try when loading a file using dl-vobs-find-file.
To add your own project, add the following to your .emacs:

(add-to-list 'dl-vobs-find-file-vobs \"/vobs/ng/your_project/src\")
")

(defun dl-vobs-find-file (filename)
  "find-file for discreet people.

If the file doesn't exist, look for filename appended to a predefined list of
vob roots, and search into layers as well.  This allows you to load up a file
using a \"LAYER/...\" or \"PACKAGE/...\" syntax.  Recommended binding:

 (global-set-key [(control c) (control x) (control f)] 'dl-vobs-find-file)

Note: when a directory is entered, this function will set the current path in
the requested directory instead of opening the directory."
  (interactive "FDL Find file: ")
  (let ((dname nil))
    (find-file
     (cond ((and (setq dname (dl-vobs-search-filename filename))
		 (file-directory-p dname) )
	    (read-file-name "DL Find file (bis): " (concat dname "/")))
	   (dname dname)
	   ((message "File not found in DL vobs, sorry.") filename)) )))
  
(defun dl-vobs-find-alternate-file (filename)
  "find-alternate-file for discreet people.
See dl-vobs-find-file description for details."
  (interactive "FDL Find file: ")
  (let ((dname nil))
    (find-alternate-file
     (cond ((and (setq dname (dl-vobs-search-filename filename))
		 (file-directory-p dname) )
	    (read-file-name "DL Find file (bis): " (concat dname "/")))
	   (dname dname)
	   ((message "File not found in DL vobs, sorry.") filename)) )))

(defun dl-vobs-search-filename (filename)
  "If the given filename exists, returns it, otherwise look for in a list of
vobs and layers.  If it isn't found there, return nil, otherwise return the full
found filename."
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


(defun dl-group-region (beg end)
  "Inserts grouping markers around the region."
  (interactive "r")
  (save-excursion
    (progn
      (goto-char end)
      (or (equal (current-column) 0)
	  (beginning-of-line))
      (open-line 1)
      (insert " // </group>")
      (indent-according-to-mode)

      (goto-char beg)
      (beginning-of-line)
      (open-line 1)
      (insert " // <group>")
      (indent-according-to-mode) )))


(provide 'dlUtilsExtras)

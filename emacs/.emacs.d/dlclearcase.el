;; -*- mode: lisp-interaction -*-
;;
;; Author: Martin Blais
;; Date: 2000-03-06 10:10:01 blais

;;
;; External declarations.
;;

(require 'dlUtilsExtras)

;;
;; Generic ClearCase functionality.
;;

(defvar dl-clearcase-cleartool "cleartool"
  "Name of clearcase executable.")

(defvar dl-clearcase-output-name "*Cleartool output*"
  "Name of dl-clearcase output buffer.")

(defvar dl-clearcase-diff-output-name "*Cleartool diff output*"
  "Name of dl-clearcase output diff buffer.")

(defun dl-clearcase-next-action ()
  "Checkout or checkin a file, depending on read-only status of the file."
  (interactive)
  (if (not (equal
	    (if buffer-read-only
		(call-process dl-clearcase-cleartool nil 
			      (get-buffer-create dl-clearcase-output-name) t 
			      "checkout" "-nc" buffer-file-name)
	      (call-process dl-clearcase-cleartool nil 
			    (get-buffer-create dl-clearcase-output-name) t 
			    "checkin" "-nc" buffer-file-name) ) 0))
      (message "Error running cleartool.")
    (revert-buffer t t) ))

(defun dl-clearcase-unco ()
  "Uncheckout the current buffer file."
  (interactive)
  (if (not (equal
	    (if buffer-read-only
		(message "Unco aborted: File is read-only")
	      (call-process dl-clearcase-cleartool nil 
			    (get-buffer-create dl-clearcase-output-name) t 
			    "unco" "-rm" buffer-file-name) ) 0))
      (message "Error running cleartool.")
    (revert-buffer t t) ))

(defun dl-clearcase-mkelem ()
  "Make an element with the current buffer file."
  (interactive)
  (if (not (equal
	    (if buffer-read-only
		(message "Make element aborted: File is read-only")
	      (call-process dl-clearcase-cleartool nil 
			    (get-buffer-create dl-clearcase-output-name) t 
			    "mkelem" "-nc" buffer-file-name) ) 0))
      (message "Error running cleartool.")
    (revert-buffer t t) ))

(defun dl-clearcase-history ()
  "List the history (version tree) for the current buffer file."
  (interactive)
  (with-output-to-temp-buffer "*Cleartool history*"
    (if buffer-file-name 
	(if (not (equal
		  (call-process dl-clearcase-cleartool nil 
				(get-buffer-create dl-clearcase-output-name) t 
				"clearvstree.exe" buffer-file-name) 0))
	    (message "Error running cleartool.")
	  (revert-buffer t t) ))))


;;
;; discreet-specific functionality.
;;

(defun dl-clearcase-guess-branch ()
  "Guess which branch this process is running in.  If not currently running
within a clearcase view, returns nil."
  (let ((proc-output (dl-file-to-string "DL_guess_branch" t t)))
    (if (and proc-output 
	     (string-match "cleartool" proc-output)
	     (string-match "Error" proc-output))
	nil
      proc-output)))

(defun dl-clearcase-get-mod-files ()
  "Show a list of modified files for the current branch."
  (interactive)
  (with-output-to-temp-buffer dl-clearcase-output-name
    (if buffer-file-name 
	(if (not (equal
		  (call-process "DL_get_mod_files" nil 
				(get-buffer-create dl-clearcase-output-name) t 
				buffer-file-name) 0))
	    (message "Error running cleartool.")
	  (revert-buffer t t) ))))

(defun dl-clearcase-xxdiff-ancestor ()
  "Spawn an xxdiff of the current file with the main branch."
  (interactive)
  ;; FIXME to do: make sure the file is already saved.

  (if buffer-file-name 
      (let* (
	     (dummy
	      (if (buffer-modified-p (current-buffer))
		  (map-y-or-n-p
		   (format "Save file %s? " (buffer-file-name (current-buffer)))
		   (function (lambda (buffer) (save-buffer)))
		   (list (current-buffer)))))
		  
	     ;; Get the latest main branch file name.
	     (main-file-name
	      (concat 
	       (substring buffer-file-name 0 (string-match "@@.*" 
							   buffer-file-name))
	       "@@/main/LATEST"))
	     ;; Get the common predecessor.
	     (ancestor-file-name
	      (dl-file-to-string "cleartool" t 
				 (list "desc" "-s" "-anc" 
				       buffer-file-name main-file-name)))
	     )
	(if (equal system-type `windows-nt)
	    (call-process dl-clearcase-cleartool
			  nil (get-buffer-create dl-clearcase-output-name) t 
			  "diff" "-gra" buffer-file-name ancestor-file-name)
	    (call-process "xxdiff" 
			  nil (get-buffer-create dl-clearcase-output-name) t 
			  buffer-file-name ancestor-file-name))
	)))

(defun dl-clearcase-diff-ancestor ()
  "Spawn an diff of the current file with the main branch."
  (interactive)
  ;; FIXME to do: make sure the file is already saved.

  (if buffer-file-name 
      (let* (
	     (dummy
	      (if (buffer-modified-p (current-buffer))
		  (map-y-or-n-p
		   (format "Save file %s? " (buffer-file-name (current-buffer)))
		   (function (lambda (buffer) (save-buffer)))
		   (list (current-buffer)))))
		  
	     ;; Get the latest main branch file name.
	     (main-file-name
	      (concat 
	       (substring buffer-file-name 0 (string-match "@@.*" 
							   buffer-file-name))
	       "@@/main/LATEST"))
	     ;; Get the common predecessor.
	     (ancestor-file-name
	      (dl-file-to-string "cleartool" t 
				 (list "desc" "-s" "-anc" 
				       buffer-file-name main-file-name)))

	     (diff-output-buffer
	      (get-buffer-create dl-clearcase-diff-output-name))
	     )
	(erase-buffer diff-output-buffer)
	(display-buffer diff-output-buffer)
	(call-process "diff"  
		      nil diff-output-buffer t 
		      buffer-file-name ancestor-file-name)
	)))

;;
;; Access bindings.
;;

(defun dl-clearcase-setup-keys ()
  "Key setup for vc-cc dl-clearcase functions"
   (local-set-key [(control x)(v)(v)] 'dl-clearcase-next-action)
   (local-set-key [(control x)(v)(u)] 'dl-clearcase-unco)
   (local-set-key [(control x)(v)(e)] 'dl-clearcase-mkelem)
   (local-set-key [(control x)(v)(t)] 'dl-clearcase-history)
   (local-set-key [(control x)(v)(f)] 'dl-clearcase-get-mod-files)
   (local-set-key [(control x)(v)(x)] 'dl-clearcase-xxdiff-ancestor)
   (local-set-key [(control x)(v)(=)] 'dl-clearcase-diff-ancestor))
  
(add-hook 'c-mode-common-hook 'dl-clearcase-setup-keys)
(add-hook 'makefile-mode-hook 'dl-clearcase-setup-keys)

;;   (global-set-key [(control x)(v)(v)] 'dl-clearcase-next-action)
;;   (global-set-key [(control x)(v)(u)] 'dl-clearcase-unco)
;;   (global-set-key [(control x)(v)(e)] 'dl-clearcase-mkelem)
;;   (global-set-key [(control x)(v)(t)] 'dl-clearcase-history)
;;   (global-set-key [(control x)(v)(f)] 'dl-clearcase-get-mod-files)
;;   (global-set-key [(control x)(v)(x)] 'dl-clearcase-xxdiff-ancestor)
;;   (global-set-key [(control x)(v)(=)] 'dl-clearcase-diff-ancestor)


;; Provide the package.
(provide 'dlClearcase)

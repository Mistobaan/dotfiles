;;; -*- mode: lisp-interaction -*-
;;*****************************************************************************/
;; Copyright (c) 1997,1998,1999,2000 Discreet Logic, Inc.
;;
;; These coded instructions, statements, and computer programs contain
;; unpublished proprietary information written by Discreet Logic and
;; are protected by Federal copyright law. They may not be disclosed
;; to third parties or copied or duplicated in any form, in whole or
;; in part, without the prior written consent of Discreet Logic.
;;*****************************************************************************/
;;
;; Discreet Logic Utilities
;; ========================
;;

;; Public functions
;; ----------------

(defun dl-find-other-file ()
  "Cycles through the header, inline, implementation and source files
of a given component."
  (interactive)
  (let ((fname (file-name-nondirectory 
                (file-name-sans-extension (buffer-file-name))))
        (dir (file-name-directory (buffer-file-name))))
    (cond ((dl-header-file-p (buffer-file-name))
           (cond ((file-exists-p (concat dir fname ".inline.h"))
                  (find-file (concat dir fname ".inline.h")))
                 ((file-exists-p (concat dir "src/" fname ".inline.h" ))
                  (find-file (concat dir "src/" fname ".inline.h" )))
                 ((file-exists-p (concat dir fname ".imp.h"))
                  (find-file (concat dir fname ".imp.h")))
                 ((file-exists-p (concat dir "src/" fname ".imp.h" ))
                  (find-file (concat dir "src/" fname ".imp.h" )))
                 ((file-exists-p (concat dir "src/" fname ".cpp"))
                  (find-file (concat dir "src/" fname ".cpp")))
                 (t
                  (find-file (concat dir fname ".cpp")))
                 ))
          ((dl-inline-file-p (buffer-file-name))
           (let ((fname2 (file-name-sans-extension fname)))
	     (cond ((file-exists-p (concat dir fname2 ".imp.h"))
		    (find-file (concat dir fname2 ".imp.h"))
		    )
		   (t
		    (find-file (concat dir fname2 ".cpp"))
		    ))
	     )
	   )
          ((dl-imp-file-p (buffer-file-name))
           (find-file (concat dir (file-name-sans-extension fname) ".cpp"))
           )
          ((dl-source-file-p (buffer-file-name))
           (if (get-buffer (concat fname ".h"))
               (switch-to-buffer (concat fname ".h"))
             (find-file (concat dir fname ".h"))
             )
           )
          )
    )
  )

(defun dl-inline-file-p ( file-name )
  "Returns true if the given file name is a inline file."
  (string-match "\\.inline\\.h$" file-name)
  )

(defun dl-imp-file-p ( file-name )
  "Returns true if the given file name is a imp file."
  (string-match "\\.imp\\.h$" file-name)
  )

(defun dl-header-file-p ( file-name )
  "Returns true if the given file name is a header file."
  (and (string-match "\\.h$" file-name)
       (not (string-match "\\.inline\\.h$" file-name))
       (not (string-match "\\.imp\\.h$" file-name))
       )
  )

(defun dl-source-file-p ( file-name )
  "Returns true if the given file name is a source file."
  (string-match "\\.cpp$" file-name)
  )


(provide 'dlUtils)

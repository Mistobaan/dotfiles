;;; -*- mode: lisp-interaction -*-
;;
;; Source-code file utilities
;; ========================
;;

;; Public functions
;; ----------------

(defun fj-find-other-file ()
  "Cycles through the header and source files of a given component."
  (interactive)
  (let ((fname (file-name-nondirectory 
                (file-name-sans-extension (buffer-file-name))))
        (dir (file-name-directory (buffer-file-name))))
    (cond ((fj-impheader-file-p (buffer-file-name))
           (find-file (concat dir (file-name-sans-extension fname) ".cpp"))
           )
          ((fj-header-file-p (buffer-file-name))
           (cond ((file-exists-p (concat dir "../src/" fname ".imp.h"))
                  (find-file (concat dir "../src/" fname ".imp.h"))
                  )
                 ((file-exists-p (concat dir fname ".c"))
                  (find-file (concat dir fname ".c"))
                  )
                 ((file-exists-p (concat dir "../src/" fname ".c"))
                  (find-file (concat dir "../src/" fname ".c"))
                  )
                 ((file-exists-p (concat dir fname ".cpp"))
                  (find-file (concat dir fname ".cpp"))
                  )
                 ((file-exists-p (concat dir "../src/" fname ".cpp"))
                  (find-file (concat dir "../src/" fname ".cpp"))
                  )
                 )
           )
          ((fj-cpp-source-file-p (buffer-file-name))
           (cond ((file-exists-p (concat dir "../include/" fname ".h"))
                  (find-file (concat dir "../include/" fname ".h"))
                  )
                 ((file-exists-p (concat dir fname ".h"))
                  (find-file (concat dir  fname ".h"))
                  )
                 )
           )
          ((fj-c-source-file-p (buffer-file-name))
           (cond ((file-exists-p (concat dir "../include/" fname ".h"))
                  (find-file (concat dir "../include/" fname ".h"))
                  )
                 ((file-exists-p (concat dir fname ".h"))
                  (find-file (concat dir  fname ".h"))
                  )
                 )
           
           )
          )
    )
  )

(defun fj-header-file-p ( file-name )
  "Returns true if the given file name is a header file."
  (string-match "\\.h$" file-name)
  )

(defun fj-impheader-file-p ( file-name )
  "Returns true if the given file name is a template imp-header file."
  (string-match "\\.imp.h$" file-name)
  )

(defun fj-cpp-source-file-p ( file-name )
  "Returns true if the given file name is a C++ source file."
  (string-match "\\.cpp$" file-name)
  )

(defun fj-c-source-file-p ( file-name )
  "Returns true if the given file name is a C source file."
  (string-match "\\.c$" file-name)
  )


(provide 'srcFileUtils)

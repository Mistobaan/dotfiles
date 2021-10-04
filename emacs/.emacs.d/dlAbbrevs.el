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
;; Discreet Logic Abbreviations
;; ============================

;; Defines abbreviations for most commonly used constructs. 
;; See the section entitled 'Abbreviation table' for a description of
;; the available abbreviations.

;; Utility functions
;; -----------------

(require 'dlStyleGuide)
(require 'dlUtils)

(defun inside-comment-or-string-p ()
  "Indicates if the current buffer position is located inside a comment
   or a string"
  (let ((parse-state (parse-partial-sexp (point-min) (point))))
    (or (nth 4 parse-state) (nth 3 parse-state))))

;; Abbreviation table
;; ------------------
 
(define-abbrev-table 
  'c++-mode-abbrev-table 
  '(

    ;; These abbreviations should be expanded by an explicit call
    ;; to 'expand-abbrev' (C-x ') instead of typing a space or
    ;; a carriage-return.
    ;;
    ;; newheader  - inserts the template for a new header file
    ;; newsource  - inserts the template for a new source file
    ;; newinline  - inserts the template for a new inline file
    ;; newimp     - inserts the template for a new implementation file
    ;; newmodule  - inserts the template for a new module documentation file
    ;; newclass   - inserts the template for a class declaration (if
    ;;              in a header file) or a class definition (if in
    ;;              a source or an inline file).
    ;; newbox     - inserts a box (C style in header file and C++ style
    ;;              in inline file or source file).
    ;; newfunc    - inserts a function header.

    ("newheader" "" dl-new-header-abbrev 0)
    ("newsource" "" dl-new-source-abbrev 0)
    ("newinline" "" dl-new-inline-abbrev 0)
    ("newimp"    "" dl-new-imp-abbrev 0)
    ("newmodule" "" dl-new-module-abbrev 0)
    ("newclass"  "" dl-insert-class-abbrev 0)
    ("newbox"    "" dl-insert-box-abbrev 0)
    ("newfunc"   "" dl-insert-function-abbrev 0)
    ("hrcheck"   "" dl-insert-hrcheck-abbrev 0)

    ;; These abbreviations should be expanded using a space.
    ;; These should be self explanatory.

    ("if"     "if"     dl-if-abbrev        0)
    ("switch" "switch" dl-switch-abbrev    0)
    ("case"   "case"   dl-case-abbrev      0)
    ("while"  "while"  dl-while-abbrev     0)
    ("else"   "else"   dl-else-abbrev      0)
    ("for"    "for"    dl-for-abbrev       0)
    ("do"     "do"     dl-do-abbrev        0)
    ("try"    "try"    dl-exception-abbrev 0)
    ("elseif" "elseif" dl-elseif-abbrev    0)
    )
  )

;; Abbreviation hooks
;; ------------------

(defun dl-if-abbrev ()
  (if (or (inside-comment-or-string-p)
          (char-equal 
           (save-excursion 
             (backward-char 3) 
             (char-after)
             ) ?# )
          )
      nil
    (insert-string " (asdf ) {\n")
    (indent-according-to-mode)
    (insert-string "\n}") 
    (indent-according-to-mode)
    (search-backward " )")
    )
  )

(defun dl-while-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " ( ) {\n")
    (indent-according-to-mode)
    (insert-string "\n}") 
    (indent-according-to-mode)
    (search-backward " )")
    )
  )

(defun dl-switch-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " ( ) {\n")
    (insert-string "\ndefault: {")
    (indent-according-to-mode)
    (insert-string "\n} break;")
    (indent-according-to-mode)
    (insert-string "\n}") 
    (indent-according-to-mode)
    (search-backward " )")
    )
  )

(defun dl-case-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (indent-according-to-mode)
    (insert-string " c: {\n")
    (indent-according-to-mode)
    (insert-string "\n")
    (indent-according-to-mode)
    (insert-string "} break;")
    (indent-according-to-mode)
    (insert-string "\n")
    (search-backward " c:")
    (delete-char 2)
    )
  )

(defun dl-else-abbrev ()
  (if (or (inside-comment-or-string-p)
          (char-equal 
           (save-excursion 
             (backward-char 5) 
             (char-after)
             ) ?# )
          )
      nil
    (insert-string " {\n1\n}")
    (indent-according-to-mode)
    (next-line -1)
    (indent-according-to-mode)
    )
  )

(defun dl-else-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string "{\n2\n}")
    (search-backward "{")
    )
  )

(defun dl-elseif-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string "( ){\n\n}")
    (indent-according-to-mode)
    (search-backward "if")
    (insert-string " ")
    (search-forward "(")
    )
  )

(defun dl-for-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " (;; ) {\n}")
    (indent-according-to-mode)
    (search-backward ";; )")
    )
  )

(defun dl-do-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " {\n\n} while ( );")
    (indent-according-to-mode)
    (next-line -1)
    (indent-according-to-mode)
    )
  )

(defun dl-include-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " <.h>")
    (search-backward "\\.h")
    )
  )

(defun dl-exception-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " {\n")
    (indent-according-to-mode)
    (insert-string " \n")
    (indent-according-to-mode)
    (insert-string " }")
    (indent-according-to-mode)
    (insert-string "\ncatch ( ... ) {")
    (indent-according-to-mode)
    (insert-string " \n}")
    (indent-according-to-mode)
    (search-backward "{")
    (search-backward "{")
    (next-line 1)
    (indent-according-to-mode)
    )
  )

(defun dl-new-header-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (let (layer fileName)
      (setq layer (read-string "Layer:"))
      (setq fileName (read-string "File (without the .h):"))
      (dl-new-header layer fileName)
      )
    )
  )

(defun dl-new-source-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (dl-new-source)
    )
  )

(defun dl-new-inline-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (dl-new-inline)
    )
  )

(defun dl-new-imp-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (let (layer package fileName)
      (setq layer (read-string "Layer:"))
      (setq package (read-string "Package:"))
      (setq fileName (read-string "File (without the .imp.h):"))
      (dl-new-imp layer package fileName)
      )
    )
  )

(defun dl-new-module-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (let (layer package)
      (setq layer (read-string "Layer:"))
      (setq package (read-string "Package:"))
      (dl-new-module layer package)
      )
    )
  )

(defun dl-insert-function-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (dl-insert-function)
    )
  )

(defun dl-insert-hrcheck-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (dl-insert-hrcheck)
    )
  )

(defun dl-insert-class-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (let ((className (read-string "Class name:")))
      (cond 
       ((dl-imp-file-p buffer-file-name)
        (dl-insert-class-definition className))
       ((dl-inline-file-p buffer-file-name) 
        (dl-insert-class-definition className))
       ((dl-source-file-p buffer-file-name)
        (dl-insert-class-definition className))
       ((dl-header-file-p buffer-file-name)
        (dl-insert-class-declaration className))
       )
      )
    )
  )

(defun dl-insert-box-abbrev ()  
  (if (inside-comment-or-string-p)
      nil
    (cond ((dl-inline-file-p buffer-file-name) (dl-insert-box ""))
          ((dl-source-file-p buffer-file-name) (dl-insert-box ""))
          ((dl-header-file-p buffer-file-name) (dl-insert-box-C "")))
    )
  )

(provide 'dlAbbrevs)

;;; -*- mode: lisp-interaction -*-
;;
;; Useful abbreviations
;; Inspired by discreet setup
;;

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

    ;; These abbreviations should be expanded using a space.
    ;; These should be self explanatory.

    ("if"      "if"      fj-if-abbrev        0)
    ("switch"  "switch"  fj-switch-abbrev    0)
    ("case"    "case"    fj-case-abbrev      0)
    ("while"   "while"   fj-while-abbrev     0)
    ("elseif"  "else if" fj-elseif-abbrev    0)
    ("else"    "else"    fj-else-abbrev      0)
    ("for"     "for"     fj-for-abbrev       0)
    ("do"      "do"      fj-do-abbrev        0)
    ("try"     "try"     fj-exception-abbrev 0)
    ("newfunc" ""        fj-newfunc-abbrev   0)
    )
  )

;; Abbreviation hooks
;; ------------------

(defun fj-if-abbrev ()
  (if (or (inside-comment-or-string-p)
          (char-equal 
           (save-excursion 
             (backward-char 3) 
             (char-after)
             ) ?# )
          )
      nil
    (insert-string " ( )")
    (indent-according-to-mode)
	(insert-string "\n{")
    (indent-according-to-mode)
    (insert-string "\n}") 
    (indent-according-to-mode)
    (search-backward " )")
    )
  )

(defun fj-while-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " ( )\n")
    (indent-according-to-mode)
	(insert-string "{\n")
    (indent-according-to-mode)
    (insert-string "\n}") 
    (indent-according-to-mode)
    (search-backward " )")
    )
  )

(defun fj-switch-abbrev ()
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

(defun fj-case-abbrev ()
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

(defun fj-else-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (indent-according-to-mode)
    (insert-string "\n{")
    (indent-according-to-mode)
    (insert-string "\n")
    (indent-according-to-mode)
    (insert-string "\n}")
    (indent-according-to-mode)
    (next-line -1)
    (indent-according-to-mode)
    )
  )

(defun fj-elseif-abbrev ()
  (if (or (inside-comment-or-string-p)
          (char-equal 
           (save-excursion 
             (backward-char 5) 
             (char-after)
             ) ?# )
          )
      nil
    (insert-string " ( )")
    (indent-according-to-mode)
	(insert-string "\n{")
    (indent-according-to-mode)
    (insert-string "\n}") 
    (indent-according-to-mode)
    (search-backward " )")
    )
  )

(defun fj-for-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (insert-string " (;; )")
    (indent-according-to-mode)
	(insert-string "\n{")
    (indent-according-to-mode)
    (insert-string "\n}") 
    (indent-according-to-mode)
    (search-backward ";; )")
    )
  )

(defun fj-do-abbrev ()
  (if (inside-comment-or-string-p)
      nil
    (indent-according-to-mode)
    (insert-string "\n{")
    (indent-according-to-mode)
    (insert-string "\n} while ( );")
    (indent-according-to-mode)
    (next-line -2)
    (indent-according-to-mode)
    )
  )

(defun fj-exception-abbrev ()
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

(defun fj-newfunc-abbrev ()
    (interactive)
    (insert-string "\
//-----------------------------------------------------------------------------
//")
    (next-line 1)
  )

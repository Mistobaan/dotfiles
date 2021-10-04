;;; -*- mode: lisp-interaction -*-
;;*****************************************************************************/
;; Copyright (c) 1997-2000 Discreet Logic, Inc.
;;
;; These coded instructions, statements, and computer programs contain
;; unpublished proprietary information written by Discreet Logic and
;; are protected by Federal copyright law. They may not be disclosed
;; to third parties or copied or duplicated in any form, in whole or
;; in part, without the prior written consent of Discreet Logic.
;;*****************************************************************************/
;;
;; Discreet Logic Style Guide
;; ==========================
;;
;; This file contains the Discreet Logic style definition and defines
;; several supporting functions. All available functions are described
;; in the section entitled 'Public functions' below.

(require 'cc-align)

;; Utilities
;; ---------

;; Indentation controls
;; --------------------

(defun dl-snug-close (syntax pos)
  (save-excursion
    (let (langelem)
      (if (and (eq syntax 'block-close)
               (setq langelem (assq 'block-close c-syntactic-context))
               (progn (goto-char (cdr langelem))
                      (if (eq (char-after) ?{)
                          (c-safe (forward-sexp -1)))
                      (or (looking-at "\\<do\\>[^_]")
			  (looking-at "\\<case\\>[^_]"))))
          '(before)
        '(before after)))))

(defun dl-class-open (syntax pos)
  (save-excursion
    (progn (goto-char pos)
	   (if (or (looking-at "^namespace\\>")
		   (save-excursion 
		   (progn (forward-word -2)
			  (looking-at "^namespace\\>")))
		   (save-excursion 
		     (progn (forward-word -1)
			    (looking-at "^namespace\\>"))))
	       '(after)
	     '(before after)))))

(defconst dl-style
  (let ((tmp-dl-style

  '((c-basic-offset               . 4)                                         
    (c-hanging-braces-alist       . ((class-open          before after)        
			       	     (class-close         before)
			       	     (defun-open          before after)        
			       	     (defun-close         before after)        
			       	     (inline-open         before after)        
			       	     (inline-close        before after)        
			       	     (brace-list-open     after)               
			       	     (brace-list-close    before)              
			       	     (block-open          before after)        
			       	     (block-close       . dl-snug-close)     
			       	     (substatement-open   after)               
			       	     (substatement-close  before after)        
			       	     (statement-case-open after)               
			       	     (extern-lang-open    after)               
			       	     (extern-lang-close   before after)))      
    (c-hanging-colons-alist       . ((case-label          )                    
			       	     (label               after)               
			       	     (access-label        after)               
			       	     (member-init-intro   before)              
			       	     (inher-intro         before)))            
    (c-cleanup-list               .  (empty-defun-braces
				      defun-close-semi
				      list-close-coma
				      scope-operator))
    (c-offsets-alist . ((string                . -1000)
			(c                     . c-lineup-C-comments)
			(defun-open            . 0)
			(defun-close           . 0)
			(defun-block-intro     . +)
			(class-open            . 0)
			(class-close           . 0)
			(inline-open           . 0)
			(inline-close          . 0)
			(func-decl-cont        . +)
			(knr-argdecl-intro     . +)
			(knr-argdecl           . 0)
			(topmost-intro         . 0)
			(topmost-intro-cont    . 0)
			(member-init-intro     . +)
			(member-init-cont      . 0)
			(inher-intro           . +)
			(inher-cont            . c-lineup-multi-inher)
			(block-open            . 0)
			(block-close           . 0)
			(brace-list-open       . 0)
			(brace-list-close      . 0)
			(brace-list-intro      . +)
			(brace-list-entry      . 0)
			(statement             . 0)
			(statement-cont        . +)
			(statement-block-intro . +)
			(statement-case-intro  . +)
			(statement-case-open   . +)
			(substatement          . +)
			(substatement-open     . 0)
			(case-label            . +)
			(access-label          . -)
			(label                 . 0)
			(do-while-closure      . 0)
			(else-clause           . 0)
			(comment-intro         . c-lineup-comment)
			(arglist-intro         . +)
			(arglist-cont          . 0)
			(arglist-cont-nonempty . c-lineup-arglist)
			(arglist-close         . 0)
			(stream-op             . c-lineup-streamop)
			(inclass               . +)
			(cpp-macro             . -1000)
			(friend                . 0)
			(objc-method-intro     . -1000)
			(objc-method-args-cont . c-lineup-ObjC-method-args)
			(objc-method-call-cont . c-lineup-ObjC-method-call)
			(extern-lang-open      . 0)
			(extern-lang-close     . 0)
			(inextern-lang         . 0)
			(template-args-cont    . +)))) ))
      ;;; For newer versions.
    (if (not (string-match "20\.3" emacs-version))
	(setcdr
	 (assoc 'c-offsets-alist tmp-dl-style)
	 (nconc (cdr (assoc 'c-offsets-alist tmp-dl-style))
		'((cpp-macro-cont        . c-lineup-dont-change)
		  (namespace-open        . 0)
		  (namespace-close       . 0)
		  (innamespace           . 0)))) )
    tmp-dl-style )
  "Discreet Logic Style Guide")


;; Hooks
;; -----

(add-hook 
 'c-mode-common-hook 
 '(lambda()
;;    (setq indent-tabs-mode nil)
    (setq c-class-key "\\(class\\|struct\\|union\\|namespace\\)")
    (c-add-style "DL Style" dl-style t)
    (abbrev-mode 1)
    )
 )

;; Public functions
;; ----------------

(defun dl-insert-box (title)
  "Inserts a box around the given title at the current position."
   (interactive "sTitle: ")
   (insert-string 
"//=============================================================================
// " )
   (insert-string title)
   (insert-string
"
//=============================================================================

" )
)

(defun dl-insert-box-C (title)
  "Inserts a box around the given title at the current position but uses
C-style comments (/*) instead of C++-style comments (//)."
  (interactive "sTitle: ")
  (insert-string
   "/*=============================================================================
 * " )
  (insert-string title)
  (insert-string
   "
 *===========================================================================*/

" )
  )

(defun dl-insert-function ()
  "Inserts a function header at the given position."
  (interactive)
  (insert-string "\
//-----------------------------------------------------------------------------
//" )
  )

(defun dl-insert-hrcheck ()
  "Inserts a function header at the given position."
  (interactive)
  (insert-string "siILASSERT( ILSUCCEEDED( hr ) );" )
  )

(defun dl-insert-class-declaration (className)
  "Inserts a class declaration in a header file."
  (interactive "sClass name:")
  (dl-insert-box-C (concat "CLASS " className))
  (insert-string "// <summary></summary>\n\n")
  (insert-string (concat "class " className "\n{\n\n"))
  (insert-string "\
public: 

   /*----- constants -----*/

   /*----- types and enumerations ----*/

   /*----- classes -----*/

   /*----- static member functions -----*/

   /*----- member functions -----*/
      
protected: 

   /*----- constants -----*/

   /*----- types and enumerations ----*/

   /*----- classes -----*/

   /*----- static member functions -----*/

   /*----- member functions -----*/


private: 

   /*----- constants -----*/

   /*----- types and enumerations ----*/

   /*----- classes -----*/

   /*----- static member functions -----*/

   /*----- member functions -----*/\n")
  (insert-string (concat "   explicit " className "();\n"))
  (insert-string (concat "   " className "( const " className " & );\n"))
  (insert-string (concat "   ~" className "();\n"))
  (insert-string (concat "   " className "& operator=( const " className "& );\n"))

  (insert-string "\

  /*----- static data members -----*/

  /*----- data members -----*/

};\n")

  (search-backward "<summary")
  (forward-char 9)
  )

(defun dl-insert-class-definition (className)
  "Inserts a class definition in a source file."
  (interactive "sClass name:")
  (dl-insert-box (concat "CLASS " className))
  (dl-insert-function)
  )

(defun dl-new-header (layer fileName)
  "Inserts the template for a new header file."
  (interactive "sLayer:\nsFile:")
  (let ((includeGuard 
	 (concat "DL_INCL_" (upcase layer) "_" (upcase fileName))))
    (insert-string "\
//*****************************************************************************/
// Copyright (c) ")
    (insert-string (number-to-string (nth 5 (decode-time))))
    (insert-string " Softimage Inc.
//
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Softimage and
// are protected by Federal copyright law. They may not be disclosed
// to third parties or copied or duplicated in any form, in whole or
// in part, without the prior written consent of Softimage.
//*****************************************************************************/\n\n")
    (insert-string (concat "#ifndef " includeGuard "\n"))
    (insert-string (concat "#define " includeGuard "\n\n"))
    )
  (dl-insert-box-C "EXTERNAL DECLARATIONS")
  (insert-string
   (concat "#ifndef DL_INCL_" (upcase layer) "_" (upcase layer) "DEFS\n"))
  (insert-string
   (concat "#include <" layer "/" layer "Defs.h>\n"))
  (insert-string "#endif

DL_NAMESPACE_START


DL_NAMESPACE_END

#endif\n" )
  )

(defun dl-new-source ()
  "Inserts the template for a new source file."
  (interactive)
  (insert-string "\
//*****************************************************************************/
// Copyright (c) ")
  (insert-string (number-to-string (nth 5 (decode-time))))
  (insert-string " Softimage Inc.
//
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Softimage and
// are protected by Federal copyright law. They may not be disclosed
// to third parties or copied or duplicated in any form, in whole or
// in part, without the prior written consent of Softimage.
//*****************************************************************************/

//=============================================================================
// EXTERNAL DECLARATIONS
//=============================================================================

namespace {

DL_USING_NAMESPACE

//=============================================================================
// LOCAL DECLARATIONS
//=============================================================================

/*----- constants -----*/

/*----- types and enumerations -----*/

/*----- classes -----*/

/*----- function prototypes -----*/

/*----- variables -----*/

//=============================================================================
// LOCAL FUNCTIONS
//=============================================================================

}

DL_NAMESPACE_START

//=============================================================================
// PUBLIC FUNCTIONS
//=============================================================================

DL_NAMESPACE_END
" )
  )

(defun dl-new-inline ()
  "Inserts the template for a new inline file."
  (insert-string "\
//*****************************************************************************/
// Copyright (c) ")
  (insert-string (number-to-string (nth 5 (decode-time))))
  (insert-string " Softimage Inc.
//
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Softimage and
// are protected by Federal copyright law. They may not be disclosed
// to third parties or copied or duplicated in any form, in whole or
// in part, without the prior written consent of Softimage.
//*****************************************************************************/\n\n")
  (dl-insert-box "EXTERNAL DECLARATIONS")
  (insert-string "\
DL_NAMESPACE_START

DL_NAMESPACE_END" )
  )

(defun dl-new-imp (layer package fileName)
  "Inserts the template for a new implementation file."
  (interactive "sLayer:\nsPackage:\nsFile:")
  (insert-string "\
//*****************************************************************************/
// Copyright (c) ")
  (insert-string (number-to-string (nth 5 (decode-time))))
  (insert-string " Softimage Inc.
//
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Softimage and
// are protected by Federal copyright law. They may not be disclosed
// to third parties or copied or duplicated in any form, in whole or
// in part, without the prior written consent of Softimage.
//*****************************************************************************/\n\n")
  (let ((includeGuardForHeader 
	 (concat "DL_INCL_" (upcase layer) "_" (upcase fileName)))
        (includeGuardForImp
         (concat "DL_INCL_" (upcase layer) "_" (upcase fileName) "_IMP"))
        )
    (insert-string (concat "#ifndef " includeGuardForImp "\n"))
    (insert-string (concat "#define " includeGuardForImp "\n\n"))
    (dl-insert-box "EXTERNAL DECLARATIONS" );
    (insert-string (concat "#ifndef " includeGuardForHeader "\n"))
    (insert-string (concat "#include <" layer "/" package "/src/" fileName ".h>\n"))
    (insert-string (concat "#endif\n\n"))
    )
  (insert-string "\
DL_NAMESPACE_START

DL_NAMESPACE_END
    
#endif")
)

(defun dl-new-module (layer package)
  "Inserts the template for a module documentation file."
  (interactive "sLayer:\nsPackage:")
  (insert-string "\
//*****************************************************************************/
// Copyright (c) ")
  (insert-string (number-to-string (nth 5 (decode-time))))
  (insert-string " Softimage Inc.
//
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Softimage and
// are protected by Federal copyright law. They may not be disclosed
// to third parties or copied or duplicated in any form, in whole or
// in part, without the prior written consent of Softimage.
//*****************************************************************************/\n\n")
  (let ((includeGuard 
	 (concat "DL_INCL_" (upcase layer) "_" (upcase package)))
        )
    (insert-string (concat "#ifndef " includeGuard "\n"))
    (insert-string (concat "#define " includeGuard "\n\n"))
    (dl-insert-box-C "DOCUMENTATION" );
    )
  (insert-string "\
// <module>
//
// The module should be documented here.
//
// <todo>
// </todo>
//
// </module>

#endif")
)

(provide 'dlStyleGuide)


;;
;;  Customization of font-lock
;;
(require 'font-lock)

;;
;; Define my font-lock highlighting
;;

(defconst my-c++-font-lock-keywords nil
  "My font lock stuff")

(let ((c++-keywords
       ;; ("break" "continue" "do" "else" "for" "if" "return" "switch" "while"
       ;;  "class" "struct" "union" "namespace" "using"
       ;;  "extern" "static" "auto" "register" "enum" "typedef" 
       ;;  "friend" "inline" "virtual" "template"
       ;;  "asm" "catch" "delete" "new" "operator" "sizeof" "this" "throw" "try"
       ;;  "protected" "private" "public")
       (concat "\\(^[ \t]*\\<\\(class\\|namespace\\|struct\\|union\\)\\>\\)\\|"
               "\\<\\("
	       "a\\(sm\\|uto\\)\\|"
	       "break\\|"
	       "c\\(atch\\|ontinue\\)\\|"
	       "d\\(elete\\|o\\)\\|"
	       "e\\(lse\\|num\\|x\\(tern\\|plicit\\)\\)\\|"
	       "f\\(or\\|riend\\)\\|"
	       "i\\(f\\|nline\\)\\|"
	       "n\\(amespace\\|ew\\)\\|"
	       "p\\(r\\(ivate\\|otected\\)\\|ublic\\)\\|"
	       "re\\(gister\\|turn\\)\\|"
	       "s\\(izeof\\|witch\\|tatic\\)\\|"
	       "t\\(h\\(is\\|row\\)\\|ry\\|emplate\\|ypedef\\)\\|"
	       "using\\|"
	       "v\\(olatile\\|irtual\\)\\|"
	       "while"
               "\\)\\>"))
      (ctoken "\\(\\(\\(::\\)?\\<~?[A-Za-z0-9_]+\\>\\(<[^=>]*>\\)?\\)+\\)")
      (c++-structs   "\\<\\(class\\|namespace\\|struct\\|union\\)\\>")
      (c++-operators (concat "\\("
			     "[[(><!=+*/%^&|~,-]"
			     "[])><!=+*/%^&|~-]?"
			     "[=*]?"
			     "\\)?")))
  (setq my-c++-font-lock-keywords 
	(list
	 ;; Fontify function name definitions (GNU style; without type on line).
	 
	 ;; In FSF this has the simpler definition of "\\sw+" for ctoken.
	 ;; I'm not sure if ours is more correct.
	 ;; This is a subset of the next rule, and is slower when present. --dmoore
	 ;; (list (concat "^\\(" ctoken "\\)[ \t]*(") 1 'font-lock-function-name-face)
	 ;;
	 ;; fontify the names of functions being defined.
	 ;; FSF doesn't have this but I think it should be fast for us because
	 ;; our regexp routines are more intelligent than FSF's about handling
	 ;; anchored-at-newline. (When I added this hack in regex.c, it halved
	 ;; the time to do the regexp phase of font-lock for a C file!) Not
	 ;; including this discriminates against those who don't follow the
	 ;; GNU coding style. --ben
	 ;; x?x?x?y?z should always be: (x(xx?)?)?y?z --dmoore
	 (list (concat 
		"^"
		"\\(" "template[ \t]*<[^>]*>[ \t]*" "\\)?"
		"\\(" ctoken "[ *&\t]+\\)?" ; type specs; there can be no
		"\\(" ctoken "[ *&\t]+\\)?"
		"\\(" ctoken "[ *&\t]+\\)?" ; more than 3 tokens, right?
		"\\(" ctoken "[ *&\t]+\\)?"
		"\\(" ctoken c++-operators "\\)[ \t]*(") ; name
		22 'font-lock-function-name-face)

	 ;;
	 ;; This is faster but not by much.  I don't see why not.
	 ;; (list (concat "^\\(" ctoken "\\)[ \t]*(") 1 'font-lock-function-name-face)
	 ;;
	 ;; Added next two; they're both jolly-good fastmatch candidates so
	 ;; should be fast. --ben
	 ;;
	 ;; Fontify structure names (in structure definition form).
	 (list (concat "^[ \t]*\\(template[ \t]*<.*>[ \t]*\\)?" c++-structs 
		       "[ \t]+\\(" ctoken "\\)")
	       '(2 font-lock-keyword-face) '(3 font-lock-function-name-face))
	 ;;
	 ;; Fontify case clauses.  This is fast because its anchored on the left.
	 '("case[ \t]+\\(\\(\\sw\\|\\s_\\)+\\):". 1)
	 ;;
	 '("\\<\\(default\\):". 1)
	 ;; Fontify filenames in #include <...> preprocessor directives as strings.
	 '("^#[ \t]*include[ \t]+\\(<[^>\"\n]+>\\)" 1 font-lock-string-face)
	 ;;
	 ;; Fontify function macro names.
	 '("^#[ \t]*define[ \t]+\\(\\(\\sw+\\)(\\)" 2 font-lock-function-name-face)
	 ;;
	 ;; Fontify symbol names in #if ... defined preprocessor directives.
	 '("^#[ \t]*if\\>"
	   ("\\<\\(defined\\)\\>[ \t]*(?\\(\\sw+\\)?" nil nil
	    (1 font-lock-preprocessor-face) (2 font-lock-variable-name-face nil t)))
	 ;;
	 ;; Fontify symbol names in #elif ... defined preprocessor directives.
	 '("^#[ \t]*elif\\>"
	   ("\\<\\(defined\\)\\>[ \t]*(?\\(\\sw+\\)?" nil nil
	    (1 font-lock-preprocessor-face) (2 font-lock-variable-name-face nil t)))
	 ;;
	 ;; Fontify otherwise as symbol names, and the preprocessor directive names.
	 '("^\\(#[ \t]*[a-z]+\\)\\>[ \t]*\\(\\sw+\\)?"
	   (1 font-lock-preprocessor-face) (2 font-lock-variable-name-face nil t))
	 

	 ;;
	 ;; Fontify operator function name overloading.
	 (list (concat "\\<\\(operator\\)\\>[ \t]*" c++-operators)
	   '(1 font-lock-keyword-face) '(2 font-lock-keyword-face nil t))

	 ;;
	 ;; Fontify case/goto keywords and targets, and case default/goto tags.
	 '("\\<\\(case\\|goto\\)\\>[ \t]*\\([^ \t\n: ;]+\\)?"
	   (1 font-lock-keyword-face) (2 font-lock-reference-face nil t))
	 '("^[ \t]*\\(\\sw+\\)[ \t]*:[^:]" 1 font-lock-reference-face)
	 ;;
	 ;; Fontify other builtin keywords.
	 (cons (concat "\\(" c++-keywords "\\)") 'font-lock-keyword-face)

	 )))

;;
;; My own compilation font lock
;;
(defconst my-compilation-font-lock-keywords nil
  "My font lock stuff")

(setq my-compilation-font-lock-keywords
  (list
   '("^Propagating.*$"                                                   . font-lock-function-name-face)
   '("^Making.*$"                                                        . font-lock-function-name-face)
   '("^Building.*$"                                                      . font-lock-function-name-face)
   '("^Rebuilding.*$"                                                    . font-lock-function-name-face)
   '("^Updating.*$"                                                      . font-lock-function-name-face)
   '("^Cleaning.*$"                                                      . font-lock-function-name-face)
   '("^====.*$"                                                          . font-lock-function-name-face)
   '("^Running test:.*(FAILED).*$"                                       . font-lock-reference-face)
   '("^Stop  running test:.*(FAILED).*$"                                 . font-lock-reference-face)
   '("^Running test:.*$"                                                 . font-lock-comment-face)
   '("^Start running test:.*$"                                           . font-lock-comment-face)
   '("^Stop  running test:.*$"                                           . font-lock-comment-face)
   ))

(if (equal system-type `windows-nt)
    (setq my-compilation-font-lock-keywords 
	  (append 
	   my-compilation-font-lock-keywords
	   '(
	     ("^\tCL /c .*$"                                                 . font-lock-string-face) 
	     ("^\techo .*$"                                                  . font-lock-string-face) 
	     ("^\tLINK /DLL .*$"                                             . font-lock-string-face) 
	     ("^\\([^ ,\n\(\)]+([0-9]+)\\) : \\(error\\|fatal error\\|warning\\) " 
	      (0 bold  t t) (1 font-lock-function-name-face t t) )
	     )
	   )
	  )
    (setq my-compilation-font-lock-keywords 
	  (append 
	   my-compilation-font-lock-keywords
	   '(("^[-_.\"A-Za-z0-9/+]+\\(:\\|, line \\)[0-9]+: \\([wW]arning:\\).*$" . font-lock-keyword-face)
	     ("^[-_.\"A-Za-z0-9/+]+\\(: *\\|, line \\)[0-9]+:.*$"                 . font-lock-function-name-face)
	     ("^[^\n]+-[a-zA-Z][^\n]+$"                                           . font-lock-doc-string-face)
	     ("\\(^[-_.\"A-Za-z0-9/+]+\\)\\(: *\\|, line \\)[0-9]+"               1 font-lock-string-face t)
	     ("^[-_.\"A-Za-z0-9/+]+\\(: *[0-9]+\\|, line [0-9]+\\)"               1 bold t)
	     ("^\\(CC\|cc\\) .*$"                                                 0 font-lock-string-face t) 
	     ("\\(cc\\|cft\\)-[0-9]+ [cC]\\([cC]\\|f77\\): \\(ERROR\\|WARNING\\|REMARK\\) \\([^,\n]+, \\)*File = \\([^,\n]+\\), Line = \\([0-9]+\\)" 
	      (0 bold  t t) (3 font-lock-function-name-face t t) )
	     )
	   )
	  )
  )

;;
;; Set all C/C++ modes to the same values
;;
(custom-set-variables 
 '(c++-font-lock-keywords   my-c++-font-lock-keywords t)
 '(c++-font-lock-keywords-1 my-c++-font-lock-keywords t)
 '(c++-font-lock-keywords-2 my-c++-font-lock-keywords t)
 '(c++-font-lock-keywords-3 my-c++-font-lock-keywords t)
 '(c-font-lock-keywords     my-c++-font-lock-keywords t)
 '(c-font-lock-keywords-1   my-c++-font-lock-keywords t)
 '(c-font-lock-keywords-2   my-c++-font-lock-keywords t)
 '(c-font-lock-keywords-3   my-c++-font-lock-keywords t)
 '(compilation-font-lock-keywords my-compilation-font-lock-keywords t))



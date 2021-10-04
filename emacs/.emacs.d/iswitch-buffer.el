;; @(#) iswitch-buffer.el -- switch between buffers using substrings

;; Copyright (C) 1996 Stephen Eglen
;;
;; Author: Stephen Eglen <stephene@cogs.susx.ac.uk>
;; Maintainer: Stephen Eglen <stephene@cogs.susx.ac.uk>
;; Created: 15 Oct 1996
;; Version: 1.0
;; Keywords: extensions
;; location: http://www.cogs.susx.ac.uk/users/stephene/emacs


;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 1, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; A copy of the GNU General Public License can be obtained from this
;; program's author (send electronic mail to
;; <stephene@cogs.susx.ac.uk>) or from the Free Software Foundation,
;; Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;; LCD Archive Entry:
;; iswitch-buffer|Stephen Eglen|<stephene@cogs.susx.ac.uk>
;; |switch between buffers using substrings
;; |$Date: 1996/11/22 11:41:42 $|$Revision: 1.15 $|~/packages/iswitch-buffer.el



;;; Installation:
;;
;; To autoload the package, do:
;;
;;      (autoload 'iswitch-default-keybindings "iswitch-buffer"
;;                "Switch buffer by susbtring" t)
;;
;; Or you can just load it normally with a require
;;
;;      (require 'iswitch-buffer)
;;      (setq    iswitch-mode-hook  nil)      ;; optional
;;
;; This file overrides the normal keybindings for
;;
;;      C-x b, C-x 4 b and C-x 5 b
;;
;; Adjust the iswitch-load-hook if you don't want new bindings.

;;; Commentary:
;;
;;  Has been tested on Emacs 19.27, 19.34 and Xemacs 19.14.
;;
;; Iswitch -- how it works
;;
;; As you type in a substring, the list of buffers currently matching
;; the substring are displayed as you type.  The list is ordered so
;; that the most recent buffers visited come at the start of the list.
;; The buffer at the start of the list will be the one visited when
;; you press return.  By typing more of the substring, the list is
;; narrowed down so that gradually the buffer you want will be at the
;; top of the list.  Alternatively, you can use C-s an C-r to rotate
;; buffer names in the list until the one you want is at the top of
;; the list.  Completion is also available.


;; This function is inspired by the code written by Michael R Cook
;; <mcook@cognex.com>.  The difference between this code and Michael's
;; is that his looks for exact matches rather than substring matches.
;; Jari should take credit for creating this function based on
;; Michael's.  (Another related package is icomplete.)
;;
;;
;; Example: say you are looking for a file called "file.c" when you
;; first use the iswitch function you get a default suggestion which
;; is the "other-buffer"
;;
;;      iswitch: {file.h}
;;
;; Then I type "i", so this gives me all buffers with "i" in the name:
;;
;;      iswitch: i  {file.h,iswitch-buffer.el,file.data,...}
;;
;; Now I type "l" and I get just a few selections left
;;
;;      iswitch: il  {file.h,file.data,file.c,MAIL,*mail*}
;;
;;  and at this point,  I can either type "e.c" to specify the c file, or
;;  just hit ctrl-s twice so that file.c is at the top of the list:
;;
;;      (C-s) iswitch: il  {file.data,file.c,MAIL,*mail*,file.h}
;;      (C-s) iswitch: il  {file.c,MAIL,*mail*,file.h,file.data}
;;
;;  and finally, I can press RTN to select the first item in the list.
;;  If you want to select the buffer given by the prompt, rather than
;;  the first item in the list press C-j.  If a buffer doesnt exist,
;;  then you will be prompted to create a new buffer.
;;
;;  See the doc string of iswitch-buffer for keybindings.
;;  (describe-function 'iswitch-mode)
;;  Note also that SPC is defined to be the same as C-s.
;;
;;  See also the user variables if you want to change the setup.
;;


;; History
;;
;; iswitch remembers the most recent buffers that you have selected.
;; You can access this list using the C-v key (iswitch-toggle-list) to
;; switch between searching through all buffers or just those buffers
;; in the history list.  By default, you search all buffers, but if
;; you want to start iswitch in history mode all the time, then add:
;; (add-hook 'iswitch-mode-hook 'iswitch-start-with-used-list) When
;; you select a buffer, it is moved to the front of the history list.
;; By default, if a buffer is killed, it is also removed from the list
;; (using iswitch-list-housekeeping).


;; Completion
;;
;; Pressing TAB will complete the substring to the matched buffers as
;; far as possible.  Completion works by finding the longest common
;; suffix to the first match of the current prompt in each buffer.
;; Example:
;; iswitch: te {mp:temp1,temp2,temp3}
;;              ^^^
;; If I now hit TAB, "mp" gets completed to "te" to make "temp".  Note
;; that by default it shows you what will get added to the prompt if
;; you hit TAB; this is indicated by the text indicated here with ^^^.
;; (This is controlled by iswitch-show-completion.)
;; Also, if there is only matching buffer, hitting TAB will select that buffer.


;; Editing
;;

;; If you make a mistake typing in the substring, simple corrections
;; can be made by deleting and retyping.  There is also an editing
;; mode, for minibuffer like editing.  Hit C-e to start editing and
;; then enter to resume iswitch.  (If you get into trouble editing,
;; press enter and then use C-g to exit from iswitch.  Currently if
;; you hit C-g in the editing mode, it gets stuck!


;;; Todo:
;; Notes for developers: what needs doing.
;;
;;  doesnt yet take into account the values of
;;  same-window-buffer-names
;;  same-window-regexps
;;  but do they cause a problem?
;;
;;  what is the difference between overriding-terminal-local-map and
;;  overriding-local-map?  I got overriding-terminal-local-map from
;;  isearch.el but the terminal version doesnt exist in emacs 19.27.

;; Other control chars?

;; at the moment, iswitch doesnt trasnsparently exit and go into other
;; keybindings, eg, if you are in iswitch and then hit C-x C-f, it
;; wont silently exit iswitch and go into find-file.  Should it?
;; This looks like a lot of work, seeing the iswitch code.

;; do we want c-q to be the quoting prefix, as is normal?

;; iswitch-list. If we are using the buffer-list (rather than history)
;; what should this value be -- nil?

;; Keybindings

;; Perhaps these arent the best keybindings in the world.  If anyone
;; comes up with a better set, let me know your suggestions!

;;  Limitations:
;;
;;  Regexp mode
;;  Cannot use [ or \ to build up a regexp, as they form incomplete input.
;;  This function is really for quick switching between buffers.  If you
;;  really want to use these in regexp searching, get in touch!
;;  Also, completion doesnt work in regexp mode. (with bufs file1 and file2,
;;  type in f. and then ask for completion.)


;;; Code:

;;; ............................................................ hooks ...

(defvar iswitch-load-hook 'iswitch-default-keybindings
  "*Hook run when file has been loaded.")

(defvar iswitch-mode-hook nil
  "Function(s) to call after starting up iswitch.")

(defvar iswitch-mode-end-hook nil
  "Function(s) to call after exiting iswitch.")

;;; ................................................... User variables ...

(defvar iswitch-buffer-ignore
  '("^ ")
  "*List of regexps or functions matching buffer names to ignore.  For
example, traditional behavior is not to list buffers whose names begin
with a space, for which the regexp is \"^ \".  See the source file for
example functions that filter buffernames.")

(defvar iswitch-regexp nil
 "*Non-nil means that iswitch will do regexp
matching. Value can be toggled within iswitch.")

(defvar iswitch-buffer-prompt-newbuffer t
  "*Non-nil means prompt user to confirm before creating new buffers.")

(defvar iswitch-buffer-newbuffer t
  "*Non-nil means that new buffers can possibly be created if they
dont exist.")

(defvar iswitch-case case-fold-search
  "*Non-nil if searching of buffer names should ignore case.")

(defvar iswitch-show-completion t
  "*Non-nil means that possible completion is calculated and shown
in prompt. The calculation may slow down package.")

(defvar iswitch-default-method  'always-frame
    "*How to switch to buffer when pressing C-x b. See variable
  iswitch-method.")
;;; ............................................... internal variables ...


(defconst iswitch-buffer-version (substring "$Revision: 1.15 $" 11 -2)
  "$Id: iswitch-buffer.el,v 1.15 1996/11/22 11:41:42 stephene Exp stephene $

Report bugs to: Stephen Eglen <stephene@cogs.susx.ac.uk>")

(defvar iswitch-buffer-ignore-orig nil
"Stores original value of iswitch-buffer-ignore before iswitch starts.")


(defvar iswitch-rescan nil
  "Internal variable -- whether we need to regenerate the list of matching
buffers.")


(defvar iswitch-method nil
  "Selected buffer is shown in either the same window, other window or in
a new frame according to this variable.  Its value is  one of
`samewindow', `otherwindow', `otherframe', `maybe-frame' or
`always-frame`

maybe-frame means that if the window is visible in some _other_ frame
it suggests jumping to it instead of creating window to current frame.

always-frame jumps to other frame if the buffer is visible there.

")

(defvar iswitch-text nil
  "Stores the users string as it is typed in.")

(defvar iswitch-matches nil
  "List of buffers currenly matching the text typed in.")

(defvar iswitch-change-word-sub  nil
  "Private. Variable dynamically bound in function
iswitch-word-matching-substring.")


(defvar iswitch-common-match-string  nil
  "Private. Common match for buffers.")


(defvar iswitch-list nil
  "Private. Current buffer list in use.")

(defvar iswitch-list-entered  nil
  "Private. Selected buffer history, maximum history count is 15.
Format '(\"buffer\" \"buffer\" ...), most recent first.  Once the
maximum number of buffer names is reached, as new ones are added to
the front of the list, old ones are removed from the end of the
list.")

(defvar iswitch-matches nil
  "List of buffers currenly matching the text typed in.")

(defvar iswitch-list-entered-in-use  nil
  "Private. Non-nil if history list is currently used.")


(defvar iswitch-show-inital-list  nil
  "Private. If non-nil then all bufferes are shown when entering iswitch.")

(defvar iswitch-show-whole-list  nil
  "Private. If non-nil, we show the whole buffer list.")

;;; .................................................. mode definition ...


(defvar iswitch-mode nil
  "Minor mode flag.")

(make-variable-buffer-local 'iswitch-mode)


(defvar iswitch-mode-name " Iswitch"
  "Name of the minor mode, if non-nil.")


(defvar iswitch-mode-map nil
  "Keymap for iswitch-mode.")


(defun iswitch-define-keys-to-map (map function &optional beg end)
  "Put FUNCTION into MAP. Optional BEG and END default to
range 32..127, for the normal ABC map."
  (let ((i (or beg 32))                       ;Defaults to ABC map
      (str (make-string 1 0))
      )
    (while (< i (or end 127))
      (aset str 0 i)
      (define-key map str function)
      (setq i (1+ i))
      )))


(defun iswitch-define-abc-map (map function)
  "Put FUNCTION into ABC.. keymap."
  (let ((i 32)
	(str (make-string 1 0))
	)
    (while (< i 127)
      (aset str 0 i)
      (define-key map str function)
      (setq i (1+ i))
      )))

;;; define the minor mode map.
;;;###autoload
(defun iswitch-define-mode-map ()
  (interactive)
  (or iswitch-mode-map
      (let ((i 0)
	    (map (make-keymap)))
	(suppress-keymap map)
	;;(set-keymap-name map 'iswitch-mode-map) ; only for convienience
	
      
	;; Make function keys, etc, exit iswitch
	;;
	;; (define-key map [t] 'iswitch-other-control-char) ; what isxxxx?
	;;
	;; Control chars will end iswitch.
	;; (taken from isearch)
	;; We use a dense keymap to save space.
	;;
	(while (< i ?\ )
	  (define-key map (make-string 1 i) 'iswitch-other-control-char)
	  (setq i (1+ i)))

        ;; Bind all printing characters to `iswitch-printing-char'.
        ;; This isn't normally necessary, but if a printing character were
        ;; bound to something other than self-insert-command in global-map,
        ;; then it would terminate the search and be executed without this.

	(iswitch-define-abc-map map 'iswitch-printing-char)

        ;; Several non-printing chars change the searching behavior.
        ;;
	(define-key map "\C-e" 'iswitch-edit-prompt)
        (define-key map "\C-z" 'iswitch-show-whole-list)
        (define-key map "\C-f" 'iswitch-find-file)
        (define-key map "\C-s" 'iswitch-next-match)
        (define-key map "\C-r" 'iswitch-prev-match)

        (define-key map "\C-v" 'iswitch-toggle-list)
        (define-key map "\C-t" 'iswitch-toggle-regexp)
        (define-key map "\C-a" 'iswitch-toggle-ignore)
        (define-key map "\C-c" 'iswitch-toggle-case)

        (define-key map "\177" 'iswitch-delete-char)
	;; for non windowed sessions.
	(if (null window-system)
	    (define-key map "\C-h" 'iswitch-delete-char))
        (define-key map "\C-g" 'iswitch-abort)

        ;; old bindings
        ;; (define-key map "\r" 'iswitch-select-buffer-text)
        ;; (define-key map "\t" 'iswitch-select-first-match)
        ;;
        ;; new bindings
        (define-key map "\r" 'iswitch-select-first-match)
        (define-key map "\C-j" 'iswitch-select-buffer-text)
        (define-key map "\t" 'iswitch-complete)

        ;; change the binding of the space bar if you want.
        ;; space is normally defined to next match.
        ;;
        (define-key map " " 'iswitch-next-match)
        ;;(define-key map " " 'iswitch-printing-char)

        (setq iswitch-mode-map map) ) ))


;;; Keybindings
;;;###autoload
(defun iswitch-default-keybindings ()
  "Set up default keybindings for iswitch."
  (interactive)
  (global-set-key "b" 'iswitch-buffer)
  (global-set-key "4b" 'iswitch-buffer-other-window)
  (global-set-key "5b" 'iswitch-buffer-other-frame))

;;; .................................................... user callable ...
;;; Entry functions

;;;###autoload
(defun iswitch-buffer ()
  "Switch to another buffer and show it in the current window.
The buffer name is selected interactively by typing a substring.
For details of keybindings, do `C-h f iswitch-mode'."
  (interactive)
  (setq iswitch-method iswitch-default-method)
  (iswitch-entry))


;;;###autoload
(defun iswitch-buffer-other-window ()
  "Switch to another buffer and show it in another window.
The buffer name is selected interactively by typing a substring.
For details of keybindings, do `C-h f iswitch-mode'."
  (interactive)
  (setq iswitch-method 'otherwindow)
  (iswitch-entry))



;;;###autoload
(defun iswitch-buffer-other-frame ()
  "Switch to another buffer and show it in another frame.
The buffer name is selected interactively by typing a substring.
For details of keybindings, do `C-h f iswitch-mode'."
  (interactive)
  (setq iswitch-method 'otherframe)
  (iswitch-entry))

(defun iswitch-entry ()
  ;;Simply fall into iswitch mode.
  (interactive)
  (iswitch-mode))


;;;###autoload
(defun iswitch-mode ()
  "Start iswitch minor mode.  As you type in a string, all of the buffers
matching the string are displayed.  When you have found the buffer you want,
it can then be selected.

The prompt tells you what's happening. There may be extra characters at
front: H means that you're  using the history of entered buffers, R refers
to regexp mode, C means that buffer switching is case sensitive.
    iswitch: {*help*}                     ,you start here
    iswitch: {*help* >> *buffer*,}        ,after pressing C-z
    R H iswitch: {*help* >> *buffer*,}    ,regexp mode and History list
    ...

Kebindings:
\\<iswitch-mode-map>

\\[iswitch-select-first-match] Pick _first_ selection in list
\\[iswitch-next-match] Put the first element at the end of the list
\\[iswitch-prev-match] Put the last element at the start of the list

\\[iswitch-select-buffer-text] Select the current prompt as the buffer.
    If no buffer is found, prompt for a new one.
\\[iswitch-complete] Complete a common suffix to the current string that \
matches all buffers
\\[iswitch-edit-prompt] Enter editing mode.

\\[iswitch-show-whole-list] Toggle viewing whole list when you start.
\\[iswitch-toggle-list] Toggle active list (history or current buffers)
\\[iswitch-toggle-regexp] Toggle rexep searching
\\[iswitch-toggle-ignore] Toggle ignoring certain buffers (see \
iswitch-buffer-ignore)
\\[iswitch-toggle-case] Toggle case-sensitive searching of buffer names
\\[iswitch-find-file] Quit iswitch and drop into find-file
\\[iswitch-abort] Quit

"

  ;; Initialize global vars
  (setq iswitch-mode                    t
        iswitch-text                    ""
        iswitch-common-match-string    nil
        iswitch-matches                 nil
        iswitch-list-entered-in-use     nil
        iswitch-list                    nil
        iswitch-show-whole-list         nil
        )

  (force-mode-line-update)

  ;; make the iswitch-mode-map dominant
  ;(setq overriding-terminal-local-map iswitch-mode-map)
  (setq overriding-local-map iswitch-mode-map)
  (iswitch-list-housekeeping)

  ;; run any hooks?
  (run-hooks 'iswitch-mode-hook)

  ;; this is the first time the msg is displayed
  (setq iswitch-rescan t)
  (iswitch-set-matches)
  (iswitch-update-msg)
  )



;;; Completion

(defun iswitch-set-common-completion  ()
  "Find common match from iswitch-matches using iswitch-text and
put the match into iswitch-common-match-string."
  (let* (val
         )
    (setq  iswitch-common-match-string nil)
    (if (and iswitch-matches
             (stringp iswitch-text)
             (> (length iswitch-text) 0))
        (if (setq val (iswitch-find-common-substring
                       iswitch-matches iswitch-text))
            (setq iswitch-common-match-string val)))
    val
    ))

(defun iswitch-complete ()
  "Try and complete the current pattern amongst the buffer names."
  (interactive)
  (let (res )
    (if (not  iswitch-matches)
        (progn
          (message "No buffer completions.")
          (sit-for 0.3)
          (iswitch-update-msg)
          )

      ;; Now we have array where to find the completion
      ;;
      (if iswitch-show-completion       ;is the pre-mode on?
          (setq res iswitch-common-match-string) ;we already know this
        (setq res (iswitch-find-common-substring
                   iswitch-matches iswitch-text)))
      (if (eq 1 (length iswitch-matches))
          ;; Only one choice, select it
          (iswitch-select-first-match)
        (if (not (memq res '(t nil)))
            ;; match was not exact
            (setq iswitch-text (iswitch-find-common-substring
                                iswitch-matches iswitch-text)))
        (setq iswitch-rescan nil)
        (iswitch-update-msg)
        ))
    ))


(defun iswitch-word-matching-substring (word)
  "Remove the part of WORD before the first match to iswitch-change-word-sub
 (given a value by the calling function).  If iswitch-change-word-sub cannot be
found in WORD, return nil. "
  (let ((case-fold-search iswitch-case)) 
    (let ((m (string-match iswitch-change-word-sub word)))
      (if m
          (substring word m)
        ;; else no match
        nil))))




(defun iswitch-find-common-substring (lis subs)
  "Return the common element of each word in LIS beginning with the
substring SUBS."
  (let (res
        alist
        iswitch-change-word-sub
        )
    (setq iswitch-change-word-sub
          (if iswitch-regexp
              subs
            (regexp-quote subs)))
    (setq res (mapcar 'iswitch-word-matching-substring lis))
    (setq res (delq nil res)) ;; remove any nil elements (shouldnt happen)
    (setq alist (mapcar 'iswitch-makealist res)) ;; could use an  OBARRAY

    ;; try-completion returns t if there is an exact match.
    (let ((completion-ignore-case iswitch-case))

    (try-completion subs alist)   
    )))

(defsubst iswitch-pre-complete ()
  "Set and find the possible completion string."
  (if iswitch-show-completion
      (iswitch-set-common-completion)))


;;; ................................................... mode functions ...

(defsubst iswitch-command-finish (&optional do-complete)
  "Finish the interactive iswitch command and perform redisplay."
  (iswitch-set-matches)
  (if do-complete
      (iswitch-pre-complete))
  (iswitch-update-msg)
  )


;;  This function is copy from Jari's tinylib.el [ti::w-list]
;;  We really shouldn't copy functions to every lisp package, but
;;  use the libs...
;;
(defun iswitch-window-list (&optional buffers)
  "Gathers all visible windows, optionally buffers visible in
current frame."
  (let* ((s     (selected-window))      ;start window
	 l
         (loop  t)
         (w     s)                      ;current cycle
         ww
	 elt
         )

    ;;  Start list
    ;;
    (if buffers
	(setq l (list (window-buffer s)))
      (setq l (list s)))

    (while loop
      (setq ww (next-window w))
      (setq w ww)                       ;change
      (other-window 1)                  ;move fwd
      (if (eq ww s)                     ;back to beginning ?
          (setq loop nil)

	(if buffers			;list of buffers instead
	    (setq ww (window-buffer ww)))
        (setq l (cons ww l))
	))

    (reverse l)
    ))




(defun iswitch-window-buffer-p  (buffer)
  "Return window pointer if buffer is visible in some window
_other_ than in the current frame."
  (interactive)
  (let ((blist (iswitch-window-list 'buffers))
	(ptr   (get-buffer buffer))
	)
    ;;  The buffer is alreadyt visible in this fram, return nil
    ;;
    ;;
    (if (memq ptr blist)
	nil
      ;;  maybe in other frame...
      (get-buffer-window buffer 'visible)
      )))

(defun iswitch-start-with-used-list  ()
  "Start the switching with used buffer list. This function
should be called from iswitch-mode-hook."
  ;; if there is no list,  do nothing special
  (cond
   (iswitch-list-entered
    (setq iswitch-list-entered-in-use t)
    (iswitch-toggle-list 'bypass)
    )))

(defun iswitch-show-whole-list  ()
  "Show all buffers if there is no matches."
  (interactive)
  (setq iswitch-show-whole-list (not iswitch-show-whole-list))
  (iswitch-update-msg)
  )

(defun iswitch-edit-prompt  ()
  "Leave iswitch mode, edit the prompt and then go back into iswitch."
  (interactive)
  ;; Use regular keymap for a while ....
  ;; todo: switch off iswitch map for a while
  (setq overriding-local-map minibuffer-local-map) 
  ;;(iswitch-define-abc-map iswitch-mode-map 'self-insert-command)
  ;; not sure if global-map is the right one to use.
  (setq iswitch-text (read-from-minibuffer "iswitch edit: " iswitch-text
					   global-map))
  
  ;; put iswitch on charge again....
  ;;
  (setq overriding-local-map iswitch-mode-map)
  ;;(iswitch-define-abc-map iswitch-mode-map 'iswitch-printing-char)
  ;;(message "after edit, text is %s" iswitch-text) ;DELME
  (setq iswitch-matches nil)          
  (iswitch-set-matches)		
  (iswitch-command-finish 'complete)
  )

(defun iswitch-find-file  ()
  "Exit iswitch and drop into find-file.  This is useful for when you find 
that the file you are looking for has not yet been visited."
  (interactive)
  (iswitch-done)
  (call-interactively 'find-file)
  )


;;; Exit functions
(defun iswitch-abort ()
  "Abort iswitch."
  (interactive)
  (iswitch-done)
  (ding)
  )

(defun iswitch-exit (buf)
  "Exit switch normally and visualize BUF according to ISWITCH-METHOD."
  (interactive)
  (iswitch-done)


  (let (newbufcreated )
    ;; check that the buffer exists
    (cond
     ((and buf (get-buffer buf))        ;does it exist ?

      ;; buffer exists, so view it and then exit
      (iswitch-visit-buffer buf)
      (message "" ))

     ;; buffer doesn't exist

     (t
      (if (and iswitch-buffer-newbuffer
               (or
                (not iswitch-buffer-prompt-newbuffer)

                (and iswitch-buffer-prompt-newbuffer
                     (y-or-n-p
                      (format
                       "No buffer matching `%s', create one? "
                  buf)))))
          ;; then create a new buffer
          (progn
            (setq newbufcreated (get-buffer-create buf))
            (if (fboundp 'set-buffer-major-mode)
                (set-buffer-major-mode newbufcreated))
            ;;(iswitch-visit-buffer newbufcreated))
            (iswitch-visit-buffer buf))
        ;; else wont create new buffer
        (message (format "no buffer matching `%s'" buf))
        )))))



(defun iswitch-visit-buffer (buffer)
  "Visit buffer named BUFFER in either same window,
other window, or other frame depending on value
of ISWITCH-METHOD."
  (let* (win
         )
    (setq iswitch-list-entered (delete buffer iswitch-list-entered))
    (setq iswitch-list-entered
	  (cons buffer iswitch-list-entered))


    ;;  keep list small enough
    (if (> (length iswitch-list-entered) 15)
        (setq iswitch-list-entered
              ;; remove one from the end
              (reverse (cdr (reverse iswitch-list-entered)))
              ))

    (cond
     ((eq iswitch-method 'samewindow)
      (switch-to-buffer buffer))

     ((memq iswitch-method '(always-frame maybe-frame))
      (cond
       ((and (setq win (iswitch-window-buffer-p buffer))
	     (or (eq iswitch-method 'always-frame)
		 (y-or-n-p "Jump to frame? ")))
	(raise-frame (select-frame (window-frame win)))
	(select-window win)
	)
       (t
	;;  No buffer in other frames...
	(switch-to-buffer buffer)
	)))



     ((eq iswitch-method 'otherwindow)
      (switch-to-buffer-other-window buffer))

     ((eq iswitch-method 'otherframe)
      (switch-to-buffer-other-frame buffer))
     )
    ))


(defun iswitch-done (&optional nopush edit)
  ;; todo - is mouse ok?
  ;;(setq mouse-leave-buffer-hook nil)
  ;; Called by all commands that terminate iswitch-mode.
  ;; If NOPUSH is non-nil, we don't push the string on the search ring.

  (setq overriding-local-map nil)
  ;(setq overriding-terminal-local-map nil)
  ;; (setq pre-command-hook iswitch-old-pre-command-hook) ; for lemacs
  ;;(iswitch-dehighlight t)

  (setq iswitch-mode nil)
  (force-mode-line-update)
  (run-hooks 'iswitch-mode-end-hook)
  )


;;; ............................................ command line handling ...
;;; Processing functions




(defun iswitch-printing-char ()
  "Process a normal printing char."
  (interactive)
  (iswitch-process-char (iswitch-last-command-char)))

(defun iswitch-process-char (char)
  ;;Process another char
  (setq iswitch-text (concat iswitch-text (make-string 1 char)))
  (iswitch-command-finish 'complete)
  )



(defun iswitch-delete-char ()
  "delete the last character from iswitch-text."
  (interactive)
  (let ((len1      (if (stringp iswitch-text)
                       (length iswitch-text)
                     0))
        )
    (if (<= len1 1)
        (setq iswitch-text "")
      (setq iswitch-text (substring iswitch-text 0 (1- len1))))
    ;; ask iswitch-matches to be regenerated.
    (setq iswitch-matches nil)          
    (iswitch-set-matches)		

    (iswitch-command-finish 'complete)
    ))


(defun iswitch-last-command-char ()
  "General function to return the last command character (simple wrapper)."
  last-command-char)



;;; Toggle functions

(defun iswitch-toggle-case ()
  "Toggle the value of iswitch-case."
  (interactive)
  (setq iswitch-case (not iswitch-case))
  (iswitch-command-finish)
  )

(defun iswitch-toggle-ignore ()
  "Toggle the value of iswitch-buffer-ignore between its original value and
nil to switch it off."
  (interactive)
  (if iswitch-buffer-ignore
      (progn
        (setq iswitch-buffer-ignore-orig iswitch-buffer-ignore)
        (setq iswitch-buffer-ignore nil)
        )
    ;; else
    (setq iswitch-buffer-ignore iswitch-buffer-ignore-orig)
    )
  (iswitch-command-finish)
  )



;;; Examples for setting the value of iswitch-buffer-ignore
;;(defun ignore-c-mode (name)
;;  "ignore all c mode buffers -- example function for iswitch"
;;  (save-excursion
;;    (set-buffer name)
;;    (string-match "^C$" mode-name)))

;;(setq iswitch-buffer-ignore '("^ " ignore-c-mode ))
;;(setq iswitch-buffer-ignore '("^ " "\\.c$" "\\.h$"))

(defun iswitch-toggle-regexp ()
  "Toggle the value of iswitch-regexp."
  (interactive)
  (setq iswitch-regexp (not iswitch-regexp))
  ;; ask for list to be regenerated.
  (setq iswitch-rescan t)
  (setq iswitch-matches nil)          ;Force full rescan
  (iswitch-set-matches)		

  (iswitch-command-finish)
  )



(defun iswitch-list-housekeeping  ()
  "Remove buffers that do not exist any more from iswitch-list-entered."
  (let* (list
       )
    (mapcar
     (function
      (lambda (buffer)
      (if (get-buffer buffer)
          (setq list (cons buffer list)))))
      iswitch-list-entered)
    (setq iswitch-list-entered (reverse list))
    ))

(defun iswitch-toggle-list  (&optional bypass-toggle)
  "Switch between available buffer lists: whole list and entered buffers.
BYPASS-TOGGLE menas that the iswitch-list-entered-in-use has
already been predefined somewhere else and the toggling should be ignored.
"
  (interactive)

  (if (null bypass-toggle)
      (setq iswitch-list-entered-in-use (not iswitch-list-entered-in-use)))

  (if iswitch-list-entered-in-use
      (setq iswitch-list iswitch-list-entered)
    (setq iswitch-list nil))


  (setq iswitch-matches nil)
  (iswitch-set-matches)
  (iswitch-update-msg)
  )

(defun iswitch-set-matches ()
  "Set iswitch-matches variable to the list of buffers matching prompt."

  (if iswitch-rescan
      (setq iswitch-matches
            (if (> (length iswitch-text) 0)

                ;;  if there is already a list, reuse it
                ;;  This kinda "gets closer"
                ;;
                (if (> (length iswitch-matches) 1)
                    (iswitch-get-matched-buffers
                     iswitch-text iswitch-regexp iswitch-matches)
                  ;; Otw get fresh list
                  (iswitch-get-matched-buffers
                   ;;iswitch-text iswitch-regexp iswitch-list)) TODO order
		   ;; should this be iswitch-list of buffer-list
                   iswitch-text iswitch-regexp 
		   (or iswitch-list (buffer-list)))) ;;eggy
	      

              ;; else no text typed in, so give a default
              ;; buffer to change to.
              (list  (buffer-name (other-buffer)))))
    )
  )


(defun iswitch-update-msg ()
  "Update the msg displayed to the user."
  (let* ((str    iswitch-common-match-string)
         (list2  iswitch-list-entered-in-use)
         (len    (if (stringp str)
                     (length str) 0))
         msg
         (list-str
                (mapconcat
                 'concat
                 (if (null iswitch-show-whole-list)
                     ""
                   (if iswitch-list
                       iswitch-list
                     (iswitch-get-matched-buffers
                      iswitch-text iswitch-regexp (buffer-list))
                     ))
                 ","))
         )

    (setq iswitch-rescan t)

    (setq msg
          (format "%s%s%s%siswitch: %s {%s%s}"
                  (if iswitch-regexp "R " "")      	;; #1 %s
                  (if iswitch-case "" "C ")        	;; #2 
                  (if iswitch-buffer-ignore "" "A ")	;; #3 
                  (if list2 "H " "")               	;; #4
                  iswitch-text                     	;; #5

                  (if (or (null iswitch-show-completion)  ;; #6

                          ;;  There is no completion
                          (not (stringp str))

                          ;; Only one match, don't show completion
                          (< (length iswitch-matches) 2)

                          ;; Should we show the string, if it's
                          ;; too short or full match, don't
                          ;; bother..
                          (< len 2)
                          (= len (length iswitch-text))
                          )
                      ""
                    (concat
                     ;; show only remaining, eg
                     ;; matched RMAIL breaks into -->
                     ;;
                     ;;  "RM"  {AIL:}
                     ;;
                     (substring
                      iswitch-common-match-string
                      (length iswitch-text))
                     ":")
                    )

                  (cond                     ;; #7
                   (iswitch-matches
                    (format
                     "%s%s"
                     (mapconcat 'concat iswitch-matches ",")
                     (if (or (null iswitch-show-whole-list)
                             (not (equal "" iswitch-text)))
                         ""
                       (concat " >>" list-str))))
                    (t
                     "<no match>"))

                  ))
    (message "%s" msg)
    ))


;;; Buffer has been selected

(defun iswitch-select-first-match ()
  "Select the first match in the list of matching buffers.
If there are no matching buffers, possibly create a new one."
  (interactive)
  (if (> (length iswitch-matches) 0)
      (iswitch-exit (car iswitch-matches))
    ;; else assume that a new buffer is to be creted.
    (iswitch-exit iswitch-text)
    ))



(defun iswitch-select-buffer-text ()
  "Select the buffer named by the prompt, or possibly create a new buffer
if no such buffer exists."
  (interactive)
  (iswitch-exit iswitch-text))



;;; Rotate through the list of matches

(defun iswitch-next-match ()
  "Put the first selected buffer at the end of the list of buffer matches."
  (interactive)
  (let ((tmp  (car iswitch-matches)) )
    (setq iswitch-matches (cdr iswitch-matches))
    (setq iswitch-matches (append iswitch-matches (list tmp)))

    (setq iswitch-rescan nil)
    (iswitch-update-msg)))

(defun iswitch-prev-match ()
  "Put the last selected buffer at the front of the list of buffer matches."
  (interactive)
  (setq iswitch-matches (iswitch-rotate-list iswitch-matches))
  (setq iswitch-rescan nil)
  (iswitch-update-msg))




;; Handling other control chars.
(defun iswitch-other-control-char ()
  "Do something with the other control characters."
  (interactive)
  (message "character not recognised by iswitch")
  (sit-for 0.3)
  (iswitch-update-msg))


;(defun iswitch-other-control-char-old ()
;  "Do something with the other control characters."
;  (interactive)
;  (iswitch-abort))

;;; Auxiliary functions

;; taken from listbuf-ignore-buffername-p in listbuf.el
;; by friedman@prep.ai.mit.edu

(defun iswitch-ignore-buffername-p (bufname)
  "Returns T if the buffer BUFNAME should be ignored."
  (let ((data       (match-data))
        (re-list    iswitch-buffer-ignore)
        ignorep
        nextstr
        )
    (while re-list
      (setq nextstr (car re-list))
      (cond
       ((stringp nextstr)
        (if (string-match nextstr bufname)
            (progn
              (setq ignorep t)
              (setq re-list nil))))
       ((fboundp nextstr)
        (if (funcall nextstr bufname)
            (progn
              (setq ignorep t)
              (setq re-list nil))
          ))
       )
      (setq re-list (cdr re-list)))
    (store-match-data data)

    ;; return the result
    ignorep)
  )


(defun iswitch-get-matched-buffers
  (regexp &optional string-format buffer-list)
  "Return matched buffers. If STRING-FORMAT is non-nil, consider
REGEXP as string.
BUFFER-LIST can be list of buffers or list of strings.
"
  (let* ((case-fold-search  iswitch-case)
	 ;; need reverse since we are building up list backwards
	 (list              (reverse (buffer-list)))
         (do-string          (stringp (car list)))
         name
         ret
         )
    (mapcar
     (function
      (lambda (x)

        (if do-string
            (setq name x)               ;We already have the name
          (setq name (buffer-name x)))

        (cond
         ((and (or (and string-format (string-match regexp name))
                   (and (null string-format)
                        (string-match (regexp-quote regexp) name)))
               (not (iswitch-ignore-buffername-p name)))
          (setq ret (cons name ret))
          ))))
     list)
    ret
    ))


(defun iswitch-makealist (res)
  "Return a dotted pair (RES . 1)"
  (cons res 1))

;; from Wayne Mesard <wmesard@esd.sgi.com>
(defun iswitch-rotate-list (lis)
  "Destructively removes the last element from LIS.
Returns the modified list with the last element prepended to it."
  (if (<= (length lis) 1)
      lis
    (let ((las lis)
          (prev lis))
      (while (consp (cdr las))
        (setq prev las
              las (cdr las)))
      (setcdr prev nil)
      (cons (car las) lis))
    ))

;;; Interfacing with mic-paren

(defvar paren-message-offscreen nil)
(defvar iswitch-paren-message-offscreen nil)

;; temp variable to keep value of paren-message-offscreen safe
;; during iswitch

(defun iswitch-micparen-off ()
  "Disable micparen while in iswitch."
  (setq iswitch-paren-message-offscreen  paren-message-offscreen)
  (setq paren-message-offscreen 'nil))

(defun iswitch-micparen-restore ()
  "Restore micparen after iswitch."
  (setq paren-message-offscreen  iswitch-paren-message-offscreen))


;; (add-hook 'iswitch-mode-hook 'iswitch-micparen-off)
;; (add-hook 'iswitch-mode-end-hook 'iswitch-micparen-restore)



;;; .................................................... final install ...
;; add iswitch-mode to the list of minor modes.
;;

(iswitch-define-mode-map)

(or (assq 'iswitch-mode minor-mode-alist)
    (setq minor-mode-alist
        (cons (list 'iswitch-mode 'iswitch-mode-name)
              minor-mode-alist)))


(provide   'iswitch-buffer)
(run-hooks 'iswitch-load-hook)

;;; iswitch-buffer.el ends here

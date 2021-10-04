;;; clearcase.el --- ClearCase/Emacs integration.

;;{{{ Introduction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is a new ClearCase/Emacs integration, still under development.
;;
;; Author: esler@rational.com
;;
;; How to use
;; ==========
;;
;;   0. Make sure you're using emacs-20.x.  I've been using 20.4.
;;      I believe 20.3 should work okay too but haven't really tested it.
;;      Emacs-19 seems to work too except for the ClearCase menu which I
;;      didn't yet have time to fix.
;;
;;   1. Make sure that you DON'T load old versions of vc-hooks.el which contain
;;      incompatible versions of the tq package (functions tq-enqueue and
;;      friends). In particular, Bill Sommerfeld's VC/CC integration has this
;;      problem.
;;
;;   2. Copy the files (or at least the clearcase.elc file) to a directory
;;      on your emacs-load-path.
;;
;;   3. Insert this in your emacs startup file:  (load "clearcase")
;;
;; When you begin editing in any view-context, a ClearCase menu will appear
;; and ClearCase Minor Mode will be activated for you.
;;
;; Summary of features
;; ===================
;;
;;   Keybindings compatible with Emacs' VC (where it makes sense)
;;   Richer interface than VC
;;   Works on NT and Unix
;;   Context sensitive menu (Emacs knows the mtype of files)
;;   Snapshot view support: update, version comparisons
;;   Can use Emacs Ediff for version comparison display
;;   Dired Mode:
;;     - en masse checkin/out etc
;;     - enhanced display
;;     - browse version tree
;;   Completion of viewnames, version strings
;;   Auto starting of views referenced as /view/TAG/.. (or \\view\TAG\...)
;;   Emacs for editing comments, config specs
;;   Launching applets
;;   Operations directly available from Emacs menu/keymap:
;;     create-activity
;;     set-activity
;;     mkelem,
;;     checkout
;;     checkin,
;;     unco,
;;     describe
;;     list history
;;     mkbrtype
;;     update view
;;     launch applets
;;     comparison using ediff, diff or applet
;;   Auto version-stamping (if enabled, e.g in this file)
;;
;; Acknowledgements
;; ================
;;
;; The help of the following is gratefully acknowledged:
;;
;;   XEmacs support and other bugfixes:
;;
;;     Rod Whitby
;;     Adrian Aichner
;;
;;   This was a result of examining earlier versions of VC and VC/ClearCase
;;   integrations and borrowing freely therefrom.  Accordingly, the following
;;   are ackowledged as contributors:
;;
;;   VC/ClearCase integration authors:
;;
;;     Bill Sommerfeld
;;     Rod Whitby
;;     Andrew Markebo
;;     Andy Eskilsson
;;     Paul Smith
;;     John Kohl
;;     Chris Felaco
;;
;;   VC authors:
;;
;;     Eric S. Raymond
;;     Andre Spiegel
;;     Sebastian Kremer
;;     Richard Stallman
;;     Per Cederqvist
;;     ttn@netcom.com
;;     Andre Spiegel
;;     Jonathan Stigelman
;;     Steve Baur
;;
;; Next enhancements needed
;; ========================
;;
;;   Faster menu construction
;;   More UCM support
;;     o deliver
;;     o create stream
;;     o connect view to stream
;;   Async history listing
;;   Refined history listing
;;   Improved Dired display
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;}}}

;;{{{ Version info

(defconst clearcase-version-stamp "ClearCase-version: </main/161>")
(defconst clearcase-version (substring clearcase-version-stamp 19))
(defconst clearcase-maintainer-address "esler@rational.com")
(defun clearcase-submit-bug-report ()
  "Submit via mail a bug report on ClearCase Mode"
  (interactive)
  (and (y-or-n-p "Do you really want to submit a report on ClearCase Mode ? ")
       (reporter-submit-bug-report
        clearcase-maintainer-address
        (concat "clearcase.el " clearcase-version)
        '(clearcase-diff-on-checkin))))

;;}}}

;;{{{ Portability

(defvar clearcase-xemacs-p (string-match "XEmacs" emacs-version))

(defvar clearcase-on-mswindows (memq system-type '(windows-nt ms-windows cygwin32)))

(defvar clearcase-on-cygwin32 (eq system-type 'cygwin32))

(defun clearcase-view-mode-quit (buf)
  "Exit from View mode, restoring the previous window configuration."
  (progn
    (cond ((frame-property (selected-frame) 'clearcase-view-window-config)
           (set-window-configuration
            (frame-property (selected-frame) 'clearcase-view-window-config))
           (set-frame-property  (selected-frame) 'clearcase-view-window-config nil))
          ((not (one-window-p))
           (delete-window)))
    (kill-buffer buf)))

(defun clearcase-view-mode (arg &optional camefrom)
  (if clearcase-xemacs-p
      (let* ((winconfig (current-window-configuration))
             (was-one-window (one-window-p))
             (buffer-name (buffer-name (current-buffer)))
             (clearcase-view-not-visible
              (not (and (windows-of-buffer buffer-name) ;shortcut
                        (memq (selected-frame)
                              (mapcar 'window-frame
                                      (windows-of-buffer buffer-name)))))))
        (when clearcase-view-not-visible
          (set-frame-property (selected-frame)
                              'clearcase-view-window-config winconfig))
        (view-mode camefrom 'clearcase-view-mode-quit)
        (setq buffer-read-only nil))
    (view-mode arg)))

(defun clearcase-port-view-buffer-other-window (buffer)
  (if clearcase-xemacs-p
      (switch-to-buffer-other-window buffer)
    (view-buffer-other-window buffer nil 'kill-buffer)))

(defun clearcase-dired-sort-by-date ()
  (if (fboundp 'dired-sort-by-date)
      (dired-sort-by-date)))

;; Copied from emacs-20
;;
(if (not (fboundp 'subst-char-in-string))
    (defun subst-char-in-string (fromchar tochar string &optional inplace)
      "Replace FROMCHAR with TOCHAR in STRING each time it occurs.
Unless optional argument INPLACE is non-nil, return a new string."
      (let ((i (length string))
            (newstr (if inplace string (copy-sequence string))))
        (while (> i 0)
          (setq i (1- i))
          (if (eq (aref newstr i) fromchar)
              (aset newstr i tochar)))
        newstr)))

;;}}}

;;{{{ Require calls

;; nyi: we also use these at the moment:
;;     -view
;;     -ediff
;;     -view
;;     -dired-sort

;; nyi: any others ?

(require 'cl)
(require 'comint)
(require 'dired)
(require 'easymenu)
(require 'reporter)
(require 'ring)
(or clearcase-xemacs-p
    (require 'timer))

;; NT Emacs - doesn't use tq.
;;
(if (not clearcase-on-mswindows)
    (require 'tq))

;;}}}

;;{{{ Debugging facilities

;; Setting this to true will enable some debug code.
;;
(defvar clearcase-debug t)
(defmacro clearcase-when-debugging (&rest forms)
  (list 'if 'clearcase-debug (cons 'progn forms)))

(defun clearcase-trace (string)
  (clearcase-when-debugging
   (let ((trace-buf (get-buffer "*clearcase-trace*")))
     (if trace-buf
         (save-excursion
           (set-buffer trace-buf)
           (goto-char (point-max))
           (insert string "\n"))))))

(defun clearcase-dump ()
  (interactive)
  (let ((buf (get-buffer-create "*clearcase-dump*"))
        (camefrom (current-buffer)))
    (save-excursion
      (set-buffer buf)
      (clearcase-view-mode 0 camefrom)
      (erase-buffer))
    (clearcase-fprop-dump buf)
    (clearcase-vprop-dump buf)
    (clearcase-port-view-buffer-other-window buf)
    (goto-char 0)
    (set-buffer-modified-p nil)         ; XEmacs - fsf uses `not-modified'
    (shrink-window-if-larger-than-buffer)))

(defun clearcase-flush-caches ()
  (interactive)
  (clearcase-fprop-clear-all-properties)
  (clearcase-vprop-clear-all-properties))

;;}}}

;;{{{ Customizable variables

;; nyi: check all of these for relevance

(eval-and-compile
  (condition-case ()
      (require 'custom)
    (error nil))
  (if (and (featurep 'custom)
           (fboundp 'custom-declare-variable))
      nil;; We've got what we needed
    ;; We have the old custom-library, hack around it!
    (defmacro defgroup (&rest args)
      nil)
    (defmacro defcustom (var value doc &rest args)
      (` (defvar (, var) (, value) (, doc))))
    (defmacro defface (face value doc &rest stuff)
      `(make-face ,face))
    (defmacro custom-declare-variable (symbol value doc &rest args)
      (list 'defvar (eval symbol) value doc))))

(defgroup clearcase () "ClearCase Options" :group 'tools :prefix "clearcase")

(defcustom clearcase-complete-viewtags t
  "*If non-nil, completion on viewtags is enabled. For sites with thousands of view
this should be set to nil."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-minimise-menus nil
  "*If non-nil, menus will hide rather than grey-out inapplicable choices."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-make-backup-files nil
  "*If non-nil, backups of ClearCase files are made as with other files.
If nil (the default), ClearCase don't get backups."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-follow-symlinks 'ask
  "*Indicates what to do if you visit a symbolic link to a file
that is under version control.  Editing such a file through the
link bypasses the version control system, which is dangerous and
probably not what you want.
  If this variable is t, ClearCase Mode follows the link and visits
the real file, telling you about it in the echo area.  If it is `ask',
ClearCase Mode asks for confirmation whether it should follow the link.
If nil, the link is visited and a warning displayed."
  :group 'clearcase
  :type '(radio (const :tag "Never follow symlinks" nil)
                (const :tag "Automatically follow symlinks" t)
                (const :tag "Prompt before following symlinks" ask)))

(defcustom clearcase-display-status t
  "*If non-nil, display version string and reservation status in modeline.
Otherwise, not displayed."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-display-branch t
  "*If non-nil, full branch name of ClearCase working file displayed in modeline.
Otherwise, just the version number or label is displayed."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-auto-dired-mode t
  "*If non-nil, automatically enter `clearcase-dired-mode' in dired-mode buffers where
version control is set-up."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-dired-highlight t
  "If non-nil, highlight reserved files in clearcase-dired buffers."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-checkout-dir-on-mkelem 'ask
  "*If t, automatically checkout the directory (if needed) when creating an element.
If nil, don't checkout the directory and cancel the registration.
If `ask', prompt before checking out the directory.

This only applies to version control systems with versioned directories (namely
ClearCase."
  :group 'clearcase
  :type '(radio (const :tag "Never checkout dir on mkelem" nil)
                (const :tag "Automatically checkout dir on mkelem" t)
                (const :tag "Prompt to checkout dir on mkelem" ask)))

(defcustom clearcase-alternate-lsvtree nil
  "Use an alternate external program instead of xlsvtree"
  :group 'clearcase
  :type '(radio (const :tag "Use default" nil)
                (string :tag "Command")))

(defcustom clearcase-diff-on-checkin nil
  "Display diff on checkin to help you compose the checkin comment."
  :group 'clearcase
  :type 'boolean)

;; General customization

(defcustom clearcase-suppress-confirm nil
  "If non-nil, treat user as expert; suppress yes-no prompts on some things."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-initial-mkelem-comment nil
  "Prompt for initial comment when an element is created."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-command-messages nil
  "Display run messages from back-end commands."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-mistrust-permissions 'file-symlink-p
  "Don't assume that permissions and ownership track version-control status."
  :group 'clearcase
  :type '(radio (const :tag "Trust permissions" nil)
                (symbol :tag "Function")))

(defcustom clearcase-checkin-switches nil
  "Extra switches passed to the checkin program by \\[clearcase-checkin]."
  :group 'clearcase
  :type '(radio (const :tag "No extra switches" nil)
                (string :tag "Switches")))

(defcustom clearcase-default-comment "[no seeded comment]"
  "Default comment for when no checkout comment is available, or
for those version control systems which don't support checkout comments."
  :group 'clearcase
  :type 'string)

(defcustom clearcase-checkin-on-mkelem nil
  "If t, file will be checked-in when first created as an element."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-suppress-checkout-comments nil
  "Suppress prompts for checkout comments for those version control
systems which use them."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-checkout-switches nil
  "Extra switches passed to the checkout program by \\[clearcase-commented-checkout]."
  :group 'clearcase
  :type '(radio (const :tag "No extra switches" nil)
                (string :tag "Switches")))

(defcustom clearcase-directory-exclusion-list '("lost+found")
  "Directory names ignored by functions that recursively walk file trees."
  :group 'clearcase
  :type '(repeat (string :tag "Subdirectory")))

(defcustom clearcase-after-checkin-hook nil
  "List of functions called after a checkin is done.  See `run-hooks'."
  :group 'clearcase
  :type 'hook)

(defcustom clearcase-before-checkin-hook nil
  "List of functions called before a checkin is done.  See `run-hooks'."
  :group 'clearcase
  :type 'hook)

(defcustom clearcase-after-mkelem-hook nil
  "List of functions called after a mkelem is done.  See `run-hooks'."
  :group 'clearcase
  :type '(repeat (symbol :tag "Function")))

(defcustom clearcase-before-mkelem-hook nil
  "List of functions called before a mkelem is done.  See `run-hooks'."
  :group 'clearcase
  :type '(repeat (symbol :tag "Function")))

(defcustom clearcase-use-normal-diff nil
  "If non-nil, use normal diff instead of cleardiff."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-normal-diff-program "diff"
  "*Program to use for generating the differential of the two files
when `clearcase-use-normal-diff' is t."
  :group 'clearcase
  :type 'string)

(defcustom clearcase-normal-diff-switches "-u"
  "*Switches (combined into single string) passed to `clearcase-normal-diff-program'
when `clearcase-use-normal-diff' is t.  Usage of the -u switch is
recommended to produce unified diffs, when your
`clearcase-normal-diff-program' supports it."
  :group 'clearcase
  :type 'string)

(defcustom clearcase-cleartool-path
  (if clearcase-on-mswindows
      (cond
       ((file-exists-p "d:/Program Files/Rational/Clearcase/bin/cleartool.exe")
        "d:/Program Files/Rational/Clearcase/bin/cleartool")
       ((file-exists-p "c:/Program Files/Rational/Clearcase/bin/cleartool.exe")
        "c:/Program Files/Rational/Clearcase/bin/cleartool")
       ((file-exists-p "d:/atria/bin/cleartool.exe")
        "d:/atria/bin/cleartool")
       ((file-exists-p "c:/atria/bin/cleartool.exe")
        "c:/atria/bin/cleartool.exe")
       (t
        "cleartool"))
    (if (file-exists-p "/usr/atria/bin/cleartool")
        "/usr/atria/bin/cleartool"
      "cleartool"))

  "Path to ClearCase cleartool"
  :group 'clearcase
  :type 'file)

(defcustom clearcase-vxpath-glue "@@"
  "The string used to construct version-extended pathnames."
  :group 'clearcase
  :type 'string)

(defcustom clearcase-viewroot (if clearcase-on-mswindows
                                  "//view"
                                "/view")
  "The ClearCase viewroot directory."
  :group 'clearcase
  :type 'file)

(defcustom clearcase-viewroot-drive "m:"
  "The ClearCase viewroot drive letter for Windows."
  :group 'clearcase
  :type 'string)

(defcustom clearcase-suppress-vc-within-mvfs t
  "Suppresses VC activity within the MVFS."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-hide-rebase-activities t
  "Hide rebase activities from activity selection list."
  :group 'clearcase
  :type 'boolean)

(defcustom clearcase-rebase-id-regexp "^rebase\\."
  "The regexp used to detect rebase actvities."
  :group 'clearcase
  :type 'string)

;;}}}

;;{{{ Global variables

;; On Win32, allow either slash when parsing pathnames.
;;
(defvar clearcase-pname-sep-regexp (if clearcase-on-mswindows
                                       "[\\/]"
                                     "[/]"))

(defvar clearcase-non-pname-sep-regexp (if clearcase-on-mswindows
                                           "[^/\\]"
                                         "[^/]"))

;; Matches any viewtag (without the trailing "/").
;;
(defvar clearcase-viewtag-regexp
  (concat "^"
          clearcase-viewroot
          clearcase-pname-sep-regexp
          "\\("
          clearcase-non-pname-sep-regexp "*"
          "\\)"
          "$"
          ))

;; Matches ANY viewroot-relative path
;;
(defvar clearcase-vrpath-regexp
  (concat "^"
          clearcase-viewroot
          clearcase-pname-sep-regexp
          "\\("
          clearcase-non-pname-sep-regexp "*"
          "\\)"
          ))

;;}}}

;;{{{ Minor Mode: ClearCase

;; For ClearCase Minor Mode
;;
(defvar clearcase-mode nil)
(set-default 'clearcase-mode nil)
(make-variable-buffer-local 'clearcase-mode)
(put 'clearcase-mode 'permanent-local t)

;; Tell Emacs about this new kind of minor mode
;;
(if (not (assoc 'clearcase-mode minor-mode-alist))
    (setq minor-mode-alist (cons '(clearcase-mode clearcase-mode)
                                 minor-mode-alist)))

;; For now we override the bindings for VC Minor Mode with ClearCase Minor Mode
;; bindings.
;;
(defvar clearcase-mode-map (make-sparse-keymap))
(defvar clearcase-prefix-map (make-sparse-keymap))
(define-key clearcase-mode-map "\C-xv" clearcase-prefix-map)
;; nyi: make this a customisable choice:
;;
(define-key clearcase-mode-map "\C-x\C-q" 'clearcase-toggle-read-only)

(define-key clearcase-prefix-map "b" 'clearcase-browse-vtree-current-buffer)
(define-key clearcase-prefix-map "c" 'clearcase-uncheckout-current-buffer)
(define-key clearcase-prefix-map "e" 'clearcase-edcs-edit)
(define-key clearcase-prefix-map "i" 'clearcase-mkelem-current-buffer)
(define-key clearcase-prefix-map "l" 'clearcase-list-history-current-buffer)
(define-key clearcase-prefix-map "m" 'clearcase-mkbrtype)
(define-key clearcase-prefix-map "u" 'clearcase-uncheckout-current-buffer)
(define-key clearcase-prefix-map "v" 'clearcase-next-action-current-buffer)
(define-key clearcase-prefix-map "w" 'clearcase-what-rule-current-buffer)
(define-key clearcase-prefix-map "=" 'clearcase-diff-pred-current-buffer)
(define-key clearcase-prefix-map "?" 'clearcase-describe-current-buffer)

;; To avoid confusion, we prevent VC Mode from being active at all by
;; undefining its keybindings for which ClearCase Mode doesn't yet have an
;; analogue.
;;
(define-key clearcase-prefix-map "a" 'undefined);; vc-update-change-log
(define-key clearcase-prefix-map "d" 'undefined);; vc-directory
(define-key clearcase-prefix-map "g" 'undefined);; vc-annotate
(define-key clearcase-prefix-map "h" 'undefined);; vc-insert-headers
(define-key clearcase-prefix-map "m" 'undefined);; vc-merge
(define-key clearcase-prefix-map "r" 'undefined);; vc-retrieve-snapshot
(define-key clearcase-prefix-map "s" 'undefined);; vc-create-snapshot
(define-key clearcase-prefix-map "t" 'undefined);; vc-dired-toggle-terse-mode
(define-key clearcase-prefix-map "~" 'undefined);; vc-version-other-window

;; Associate the map and the minor mode
;;
(or (not (boundp 'minor-mode-map-alist))
    (assq 'clearcase-mode (symbol-value 'minor-mode-map-alist))
    (setq minor-mode-map-alist
          (cons (cons 'clearcase-mode clearcase-mode-map)
                minor-mode-map-alist)))

(defun clearcase-mode (&optional arg)
  "ClearCase Minor Mode"

  (interactive "P")

  ;; Behave like a proper minor-mode.
  ;;
  (setq clearcase-mode
        (if (interactive-p)
            (if (null arg)
                (not clearcase-mode)

              ;; Check if the numeric arg is positive.
              ;;
              (> (prefix-numeric-value arg) 0))

          ;; else
          ;; Use the car if it's a list.
          ;;
          (if (consp arg)
              (setq arg (car arg)))
          (if (symbolp arg)
              (if (null arg)
                  (not clearcase-mode);; toggle mode switch
                (not (eq '- arg)));; True if symbol is not '-

            ;; else
            ;; assume it's a number and check that.
            ;;
            (> arg 0))))

  (if clearcase-mode
      (easy-menu-add clearcase-menu 'clearcase-mode-map))
  )

;;}}}

;;{{{ Minor Mode: ClearCase Dired

;;{{{ Reformatting the Dired buffer

;; Create a face for highlighting checked out files in clearcase-dired.
;;
(if (not (memq 'clearcase-dired-checkedout-face (face-list)))
    (progn
      (make-face 'clearcase-dired-checkedout-face)
      (set-face-foreground 'clearcase-dired-checkedout-face "red")))

(defun clearcase-dired-reformat-buffer ()
  "Reformats the current dired buffer."
  (let* ((filelist nil)
         (directory default-directory)
         subdir
         fullpath)

    ;; Iterate over each line in the buffer.
    ;;
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (cond

         ;; Case 1: Look for directory markers
         ;;
         ((setq subdir (dired-get-subdir))
          (setq directory subdir)

          (setq filelist (clearcase-dired-list-checkouts directory))

          ;; If no elements are found, we don't need to check each file, and
          ;; it's very slow.  The filelist should contain something so it
          ;; doesn't attempt to do this.
          ;;
          (if (null filelist)
              (setq filelist '(nil)))
          (message "Reformatting %s..." directory))

         ;; Case 2: Look for files (the safest way to get the filename).
         ;;
         ((setq fullpath (dired-get-filename nil t))
          ;; Expand it to get rid of . and .. entries.
          ;;
          (setq fullpath (expand-file-name fullpath))

          ;; Only modify directory listings of the correct format.
          ;;
          (and
           (looking-at
            "..\\([drwxlts-]+ \\) *[0-9]+ \\(.+\\) +[0-9]+\\( [^ 0-9]+ [0-9 ][0-9] .*\\)")
           (let* ((file-is-element (assoc fullpath filelist))
                  (owner (if file-is-element (cdr file-is-element)

                           ;; If a filelist was not specified, try to find the
                           ;; owner of a checkout.  The only time this should
                           ;; happen is when we are updating a single file
                           ;; entry.  For whole subdirectories, the filelist
                           ;; should have been generated.
                           ;;
                           (save-match-data
                             (and (null filelist)
                                  (clearcase-fprop-owner-of-checkout fullpath)))))
                  (info-length (- (match-end 2) (match-beginning 2)))
                  (rep (format "%-8s RESERVED" owner)))

             ;; Remove this element from the alist (in case multiple users have
             ;; a file checked out).
             ;;
             (if (consp file-is-element)
                 (setcar file-is-element nil))

             ;; Highlight the line if the file is reserved.
             ;;
             (if owner
                 (progn
                   (goto-char (match-beginning 2))

                   ;; Replace the user/group with user/RESERVED.
                   ;;
                   (let ((buffer-read-only nil))
                     (cond ((>= info-length 17) (setq info-length 17))
                           ((>= info-length 8) (setq info-length 8))

                           ;; The ls-lisp package has a 1-char wide column.
                           ;; Handle it.
                           ;;(t (error "Bad format.")))
                           ;; This should be fixed. Maybe for ls-lisp we should insert
                           ;; a whole new column.
                           ;;
                           (t
                            (setq rep "RESERVED")
                            (setq info-length (length "RESERVED"))))

                     (delete-char info-length)
                     (insert (substring rep 0 info-length)))

                   ;; Highlight the checked out files.
                   ;;
		   (if (fboundp 'put-text-property)
		       (let ((buffer-read-only nil))
			 (put-text-property (match-beginning 2) (match-end 2)
					    'face 'clearcase-dired-checkedout-face)))
                   ))))))
        (forward-line 1))))
  (message "Reformatting...Done"))

(defvar clearcase-dired-listing-switches (concat dired-listing-switches "d"))

(defun clearcase-dired-list-checkouts (directory)
  "Returns an alist of checked-out files to users in the directory."
  (let ((filelist nil)
        (default-directory directory))

    ;; Don't bother looking for checkouts in the version tree
    ;; nor in view-private directories.
    ;;
    (if (and (not (clearcase-vxpath-p directory))
             (not (eq 'view-private-object (clearcase-fprop-mtype directory))))
        (progn
          (message "Listing ClearCase checkouts...")

          (setq filelist (clearcase-dired-find-checkouts directory))

          ;; Check if the directory itself is checked-out.
          ;;
          (let* ((dirname (directory-file-name directory))
                 (user (clearcase-fprop-owner-of-checkout dirname)))
            (if user
                (setq filelist (cons (cons dirname user) filelist)))

            ;; Check the parent too, he's in the list.
            ;;
            (setq dirname (directory-file-name (expand-file-name (concat directory
                                                                         "..")))
                  user (clearcase-fprop-owner-of-checkout dirname))
            (if user
                (setq filelist (cons (cons dirname user) filelist))))

          (message "Listing ClearCase checkouts...done")))

    ;; Return the filelist.
    ;;
    filelist))

(defun clearcase-dired-find-checkouts (directory)

  ;; Never list checkouts in a history-mode dired buffer.
  ;;
  (if (clearcase-vxpath-p directory)
      nil
    (let ((true-directory (file-truename directory)))
      (let* (;; Trim off the view specifier.
             ;;
             (reldir (clearcase-vrpath-tail true-directory))
             (cmd (list
                   "lsco" "-fmt"
                   ;; nyi. Is this correct for all platforms ?
                   ;;
		   (if clearcase-on-mswindows
                       (if clearcase-xemacs-p
                           "\"%n %u %Tf\\n\""
                         "%n %u %Tf\\n")
                     "'%n %u %Tf\\n'")
		   "-cview"

                   ;; Put the directory so all names will be fullpaths For some
                   ;; reason ClearCase adds an extra slash if you leave the
                   ;; trailing slash on the directory, so we need to remove it.
                   ;;
                   (clearcase-path-native (directory-file-name (or reldir true-directory)))))
             (string (clearcase-path-canonicalise-slashes
                      (apply 'clearcase-ct-cleartool-cmd cmd)))
             (tmplist (clearcase-utl-split-string-at-char string ?\n)))

        ;; Return the reversed alist constructed from the file/version pairs.
        ;;
        (let ((answer (nreverse
                       (mapcar (function
                                (lambda (string)
                                  (let* ((space ? )
                                         (split-list (clearcase-utl-split-string-at-char string space))
                                         (fullname (clearcase-vxpath-cons-vxpath
                                                    (car split-list) nil
                                                    (if reldir
                                                        (caddr split-list))))
                                         (checkout-owner (cadr split-list)))
                                    (cons fullname checkout-owner))))
                               tmplist))))

          ;; Add in checkout info for "." and ".."
          ;;
          (let* ((entry ".")
                 (path (expand-file-name (concat true-directory entry))))
            (if (clearcase-fprop-checked-out path)
                (setq answer (cons (cons "." (clearcase-fprop-owner-of-checkout path))
                                   answer))))
          (let* ((entry "..")
                 (path (expand-file-name (concat true-directory entry))))
            (if (clearcase-fprop-checked-out path)
                (setq answer (cons (cons "." (clearcase-fprop-owner-of-checkout path))
                                   answer))))
          answer)))))

;;}}}

;; For ClearCase Dired Minor Mode
;;
(defvar clearcase-dired-mode nil)
(set-default 'clearcase-dired-mode nil)
(make-variable-buffer-local 'clearcase-dired-mode)

;; Tell Emacs about this new kind of minor mode
;;
(if (not (assoc 'clearcase-dired-mode minor-mode-alist))
    (setq minor-mode-alist (cons '(clearcase-dired-mode clearcase-dired-mode)
                                 minor-mode-alist)))

;; For now we override the bindings for VC Minor Mode with ClearCase Dired
;; Minor Mode bindings.
;;
(defvar clearcase-dired-mode-map (make-sparse-keymap))
(defvar clearcase-dired-prefix-map (make-sparse-keymap))
(define-key clearcase-dired-mode-map "\C-xv" clearcase-dired-prefix-map)

(define-key clearcase-dired-prefix-map "b" 'clearcase-browse-vtree-dired-file)
(define-key clearcase-dired-prefix-map "c" 'clearcase-uncheckout-dired-files)
(define-key clearcase-dired-prefix-map "e" 'clearcase-edcs-edit)
(define-key clearcase-dired-prefix-map "i" 'clearcase-mkelem-dired-files)
(define-key clearcase-dired-prefix-map "l" 'clearcase-list-history-dired-file)
(define-key clearcase-dired-prefix-map "m" 'clearcase-mkbrtype)
(define-key clearcase-dired-prefix-map "u" 'clearcase-uncheckout-dired-files)
(define-key clearcase-dired-prefix-map "v" 'clearcase-next-action-dired-files)
(define-key clearcase-dired-prefix-map "w" 'clearcase-what-rule-dired-file)
(define-key clearcase-dired-prefix-map "=" 'clearcase-diff-pred-dired-file)
(define-key clearcase-dired-prefix-map "~" 'clearcase-version-other-window)
(define-key clearcase-dired-prefix-map "?" 'clearcase-describe-dired-file)

;; To avoid confusion, we prevent VC Mode from being active at all by
;; undefining its keybindings for which ClearCase Mode doesn't yet have an
;; analogue.
;;
(define-key clearcase-dired-prefix-map "a" 'undefined);; vc-update-change-log
(define-key clearcase-dired-prefix-map "d" 'undefined);; vc-directory
(define-key clearcase-dired-prefix-map "g" 'undefined);; vc-annotate
(define-key clearcase-dired-prefix-map "h" 'undefined);; vc-insert-headers
(define-key clearcase-dired-prefix-map "m" 'undefined);; vc-merge
(define-key clearcase-dired-prefix-map "r" 'undefined);; vc-retrieve-snapshot
(define-key clearcase-dired-prefix-map "s" 'undefined);; vc-create-snapshot
(define-key clearcase-dired-prefix-map "t" 'undefined);; vc-dired-toggle-terse-mode

;; Associate the map and the minor mode
;;
(or (not (boundp 'minor-mode-map-alist))
    (assq 'clearcase-dired-mode (symbol-value 'minor-mode-map-alist))
    (setq minor-mode-map-alist
          (cons (cons 'clearcase-dired-mode clearcase-dired-mode-map)
                minor-mode-map-alist)))

(defun clearcase-dired-mode (&optional arg)
  "The augmented Dired minor mode used in ClearCase directory buffers.
All Dired commands operate normally.  Users with checked-out files
are listed in place of the file's owner and group. Keystrokes bound to
ClearCase Mode commands will execute as though they had been called
on a buffer attached to the file named in the current Dired buffer line."

  (interactive "P")

  ;; Behave like a proper minor-mode.
  ;;
  (setq clearcase-dired-mode
        (if (interactive-p)
            (if (null arg)
                (not clearcase-dired-mode)

              ;; Check if the numeric arg is positive.
              ;;
              (> (prefix-numeric-value arg) 0))

          ;; else
          ;; Use the car if it's a list.
          ;;
          (if (consp arg)
              (setq arg (car arg)))

          (if (symbolp arg)
              (if (null arg)
                  (not clearcase-dired-mode);; toggle mode switch
                (not (eq '- arg)));; True if symbol is not '-

            ;; else
            ;; assume it's a number and check that.
            ;;
            (> arg 0))))

  (if (not (eq major-mode 'dired-mode))
      (setq clearcase-dired-mode nil))

  (if (and clearcase-dired-mode clearcase-dired-highlight)
      (clearcase-dired-reformat-buffer))

  (if clearcase-dired-mode
      (easy-menu-add clearcase-dired-menu 'clearcase-dired-mode-map))
  )

;;}}}

;;{{{ Major Mode: for editing comments.

;; The major mode function.
;;
(defun clearcase-comment-mode ()
  "Major mode for editing comments for ClearCase.

These bindings are added to the global keymap when you enter this mode:

\\[clearcase-next-action-current-buffer]  perform next logical version-control operation on current file
\\[clearcase-mkelem-current-buffer]       mkelem the current file
\\[clearcase-toggle-read-only]            like next-action, but won't create elements
\\[clearcase-list-history-current-buffer] display change history of current file
\\[clearcase-uncheckout-current-buffer]   cancel checkout in buffer
\\[clearcase-diff-pred-current-buffer]    show diffs between file versions
\\[clearcase-version-other-window]        visit old version in another window

While you are entering a comment for a version, the following
additional bindings will be in effect.

\\[clearcase-comment-finish]           proceed with check in, ending comment

Whenever you do a checkin, your comment is added to a ring of
saved comments.  These can be recalled as follows:

\\[clearcase-comment-next]             replace region with next message in comment ring
\\[clearcase-comment-previous]         replace region with previous message in comment ring
\\[clearcase-comment-search-reverse]   search backward for regexp in the comment ring
\\[clearcase-comment-search-forward]   search backward for regexp in the comment ring

Entry to the clearcase-comment-mode calls the value of text-mode-hook, then
the value of clearcase-comment-mode-hook.

Global user options:
 clearcase-initial-mkelem-comment      If non-nil, require user to enter a change
                                   comment upon first checkin of the file.

 clearcase-suppress-confirm     Suppresses some confirmation prompts,
                            notably for reversions.

 clearcase-command-messages     If non-nil, display run messages from the
                            actual version-control utilities (this is
                            intended primarily for people hacking clearcase.el
                            itself).
"
  (interactive)

  ;; Major modes are supposed to just (kill-all-local-variables)
  ;; but we rely on clearcase-parent-buffer already having been set
  ;;
  ;;(let ((parent clearcase-parent-buffer))
  ;;  (kill-all-local-variables)
  ;;  (set (make-local-variable 'clearcase-parent-buffer) parent))

  (setq major-mode 'clearcase-comment-mode)
  (setq mode-name "ClearCase/Comment")

  (set-syntax-table text-mode-syntax-table)
  (use-local-map clearcase-comment-mode-map)
  (setq local-abbrev-table text-mode-abbrev-table)

  (make-local-variable 'clearcase-comment-operands)
  (make-local-variable 'clearcase-comment-ring-index)

  (set-buffer-modified-p nil)
  (setq buffer-file-name nil)
  (run-hooks 'text-mode-hook 'clearcase-comment-mode-hook))

;; The keymap.
;;
(defvar clearcase-comment-mode-map nil)
(if clearcase-comment-mode-map
    nil
  (setq clearcase-comment-mode-map (make-sparse-keymap))
  (define-key clearcase-comment-mode-map "\M-n" 'clearcase-comment-next)
  (define-key clearcase-comment-mode-map "\M-p" 'clearcase-comment-previous)
  (define-key clearcase-comment-mode-map "\M-r" 'clearcase-comment-search-reverse)
  (define-key clearcase-comment-mode-map "\M-s" 'clearcase-comment-search-forward)
  (define-key clearcase-comment-mode-map "\C-c\C-c" 'clearcase-comment-finish)
  (define-key clearcase-comment-mode-map "\C-x\C-s" 'clearcase-comment-save)
  (define-key clearcase-comment-mode-map "\C-x\C-q" 'clearcase-comment-num-num-error))

;; Constants.
;;
(defconst clearcase-comment-maximum-ring-size 32
  "Maximum number of saved comments in the comment ring.")

;; Variables.
;;
(defvar clearcase-comment-entry-mode nil)
(defvar clearcase-comment-operation nil)
(defvar clearcase-comment-operands)
(defvar clearcase-comment-ring nil)
(defvar clearcase-comment-ring-index nil)
(defvar clearcase-comment-last-match nil)
(defvar clearcase-comment-window-config nil)

;; In several contexts, this is a local variable that points to the buffer for
;; which it was made (either a file, or a ClearCase dired buffer).
;;
(defvar clearcase-parent-buffer nil)
(defvar clearcase-parent-buffer-name nil)

;;{{{ Commands and functions

(defun clearcase-comment-start-entry (uniquifier
                                      prompt
                                      continuation
                                      operands
                                      &optional parent-buffer comment-seed)

  "Accept a comment by poppping up a clearcase-comment-mode buffer
with a name derived from UNIQUIFIER, and emitting PROMPT in the minibuffer.
Set the continuation on close to CONTINUATION, which should be apply-ed to a list
formed by appending OPERANDS and the comment-string.

Optional 5th argument specifies a PARENT-BUFFER to return to when the operation
is complete.

Optional 6th argument specifies a COMMENT-SEED to insert in the comment buffer for
the user to edit."

  (let ((comment-buffer (get-buffer-create (format "*Comment-%s*" uniquifier)))
        (old-window-config (current-window-configuration))
        (parent (or parent-buffer
                    (current-buffer))))
    (pop-to-buffer comment-buffer)

    (set (make-local-variable 'clearcase-comment-window-config) old-window-config)
    (set (make-local-variable 'clearcase-parent-buffer) parent)

    (clearcase-comment-mode)
    (setq clearcase-comment-operation continuation)
    (setq clearcase-comment-operands operands)
    (if comment-seed
        (insert comment-seed))
    (message "%s  Type C-c C-c when done." prompt)))


(defun clearcase-comment-cleanup ()
  ;; Make sure it ends with newline
  ;;
  (goto-char (point-max))
  (if (not (bolp))
      (newline))

  ;; Remove useless whitespace.
  ;;
  (goto-char (point-min))
  (while (re-search-forward "[ \t]+$" nil t)
    (replace-match ""))

  ;; Remove trailing newlines, whitespace.
  ;;
  (goto-char (point-max))
  (skip-chars-backward " \n\t")
  (delete-region (point) (point-max)))

(defun clearcase-comment-finish ()
  "Complete the operation implied by the current comment."
  (interactive)

  ;;Clean and record the comment in the ring.
  ;;
  (let ((comment-buffer (current-buffer)))
    (clearcase-comment-cleanup)

    (if (null clearcase-comment-ring)
        (setq clearcase-comment-ring (make-ring clearcase-comment-maximum-ring-size)))
    (ring-insert clearcase-comment-ring (buffer-string))

    ;; Perform the operation on the operands.
    ;;
    (if clearcase-comment-operation
        (save-excursion
          (apply clearcase-comment-operation
                 (append clearcase-comment-operands (list (buffer-string)))))
      (error "No comment operation is pending"))

    ;; Return to "parent" buffer of this operation.
    ;; Remove comment window.
    ;;
    (let ((old-window-config clearcase-comment-window-config))
      (pop-to-buffer clearcase-parent-buffer)
      (delete-windows-on comment-buffer)
      (kill-buffer comment-buffer)
      (if old-window-config (set-window-configuration old-window-config)))))

(defun clearcase-comment-save-comment-for-buffer (comment buffer)
  (save-excursion
    (set-buffer buffer)
    (let ((file (buffer-file-name)))
      (if (clearcase-fprop-checked-out file)
          (progn
            (clearcase-ct-do-cleartool-command "chevent"
                                               file
                                               comment
                                               "-replace")
            (clearcase-fprop-set-comment file comment))
        (error "Can't change comment of checked-in version with this interface")))))

(defun clearcase-comment-save ()
  "Save the currently entered comment"
  (interactive)
  (let ((comment-string (buffer-string))
        (parent-buffer clearcase-parent-buffer))
    (if (not (buffer-modified-p))
        (message "(No changes need to be saved)")
      (progn
        (save-excursion
          (set-buffer parent-buffer)
          (clearcase-comment-save-comment-for-buffer comment-string parent-buffer))

        (set-buffer-modified-p nil)))))

(defun clearcase-comment-num-num-error ()
  (interactive)
  (message "Perhaps you wanted to type C-c C-c instead?"))

;; Code for the comment ring.
;;
(defun clearcase-comment-next (arg)
  "Cycle forwards through comment history."
  (interactive "*p")
  (clearcase-comment-previous (- arg)))

(defun clearcase-comment-previous (arg)
  "Cycle backwards through comment history."
  (interactive "*p")
  (let ((len (ring-length clearcase-comment-ring)))
    (cond ((or (not len) (<= len 0))
           (message "Empty comment ring")
           (ding))
          (t
           (erase-buffer)

           ;; Initialize the index on the first use of this command so that the
           ;; first M-p gets index 0, and the first M-n gets index -1.
           ;;
           (if (null clearcase-comment-ring-index)
               (setq clearcase-comment-ring-index
                     (if (> arg 0) -1
                       (if (< arg 0) 1 0))))
           (setq clearcase-comment-ring-index
                 (mod (+ clearcase-comment-ring-index arg) len))
           (message "%d" (1+ clearcase-comment-ring-index))
           (insert (ring-ref clearcase-comment-ring clearcase-comment-ring-index))))))

(defun clearcase-comment-search-forward (str)
  "Searches forwards through comment history for substring match."
  (interactive "sComment substring: ")
  (if (string= str "")
      (setq str clearcase-comment-last-match)
    (setq clearcase-comment-last-match str))
  (if (null clearcase-comment-ring-index)
      (setq clearcase-comment-ring-index 0))
  (let ((str (regexp-quote str))
        (n clearcase-comment-ring-index))
    (while (and (>= n 0) (not (string-match str (ring-ref clearcase-comment-ring n))))
      (setq n (- n 1)))
    (cond ((>= n 0)
           (clearcase-comment-next (- n clearcase-comment-ring-index)))
          (t (error "Not found")))))

(defun clearcase-comment-search-reverse (str)
  "Searches backwards through comment history for substring match."
  (interactive "sComment substring: ")
  (if (string= str "")
      (setq str clearcase-comment-last-match)
    (setq clearcase-comment-last-match str))
  (if (null clearcase-comment-ring-index)
      (setq clearcase-comment-ring-index -1))
  (let ((str (regexp-quote str))
        (len (ring-length clearcase-comment-ring))
        (n (1+ clearcase-comment-ring-index)))
    (while (and (< n len)
                (not (string-match str (ring-ref clearcase-comment-ring n))))
      (setq n (+ n 1)))
    (cond ((< n len)
           (clearcase-comment-previous (- n clearcase-comment-ring-index)))
          (t (error "Not found")))))

;;}}}

;;}}}

;;{{{ Major Mode: for editing config-specs.

;; The major mode function.
;;
(defun clearcase-edcs-mode ()
  (interactive)
  (set-syntax-table text-mode-syntax-table)
  (use-local-map clearcase-edcs-mode-map)
  (setq major-mode 'clearcase-edcs-mode)
  (setq mode-name "ClearCase/edcs")
  (make-variable-buffer-local 'clearcase-parent-buffer)
  (set-buffer-modified-p nil)
  (setq buffer-file-name nil)
  (run-hooks 'text-mode-hook 'clearcase-edcs-mode-hook))

;; The keymap.
;;
(defvar clearcase-edcs-mode-map nil)
(if clearcase-edcs-mode-map
    nil
  (setq clearcase-edcs-mode-map (make-sparse-keymap))
  (define-key clearcase-edcs-mode-map "\C-c\C-c" 'clearcase-edcs-finish)
  (define-key clearcase-edcs-mode-map "\C-x\C-s" 'clearcase-edcs-save))

;; Variables.
;;
(defvar clearcase-edcs-tag-name nil
  "Name of view tag which is currently being edited")

(defvar clearcase-edcs-tag-history ()
  "History of view tags used in clearcase-edcs-edit")

;;{{{ Commands

(defun clearcase-edcs-edit (tag-name)
  "Edit a ClearCase configuration specification"
  (interactive
   (let ((vxname (clearcase-fprop-viewtag default-directory)))
     (list (directory-file-name
            (completing-read "View Tag: "
                             (clearcase-viewtag-all-viewtags-obarray)
                             nil
                             ;;'fascist
                             nil
                             vxname
                             'clearcase-edcs-tag-history)))))
  (let ((start (current-buffer))
        (buffer-name (format "*ClearCase-Config-%s*" tag-name)))
    (kill-buffer (get-buffer-create buffer-name))
    (pop-to-buffer (get-buffer-create buffer-name))
    (auto-save-mode auto-save-default)
    (erase-buffer)
    (insert (clearcase-ct-cleartool-cmd "catcs" "-tag" tag-name))
    (goto-char (point-min))
    (re-search-forward "^[^#\n]" nil 'end)
    (beginning-of-line)
    (clearcase-edcs-mode)
    (setq clearcase-parent-buffer start)
    (make-local-variable 'clearcase-edcs-tag-name)
    (setq clearcase-edcs-tag-name tag-name)))

(defun clearcase-edcs-save ()
  (interactive)
  (if (not (buffer-modified-p))
      (message "Configuration not changed since last saved")
    (let ((tmp (clearcase-utl-temp-filename)))
      (unwind-protect
          (progn
            (message "Setting configuration for %s..." clearcase-edcs-tag-name)
            (write-region (point-min) (point-max) tmp nil 'dont-mention-it)
            (let ((ret (clearcase-ct-cleartool-cmd "setcs"
                                                   "-tag"
                                                   clearcase-edcs-tag-name
                                                   (clearcase-path-native tmp))))
              (if (string-match "cleartool: Error:" ret)
                  (error (substring ret (match-end 0)))))

            ;; nyi: we could be smarter and retain viewtag info and perhaps some
            ;;      other info. For now invalidate all cached file property info.
            ;;
            (clearcase-fprop-clear-all-properties)

            (set-buffer-modified-p nil)
            (message "Setting configuration for %s...done" clearcase-edcs-tag-name))
        (if (file-exists-p tmp)
            (delete-file tmp))))))

(defun clearcase-edcs-finish ()
  (interactive)
  (let ((old-buffer (current-buffer)))
    (clearcase-edcs-save)
    (bury-buffer nil)
    (kill-buffer old-buffer)))

;;}}}

;;}}}

;;{{{ View browser

;; nyi: Just an idea now.
;;      Be able to present a selection of views at various times
;;        - show me current file in other view
;;        - top-level browse operation

;;  clearcase-viewtag-started-viewtags gives us the dynamic views that are mounted.

;;  How to find local snapshots ?

;; How to find drive-letter mount points for view on NT ?
;;  - parse "subst" output

;;}}}

;;{{{ Commands

;;{{{ UCM operations

;;{{{ make activity

(defun clearcase-ucm-mkact-current-dir (headline &optional comment)
  "Make an activity with HEADLINE and optional COMMENT,
in the stream associated with the view associated with the current directory.
The activity name is generated by ClearCase."
  (interactive "sHeadline: ")
  (let* ((viewtag (clearcase-fprop-viewtag default-directory))
         (stream  (clearcase-vprop-stream viewtag))
         (pvob    (clearcase-vprop-pvob viewtag)))
    (if (not (clearcase-vprop-ucm viewtag))
        (error "View %s is not a UCM view" viewtag))
    (if (null stream)
        (error "View %s has no stream" viewtag))
    (if (null stream)
        (error "View %s has no PVOB" viewtag))

    (if (null comment)
        ;; If no comment supplied, go and get one..
        ;;
        (progn
          (clearcase-comment-start-entry (format "new-activity-%d" (random))
                                         "Enter comment for new activity."
                                         'clearcase-ucm-mkact-current-dir
                                         (list headline)))
      ;; ...else do the operation.
      ;;
      (message "Making activity...")
      (let ((tmpfile (clearcase-utl-temp-filename))
            (qualified-stream (format "%s@%s" stream pvob))
            (quoted-headline (concat "\""
                                     (clearcase-utl-escape-double-quotes headline)
                                     "\"")))
        (unwind-protect
            (progn
              (write-region comment nil tmpfile nil 'noprint)
              (let ((ret (clearcase-ct-blocking-call "mkact" "-cfile" (clearcase-path-native tmpfile)
                                                     "-headline" quoted-headline
                                                     "-in" qualified-stream "-force")))
                (if (string-match "cleartool: Error" ret)
                    (error "Error making activity: %s" ret))))
          (if (file-exists-p tmpfile)
              (delete-file tmpfile))))

      ;; Flush the activities for this view so they'll get refreshed when needed.
      ;;
      (clearcase-vprop-flush-activities viewtag)

      (message "Making activity...done"))))

;; Not currently used as we prefer system-generated activity names for now.
;;
(defun clearcase-ucm-mkact-named-current-dir (name headline &optional comment)
  "Make an activity with NAME and HEADLINE and optional COMMENT,
in the stream associated with the view associated with the current directory"
  (interactive "sActivity name: \nsHeadline: ")
  (let* ((viewtag (clearcase-fprop-viewtag default-directory))
         (stream  (clearcase-vprop-stream viewtag))
         (pvob    (clearcase-vprop-pvob viewtag)))
    (if (not (clearcase-vprop-ucm viewtag))
        (error "View %s is not a UCM view" viewtag))
    (if (null stream)
        (error "View %s has no stream" viewtag))
    (if (null stream)
        (error "View %s has no PVOB" viewtag))

    (if (null comment)
        ;; If no comment supplied, go and get one..
        ;;
        (progn
          (clearcase-comment-start-entry name
                                         "Enter comment for new activity."
                                         'clearcase-ucm-mkact-named-current-dir
                                         (list name headline)))
      ;; ...else do the operation.
      ;;
      (message "Making activity...")
      (let ((tmpfile (clearcase-utl-temp-filename))
            (qualified-name (format "%s@%s" name pvob))
            (qualified-stream (format "%s@%s" stream pvob))
            (quoted-headline (concat "\""
                                     (clearcase-utl-escape-double-quotes headline)
                                     "\"")))
        (unwind-protect
            (progn
              (write-region comment nil tmpfile nil 'noprint)
              (let ((ret (clearcase-ct-blocking-call "mkact" "-cfile" (clearcase-path-native tmpfile)
                                                     "-headline" quoted-headline
                                                     "-in"
                                                     qualified-stream
                                                     (if (zerop (length name))
                                                         "-force"
                                                       qualified-name))))
                (if (string-match "cleartool: Error" ret)
                    (error "Error making activity: %s" ret))))
          (if (file-exists-p tmpfile)
              (delete-file tmpfile))))
      (message "Making activity...done"))))

;;}}}

;;{{{ set activity

(defun clearcase-ucm-filter-out-rebases (activities)
  (if (not clearcase-hide-rebase-activities)
      activities
    (clearcase-utl-list-filter
     (function
      (lambda (activity)
        (let ((id (car activity)))
          (not (string-match clearcase-rebase-id-regexp id)))))
     activities)))
        
(defun clearcase-ucm-set-activity-current-dir ()
  (interactive)
  (let* ((viewtag (clearcase-fprop-viewtag default-directory)))
    (if (not (clearcase-vprop-ucm viewtag))
        (error "View %s is not a UCM view" viewtag))
    ;; Filter out the rebases here if the user doesn't want to see them.
    ;;
    (let ((activities (clearcase-ucm-filter-out-rebases (clearcase-vprop-activities viewtag))))
      (if (null activities)
          (error "View %s has no activities" viewtag))
      (clearcase-ucm-make-selection-window (concat "*clearcase-activity-select-%s*" viewtag)
                                           (mapconcat
                                            (function
                                             (lambda (activity)
                                               (let ((id (car activity))
                                                     (title (cdr activity)))
                                                 (format "%s\t%s" id title))))
                                            activities
                                            "\n")
                                           'clearcase-ucm-activity-selection-interpreter
                                           'clearcase-ucm-set-activity
                                           (list viewtag)))))

(defun clearcase-ucm-activity-selection-interpreter ()
  "Extract the activity name from the buffer at point"
  (if (looking-at "^\\(.*\\)\t")
      (let ((activity-name (buffer-substring (match-beginning 1)
                                             (match-end 1))))
        activity-name)
    (error "No activity on this line")))

(defun clearcase-ucm-set-activity-none-current-dir ()
  (interactive)
  (let* ((viewtag (clearcase-fprop-viewtag default-directory)))
    (if (not (clearcase-vprop-ucm viewtag))
        (error "View %s is not a UCM view" viewtag))
    (clearcase-ucm-set-activity viewtag nil)))

(defun clearcase-ucm-set-activity (viewtag activity-name)
  (if activity-name
      ;; Set an activity
      ;;
      (progn
        (message "Setting activity...")
        (let* ((qualified-activity-name (if (string-match "@" activity-name)
                                            activity-name
                                          (concat activity-name "@" (clearcase-vprop-pvob viewtag))))
               (ret (clearcase-ct-blocking-call "setactivity" "-nc" "-view"
                                                viewtag
                                                (if qualified-activity-name
                                                    qualified-activity-name
                                                  "-none"))))
          (if (string-match "cleartool: Error" ret)
              (error "Error setting activity: %s" ret)))
        ;; Update cache
        ;;
        (clearcase-vprop-set-current-activity viewtag activity-name)
        (message "Setting activity...done"))

    ;; Set NO activity
    ;;
    (message "Unsetting activity...")
    (let ((ret (clearcase-ct-blocking-call "setactivity" "-nc" "-view"
                                           viewtag "-none")))
      (if (string-match "cleartool: Error" ret)
          (error "Error unsetting activity: %s" ret)))
    ;; Update cache
    ;;
    (clearcase-vprop-set-current-activity viewtag nil)
    (message "Unsetting activity...done")))

;;}}}

;;}}}

;;{{{ Next-action

(defun clearcase-next-action-current-buffer ()
  "Do the next logical operation on the current file.
Operations include mkelem, checkout, checkin, uncheckout"
  (interactive)
  (clearcase-next-action buffer-file-name))

(defun clearcase-next-action-dired-files ()
  "Do the next logical operation on the marked files.
Operations include mkelem, checkout, checkin, uncheckout.
If all the files are not in an equivalent state, an error is raised."

  (interactive)
  (clearcase-next-action-seq (dired-get-marked-files)))

(defun clearcase-next-action (file)
  (let ((action (clearcase-compute-next-action file)))
    (cond

     ((eq action 'mkelem)
      (clearcase-commented-mkelem file))

     ((eq action 'checkout)
      (clearcase-commented-checkout file))

     ((eq action 'uncheckout)
      (if (yes-or-no-p "Checked-out file appears unchanged. Cancel checkout ? ")
          (clearcase-uncheckout file)))

     ((eq action 'illegal-checkin)
      (error "This file is checked out by %s" (clearcase-fprop-user file)))

     ((eq action 'checkin)
      (clearcase-commented-checkin file))

     (t
      (error "Can't compute suitable next ClearCase action for file %s" file)))))

(defun clearcase-next-action-seq (files)
  "Do the next logical operation on the sequence of FILES."

  ;; Check they're all in the same state.
  ;;
  (let ((actions (mapcar (function clearcase-compute-next-action) files)))
    (if (not (apply (function eq) actions))
        (error "Marked files are not all in the same state"))
    (let ((action (car actions)))
      (cond

       ((eq action 'mkelem)
        (clearcase-commented-mkelem-seq files))

       ((eq action 'checkout)
        (clearcase-commented-checkout-seq files))

       ((eq action 'uncheckout)
        (if (yes-or-no-p "Checked-out files appears unchanged. Cancel checkouts ? ")
            (clearcase-uncheckout-seq files)))

       ((eq action 'illegal-checkin)
        (error "These files are checked out by someone else; will no checkin"))

       ((eq action 'checkin)
        (clearcase-commented-checkin-seq files))

       (t
        (error "Can't compute suitable next ClearCase action for marked files"))))))

(defun clearcase-compute-next-action (file)
  "Compute the next logical acction on FILE."

  (cond
   ;; nyi: other cases to consider later:
   ;;
   ;;   - file is unreserved
   ;;   - file is not mastered

   ;; Case 1: it is not yet an element
   ;;         ==> mkelem
   ;;
   ((clearcase-file-ok-to-mkelem file)
    'mkelem)

   ;; Case 2: file is not checked out
   ;;         ==> checkout
   ;;
   ((clearcase-file-ok-to-checkout file)
    'checkout)

   ;; Case 3: file is checked-out but not modified in buffer or disk
   ;;         ==> offer to uncheckout
   ;;
   ((and (clearcase-file-ok-to-uncheckout file)
         (not (file-directory-p file))
         (not (buffer-modified-p))
         (not (clearcase-file-appears-modified-since-checkout-p file)))
    'uncheckout)

   ;; Case 4: file is checked-out but by somebody else using this view.
   ;;         ==> refuse to checkin
   ;;
   ((and (clearcase-fprop-checked-out file)
         (not (string= (user-login-name)
                       (clearcase-fprop-user file))))
    'illegal-checkin)

   ;; Case 5: user has checked-out the file
   ;;         ==> check it in
   ;;
   ((clearcase-file-ok-to-checkin file)
    'checkin)

   (t
    nil)))

;;}}}

;;{{{ Mkelem

(defun clearcase-mkelem-current-buffer ()
  "Make the current file into a ClearCase element."
  (interactive)

  ;; Watch out for new buffers of size 0: the corresponding file
  ;; does not exist yet, even though buffer-modified-p is nil.
  ;;
  (if (and (not (buffer-modified-p))
           (zerop (buffer-size))
           (not (file-exists-p buffer-file-name)))
      (set-buffer-modified-p t))

  (clearcase-commented-mkelem buffer-file-name))

(defun clearcase-mkelem-dired-files ()
  "Make the selected files into ClearCase elements."
  (interactive)
  (clearcase-commented-mkelem-seq (dired-get-marked-files)))

;;}}}

;;{{{ Checkin

(defun clearcase-checkin-current-buffer ()
  "Checkin the file in the current buffer."
  (interactive)

  ;; Watch out for new buffers of size 0: the corresponding file
  ;; does not exist yet, even though buffer-modified-p is nil.
  ;;
  (if (and (not (buffer-modified-p))
           (zerop (buffer-size))
           (not (file-exists-p buffer-file-name)))
      (set-buffer-modified-p t))

  (clearcase-commented-checkin buffer-file-name))

(defun clearcase-checkin-dired-files ()
  "Checkin the selected files."
  (interactive)
  (clearcase-commented-checkin-seq (dired-get-marked-files)))

(defun clearcase-dired-checkin-current-dir ()
  (interactive)
  (clearcase-commented-checkin (dired-current-directory)))

;;}}}

;;{{{ Checkout

(defun clearcase-checkout-current-buffer ()
  "Checkout the file in the current buffer."
  (interactive)
  (clearcase-commented-checkout buffer-file-name))

(defun clearcase-checkout-dired-files ()
  "Checkout the selected files."
  (interactive)
  (clearcase-commented-checkout-seq (dired-get-marked-files)))

(defun clearcase-dired-checkout-current-dir ()
  (interactive)
  (clearcase-commented-checkout (dired-current-directory)))

;;}}}

;;{{{ Uncheckout

(defun clearcase-uncheckout-current-buffer ()
  "Uncheckout the file in the current buffer."
  (interactive)
  (clearcase-uncheckout buffer-file-name))

(defun clearcase-uncheckout-dired-files ()
  "Uncheckout the selected files."
  (interactive)
  (clearcase-uncheckout-seq (dired-get-marked-files)))

(defun clearcase-dired-uncheckout-current-dir ()
  (interactive)
  (clearcase-uncheckout (dired-current-directory)))

;;}}}

;;{{{ Mkbrtype

(defun clearcase-mkbrtype (typename)
  (interactive "sBranch type name: ")
  (clearcase-commented-mkbrtype typename))

;;}}}

;;{{{ Describe

(defun clearcase-describe-current-buffer ()
  "Give a ClearCase description of the file in the current buffer."
  (interactive)
  (clearcase-describe buffer-file-name))

(defun clearcase-describe-dired-file ()
  "Describe the selected files."
  (interactive)
  (clearcase-describe (dired-get-filename)))

;;}}}

;;{{{ What-rule

(defun clearcase-what-rule-current-buffer ()
  (interactive)
  (clearcase-what-rule buffer-file-name))

(defun clearcase-what-rule-dired-file ()
  (interactive)
  (clearcase-what-rule (dired-get-filename)))

;;}}}

;;{{{ List history

(defun clearcase-list-history-current-buffer ()
  "List the change history of the current buffer in a window."
  (interactive)
  (clearcase-list-history buffer-file-name))

(defun clearcase-list-history-dired-file ()
  "List the change history of the current file."
  (interactive)
  (clearcase-list-history (dired-get-filename)))

;;}}}

;;{{{ Ediff

(defun clearcase-ediff-pred-current-buffer ()
  "Use Ediff to compare a version in the current buffer against its predecessor."
  (interactive)
  (clearcase-ediff-file-with-version buffer-file-name
                                     (clearcase-fprop-predecessor-version buffer-file-name)))

(defun clearcase-ediff-pred-dired-file ()
  "Use Ediff to compare the selected version against its predecessor."
  (interactive)
  (let ((truename (clearcase-fprop-truename (dired-get-filename))))
    (clearcase-ediff-file-with-version truename
                                       (clearcase-fprop-predecessor-version truename))))

(defun clearcase-ediff-branch-base-current-buffer()
  "Use Ediff to compare a version in the current buffer
against the base of its branch."
  (interactive)
  (clearcase-ediff-file-with-version buffer-file-name
                                     (clearcase-vxpath-version-of-branch-base buffer-file-name)))

(defun clearcase-ediff-branch-base-dired-file()
  "Use Ediff to compare the selected version against the base of its branch."
  (interactive)
  (let ((truename (clearcase-fprop-truename (dired-get-filename))))
    (clearcase-ediff-file-with-version truename
                                       (clearcase-vxpath-version-of-branch-base truename))))

(defun clearcase-ediff-named-version-current-buffer (version)
  ;; nyi: if we're in history-mode, probably should just use
  ;; (read-file-name)
  ;;
  (interactive (list (clearcase-read-version-name "Version for comparison: "
                                                  buffer-file-name)))
  (clearcase-ediff-file-with-version buffer-file-name version))

(defun clearcase-ediff-named-version-dired-file (version)
  ;; nyi: if we're in history-mode, probably should just use
  ;; (read-file-name)
  ;;
  (interactive (list (clearcase-read-version-name "Version for comparison: "
                                                  (dired-get-filename))))
  (clearcase-ediff-file-with-version  (clearcase-fprop-truename (dired-get-filename))
                                      version))

(defun clearcase-ediff-file-with-version (truename other-version)
  (let ((other-vxpath (clearcase-vxpath-cons-vxpath (clearcase-vxpath-element-part truename)
                                                    other-version)))
    (if (clearcase-file-is-in-mvfs-p truename)
        (ediff-files other-vxpath truename)
      (ediff-buffers (clearcase-vxpath-get-version-in-buffer other-vxpath)
                     (find-buffer-visiting truename)))))

;;}}}

;;{{{ Applet diff

(defun clearcase-applet-diff-pred-current-buffer ()
  "Use applet to compare a version in the current buffer against its predecessor."
  (interactive)
  (clearcase-applet-diff-file-with-version buffer-file-name
                                           (clearcase-fprop-predecessor-version buffer-file-name)))

(defun clearcase-applet-diff-pred-dired-file ()
  "Use applet to compare the selected version against its predecessor."
  (interactive)
  (let ((truename (clearcase-fprop-truename (dired-get-filename))))
    (clearcase-applet-diff-file-with-version truename
                                             (clearcase-fprop-predecessor-version truename))))

(defun clearcase-applet-diff-branch-base-current-buffer()
  "Use applet to compare a version in the current buffer
against the base of its branch."
  (interactive)
  (clearcase-applet-diff-file-with-version buffer-file-name
                                           (clearcase-vxpath-version-of-branch-base buffer-file-name)))

(defun clearcase-applet-diff-branch-base-dired-file()
  "Use applet to compare the selected version against the base of its branch."
  (interactive)
  (let ((truename (clearcase-fprop-truename (dired-get-filename))))
    (clearcase-applet-diff-file-with-version truename
                                             (clearcase-vxpath-version-of-branch-base truename))))

(defun clearcase-applet-diff-named-version-current-buffer (version)
  ;; nyi: if we're in history-mode, probably should just use
  ;; (read-file-name)
  ;;
  (interactive (list (clearcase-read-version-name "Version for comparison: "
                                                  buffer-file-name)))
  (clearcase-applet-diff-file-with-version buffer-file-name version))

(defun clearcase-applet-diff-named-version-dired-file (version)
  ;; nyi: if we're in history-mode, probably should just use
  ;; (read-file-name)
  ;;
  (interactive (list (clearcase-read-version-name "Version for comparison: "
                                                  (dired-get-filename))))
  (clearcase-applet-diff-file-with-version  (clearcase-fprop-truename (dired-get-filename))
                                            version))

(defun clearcase-applet-diff-file-with-version (truename other-version)
  (let* ((other-vxpath (clearcase-vxpath-cons-vxpath (clearcase-vxpath-element-part truename)
                                                     other-version))
         (other-file (if (clearcase-file-is-in-mvfs-p truename)
                         other-vxpath
                       (clearcase-vxpath-get-version-in-temp-file other-vxpath)))
         (applet-name (if clearcase-on-mswindows
                          "cleardiffmrg"
                        "xcleardiff")))
    (start-process-shell-command "Diff"
                                 nil
                                 applet-name
                                 other-file
                                 truename)))

;;}}}

;;{{{ Diff

(defun clearcase-diff-pred-current-buffer ()
  "Use Diff to compare a version in the current buffer against its predecessor."
  (interactive)
  (clearcase-diff-file-with-version buffer-file-name
                                    (clearcase-fprop-predecessor-version buffer-file-name)))

(defun clearcase-diff-pred-dired-file ()
  "Use Diff to compare the selected version against its predecessor."
  (interactive)
  (let ((truename (clearcase-fprop-truename (dired-get-filename))))
    (clearcase-diff-file-with-version truename
                                      (clearcase-fprop-predecessor-version truename))))

(defun clearcase-diff-branch-base-current-buffer()
  "Use Diff to compare a version in the current buffer
against the base of its branch."
  (interactive)
  (clearcase-diff-file-with-version buffer-file-name
                                    (clearcase-vxpath-version-of-branch-base buffer-file-name)))

(defun clearcase-diff-branch-base-dired-file()
  "Use Diff to compare the selected version against the base of its branch."
  (interactive)
  (let ((truename (clearcase-fprop-truename (dired-get-filename))))
    (clearcase-diff-file-with-version truename
                                      (clearcase-vxpath-version-of-branch-base truename))))

(defun clearcase-diff-named-version-current-buffer (version)
  ;; nyi: if we're in history-mode, probably should just use
  ;; (read-file-name)
  ;;
  (interactive (list (clearcase-read-version-name "Version for comparison: "
                                                  buffer-file-name)))
  (clearcase-diff-file-with-version buffer-file-name version))

(defun clearcase-diff-named-version-dired-file (version)
  ;; nyi: if we're in history-mode, probably should just use
  ;; (read-file-name)
  ;;
  (interactive (list (clearcase-read-version-name "Version for comparison: "
                                                  (dired-get-filename))))
  (clearcase-diff-file-with-version (clearcase-fprop-truename (dired-get-filename))
                                    version))

(defun clearcase-diff-file-with-version (truename other-version)
  (let ((other-vxpath (clearcase-vxpath-cons-vxpath (clearcase-vxpath-element-part truename)
                                                    other-version)))
    (if (clearcase-file-is-in-mvfs-p truename)
        (clearcase-diff-files other-vxpath truename)
      (clearcase-diff-files (clearcase-vxpath-get-version-in-temp-file other-vxpath)
                            truename))))

;;}}}

;;{{{ Browse vtree

(defun clearcase-browse-vtree-current-buffer ()
  (interactive)
  (clearcase-browse-vtree buffer-file-name))

(defun clearcase-browse-vtree-dired-file ()
  (interactive)
  (clearcase-browse-vtree (dired-get-filename)))

;;}}}

;;{{{ Applet vtree

(defun clearcase-applet-vtree-browser-current-buffer ()
  (interactive)
  (clearcase-applet-vtree-browser buffer-file-name))

(defun clearcase-applet-vtree-browser-dired-file ()
  (interactive)
  (clearcase-applet-vtree-browser (dired-get-filename)))

(defun clearcase-applet-vtree-browser (file)
  (let ((applet-name (if clearcase-on-mswindows
                         "clearvtree"
                       "xlsvtree")))
    (start-process-shell-command "Vtree_browser"
                                 nil
                                 applet-name
                                 file)))

;;}}}

;;{{{ Other applets

(defun clearcase-applet-rebase ()
  (interactive)
  (start-process-shell-command "Rebase"
                               nil
                               "clearmrgman"
                               (if clearcase-on-mswindows
                                   "/rebase"
                                 "-rebase")))

(defun clearcase-applet-merge-manager ()
  (interactive)
  (start-process-shell-command "Merge_manager"
                               nil
                               "clearmrgman"))

(defun clearcase-applet-project-explorer ()
  (interactive)
  (start-process-shell-command "Project_explorer"
                               nil
                               "clearprojexp"))

(defun clearcase-applet-snapshot-view-updater ()
  (interactive)
  (start-process-shell-command "View_updater"
                               nil
                               "clearviewupdate"))

;;}}}

;;{{{ Update snapshot

;; In a file buffer:
;;  - update current-file
;;  - update directory
;; In dired:
;;  - update dir
;;  - update marked files
;;  - update file

;; We allow several simultaneous updates, but only one per view.

(defun clearcase-update-view ()
  (interactive)
  (clearcase-update (clearcase-fprop-viewtag default-directory)))

(defun clearcase-update-default-directory ()
  (interactive)
  (clearcase-update (clearcase-fprop-viewtag default-directory) default-directory))

(defun clearcase-update-current-buffer ()
  (interactive)
  (clearcase-update (clearcase-fprop-viewtag default-directory) buffer-file-name))

(defun clearcase-update-dired-files ()
  (interactive)
  (apply (function clearcase-update)
         (cons (clearcase-fprop-viewtag default-directory)
               (dired-get-marked-files))))
;; Silence compiler complaints about free variable.
;;
(defvar clearcase-update-buffer-viewtag nil)

(defun clearcase-update (viewtag &rest pnames)
  "Run a cleartool+update process in VIEWTAG
if there isn't one already running in that view.
Other arguments PNAMES indicate files to update"

  ;; Check that there is no update process running in that view.
  ;;
  (if (apply (function clearcase-utl-or-func)
             (mapcar (function (lambda (proc)
                                 (if (not (eq 'exit (process-status proc)))
                                     (let ((buf (process-buffer proc)))
                                       (and buf
                                            (assq 'clearcase-update-buffer-viewtag (buffer-local-variables buf))
                                            (save-excursion
                                              (set-buffer buf)
                                              (equal viewtag clearcase-update-buffer-viewtag)))))))
                     (process-list)))
      (error "There is already an update running in view %s" viewtag))

  ;; All clear so:
  ;;  - create a process in a buffer
  ;;  - rename the buffer to be of the form *clearcase-update*<N>
  ;;  - mark it as one of ours by setting clearcase-update-buffer-viewtag
  ;;
  (pop-to-buffer (apply (function make-comint)
                        (append (list "clearcase-update-temp-name"
                                      clearcase-cleartool-path
                                      nil
                                      "update")
                                pnames))
                 t);; other window
  (rename-buffer "*clearcase-update*" t)
  (set (make-local-variable 'clearcase-update-buffer-viewtag) viewtag))

;;}}}

;;}}}

;;{{{ Functions

;;{{{ Basic ClearCase operations

;;{{{ Mkelem

(defun clearcase-file-ok-to-mkelem (file)
  "Test if FILE is okay to mkelem."
  (let ((mtype (clearcase-fprop-mtype file)))
    (and (not (file-directory-p file))
         (and (or (equal 'view-private-object mtype)
                  (equal 'derived-object mtype))
              (not (clearcase-file-covers-element-p file))))))

(defun clearcase-assert-file-ok-to-mkelem (file)
  "Raise an exception if FILE is not suitable for mkelem."
  (if (not (clearcase-file-ok-to-mkelem file))
      (error "%s cannot be made into an element" file)))

(defun clearcase-commented-mkelem (file &optional comment)
  "Create a new element from FILE. If COMMENT is non-nil, it
will be used, otherwise the user will be prompted to enter one."

  (clearcase-assert-file-ok-to-mkelem file)

  ;; We may need to checkout the directory.
  ;;
  (let ((containing-dir (file-name-directory file))
        user)
    (if (eq 'directory-version (clearcase-fprop-mtype containing-dir))
        (progn
          (setq user (clearcase-fprop-owner-of-checkout containing-dir))
          (if user
              (if (not (equal user (user-login-name)))
                  (error "Directory is checked-out by %s." user))
            (if (cond
                 ((eq clearcase-checkout-dir-on-mkelem 'ask)
                  (y-or-n-p (format "Checkout directory %s " containing-dir)))
                 (clearcase-checkout-dir-on-mkelem)
                 (t nil))
                (clearcase-commented-checkout containing-dir comment)
              (error "Can't make an element unless directory is checked-out."))))))

  (if (null comment)
      ;; If no comment supplied, go and get one...
      ;;
      (clearcase-comment-start-entry (file-name-nondirectory file)
                                     "Enter initial comment for the new element."
                                     'clearcase-commented-mkelem
                                     (list file)
                                     (find-file-noselect file)
                                     clearcase-initial-mkelem-comment)

    ;; ...otherwise perform the operation.
    ;;
    (clearcase-fprop-unstore-properties file)
    (message "Making element %s..." file)

    (save-excursion
      ;; Sync the buffer to disk, and get local value of clearcase-checkin-switches
      ;;
      (let ((buffer-on-file (find-buffer-visiting file)))
        (if buffer-on-file
            (progn
              (set-buffer buffer-on-file)
              (clearcase-sync-to-disk))))

      (if clearcase-checkin-on-mkelem
          (clearcase-ct-do-cleartool-command "mkelem" file comment "-ci")
        (clearcase-ct-do-cleartool-command "mkelem" file comment))
      (message "Making element %s...done" file)

      ;; Resync.
      ;;
      (clearcase-sync-from-disk file t))))

(defun clearcase-commented-mkelem-seq (files &optional comment)
  "Mkelem a sequence of FILES. If COMMENT is supplied it will be
used, otherwise the user will be prompted to enter one."

  (mapcar
   (function clearcase-assert-file-ok-to-mkelem)
   files)

  (if (null comment)
      ;; No comment supplied, go and get one...
      ;;
      (clearcase-comment-start-entry "mkelem"
                                     "Enter comment for elements' creation"
                                     'clearcase-commented-mkelem-seq
                                     (list files))
    ;; ...otherwise operate.
    ;;
    (mapcar
     (function
      (lambda (file)
        (clearcase-commented-mkelem file comment)))
     files)))

;;}}}

;;{{{ Checkin

(defun clearcase-file-ok-to-checkin (file)
  "Test if FILE is suitable for checkin."
  (let ((me (user-login-name)))
    (equal me (clearcase-fprop-owner-of-checkout file))))

(defun clearcase-assert-file-ok-to-checkin (file)
  "Raise an exception if FILE is not suitable for checkin."
  (if (not (clearcase-file-ok-to-checkin file))
      (error "You cannot checkin %s" file)))

(defun clearcase-commented-checkin (file &optional comment)
  "Check-in FILE with COMMENT. If the comment is omitted,
a buffer is popped up to accept one."

  (clearcase-assert-file-ok-to-checkin file)

  (if (null comment)
      ;; If no comment supplied, go and get one..
      ;;
      (progn
        (clearcase-comment-start-entry (file-name-nondirectory file)
                                       "Enter a checkin comment."
                                       'clearcase-commented-checkin
                                       (list file)
                                       (find-file-noselect file)
                                       (clearcase-fprop-comment file))

        ;; Also display a diff, if that is the custom:
        ;;
        (if (and (not (file-directory-p file))
                 clearcase-diff-on-checkin)
            (save-excursion
              (let ((tmp-buffer (current-buffer)))
                (message "Running diff...")
                (clearcase-diff-file-with-version file
                                                  (clearcase-fprop-predecessor-version file))
                (message "Running diff...done")
                (set-buffer "*clearcase*")
                (if (get-buffer "*clearcase-diff*")
                    (kill-buffer "*clearcase-diff*"))
                (rename-buffer "*clearcase-diff*")
                (pop-to-buffer tmp-buffer)))))

    ;; ...otherwise perform the operation.
    ;;
    (message "Checking in %s..." file)
    (save-excursion
      ;; Sync the buffer to disk, and get local value of clearcase-checkin-switches
      ;;
      (let ((buffer-on-file (find-buffer-visiting file)))
        (if buffer-on-file
            (progn
              (set-buffer buffer-on-file)
              (clearcase-sync-to-disk))))
      (apply 'clearcase-ct-do-cleartool-command "ci" file comment
             clearcase-checkin-switches))
    (message "Checking in %s...done" file)

    ;; Resync.
    ;;
    (clearcase-sync-from-disk file t)))

(defun clearcase-commented-checkin-seq (files &optional comment)
  "Checkin a sequence of FILES. If COMMENT is supplied it will be
used, otherwise the user will be prompted to enter one."

  ;; Check they're all in the right state to be checked-in.
  ;;
  (mapcar
   (function clearcase-assert-file-ok-to-checkin)
   files)

  (if (null comment)
      ;; No comment supplied, go and get one...
      ;;
      (clearcase-comment-start-entry "checkin"
                                     "Enter checkin comment."
                                     'clearcase-commented-checkin-seq
                                     (list files))
    ;; ...otherwise operate.
    ;;
    (mapcar
     (function
      (lambda (file)
        (clearcase-commented-checkin file comment)))
     files)))

;;}}}

;;{{{ Checkout

(defun clearcase-file-ok-to-checkout (file)
  "Test if FILE is suitable for checkout."
  (let ((mtype (clearcase-fprop-mtype file)))
    (and (or (eq 'version mtype)
             (eq 'directory-version mtype))
         (not (clearcase-fprop-checked-out file)))))

(defun clearcase-assert-file-ok-to-checkout (file)
  "Raise an exception if FILE is not suitable for checkout."
  (if (not (clearcase-file-ok-to-checkout file))
      (error "You cannot checkout %s" file)))

;; nyi: Offer to setact if appropriate

(defun clearcase-commented-checkout (file &optional comment)
  "Check-out FILE with COMMENT. If the comment is omitted,
a buffer is popped up to accept one."

  (clearcase-assert-file-ok-to-checkout file)

  (if (and (null comment)
           (not clearcase-suppress-checkout-comments))
      ;; If no comment supplied, go and get one...
      ;;
      (clearcase-comment-start-entry (file-name-nondirectory file)
                                     "Enter a checkout comment."
                                     'clearcase-commented-checkout
                                     (list file)
                                     (find-file-noselect file))

    ;; ...otherwise perform the operation.
    ;;
    (message "Checking out %s..." file)
    ;; Change buffers to get local value of clearcase-checkin-switches.
    ;;
    (save-excursion
      (set-buffer (or (find-buffer-visiting file)
                      (current-buffer)))
      (clearcase-ct-do-cleartool-command "co"
                                         file
                                         comment
                                         clearcase-checkout-switches))
    (message "Checking out %s...done" file)

    ;; Resync.
    ;;
    (clearcase-sync-from-disk file t)))


(defun clearcase-commented-checkout-seq (files &optional comment)
  "Checkout a sequence of FILES. If COMMENT is supplied it will be
used, otherwise the user will be prompted to enter one."

  (mapcar
   (function clearcase-assert-file-ok-to-checkout)
   files)

  (if (and (null comment)
           (not clearcase-suppress-checkout-comments))
      ;; No comment supplied, go and get one...
      ;;
      (clearcase-comment-start-entry "checkout"
                                     "Enter a checkout comment."
                                     'clearcase-commented-checkout-seq
                                     (list files))
    ;; ...otherwise operate.
    ;;
    (mapcar
     (function
      (lambda (file)
        (clearcase-commented-checkout file comment)))
     files)))

;;}}}

;;{{{ Uncheckout

(defun clearcase-file-ok-to-uncheckout (file)
  "Test if FILE is suitable for uncheckout."
  (equal (user-login-name)
         (clearcase-fprop-owner-of-checkout file)))

(defun clearcase-assert-file-ok-to-uncheckout (file)
  "Raise an exception if FILE is not suitable for uncheckout."
  (if (not (clearcase-file-ok-to-uncheckout file))
      (error "You cannot uncheckout %s" file)))

(defun clearcase-uncheckout (file)
  "Uncheckout FILE."

  (clearcase-assert-file-ok-to-uncheckout file)

  ;; If it has changed since checkout, insist the user confirm.
  ;;
  (if (and (not (file-directory-p file))
           (clearcase-file-appears-modified-since-checkout-p file)
           (not clearcase-suppress-confirm)
           (not (yes-or-no-p (format "Really discard changes to %s ?" file))))
      (message "Uncheckout of %s cancelled" file)

    ;; Go ahead and unco:
    ;;
    (message "Cancelling checkout of %s..." file)
    ;; nyi:
    ;;  - Prompt for -keep or -rm
    ;;  - offer to remove /0 branches
    ;;
    (clearcase-ct-do-cleartool-command "unco" file 'unused "-keep")
    (message "Cancelling checkout of %s...done" file)

    ;; Resync.
    ;;
    (clearcase-sync-from-disk file)))

(defun clearcase-uncheckout-seq (files)
  "Uncheckout a sequence of FILES."

  (mapcar
   (function clearcase-assert-file-ok-to-uncheckout)
   files)

  (mapcar
   (function clearcase-uncheckout)
   files))

;;}}}

;;{{{ Describe

;; nyi: use better process interface here ?

(defun clearcase-describe (file)
  "Give a ClearCase description of FILE."
  (clearcase-do-command 0 clearcase-cleartool-path file "describe")
  (clearcase-port-view-buffer-other-window "*clearcase*")
  (goto-char 0)
  (shrink-window-if-larger-than-buffer))

(defun clearcase-describe-seq (files)
  "Give a ClearCase description of the sequence of FILES."
  (error "Not yet implemented"))

;;}}}

;;{{{ Mkbrtype

(defun clearcase-commented-mkbrtype (typename &optional comment)
  (if (null comment)
      (clearcase-comment-start-entry (format "mkbrtype:%s" typename)
                                     "Enter a comment for the new branch type."
                                     'clearcase-commented-mkbrtype
                                     (list typename))
    (let ((tmpfile (clearcase-utl-temp-filename))
          (qualified-typename typename))
      (write-region comment nil tmpfile nil 'noprint)
      (if (not (string-match "@" typename)
               (setq qualified-typename
                     (format "%s@%s" typename default-directory))))

      (clearcase-ct-cleartool-cmd "mkbrtype"
                                  "-cfile"
                                  (clearcase-path-native tmpfile)
                                  qualified-typename)

      ;; nyi: use unwind-protect to remove tempfiles.
      ;;
      (if (file-exists-p tmpfile)
          (delete-file tmpfile)))))

;;}}}

;;{{{ Browse vtree (using Dired Mode)

(defun clearcase-file-ok-to-browse (file)
  (and file
       (or (equal 'version (clearcase-fprop-mtype file))
           (equal 'directory-version (clearcase-fprop-mtype file)))
       (clearcase-file-is-in-mvfs-p file)))

(defun clearcase-browse-vtree (file)
  (if (not (clearcase-fprop-file-is-version-p file))
      (error "%s is not a Clearcase element" file))

  (if (not (clearcase-file-is-in-mvfs-p file))
      (error "File is not in MVFS"))

  (let* ((version-path (clearcase-vxpath-cons-vxpath
                        file
                        (or (clearcase-vxpath-version-part file)
                            (clearcase-fprop-version file))))
         ;; nyi: Can't seem to get latest first here.
         ;;
         (dired-listing-switches (concat dired-listing-switches
                                         "rt"))

         (branch-path (file-name-directory version-path))

         ;; Position cursor to the version we came from.
         ;; If it was checked-out, go to predecessor.
         ;;
         (version-number (file-name-nondirectory
                          (if (clearcase-fprop-checked-out file)
                              (clearcase-fprop-predecessor-version file)
                            version-path))))

    (if (file-exists-p version-path)
        (progn
          ;; Invoke dired on the directory of the version branch.
          ;;
          (dired branch-path)
          (clearcase-dired-sort-by-date)

          (if (re-search-forward (concat "[ \t]+"
                                         "\\("
                                         (regexp-quote version-number)
                                         "\\)"
                                         "$")
                                 nil
                                 t)
              (goto-char (match-beginning 1))))
      (dired (concat file clearcase-vxpath-glue))

      ;; nyi: We want ANY directory in the history tree to appear with
      ;;      newest first. Probably requires a hook to dired mode.
      ;;
      (clearcase-dired-sort-by-date))))

;;}}}

;;{{{ List history

(defun clearcase-list-history (file)
  "List the change history of FILE."

  (if (eq 'version (clearcase-fprop-mtype file))
      (progn
        (clearcase-ct-do-cleartool-command "lshistory" file 'unused)
        (pop-to-buffer (get-buffer-create "*clearcase*"))
        (setq default-directory (file-name-directory file))
        (while (looking-at "=*\n")
          (delete-char (- (match-end 0) (match-beginning 0)))
          (forward-line -1))
        (goto-char (point-min))
        (if (looking-at "[\b\t\n\v\f\r ]+")
            (delete-char (- (match-end 0) (match-beginning 0))))
        (shrink-window-if-larger-than-buffer))
    (error "%s is not a ClearCase element" file)))

;;}}}

;;{{{ Diff/cmp

;; nyi: quick hack. This should really use a cleaned up version of
;;      clearcase-do-command
;;
(defun clearcase-files-are-identical (f1 f2)
  "Test if FILE1 and FILE2 have identical contents."

  (clearcase-when-debugging
   (if (not (file-exists-p f1))
       (error "%s  non-existent" f1))
   (if (not (file-exists-p f2))
       (error "%s  non-existent" f2)))

  (zerop (call-process "cleardiff" nil nil nil "-status_only" f1 f2)))

(defun clearcase-diff-files (file1 file2)
  "Run cleardiff on FILE1 and FILE2 and display the differences."
  (if clearcase-use-normal-diff
      (clearcase-do-command 2 clearcase-normal-diff-program file2 clearcase-normal-diff-switches file1)
    (clearcase-do-command 2 "cleardiff" file2 "-diff_format" file1))
  (let ((diff-size  (save-excursion
                      (set-buffer "*clearcase*")
                      (buffer-size))))
    (if (zerop diff-size)
        (message "No differences")
      (clearcase-port-view-buffer-other-window "*clearcase*")
      (goto-char 0)
      (shrink-window-if-larger-than-buffer))))

;;}}}

;;{{{ What rule

(defun clearcase-what-rule (file)
  (let ((result (clearcase-ct-cleartool-cmd "ls"
                                            "-d"
                                            (clearcase-path-native file))))
    (if (string-match "Rule: \\(.*\\)\n" result)
        (message (substring result
                            ;; Be a little more verbose
                            (match-beginning 0) (match-end 1)))
      (error result))))

;;}}}

;;}}}

;;{{{ File property cache

;; ClearCase properties of files are stored in a vector in a hashtable
;; with the absolute-filename (with no trailing slashes) as the lookup key.
;;
;; Properties are:
;;
;; [0] truename            : string
;; [1] mtype               : { nil, view-private-object, version,
;;                             directory-version, file-element,
;;                             dir-element, derived-object
;;                           }
;; [2] checked-out         : boolean
;; [3] reserved            : boolean
;; [4] version             : string
;; [5] predecessor-version : string
;; [6] oid                 : string
;; [7] user                : string
;; [8] date                : string (yyyymmdd.hhmmss)
;; [9] time-last-described : (N, N, N) time when the properties were last read from ClearCase
;; [10] viewtag            : string
;; [11] comment            : string

;; nyi: other possible properties to record:
;;      mtime when last described (lets us know when the cached properties might be stale)

;;{{{ Debug code

;; nyi: per-file describe count ?

(defun clearcase-fprop-unparse-properties (properties)
  "Return a string suitable for printing PROPERTIES."
  (concat
   (format "truename:            %s\n" (aref properties 0))
   (format "mtype:               %s\n" (aref properties 1))
   (format "checked-out:         %s\n" (aref properties 2))
   (format "reserved:            %s\n" (aref properties 3))
   (format "version:             %s\n" (aref properties 4))
   (format "predecessor-version: %s\n" (aref properties 5))
   (format "oid:                 %s\n" (aref properties 6))
   (format "user:                %s\n" (aref properties 7))
   (format "date:                %s\n" (aref properties 8))
   (format "time-last-described: %s\n" (current-time-string (aref properties 9)))
   (format "viewtag:             %s\n" (aref properties 10))
   (format "comment:             %s\n" (aref properties 11))))

(defun clearcase-fprop-display-properties (file)
  "Display the recorded ClearCase properties of FILE."
  (interactive "F")
  (let* ((abs-file (expand-file-name file))
         (properties (clearcase-fprop-lookup-properties abs-file))
         (camefrom (current-buffer)))
    (if properties
        (progn
          (set-buffer (get-buffer-create "*clearcase*"))
          (clearcase-view-mode 0 camefrom)
          (erase-buffer)
          (insert (clearcase-fprop-unparse-properties properties))
          (clearcase-port-view-buffer-other-window "*clearcase*")
          (goto-char 0)
          (set-buffer-modified-p nil)   ; XEmacs - fsf uses `not-modified'
          (shrink-window-if-larger-than-buffer))
      (error "Properties for %s not stored" file))))

(defun clearcase-fprop-dump (&optional buf)
  "Dump out the table recording ClearCase properties of files."
  (interactive)
  (let ((output-buffer (if buf
                           buf
                         (get-buffer-create "*clearcase-fprop-dump*")))
        (camefrom (current-buffer)))
    (set-buffer output-buffer)
    (or buf (clearcase-view-mode 0 camefrom))
    (or buf (erase-buffer))
    (insert (format "File describe count: %s\n" clearcase-fprop-describe-count))
    (mapatoms
     (function
      (lambda (symbol)
        (let ((properties (symbol-value symbol)))
          (insert "\n"
                  (format "key:                 %s\n" (symbol-name symbol))
		  "\n"
                  (clearcase-fprop-unparse-properties properties)))))
     clearcase-fprop-hashtable)
    (insert "\n")
    (or buf
        (progn
          (clearcase-port-view-buffer-other-window output-buffer)
          (goto-char 0)
          (set-buffer-modified-p nil)   ; XEmacs - fsf uses `not-modified'
          (shrink-window-if-larger-than-buffer)))))

;;}}}

(defvar clearcase-fprop-hashtable (make-vector 31 0)
  "Obarray for per-file ClearCase properties.")

(defun clearcase-fprop-canonicalise-path (filename)
  ;; We want DIR/y and DIR\y to map to the same cache entry on ms-windows.
  ;; We want DIR and DIR/ (and on windows DIR\) to map to the same cache entry.
  ;; 
  ;; However, on ms-windows avoid canonicalising X:/ to X: because, for some
  ;; reason, cleartool+desc fails on X:, but works on X:/
  ;;
  (setq filename (clearcase-path-canonicalise-slashes filename))
  (if (and clearcase-on-mswindows
           (string-match (concat "^" "[A-Za-z]:" clearcase-pname-sep-regexp "$")
                         filename))
      filename
    (clearcase-utl-strip-trailing-slashes filename)))

(defun clearcase-fprop-clear-all-properties ()
  "Delete all entries in the clearcase-fprop-hashtable."
  (setq clearcase-fprop-hashtable (make-vector 31 0)))

(defun clearcase-fprop-store-properties (file properties)
  "For FILE, store its ClearCase PROPERTIES in the clearcase-fprop-hashtable."
  (assert (file-name-absolute-p file))
  (set (intern (clearcase-fprop-canonicalise-path file)
               clearcase-fprop-hashtable) properties))

(defun clearcase-fprop-unstore-properties (file)
  "For FILE, delete its entry in the clearcase-fprop-hashtable."
  (assert (file-name-absolute-p file))
  (unintern (clearcase-fprop-canonicalise-path file) clearcase-fprop-hashtable))

(defun clearcase-fprop-lookup-properties (file)
  "For FILE, lookup and return its ClearCase properties from the
clearcase-fprop-hashtable."
  (assert (file-name-absolute-p file))
  (symbol-value (intern-soft (clearcase-fprop-canonicalise-path file)
                             clearcase-fprop-hashtable)))

(defun clearcase-fprop-get-properties (file)
  "For FILE, make sure it's ClearCase properties are in the hashtable
and then return them."
  (or (clearcase-fprop-lookup-properties file)
      (let ((properties
	     (condition-case nil
		 (clearcase-fprop-read-properties file)
	       (error (make-vector 31 nil)))))
        (clearcase-fprop-store-properties file properties)
        properties)))

(defun clearcase-fprop-truename (file)
  "For FILE, return its \"truename\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 0))

(defun clearcase-fprop-mtype (file)
  "For FILE, return its \"mtype\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 1))

(defun clearcase-fprop-checked-out (file)
  "For FILE, return its \"checked-out\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 2))

(defun clearcase-fprop-reserved (file)
  "For FILE, return its \"reserved\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 3))

(defun clearcase-fprop-version (file)
  "For FILE, return its \"version\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 4))

(defun clearcase-fprop-predecessor-version (file)
  "For FILE, return its \"predecessor-version\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 5))

(defun clearcase-fprop-oid (file)
  "For FILE, return its \"oid\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 6))

(defun clearcase-fprop-user (file)
  "For FILE, return its \"user\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 7))

(defun clearcase-fprop-date (file)
  "For FILE, return its \"date\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 8))

(defun clearcase-fprop-time-last-described (file)
  "For FILE, return its \"time-last-described\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 9))

(defun clearcase-fprop-viewtag (file)
  "For FILE, return its \"viewtag\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 10))

(defun clearcase-fprop-comment (file)
  "For FILE, return its \"comment\" ClearCase property."
  (aref (clearcase-fprop-get-properties file) 11))

(defun clearcase-fprop-set-comment (file comment)
  "For FILE, set its \"comment\" ClearCase property to COMMENT."
  (aset (clearcase-fprop-get-properties file) 11 comment))

(defun clearcase-fprop-owner-of-checkout (file)
  "For FILE, return whether the current user has it checked-out."
  (if (clearcase-fprop-checked-out file)
      (clearcase-fprop-user file)
    nil))

(defun clearcase-fprop-file-is-version-p (object-name)
  (if object-name
      (let ((mtype (clearcase-fprop-mtype object-name)))
        (or (eq 'version mtype)
            (eq 'directory-version mtype)))))

;; Read the object's ClearCase properties using cleartool and the Lisp reader.
;;
;; nyi: for some reason the \n before the %c necessary here so avoid confusing the
;;      cleartool/tq interface.  Completely mysterious. Arrived at by
;;      trial and error.
;;
(defvar clearcase-fprop-fmt-string

  ;; nyi: Not sure why the different forms of quotation are needed here.
  ;;
  (if clearcase-on-mswindows
      (if clearcase-xemacs-p
          ;; XEmacs/Windows
          ;;
	  (if clearcase-on-cygwin32
	      ;; Cygwin build
	      ;;
	      "[nil \\\"%m\\\" \\\"%f\\\" \\\"%Rf\\\" \\\"%Sn\\\" \\\"%PSn\\\" \\\"%On\\\" \\\"%u\\\" \\\"%Nd\\\" nil nil nil]\\n%c"
	    ;; Native build
	    ;;
	    ;;"\"[nil \\\"%m\\\" \\\"%f\\\" \\\"%Rf\\\" \\\"%Sn\\\" \\\"%PSn\\\" \\\"%On\\\" \\\"%u\\\" \\\"%Nd\\\" nil nil nil]\n%c\"")
            "[nil \\\"%m\\\" \\\"%f\\\" \\\"%Rf\\\" \\\"%Sn\\\" \\\"%PSn\\\" \\\"%On\\\" \\\"%u\\\" \\\"%Nd\\\" nil nil nil]\n%c")            

        ;; GnuEmacs/Windows
        ;;
        "[nil \"%m\" \"%f\" \"%Rf\" \"%Sn\" \"%PSn\" \"%On\" \"%u\" \"%Nd\" nil nil nil]\\n%c")
    ;; Unix
    ;;
    "'[nil \"%m\" \"%f\" \"%Rf\" \"%Sn\" \"%PSn\" \"%On\" \"%u\" \"%Nd\" nil nil nil]\\n%c'")
  
  "Format for cleartool+describe command when reading the
ClearCase properties of a file")

(defvar clearcase-fprop-describe-count 0
  "Count the number of times clearcase-fprop-read-properties is called")

(defun clearcase-fprop-read-properties (file)
  "Invoke the cleartool+describe command to obtain the ClearCase
properties of FILE."
  (assert (file-name-absolute-p file))
  (let* ((truename (clearcase-fprop-canonicalise-path (file-truename (expand-file-name file)))))

    ;; If the object doesn't exist, signal an error
    ;;
    (if (or (not (file-exists-p file))
            (not (file-exists-p truename)))
        (error "File doesn't exist: %s" file)

      ;; Run cleartool+ describe and capture the output as a string:
      ;;
      (let ((desc-string (clearcase-ct-cleartool-cmd "desc"
                                                     "-fmt"
                                                     clearcase-fprop-fmt-string
                                                     (clearcase-path-native truename))))
        (setq clearcase-fprop-describe-count (1+ clearcase-fprop-describe-count))

        ;; nyi: Push this erroror checking down into clearcase-ct-cleartool-cmd ?

        (if (string-match "cleartool: Error" desc-string)
            (error "Error reading file properties: %s" desc-string))

        ;;(clearcase-trace (format "desc of %s <<<<" truename))
        ;;(clearcase-trace desc-string)
        ;;(clearcase-trace (format "desc of %s >>>>" truename))

        ;; Read all but the comment, using the Lisp reader, and then copy
        ;; what's left as the comment.  We don't try to use the Lisp reader to
        ;; fetch the comment to avoid problems with quotation.
        ;;
        ;; nyi: it would be nice if we could make cleartool use "/" as pname-sep,
        ;;      because read-from-string will barf on imbedded "\".  For now
        ;;      run clearcase-path-canonicalise-slashes over the cleartool
        ;;      output before invoking the Lisp reader.
        ;;
        (let* ((first-read (read-from-string (clearcase-path-canonicalise-slashes desc-string)))
               (result (car first-read))
               (bytes-read (cdr first-read))
               (comment (substring desc-string (1+ bytes-read))));; skip \n

          ;; Plug in the slots I left empty:
          ;;
          (aset result 0 truename)
          (aset result 9 (current-time))

          (aset result 11 comment)

          ;; Convert mtype to an enumeration:
          ;;
          (let ((mtype-string (aref result 1)))
            (cond
             ((string= mtype-string "version")
              (aset result 1 'version))

             ((string= mtype-string "directory version")
              (aset result 1 'directory-version))

             ((string= mtype-string "view private object")
              (aset result 1 'view-private-object))

             ((string= mtype-string "file element")
              (aset result 1 'file-element))

             ((string= mtype-string "directory element")
              (aset result 1 'directory-element))

             ((string= mtype-string "derived object")
              (aset result 1 'derived-object))

             ;; For now treat checked-in DOs as versions.
             ;;
             ((string= mtype-string "derived object version")
              (aset result 1 'version))

             ;; On NT, coerce the mtype of symlinks into that
             ;; of their targets.
             ;;
             ;; nyi: I think this is approximately right.
             ;;
             ((and (string= mtype-string "symbolic link")
                   clearcase-on-mswindows)
              (if (file-directory-p truename)
                  (aset result 1 'directory-version)
                (aset result 1 'version)))

             ;; We get this on paths like foo.c@@/main
             ;;
             ((string= mtype-string "branch")
              (aset result 1 'branch))

             ((string= mtype-string "**null meta type**")
              (aset result 1 nil))

             (t
              (error "Unknown mtype returned by cleartool+describe: %s"
                     mtype-string))))

          ;; nyi: possible efficiecney win: only evaluate the viewtag on demand.
          ;;
          (if (aref result 1)
              (aset result 10 (clearcase-file-viewtag truename)))

          ;; Convert checked-out field to boolean:
          ;;
          (aset result 2 (not (zerop (length (aref result 2)))))

          ;; Convert reserved field to boolean:
          ;;
          (aset result 3 (string= "reserved" (aref result 3)))

          ;; Return the array of properties.
          ;;
          result)))))

;;}}}

;;{{{ View property cache

;; ClearCase properties of views are stored in a vector in a hashtable
;; with the viewtag as the lookup key.
;;
;; Properties are:
;;
;; [0] snapshot            : boolean (false means dynamic)
;; [1] ucm                 : boolean
;; [2] stream              : string
;; [3] pvob                : string
;; [4] activities          : list of strings
;; [5] current-activity    : string

;;{{{ Debug code

(defun clearcase-vprop-dump (&optional buf)
  "Dump out the table recording ClearCase properties of views."
  (interactive)
  (let ((output-buffer (if buf
                           buf
                         (get-buffer-create "*clearcase-vprop-dump*")))
        (camefrom (current-buffer)))
    (set-buffer output-buffer)
    (or buf (clearcase-view-mode 0 camefrom))
    (or buf (erase-buffer))
    (insert (format "View describe count: %s\n" clearcase-vprop-describe-count))
    (mapatoms
     (function
      (lambda (symbol)
        (let ((properties (symbol-value symbol)))
          (insert "\n"
		  (format "viewtag:             %s\n" (symbol-name symbol))
		  "\n"
		  (clearcase-vprop-unparse-properties properties)))))
     clearcase-vprop-hashtable)
    (insert "\n")
    (or buf
        (progn
          (clearcase-port-view-buffer-other-window output-buffer)
          (goto-char 0)
          (set-buffer-modified-p nil)   ; XEmacs - fsf uses `not-modified'
          (shrink-window-if-larger-than-buffer)))))

(defun clearcase-vprop-unparse-properties (properties)
  "Return a string suitable for printing PROPERTIES."
  (concat
   (format "snapshot:            %s\n" (aref properties 0))
   (format "ucm:                 %s\n" (aref properties 1))
   (format "stream:              %s\n" (aref properties 2))
   (format "pvob:                %s\n" (aref properties 3))
   (format "activities:          %s\n" (aref properties 4))
   (format "current-activity:    %s\n" (aref properties 5))))

;;}}}

;;{{{ Asynchronously fetching view properties:

(defvar clearcase-vprop-timer nil)
(defvar clearcase-vprop-prefetch-queue nil)
(defun clearcase-vprop-schedule-fetch (viewtag)
  (or clearcase-xemacs-p
      (if (null clearcase-vprop-timer)
          (setq clearcase-vprop-timer (timer-create))))
  (setq clearcase-vprop-prefetch-queue (cons viewtag clearcase-vprop-prefetch-queue))
  (if clearcase-xemacs-p
      (setq clearcase-vprop-timer
            (run-with-idle-timer 5 t 'clearcase-vprop-timer-function))
    (timer-set-function clearcase-vprop-timer 'clearcase-vprop-timer-function)
    (timer-set-idle-time clearcase-vprop-timer 5)
    (timer-activate-when-idle clearcase-vprop-timer)))

(defun clearcase-vprop-timer-function ()
  (mapcar (function (lambda (viewtag)
                      (clearcase-vprop-get-properties viewtag)))
          clearcase-vprop-prefetch-queue)
  (setq clearcase-vprop-prefetch-queue nil))

;;}}}

(defvar clearcase-vprop-hashtable (make-vector 31 0)
  "Obarray for per-view ClearCase properties.")

(defun clearcase-vprop-clear-all-properties ()
  "Delete all entries in the clearcase-vprop-hashtable."
  (setq clearcase-vprop-hashtable (make-vector 31 0)))

(defun clearcase-vprop-store-properties (viewtag properties)
  "For VIEW, store its ClearCase PROPERTIES in the clearcase-vprop-hashtable."
  (set (intern viewtag clearcase-vprop-hashtable) properties))

(defun clearcase-vprop-unstore-properties (viewtag)
  "For VIEWTAG, delete its entry in the clearcase-vprop-hashtable."
  (unintern viewtag clearcase-vprop-hashtable))

(defun clearcase-vprop-lookup-properties (viewtag)
  "For VIEWTAG, lookup and return its ClearCase properties from the
clearcase-vprop-hashtable."
  (symbol-value (intern-soft viewtag clearcase-vprop-hashtable)))

(defun clearcase-vprop-get-properties (viewtag)
  "For VIEWTAG, make sure it's ClearCase properties are in the hashtable
and then return them."
  (or (clearcase-vprop-lookup-properties viewtag)
      (let ((properties (clearcase-vprop-read-properties viewtag)))
        (clearcase-vprop-store-properties viewtag properties)
        properties)))

(defun clearcase-vprop-snapshot (viewtag)
  "For VIEWTAG, return its \"snapshot\" ClearCase property."
  (aref (clearcase-vprop-get-properties viewtag) 0))

(defun clearcase-vprop-ucm (viewtag)
  "For VIEWTAG, return its \"ucm\" ClearCase property."
  (aref (clearcase-vprop-get-properties viewtag) 1))

(defun clearcase-vprop-stream (viewtag)
  "For VIEWTAG, return its \"stream\" ClearCase property."
  (aref (clearcase-vprop-get-properties viewtag) 2))

(defun clearcase-vprop-pvob (viewtag)
  "For VIEWTAG, return its \"stream\" ClearCase property."
  (aref (clearcase-vprop-get-properties viewtag) 3))

(defun clearcase-vprop-activities (viewtag)
  "For VIEWTAG, return its \"activities\" ClearCase property."

  ;; If the activity set has been flushed, go and schedule a re-fetch.
  ;;
  (let ((properties (clearcase-vprop-get-properties viewtag)))
    (if (null (aref properties 4))
        (aset properties 4 (clearcase-vprop-read-activities-asynchronously viewtag))))

  ;; Now poll, waiting for the activities to be available.
  ;;
  (let ((loop-count 0))
    ;; If there is a background process still reading the activities,
    ;; wait for it to finish.
    ;;
    ;; nyi: probably want a timeout here.
    ;;
    ;; nyi: There seems to be a race on NT in accept-process-output so that
    ;;      we would wait forever.
    ;;
    (if (not clearcase-on-mswindows)
        ;; Unix synchronization with the end of the process
        ;; which is reading activities.
        ;;
        (while (bufferp (aref (clearcase-vprop-get-properties viewtag) 4))
          (save-excursion
            (set-buffer (aref (clearcase-vprop-get-properties viewtag) 4))
            (message "Reading activity list...")
            (setq loop-count (1+ loop-count))
            (accept-process-output clearcase-vprop-async-proc)))
      
      ;; NT synchronization with the end of the process which is reading
      ;; activities.
      ;;
      ;; Unfortunately on NT we can't rely on the process sentinel being called
      ;; so we have to explicitly test the process status.
      ;;
      (while (bufferp (aref (clearcase-vprop-get-properties viewtag) 4))
        (message "Reading activity list...")
        (save-excursion
          (set-buffer (aref (clearcase-vprop-get-properties viewtag) 4))
          (if (or (not (processp clearcase-vprop-async-proc))
                  (eq 'exit (process-status clearcase-vprop-async-proc)))

              ;; The process has finished or gone away and apparently
              ;; the sentinel didn't get called which would have called
              ;; clearcase-vprop-finish-reading-activities, so call it
              ;; explicitly here.
              ;;
              (clearcase-vprop-finish-reading-activities (current-buffer))

            ;; The process is apparently still running, so wait
            ;; so more.
            (setq loop-count (1+ loop-count))
            (sit-for 1)))))
      
    (if (not (zerop loop-count))
        (message "Reading activity list...done"))
    
    (aref (clearcase-vprop-get-properties viewtag) 4)))
  
(defun clearcase-vprop-current-activity (viewtag)
  "For VIEWTAG, return its \"current-activity\" ClearCase property."
  (aref (clearcase-vprop-get-properties viewtag) 5))

(defun clearcase-vprop-set-activities (viewtag activities)
  "For VIEWTAG, set its \"activities\" ClearCase property to ACTIVITIES."
  (let ((properties (clearcase-vprop-lookup-properties viewtag)))
    ;; We must only set the activities for an existing vprop entry.
    ;;
    (assert properties)
    (aset properties 4 activities)))

(defun clearcase-vprop-flush-activities (viewtag)
  "For VIEWTAG, set its \"activities\" ClearCase property to nil,
to cause a future re-fetch."
  (clearcase-vprop-set-activities viewtag nil))
  
(defun clearcase-vprop-set-current-activity (viewtag activity)
  "For VIEWTAG, set its \"current-activity\" ClearCase property to ACTIVITY."
  (aset (clearcase-vprop-get-properties viewtag) 5 activity))

;; Read the object's ClearCase properties using cleartool lsview and cleartool lsstream.
;; nyi: don't invoke lsstream unless we have V4 installed.

(defvar clearcase-vprop-describe-count 0
  "Count the number of times clearcase-vprop-read-properties is called")

(defvar clearcase-lsstream-fmt-string
  (if clearcase-on-mswindows
      (if clearcase-xemacs-p
          ;; XEmacs/Windows
          ;;
	  (if clearcase-on-cygwin32
	      ;; Cygwin build
	      ;;
	      "[\\\"%n\\\"  \\\"%[master]p\\\" ]"
	    ;; Native build
	    ;;
	    "\"[\\\"%n\\\"  \\\"%[master]p\\\" ]\"")
        ;; GnuEmacs/Windows
        ;;
        "[\"%n\"  \"%[master]p\" ]")
    ;; Unix
    ;;
    "'[\"%n\"  \"%[master]p\" ]'"))

(defvar clearcase-lsact-fmt-string
  (if clearcase-on-mswindows
      (if clearcase-xemacs-p
          ;; XEmacs/Windows
          ;;
	  (if clearcase-on-cygwin32
	      ;; Cygwin build
	      ;;
	      "%%n"
	    ;; Native build
	    ;;
	    "\"%%n\"")
        ;; GnuEmacs/Windows
        ;;
        "\"%%n\"")
    ;; Unix
    ;;
    "%%n"))
        
(defun clearcase-vprop-read-properties (viewtag)
  "Invoke the cleartool+describe command to obtain the ClearCase
properties of VIEWTAG."

  ;; Run cleartool+lsview and capture the output as a string:
  ;;
  (message "Reading view properties...")
  (let* ((result (make-vector 6 nil))
         (cmd (if clearcase-v3
                  (list "lsview" "-long")
                (list "lsview" "-properties" "-full")))
         (ls-string (apply 'clearcase-ct-blocking-call (append cmd (list viewtag)))))
    (setq clearcase-vprop-describe-count (1+ clearcase-vprop-describe-count))

    ;; nyi: Push this erroror checking down into clearcase-ct-cleartool-cmd ?
    ;;
    (if (string-match "cleartool: Error" ls-string)
        (error "Error reading view properties: %s" ls-string))

    (let ((snapshot nil)
          (ucm nil)
          (stream nil)
          (pvob nil)
          (activity-names nil)
          (activity-titles nil)
          (activities nil)
          (current-activity nil))

      (if clearcase-v3
          (setq snapshot (numberp (string-match "^View attributes:.*snapshot" ls-string)))
        (setq snapshot (numberp (string-match "^Properties:.*snapshot" ls-string))))

      (setq ucm (numberp (string-match "^Properties:.*ucmview" ls-string)))

      (if ucm
          (progn
            ;; Get the stream, activities and pvob.
            ;;
            (let* ((desc-string (clearcase-ct-blocking-call "lsstream" "-fmt"
                                                            clearcase-lsstream-fmt-string
                                                            "-view" viewtag)))
              (if (string-match "cleartool: Error" desc-string)
                  (error "Error reading view properties: %s" desc-string))
              (let* ((first-read (read-from-string (clearcase-utl-escape-backslashes desc-string)))
                     (array-read (car first-read))
                     (bytes-read (cdr first-read)))

                ;; Get stream name
                ;;
                (setq stream (aref array-read 0))

                ;; Get PVOB tag from something like "unix@/vobs/projects"
                ;;
                (let ((s (aref array-read 1)))
                  (if (string-match "@" s)
                      (setq pvob (substring s (match-end 0)))
                    (setq pvob s)))))

            ;; Get the activity list and store as a list of (NAME . TITLE) pairs
            ;;
            (setq activities (clearcase-vprop-read-activities-asynchronously viewtag))

            ;; Get the current activity
            ;;
            (let ((name-string (clearcase-ct-blocking-call "lsact" "-cact" "-fmt"
                                                           clearcase-lsact-fmt-string
                                                           "-view" viewtag)))
              (if (string-match "cleartool: Error" name-string)
                  (error "Error reading current activity: %s" name-string))
              (if (not (zerop (length name-string)))
                  (setq current-activity name-string)))))

      (aset result 0 snapshot)
      (aset result 1 ucm)
      (aset result 2 stream)
      (aset result 3 pvob)
      (aset result 4 activities)
      (aset result 5 current-activity))

    (message "Reading view properties...done")

    result))

(defvar clearcase-vprop-async-viewtag nil)
(defvar clearcase-vprop-async-proc nil)
(defun clearcase-vprop-read-activities-asynchronously (viewtag)
  ;; Clean up old instance of the buffer we use to fetch activities:
  ;;
  (let ((buf (get-buffer (format "*clearcase-activity-listing-%s*" viewtag))))
    (if buf
        (progn
          (save-excursion
            (set-buffer buf)
            (if (and (boundp 'clearcase-vprop-async-proc)
                     clearcase-vprop-async-proc)
                (condition-case ()
                    (kill-process clearcase-vprop-async-proc)
                  (error nil))))
          (kill-buffer buf))))

  ;; Create a buffer and an associated new process to read activities
  ;; in the background. We return the buffer to be stored in the
  ;; activities field of the view-properties record. The function
  ;; clearcase-vprop-activities will recognise when the asynch fetching
  ;; is still underway and wait for it to finish.
  ;;
  ;; The process has a sentinel function which is supposed to get called when
  ;; the process finishes. This sometimes doesn't happen on Windows, so that
  ;; clearcase-vprop-activities has to do a bit more work.  (Perhaps a race exists:
  ;; the process completes before the sentinel can be set ?)
  ;;
  (let* ((buf (get-buffer-create (format "*clearcase-activity-listing-%s*" viewtag)))
         (proc (start-process (format "*clearcase-activity-listing-%s*" viewtag)
                              buf
                              clearcase-cleartool-path
                              "lsact" "-view" viewtag)))
    (process-kill-without-query proc)
    (save-excursion
      (set-buffer buf)
      ;; Create a sentinel to parse and store the activities when the
      ;; process finishes. We record the viewtag as a buffer-local
      ;; variable so the sentinel knows where to store the activities.
      ;;
      (set (make-local-variable 'clearcase-vprop-async-viewtag) viewtag)
      (set (make-local-variable 'clearcase-vprop-async-proc) proc)
      (set-process-sentinel proc 'clearcase-vprop-read-activities-sentinel))
    ;; Return the buffer.
    ;;
    buf))

(defun clearcase-vprop-read-activities-sentinel (process event-string)
  (clearcase-trace "Activity reading process sentinel called")
  (if (not (equal "finished\n" event-string))
      ;; Failure
      ;;
      (error "Reading activities failed: %s" event-string))
  (clearcase-vprop-finish-reading-activities (process-buffer process)))

(defun clearcase-vprop-finish-reading-activities (buffer)
  (let ((activity-list nil))
    (message "Parsing view activities...")
    (save-excursion
      (set-buffer buffer)
      (if (or (not (boundp 'clearcase-vprop-async-viewtag))
              (null clearcase-vprop-async-viewtag))
          (error "Internal error: clearcase-vprop-async-viewtag not set"))

      ;; Check that our buffer is the one currently expected to supply the
      ;; activities. (Avoid races.)
      ;;
      (let ((properties (clearcase-vprop-lookup-properties clearcase-vprop-async-viewtag)))
        (if (and properties
                 (eq buffer (aref properties 4)))
            (progn

              ;; Parse the buffer, slicing out the 2nd and 4th fields as name and title.
              ;;
              (goto-char (point-min))
              (while (re-search-forward "^[^ \t]+[ \t]+\\([^ \t]+\\)[ \t]+[^ \t]+[ \t]+\"+\\(.*\\)\"$" nil t)
                (let ((id (buffer-substring (match-beginning 1)
                                            (match-end 1)))
                      (title (buffer-substring (match-beginning 2)
                                               (match-end 2))))
                  (setq activity-list (cons (cons id title)
                                            activity-list))))

              ;; We've got activity-list in the reverse order that
              ;; cleartool+lsactivity generated them.  I think this is reverse
              ;; chronological order, so keep this order since it is more
              ;; convenient when setting to an activity.
              ;;
              ;;(setq activity-list (nreverse activity-list))
              
              (clearcase-vprop-set-activities clearcase-vprop-async-viewtag activity-list))
          
          (kill-buffer buffer))))
    (message "Parsing view activities...done")))

;;{{{ old synchronous activity reader

(defun clearcase-vprop-read-activities-synchronously (viewtag)
  "Return a list of (activity-name . title) pairs for VIEWTAG"
  ;; nyi: ought to use a variant of clearcase-ct-blocking-call that returns a buffer
  ;;      rather than a string

  ;; Performance: takes around 30 seconds to read 1000 activities.
  ;; Too slow to invoke willy-nilly on integration streams for example,
  ;; which typically can have 1000+ activities.

  (let ((ret (clearcase-ct-blocking-call "lsact" "-view" viewtag)))
    (if (string-match "cleartool: Error" ret)
        (error "Error reading view activities: %s" ret))
    (let ((buf (get-buffer-create "*clearcase-activity-listing*"))
          (activity-list nil))
      (save-excursion
        (set-buffer buf)
        (erase-buffer)
        (insert ret)
        (goto-char (point-min))
        ;; Slice out the 2nd and 4th fields as name and title
        ;;
        (while (re-search-forward "^[^ \t]+[ \t]+\\([^ \t]+\\)[ \t]+[^ \t]+[ \t]+\"+\\(.*\\)\"$" nil t)
          (setq activity-list (cons (cons (buffer-substring (match-beginning 1)
                                                            (match-end 1))
                                          (buffer-substring (match-beginning 2)
                                                            (match-end 2)))
                                    activity-list)))
        (kill-buffer buf))

      ;; We've got activity-list in the reverse order that
      ;; cleartool+lsactivity generated them.  I think this is reverse
      ;; chronological order, so keep this order since it is more
      ;; convenient when setting to an activity.
      ;;
      ;;(nreverse activity-list))))
      activity-list)))

;;}}}

;;}}}

;;{{{ Determining if a checkout was modified.

;; How to tell if a file has been changed since checkout ?

;; If it's size differs from pred, it changed.
;; If we saw the first OID after checkout and it is different now, it changed
;; Otherwise use outboard cmp routine ? Perl ?
;;

;; nyi: doesn't work; get 1-second difference,
;; maybe because of clock skew between VOB and view ?
;;


(defun clearcase-file-appears-modified-since-checkout-p (file)
  "Return whether FILE appears to have been modified since checkout.
It doesn't examine the file contents."

  (cond
   ;; We consider various cases in order of increasing cost to compute.

   ;; Case 1: it's not even checked-out.
   ;;
   ((not (clearcase-fprop-checked-out file))
    nil)

   ;; Case 2: the mtime and the ctime are no longer the same.
   ;;
   ((not (equal (clearcase-utl-file-mtime file)
                (clearcase-utl-file-ctime file)))
    t)

   ;; Case 3: the size changed.
   ;;
   ((not (equal (clearcase-utl-file-size file)
                (clearcase-utl-file-size (clearcase-vxpath-cons-vxpath
                                          file (clearcase-fprop-predecessor-version file)))))
    t)

   ;; Case 4: the time of the checkout == the modification time of the file.
   ;;         (Unfortunately, non-equality doesn't necessarily mean the file
   ;;          was modified. It can sometimes be off by one second or so.)
   ;;
   ;; nyi: redundant case ?
   ;;
   ((string=
     (clearcase-fprop-date file)
     (clearcase-utl-emacs-date-to-clearcase-date
      (current-time-string (nth 5 (file-attributes file)))))
    nil)

   (t
    nil)))



;; nyi: store the date property in Emacs' format to minimise
;; format conversions ?
;;

;;}}}

;;{{{ Tests for view-residency

;;{{{ Tests for MVFS file residency

;; nyi: probably superseded by clearcase-file-would-be-in-view-p
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; nyi: this should get at least partially invalidated when
;;          VOBs are unmounted.

;; nyi: make this different for NT
;;
(defvar clearcase-always-mvfs-regexp (if (not clearcase-on-mswindows)
                                         "^/vobs/[^/]+/"

                                       ;; nyi: express this using drive variable
                                       ;;
                                       (concat "^"
                                               "[Mm]:"
                                               clearcase-pname-sep-regexp)))

;; This prevents the clearcase-file-vob-root function from pausing for long periods
;; stat-ing /net/host@@
;;
;; nyi: is there something equivalent on NT I need to avoid ?
;;

(defvar clearcase-never-mvfs-regexps (if clearcase-on-mswindows
                                         nil
                                       '(
                                         "^/net/[^/]+/"
                                         "^/tmp_mnt/net/[^/]+/"
                                         ))
  "Regexps matching those paths we can assume are never inside the MVFS.")

(defvar clearcase-known-vob-root-cache nil)

(defun clearcase-file-would-be-in-mvfs-p (filename)
  "Return whether FILE, after it is created, would reside in an MVFS filesystem."
  (let ((truename (file-truename filename)))
    (if (file-exists-p truename)
        (clearcase-file-is-in-mvfs-p truename)
      (let ((containing-dir (file-name-as-directory (file-name-directory truename))))
        (clearcase-file-is-in-mvfs-p containing-dir)))))

(defun clearcase-file-is-in-mvfs-p (filename)
  "Return whether existing FILE, resides in an MVFS filesystem."
  (let ((truename (file-truename filename)))

    (or
     ;; case 1: its prefix matches an "always VOB" prefix like /vobs/...
     ;;
     ;; nyi: problem here: we return true for "/vobs/nonexistent/"
     ;;
     (numberp (string-match clearcase-always-mvfs-regexp truename))

     ;; case 2: it has a prefix which is a known VOB-root
     ;;
     (clearcase-file-matches-vob-root truename clearcase-known-vob-root-cache)

     ;; case 3: it has an ancestor dir which is a newly met VOB-root
     ;;
     (clearcase-file-vob-root truename))))

(defun clearcase-wd-is-in-mvfs ()
  "Return whether the current directory resides in an MVFS filesystem."
  (clearcase-file-is-in-mvfs-p (file-truename ".")))

(defun clearcase-file-matches-vob-root (truename vob-root-list)
  "Return whether TRUENAME has a prefix in VOB-ROOT-LIST."
  (if (null vob-root-list)
      nil
    (or (numberp (string-match (regexp-quote (car vob-root-list))
                               truename))
        (clearcase-file-matches-vob-root truename (cdr vob-root-list)))))

(defun clearcase-file-vob-root (truename)
  "File the highest versioned directory in TRUENAME."

  ;; Use known non-MVFS patterns to rule some paths out.
  ;;
  (if (apply (function clearcase-utl-or-func)
             (mapcar (function (lambda (regexp)
                                 (string-match regexp truename)))
                     clearcase-never-mvfs-regexps))
      nil
    (let ((previous-dir nil)
          (dir  (file-name-as-directory (file-name-directory truename)))
          (highest-versioned-directory nil))

      (while (not (string-equal dir previous-dir))
        (if (clearcase-file-covers-element-p dir)
            (setq highest-versioned-directory dir))
        (setq previous-dir dir)
        (setq dir (file-name-directory (directory-file-name dir))))

      (if highest-versioned-directory
          (add-to-list 'clearcase-known-vob-root-cache highest-versioned-directory))

      highest-versioned-directory)))

;; Note: you should probably be using clearcase-fprop-mtype instead of this
;;       unless you really know what you're doing (nyi: check usages of this.)
;;
(defun clearcase-file-covers-element-p (path)
  "Determine quickly if PATH refers to a Clearcase element,
without caching the result."

  ;; nyi: Even faster: consult the fprop cache first ?

  (let ((element-dir (concat (clearcase-vxpath-element-part path) clearcase-vxpath-glue)))
    (and (file-exists-p path)
         (file-directory-p element-dir))))

;;}}}

;;{{{ Tests for snapshot view residency

;; nyi: probably superseded by clearcase-file-would-be-in-view-p
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar clearcase-known-snapshot-root-cache nil)

(defun clearcase-file-would-be-in-snapshot-p (filename)
  "Return whether FILE, after it is created, would reside in a snapshot view.
If so, return the viewtag."
  (let ((truename (file-truename filename)))
    (if (file-exists-p truename)
        (clearcase-file-is-in-snapshot-p truename)
      (let ((containing-dir (file-name-as-directory (file-name-directory truename))))
        (clearcase-file-is-in-snapshot-p containing-dir)))))

(defun clearcase-file-is-in-snapshot-p (truename)
  "Return whether existing FILE, resides in a snapshot view.
If so, return the viewtag."

  (or
   ;; case 1: it has a prefix which is a known snapshot-root
   ;;
   (clearcase-file-matches-snapshot-root truename clearcase-known-snapshot-root-cache)

   ;; case 2: it has an ancestor dir which is a newly met VOB-root
   ;;
   (clearcase-file-snapshot-root truename)))

(defun clearcase-wd-is-in-snapshot ()
  "Return whether the current directory resides in a snapshot view."
  (clearcase-file-is-in-snapshot-p (file-truename ".")))

(defun clearcase-file-matches-snapshot-root (truename snapshot-root-list)
  "Return whether TRUENAME has a prefix in SNAPSHOT-ROOT-LIST."
  (if (null snapshot-root-list)
      nil
    (or (numberp (string-match (regexp-quote (car snapshot-root-list))
                               truename))
        (clearcase-file-matches-snapshot-root truename (cdr snapshot-root-list)))))

;; This prevents the clearcase-file-snapshot-root function from pausing for long periods
;; stat-ing /net/host@@
;;
;; nyi: is there something equivalent on NT I need to avoid ?
;;

(defvar clearcase-never-snapshot-regexps (if clearcase-on-mswindows
                                             nil
                                           '(
                                             "^/net/[^/]+/"
                                             "^/tmp_mnt/net/[^/]+/"
                                             ))
  "Regexps matching those paths we can assume are never inside a snapshot view.")

(defun clearcase-file-snapshot-root (truename)
  "File the the snapshot view root containing TRUENAME."

  ;; Use known non-snapshot patterns to rule some paths out.
  ;;
  (if (apply (function clearcase-utl-or-func)
             (mapcar (function (lambda (regexp)
                                 (string-match regexp truename)))
                     clearcase-never-snapshot-regexps))
      nil
    (let ((previous-dir nil)
          (dir (file-name-as-directory (file-name-directory truename)))
          (viewtag nil)
          (viewroot nil))


      (while (and (not (string-equal dir previous-dir))
                  (null viewtag))

        ;; See if .view.dat exists and contains a valid view uuid
        ;;
        (let ((view-dat-name (concat dir (if clearcase-on-mswindows
					     "view.dat" ".view.dat"))))
          (if (file-readable-p view-dat-name)
              (let ((uuid (clearcase-viewdat-to-uuid view-dat-name)))
                (if uuid
                    (progn
                      (setq viewtag (clearcase-view-uuid-to-tag uuid))
                      (if viewtag
                          (setq viewroot dir)))))))

        (setq previous-dir dir)
        (setq dir (file-name-directory (directory-file-name dir))))

      (if viewroot
          (add-to-list 'clearcase-known-snapshot-root-cache viewroot))

      ;; nyi: update a viewtag==>viewroot map ?

      viewtag)))

(defun clearcase-viewdat-to-uuid (file)
  "Extract the view-uuid from a .view.dat file."
  ;; nyi
  )

(defun clearcase-view-uuid-to-tag (uuid)
  "Look up the view-uuid in the register to discover its tag."
  ;; nyi
  )

;;}}}

;; This is simple-minded but seems to work because cleartool+describe
;; groks snapshot views.
;;
;; nyi: Might be wise to cache view-roots to speed this up because the
;;      filename-handlers call this.
;;
;; nyi: Some possible shortcuts
;;      1. viewroot-relative path [syntax]
;;      2. under m:/ on NT        [syntax]
;;      3. setviewed on Unix      [find a containing VOB-root]
;;      4. subst-ed view on NT (calling net use seems very slow though)
;;                                [find a containing VOB-root]
;;      5. snapshot view
;;
(defun clearcase-file-would-be-in-view-p (filename)
  "Return whether FILE, after it is created, would reside in a ClearCase view."
  (let  ((truename (file-truename (expand-file-name filename))))

    ;; We use clearcase-path-file-really-exists-p here to make sure we are dealing
    ;; with a real file and not something faked by Emacs' file name handlers
    ;; like Ange-FTP.
    ;;
    (if (clearcase-path-file-really-exists-p truename)
        (clearcase-file-is-in-view-p truename)
      (let ((containing-dir (file-name-as-directory (file-name-directory truename))))
        (and (clearcase-path-file-really-exists-p containing-dir)
             (clearcase-file-is-in-view-p containing-dir))))))

(defun clearcase-file-is-in-view-p (filename)
  (let  ((truename (file-truename (expand-file-name filename))))
    ;; Shortcut if the file is a version-extended path.
    ;;
    (or (clearcase-vxpath-p truename)
        (clearcase-fprop-mtype truename))))

(defun clearcase-file-viewtag (filename)
  "Find the viewtag associated with existing FILENAME."

  (clearcase-when-debugging
   (assert (file-exists-p filename)))

  (let ((truename (file-truename (expand-file-name filename))))
    (cond

     ;; Case 1: viewroot-relative path
     ;;         ==> syntax
     ;;
     ((clearcase-vrpath-p truename)
      (clearcase-vrpath-viewtag truename))

     ;; Case 2: under m:/ on NT
     ;;         ==> syntax
     ;;
     ((and clearcase-on-mswindows
           (string-match (concat clearcase-viewroot-drive
                                 clearcase-pname-sep-regexp
                                 "\\("
                                 clearcase-non-pname-sep-regexp "*"
                                 "\\)"
                                 )
                         truename))
      (substring truename (match-beginning 1) (match-end 1)))

     ;; Case 3: setviewed on Unix
     ;;         ==> read EV, but need to check it's beneath a VOB-root
     ;;
     ((and clearcase-setview-viewtag
           (clearcase-file-would-be-in-mvfs-p truename))
      clearcase-setview-viewtag)

     ;; Case 4: subst-ed view on NT
     ;;         ==> use ct+pwv -wdview
     ;; Case 5: snapshot view
     ;;         ==> use ct+pwv -wdview
     (t
      (clearcase-file-wdview truename)))))

(defun clearcase-file-wdview (truename)
  "Return the working-directory view associated with TRUENAME,
or nil if none"
  (let ((default-directory (if (file-directory-p truename)
                               truename
                             (file-name-directory truename))))
    (clearcase-ct-cd default-directory)
    (let ((ret (clearcase-ct-blocking-call "pwv" "-wdview" "-short")))
      (if (string-match "cleartool: Error:" ret)
          (error (substring ret (match-end 0))))
      (if (not (string-match " NONE " ret))
          (clearcase-utl-1st-line-of-string ret)))))

;;}}}

;;{{{ The cleartool sub-process

;; We use pipes rather than pty's for two reasons:
;;
;;   1. NT only has pipes
;;   2. On Solaris there appeared to be a problem in the pty handling part
;;      of Emacs, which resulted in Emacs/tq seeing too many cleartool prompt
;;      strings. This would occasionally occur and prevent the tq-managed
;;      interactions with the cleartool sub-process from working correctly.
;;
;; Now we use pipes. Cleartool detects the "non-tty" nature of the output
;; device and doesn't send a prompt. We manufacture an end-of-transaction
;; marker by sending a "pwd -h" after each cleartool sub-command and then use
;; the expected output of "Usage: pwd\n" as our end-of-txn pattern for tq.
;;
;; Even using pipes, the semi-permanent outboard-process using tq doesn't work
;; well on NT. There appear to be bugs in accept-process-output such that:
;;   0. there apparently were hairy race conditions, which a sprinkling
;;      of (accept-process-output nil 1) seemed to avoid somewhat.
;;   1. it never seems to timeout if you name a process as arg1.
;;   2. it always seems to wait for TIMEOUT, even if there is output ready.
;; The result seemed to be less responsive tha just calling a fresh cleartool
;; process for each invokation of clearcase-ct-blocking-call
;;
;; It still seems worthwhile to make it work on NT, as clearcase-ct-blocking-call
;; typically takes about 0.5 secs on NT versus 0.05 sec on Solaris,
;; an order of magnitude difference.
;;

(defconst clearcase-ct-eotxn-cmd "pwd -h\n")
(defconst clearcase-ct-eotxn-response "Usage: pwd\n")
(defconst clearcase-ct-eotxn-response-length (length clearcase-ct-eotxn-response))

(defconst clearcase-ct-subproc-timeout 30
  "Timeout on calls to subprocess")

(defvar clearcase-ct-tq nil
  "Transaction queue to talk to ClearTool in a subprocess")

(defvar clearcase-ct-return nil
  "Return value when we're involved in a blocking call")

(defvar clearcase-ct-view ""
  "Current view of cleartool subprocess, or the empty string if none")

(defvar clearcase-ct-wdir ""
  "Current working directory of cleartool subprocess,
or the empty string if none")

(defvar clearcase-ct-running nil)

(defun clearcase-ct-accept-process-output (proc timeout)
  (accept-process-output proc timeout))

(defun clearcase-ct-start-cleartool ()
  (clearcase-trace "clearcase-ct-start-cleartool()")
  (let ((process-environment (append '("ATRIA_NO_BOLD=1"
                                       "ATRIA_FORCE_GUI=1")
                                     ;;; emacs is a GUI, right? :-)
                                     process-environment)))
    (clearcase-trace (format "Starting cleartool in %s" default-directory))
    (let* (;; Force the use of a pipe
           ;;
           (process-connection-type nil)
           (cleartool-process (start-process "cleartool"
                                             "*cleartool*"
                                             clearcase-cleartool-path)))
      (process-kill-without-query cleartool-process)
      (setq clearcase-ct-view "")
      (setq clearcase-ct-tq (tq-create cleartool-process))
      (tq-enqueue clearcase-ct-tq
                  clearcase-ct-eotxn-cmd;; question
                  clearcase-ct-eotxn-response;; regexp
                  'clearcase-ct-running;; closure
                  'set);; function
      (while (not clearcase-ct-running)
        (message "waiting for cleartool to start...")
        (clearcase-ct-accept-process-output (tq-process clearcase-ct-tq)
                                            clearcase-ct-subproc-timeout))
      (clearcase-trace "clearcase-ct-start-cleartool() done")
      (message "waiting for cleartool to start...done"))))

(defun clearcase-ct-kill-cleartool ()
  "Kill off cleartool subprocess.  If another one is needed,
it will be restarted.  This may be useful if you're debugging clearcase."
  (interactive)
  (clearcase-ct-kill-tq))

(defun clearcase-ct-callback (arg val)
  (clearcase-trace (format "clearcase-ct-callback:<\n"))
  (clearcase-trace val)
  (clearcase-trace (format "clearcase-ct-callback:>\n"))
  ;; This can only get called when the last thing received from
  ;; the cleartool sub-process was clearcase-ct-eotxn-response,
  ;; so it is safe to just remove it here.
  ;;
  (setq clearcase-ct-return (substring val 0 (- clearcase-ct-eotxn-response-length))))

(defun clearcase-ct-do-cleartool-command (command file comment &rest flags)
  "Execute a cleartool command, notifying user and checking for
errors. Output from COMMAND goes to buffer *clearcase*.  The last argument of the
command is the name of FILE; this is appended to an optional list of
FLAGS."
  (if file
      (setq file (expand-file-name file)))
  (if (listp command)
      ;;      (progn
      ;;      (setq flags (append (cdr command) flags))
      ;;      (setq command (car command)))
      (error "command must not be a list"))
  (if clearcase-command-messages
      (if file
          (message "Running %s on %s..." command file)
        (message "Running %s..." command)))
  (let ((camefrom (current-buffer))
        (squeezed nil)
        status)
    (set-buffer (get-buffer-create "*clearcase*"))
    (set (make-local-variable 'clearcase-parent-buffer) camefrom)
    (set (make-local-variable 'clearcase-parent-buffer-name)
         (concat " from " (buffer-name camefrom)))
    (erase-buffer)
    ;; This is so that command arguments typed in the *clearcase* buffer will
    ;; have reasonable defaults.
    ;;
    (if file
        (setq default-directory (file-name-directory file)))

    (mapcar
     (function (lambda (s)
                 (and s
                      (setq squeezed
                            (append squeezed (list s))))))
     flags)
    (let ((tmpfile (clearcase-utl-temp-filename)))
      (unwind-protect
          (progn
            (if (not (eq comment 'unused))
                (if comment
                    (progn
                      (write-region comment nil tmpfile nil 'noprint)
                      (setq squeezed (append squeezed (list "-cfile" (clearcase-path-native tmpfile)))))
                  (setq squeezed (append squeezed (list "-nc")))))
            (if file
                (setq squeezed (append squeezed (list (clearcase-path-native file)))))
            (let ((default-directory (file-name-directory
                                      (or file default-directory))))
              (clearcase-ct-cd default-directory)
              (if clearcase-command-messages
                  (message "Running %s..." command))
              (insert
               (apply 'clearcase-ct-cleartool-cmd (append (list command) squeezed)))
              (if clearcase-command-messages
                  (message "Running %s...done" command))))
        (if (file-exists-p tmpfile)
            (delete-file tmpfile))))
    (goto-char (point-min))
    (clearcase-view-mode 0 camefrom)
    (set-buffer-modified-p nil)         ; XEmacs - fsf uses `not-modified'
    (if (re-search-forward "^cleartool: Error:.*$" nil t)
        (progn
          (setq status (buffer-substring (match-beginning 0) (match-end 0)))
          (clearcase-port-view-buffer-other-window "*clearcase*")
          (shrink-window-if-larger-than-buffer)
          (error "Running %s...FAILED (%s)" command status))
      (if clearcase-command-messages
          (message "Running %s...OK" command)))
    (set-buffer camefrom)
    status))

(defun clearcase-ct-cd (dir)
  (if (or (not dir)
          (string= dir clearcase-ct-wdir))
      clearcase-ct-wdir
    (let ((ret (clearcase-ct-blocking-call "cd" (clearcase-path-native dir))))
      (if (string-match "cleartool: Error:" ret)
          (error (substring ret (match-end 0)))
        (setq clearcase-ct-wdir dir)))))

(defun clearcase-ct-cleartool-cmd (&rest cmd)
  (apply 'clearcase-ct-blocking-call cmd))

;; NT Emacs - needs a replacement for tq.
;;
(defun clearcase-ct-get-command-stdout (program &rest args)
  "Call PROGRAM.
Returns PROGRAM's stdout.
ARGS is the command line arguments to PROGRAM."
  (let ((buf (generate-new-buffer "cleartoolexecution")))
    (prog1
        (save-excursion
          (set-buffer buf)
	  (apply 'call-process program nil buf nil args)
          (buffer-string))
      (kill-buffer buf))))

;; The TQ interaction still doesn't work on NT.
;;
(defvar clearcase-disable-tq clearcase-on-mswindows
  "Set to T if the Emacs/cleartool interactions via tq are not working right.")

(defun clearcase-ct-blocking-call (&rest cmd)
  (clearcase-trace (format "clearcase-ct-blocking-call(%s)" cmd))
  (save-excursion
    (setq clearcase-ct-return nil)

    (if clearcase-disable-tq
        ;; Don't use tq:
        ;;
        (setq clearcase-ct-return (apply 'clearcase-ct-get-command-stdout
                                         clearcase-cleartool-path cmd))
      
      ;; Use tq:
      ;;
      (setq clearcase-ct-return nil)
      (if (not clearcase-ct-tq)
          (clearcase-ct-start-cleartool))
      (unwind-protect
          (let ((command ""))
	    (mapcar
	     (function
              (lambda (token)
                ;; If the token has imbedded spaces and is not already quoted,
                ;; add double quotes.
                ;;
                (setq command (concat command
                                      " "
                                      (clearcase-utl-quote-if-nec token)))))
	     cmd)
            (tq-enqueue clearcase-ct-tq
                        (concat command "\n"
                                clearcase-ct-eotxn-cmd);; question
                        clearcase-ct-eotxn-response;; regexp
                        nil;; closure
                        'clearcase-ct-callback);; function
            (while (not clearcase-ct-return)
              (clearcase-ct-accept-process-output (tq-process clearcase-ct-tq)
                                                  clearcase-ct-subproc-timeout)))
        ;; Error signalled:
        ;;
        (while (tq-queue clearcase-ct-tq)
          (tq-queue-pop clearcase-ct-tq)))))
  clearcase-ct-return)

(defun clearcase-ct-kill-tq ()
  (process-send-eof (tq-process clearcase-ct-tq))
  (kill-process (tq-process clearcase-ct-tq))
  (setq clearcase-ct-running nil)
  (setq clearcase-ct-tq nil))

(defun clearcase-ct-kill-buffer-hook ()

  ;; NT Emacs - doesn't use tq.
  ;;
  (if (not clearcase-on-mswindows)
      (let ((kill-buffer-hook nil))
        (if (and (boundp 'clearcase-ct-tq)
                 clearcase-ct-tq
                 (eq (current-buffer) (tq-buffer clearcase-ct-tq)))
            (error "Don't kill TQ buffer %s, use `clearcase-ct-kill-tq'" (current-buffer))))))

(add-hook 'kill-buffer-hook 'clearcase-ct-kill-buffer-hook)

;;}}}

;;{{{ Invoking a command

;; nyi Probably redundant.

(defun clearcase-do-command (okstatus command file &rest flags)
  "Execute a version-control command, notifying user and checking for errors.
The command is successful if its exit status does not exceed OKSTATUS.
Output from COMMAND goes to buffer *clearcase*.  The last argument of the command is
an optional list of FLAGS."
  (setq file (expand-file-name file))
  (if clearcase-command-messages
      (message "Running %s on %s..." command file))
  (let ((camefrom (current-buffer))
        (pwd )
        (squeezed nil)
        status)
    (set-buffer (get-buffer-create "*clearcase*"))
    (set (make-local-variable 'clearcase-parent-buffer) camefrom)
    (set (make-local-variable 'clearcase-parent-buffer-name)
         (concat " from " (buffer-name camefrom)))
    (erase-buffer)
    ;; This is so that command arguments typed in the *clearcase* buffer will
    ;; have reasonable defaults.
    ;;
    (setq default-directory (file-name-directory file)
          file (file-name-nondirectory file))

    (mapcar
     (function (lambda (s)
                 (and s
                      (setq squeezed
                            (append squeezed (list s))))))
     flags)
    (setq squeezed (append squeezed (list file)))
    (setq status (apply 'call-process command nil t nil squeezed))
    (goto-char (point-min))
    (clearcase-view-mode 0 camefrom)
    (set-buffer-modified-p nil)         ; XEmacs - fsf uses `not-modified'
    (if (or (not (integerp status)) (< okstatus status))
        (progn
          (clearcase-port-view-buffer-other-window "*clearcase*")
          (shrink-window-if-larger-than-buffer)
          (error "Running %s...FAILED (%s)" command
                 (if (integerp status)
                     (format "status %d" status)
                   status)))
      (if clearcase-command-messages
          (message "Running %s...OK" command)))
    (set-buffer camefrom)
    status))

;;}}}

;;{{{ Viewtag management

;;{{{ Started views

(defun clearcase-viewtag-try-to-start-view (viewtag)
  "If VIEW is not apparently already visible under viewroot, start it."
  (if (not (member viewtag (clearcase-viewtag-started-viewtags)))
      (clearcase-viewtag-start-view viewtag)))

(defun clearcase-viewtag-started-viewtags-alist ()
  "Return an alist of views that are currently visible under the viewroot."
  (mapcar
   (function
    (lambda (tag)
      (list (concat tag "/"))))
   (clearcase-viewtag-started-viewtags)))

(defun clearcase-viewtag-started-viewtags ()
  "Return the list of viewtags already visible under the viewroot."
  (let ((raw-list  (if clearcase-on-mswindows
                       (directory-files clearcase-viewroot-drive)
                     (directory-files clearcase-viewroot))))
    (clearcase-utl-list-filter
     (function (lambda (string)
                 ;; Exclude the ones that start with ".",
                 ;; and the ones that end with "@@".
                 ;;
                 (and (not (equal ?. (aref string 0)))
                      (not (string-match "@@$" string)))))
     raw-list)))

;; nyi: Makes sense on NT ?
;;      Probably also want to run subst ?
;;      Need a better high-level interface to start-view
;;
(defun clearcase-viewtag-start-view (viewtag)
  "If VIEWTAG is in our cache of valid view names, start it."
  (if (clearcase-viewtag-exists viewtag)
      (progn
        (message "Starting view server for %s..." viewtag)
        (let ((ret (clearcase-ct-blocking-call "startview" viewtag)))
          (if (string-match "cleartool: Error:" ret)
              (error (substring ret (match-end 0)))
            (message "Starting view server for %s...done" viewtag))))))

;;}}}

;;{{{ All views

;; Exported interfaces

(defun clearcase-viewtag-all-viewtags-obarray ()
  "Return an obarray of all valid viewtags as of the last time we looked."
  (if (null clearcase-viewtag-cache)
      (progn
        (setq clearcase-viewtag-cache (clearcase-viewtag-read-all-viewtags))
        (clearcase-viewtag-schedule-cache-invalidation)))
  clearcase-viewtag-cache)

(defun clearcase-viewtag-exists (viewtag)
  (symbol-value (intern-soft viewtag (clearcase-viewtag-all-viewtags-obarray))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Internals

(defvar clearcase-viewtag-cache nil
  "Oblist of all known viewtags.")

(defvar clearcase-viewtag-cache-timeout 1800
  "*Default timeout of all-viewtag cache, in seconds.")

(defun clearcase-viewtag-schedule-cache-invalidation ()
  "Schedule the next invalidation of clearcase-viewtag-cache."
  (run-at-time (format "%s sec" clearcase-viewtag-cache-timeout)
               nil
               (function (lambda (&rest ignore)
                           (setq clearcase-viewtag-cache nil)))
               nil))
;; Some primes:
;;
;;     1,
;;     2,
;;     3,
;;     7,
;;     17,
;;     31,
;;     61,
;;     127,
;;     257,
;;     509,
;;     1021,
;;     2053,

(defun clearcase-viewtag-read-all-viewtags ()
  "Invoke ct+lsview to get all viewtags, and return an obarry containing them."
  (message "Fetching view names...")
  (let* ((default-directory "/")
         (result (make-vector 1021 0))
         (raw-views-string (clearcase-ct-blocking-call "lsview" "-short"))
         (view-list (clearcase-utl-split-string-at-char raw-views-string ?\n)))
    (message "Fetching view names...done")
    (mapcar (function (lambda (string)
                        (set (intern string result) t)))
            view-list)
    result))

;;}}}

;;}}}

;;{{{ Pathnames

;;{{{ Pathnames: version-extended

(defun clearcase-vxpath-p (path)
  (or (string-match (concat clearcase-vxpath-glue "/") path)
      (string-match (concat clearcase-vxpath-glue "\\\\") path)))

(defun clearcase-vxpath-element-part (vxpath)
  "Return the element part of version-extended PATH."
  (if (string-match clearcase-vxpath-glue vxpath)
      (substring vxpath 0 (match-beginning 0))
    vxpath))

(defun clearcase-vxpath-version-part (vxpath)
  "Return the version part of version-extended PATH."
  (if (string-match clearcase-vxpath-glue vxpath)
      (substring vxpath (match-end 0))
    nil))

(defun clearcase-vxpath-cons-vxpath (file version &optional viewtag)
  "Make a ClearCase version-extended pathname for ELEMENT's version VERSION.
If ELEMENT is actually a version-extended pathname, substitute VERSION for
the version included in ELEMENT.  If VERSION is nil, remove the version-extended
pathname.

If optional VIEWTAG is specified, make a view-relative pathname, possibly
replacing the existing view prefix."
  (let* ((element (clearcase-vxpath-element-part file))
         (glue-fmt (if (and (> (length version) 0)
                            (= (aref version 0) ?/))
                       (concat "%s" clearcase-vxpath-glue "%s")
                     (concat "%s" clearcase-vxpath-glue "/%s")))
         (relpath (clearcase-vrpath-tail element)))
    (if viewtag
        (setq element (concat clearcase-viewroot "/" viewtag (or relpath element))))
    (if version
        (format glue-fmt element version)
      element)))

;; NYI: This should cache the predecessor version as a property
;; of the file.
;;
(defun clearcase-vxpath-of-predecessor (file)
  "Compute the version-extended pathname of the predecessor version of FILE."
  (if (not (equal 'version (clearcase-fprop-mtype file)))
      (error "Not a clearcase version: %s" file))
  (let ((abs-file (expand-file-name file)))
    (let ((ver (clearcase-utl-1st-line-of-string
                (clearcase-ct-cleartool-cmd "describe"
                                            "-pred"
                                            "-short"
                                            (clearcase-path-native abs-file)))))
      (clearcase-path-canonicalise-slashes (concat
                                            (clearcase-vxpath-element-part file)
                                            clearcase-vxpath-glue
                                            ver)))))

(defun clearcase-vxpath-version-extend (file)
  "Compute the version-extended pathname of FILE."
  (if (not (equal 'version (clearcase-fprop-mtype file)))
      (error "Not a clearcase version: %s" file))
  (let ((abs-file (expand-file-name file)))
    (clearcase-path-canonicalise-slashes
     (clearcase-utl-1st-line-of-string
      (clearcase-ct-cleartool-cmd "describe"
                                  "-fmt"
                                  (if (and clearcase-on-mswindows
                                           clearcase-xemacs-p)
                                      (concat "\"%En"
                                              clearcase-vxpath-glue
                                              "%Vn\"")
                                    (concat "%En"
                                            clearcase-vxpath-glue
                                            "%Vn"))
                                  (clearcase-path-native abs-file))))))

(defun clearcase-vxpath-of-branch-base (file)
  "Compute the version-extended pathname of the version at the branch base of FILE."
  (let* ((file-version-path (clearcase-vxpath-version-extend file))
         (file-version-number (file-name-nondirectory file-version-path))
         (branch (file-name-directory file-version-path)))
    (let* ((base-number 0)
           (base-version-path (format "%s%d" branch base-number)))
      (while (and (not (file-exists-p base-version-path))
                  (< base-number file-version-number))
        (setq base-number (1+ base-number))
        (setq base-version-path (format "%s%d") branch base-number))
      base-version-path)))

(defun clearcase-vxpath-version-of-branch-base (file)
  (clearcase-vxpath-version-part (clearcase-vxpath-of-branch-base file)))

(defun clearcase-vxpath-get-version-in-buffer (vxpath)
  "Return a buffer containing the version named by VXPATH.
Intended for use in snapshot views."
  (let* ((temp-file (clearcase-vxpath-get-version-in-temp-file vxpath))
         (buffer (find-file-noselect temp-file t)))
    (delete-file temp-file)
    buffer))

(defun clearcase-vxpath-get-version-in-temp-file (vxpath)
  "Return the name of a temporary file containing the version named by VXPATH.
Intended for use in snapshot views."

  ;; nyi: how to get these temp-files cleaned-up ?
  ;;
  (let ((temp-file (clearcase-utl-temp-filename vxpath)))
    (clearcase-ct-blocking-call "get"
                                "-to"
                                (clearcase-path-native temp-file)
                                (clearcase-path-native vxpath))
    temp-file))

;;}}}

;;{{{ Pathnames: viewroot-relative

;; nyi: make all this work with viewroot-drive-relative files too

(defun clearcase-vrpath-p (path)
  "Return whether PATH is viewroot-relative."
  (string-match clearcase-vrpath-regexp path))

(defun clearcase-vrpath-head (vrpath)
  "Given viewroot-relative PATH, return the prefix including the view-tag."
  (if (string-match clearcase-vrpath-regexp vrpath)
      (substring vrpath (match-end 0))))

(defun clearcase-vrpath-tail (vrpath)
  "Given viewroot-relative PATH, return the suffix after the view-tag."
  (if (string-match clearcase-vrpath-regexp vrpath)
      (substring vrpath (match-end 0))))

(defun clearcase-vrpath-viewtag (vrpath)
  "Given viewroot-relative PATH, return the view-tag."
  (if (string-match clearcase-vrpath-regexp vrpath)
      (substring vrpath (match-beginning 1) (match-end 1))))

;; Remove useless viewtags from a pathname.
;; e.g. if we're setviewed to view "VIEWTAG"
;;    (clearcase-path-remove-useless-viewtags "/view/VIEWTAG/PATH")
;;     ==> "PATH"
;;    (clearcase-path-remove-useless-viewtags "/view/z/view/y/PATH")
;;     ==> /view/y/"PATH"
;;
(defvar clearcase-multiple-viewroot-regexp
  (concat "^"
          clearcase-viewroot
          clearcase-pname-sep-regexp
          clearcase-non-pname-sep-regexp "+"
          "\\("
          clearcase-viewroot
          clearcase-pname-sep-regexp
          "\\)"
          ))

(defun clearcase-path-remove-useless-viewtags (pathname)
  ;; Try to avoid file-name-handler recursion here:
  ;;
  (let ((setview-root clearcase-setview-root))
    (if setview-root
        ;; Append "/":
        ;;
        (setq setview-root (concat setview-root "/")))

    (cond

     ((string-match clearcase-multiple-viewroot-regexp pathname)
      (clearcase-path-remove-useless-viewtags (substring pathname (match-beginning 1))))

     ((and setview-root
           (string= setview-root "/"))
      pathname)

     ;; If pathname has setview-root as a proper prefix,
     ;; strip it off and recurse:
     ;;
     ((and setview-root
           (< (length setview-root) (length pathname))
           (string= setview-root (substring pathname 0 (length setview-root))))
      (clearcase-path-remove-useless-viewtags (substring pathname (- (length setview-root) 1))))

     (t
      pathname))))

;;}}}

(defun clearcase-path-canonicalise-slashes (path)
  (if (not clearcase-on-mswindows)
      path
    (subst-char-in-string ?\\ ?/ path nil)))

(defun clearcase-path-canonical (path)
  (if (not clearcase-on-mswindows)
      path
    (if clearcase-on-cygwin32
	(substring (shell-command-to-string (concat "cygpath -u -p '" path "'")) 0 -1)
      (subst-char-in-string ?\\ ?/ path nil))))

(defun clearcase-path-native (path)
  (if (not clearcase-on-mswindows)
      path
    (if clearcase-on-cygwin32
	(substring (shell-command-to-string (concat "cygpath -w -p " path)) 0 -1)
      (subst-char-in-string ?/ ?\\ path nil))))

(defun clearcase-path-file-really-exists-p (filename)
  "Test if a file really exists, when all file-name handlers are disabled."
  (let ((inhibit-file-name-operation 'file-exists-p)
        (inhibit-file-name-handlers (mapcar
                                     (lambda (pair)
                                       (cdr pair))
                                     file-name-handler-alist)))
    (file-exists-p filename)))

;;}}}

;;{{{ Mode-line

(defun clearcase-mode-line-buffer-id (filename)
  "Compute an abbreviated version string for the mode-line.
It will be in one of three forms: /main/NNN, or .../branchname/NNN, or DO-NAME"

  (if (clearcase-fprop-checked-out filename)
      (if (clearcase-fprop-reserved filename)
          "RESERVED"
        "UNRESERVED")
    (let ((ver-string (clearcase-fprop-version filename)))
      (if (not (zerop (length ver-string)))
          (let ((i (length ver-string))
                (slash-count 0))
            ;; Search back from the end to the second-last slash
            ;;
            (while (and (> i 0)
                        (< slash-count  2))
              (if (equal ?/ (aref ver-string (1- i)))
                  (setq slash-count (1+ slash-count)))
              (setq i (1- i)))
            (if (> i 0)
                (concat "..." (substring ver-string i))
              (substring ver-string i)))))))

;;}}}

;;{{{ Minibuffer reading

;;{{{ clearcase-read-version-name

(defun clearcase-read-version-name (prompt file)
  "Display PROMPT and read a version string for FILE in the minibuffer,
with completion if possible."
  (let* ((insert-default-directory nil)
         (predecessor (clearcase-fprop-predecessor-version file))
         (default-filename (clearcase-vxpath-cons-vxpath file predecessor))

         ;; To get this too work it is necessary to make Emacs think
         ;; we're completing with respect to "ELEMENT@@/" rather
         ;; than "ELEMENT@@". Otherwise when we enter a version
         ;; like "/main/NN", it thinks we entered an absolute path.
         ;; So instead, we prompt the user to enter "main/..../NN"
         ;; and add back the leading slash before returning.
         ;;
         (completing-dir (concat file "@@/")))
    (if (clearcase-file-is-in-mvfs-p file)
        ;; Completion only works in MVFS:
        ;;
        (concat "/" (read-file-name prompt
                                    completing-dir
                                    (substring predecessor 1)
                                    ;;nil
                                    t
                                    (substring predecessor 1)))
      (concat "/" (read-string prompt
                               (substring predecessor 1)
                               nil
                               (substring predecessor 1))))))


;;}}}

;;{{{ clearcase-read-label-name

;; nyi: unused

(defun clearcase-read-label-name (prompt)
  "Read a label name."

  (let* ((string (clearcase-ct-cleartool-cmd "lstype"
                                             "-kind"
                                             "lbtype"
                                             "-short"))
         labels)
    (mapcar (function (lambda (arg)
                        (if (string-match "(locked)" arg)
                            nil
                          (setq labels (cons (list arg) labels)))))
            (clearcase-utl-split-string string "\n"))
    (completing-read prompt labels nil t)))

;;}}}

;;}}}

;;{{{ Directory-tree walking

(defun clearcase-dir-all-files (func &rest args)
  "Invoke FUNC f ARGS on each regular file f in default directory."
  (let ((dir default-directory))
    (message "Scanning directory %s..." dir)
    (mapcar (function (lambda (f)
                        (let ((dirf (expand-file-name f dir)))
                          (apply func dirf args))))
            (directory-files dir))
    (message "Scanning directory %s...done" dir)))

(defun clearcase-file-tree-walk-internal (file func args quiet)
  (if (not (file-directory-p file))
      (apply func file args)
    (or quiet
        (message "Traversing directory %s..." file))
    (let ((dir (file-name-as-directory file)))
      (mapcar
       (function
        (lambda (f) (or
                     (string-equal f ".")
                     (string-equal f "..")
                     (member f clearcase-directory-exclusion-list)
                     (let ((dirf (concat dir f)))
                       (or
                        (file-symlink-p dirf);; Avoid possible loops
                        (clearcase-file-tree-walk-internal dirf func args quiet))))))
       (directory-files dir)))))
;;
(defun clearcase-file-tree-walk (func &rest args)
  "Walk recursively through default directory.
Invoke FUNC f ARGS on each non-directory file f underneath it."
  (clearcase-file-tree-walk-internal default-directory func args nil)
  (message "Traversing directory %s...done" default-directory))

(defun clearcase-subdir-tree-walk (func &rest args)
  "Walk recursively through default directory.
Invoke FUNC f ARGS on each subdirectory underneath it."
  (clearcase-subdir-tree-walk-internal default-directory func args nil)
  (message "Traversing directory %s...done" default-directory))

(defun clearcase-subdir-tree-walk-internal (file func args quiet)
  (if (file-directory-p file)
      (let ((dir (file-name-as-directory file)))
        (apply func dir args)
        (or quiet
            (message "Traversing directory %s..." file))
        (mapcar
         (function
          (lambda (f) (or
                       (string-equal f ".")
                       (string-equal f "..")
                       (member f clearcase-directory-exclusion-list)
                       (let ((dirf (concat dir f)))
                         (or
                          (file-symlink-p dirf);; Avoid possible loops
                          (clearcase-subdir-tree-walk-internal dirf
                                                               func
                                                               args
                                                               quiet))))))
         (directory-files dir)))))

;;}}}

;;{{{ Buffer context

;; nyi: it would be nice if we could restore fold context too, for folded files.

;; Save a bit of the text around POSN in the current buffer, to help
;; us find the corresponding position again later.  This works even
;; if all markers are destroyed or corrupted.
;;
(defun clearcase-position-context (posn)
  (list posn
        (buffer-size)
        (buffer-substring posn
                          (min (point-max) (+ posn 100)))))

;; Return the position of CONTEXT in the current buffer, or nil if we
;; couldn't find it.
;;
(defun clearcase-find-position-by-context (context)
  (let ((context-string (nth 2 context)))
    (if (equal "" context-string)
        (point-max)
      (save-excursion
        (let ((diff (- (nth 1 context) (buffer-size))))
          (if (< diff 0) (setq diff (- diff)))
          (goto-char (nth 0 context))
          (if (or (search-forward context-string nil t)
                  ;; Can't use search-backward since the match may continue
                  ;; after point.
                  ;;
                  (progn (goto-char (- (point) diff (length context-string)))
                         ;; goto-char doesn't signal an error at
                         ;; beginning of buffer like backward-char would.
                         ;;
                         (search-forward context-string nil t)))
              ;; to beginning of OSTRING
              ;;
              (- (point) (length context-string))))))))

;;}}}

;;{{{ Synchronizing buffers with disk

(defun clearcase-sync-from-disk (file &optional no-confirm)

  (clearcase-fprop-unstore-properties file)
  ;; If the given file is in any buffer, revert it.
  ;;
  (let ((buffer (find-buffer-visiting file)))
    (if buffer
        (save-excursion
          (set-buffer buffer)
          (clearcase-buffer-revert no-confirm)
          (clearcase-fprop-get-properties file)

          ;; Make sure the mode-line gets updated.
          ;;
          (setq clearcase-mode
                (concat " ClearCase:"
                        (clearcase-mode-line-buffer-id file)))
          (force-mode-line-update))))

  ;; Update any Dired Mode buffers that list this file.
  ;;
  (dired-relist-file file)

  ;; If the file was a directory, update any dired-buffer for
  ;; that directory.
  ;;
  (mapcar (function (lambda (buffer)
                      (save-excursion
                        (set-buffer buffer)
                        (revert-buffer))))
          (dired-buffers-for-dir file)))

(defun clearcase-sync-to-disk (&optional not-urgent)

  ;; Make sure the current buffer and its working file are in sync
  ;; NOT-URGENT means it is ok to continue if the user says not to save.
  ;;
  (if (buffer-modified-p)
      (if (or clearcase-suppress-confirm
              (y-or-n-p (format "Buffer %s modified; save it? "
                                (buffer-name))))
          (save-buffer)
        (if not-urgent
            nil
          (error "Aborted")))))


(defun clearcase-buffer-revert (&optional no-confirm)
  ;; Should never call for Dired buffers
  ;;
  (assert (not (eq major-mode 'dired-mode)))
  
  ;; Revert buffer, try to keep point and mark where user expects them in spite
  ;; of changes because of expanded version-control key words.  This is quite
  ;; important since otherwise typeahead won't work as expected.
  ;;
  (widen)
  (let ((point-context (clearcase-position-context (point)))

        ;; Use clearcase-utl-mark-marker to avoid confusion in transient-mark-mode.
        ;; XEmacs - mark-marker t, FSF Emacs - mark-marker.
        ;;
        (mark-context (if (eq (marker-buffer (clearcase-utl-mark-marker))
                              (current-buffer))
                          (clearcase-position-context (clearcase-utl-mark-marker))))
        (camefrom (current-buffer)))

    ;; nyi: Should we run font-lock ?
    ;; Want to avoid re-doing a buffer that is already correct, such as on
    ;; check-in/check-out.
    ;; For now do-nothing.

    ;; The actual revisit.
    ;; For some reason, revert-buffer doesn't recompute whether View Minor Mode
    ;; should be on, so turn it off and then turn it on if necessary.
    ;;
    ;; nyi: Perhaps we should re-find-file ?
    ;;
    (or clearcase-xemacs-p
        (if (fboundp 'view-mode)
            (view-mode 0)))
    (revert-buffer t no-confirm t)
    (or clearcase-xemacs-p
        (if (and (boundp 'view-read-only)
                 view-read-only
                 buffer-read-only)
            (view-mode 1)))

    ;; Restore point and mark.
    ;;
    (let ((new-point (clearcase-find-position-by-context point-context)))
      (if new-point (goto-char new-point)))
    (if mark-context
        (let ((new-mark (clearcase-find-position-by-context mark-context)))
          (if new-mark (set-mark new-mark))))))

;;}}}

;;{{{ Utilities

;; NT Emacs - use environment variable TEMP if it exists.
;;
(defun clearcase-utl-temp-filename (&optional vxpath)
  (let ((ext ""))
    (and vxpath
         (save-match-data
           (if (string-match "\\(\\.[^.]+\\)@@" vxpath)
               (setq ext (match-string 1 vxpath)))))
    (concat (make-temp-name (clearcase-path-canonical
                             (concat (or (getenv "TEMP") "/tmp")
                                     "/clearcase-")))
            ext)))

(defun clearcase-utl-emacs-date-to-clearcase-date (s)
  (concat
   (substring s 20);; yyyy
   (int-to-string (clearcase-utl-month-unparse (substring s 4 7)));; mm
   (substring s 8 10);; dd
   "."
   (substring s 11 13);; hh
   (substring s 14 16);; mm
   (substring s 17 19)));; ss

(defun clearcase-utl-month-unparse (s)
  (cond
   ((string= s "Jan") 1)
   ((string= s "Feb") 2)
   ((string= s "Mar") 3)
   ((string= s "Apr") 4)
   ((string= s "May") 5)
   ((string= s "Jun") 6)
   ((string= s "Jul") 7)
   ((string= s "Aug") 8)
   ((string= s "Sep") 9)
   ((string= s "Oct") 10)
   ((string= s "Nov") 11)
   ((string= s "Dec") 12)))

(defun clearcase-utl-strip-trailing-slashes (name)
  (let* ((len (length name)))
    (while (and (> len 1)
                (or (equal ?/ (aref name (1- len)))
                    (equal ?\\ (aref name (1- len)))))
      (setq len (1- len)))
    (substring name 0 len)))

(defun clearcase-utl-file-size (file)
  (nth 7 (file-attributes file)))
(defun clearcase-utl-file-atime (file)
  (nth 4 (file-attributes file)))
(defun clearcase-utl-file-mtime (file)
  (nth 5 (file-attributes file)))
(defun clearcase-utl-file-ctime (file)
  (nth 6 (file-attributes file)))

(defun clearcase-utl-kill-view-buffer ()
  (interactive)
  (let ((buf (current-buffer)))
    (delete-windows-on buf)
    (kill-buffer buf)))

(defun clearcase-utl-escape-double-quotes (s)
  "Escape any double quotes in string S"
  (mapconcat (function (lambda (char)
                         (if (equal ?\" char)
                             (string ?\\ char)
                           (string char))))
             s
             ""))

(defun clearcase-utl-escape-backslashes (s)
  "Double any backslashes in string S"
  (mapconcat (function (lambda (char)
                         (if (equal ?\\ char)
                             "\\\\"
                           (string char))))
             s
             ""))

(defun clearcase-utl-quote-if-nec (token)
  "If TOKEN contains whitespace and is not already quoted,
wrap it in double quotes."
  (if (and (string-match "[ \t]" token)
           (not (equal ?\" (aref token 0)))
           (not (equal ?\' (aref token 0))))
      (concat "\"" token "\"")
    token))

(defun clearcase-utl-or-func (&rest args)
  "A version of `or' that can be applied to a list."
  (let ((result nil)
        (cursor args))
    (while (and (null result)
                cursor)
      (if (car cursor)
          (setq result t))
      (setq cursor (cdr cursor)))
    result))

(defun clearcase-utl-list-filter (predicate list)
  "Map PREDICATE over each element of LIST, and return a list of the elements
that mapped to non-nil."
  (let ((result '())
        (cursor list))
    (while (not (null cursor))
      (let ((elt (car cursor)))
        (if (funcall predicate elt)
            (setq result (cons elt result)))
        (setq cursor (cdr cursor))))
    (nreverse result)))

;; FSF Emacs - doesn't like parameters on mark-marker.
;;
(defun clearcase-utl-mark-marker ()
  (if clearcase-xemacs-p
      (mark-marker t)
    (mark-marker)))

(defun clearcase-utl-syslog (buf value)
  (save-excursion
    (let ((tmpbuf (get-buffer buf)))
      (if (bufferp tmpbuf)
          (progn
            (set-buffer buf)
            (goto-char (point-max))
            (insert (format "%s\n" value)))))))

;; Extract the first line of a string.
;;
(defun clearcase-utl-1st-line-of-string (s)
  (let ((newline ?\n)
        (len (length s))
        (i 0))
    (while (and (< i len)
                (not (eq newline
                         (aref s i))))
      (setq i (1+ i)))
    (substring s 0 i)))

(defun clearcase-utl-split-string (str pat &optional indir suffix)
  (let ((ret nil)
        (start 0)
        (last (length str)))
    (while (< start last)
      (if (string-match pat str start)
          (progn
            (let ((tmp (substring str start (match-beginning 0))))
              (if suffix (setq tmp (concat tmp suffix)))
              (setq ret (cons (if indir (cons tmp nil)
                                tmp)
                              ret)))
            (setq start (match-end 0)))
        (setq start last)
        (setq ret (cons (substring str start) ret))))
    (nreverse ret)))

(defun clearcase-utl-split-string-at-char (str char)
  (let ((ret nil)
        (i 0)
        (eos (length str)))
    (while (< i eos)
      ;; Collect next token
      ;;
      (let ((token-begin i))
        ;; Find the end
        ;;
        (while (and (< i eos)
                    (not (eq char (aref str i))))
          (setq i (1+ i)))

        (setq ret (cons (substring str token-begin i)
                        ret))
        (setq i (1+ i))))
    (nreverse ret)))


(defun clearcase-utl-add-env (env var)
  (catch 'return
    (let ((a env)
          (vname (substring var 0
                            (and (string-match "=" var)
                                 (match-end 0)))))
      (let ((vnl (length vname)))
        (while a
          (if (and (> (length (car a)) vnl)
                   (string= (substring (car a) 0 vnl)
                            vname))
              (throw 'return env))
          (setq a (cdr a)))
        (cons var env)))))


(defun clearcase-utl-augment-env-from-view-config-spec (old-env tag &optional add-ons)
  (let ((newenv nil)
        (cc-env (clearcase-misc-extract-evs-from-config-spe tag)))

    ;; 1. Add-on bindings at the front:
    ;;
    (while add-ons
      (setq newenv (clearcase-utl-add-env newenv (car add-ons)))
      (setq add-ons (cdr add-ons)))

    ;; 2. Then bindings defined in the config-spec:
    ;;
    (while cc-env
      (setq newenv (clearcase-utl-add-env newenv (car cc-env)))
      (setq cc-env (cdr cc-env)))

    ;; 3. Lastly bindings that were in the old environment.
    ;;
    (while old-env
      (setq newenv (clearcase-utl-add-env newenv (car old-env)))
      (setq old-env (cdr old-env)))
    newenv))

;;}}}

;;{{{ Miscellaneous

;; nyi: What does this do ?
;;
;; Presumably pull EV bindings out of comments in the config-spec.
;; Derived from Bill Sommerfeld's code and HP conventions ?
;; Leave it in for now.
;; Later define a hook to permit this kind of thing.
;;
(defun clearcase-misc-extract-evs-from-config-spe (tag)
  (let ((tmp-buffer (generate-new-buffer " *env temp*"))
        ret)
    (unwind-protect
        (save-excursion
          (set-buffer tmp-buffer)
          (insert (clearcase-ct-blocking-call "catcs" "-tag" tag))
          (goto-char (point-min))
          (keep-lines "%ENV%")
          (goto-char (point-min))
          (while (re-search-forward "^.*%ENV%[ \t]\\(.*\\)=\\(.*\\)$" nil t)
            (setq ret (cons (format "%s=%s"
                                    (buffer-substring (match-beginning 1)
                                                      (match-end 1))
                                    (buffer-substring (match-beginning 2)
                                                      (match-end 2)))
                            ret)))
          ret)
      (kill-buffer tmp-buffer))))

;;}}}

;;}}}

;;{{{ Menus

;; Predicate to determine if ClearCase menu items are relevant.
;; nyi" this should disappear
;;
(defun clearcase-buffer-contains-version-p ()
  "Return true if the current buffer contains a ClearCase file or directory."
  (let ((object-name (if (eq major-mode 'dired-mode)
                         default-directory
                       buffer-file-name)))
    (clearcase-fprop-file-is-version-p object-name)))

;;{{{ clearcase-mode menu

;;{{{ The contents

;; This version of the menu will hide rather than grey out inapplicable entries.
;;
(defvar clearcase-menu-contents-minimised
  (list "ClearCase"

        ["Check In" clearcase-checkin-current-buffer
         :keys nil
         :visible (clearcase-file-ok-to-checkin buffer-file-name)]

        ["Check Out" clearcase-checkout-current-buffer
         :keys nil
         :visible (clearcase-file-ok-to-checkout buffer-file-name)]

        ["Un-checkout" clearcase-uncheckout-current-buffer
         :visible (clearcase-file-ok-to-uncheckout buffer-file-name)]

        ["Make element" clearcase-mkelem-current-buffer
         :visible (clearcase-file-ok-to-mkelem buffer-file-name)]

        "---------------------------------"
        ["Describe version" clearcase-describe-current-buffer
         :visible (clearcase-buffer-contains-version-p)]

        ["Describe file" clearcase-describe-current-buffer
         :visible (not (clearcase-buffer-contains-version-p))]

        ["Show config-spec rule" clearcase-what-rule-current-buffer
         :visible (clearcase-buffer-contains-version-p)]

        ;; nyi: enable this also when setviewed ?
        ;;
        ["Edit config-spec" clearcase-edcs-edit t]

        "---------------------------------"
        (list "Compare (emacs)..."
              ["Compare with predecessor" clearcase-ediff-pred-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Compare with branch base" clearcase-ediff-branch-base-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Compare with named version" clearcase-ediff-named-version-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)])
        (list "Compare (applet)..."
              ["Compare with predecessor" clearcase-applet-diff-pred-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Compare with branch base" clearcase-applet-diff-branch-base-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Compare with named version" clearcase-applet-diff-named-version-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)])
        (list "Compare (diff)..."
              ["Compare with predecessor" clearcase-diff-pred-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Compare with branch base" clearcase-diff-branch-base-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Compare with named version" clearcase-diff-named-version-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)])
        "---------------------------------"
        ["Browse versions (dired)" clearcase-browse-vtree-current-buffer
         :visible (clearcase-file-ok-to-browse buffer-file-name)]
        ["Vtree browser applet" clearcase-applet-vtree-browser-current-buffer
         :keys nil
         :visible (clearcase-buffer-contains-version-p)]
        "---------------------------------"
        (list "Update snapshot..."
              ["Update view" clearcase-update-view
               :keys nil
               :visible (and (clearcase-file-is-in-view-p default-directory)
                             (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update directory" clearcase-update-default-directory
               :keys nil
               :visible (and (clearcase-file-is-in-view-p default-directory)
                             (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update this file" clearcase-update-current-buffer
               :keys nil
               :visible (and (clearcase-file-ok-to-checkout buffer-file-name)
                             (not (clearcase-file-is-in-mvfs-p buffer-file-name)))]
              )
        "---------------------------------"
        (list "Element history..."
              ["Element history (full)" clearcase-list-history-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Element history (branch)" clearcase-list-history-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)]
              ["Element history (me)" clearcase-list-history-current-buffer
               :keys nil
               :visible (clearcase-buffer-contains-version-p)])
        "---------------------------------"
        ["Make activity" clearcase-ucm-mkact-current-dir
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set activity..." clearcase-ucm-set-activity-current-dir
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set NO activity" clearcase-ucm-set-activity-none-current-dir
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Rebase this stream" clearcase-applet-rebase
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        "---------------------------------"
        (list "Applets"
              ["Merge manager" clearcase-applet-merge-manager
               :keys nil]
              ["Project explorer" clearcase-applet-project-explorer
               :keys nil]
              ["Snapshot view updater" clearcase-applet-snapshot-view-updater
               :keys nil])
        "---------------------------------"

        ;; nyi:
        ;; Enable this when current buffer is on VOB.
        ;;
        ["Make branch type" clearcase-mkbrtype
         :keys nil]

        "---------------------------------"
        ["Report Bug in ClearCase Mode" clearcase-submit-bug-report
         :keys nil]

        ["Dump internals" clearcase-dump
         :keys nil
         :visible (or (equal "rwhitby" (user-login-name))
                      (equal "esler" (user-login-name)))]

        ["Flush caches" clearcase-flush-caches
         :keys nil
         :visible (or (equal "rwhitby" (user-login-name))
                      (equal "esler" (user-login-name)))]

        "---------------------------------"
        ["Customize..." (customize-group 'clearcase)
         :keys nil]))

(defvar clearcase-menu-contents
  (list "ClearCase"

        ["Check In" clearcase-checkin-current-buffer
         :keys nil
         :active (clearcase-file-ok-to-checkin buffer-file-name)]

        ["Check Out" clearcase-checkout-current-buffer
         :keys nil
         :active (clearcase-file-ok-to-checkout buffer-file-name)]

        ["Un-checkout" clearcase-uncheckout-current-buffer
         :active (clearcase-file-ok-to-uncheckout buffer-file-name)]

        ["Make element" clearcase-mkelem-current-buffer
         :active (clearcase-file-ok-to-mkelem buffer-file-name)]

        "---------------------------------"
        ["Describe version" clearcase-describe-current-buffer
         :active (clearcase-buffer-contains-version-p)]

        ["Describe file" clearcase-describe-current-buffer
         :active (not (clearcase-buffer-contains-version-p))]

        ["Show config-spec rule" clearcase-what-rule-current-buffer
         :active (clearcase-buffer-contains-version-p)]

        ;; nyi: enable this also when setviewed ?
        ;;
        ["Edit config-spec" clearcase-edcs-edit t]

        "---------------------------------"
        (list "Compare (emacs)..."
              ["Compare with predecessor" clearcase-ediff-pred-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Compare with branch base" clearcase-ediff-branch-base-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Compare with named version" clearcase-ediff-named-version-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)])
        (list "Compare (applet)..."
              ["Compare with predecessor" clearcase-applet-diff-pred-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Compare with branch base" clearcase-applet-diff-branch-base-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Compare with named version" clearcase-applet-diff-named-version-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)])
        (list "Compare (diff)..."
              ["Compare with predecessor" clearcase-diff-pred-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Compare with branch base" clearcase-diff-branch-base-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Compare with named version" clearcase-diff-named-version-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)])
        "---------------------------------"
        ["Browse versions (dired)" clearcase-browse-vtree-current-buffer
         :active (clearcase-file-ok-to-browse buffer-file-name)]
        ["Vtree browser applet" clearcase-applet-vtree-browser-current-buffer
         :keys nil
         :active (clearcase-buffer-contains-version-p)]
        "---------------------------------"
        (list "Update snapshot..."
              ["Update view" clearcase-update-view
               :keys nil
               :active (and (clearcase-file-is-in-view-p default-directory)
                            (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update directory" clearcase-update-default-directory
               :keys nil
               :active (and (clearcase-file-is-in-view-p default-directory)
                            (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update this file" clearcase-update-current-buffer
               :keys nil
               :active (and (clearcase-file-ok-to-checkout buffer-file-name)
                            (not (clearcase-file-is-in-mvfs-p buffer-file-name)))]
              )
        "---------------------------------"
        (list "Element history..."
              ["Element history (full)" clearcase-list-history-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Element history (branch)" clearcase-list-history-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)]
              ["Element history (me)" clearcase-list-history-current-buffer
               :keys nil
               :active (clearcase-buffer-contains-version-p)])
        "---------------------------------"
        ["Make activity" clearcase-ucm-mkact-current-dir
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set activity..." clearcase-ucm-set-activity-current-dir
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set NO activity" clearcase-ucm-set-activity-none-current-dir
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Rebase this stream" clearcase-applet-rebase
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        "---------------------------------"
        (list "Applets"
              ["Merge manager" clearcase-applet-merge-manager
               :keys nil]
              ["Project explorer" clearcase-applet-project-explorer
               :keys nil]
              ["Snapshot view updater" clearcase-applet-snapshot-view-updater
               :keys nil])
        "---------------------------------"

        ;; nyi:
        ;; Enable this when current buffer is on VOB.
        ;;
        ["Make branch type" clearcase-mkbrtype
         :keys nil]

        "---------------------------------"
        ["Report Bug in ClearCase Mode" clearcase-submit-bug-report
         :keys nil]

        ["Dump internals" clearcase-dump
         :keys nil
         :active (or (equal "rwhitby" (user-login-name))
                     (equal "esler" (user-login-name)))]

        ["Flush caches" clearcase-flush-caches
         :keys nil
         :active (or (equal "rwhitby" (user-login-name))
                     (equal "esler" (user-login-name)))]

        "---------------------------------"
        ["Customize..." (customize-group 'clearcase)
         :keys nil]))

(if (and clearcase-minimise-menus
         (not clearcase-xemacs-p))
    (setq clearcase-menu-contents clearcase-menu-contents-minimised))

;;}}}

(if (>= emacs-major-version '20)
    (progn
      ;; Define the menu
      ;;
      (easy-menu-define
       clearcase-menu
       (list clearcase-mode-map)
       "ClearCase menu"
       clearcase-menu-contents)

      (or clearcase-xemacs-p
          (add-to-list 'menu-bar-final-items 'ClearCase))))

;;}}}

;;{{{ clearcase-dired-mode menu

;;{{{ Related functions

;; nyi: this probably gets run for each menu element.
;;      For better efficency, look into using a one-pass ":filter"
;;      to construct this menu dynamically.

(defun clearcase-dired-mark-count ()
  (let ((old-point (point))
        (count 0))
    (goto-char (point-min))
    (while (re-search-forward
            (concat "^" (regexp-quote (char-to-string
                                       dired-marker-char))) nil t)
      (setq count (1+ count)))
    (goto-char old-point)
    count))

(defun clearcase-dired-current-ok-to-checkin ()
  (let ((file (dired-get-filename nil t)))
    (and file
         (clearcase-file-ok-to-checkin file))))

(defun clearcase-dired-current-ok-to-checkout ()
  (let ((file (dired-get-filename nil t)))
    (and file
         (clearcase-file-ok-to-checkout file))))

(defun clearcase-dired-current-ok-to-uncheckout ()
  (let ((file (dired-get-filename nil t)))
    (and file
         (clearcase-file-ok-to-uncheckout file))))

(defun clearcase-dired-current-ok-to-mkelem ()
  (let ((file (dired-get-filename nil t)))
    (and file
         (clearcase-file-ok-to-mkelem file))))

(defun clearcase-dired-current-ok-to-browse ()
  (let ((file (dired-get-filename nil t)))
    (clearcase-file-ok-to-browse file)))

(defvar clearcase-dired-max-marked-files-to-check 5
  "The maximum number of marked files in a Dired buffer when constructing
the ClearCase menu.")

(defun clearcase-dired-marked-ok-to-checkin ()
  (let ((files (dired-get-marked-files)))
    (or (> (length files) clearcase-dired-max-marked-files-to-check)
        (apply (function clearcase-utl-or-func)
               (mapcar
                (function clearcase-file-ok-to-checkin)
                files)))))

(defun clearcase-dired-marked-ok-to-checkout ()
  (let ((files (dired-get-marked-files)))
    (or (> (length files) clearcase-dired-max-marked-files-to-check)
        (apply (function clearcase-utl-or-func)
               (mapcar
                (function clearcase-file-ok-to-checkout)
                files)))))

(defun clearcase-dired-marked-ok-to-uncheckout ()
  (let ((files (dired-get-marked-files)))
    (or (> (length files) clearcase-dired-max-marked-files-to-check)
        (apply (function clearcase-utl-or-func)
               (mapcar
                (function clearcase-file-ok-to-uncheckout)
                files)))))

(defun clearcase-dired-marked-ok-to-mkelem ()
  (let ((files (dired-get-marked-files)))
    (or (> (length files) clearcase-dired-max-marked-files-to-check)
        (apply (function clearcase-utl-or-func)
               (mapcar
                (function clearcase-file-ok-to-mkelem)
                files)))))

(defun clearcase-dired-current-dir-ok-to-checkin ()
  (let ((dir (dired-current-directory)))
    (clearcase-file-ok-to-checkin dir)))

(defun clearcase-dired-current-dir-ok-to-checkout ()
  (let ((dir (dired-current-directory)))
    (clearcase-file-ok-to-checkout dir)))

(defun clearcase-dired-current-dir-ok-to-uncheckout ()
  (let ((dir (dired-current-directory)))
    (clearcase-file-ok-to-uncheckout dir)))

;;}}}

;;{{{ Contents

;; This version of the menu will hide rather than grey out inapplicable entries.
;;
(defvar clearcase-dired-menu-contents-minimised
  (list "ClearCase"

        ;; Current file
        ;;
        ["Check-in file" clearcase-checkin-dired-files
         :keys nil
         :visible (and (< (clearcase-dired-mark-count) 2)
                       (clearcase-dired-current-ok-to-checkin))]

        ["Check-out file" clearcase-checkout-dired-files
         :keys nil
         :visible (and (< (clearcase-dired-mark-count) 2)
                       (clearcase-dired-current-ok-to-checkout))]

        ["Un-check-out file" clearcase-uncheckout-dired-files
         :keys nil
         :visible (and (< (clearcase-dired-mark-count) 2)
                       (clearcase-dired-current-ok-to-uncheckout))]

        ["Make file an element" clearcase-mkelem-dired-files
         :visible (and (< (clearcase-dired-mark-count) 2)
                       (clearcase-dired-current-ok-to-mkelem))]

        ;; Marked files
        ;;
        ["Check-in marked files" clearcase-checkin-dired-files
         :keys nil
         :visible (and (>= (clearcase-dired-mark-count) 2)
                       (clearcase-dired-marked-ok-to-checkin))]

        ["Check-out marked files" clearcase-checkout-dired-files
         :keys nil
         :visible (and (>= (clearcase-dired-mark-count) 2)
                       (clearcase-dired-marked-ok-to-checkout))]

        ["Un-check-out marked files" clearcase-uncheckout-dired-files
         :keys nil
         :visible (and (>= (clearcase-dired-mark-count) 2)
                       (clearcase-dired-marked-ok-to-uncheckout))]

        ["Make marked files elements" clearcase-mkelem-dired-files
         :keys nil
         :visible (and (>= (clearcase-dired-mark-count) 2)
                       (clearcase-dired-marked-ok-to-mkelem))]


        ;; Current directory
        ;;
        ["Check-in current-dir" clearcase-dired-checkin-current-dir
         :keys nil
         :visible (clearcase-dired-current-dir-ok-to-checkin)]

        ["Check-out current dir" clearcase-dired-checkout-current-dir
         :keys nil
         :visible (clearcase-dired-current-dir-ok-to-checkout)]

        ["Un-checkout current dir" clearcase-dired-uncheckout-current-dir
         :keys nil
         :visible (clearcase-dired-current-dir-ok-to-uncheckout)]

        "---------------------------------"
        ["Describe file" clearcase-describe-dired-file
         :visible t]

        ["Show config-spec rule" clearcase-what-rule-dired-file
         :visible t]


        ["Edit config-spec" clearcase-edcs-edit t]

        "---------------------------------"
        (list "Compare (emacs)..."
              ["Compare with predecessor" clearcase-ediff-pred-dired-file
               :keys nil
               :visible t]
              ["Compare with branch base" clearcase-ediff-branch-base-dired-file
               :keys nil
               :visible t]
              ["Compare with named version" clearcase-ediff-named-version-dired-file
               :keys nil
               :visible t])
        (list "Compare (applet)..."
              ["Compare with predecessor" clearcase-applet-diff-pred-dired-file
               :keys nil
               :visible t]
              ["Compare with branch base" clearcase-applet-diff-branch-base-dired-file
               :keys nil
               :visible t]
              ["Compare with named version" clearcase-applet-diff-named-version-dired-file
               :keys nil
               :visible t])
        (list "Compare (diff)..."
              ["Compare with predecessor" clearcase-diff-pred-dired-file
               :keys nil
               :visible t]
              ["Compare with branch base" clearcase-diff-branch-base-dired-file
               :keys nil
               :visible t]
              ["Compare with named version" clearcase-diff-named-version-dired-file
               :keys nil
               :visible t])
        "---------------------------------"
        ["Browse versions (dired)" clearcase-browse-vtree-dired-file
         :visible (clearcase-dired-current-ok-to-browse)]
        ["Vtree browser applet" clearcase-applet-vtree-browser-dired-file
         :keys nil
         :visible t]
        "---------------------------------"
        (list "Update snapshot..."
              ["Update view" clearcase-update-view
               :keys nil
               :visible (and (clearcase-file-is-in-view-p default-directory)
                             (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update directory" clearcase-update-default-directory
               :keys nil
               :visible (and (clearcase-file-is-in-view-p default-directory)
                             (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update file" clearcase-update-dired-files
               :keys nil
               :visible (and (< (clearcase-dired-mark-count) 2)
                             (clearcase-dired-current-ok-to-checkout)
                             (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update marked files" clearcase-update-dired-files
               :keys nil
               :visible (and (>= (clearcase-dired-mark-count) 2)
                             (not (clearcase-file-is-in-mvfs-p default-directory)))]
              )
        "---------------------------------"
        (list "Element history..."
              ["Element history (full)" clearcase-list-history-dired-file
               :keys nil
               :visible t]
              ["Element history (branch)" clearcase-list-history-dired-file
               :keys nil
               :visible t]
              ["Element history (me)" clearcase-list-history-dired-file
               :keys nil
               :visible t])
        "---------------------------------"
        ["Make activity" clearcase-ucm-mkact-current-dir
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set activity..." clearcase-ucm-set-activity-current-dir
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set NO activity" clearcase-ucm-set-activity-none-current-dir
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Rebase this stream" clearcase-applet-rebase
         :keys nil
         :visible (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        "---------------------------------"
        (list "Applets"
              ["Merge manager" clearcase-applet-merge-manager
               :keys nil]
              ["Project explorer" clearcase-applet-project-explorer
               :keys nil]
              ["Snapshot view updater" clearcase-applet-snapshot-view-updater
               :keys nil])
        "---------------------------------"

        ["Make branch type" clearcase-mkbrtype
         :keys nil]

        "---------------------------------"
        ["Report Bug in ClearCase Mode" clearcase-submit-bug-report
         :keys nil]

        ["Dump internals" clearcase-dump
         :keys nil
         :visible (or (equal "rwhitby" (user-login-name))
                      (equal "esler" (user-login-name)))]

        ["Flush caches" clearcase-flush-caches
         :keys nil
         :visible (or (equal "rwhitby" (user-login-name))
                      (equal "esler" (user-login-name)))]

        "---------------------------------"
        ["Customize..." (customize-group 'clearcase)
         :keys nil]))

(defvar clearcase-dired-menu-contents
  (list "ClearCase"

        ;; Current file
        ;;
        ["Check-in file" clearcase-checkin-dired-files
         :keys nil
         :active (and (< (clearcase-dired-mark-count) 2)
                      (clearcase-dired-current-ok-to-checkin))]

        ["Check-out file" clearcase-checkout-dired-files
         :keys nil
         :active (and (< (clearcase-dired-mark-count) 2)
                      (clearcase-dired-current-ok-to-checkout))]

        ["Un-check-out file" clearcase-uncheckout-dired-files
         :keys nil
         :active (and (< (clearcase-dired-mark-count) 2)
                      (clearcase-dired-current-ok-to-uncheckout))]

        ["Make file an element" clearcase-mkelem-dired-files
         :active (and (< (clearcase-dired-mark-count) 2)
                      (clearcase-dired-current-ok-to-mkelem))]

        ;; Marked files
        ;;
        ["Check-in marked files" clearcase-checkin-dired-files
         :keys nil
         :active (and (>= (clearcase-dired-mark-count) 2)
                      (clearcase-dired-marked-ok-to-checkin))]

        ["Check-out marked files" clearcase-checkout-dired-files
         :keys nil
         :active (and (>= (clearcase-dired-mark-count) 2)
                      (clearcase-dired-marked-ok-to-checkout))]

        ["Un-check-out marked files" clearcase-uncheckout-dired-files
         :keys nil
         :active (and (>= (clearcase-dired-mark-count) 2)
                      (clearcase-dired-marked-ok-to-uncheckout))]

        ["Make marked files elements" clearcase-mkelem-dired-files
         :keys nil
         :active (and (>= (clearcase-dired-mark-count) 2)
                      (clearcase-dired-marked-ok-to-mkelem))]


        ;; Current directory
        ;;
        ["Check-in current-dir" clearcase-dired-checkin-current-dir
         :keys nil
         :active (clearcase-dired-current-dir-ok-to-checkin)]

        ["Check-out current dir" clearcase-dired-checkout-current-dir
         :keys nil
         :active (clearcase-dired-current-dir-ok-to-checkout)]

        ["Un-checkout current dir" clearcase-dired-uncheckout-current-dir
         :keys nil
         :active (clearcase-dired-current-dir-ok-to-uncheckout)]

        "---------------------------------"
        ["Describe file" clearcase-describe-dired-file
         :active t]

        ["Show config-spec rule" clearcase-what-rule-dired-file
         :active t]


        ["Edit config-spec" clearcase-edcs-edit t]

        "---------------------------------"
        (list "Compare (emacs)..."
              ["Compare with predecessor" clearcase-ediff-pred-dired-file
               :keys nil
               :active t]
              ["Compare with branch base" clearcase-ediff-branch-base-dired-file
               :keys nil
               :active t]
              ["Compare with named version" clearcase-ediff-named-version-dired-file
               :keys nil
               :active t])
        (list "Compare (applet)..."
              ["Compare with predecessor" clearcase-applet-diff-pred-dired-file
               :keys nil
               :active t]
              ["Compare with branch base" clearcase-applet-diff-branch-base-dired-file
               :keys nil
               :active t]
              ["Compare with named version" clearcase-applet-diff-named-version-dired-file
               :keys nil
               :active t])
        (list "Compare (diff)..."
              ["Compare with predecessor" clearcase-diff-pred-dired-file
               :keys nil
               :active t]
              ["Compare with branch base" clearcase-diff-branch-base-dired-file
               :keys nil
               :active t]
              ["Compare with named version" clearcase-diff-named-version-dired-file
               :keys nil
               :active t])
        "---------------------------------"
        ["Browse versions (dired)" clearcase-browse-vtree-dired-file
         :active (clearcase-dired-current-ok-to-browse)]
        ["Vtree browser applet" clearcase-applet-vtree-browser-dired-file
         :keys nil
         :active t]
        "---------------------------------"
        (list "Update snapshot..."
              ["Update view" clearcase-update-view
               :keys nil
               :active (and (clearcase-file-is-in-view-p default-directory)
                            (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update directory" clearcase-update-default-directory
               :keys nil
               :active (and (clearcase-file-is-in-view-p default-directory)
                            (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update file" clearcase-update-dired-files
               :keys nil
               :active (and (< (clearcase-dired-mark-count) 2)
                            (clearcase-dired-current-ok-to-checkout)
                            (not (clearcase-file-is-in-mvfs-p default-directory)))]
              ["Update marked files" clearcase-update-dired-files
               :keys nil
               :active (and (>= (clearcase-dired-mark-count) 2)
                            (not (clearcase-file-is-in-mvfs-p default-directory)))]
              )
        "---------------------------------"
        (list "Element history..."
              ["Element history (full)" clearcase-list-history-dired-file
               :keys nil
               :active t]
              ["Element history (branch)" clearcase-list-history-dired-file
               :keys nil
               :active t]
              ["Element history (me)" clearcase-list-history-dired-file
               :keys nil
               :active t])
        "---------------------------------"
        ["Make activity" clearcase-ucm-mkact-current-dir
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set activity..." clearcase-ucm-set-activity-current-dir
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Set NO activity" clearcase-ucm-set-activity-none-current-dir
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        ["Rebase this stream" clearcase-applet-rebase
         :keys nil
         :active (clearcase-vprop-ucm (clearcase-fprop-viewtag default-directory))]
        "---------------------------------"
        (list "Applets"
              ["Merge manager" clearcase-applet-merge-manager
               :keys nil]
              ["Project explorer" clearcase-applet-project-explorer
               :keys nil]
              ["Snapshot view updater" clearcase-applet-snapshot-view-updater
               :keys nil])
        "---------------------------------"

        ["Make branch type" clearcase-mkbrtype
         :keys nil]

        "---------------------------------"
        ["Report Bug in ClearCase Mode" clearcase-submit-bug-report
         :keys nil]

        ["Dump internals" clearcase-dump
         :keys nil
         :active (or (equal "rwhitby" (user-login-name))
                     (equal "esler" (user-login-name)))]

        ["Flush caches" clearcase-flush-caches
         :keys nil
         :active (or (equal "rwhitby" (user-login-name))
                     (equal "esler" (user-login-name)))]

        "---------------------------------"
        ["Customize..." (customize-group 'clearcase)
         :keys nil]))

(if (and clearcase-minimise-menus
         (not clearcase-xemacs-p))
    (setq clearcase-dired-menu-contents clearcase-dired-menu-contents-minimised))

;;}}}

(if (>= emacs-major-version '20)
    (progn
      (easy-menu-define
       clearcase-dired-menu
       (list clearcase-dired-mode-map)
       "ClearCase Dired menu"
       clearcase-dired-menu-contents)

      (or clearcase-xemacs-p
          (add-to-list 'menu-bar-final-items 'ClearCase))))

;;}}}

;;}}}

;;{{{ Widgets

;;{{{ Single-selection buffer widget

;; Keep the compiler quiet by declaring these
;; buffer-local variables here thus.
;;
(defvar clearcase-selection-window-config nil)
(defvar clearcase-selection-interpreter nil)
(defvar clearcase-selection-continuation nil)
(defvar clearcase-selection-operands nil)

(defun clearcase-ucm-make-selection-window (buffer-name
                                            buffer-contents
                                            selection-interpreter
                                            continuation
                                            cont-arglist)
  (let ((buf (get-buffer-create buffer-name)))
    (save-excursion

      ;; Reset the buffer
      ;;
      (set-buffer buf)
      (setq buffer-read-only nil)
      (erase-buffer)
      (setq truncate-lines t)

      ;; Paint the buffer
      ;;
      (goto-char (point-min))
      (insert buffer-contents)

      ;; Insert mouse-highlighting
      ;;
      (save-excursion
        (goto-char (point-min))
        (while (< (point) (point-max))
          (condition-case nil
              (progn
                (beginning-of-line)
                (put-text-property (point)
                                   (save-excursion
                                     (end-of-line)
                                     (point))
                                   'mouse-face 'highlight))
            (error nil))
          (forward-line 1)))

      ;; Set a keymap
      ;;
      (setq buffer-read-only t)
      (use-local-map clearcase-selection-keymap)

      ;; Set up the interpreter and continuation
      ;;
      (set (make-local-variable 'clearcase-selection-window-config)
           (current-window-configuration))
      (set (make-local-variable 'clearcase-selection-interpreter)
           selection-interpreter)
      (set (make-local-variable 'clearcase-selection-continuation)
           continuation)
      (set (make-local-variable 'clearcase-selection-operands)
           cont-arglist))

    ;; Display the buffer
    ;;
    (pop-to-buffer buf)
    (goto-char 0)
    (shrink-window-if-larger-than-buffer)
    (message "Use RETURN to select an item")))

(defun clearcase-selection-continue ()
  (interactive)
  (beginning-of-line)
  (sit-for 0)
  ;; Call the interpreter to extract the item of interest
  ;; from the buffer.
  ;;
  (let ((item (funcall clearcase-selection-interpreter)))
    ;; Call the continuation.
    ;;
    (apply clearcase-selection-continuation
           (append clearcase-selection-operands (list item))))

  ;; Restore window config
  ;;
  (let ((sel-buffer (current-buffer)))
    (if clearcase-selection-window-config
        (set-window-configuration clearcase-selection-window-config))
    (delete-windows-on sel-buffer)
    (kill-buffer sel-buffer)))

(defun clearcase-selection-mouse-continue (click)
  (interactive "@e")
  (mouse-set-point click)
  (clearcase-selection-continue))

(defvar clearcase-selection-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map [return] 'clearcase-selection-continue)
    (define-key map [mouse-2] 'clearcase-selection-mouse-continue)
    (define-key map "q" 'clearcase-utl-kill-view-buffer)
    ;; nyi: refresh list
    ;; (define-key map "g" 'clearcase-selection-get)
    map))

;;}}}

;;}}}

;;{{{ Integration with Emacs

;;{{{ Detecting that ClearCase is installed and running

(defvar clearcase-clearcase-version-installed
  (let ((cmd-output (shell-command-to-string "cleartool -version")))
    (if (string-match "ClearCase version" cmd-output)
        cmd-output))
  "The version of ClearCase that is installed on the computer.")

(defvar clearcase-v3
  (and clearcase-clearcase-version-installed
       (string-match "^ClearCase version 3"
                     clearcase-clearcase-version-installed)))
(defvar clearcase-v4
  (and clearcase-clearcase-version-installed
       (string-match "^ClearCase version 4"
                     clearcase-clearcase-version-installed)))

(defun clearcase-servers-online-p ()
  "Heuristic to determine if the local host is network-connected to
its ClearCase servers."

  ;; nyi: Something more lightweight would be nice.
  ;;
  (let ((result nil)
        (buf (get-buffer-create "*clearcase-lsregion*")))
    (save-excursion
      (set-buffer buf)
      (erase-buffer)
      (let ((process (start-process "lsregion" buf clearcase-cleartool-path "lsregion" "-long"))
            (timeout-occurred nil))

        ;; Now wait a little while, if necessary, for some output.
        ;;
        (while (and (null result)
                    (not timeout-occurred)
                    (< (buffer-size) (length "Tag: ")))
          (if (null (accept-process-output process 10))
              (setq timeout-occurred t))
          (goto-char (point-min))
          (if (looking-at "Tag: ")
              (setq result t)))
        (if (memq (process-status process) '(run stop))
            (kill-process process))))
    ;; If servers are apparently not online, keep the
    ;; buffer around so we can see what lsregion reported.
    ;;
    (if result
        (kill-buffer buf))
    result))

(defvar clearcase-servers-online
  (and clearcase-clearcase-version-installed
       (clearcase-servers-online-p))
  "T if ClearCase servers can be contacted, otherwise nil")

(defvar clearcase-setview-root
  (if (not clearcase-on-mswindows)
      (getenv "CLEARCASE_ROOT"))
  "The setview view-root of the Emacs process")

(defvar clearcase-setview-viewtag
  (if clearcase-setview-root
      (file-name-nondirectory clearcase-setview-root))
  "The setview viewtag of the Emacs process")

;;}}}

;;{{{ Hooks

;;{{{ A find-file hook to turn on clearcase-mode

(defun clearcase-hook-find-file-hook ()
  (let ((filename (buffer-file-name)))
    (if filename
        (progn
          (clearcase-fprop-unstore-properties filename)
          (if (clearcase-file-would-be-in-view-p filename)
              (progn
                ;; 1. Activate minor mode
                ;;
                (clearcase-mode 1)

                ;; 2. Pre-fetch file properties
                ;;
                (if (file-exists-p filename)
                    (progn
                      (clearcase-fprop-get-properties filename)

                      ;; 3. Put branch/ver in mode-line
                      ;;
                      (setq clearcase-mode
                            (concat " ClearCase:"
                                    (clearcase-mode-line-buffer-id filename)))
                      (force-mode-line-update)

                      ;; 4. Schedule the asynchronous fetching of the view's properties
                      ;;    next time Emacs is idle enough.
                      ;;
                      (clearcase-vprop-schedule-fetch (clearcase-fprop-viewtag filename))))

                (clearcase-set-auto-mode)))))))

(defun clearcase-set-auto-mode ()
  "Check again for the mode of the current buffer when using ClearCase version extended paths."

  (let* ((version (clearcase-vxpath-version-part (buffer-file-name)))
         (buffer-file-name (clearcase-vxpath-element-part (buffer-file-name))))

    ;; Need to recheck the major mode only if a version was appended.
    ;;
    (if version
        (set-auto-mode))))

;;}}}

;;{{{ A find-file hook for version-extended pathnames

;; Set the buffer name to <filename>@@/<branch path>/<version>,
;; even when we're using a version-extended pathname.
;;
(defun clearcase-hook-vxpath-find-file-hook ()
  (if (clearcase-vxpath-p default-directory)
      (let ((element (clearcase-vxpath-element-part default-directory))
            (version (clearcase-vxpath-version-part default-directory)))

        (let ((new-buffer-name
               (concat (file-name-nondirectory element)
                       clearcase-vxpath-glue
                       version
                       (buffer-name)))
              (new-dir (file-name-directory element)))

          (or (string= new-buffer-name (buffer-name))

              ;; Uniquify the name, if necessary.
              ;;
              (let ((n 2)
                    (uniquifier-string ""))
                (while (get-buffer (concat new-buffer-name uniquifier-string))
                  (setq uniquifier-string (format "<%d>" n))
                  (setq n (1+ n)))
                (rename-buffer
                 (concat new-buffer-name uniquifier-string))))
          (setq default-directory new-dir)))
    nil))

;;}}}

;;{{{ A dired-mode-hook to turn on clearcase-dired-mode

(defun clearcase-hook-dired-mode-hook ()
  ;; Force a re-computation of whether the directory is within ClearCase.
  ;;
  (clearcase-fprop-unstore-properties default-directory)

  ;; Wrap this in an exception handler. Otherwise, diredding into
  ;; a deregistered or otherwise defective snapshot-view fails.
  ;;
  (condition-case ()
      ;; If this directory is below a ClearCase element,
      ;;   1. turn on ClearCase Dired Minor Mode.
      ;;   2. display branch/ver in mode-line
      ;;
      (if (clearcase-file-would-be-in-view-p default-directory)
          (progn
            (if clearcase-auto-dired-mode
                (progn
                  (clearcase-dired-mode 1)
                  (clearcase-fprop-get-properties default-directory)
                  (clearcase-vprop-schedule-fetch (clearcase-fprop-viewtag default-directory))))
            (setq clearcase-dired-mode
                  (concat " ClearCase:"
                          (clearcase-mode-line-buffer-id default-directory)))
            (force-mode-line-update)))
    (error (message "Error fetching ClearCase properties of %s" default-directory))))

;;}}}

;;{{{ A dired-after-readin-hook to add ClearCase information to the display

(defun clearcase-hook-dired-after-readin-hook ()

  ;; If in clearcase-dired-mode, reformat the buffer.
  ;;
  (if clearcase-dired-mode
      (clearcase-dired-reformat-buffer))
  t)

;;}}}

;;{{{ A write-file-hook to auto-insert a version-string.

;; To use this, put a line containing this in the first 8 lines of your file:
;;    ClearCase-version: </main/161>
;; and make sure that clearcase-version-stamp-active gets set to true at least
;; locally in the file.

(defvar clearcase-version-stamp-line-limit 1000)
(defvar clearcase-version-stamp-begin-regexp "ClearCase-version:[ \t]<")
(defvar clearcase-version-stamp-end-regexp ">")
(defvar clearcase-version-stamp-active nil)

(defun clearcase-increment-version (version-string)
  (let* ((branch (file-name-directory version-string))
         (number (file-name-nondirectory version-string))
         (new-number (1+ (string-to-number number))))
    (format "%s%d" branch new-number)))

(defun clearcase-version-stamp ()
  (interactive)
  (if (and clearcase-version-stamp-active
           (file-exists-p buffer-file-name)
           (equal 'version (clearcase-fprop-mtype buffer-file-name)))
      (let ((latest-version (clearcase-fprop-predecessor-version buffer-file-name)))
        (save-excursion
          (save-restriction
            (widen)
            (goto-char (point-min))
            (forward-line clearcase-version-stamp-line-limit)
            (let ((limit (point))
                  (v-start nil)
                  (v-end nil))
              (goto-char (point-min))
              (while (and (< (point) limit)
                          (re-search-forward clearcase-version-stamp-begin-regexp
                                             limit
                                             'move))
                (setq v-start (point))
                (end-of-line)
                (let ((line-end (point)))
                  (goto-char v-start)
                  (if (re-search-forward clearcase-version-stamp-end-regexp
                                         line-end
                                         'move)
                      (setq v-end (match-beginning 0)))))
              (if v-end
                  (let ((new-version-stamp (clearcase-increment-version latest-version)))
                    (goto-char v-start)
                    (delete-region v-start v-end)
                    (insert-and-inherit new-version-stamp)))))))))

(defun clearcase-hook-write-file-hook ()

  (clearcase-version-stamp)
  ;; Important to return nil so the files eventually gets written.
  ;;
  nil)

;;}}}

;;{{{ A kill-buffer hook

(defun clearcase-hook-kill-buffer-hook ()
  (let ((filename (buffer-file-name)))
    (if (and filename
             ;; W3 has buffers in which 'buffer-file-name is bound to
             ;; a URL.  Don't attempt to unstore their properties.
             ;;
             (boundp 'buffer-file-truename)
             buffer-file-truename)
        (clearcase-fprop-unstore-properties filename))))

;;}}}

;;}}}

;;{{{ Replace toggle-read-only

(defun clearcase-toggle-read-only (&optional arg)
  "Change read-only status of current buffer, perhaps via version control.
If the buffer is visiting a ClearCase version, then check the file in or out.
Otherwise, just change the read-only flag of the buffer.  If called with an
argument then just change the read-only flag even if visiting a ClearCase
version."
  (interactive "P")
  (cond (arg
	 (toggle-read-only))
	((and (clearcase-fprop-mtype buffer-file-name)
              buffer-read-only
              (file-writable-p buffer-file-name)
              (/= 0 (user-uid)))
         (toggle-read-only))

        ((clearcase-fprop-mtype buffer-file-name)
         (clearcase-next-action-current-buffer))

        (t
         (toggle-read-only))))

;;}}}

;;{{{ File-name-handlers

;;{{{ Start dynamic views automatically when paths to them are used

;; This handler starts views when viewroot-relative paths are dereferenced.
;;
;; nyi: for now really only seems useful on Unix.
;;
(defun clearcase-viewroot-relative-file-name-handler (operation &rest args)

  (clearcase-when-debugging
   (if (fboundp 'clearcase-utl-syslog)
       (clearcase-utl-syslog "*clearcase-fh-trace*"
                             (cons "clearcase-viewroot-relative-file-name-handler:"
                                   (cons operation args)))))

  ;; Inhibit the handler to avoid recursion.
  ;;
  (let ((inhibit-file-name-handlers
         (cons 'clearcase-viewroot-relative-file-name-handler
               (and (eq inhibit-file-name-operation operation)
                    inhibit-file-name-handlers)))
        (inhibit-file-name-operation operation))

    (let ((first-arg (car args)))
      ;; We don't always get called with a string.
      ;; e.g. one file operation is verify-visited-file-modtime, whose
      ;; first argument is a buffer.
      ;;
      (if (stringp first-arg)
          (progn
            ;; Now start the view if necessary
            ;;
            (save-match-data
              (let* ((path (clearcase-path-remove-useless-viewtags first-arg))
                     (viewtag (clearcase-vrpath-viewtag path))
                     (default-directory (clearcase-path-remove-useless-viewtags default-directory)))
                (if viewtag
                    (clearcase-viewtag-try-to-start-view viewtag))))))
      (apply operation args))))

;;}}}

;;{{{ Completion on viewtags

;; This handler provides completion for viewtags.
;;
(defun clearcase-viewtag-file-name-handler (operation &rest args)

  (clearcase-when-debugging
   (if (fboundp 'clearcase-utl-syslog)
       (clearcase-utl-syslog "*clearcase-fh-trace*"
                             (cons "clearcase-viewtag-file-name-handler:"
                                   (cons operation args)))))
  (cond

   ((eq operation 'file-name-completion)
    (save-match-data (apply 'clearcase-viewtag-completion args)))

   ((eq operation 'file-name-all-completions)
    (save-match-data (apply 'clearcase-viewtag-completions args)))

   (t
    (let ((inhibit-file-name-handlers
           (cons 'clearcase-viewtag-file-name-handler
                 (and (eq inhibit-file-name-operation operation)
                      inhibit-file-name-handlers)))
          (inhibit-file-name-operation operation))
      (apply operation args)))))

(defun clearcase-viewtag-completion (file dir)
  (try-completion file (clearcase-viewtag-all-viewtags-obarray)))

(defun clearcase-viewtag-completions (file dir)
  (all-completions file (clearcase-viewtag-all-viewtags-obarray)))

;;}}}

;;{{{ Disable VC in the MVFS

;; This handler ensures that VC doesn't attempt to operate inside the MVFS.
;; This stops it from futile searches for RCS directories and the like inside.
;; It prevents a certain amount of clutter in the MVFS' noent-cache.
;;
(defun clearcase-suppress-vc-within-mvfs-file-name-handler (operation &rest args)
  (clearcase-when-debugging
   (if (fboundp 'clearcase-utl-syslog)
       (clearcase-utl-syslog "*clearcase-fh-trace*"
                             (cons "clearcase-suppress-vc-within-mvfs-file-name-handler:"
                                   (cons operation args)))))
  ;; Inhibit recursion:
  ;;
  (let ((inhibit-file-name-handlers
         (cons 'clearcase-suppress-vc-within-mvfs-file-name-handler
               (and (eq inhibit-file-name-operation operation)
                    inhibit-file-name-handlers)))
        (inhibit-file-name-operation operation))

    (cond
     ((and (eq operation 'vc-registered)
           (clearcase-file-would-be-in-view-p (car args)))
      nil)

     (t
      (apply operation args)))))

;;}}}

;;}}}

;;{{{ Advise some functions

;;{{{ Advise gud-find-file

(defun clearcase-advise-gud-find-file ()
  (defadvice gud-find-file (before clearcase-gud-find-file protect activate)
    "Sets the current view and comint-file-name-prefix if necessary for
ClearCase support."
    (let ((prefix (clearcase-vrpath-head default-directory)))
      (and prefix
           (ad-set-arg 0 (concat prefix (ad-get-arg 0)))))))

;;}}}

;;{{{ Advise comint-exec-1 to do ct+setview

;; nyi: ensure we don't do setview to a snapshot view

(defsubst clearcase-ct-setview-arglist (dir args)
  (let ((r (concat (if dir (format "cd %s; " dir) "")
                   "exec "
                   (mapconcat 'identity args " "))))
    (insert r "\n")
    r))

(defun clearcase-advise-comint-exec-1 ()
  (defadvice comint-exec-1 (around clearcase-comint-exec-1 protect activate)
    "Sets the current view and comint-file-name-prefix if necessary for
ClearCase support."
    (let ((tag (clearcase-fprop-viewtag default-directory))
          (view-rel (clearcase-vrpath-tail default-directory)))
      (if (or
           ;; No setview on w32:
           ;;
           clearcase-on-mswindows

           ;; No setview unless un MVFS:
           ;;
           (not (or (clearcase-vrpath-p default-directory)
                    (clearcase-wd-is-in-mvfs)))

           ;; No need to setview if the view is the same
           ;; as Emacs' setview:
           ;;
           (and clearcase-setview-root
                (string= tag (clearcase-vrpath-viewtag clearcase-setview-root))))
          ad-do-it
        (let ((process-environment

               ;; If using termcap, we specify `emacs' as the terminal type
               ;; because that lets us specify a width.  If using terminfo, we
               ;; specify `unknown' because that is a defined terminal type.
               ;; `emacs' is not a defined terminal type and there is no way for
               ;; us to define it here.  Some programs that use terminfo get very
               ;; confused if TERM is not a valid terminal type.
               ;;
               (clearcase-utl-augment-env-from-view-config-spec process-environment tag
                                                                (if (and (boundp 'system-uses-terminfo)
                                                                         (symbol-value 'system-uses-terminfo))
                                                                    (list "EMACS=t"
                                                                          "TERM=unknown"
                                                                          (format "COLUMNS=%d"
                                                                                  (frame-width)))
                                                                  (list "EMACS=t"
                                                                        "TERM=emacs"
                                                                        (format "TERMCAP=emacs:co#%d:tc=unknown"
                                                                                (frame-width)))))))
          (insert "setview " tag "\n")
          (make-variable-buffer-local 'comint-file-name-prefix)
          (setq comint-file-name-prefix (format (concat clearcase-viewroot "/%s") tag))
          (setq ad-return-value
                (start-process name buffer clearcase-cleartool-path
                               "setview" "-exec"
                               (clearcase-ct-setview-arglist view-rel
                                                             (cons command switches))
                               tag)))))))

;;}}}

;;{{{ Advise start-process-shell-command to do ct+setview

;; nyi: Problems here:
;;      variable "buffer" is free
;;      do we need it anyway ?

;; (defun clearcase-advise-start-process-shell-command ()
;;   (defadvice start-process-shell-command (around clearcase-spsc protect activate)
;;     "Sets the current view if necessary for ClearCase support."
;;     (let ((tag (clearcase-fprop-viewtag default-directory))
;;           (view-rel (clearcase-vrpath-tail default-directory)))
;;       (if (or clearcase-on-mswindows
;;               (not (clearcase-wd-is-in-mvfs)))
;;           ;; On w32 or outside MVFS don't bother modifying the behaviour
;;           ;;
;;           ad-do-it
;;         (let ((process-environment (clearcase-utl-augment-env-from-view-config-spec process-environment tag)))
;;           (if (and clearcase-setview-root
;;                    (string= tag (clearcase-vrpath-viewtag clearcase-setview-root)))
;;               ad-do-it
;;             (progn
;;               (setq ad-return-value
;;                     (start-process name buffer clearcase-cleartool-path
;;                                    "setview" "-exec"
;;                                    (clearcase-ct-setview-arglist view-rel args)
;;                                    tag)))))))))

;;}}}

;;}}}

(defun clearcase-integrate ()
  "Enable ClearCase integration"
  (interactive)

  ;; 0. Empty caches.
  ;;
  (clearcase-fprop-clear-all-properties)
  (clearcase-vprop-clear-all-properties)

  ;; 1. Install hooks.
  ;;
  (add-hook 'find-file-hooks 'clearcase-hook-find-file-hook)
  (add-hook 'find-file-hooks 'clearcase-hook-vxpath-find-file-hook)
  (add-hook 'dired-mode-hook 'clearcase-hook-dired-mode-hook)
  (add-hook 'dired-after-readin-hook 'clearcase-hook-dired-after-readin-hook)
  (add-hook 'kill-buffer-hook 'clearcase-hook-kill-buffer-hook)
  (add-hook 'write-file-hooks 'clearcase-hook-write-file-hook)

  ;; 2. Install file-name handlers.
  ;;
  ;;    2.1 Start views when //view/TAG or m:/TAG is referenced.
  ;;
  (if (not clearcase-on-mswindows)
      (add-to-list 'file-name-handler-alist
                   (cons clearcase-vrpath-regexp
                         'clearcase-viewroot-relative-file-name-handler)))

  ;;    2.2 Completion on viewtags.
  ;;
  (if clearcase-complete-viewtags
      (add-to-list 'file-name-handler-alist
                   (cons clearcase-viewtag-regexp
                         'clearcase-viewtag-file-name-handler)))

  ;;    2.3 Turn off RCS/VCS/SCCS activity inside a ClearCase dynamic view.
  ;;
  (if clearcase-suppress-vc-within-mvfs
      (add-to-list 'file-name-handler-alist
                   (cons ".*" 'clearcase-suppress-vc-within-mvfs-file-name-handler)))
  
  ;; 3. Install advice.
  ;;
  (if (not clearcase-on-mswindows)
      (progn
        ;;(clearcase-advise-comint-exec-1)
        ;;(clearcase-advise-gud-find-file)
        )))

(defun clearcase-unintegrate ()
  "Disable ClearCase integration"
  (interactive)

  ;; 0. Empty caches.
  ;;
  (clearcase-fprop-clear-all-properties)
  (clearcase-vprop-clear-all-properties)

  ;; 1. Remove hooks.
  ;;
  (remove-hook 'find-file-hooks 'clearcase-hook-find-file-hook)
  (remove-hook 'find-file-hooks 'clearcase-hook-vxpath-find-file-hook)
  (remove-hook 'dired-mode-hook 'clearcase-hook-dired-mode-hook)
  (remove-hook 'dired-after-readin-hook 'clearcase-hook-dired-after-readin-hook)
  (remove-hook 'kill-buffer-hook 'clearcase-hook-kill-buffer-hook)
  (remove-hook 'write-file-hooks 'clearcase-hook-write-file-hook)

  ;; 2. Remove file-name handlers.
  ;;
  (delete-if (function (lambda (entry)
                         (eq 'clearcase-viewroot-relative-file-name-handler
                             (cdr entry))))
             file-name-handler-alist)

  (delete-if (function (lambda (entry)
                         (eq 'clearcase-viewtag-file-name-handler
                             (cdr entry))))
             file-name-handler-alist)

  (delete-if (function (lambda (entry)
                         (eq 'clearcase-suppress-vc-within-mvfs-file-name-handler
                             (cdr entry))))
             file-name-handler-alist)

  ;; 3. Remove advice.
  ;;
  (if (not clearcase-on-mswindows)
      (progn
        (ad-deactivate 'comint-exec-1)
        (ad-deactivate 'gud-find-file))))

;; Here's where we really wire it all in:
;;
(if clearcase-servers-online
    (progn
      (clearcase-integrate)
      ;; Schedule a fetching of the view properties when next idle.
      ;; This avoids awkward pauses after the user reaches for the
      ;; ClearCase menubar entry.
      ;;
      (if clearcase-setview-viewtag
          (clearcase-vprop-schedule-fetch clearcase-setview-viewtag))
      )
  (message "ClearCase apparently not online. ClearCase/Emacs integration not installed."))

;;}}}

(provide 'clearcase)

;;; clearcase.el ends here

;; Local variables:
;; folded-file: t
;; clearcase-version-stamp-active: t
;; End:

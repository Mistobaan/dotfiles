;;Martin Boyer, Hydro-Quebec
;;
(defun imouse-drag-display (event)
  (interactive "e")
  (save-selected-window
    (select-window (event-window event))
    (let ((down t)
	  ;; (start-x (event-x event))
	  (start-y (event-y event))
	  ;; new-x
	  new-y)
      (message "Hold button down to drag text, release it when done.")
      (while down
	(next-event event)
	(if (or (button-press-event-p event)
		(button-release-event-p event))
	    (setq down nil))
	(dispatch-event event)
	(if (motion-event-p event)
	    (progn
	      (setq ;; new-x (event-x event)
		    new-y (event-y event))
	      (scroll-down (- new-y start-y))
	      ;; We'll have to wait until scroll-left works...
	      ;;(scroll-left (/ (- new-x start-x) 4))
	      ;;(set-window-hscroll (selected-window)
	      ;;      	      (min (max (+ (window-hscroll) 
	      ;;      			   (/ (- new-x start-x) 4)
	      ;;      			   ) 0) (window-width)))
	      ;;(message "%d" (window-hscroll))
	      (setq ;; start-x new-x
		    start-y new-y)))))))



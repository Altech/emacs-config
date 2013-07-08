(load-file "~/.emacs.d/ProofGeneral-4.2/generic/proof-site.el")


(defun turn-on-my-coq-settings ()
  (interactive)
  (iimage-mode t)
  (modi-permanently-mode t)
  (color-theme-my-xp)
  (blink-cursor-mode -1)
  (set-cursor-color "#8b4513") 
  (define-key coq-mode-map (kbd "\'") 'self-insert-command)
  (define-key coq-mode-map (kbd "M-l M-d") 'altech:git-gutter:popup-hunk)
  (define-key coq-mode-map (kbd "C-c C-s c") 'altech:rinkou-emp-region)
  (define-key coq-mode-map (kbd "C-c C-s u") 'altech:rinkou-und-region)
  (define-key coq-mode-map (kbd "C-;") 'altech:rinkou-und-region)
  (define-key coq-mode-map (kbd "C-'") 'altech:rinkou-emp-region)
  (define-key coq-mode-map (kbd "C-.") 'altech:rinkou-remove-modification)
  (define-key coq-mode-map (kbd "C-c C-s r") 'altech:rinkou-remove-modification)
  (define-key coq-mode-map (kbd "M-d") 'look-up-current-word-in-dictionary-app)
  (define-key coq-mode-map (kbd "C-l") (lambda ()
					(interactive)
					(recenter 0)))
  (define-key coq-mode-map (kbd "C-M-f") 'super-coq:proof-next)
  (define-key coq-mode-map (kbd "C-M-g") 'proof-assert-next-command-interactive)
  (define-key coq-mode-map (kbd "C-M-j") 'proof-undo-last-successful-command))


(defadvice proof-assert-next-command-interactive (after back-one-char)
  (goto-char (1- (point))))


(defun super-coq:parse-goals (s)
 (super-coq:bundle-premises
  (super-coq:cleansing
   (mapcar
    (lambda (l) (cond
		 ((string-match "\\([0-9]+\\) subgoals" l) (cons 'nsubgoals (match-string 1 l)))
		 ((string-match "(ID \\([0-9]+\\))" l) (cons 'id (match-string 1 l)))
		 ((string-match "^  \\([^ ].*?\\) : \\(.+\\)" l) (cons 'premise (cons (match-string 1 l) (match-string 2 l))))
		 ((string-match "===============" l) 'induction-line)
		 ((string-match "^   \\(.+\\)" l) (cons 'maybe-goal (match-string 1 l)))
		 (t nil)))
    (split-string s "\n"))))) ; => super-coq:parse-goals

(defun super-coq:cleansing (ls)
  (if (null ls)
      nil
    (let ((d (car ls)))
      (if (null d)
	  (super-coq:cleansing (cdr ls))
	(if (consp d)
	    (cons d (super-coq:cleansing (cdr ls)))
	  (if (eq d 'induction-line)
	      (cons (cons 'goal (cdadr ls)) (remove-if (lambda (e) (null e)) (cddr ls)))
	    ))))))

(defun super-coq:bundle-premises (ls)
  (if (null ls)
      nil
    (if (and (consp (car ls)) (eq (caar ls) 'premise))
	(let ((bundled (super-coq:bundle-premises-main ls)))
	  (cons (cons 'premises (super-coq:init bundled)) (super-coq:last bundled)))
      (cons (car ls) (super-coq:bundle-premises (cdr ls))))))

(defun super-coq:bundle-premises-main (ls)
  (if (and (not (null ls)) (consp (car ls)) (eq (caar ls) 'premise))
      (cons (cdar ls) (super-coq:bundle-premises-main (cdr ls)))
    (cons ls nil)))

(defun super-coq:ids (ls)
  (if (null ls)
      nil
    (if (consp (car ls))
	(if (eq 'id (caar ls))
	    (cons (cdar ls) (super-coq:ids (cdr ls)))
	  (super-coq:ids (cdr ls))))))

(defun super-coq:init (ls)
  (if (null (cddr ls))
      (cons (car ls) nil)
    (cons (car ls) (super-coq:init (cdr ls)))))

(defun super-coq:last (ls)
  (if (null (cdr ls))
      (car ls)
    (super-coq:last (cdr ls))))

(defun super-coq:proof-next ()
  (interactive)
  (super-coq:remove-info)
  (let* ((before-goals (super-coq:parse-goals (with-current-buffer (get-buffer "*goals*") (buffer-string)))))
    (proof-assert-next-command-interactive)
    (sleep-for 0.15)
    (let* ((after-goals (super-coq:parse-goals (with-current-buffer (get-buffer "*goals*") (buffer-string)))))
      (if (not (equal (cdr (assq 'nsubgoals before-goals)) (cdr (assq 'nsubgoals after-goals))))
	  ;; show number of subgoals if changed
	  (super-coq:add-faces-to-goals "^\\([0-9]+\\)"
	    (overlay-put (make-overlay (match-beginning 1) (match-end 1)) 'face 'underline)
	    (super-coq:add-before-info (concat " (" (cdr (assq 'nsubgoals before-goals)) ")")))
	;; emphasize new premises, mark rewrited premises
	(let ((before-premises (cdr (assq 'premises before-goals)))
	      (after-premises  (cdr (assq 'premises after-goals))))
	  (mapc (lambda (premise)
		  (let ((before-premise (assoc (car premise) before-premises)))
		    (if (not before-premise)
			(super-coq:add-faces-to-goals (concat "^ *\\(" (car premise) "\\) : \\(.+\\)")
			  (dolist (i '(1 2))
			    (overlay-put (make-overlay (match-beginning i) (match-end i)) 'face 'bold)))
		      (if (not (equal (cdr premise) (cdr before-premise)))
			  (super-coq:add-faces-to-goals (concat "^ *\\(" (car premise) "\\) : \\(.+\\)")
			    (overlay-put (make-overlay (match-beginning 2) (match-end 2)) 'face 'underline)
			    (goto-char (match-end 2))
			    (super-coq:add-before-info (concat " (" (cdr before-premise)  ")")))))))
		after-premises))
	;; show before goal term if changed
	(let ((before-goal (cdr (assq 'goal before-goals)))
	      (after-goal  (cdr (assq 'goal after-goals))))
	  (if (not (equal before-goal after-goal))
	      (super-coq:add-faces-to-goals "==============\n   \\(.+\\)"
		(goto-char (match-beginning 1))
		(super-coq:add-before-info (concat before-goal "\n-> "))))))
      ;; emphasize new subgoal
      (let ((before-ids (super-coq:ids before-goals)) (after-ids (super-coq:ids after-goals)))
	(super-coq:add-faces-to-goals "subgoal [0-9]+ (ID [0-9]+)$"
	  (overlay-put (make-overlay (match-beginning 0) (match-end 0)) 'face 'bold))
	(mapc (lambda (id)
		(unless (member id before-ids)
		  (super-coq:add-faces-to-goals (concat "^.*(ID " id ").*:$")
		    (overlay-put (make-overlay (match-beginning 0) (match-end 0)) 'face 'bold))))
	      after-ids)))))

(defun super-coq:add-before-info (info)
  (let* ((s (concat ">>>" info "<<<")) (p1 (point)) (p2 (+ p1 (length s))))
    (insert s)
    (overlay-put (make-overlay p1 p2) 'face '(:foreground "gray49"))
    (save-restriction
      (narrow-to-region p1 p2)
      (beginning-of-buffer)
      (while (re-search-forward "\\(>>>\\)\\(.\\|\n\\)+?\\(<<<\\)" nil t)
	(let ((o1 (make-overlay (match-beginning 1) (match-end 1))) (o3 (make-overlay (match-beginning 3) (match-end 3))))
	  (dolist (i '(1 3))
	    (let ((o (make-overlay (match-beginning i) (match-end i))))
	      (overlay-put o 'category 'coq-improver)
	      (overlay-put o 'invisible t))))))))

(defun super-coq:remove-info ()
  (with-current-buffer (get-buffer "*goals*")
    (setq buffer-read-only nil)
    (let ((s (point-min)) (e (point-max)))
      (save-restriction
	(narrow-to-region s e)
	(remove-overlays s e 'category 'coq-improver)
	(beginning-of-buffer)
	(while (re-search-forward ">>>\\(.\\|\n\\)+?<<<" nil t)
	  (replace-match ""))))
    (setq buffer-read-only t)))

(defmacro super-coq:add-faces-to-goals (regexp &rest body)
  (declare (indent 1))
  `(with-current-buffer (get-buffer "*goals*")
     (setq buffer-read-only nil)
     (save-excursion
       (beginning-of-buffer)
       (while (re-search-forward ,regexp nil t)
	 ,@body))
     (setq buffer-read-only t)))

;; (super-coq:remove-info)
;; (defvar sample-goals (with-current-buffer (get-buffer "*goals*") (buffer-string)))
;; (super-coq:parse-goals sample-goals) ; => 

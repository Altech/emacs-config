(load-file "~/.emacs.d/ProofGeneral-4.2/generic/proof-site.el")


(defun turn-on-my-coq-settings ()
  (interactive)
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
					(recenter 0))))

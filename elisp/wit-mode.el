
(defcustom wit-command-name 
  "bash -l -c 'source $HOME/.rvm/scripts/rvm && rvm use 2.0.0 > /dev/null && ruby -I~/work/wit/lib ~/work/wit/bin/wit.rb %s'"
  "Executable path for WIT script")

;; http://www.emacswiki.org/emacs/ElispCookbook
(defun wip-chomp (str)
  "Chomp leading and tailing whitespace from STR."
  (while (string-match "\\`\n+\\|^\\s-+\\|\\s-+$\\|\n+\\'" str)
    (setq str (replace-match "" t t str)))
  str)

(setq wit-timeline-hash (make-hash-table :test 'equal))

(defun wit-cache-timeline (prev-name next-name)
  (progn
    (puthash (list 'prev next-name) prev-name wit-timeline-hash)
    (puthash (list 'next prev-name) next-name wit-timeline-hash)))

(defun wit-cache-timeline-lookup (type name)
  (gethash (list type name) wit-timeline-hash))

(defun wit-command (arg-str)
  (let ((command-str (format wit-command-name arg-str)))
    (wip-chomp (shell-command-to-string command-str))))

(defun wit-command-and-open (arg-str)
  (let ((filename (wit-command arg-str)))
    (find-file filename)
    filename))

(defun wit-open-fresh (&optional title)
  (interactive "MNew Note:")
  (wit-command-and-open (format "fresh --boilerplate \"%s\"" (or title "index"))))

(defun wit-open-latest ()
  (interactive)
  (wit-command-and-open "latest"))

(defun wit-open-next ()
  (interactive)
  (let* ((current-name (buffer-file-name))
	 (cached-name (wit-cache-timeline-lookup 'next current-name))
	 (next-name (or cached-name (wit-command (format "next %s" current-name)))))
    (if (string= "" next-name)
	(progn (ding)
	       (message "No more notes."))
      (progn
	(wit-cache-timeline current-name next-name)
	(find-file next-name)))))

(defun wit-open-prev ()
  (interactive)
  (let* ((current-name (buffer-file-name))
	 (cached-name (wit-cache-timeline-lookup 'prev current-name))
	 (prev-name (or cached-name (wit-command (format "prev %s" current-name)))))
    (if (string= "" prev-name)
	(progn (ding)
	       (message "No more notes."))
      (progn
	(wit-cache-timeline prev-name current-name)
	(find-file prev-name)))))

(defun wit-kill-cache ()
  (interactive)
  (clrhash wit-timeline-hash))

(defvar wit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [?\M-P] 'wit-open-prev)
    (define-key map [?\M-N] 'wit-open-next)
    map)
  "Minor mode keymap for WIP mode for the whole buffer.")

;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Defining-Minor-Modes.html
(define-minor-mode wit-mode
  "Toggle WIT mode"
  :init-value nil
  :lighter " WIT"
  :keymap wit-mode-map)

(defun wit-setup ()
  (interactive)
  ;; http://www.emacswiki.org/emacs/AutoModeAlist
  (add-to-list 'auto-mode-alist '("/t/.*\\.md\\'" . wit-mode))
  (global-set-key [?\C-c ?w ?f] `wit-open-fresh)
  (global-set-key [?\C-c ?w ?l] `wit-open-latest))
(wit-setup)

(provide 'wit-mode)

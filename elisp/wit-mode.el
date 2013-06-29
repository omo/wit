
(defcustom wit-command-name 
  "bash -l -c 'source $HOME/.rvm/scripts/rvm && rvm use 2.0.0 > /dev/null && ruby -I~/work/wit/lib ~/work/wit/bin/wit.rb %s'"
  "Executable path for WIT script")

;; http://www.emacswiki.org/emacs/ElispCookbook
(defun wip-chomp (str)
  "Chomp leading and tailing whitespace from STR."
  (while (string-match "\\`\n+\\|^\\s-+\\|\\s-+$\\|\n+\\'" str)
    (setq str (replace-match "" t t str)))
  str)

(defun wit-command (arg-str)
  (let ((command-str (format wit-command-name arg-str)))
    (shell-command-to-string command-str)))

(defun wit-command-and-open (arg-str)
  (let ((filename (wip-chomp (wit-command arg-str))))
    (find-file filename)))

(defun wit-open-fresh (&optional title)
  (interactive "MNew Note:")
  (wit-command-and-open (format "fresh \"%s\"" title)))

(defun wit-open-latest ()
  (interactive)
  (wit-command-and-open "latest"))

(defun wit-open-next ()
  (interactive)
  (wit-command-and-open (format "next %s" (buffer-file-name))))

(defun wit-open-prev ()
  (interactive)
  (wit-command-and-open (format "prev %s" (buffer-file-name))))

(defvar wit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [?\M-P] 'wit-open-prev)
    (define-key map [?\M-N] 'wit-open-next)
    map)
  "Minor mode keymap for WIP mode for the whole buffer.")

(defun wit-setup ()
  (interactive)
  ;; http://www.emacswiki.org/emacs/AutoModeAlist
  (add-to-list 'auto-mode-alist '("/t/.*\\.md\\'" . wit-mode))
  (global-set-key [?\C-c ?w ?f] `wit-open-fresh)
  (global-set-key [?\C-c ?w ?l] `wit-open-latest))

;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Defining-Minor-Modes.html
(define-minor-mode wit-mode
  "Toggle WIT mode"
  :init-value nil
  :lighter " WIT"
  :keymap wit-mode-map)


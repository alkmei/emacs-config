;;; org-config.el -*- lexical-binding: t; -*-

;; Org-mode and Org-roam directory paths
(setq org-directory "~/org/"
      org-roam-directory (expand-file-name "roam" org-directory))

(after! org
  (setq org-startup-indented t
        org-startup-with-inline-images t
        org-image-actual-width '(600)
        org-agenda-files (list org-directory))

  ;; Center-padded readable view
  (add-hook! 'org-mode-hook
    (defun +org-setup-presentation-h ()
      (display-line-numbers-mode -1)
      (visual-line-mode 1)
      (variable-pitch-mode 1)
      (olivetti-mode 1))))

;; org-modern configuration (enabled via (org +pretty) in init.el)
(after! org-modern
  (setq org-modern-star '("◉" "○" "◈" "◇" "✳")
        org-modern-table-vertical 1
        org-modern-table-horizontal 0.2))

;; Live-preview style toggle for markup & links (included with :lang (org +pretty))
(after! org-appear
  (setq org-appear-autoemphasis t
        org-appear-autolinks t
        org-appear-autosubmarkers t
        org-appear-autoentities t))

;; Org Roam configuration
(after! org-roam
  (setq org-roam-completion-everywhere t)
  ;; Default capture template
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+created: %U\n#+last_modified: %U\n\n")
           :unnarrowed t))))

;; Obsidian-style 3D Graph visualization in the browser
(use-package! org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start nil))

;; Keybindings for non-evil users (C-c n prefix for quick note taking & Roam)
(map! :leader
      (:prefix ("n" . "notes")
       :desc "Find Roam node"        "f" #'org-roam-node-find
       :desc "Insert Roam node"      "i" #'org-roam-node-insert
       :desc "Toggle Roam buffer"    "r" #'org-roam-buffer-toggle
       :desc "Toggle Roam Graph UI"  "g" #'org-roam-ui-open
       :desc "Capture note"          "c" #'org-roam-capture
       :desc "Sync Roam database"    "s" #'org-roam-db-sync
       (:prefix ("d" . "dailies")
        :desc "Today's daily note"   "t" #'org-roam-dailies-goto-today
        :desc "Capture today's note" "n" #'org-roam-dailies-capture-today
        :desc "Goto date"            "d" #'org-roam-dailies-goto-date
        :desc "Goto yesterday"       "y" #'org-roam-dailies-goto-yesterday
        :desc "Goto tomorrow"        "m" #'org-roam-dailies-goto-tomorrow)))

;; Global convenient non-evil keybindings (Obsidian muscle memory)
(map! "C-c n f" #'org-roam-node-find
      "C-c n i" #'org-roam-node-insert
      "C-c n r" #'org-roam-buffer-toggle
      "C-c n g" #'org-roam-ui-open
      "C-c n t" #'org-roam-dailies-goto-today)

;;; ====================================================================
;;; Automatic Git Sync for Org files in `org` directories
;;; ====================================================================

(defvar my-org-git-sync-in-progress nil
  "Non-nil if git sync is currently running for an org repository.")

(defvar my-org-git-sync-timer nil
  "Debounce timer for post-save git sync.")

(defcustom my-org-git-sync-debounce-delay 3.0
  "Seconds to wait after a save before initiating git sync."
  :type 'number
  :group 'org)

(defun my-org-git-sync--in-org-folder-p (dir)
  "Return non-nil if DIR is named `org' or is inside a directory named `org'."
  (let ((truename (file-name-as-directory (file-truename dir))))
    (string-match-p "/org\\(/\\|$\\)" truename)))

(defun my-org-git-sync-repo-root (&optional file-or-dir)
  "Return git repository root if FILE-OR-DIR is inside an `org' folder and in a git repo."
  (let ((target (or file-or-dir (buffer-file-name) default-directory)))
    (when target
      (let ((dir (file-name-as-directory (if (file-directory-p target)
                                             (file-truename target)
                                           (file-name-directory (file-truename target))))))
        (when (my-org-git-sync--in-org-folder-p dir)
          (locate-dominating-file dir ".git"))))))

(defun my-org-git-sync-run (repo-root &optional push-p)
  "Perform asynchronous git pull (rebase) and optional commit & push in REPO-ROOT."
  (when (and repo-root (not my-org-git-sync-in-progress))
    (setq my-org-git-sync-in-progress t)
    (let* ((default-directory (file-name-as-directory repo-root))
           (commit-msg (format "Auto-sync: %s" (format-time-string "%Y-%m-%d %H:%M:%S")))
           (cmd (if push-p
                    (format "git pull --rebase --autostash origin $(git rev-parse --abbrev-ref HEAD) && \
git add -A && \
(git diff --cached --quiet || git commit -m %s) && \
git push origin $(git rev-parse --abbrev-ref HEAD)"
                            (shell-quote-argument commit-msg))
                  "git pull --rebase --autostash origin $(git rev-parse --abbrev-ref HEAD)")))
      (message "Org Git Sync: synchronizing %s..." repo-root)
      (make-process
       :name "org-git-sync"
       :buffer "*org-git-sync*"
       :command (list shell-file-name shell-command-switch cmd)
       :sentinel
       (lambda (proc status)
         (setq my-org-git-sync-in-progress nil)
         (if (string-match-p "finished" status)
             (message "Org Git Sync: completed for %s" repo-root)
           (message "Org Git Sync: failed (%s) - check *org-git-sync* buffer"
                    (string-trim status))))))))

(defun my-org-git-sync-on-save ()
  "Trigger debounced git commit and push if the saved org buffer is in an org git repo."
  (when (and (derived-mode-p 'org-mode)
             buffer-file-name)
    (when-let ((repo (my-org-git-sync-repo-root buffer-file-name)))
      (when (timerp my-org-git-sync-timer)
        (cancel-timer my-org-git-sync-timer))
      (setq my-org-git-sync-timer
            (run-with-timer
             my-org-git-sync-debounce-delay nil
             (lambda (root)
               (my-org-git-sync-run root t))
             repo)))))

(defun my-org-git-sync-on-open ()
  "Trigger background git pull when opening an org file in an org git repo."
  (when (and (derived-mode-p 'org-mode)
             buffer-file-name)
    (when-let ((repo (my-org-git-sync-repo-root buffer-file-name)))
      (run-with-idle-timer 0.5 nil
                           (lambda (root)
                             (my-org-git-sync-run root nil))
                           repo))))

(defun my-org-git-sync-now ()
  "Manually trigger an org git sync for the current buffer's repository."
  (interactive)
  (if-let ((repo (my-org-git-sync-repo-root)))
      (my-org-git-sync-run repo t)
    (user-error "Current buffer is not in an org git repository")))

;; Attach hooks for automatic synchronization
(add-hook 'after-save-hook #'my-org-git-sync-on-save)
(add-hook 'org-mode-hook #'my-org-git-sync-on-open)

;; Keybinding for manual on-demand sync under notes prefix
(map! :leader
      (:prefix ("n" . "notes")
       :desc "Sync Org Git repo" "S" #'my-org-git-sync-now))


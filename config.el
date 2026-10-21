;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-monokai-pro)
(setq doom-font (font-spec :family "Iosevka" :size 16))
(setq doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size 16))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

(use-package! olivetti
  :hook ((fountain-mode) . olivetti-mode) ; Automatically turn on Olivetti in Org files
  :config
  (setq olivetti-body-width 80
        olivetti-style 'fancy))

(add-hook 'fountain-mode-hook (lambda () (adaptive-wrap-prefix-mode -1)))
(add-hook 'fountain-mode-hook
          (lambda ()
            (face-remap-add-relative 'default :family "Courier Prime" :height 1.0)))

(setq writeroom-width 60)

(add-hook 'writeroom-mode-hook
          (lambda ()
            (if writeroom-mode
                (setq buffer-face-mode-face '(:family "Iosevka Etoile"))
              (buffer-face-mode 1))
            (buffer-face-mode (if writeroom-mode 1 -1))))

(defun wslp ()
  "Return t if Emacs is running in WSL2, nil otherwise."
  (and
   ;; Check if the system is Linux
   (eq system-type 'gnu/linux)
   ;; Check for WSL-specific file
   (file-exists-p "/proc/sys/fs/binfmt_misc/WSLInterop")
   ;; Check for WSL2-specific file
   (file-exists-p "/run/WSL")
   ;; Additional check: look for Windows-style root directory
   (file-directory-p "/mnt/c")))

(when (wslp)
                                        ; WSLg breaks copy-paste from Emacs into Windows
                                        ; see: https://www.lukas-barth.net/blog/emacs-wsl-copy-clipboard/
  (setq select-active-regions nil
        select-enable-clipboard 't
        select-enable-primary nil
        interprogram-cut-function #'gui-select-text))

;;; Obsidian-like Org-Mode Configuration
(setq org-directory "~/org/"
      org-roam-directory (expand-file-name "roam" org-directory))

(after! org
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-startup-indented t
        org-startup-with-inline-images t
        org-image-actual-width '(600)
        ;; Don't display line numbers in org buffers for cleaner reading experience
        org-agenda-files (list org-directory))

  ;; Center-padded readable view like Obsidian
  (add-hook! 'org-mode-hook
    (defun +org-obsidian-setup-h ()
      (display-line-numbers-mode -1)
      (visual-line-mode 1)
      (variable-pitch-mode 1)
      (olivetti-mode 1)))

  ;; Custom font sizing for headings (clean visual hierarchy)
  (custom-set-faces!
    '(org-document-title :height 1.4 :weight bold)
    '(org-level-1 :height 1.25 :weight bold)
    '(org-level-2 :height 1.15 :weight semi-bold)
    '(org-level-3 :height 1.05 :weight semi-bold)
    '(org-level-4 :height 1.0  :weight semi-bold)
    '(org-block :inherit fixed-pitch)
    '(org-code :inherit fixed-pitch)
    '(org-table :inherit fixed-pitch)
    '(org-verbatim :inherit fixed-pitch)
    '(org-formula :inherit fixed-pitch)
    '(org-special-keyword :inherit fixed-pitch)
    '(org-meta-line :inherit fixed-pitch)
    '(org-checkbox :inherit fixed-pitch)
    '(line-number :inherit fixed-pitch)
    '(line-number-current-line :inherit fixed-pitch)))

;; Live-preview style toggle for markup & links (Obsidian Live Preview)
(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
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


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

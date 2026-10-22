;;; js-config.el -*- lexical-binding: t; -*-

;; Ensure tree-sitter grammars are discovered
(dolist (dir (list (expand-file-name "~/.config/emacs/tree-sitter")
                   (expand-file-name "~/.config/emacs/.local/etc/tree-sitter")
                   (expand-file-name "~/.emacs.d/tree-sitter")))
  (add-to-list 'treesit-extra-load-path dir))

;; Associate file extensions with Tree-sitter major modes
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.[mc]?ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.[mc]?js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.json[c]?\\'" . json-ts-mode))
;; Next.js & Tailwind configuration files
(add-to-list 'auto-mode-alist '("/next\\.config\\.[mc]?[jt]s\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("/tailwind\\.config\\.[mc]?[jt]s\\'" . tsx-ts-mode))
;; Environment variable files (.env, .env.local, .env.development, etc.)
(add-to-list 'auto-mode-alist '("\\.env\\(?:\\..*\\)?\\'" . conf-mode))

;; Standard indentation (2 spaces for modern web/react stacks)
(setq-default js-indent-level 2
              typescript-ts-mode-indent-offset 2
              css-indent-offset 2
              json-ts-mode-indent-offset 2)

;; Eglot LSP configuration
(after! eglot
  ;; Ensure typescript-language-server is used for tsx, typescript, and javascript
  (add-to-list 'eglot-server-programs
               '(((js-mode :language-id "javascript")
                  (js-ts-mode :language-id "javascript")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-ts-mode :language-id "typescript")
                  (typescript-mode :language-id "typescript"))
                 "typescript-language-server" "--stdio"))

  ;; Rich TypeScript/JavaScript workspace preferences
  (setq-default eglot-workspace-configuration
                '(:typescript
                  (:inlayHints
                   (:parameterNames (:enabled "all")
                    :parameterTypes (:enabled t)
                    :variableTypes (:enabled t)
                    :propertyDeclarationTypes (:enabled t)
                    :functionLikeReturnTypes (:enabled t)
                    :enumMemberValues (:enabled t))
                   :preferences
                   (:includeInlayParameterNameHints "all"
                    :includeInlayParameterNameHintsWhenArgumentMatchesName t
                    :includeInlayFunctionParameterTypeHints t
                    :includeInlayVariableTypeHints t
                    :includeInlayPropertyDeclarationTypeHints t
                    :includeInlayFunctionLikeReturnTypeHints t
                    :includeInlayEnumMemberValueHints t
                    :importModuleSpecifierPreference "non-relative"))
                  :javascript
                  (:inlayHints
                   (:parameterNames (:enabled "all")
                    :parameterTypes (:enabled t)
                    :variableTypes (:enabled t)
                    :propertyDeclarationTypes (:enabled t)
                    :functionLikeReturnTypes (:enabled t)
                    :enumMemberValues (:enabled t)))))

  ;; Enable inlay hints in TypeScript / TSX buffers
  (add-hook! '(typescript-ts-mode-hook tsx-ts-mode-hook)
    (defun +ts-enable-inlay-hints-h ()
      (when (fboundp 'eglot-inlay-hints-mode)
        (eglot-inlay-hints-mode +1)))))

;; Bridge Eglot diagnostics to Flycheck
(after! (flycheck eglot)
  (require 'flycheck-eglot nil t)
  (when (fboundp 'global-flycheck-eglot-mode)
    (global-flycheck-eglot-mode 1)))

;; Next.js / React / TSX Editing Enhancements
(after! emmet-mode
  ;; Enable JSX className expansion in TSX and JS buffers (e.g. .btn -> className="btn")
  (dolist (mode '(tsx-ts-mode js-ts-mode typescript-ts-mode))
    (add-to-list 'emmet-jsx-major-modes mode)))

(add-hook! '(tsx-ts-mode-hook js-ts-mode-hook)
  (defun +react-tsx-setup-h ()
    ;; Enable emmet for quick HTML/JSX expansion (C-j or M-x emmet-expand-line)
    (emmet-mode +1)))

;; Electric JSX auto-close tag helper on typing `</`
(defun +javascript-jsx-close-tag ()
  "Auto-close the innermost unclosed JSX/HTML tag on typing `</`."
  (interactive)
  (insert "/")
  (when (looking-back "<\\s-*/" 3)
    (let ((tag nil)
          (depth 0))
      (save-excursion
        (backward-char 2)
        (while (and (not tag)
                    (re-search-backward "<\\(/?\\)\\([a-zA-Z0-9_.:-]+\\)\\([^>]*\\)>" nil t))
          (let ((is-closing (string= (match-string 1) "/"))
                (tag-name (match-string 2))
                (tag-body (match-string 3)))
            (unless (string-suffix-p "/" (string-trim-right tag-body))
              (if is-closing
                  (cl-incf depth)
                (if (> depth 0)
                    (cl-decf depth)
                  (setq tag tag-name)))))))
      (when tag
        (insert (concat tag ">"))))))

(after! typescript-ts-mode
  (define-key tsx-ts-mode-map (kbd "/") #'+javascript-jsx-close-tag))

;; Convenient helper to organize imports using Eglot
(defun +javascript-organize-imports ()
  "Organize imports in the current buffer using Eglot."
  (interactive)
  (eglot-code-actions nil nil "source.organizeImports" t))

;; Helpful code action & refactoring keybindings for non-evil users
(map! :after eglot
      :map eglot-mode-map
      "C-c c a" #'eglot-code-actions
      "C-c c r" #'eglot-rename
      "C-c c f" #'+format/buffer
      "C-c c o" #'+javascript-organize-imports
      "C-c c i" #'eglot-inlay-hints-mode)

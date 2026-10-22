;;; terraform-config.el -*- lexical-binding: t; -*-

;; Associate additional Terraform and HCL files
(add-to-list 'auto-mode-alist '("\\.tf\\(vars\\)?\\'" . terraform-mode))
(add-to-list 'auto-mode-alist '("\\.tofu\\(vars\\)?\\'" . terraform-mode))
(add-to-list 'auto-mode-alist '("\\.tflint\\.hcl\\'" . terraform-mode))

;; Configure Terraform formatting with Apheleia (format on save via :editor (format +onsave))
(after! apheleia
  (setf (alist-get 'terraform apheleia-formatters)
        '("terraform" "fmt" "-"))
  (setf (alist-get 'terraform-mode apheleia-mode-alist)
        'terraform))

;; Configure Eglot for Terraform
(after! eglot
  ;; Ensure terraform-ls is recognized by eglot for terraform-mode
  (add-to-list 'eglot-server-programs
               '((terraform-mode :language-id "terraform")
                 "terraform-ls" "serve"))

  ;; Terraform language server settings
  (setq-default eglot-workspace-configuration
                (plist-put (copy-sequence (default-value 'eglot-workspace-configuration))
                           :terraform
                           '(:experimentalFeatures
                             (:prefillRequiredFields t
                              :validateOnSave t)))))

;; Terraform configuration and IDE enhancements
(after! terraform-mode
  ;; Set indentation to 2 spaces
  (setq-default terraform-indent-level 2)

  ;; Configure Flycheck checkers: chain syntax check with tflint
  (after! flycheck
    (when (executable-find "tflint")
      (flycheck-add-next-checker 'terraform '(warning . terraform-tflint))))

  ;; Keybindings for both non-Evil and Evil/Leader workflows
  (map! :map terraform-mode-map
        ;; Non-evil bindings (C-c t prefix for terraform tools)
        "C-c t i" (cmd! (compile "terraform init"))
        "C-c t p" (cmd! (compile "terraform plan"))
        "C-c t a" (cmd! (compile "terraform apply"))
        "C-c t v" (cmd! (compile "terraform validate"))
        "C-c t f" #'+format/buffer
        "C-c t d" (cmd! (compile "terraform destroy"))
        "C-c t l" (cmd! (compile "tflint"))

        ;; Local leader / leader bindings
        :localleader
        :desc "terraform init"     "i" (cmd! (compile "terraform init"))
        :desc "terraform plan"     "p" (cmd! (compile "terraform plan"))
        :desc "terraform apply"    "a" (cmd! (compile "terraform apply"))
        :desc "terraform validate" "v" (cmd! (compile "terraform validate"))
        :desc "format buffer"      "f" #'+format/buffer
        :desc "terraform destroy"  "d" (cmd! (compile "terraform destroy"))
        :desc "tflint"             "l" (cmd! (compile "tflint"))))

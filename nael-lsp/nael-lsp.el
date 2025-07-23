;;; nael-lsp.el --- lsp-mode for Nael  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Mekeor Melire

;; This file is NOT part of GNU Emacs.

;; This code is effectively licensed under GNU General Public License
;; version 3, see LICENSE.GPL3.  To be more precise, it's forked from
;; code that has been licensed under Apache-2.0, see LICENSE.APACHE2.

;;; Commentary:

;; This file configures lsp-mode to work with Nael.

;;; Code:

(require 'lsp-mode)

(require 'nael)

(defgroup nael-lsp nil
  "lsp-mode configured to work with Nael."
  :group 'nael
  :group 'lsp
  :prefix "nael-lsp-")

(add-to-list 'lsp-language-id-configuration
             '(nael-mode . "nael"))

(lsp-register-client
 (make-lsp-client
  :language-id "nael"
  :major-modes '(nael-mode)
  :new-connection (lsp-stdio-connection '("lake" "serve"))
  :semantic-tokens-faces-overrides '(:types (("leanSorryLike" . font-lock-warning-face)))
  :server-id 'nael))

(lsp-interface
 (nael:Goal (:goals :rendered) nil)
 (nael:TermGoal (:goal :range) nil))

(defun nael-lsp-eldoc-goal (cb &rest _)
  "`PlainGoal' for `eldoc-documentation-functions'.

CB is the callback provided to members of ElDoc documentation
functions.

https://leanprover-community.github.io/mathlib4_docs/Lean/Data/Lsp/\
Extra.html#Lean.Lsp.PlainGoal"
  (lsp-request-async
   "$/lean/plainGoal"
   (lsp--text-document-position-params)
   (-lambda ((&nael:Goal :goals))
     (apply
      cb
      (if-let*
          (goals
           ((not (seq-empty-p goals)))
           (first-goal (seq-first goals))
           (first-goal (nael-eglot-eldoc-fontify first-goal)))
          (list (concat
                 ;; Propertize the first newline so that a potential
                 ;; t-valued `:extend' face-attribute works correctly.
                 (propertize "Tactic state:\n"
                             'face 'nael-eglot-eldoc-header)
                 "\n"
                 ;; Re-use the previously rendered documentation of
                 ;; the first goal rather than rendering it again.
                 (replace-regexp-in-string "^" "  " first-goal)
                 (seq-mapcat
                  (lambda (goal)
                    (concat "\n\n" (replace-regexp-in-string
                                    "^" "  "
                                    (nael-eglot-eldoc-fontify goal))))
                  (seq-drop goals 1) 'string)
                 "\n")
                :echo first-goal)
        (list nil))))
   :error-handler #'ignore
   :mode 'tick))

(defun nael-lsp-eldoc-term-goal (cb &rest _)
  "`PlainTermGoal' for `eldoc-documentation-functions'."
  (lsp-request-async
   "$/lean/plainTermGoal"
   (lsp--text-document-position-params)
   ;; TODO: Use Dash's `-lambda' instead.
   (-lambda ((&nael:TermGoal :goal))
     (apply
      cb
      (if-let*
          (goal
           ((not (string= "" goal)))
           (doc (eglot--format-markup goal)))
          (list (concat
                 ;; Propertize the first newline so that a potential
                 ;; t-valued `:extend' face-attribute works correctly.
                 (propertize "Expected type:\n"
                             'face 'nael-eglot-eldoc-header)
                 "\n"
                 (replace-regexp-in-string "^" "  " doc)
                 "\n")
                ;; Don't echo any docstring at all.
                :echo 'skip)
        (list nil))))
   :error-handler #'ignore
   :mode 'tick))

(defun nael-lsp-managed ()
  "Buffer-locally set up ElDoc and lsp-mode for Nael.

Use ElDoc documentation strategy `compose' and add ElDoc documentation
functions for proof goal."
  (interactive)
  (setq-local eldoc-documentation-strategy
              #'eldoc-documentation-compose)
  (add-hook 'eldoc-documentation-functions
            #'nael-lsp-eldoc-goal -90 'local)
  (add-hook 'eldoc-documentation-functions
            #'nael-lsp-eldoc-term-goal -80 'local))

(defun nael-lsp-setup ()
  "Configure `lsp-mode' to work with `nael-mode'."
  (add-hook 'lsp-managed-mode-hook
            #'nael-lsp-managed nil 'local))

(add-hook 'nael-mode-hook
          #'nael-lsp-setup)

(provide 'nael-lsp)

;;; nael-lsp.el ends here

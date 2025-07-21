;;; nael-eglot.el --- Eglot for Nael  -*- lexical-binding: t; -*-

;; Copyright (C) 2014 Microsoft Corp.
;; Copyright (C) 2024 Free Software Foundation, Inc.
;; Copyright (C) 2025 Mekeor Melire

;; This file is NOT part of GNU Emacs.

;; This source code is forked from Lean4-Mode
;; <https://github.com/bustercopley/lean4-mode> which is licensed
;; under Apache-2.0 (see LICENSE.APACHE).  Additions and modifications
;; made within this fork are licensed under GNU General Public License
;; version 3 (see LICENSE.GPL).

;;; Commentary:

;; This file configures Eglot and ElDoc to work with Nael.  Not only
;; but in particular, it defines the function `nael-eglot-managed'
;; which is meant to be locally hooked onto `eglot-managed-mode-hook'
;; in Nael buffers.  When called, it teaches Eglot about some LSP
;; requests information (such as information about the proof goals at
;; point) that are special to the Lean LSP server; and it teaches
;; ElDoc how to display this information.

;;; Code:

(require 'eglot)

(require 'nael)

(defgroup nael-eglot nil
  "Eglot and ElDoc configured to work with Nael."
  :group 'nael
  :group 'eglot
  :prefix "nael-eglot-")

(defface nael-eglot-eldoc-header
  '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for section-headers of Nael-specific ElDoc documentations."
  :group 'nael-eglot)

(defcustom nael-eglot-eldoc-fontify-buffer
  "*Nael Eglot ElDoc Fontify*"
  "Name of buffer that is reused in order to fontify Nael code."
  :group 'nael-eglot)

(defun nael-eglot-eldoc-fontify (string)
  "Apply Nael font-lock rules to STRING."
  (with-current-buffer
      (get-buffer-create nael-eglot-eldoc-fontify-buffer)
    (erase-buffer)
    (insert string)
    (setq-local font-lock-defaults nael-font-lock-defaults)
    (font-lock-ensure)
    (buffer-string)))

(defun nael-eglot-eldoc-goal (cb &rest _)
  "`PlainGoal' for `eldoc-documentation-functions'.

CB is the callback provided to members of ElDoc documentation
functions.

https://leanprover-community.github.io/mathlib4_docs/Lean/Data/Lsp/\
Extra.html#Lean.Lsp.PlainGoal"
  (jsonrpc-async-request
   (eglot--current-server-or-lose)
   :$/lean/plainGoal
   (eglot--TextDocumentPositionParams)
   :success-fn
   (lambda (response)
     (apply
      cb
      (if-let*
          ((goals (plist-get response :goals))
           ;; Since `goals' is not a list, we separately need to
           ;; ensure it's not empty.
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
        (list nil)))))
  t)

(defun nael-eglot-eldoc-term-goal (cb &rest _)
  "`PlainTermGoal' for `eldoc-documentation-functions'.

CB is the callback provided to members of ElDoc documentation
functions.

https://leanprover-community.github.io/mathlib4_docs/Lean/Data/Lsp/\
Extra.html#Lean.Lsp.PlainTermGoal"
  (jsonrpc-async-request
   (eglot--current-server-or-lose)
   :$/lean/plainTermGoal
   (eglot--TextDocumentPositionParams)
   :success-fn
   (lambda (response)
     (apply
      cb
      (if-let*
          ((goal (plist-get response :goal))
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
        (list nil)))))
  t)

(defun nael-eglot-managed ()
  "Buffer-locally set up ElDoc and Eglot for Nael.

Use ElDoc documentation strategy `compose' and add ElDoc documentation
functions for goal and term goal."
  (interactive)
  (setq-local eldoc-documentation-strategy
              #'eldoc-documentation-compose)
  (add-hook 'eldoc-documentation-functions
            #'nael-eglot-eldoc-goal -90 'local)
  (add-hook 'eldoc-documentation-functions
            #'nael-eglot-eldoc-term-goal -80 'local))

(defun nael-eglot-server-initialized (_)
  "Buffer-locally correct Eglot's expectations on Lean LSP server.

Since `lake serve' does not output anything, instruct Eglot to not wait
for any output."
  (setq-local eglot-sync-connect
              nil))

(add-to-list 'eglot-server-programs
             (list 'nael-mode "lake" "serve"))

(defun nael-eglot-setup ()
  "Configure `eglot' to work with `nael-mode'."
  (add-hook 'eglot-server-initialized-hook
            #'nael-eglot-server-initialized nil 'local)
  (add-hook 'eglot-managed-mode-hook
            #'nael-eglot-managed nil 'local))

(add-hook 'nael-mode-hook
          #'nael-eglot-setup)

(provide 'nael-eglot)

;;; nael-eglot.el ends here

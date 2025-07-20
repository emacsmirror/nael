;;; nael-eglot.el --- Eglot for Nael  -*- lexical-binding: t; -*-

;; Copyright (C) 2014 Microsoft Corp.
;; Copyright (C) 2024 Free Software Foundation, Inc.
;; Copyright (C) 2025 Mekeor Melire

;; This file is NOT part of GNU Emacs.

;; This source code is forked from `lean4-mode'
;; <https://github.com/bustercopley/lean4-mode> which is licensed
;; under Apache-2.0 (see `LICENSE.APACHE').  Additions and
;; modifications made within this fork are licensed under GNU General
;; Public License version 3 (see `LICENSE.GPL').

;;; Commentary:

;; This file configures Eglot and ElDoc to work with Nael.  Not only
;; but in particular, it defines the function
;; `nael-eglot-managed-setup' which is meant to be locally hooked onto
;; `eglot-managed-mode-hook' in Nael buffers.  When called, it teaches
;; Eglot about some LSP requests information (such as information
;; about the proof goals at point) that are special to the Lean LSP
;; server; and it teaches ElDoc how to display this information.

;;; Code:

(defgroup nael-eglot nil
  "Eglot and ElDoc configured to work with Nael."
  :group 'nael
  :group 'eglot
  :prefix "nael-eglot-")

(defface nael-eglot-eldoc-header
  '((t (:inherit font-lock-function-name-face :weight bold)))
  "Face for section-headers of Nael-specific ElDoc documentations."
  :group 'nael)

(defvar nael-eglot-eldoc-fontify-buffer-name
  "*Nael Eglot ElDoc Fontify*"
  "Name of buffer that is reused in order to fontify Nael code.")

(defun nael-eglot-eldoc-fontify (string)
  "Apply Nael font-lock rules to STRING."
  (with-current-buffer
      (get-buffer-create nael-eglot-eldoc-fontify-buffer-name)
    (erase-buffer)
    (insert string)
    (setq-local font-lock-defaults nael-font-lock-defaults)
    (font-lock-ensure)
    (buffer-string)))

(defun nael-eglot-eldoc-plain-goal (cb)
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

(defun nael-eglot-eldoc-plain-term-goal (cb)
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

(defun nael-eglot-managed-setup ()
  "Buffer-locally setup ElDoc for Nael.

Use ElDoc documentation strategy `compose' and add ElDoc documentation
functions for `plain-goal' and `plain-term-goal'."
  (interactive)
  (setq-local eldoc-documentation-strategy
              #'eldoc-documentation-compose)
  (add-hook 'eldoc-documentation-functions
            #'nael-eglot-eldoc-plain-goal -90 'local)
  (add-hook 'eldoc-documentation-functions
            #'nael-eglot-eldoc-plain-term-goal -80 'local))

;; Use "lake serve" as language-server.
(setf (alist-get 'nael-mode eglot-server-programs)
      '("lake" "serve"))

(provide 'nael-eglot)

;;; nael-eglot.el ends here

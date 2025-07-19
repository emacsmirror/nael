;;; nael-eglot.el --- Eglot for Nael  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Mekeor Melire

;; Author:
;;   Adam Topaz <topaz@ualberta.ca>
;;   Akira Komamura <akira.komamura@gmail.com>
;;   Bao Zhiyuan <bzy_sustech@foxmail.com>
;;   Daniel Selsam <daniel.selsam@protonmail.com>
;;   Gabriel Ebner <gebner@gebner.org>
;;   Henrik Böving <hargonix@gmail.com>
;;   Hongyu Ouyang <oyhy0214@163.com>
;;   Jakub Bartczuk <bartczukkuba@gmail.com>
;;   Leonardo de Moura <leonardo@microsoft.com>
;;   Mauricio Collares <mauricio@collares.org>
;;   Mekeor Melire <mekeor@posteo.de>
;;   Philip Kaludercic <philipk@posteo.net>
;;   Richard Copley <buster@buster.me.uk>
;;   Sebastian Ullrich <sebasti@nullri.ch>
;;   Siddharth Bhat <siddu.druid@gmail.com>
;;   Simon Hudon <simon.hudon@gmail.com>
;;   Soonho Kong <soonhok@cs.cmu.edu>
;;   Tomáš Skřivan <skrivantomas@seznam.cz>
;;   Wojciech Nawrocki <wjnawrocki@protonmail.com>
;;   Yael Dillies <yael.dillies@gmail.com>
;;   Yury G. Kudryashov <urkud@urkud.name>
;; Keywords: languages
;; Maintainer: Mekeor Melire <mekeor@posteo.de>
;; Package-Requires: ((emacs "29.1") (markdown-mode "2"))
;; SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-only
;; URL: https://codeberg.org/mekeor/nael
;; Version: 0.3.0

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This file defines the function `nael-eglot-managed-setup' which is
;; meant to be locally hooked onto `eglot-managed-mode-hook' in Nael
;; buffers.  When called, it teaches Eglot how to request information
;; (such as the goals at point) from a Lean LSP server; and ElDoc is
;; taught how to display this information.

;;; Code:

(defgroup nael-eglot nil
  "Configure Eglot to work with Nael."
  :group 'nael
  :group 'eglot
  :prefix "nael-eglot-")

(defface nael-eglot-eldoc-header
  '((t (:extend t :weight bold :inherit markdown-header-face-1)))
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

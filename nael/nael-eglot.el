;;; nael-eglot.el --- Eglot for Nael  -*- lexical-binding: t; -*-

;; Copyright (C) 2014 Microsoft Corp.
;; Copyright (C) 2024 Free Software Foundation, Inc.
;; Copyright (C) 2025 Mekeor Melire

;; This file is NOT part of GNU Emacs.

;; This code is effectively licensed under GNU General Public License
;; version 3, see LICENSE.GPL3.  To be more precise, it's forked from
;; code that has been licensed under Apache-2.0, see LICENSE.APACHE2.

;;; Commentary:

;; This file configures `eglot' and `eldoc' for `nael-mode'.  Not only
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
  "`eglot' and `eldoc' configured for `nael-mode'."
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

(defun nael-eglot-eldoc-goal-fn (cb get)
  "Construct ElDoc CB handler function for Lean LSP goal response with GET."
  (lambda (response)
    (apply
     cb
     (if-let*
         ((goals (funcall get response :goals))
          ((not (seq-empty-p goals)))
          (first-goal (seq-first goals))
          (first-goal (nael-eglot-eldoc-fontify first-goal)))
         (list (concat
                ;; Propertize `\n' so that `:extend' works.
                (propertize "Tactic state:\n"
                            'face 'nael-eglot-eldoc-header)
                "\n"
                ;; Avoid rendering `first-goal' twice.
                (replace-regexp-in-string "^" "  " first-goal)
                (seq-mapcat
                 (lambda (goal)
                   (concat "\n\n" (replace-regexp-in-string
                                   "^" "  "
                                   (nael-eglot-eldoc-fontify goal))))
                 (seq-drop goals 1) 'string))
               :echo first-goal)
       (list nil)))))

(defun nael-eglot-eldoc-goal (cb &rest _)
  "ElDoc documentation function for plain goal.

Callback CB is provided to any member of
`eldoc-documentation-functions'.

The request target path is `$/lean/plainGoal' as documented here:
https://leanprover-community.github.io/mathlib4_docs/Lean/Data/Lsp/\
Extra.html#Lean.Lsp.PlainGoal"
  (jsonrpc-async-request
   (eglot--current-server-or-lose)
   :$/lean/plainGoal
   (eglot--TextDocumentPositionParams)
   :success-fn (nael-eglot-eldoc-goal-fn cb #'plist-get))
  t)

(defun nael-eglot-eldoc-term-goal-fn (cb get format)
  "Construct ElDoc CB handler function for Lean LSP term-goal response.

Use callback CB, GET to access a slot of the response, and FORMAT as
function to format / render a string, possibly with markup."
  (lambda (response)
    (apply
     cb
     (if-let*
         ((goal (funcall get response :goal))
          ((not (string= "" goal)))
          (doc (funcall format goal)))
         (list (concat
                ;; Propertize `\n' so that `:extend' works.
                (propertize "Expected type:\n"
                            'face 'nael-eglot-eldoc-header)
                "\n" (replace-regexp-in-string "^" "  " doc))
               ;; Don't echo any docstring at all.
               :echo 'skip)
       (list nil)))))

(defun nael-eglot-eldoc-term-goal (cb &rest _)
  "ElDoc documentation function for plain goal.

Callback CB is provided to any member of
`eldoc-documentation-functions'.

The request target path is `$/lean/plainTermGoal' as documented here:
https://leanprover-community.github.io/mathlib4_docs/Lean/Data/Lsp/\
Extra.html#Lean.Lsp.PlainTermGoal"
  (jsonrpc-async-request
   (eglot--current-server-or-lose)
   :$/lean/plainTermGoal
   (eglot--TextDocumentPositionParams)
   :success-fn (nael-eglot-eldoc-term-goal-fn
                cb #'plist-get #'eglot--format-markup))
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

;;;###autoload
(defun nael-eglot-init ()
  "Prepare `eglot' to work with `nael-mode'."
  (interactive)
  (add-hook 'eglot-server-initialized-hook
            #'nael-eglot-server-initialized nil 'local)
  (add-hook 'eglot-managed-mode-hook
            #'nael-eglot-managed nil 'local))

(add-hook 'nael-mode-hook
          #'nael-eglot-init
          ;; Users may (add-hook 'nael-mode-hook #'eglot-ensure) which
          ;; will default to zero depth. By choosing -80 here,
          ;; `nael-eglot-init' would then be invoked prior to
          ;; `eglot-ensure'.
          -80)

(provide 'nael-eglot)

;;; nael-eglot.el ends here

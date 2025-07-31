;;; nael-lsp.el --- lsp-mode for Nael  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Mekeor Melire

;; This file is NOT part of GNU Emacs.

;; This code is effectively licensed under GNU General Public License
;; version 3, see LICENSE.GPL3.  To be more precise, it's forked from
;; code that has been licensed under Apache-2.0, see LICENSE.APACHE2.

;;; Commentary:

;; This file configures `lsp-mode' for `nael-mode'.

;;; Code:

(require 'cl-lib)

(require 'lsp-mode)

(require 'nael)

(defgroup nael-lsp nil
  "`lsp-mode' configured for `nael-mode'."
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
  :semantic-tokens-faces-overrides
  '(:types (("leanSorryLike" . font-lock-warning-face)))
  :server-id 'nael))

;; We could introduce the following interfaces so that we can use
;; destructuring features of Dash like (-lambda ((&nael:Goal :goals
;; :rendered)) (something goals rendered)) but in the context of
;; `nael-lsp-eldoc(-term)-goal', I wasn't yet able to use it like that
;; because sometimes the response will be nil and the destructuring
;; will fail.
;;
;; (lsp-interface
;;  (nael:Goal (:goals :rendered) nil)
;;  (nael:TermGoal (:goal :range) nil))

(defun nael-lsp-eldoc-goal (cb &rest _)
  "`PlainGoal' for `eldoc-documentation-functions'.

CB is the callback provided to members of ElDoc documentation
functions.

https://leanprover-community.github.io/mathlib4_docs/Lean/Data/Lsp/\
Extra.html#Lean.Lsp.PlainGoal"
  (lsp-request-async
   "$/lean/plainGoal"
   (lsp--text-document-position-params)
   (nael-eglot-eldoc-goal-fn cb #'lsp-get)
   :error-handler #'ignore
   :mode 'tick))

(defun nael-lsp-eldoc-term-goal (cb &rest _)
  "`PlainTermGoal' for `eldoc-documentation-functions'."
  (lsp-request-async
   "$/lean/plainTermGoal"
   (lsp--text-document-position-params)
   (nael-eglot-eldoc-term-goal-fn cb #'lsp-get #'lsp--render-element)
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

(add-hook 'nael-mode-hook
          #'nael-lsp-init
          ;; Users may (add-hook 'nael-mode-hook #'lsp) which will
          ;; default to zero depth. By choosing -80 here,
          ;; `nael-lsp-init' would then be invoked prior to `lsp'.
          -80)

(provide 'nael-lsp)

;;; nael-lsp.el ends here

#!/usr/bin/env -S emacs -x
;; -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Mekeor Melire

;; This file is NOT part of GNU Emacs.

;; This code is licensed under GNU General Public License version 3,
;; see LICENSE.GPL3.

;;; Commentary:

;; This file generates Emacs-Lisp files based on data from Lean4
;; plugin for VS-Code.

;;; Code:

;;;; Fetch from VS-Code

(defconst vscode-json
  (with-temp-buffer
    (url-insert-file-contents
     (concat "https://raw.githubusercontent.com"
             "/leanprover/vscode-lean4/refs/heads/master"
             "/lean4-unicode-input/src/abbreviations.json"))
    (goto-char (point-min))
    (let ((json-key-type 'string))
      (json-read))))

(defconst vscode-json-split-regexp
  (regexp-quote "$CURSOR"))

(defun vscode-json-split (pair)
  (string-match-p vscode-json-split-regexp (cdr pair)))

(defconst vscode-json-one
  (seq-remove #'vscode-json-split vscode-json))

(defconst vscode-json-two
  (mapcar (lambda (pair)
            (let ((split (string-split (cdr pair)
                                       vscode-json-split-regexp)))
              (cons (car pair)
                    (cons (car split) (cadr split)))))
          (seq-filter #'vscode-json-split vscode-json)))

;;; Generate `nael-abbrev.el'

(with-temp-file "nael/nael-abbrev.el"
  (insert ";;; nael-abbrev.el --- Abbrev for Nael  ")
  (insert "-*- lexical-binding: t; -*-")
  (insert "\n")
  (insert "\n;; Copyright (C) 2025 Mekeor Melire")
  (insert "\n")
  (insert "\n;; This file is NOT part of GNU Emacs.")
  (insert "\n")
  (insert "\n;; This code is licensed under ")
  (insert "GNU General Public License version 3,")
  (insert "\n;; see LICENSE.GPL3.")
  (insert "\n")
  (insert "\n;;; Commentary:")
  (insert "\n")
  (insert "\n;; This file provides an Abbrev table ")
  (insert "(see `local-abbrev-table' and")
  (insert "\n;; `abbrev-mode') for `nael-mode'.")
  (insert "\n")
  (insert "\n;;; Code:")
  (insert "\n")
  (insert "\n(define-abbrev-table 'nael-abbrev-table")
  (let ((max (1- (length vscode-json-one))))
    (seq-do-indexed
     (lambda (pair index)
       (insert (format "\n%s%S %S nil :system t%s"
                       (if (eq 0 index) "  '((" "    (")
                       (concat "\\" (car pair))
                       (cdr pair)
                       (if (eq max index) ")))" ")"))))
     vscode-json-one))
  (insert "\n")
  (insert "\n(provide 'nael-abbrev)")
  (insert "\n")
  (insert "\n;;; nael-abbrev.el ends here"))

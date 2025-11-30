;;; nael-markdown.el --- Nael in Markdown  -*- lexical-binding: t; -*-

;; Copyright © 2025 Mekeor Melire

;; Author: Mekeor Melire <mekeor@posteo.de>
;; Keywords: languages
;; Maintainer: Mekeor Melire <mekeor@posteo.de>
;; Package-Requires: ((emacs "29.1")
;;                    (markdown-mode "2")
;;                    (nael "0.6.2"))
;; SPDX-License-Identifier: GPL-3.0-only
;; URL: https://codeberg.org/mekeor/nael
;; Version: 0.6.1

;;; Commentary:

;; Configure `markdown-mode' to leverage `nael-mode' for `lean'
;; labeled source blocks.

;; Uhh, this is ridiculous...

;;; Code:

(require 'markdown-mode)

;;;###autoload
(add-to-list 'markdown-code-lang-modes
             (cons "lean" 'nael-mode))

(provide 'nael-markdown)

;;; nael-markdown.el ends here

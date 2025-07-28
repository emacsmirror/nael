;;; nael-markdown.el --- Nael in Markdown  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Mekeor Melire

;; Author: Mekeor Melire <mekeor@posteo.de>
;; Keywords: languages
;; Maintainer: Mekeor Melire <mekeor@posteo.de>
;; Package-Requires: ((emacs "29.1") (markdown-mode "2"))
;; SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-only
;; URL: https://codeberg.org/mekeor/nael
;; Version: 0.3.0

;; This file is NOT part of GNU Emacs.

;; This code is effectively licensed under GNU General Public License
;; version 3, see LICENSE.GPL3.  To be more precise, it's forked from
;; code that has been licensed under Apache-2.0, see LICENSE.APACHE2.

;;; Commentary:

;; Configure `markdown-mode' to leverage `nael-mode' for `lean'
;; labeled source blocks.

;;; Code:

(require 'markdown-mode)

(add-to-list 'markdown-code-lang-modes
             (cons "lean" 'nael-mode))

(provide 'nael-markdown)

;;; nael-markdown.el ends here

;;; nael.el --- Major mode for Lean  -*- lexical-binding: t; -*-

;; Copyright (C) 2014 Microsoft Corp.
;; Copyright (C) 2024 Free Software Foundation, Inc.
;; Copyright (C) 2025 Mekeor Melire

;; Author:
;;   Adam Topaz <topaz@ualberta.ca>
;;   Akira Komamura <akira.komamura@gmail.com>
;;   Bao Zhiyuan <bzy_sustech@foxmail.com>
;;   Daniel Selsam <daniel.selsam@protonmail.com>
;;   Gabriel Ebner <gebner@gebner.org>
;;   Henrik Böving <hargonix@gmail.com>
;;   Hongyu Ouyang  <oyhy0214@163.com>
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
;; Package-Requires: ((emacs "29.1"))
;; SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-only
;; URL: https://codeberg.org/mekeor/nael
;; Version: 0.3.0

;; This file is NOT part of GNU Emacs.

;; This code is effectively licensed under GNU General Public License
;; version 3, see LICENSE.GPL3.  To be more precise, it's forked from
;; code that has been licensed under Apache-2.0, see LICENSE.APACHE2.

;;; Commentary:

;; `nael-mode' is a major mode for Lean.

;;; Code:

(require 'jsonrpc)
(require 'project)
(require 'rx)
(require 'seq)

(require 'nael-abbrev)

(defgroup nael nil
  "Major mode for Lean."
  :group 'languages
  :link '(emacs-library-link :tag "Source Lisp File" "nael.el")
  :link '(info-link :tag "Info manual" "(nael) Top")
  :link '(url-link :tag "Website" "https://codeberg.org/mekeor/nael")
  :prefix "nael-"
  :tag "Nael")

(defvar nael-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Parentheses:
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)

    ;; Comments:
    (modify-syntax-entry ?/  ". 14nb" table)
    (modify-syntax-entry ?-  ". 123"  table)
    (modify-syntax-entry ?\n ">"      table)
    (modify-syntax-entry ?«  "<"      table)
    (modify-syntax-entry ?»  ">"      table)

    ;; Words:
    (mapc
     (lambda (character) (modify-syntax-entry character "w" table))
     '(;; Latin characters:
       ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m ?n ?o ?p ?q ?r ?s ?t ?u
       ?v ?w ?x ?y ?z ?A ?B ?C ?D ?E ?F ?G ?H ?I ?J ?K ?L ?M ?N ?O ?P
       ?Q ?R ?S ?T ?U ?V ?W ?X ?Y ?Z
       ;; Digits
       ?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9
       ;; Greek (and Coptic) characters:
       ?α ?β ?γ ?δ ?ε ?ζ ?η ?θ ?ι ?κ ;; ?λ
       ?μ ?ν ?ξ ?ο ?π ?ρ ?ς ?σ ?τ ?υ ?φ ?χ ?ψ ?ω ?ϊ ?ϋ ?ό ?ύ ?ώ ?Ϗ ?ϐ
       ?ϑ ?ϒ ?ϓ ?ϔ ?ϕ ?ϖ ?ϗ ?Ϙ ?ϙ ?Ϛ ?ϛ ?Ϝ ?ϝ ?Ϟ ?ϟ ?Ϡ ?ϡ ?Ϣ ?ϣ ?Ϥ ?ϥ
       ?Ϧ ?ϧ ?Ϩ ?ϩ ?Ϫ ?ϫ ?Ϭ ?ϭ ?Ϯ ?ϯ ?ϰ ?ϱ ?ϲ ?ϳ ?ϴ ?ϵ ?϶ ?Ϸ ?ϸ ?Ϲ ?Ϻ
       ?ϻ ?ἀ ?ἁ ?ἂ ?ἃ ?ἄ ?ἅ ?ἆ ?ἇ ?Ἀ ?Ἁ ?Ἂ ?Ἃ ?Ἄ ?Ἅ ?Ἆ ?Ἇ ?ἐ ?ἑ ?ἒ ?ἓ
       ?ἔ ?ἕ ?἖ ?἗ ?Ἐ ?Ἑ ?Ἒ ?Ἓ ?Ἔ ?Ἕ ?἞ ?἟ ?ἠ ?ἡ ?ἢ ?ἣ ?ἤ ?ἥ ?ἦ ?ἧ ?Ἠ
       ?Ἡ ?Ἢ ?Ἣ ?Ἤ ?Ἥ ?Ἦ ?Ἧ ?ἰ ?ἱ ?ἲ ?ἳ ?ἴ ?ἵ ?ἶ ?ἷ ?Ἰ ?Ἱ ?Ἲ ?Ἳ ?Ἴ ?Ἵ
       ?Ἶ ?Ἷ ?ὀ ?ὁ ?ὂ ?ὃ ?ὄ ?ὅ ?὆ ?὇ ?Ὀ ?Ὁ ?Ὂ ?Ὃ ?Ὄ ?Ὅ ?὎ ?὏ ?ὐ ?ὑ ?ὒ
       ?ὓ ?ὔ ?ὕ ?ὖ ?ὗ ?὘ ?Ὑ ?὚ ?Ὓ ?὜ ?Ὕ ?὞ ?Ὗ ?ὠ ?ὡ ?ὢ ?ὣ ?ὤ ?ὥ ?ὦ ?ὧ
       ?Ὠ ?Ὡ ?Ὢ ?Ὣ ?Ὤ ?Ὥ ?Ὦ ?Ὧ ?ὰ ?ά ?ὲ ?έ ?ὴ ?ή ?ὶ ?ί ?ὸ ?ό ?ὺ ?ύ ?ὼ
       ?ώ ?὾ ?὿ ?ᾀ ?ᾁ ?ᾂ ?ᾃ ?ᾄ ?ᾅ ?ᾆ ?ᾇ ?ᾈ ?ᾉ ?ᾊ ?ᾋ ?ᾌ ?ᾍ ?ᾎ ?ᾏ ?ᾐ ?ᾑ
       ?ᾒ ?ᾓ ?ᾔ ?ᾕ ?ᾖ ?ᾗ ?ᾘ ?ᾙ ?ᾚ ?ᾛ ?ᾜ ?ᾝ ?ᾞ ?ᾟ ?ᾠ ?ᾡ ?ᾢ ?ᾣ ?ᾤ ?ᾥ ?ᾦ
       ?ᾧ ?ᾨ ?ᾩ ?ᾪ ?ᾫ ?ᾬ ?ᾭ ?ᾮ ?ᾯ ?ᾰ ?ᾱ ?ᾲ ?ᾳ ?ᾴ ?᾵ ?ᾶ ?ᾷ ?Ᾰ ?Ᾱ ?Ὰ ?Ά
       ?ᾼ ?᾽ ?ι ?᾿ ?῀ ?῁ ?ῂ ?ῃ ?ῄ ?῅ ?ῆ ?ῇ ?Ὲ ?Έ ?Ὴ ?Ή ?ῌ ?῍ ?῎ ?῏ ?ῐ
       ?ῑ ?ῒ ?ΐ ?῔ ?῕ ?ῖ ?ῗ ?Ῐ ?Ῑ ?Ὶ ?Ί ?῜ ?῝ ?῞ ?῟ ?ῠ ?ῡ ?ῢ ?ΰ ?ῤ ?ῥ
       ?ῦ ?ῧ ?Ῠ ?Ῡ ?Ὺ ?Ύ ?Ῥ ?῭ ?΅ ?` ?῰ ?῱ ?ῲ ?ῳ ?ῴ ?῵ ?ῶ ?ῷ ?Ὸ ?Ό ?Ὼ
       ?Ώ ?ῼ ?´ ?῾
       ;; Mathematical characters:
       ?℀ ?℁ ?ℂ ?℃ ?℄ ?℅ ?℆ ?ℇ ?℈ ?℉ ?ℊ ?ℋ ?ℌ ?ℍ ?ℎ ?ℏ ?ℐ ?ℑ ?ℒ ?ℓ ?℔
       ?ℕ ?№ ?℗ ?℘ ?ℙ ?ℚ ?ℛ ?ℜ ?ℝ ?℞ ?℟ ?℠ ?℡ ?™ ?℣ ?ℤ ?℥ ?Ω ?℧ ?ℨ ?℩
       ?K ?Å ?ℬ ?ℭ ?℮ ?ℯ ?ℰ ?ℱ ?Ⅎ ?ℳ ?ℴ ?ℵ ?ℶ ?ℷ ?ℸ ?ℹ ?℺ ?℻ ?ℼ ?ℽ ?ℾ
       ?ℿ ?⅀ ?⅁ ?⅂ ?⅃ ?⅄ ?ⅅ ?ⅆ ?ⅇ ?ⅈ ?ⅉ ?⅊ ?⅋ ?⅌ ?⅍ ?ⅎ ?⅏
       ;; Subscripts:
       ?₁ ?₂ ?₃ ?₄ ?₅ ?₆ ?₇ ?₈ ?₉ ?₀ ?ₐ ?ₑ ?ₒ ?ₓ ?ₔ ?ₕ ?ₖ ?ₗ ?ₘ ?ₙ ?ₚ
       ?ₛ ?ₜ ?' ?_ ?! ??))

    ;; Operators:
    (mapc
     (lambda (character) (modify-syntax-entry character "." table))
     '(?# ?$ ?% ?& ?* ?+ ?< ?= ?> ?@ ?^ ?| ?~ ?:))

    ;; Whitespace:
    (modify-syntax-entry ?\  " " table)
    (modify-syntax-entry ?\t " " table)

    ;; Strings:
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\\ "/"  table)

    table)
  "Syntax table used in `nael-mode'.")

(defconst nael-syntax-definition
  (rx
   ;; Use `line-start' rather than `word-start' for speed.
   line-start
   (group
    (or "axiom" "class" "constant" "def" "definition" "inductive"
        "instance" "lemma" "opaque" "structure" "theorem"
        (group "class" (zero-or-more space) "inductive")))
   word-end
   (zero-or-more space)
   (group (zero-or-more
           "{" (zero-or-more (not (any "}"))) "}"
           (zero-or-more space)))
   (zero-or-more space)
   (group (zero-or-more (not (any " \t\n\r{([")))))
  "Regular expression matching definitions.")

(defvar nael-font-lock-defaults
  (list
   (list
    (list (rx word-start "attribute" word-end
              (zero-or-more space)
              (group
               (one-or-more "[" (zero-or-more (not (any "]"))) "]"
                            (zero-or-more space))))
          '(1 'font-lock-preprocessor-face))
    (list (rx (group "@[" (zero-or-more (not (any "]"))) "]"))
          '(1 'font-lock-preprocessor-face))
    (list (rx (group "#"
                     (or "eval" "print" "reduce" "help" "check" "lang"
                         "check_failure" "synth")))
          '(1 'font-lock-keyword-face))

    ;; Mutual definitions:
    (list (rx word-start "mutual" word-end
              (zero-or-more space)
              word-start (or "inductive" "definition" "def") word-end
              (group (zero-or-more (not (any " \t\n\r{([,")))
                     (zero-or-more (zero-or-more space) ","
                                   (zero-or-more space)
                                   (not (any " \t\n\r{([,")))))
          '(1 'font-lock-function-name-face))

    ;; Definitions:
    nael-syntax-definition

    ;; Constants which have a keyword as subterm:
    (cons "∘if"
          'font-lock-constant-face)

    ;; Keywords:
    (list "\\(set_option\\)[ \t]*\\([^ \t\n]*\\)"
          '(2 'font-lock-constant-face))
    (cons (rx word-start
              (or
               "abbrev" "at" "attribute" "attributes" "axiom" "begin"
               "break" "builtin_initialize" "by" "cases" "catch"
               "class" "constant" "continue" "declare_syntax_cat"
               "def" "deriving" "do" "elab" "else" "end" "example"
               "exists" "export" "extends" "finally" "for" "forall"
               "from" "fun" "generalizing" "have" "hide" "hiding"
               "if" "import" "in" "include" "induction" "inductive"
               "infix" "infixl" "infixr" "init_quot" "initialize"
               "instance" "lemma" "let" "local" "macro" "macro_rules"
               "match" "match_syntax" "mut" "mutual" "namespace"
               "nomatch" "noncomputable" "notation" "open" "opaque"
               "partial" "postfix" "precedence" "prefix" "prelude"
               "private" "protected" "raw" "rec"
               "register_builtin_option" "renaming" "return" "run_cmd"
               "scoped" "section" "set_option" "show" "structure"
               "suffices" "syntax" "then" "theorem" "this" "try"
               "unif_hint" "universe" "universes" "unless" "unsafe"
               "using" "using_well_founded" "variable" "variables"
               "where" "with")
              word-end)
          'font-lock-keyword-face)
    (list (rx word-start (group "example") ".")
          '(1 'font-lock-keyword-face))
    (cons (rx (or "∎"))
          'font-lock-keyword-face)

    ;; Types:
    (cons (rx word-start
              (or "Prop" "Type" "Type*" "Sort" "Sort*")
              symbol-end)
          'font-lock-type-face)
    (list (rx word-start (group (or "Prop" "Type" "Sort")) ".")
          '(1 'font-lock-type-face))

    ;; Strings:
    (cons "\"[^\"]*\"" 'font-lock-string-face)

    ;; Constants:
    (cons (regexp-opt
           '("!" "#" "$" "&&" "*" "+" "+c" "+f" "+n" "-" "->" "/" "/"
             "/\\" ":=" "<" "<->" "<=" "=" "==" ">" ">=" "@" "\\/"
             "^c" "||" "~" "¬" "×" "×c" "×f" "×n" "Π" "Σ" "λ" "⁻¹" "ℂ"
             "ℕ" "ℕ₋₂" "ℚ" "ℝ" "ℤ" "→" "↔" "∀" "∃" "∘" "∘1nf" "∘f"
             "∘f1n" "∘fi" "∘fn" "∘fn1" "∘n" "∘n1f" "∘nf" "∧" "∨" "∼"
             "≃" "≃c" "≅" "≅c" "≠" "≡" "≤" "≥" "▸" "◾" "◾o" "⬝" "⬝e"
             "⬝h" "⬝hp" "⬝i" "⬝o" "⬝op" "⬝ph" "⬝po" "⬝pv" "⬝r" "⬝v"
             "⬝vp" "𝔸"))
          'font-lock-constant-face)
    (cons (rx word-start
              (one-or-more digit)
              (optional (and "." (zero-or-more digit)))
              word-end)
          'font-lock-constant-face)

    ;; Place holder:
    (cons (rx symbol-start "_" symbol-end)
          'font-lock-preprocessor-face)

    ;; Warnings:
    (cons (rx word-start "sorry" word-end)
          'font-lock-warning-face)
    (cons (rx word-start
              (or "assert" "dbgTrace" "panic" "unreachable"))
          'font-lock-warning-face)

    ;; Escaped identifiers:
    (list (rx (group "«")
              (group (one-or-more (not (any "»"))))
              (group "»"))
          '(1 font-lock-comment-face t)
          '(2 nil t)
          '(3 font-lock-comment-face t))))
  "Defaults for `font-lock-mode' used by `nael-mode'.")

(defun nael-comment-insert ()
  "`comment-insert-comment-function' for `nael-mode'."
  (interactive)
  (if (save-excursion (beginning-of-line)
                      (looking-at-p "[[:blank:]]*$"))
      (progn
        ;; Respect users who set `comment-start' to "--".
        (insert comment-start " ")
        ;; Respect users who set `comment-end' to "".
        (unless (length= comment-end 0)
          (save-excursion
            (insert " " comment-end))))
    (end-of-line)
    (unless (looking-back "[[:blank:]]" (1- (point)))
      (insert " "))
    (insert "-- ")))

(defun nael-fill-paragraph (&optional justify)
  "Fill comment paragraph at point."
  (interactive)
  (when (save-excursion (nth 4 (syntax-ppss (point))))
    (let* ((com-beg (save-excursion
                      (re-search-backward "[/-]-" nil t)
                      (match-beginning 0)))
           (multi (eq (char-after com-beg) ?/)))
      (if multi
          (let* ((par-beg (save-excursion
                            (re-search-backward paragraph-start nil t)
                            (match-beginning 0)))
                 (beg (max com-beg par-beg))
                 (com-end (if multi "-/" "$"))
                 (com-end (save-excursion
                            ;; If cursor is at -|/, then move to |-/,
                            ;; so that `re-search-forward' can locate
                            ;; comment ending.
                            (and (eq (char-before) ?-)
                                 (eq (char-after) ?/)
                                 (backward-char))
                            (re-search-forward com-end nil t)
                            (match-end 0)))
                 (par-end (save-excursion
                            (search-forward paragraph-separate nil t)
                            (match-end 0)))
                 (end (min com-end par-end)))
            (fill-region beg end justify))
        ;; `fill-comment-paragraph' fills prefixed comments well, when
        ;; configured correctly.
        (let ((comment-start "--") (comment-end ""))
          ;; For some reason, "" is used as fill-prefix by
          ;; `fill-comment-paragraph' when point is at --|.  Avoid
          ;; this misbehavior by moving point forward one char.
          (and (not (eolp))
               (looking-back "--" (max (- (point) 2) (point-min)))
               (forward-char))
          (fill-comment-paragraph justify))))))

;; TODO: Both `nael-navigation-defun-beginning' and
;; `nael-navigation-defun-name' currently lack support for `mutual'
;; blocks, i.e. mutually recursive definitions.

(defun nael-navigation-defun-end ()
  "`end-of-defun-function' for `nael-mode'."
  (interactive)
  (when (re-search-forward nael-syntax-definition nil t)
    (goto-char (match-beginning 0))))

(defun nael-navigation-defun-beginning ()
  "`beginning-of-defun-function' for `nael-mode'."
  (interactive)
  (re-search-backward nael-syntax-definition nil t))

(defun nael-navigation-defun-name ()
  "`add-log-current-defun-function' for `nael-mode'."
  (save-excursion
    (when (nael-navigation-defun-beginning)
      (forward-symbol 1)
      (forward-whitespace 1)
      (symbol-at-point))))

(defvar nael-imenu-generic-expression
  (list (list nil nael-syntax-definition 4))
  "`imenu-generic-expression' for `nael-mode'.")

(defcustom nael-mode-hook nil
  "Hook run when entering `nael-mode'.

If both `nael-eglot-init' and `eglot-ensure' are members, they should
appear in that order.  If both `nael-lsp-init' and `lsp' are members,
they should appear in that order."
  :options '( abbrev-mode eglot-ensure imenu-add-menubar-index
              nael-eglot-init nael-lsp-init
              lsp)
  :type 'hook
  :group 'nael)

(defvar-keymap nael-mode-map
  "<remap> <display-local-help>" #'eldoc-doc-buffer
  "C-c a" #'abbrev-mode
  "C-c c" #'project-compile
  "C-c e" #'eglot)

;;;###autoload
(define-derived-mode nael-mode prog-mode "Nael"
  "Major mode for Lean.

\\{nael-mode-map}"
  :abbrev-table nael-abbrev-table
  ;; Abbreviations: (The commentary of `nael-abbrev' explains in depth
  ;; why this workaround is needed.)
  (add-hook 'abbrev-mode-hook
            #'nael-abbrev-special-init
            nil t)
  ;; Navigation:
  (setq-local add-log-current-defun-function
              #'nael-navigation-defun-name)
  (setq-local beginning-of-defun-function
              #'nael-navigation-defun-beginning)
  (setq-local end-of-defun-function
              #'nael-navigation-defun-end)
  ;; Paragraphs and filling:
  (setq-local paragraph-start
              "[[:blank:]]*$")
  (setq-local paragraph-separate
              "[[:blank:]]*$")
  (setq-local fill-paragraph-function
              #'nael-fill-paragraph)
  ;; Comments:
  (setq-local comment-end
              "-/")
  (setq-local comment-end-skip
              "[[:space:]]*-/")
  (setq-local comment-insert-comment-function
              #'nael-comment-insert)
  (setq-local comment-padding
              1)
  (setq-local comment-quote-nested ;; Comments may be nested.
              nil)
  (setq-local comment-start
              "/-")
  (setq-local comment-start-skip
              "/-[[:space:]]*")
  (setq-local comment-style
              'multi-line)
  (setq-local comment-use-syntax
              t)
  (setq-local parse-sexp-ignore-comments
              t)
  ;; Font-lock:
  (setq-local font-lock-defaults
              nael-font-lock-defaults)
  ;; Compile:
  (setq-local compilation-mode-font-lock-keywords
              nil)
  (setq-local compile-command
              "lake build ")
  ;; Imenu:
  (setq-local imenu-generic-expression
              nael-imenu-generic-expression)
  ;; Flymake:
  (setq-local next-error-function
              #'flymake-goto-next-error))

(add-to-list 'auto-mode-alist (cons "\\.lean\\'" 'nael-mode))

(modify-coding-system-alist 'file "\\.lean\\'" 'utf-8)

(provide 'nael)

;;; nael.el ends here

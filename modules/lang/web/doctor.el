;;; lang/web/doctor.el -*- lexical-binding: t; -*-

(assert! (or (not (modulep! +lsp))
             (modulep! :tools lsp))
         "This module requires (:tools lsp)")

(assert! (or (not (modulep! +tree-sitter))
             (modulep! :tools tree-sitter))
         "This module requires (:tools tree-sitter)")

(when (modulep! :editor format)
  (unless (executable-find "prettier")
    (warn! "Couldn't find prettier. Code formatting in web, HTML, and CSS modes will not work.")))

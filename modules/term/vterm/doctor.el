;;; term/vterm/doctor.el -*- lexical-binding: t; -*-

(let ((vterm-module-ready-p
       (condition-case nil
           (progn
             (require 'vterm nil t)
             (featurep 'vterm-module))
         (error nil))))
  (unless (or vterm-module-ready-p
              (executable-find "make"))
    (warn! "Couldn't find make command. Vterm module won't compile"))

  (unless (or vterm-module-ready-p
              (executable-find "cmake"))
    (warn! "Couldn't find cmake command. Vterm module won't compile")))

(unless (fboundp 'module-load)
  (warn! "Your emacs wasn't built with dynamic modules support. The vterm module won't build"))

;;; test/lisp/test-guix-symlink-paths.el -*- lexical-binding: t; -*-

(require 'ert)

(let ((user-emacs-directory
       (file-name-as-directory
        (expand-file-name (or (getenv "EMACSDIR") user-emacs-directory)))))
  (load (expand-file-name "lisp/doom.el" user-emacs-directory) nil t))

(setq doom-user-dir
      (file-name-as-directory
       (expand-file-name (or (getenv "DOOMDIR") doom-user-dir))))

(doom-require 'doom-lib 'files)
(doom-require 'doom-lib 'modules)
(doom-require 'doom-lib 'autoloads)

(defmacro doom-test--with-symlinked-layout (&rest body)
  (declare (indent 0) (debug t))
  `(let* ((tmp (make-temp-file "doom-guix-symlink-" t))
          (store-root (expand-file-name "store" tmp))
          (visible-root (expand-file-name "visible" tmp))
          (store-core (expand-file-name "core/lisp" store-root))
          (store-user (expand-file-name "user" store-root))
          (visible-core (expand-file-name "emacs/lisp" visible-root))
          (visible-user (expand-file-name "doom" visible-root)))
     (unwind-protect
         (progn
           (make-directory store-core t)
           (make-directory store-user t)
           (make-directory (file-name-directory visible-core) t)
           (make-directory (file-name-directory visible-user) t)
           (make-symbolic-link store-core visible-core t)
           (make-symbolic-link store-user visible-user t)
           (let ((doom-core-dir (file-name-as-directory visible-core))
                 (doom-user-dir (file-name-as-directory visible-user))
                 (doom-modules-dir (file-name-as-directory (expand-file-name "modules" visible-core))))
             ,@body))
       (ignore-errors (delete-directory tmp t)))))

(ert-deftest doom-path-in-directory-p-preserves-runtime-visible-symlink-paths ()
  (let ((core-file (expand-file-name "lib/text.el" doom-core-dir))
        (user-file (expand-file-name "config.el" doom-user-dir)))
    (should (file-exists-p core-file))
    (should (file-exists-p user-file))
    (skip-unless (and (not (file-in-directory-p core-file doom-core-dir))
                      (not (file-in-directory-p user-file doom-user-dir))))
    (should (doom-path-in-directory-p core-file doom-core-dir))
    (should (doom-path-in-directory-p user-file doom-user-dir))))

(ert-deftest doom-module-from-path-detects-runtime-core-and-user-under-symlinks ()
  (let ((core-file (expand-file-name "lib/text.el" doom-core-dir))
        (user-file (expand-file-name "config.el" doom-user-dir)))
    (should (equal '(:doom) (doom-module-from-path core-file)))
    (should (equal '(:user) (doom-module-from-path user-file)))))

(ert-deftest doom-load-classifies-core-errors-under-symlinks ()
  (doom-test--with-symlinked-layout
    (let ((broken-lib "doom-test-broken-lib")
          (load-path (copy-sequence load-path)))
      (with-temp-file (expand-file-name (concat broken-lib ".el") doom-core-dir)
        (insert "(error \"boom\")\n"))
      (push doom-core-dir load-path)
      (should-error (doom-load broken-lib)
                    :type 'doom-core-error))))

(ert-deftest doom-autoloads-scan-projects-includes-forward-declared-projectile-vars ()
  (let* ((doom-modules nil)
         (_ (doom-modules-initialize t))
         (projects-file (expand-file-name "lib/projects.el" doom-core-dir))
         (forms (doom-autoloads--scan (list projects-file) nil nil))
         (text (prin1-to-string forms)))
    (dolist (sym '(projectile-project-root
                   projectile-enable-caching
                   projectile-require-project-root
                   projectile-verbose))
      (should (string-match-p (symbol-name sym) text)))))

(ert-deftest doom-projects-loaddefs-declare-projectile-verbose-as-special ()
  (let* ((doom-modules nil)
         (_ (doom-modules-initialize t))
         (projects-file (expand-file-name "lib/projects.el" doom-core-dir))
         (forms (doom-autoloads--scan (list projects-file) nil nil))
         (fake-projectile
          (make-temp-file "doom-fake-projectile-" nil ".el"
                          "(defgroup fake-projectile nil \"\" :group 'tools)\n(defcustom projectile-verbose nil \"\" :type 'boolean)\n"))
         (driver-file
          (make-temp-file "doom-fake-driver-" nil ".el"
                          ";;; -*- lexical-binding: t; -*-\n(let (projectile-verbose)\n  (load-file \"PLACEHOLDER\"))\n")))
    (unwind-protect
        (progn
          (mapc #'eval forms)
          (with-temp-buffer
            (insert-file-contents driver-file)
            (goto-char (point-min))
            (while (search-forward "PLACEHOLDER" nil t)
              (replace-match fake-projectile t t))
            (write-region (point-min) (point-max) driver-file nil 'silent))
          (should (load driver-file nil t)))
      (ignore-errors (delete-file fake-projectile))
      (ignore-errors (delete-file driver-file)))))

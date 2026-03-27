;; -*- lexical-binding: t; no-byte-compile: t; -*-
;;; lang/plantuml/doctor.el

(when (require 'plantuml-mode nil t)
  ;; java
  (unless (executable-find "java")
    (warn! "Couldn't find java. PlantUML preview or syntax checking won't work"))
  ;; graphviz
  (unless (executable-find "dot")
    (warn! "Couldn't find dot. PlantUML will only show outputs for sequence and activity diagrams"))
  ;; plantuml.jar
  (unless (or (and (boundp 'plantuml-executable-path)
                   (executable-find plantuml-executable-path))
              (file-exists-p plantuml-jar-path))
    (warn! "Couldn't find plantuml.jar or a usable PlantUML executable.")))

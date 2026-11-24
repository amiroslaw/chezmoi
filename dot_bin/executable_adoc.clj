#!/usr/bin/env bb

;; TODO add multifiles or dir support
(require '[babashka.cli :as cli]
         '[babashka.fs :as fs]
         '[clojure.string :as str])

(declare subcommands)
(def ^:private processor "asciidoctor.ruby4.0" )

(defn- common-opts
  [dark?]
  ["-r" "asciidoctor-kroki"
   "-a" "source-highlighter=rouge"
   "-a" (str "rouge-style=" (if dark? "molokai" "pastine"))
   "-a" "source-language=java"
   "-a" "highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin,clojure,fennel,bash"
   "-a" "hardbreaks=true"
   "-a" "experimental=true"
   "-a" "toc=left"
   "-a" "toclevels=5"
   "-a" "icons=font@"
   "-a" "allow-uri-read=true"
   "-a" "sectanchors=true"
   "-a" "sectlinks=true"
   "-a" "table-stripes=even"
   "-a" "imagesoutdir=./img"
   "-a" "imagesdir=./img"
   "-a" "plantuml-format=svg"])

(def spec-adoc
  {:input {:desc     "Path to the AsciiDoc file."
           :require  true
           :validate {:pred   #(and (string? %) (fs/exists? %))
                      :ex-msg (fn [m] (str "AsciiDoc file not found: " (:value m)))}}
   :dark  {:desc   "Use dark theme (molokai) for code blocks."
           :coerce :boolean
           :alias  :d}})

(defn- print-help
  [_]
  (printf " Convert AsciiDoc files to HTML (browser preview), PDF, or EPUB. %n%s
Examples:
  adoc.clj html notes.adoc
  adoc.clj pdf -d notes.adoc
  adoc.clj epub notes.adoc "
    (format-cmds! subcommands)))

(defn- build-html
  [{{:keys [input dark]} :opts}]
  (exec! "pkill" "-f" "watchexec" {:exit? false :notify? false})

  (let [note-dir (System/getenv "NOTE")
        html-out (if-not (str/blank? note-dir)
                   (str (fs/path note-dir "preview.html"))
                   "preview.html")
        browser  (or (System/getenv "BROWSER") "qutebrowser")
        ;; # --fs-events modify
        ;; asciidoctorj -o "$NOTE/preview.html"
        watchexec-cmd (vec (concat ["nohup" "watchexec" "--poll" "200ms" "--restart" "--watch" input "--"
                                    processor "-o" html-out "-b" "html5"]
                                   (common-opts dark)
                                   [input]))]
    (exec! watchexec-cmd {:background? true :out :discard :err :discard})
    (exec! browser html-out {:background? true :out :discard :err :discard})
    (notify! "AsciiDoc Preview" (str "Live preview started:\n" html-out))
    (println (str "Live HTML preview started: " html-out))))

(def ^:private format-configs
  {:pdf  {:ext     "pdf"
          :backend "pdf"
          :require "asciidoctor-pdf"
          :label   "PDF"}
   :epub {:ext     "epub"
          :backend "epub3"
          :require "asciidoctor-epub3"
          :label   "EPUB"}})

(defn- build-doc
  [format-key {{:keys [input dark]} :opts}]
  (let [{:keys [ext backend require label]} (get format-configs format-key)
        out-file (str (fs/strip-ext input) "." ext)
        cmd      (vec (concat [processor "-o" out-file "-b" backend "-r" require]
                              (common-opts dark)
                              [input]))]
    (println (str "Generating " label ": " out-file))
    (when (exec! cmd)
      (notify! (str "AsciiDoc " label) (str label " generated:\n" out-file)))))

(def subcommands
  [{:cmds ["html"],
    :desc "Generate HTML preview and open in browser",
    :fn build-html, :spec spec-adoc, :args->opts [:input]}
   {:cmds ["pdf"],
    :desc "Generate PDF file in the same directory as source AsciiDoc file",
    :fn (partial build-doc :pdf), :spec spec-adoc, :args->opts [:input]}
   {:cmds ["epub"],
    :desc "Generate EPUB file in the same directory as source AsciiDoc file",
    :fn (partial build-doc :epub), :spec spec-adoc, :args->opts [:input]}
   {:cmds ["help"],
    :desc "Print help.",
    :fn print-help}
   {:cmds [],
    :desc "Print help.",
    :fn print-help}])

(when (= *file* (System/getProperty "babashka.file"))
  (cli/dispatch (conj subcommands {:cmds ["completions"], :fn (partial completion! subcommands)})
                *command-line-args*))

;; -----------------------------------------------------------------------------
;; Useful reference comments and alternative configurations preserved from:
;; -----------------------------------------------------------------------------
;;
;; ls "$1" | entr -n asciidoctor -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true -a backend=html5 -a sectanchors=true -a sectlinks=true -a table-stripes=even  -a imagesoutdir=./img -a imagesdir=./img -a plantuml-format=svg "$1" &
;;
;; bug with asciidoctor-diagram
;; ls "$1" | entr -n asciidoctor -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true -a backend=html5 -a sectanchors=true -a sectlinks=true -a table-stripes=even -r asciidoctor-diagram -a imagesoutdir=./img -a imagesdir=./img -a plantuml-format=svg "$1" &
;;
;; --trace debug
;;
;; ls "$1" | entr -n asciidoctor -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true "$1" &

;; watchexec --watch "$1" -- asciidoc -o "$NOTE/preview.html" -a source-highlighter=highlight.js -a source-language=java -a highlightjs-languages=java,js,lua,sql,css,html,typescript,kotlin -a hardbreaks -a experimental=true -a toc=left -a toclevels=5 -a icons=font@ -a allow-uri-read=true -a backend=html5 -a sectanchors=true -a sectlinks=true -a table-stripes=even  -a imagesoutdir=./img -a imagesdir=./img -a plantuml-format=svg "$1" &
;;
;; outdir
;; outfile
;; iconsdir
;;
;; https://docs.asciidoctor.org/asciidoc/latest/attributes/document-attributes-ref/#source-highlighting-and-formatting-attributes
;;
;; asciidocFX:
;; allow-uri-read=true
;; showtitle=true
;; idprefix=true is def
;; apply-data-line=true ??
;; apply-image-cacher=true
;; imagesdir=images
;;
;;
;; source-highlighter=highlight.js
;; * coderay
;; * highlight.js
;; * pygments
;; * rouge
;;
;;
;; :doctype: article
;; :encoding: utf-8
;; :lang: en
;; :toc: left
;; :numbered:
;;

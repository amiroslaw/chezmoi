#!/usr/bin/env bb
(require '[babashka.process :as ps :refer [$ shell process sh]]
         '[clojure.string :as str]
         '[babashka.cli :as cli]
         '[clojure.core.match :refer [match]]
         '[clojure.java.io :as io])
;; TODO

(declare subcommands)

(defn- paste
  [opts clip]
  {:pre [(string? clip)]}
  (if (:paste opts)
    (do (ps-error-handler! true "clipcatctl insert" clip)
        (ps-error-handler! true "sleep 0.100")
        ; ctrl+v
        (ps-error-handler! true "ydotool key 29:1 47:1 47:0 29:0")
        ; # shift+insert -  primary clipboard
        ; (ps-error-handler! true "clipcatctl insert -k primary" clip)
        ; (ps-error-handler! true "ydotool key 42:1 110:1 110:0 42:0")
        ;       'xdotool sleep 0.100 key --clearmodifiers ctrl+v'
        (println clip))
    (println clip)))

(defn- list-clip-id
  []
  {:post [(sequential? %)]}
  (->> (ps-error-handler! true "clipcatctl list")
       str/split-lines
       (map #(str/split % #":"))
       (map first)))

(defn- get-clip
  [id]
  {:pre [(string? id)], :post [(string? %)]}
  (ps-error-handler! true "clipcatctl get" id))

(defn- previous [{opts :opts}] (paste opts (get-clip (second (list-clip-id)))))

(defn- last-item [{opts :opts}] (paste opts (get-clip (first (list-clip-id)))))

(defn- join
  [{opts :opts}]
  (let [number (if (:input opts) (rofi-number-input! "Join clip  ") (:number opts))]
    (->> (list-clip-id)
         (take number)
         (map get-clip)
         (str/join "\n")
         (paste opts))))

(def spec-join
  {:number
     {:desc "Number of previous items to join. Default 10", :coerce :int, :default 10, :alias :n},
   :input {:desc "Input for numbers of items to join.", :coerce :boolean, :alias :i}})

(def spec-global {:paste {:desc "Imitate paste.", :coerce :boolean, :alias :p}})

(defn- print-help
  [_]
  (printf
    " Utils for working with clipcat program. %n%s
Options for `join` command:%n%s
Examples:
   clipcat.clj join --number 3
  source <(clipcat.clj completions)  → source zsh completions
%nDependencies:
-- dependency: clipcat, rofi"
    (format-cmds! subcommands)
    (cli/format-opts {:spec spec-join})))

(def subcommands
  [{:cmds ["join"], :desc "Join clipboard items", :fn join, :spec (merge spec-global spec-join)}
   {:cmds ["previous"], :desc "Get the previous clipboard item", :fn previous, :spec spec-global}
   {:cmds ["last"], :desc "Get the last clipboard item", :fn last-item, :spec spec-global}
   {:cmds ["help"], :desc "Print help.", :fn print-help}
   {:cmds [], :desc "Print help.", :fn print-help}])

(when (= *file* (System/getProperty "babashka.file"))
  (cli/dispatch (conj subcommands {:cmds ["completions"], :fn (partial completion! subcommands)})
                *command-line-args*))
(comment
  (deps/add-deps '{:deps {dev.weavejester/hashp {:mvn/version "0.3.0"}}})
  (require 'hashp.preload)
  (deps/add-deps '{:deps {io.github.paintparty/fireworks {:mvn/version "0.10.4"}}})
  (require '[fireworks.core :refer [? !? ?> !?>]]))


(comment
  (cli/dispatch subcommands ["help"])
  (print (cli/dispatch subcommands ["previous"]))
  (cli/dispatch subcommands ["join" "-i"]))

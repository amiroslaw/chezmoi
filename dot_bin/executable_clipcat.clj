#!/usr/bin/env bb
(require '[clojure.string :as str] '[babashka.cli :as cli] '[clojure.core.match :refer [match]])

;; I could not find a clipboard manager for wayland which could separate primary from clipboard
;; buffer, this is why I have selection subcommand instead of passing parameter in options and
;; providing the same functionality.
;; TODO
; fix selection
; paste-clip - add x11 support with xdotool
; build my own rofi selector with keybinding for removing entries and adding them to the snippets,
; multiselect

(declare subcommands)

(defn- primary
  [{opts :opts}]
  (let [primary (exec! "wl-paste --primary")]
    (if (:paste opts)
      (do
       (exec! "sleep 0.100")
        ; shift+insert -  primary clipboard
        (exec! "ydotool key 42:1 110:1 110:0 42:0")
        (println primary))
      (println primary))))

(defn- list-clip-id []
  {:post [(sequential? %)]}
  (->> (exec! "clipcatctl list")
       str/split-lines
       (map #(str/split % #":"))
       (map first)))

(defn- get-clip
  [id]
  {:pre [(string? id)], :post [(string? %)]}
  (exec! "clipcatctl get" id))

(defn- last-clip [] (get-clip (first (list-clip-id))))

(defn- paste-clip
  ([opts] (paste-clip opts (last-clip)))
  ([opts clip]
   (if (:paste opts)
     (do 
       ; (exec! "sleep 0.100")
         ; ctrl+v
         (exec! "ydotool key 29:1 47:1 47:0 29:0")
         ; (exec! "clipcatctl insert -k primary" clip)
         ;       'xdotool sleep 0.100 key --clearmodifiers ctrl+v'
         (println clip))
     (println clip))))

(defn- clip
  [{opts :opts}]
  (let [previous (if (:previous opts) second first)]
    (->> (list-clip-id)
         previous
         get-clip
         str/trim
         (exec! "clipcatctl insert")))
  (paste-clip opts))

(defn- menu [{opts :opts}] (exec! "clipcat-menu insert") (paste-clip opts))

(defn- join
  [{opts :opts}]
  (let [number (if (:input opts) (rofi-number-input! "Join clip  ") (:number opts))]
    (->> (list-clip-id)
         (take number)
         (map get-clip)
         (str/join "\n")
         (paste-clip opts))))

(def spec-join
  {:number
     {:desc "Number of previous items to join. Default 10", :coerce :int, :default 10, :alias :n},
   :input {:desc "Input for numbers of items to join.", :coerce :boolean, :alias :i}})

(def spec-clip {:previous {:desc "Get previous clipboard item.", :coerce :boolean, :alias :r}})
(def spec-global {:paste {:desc "Imitate paste.", :coerce :boolean, :alias :p}})

(defn- print-help
  [_]
  (printf
    " Utils for working with clipcat program. %n%s
Global options:%n%s
Options for `join` command:%n%s
Options for `clip` command:%n%s
Examples:
   clipcat.clj join --number 3
  source <(clipcat.clj completions)  → source zsh completions
%nDependencies:
-- dependency: clipcat, rofi"
    (format-cmds! subcommands)
    (cli/format-opts {:spec spec-global})
    (cli/format-opts {:spec spec-join})
    (cli/format-opts {:spec spec-clip})))

(def subcommands
  [{:cmds ["join"], :desc "Join clipboard items", :fn join, :spec (merge spec-global spec-join)}
   {:cmds ["clip"], :desc "Get a clipboard item", :fn clip, :spec (merge spec-global spec-clip)}
   {:cmds ["menu"], :desc "Clipboard rofi menu", :fn menu, :spec spec-global}
   {:cmds ["primary"],
    :desc "Get the last item from the primary (selection) clipboard",
    :fn primary,
    :spec spec-global} {:cmds ["help"], :desc "Print help.", :fn print-help}
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

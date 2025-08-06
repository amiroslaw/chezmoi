#!/usr/bin/env bb

(require '[babashka.process :as ps :refer [$ shell process sh]]
         '[clojure.string :as str]
         '[babashka.cli :as cli]
         '[clojure.core.match :refer [match]]
         '[cheshire.core :as json])

; usage 
; bind = , F9, exec, "$XDG_CONFIG_HOME/hypr/scratchpad.clj" news "wezterm start --class news -- top"

; TODO
; IMPORTANT, hypr rule can't move 
; to jest prosty skrypt uruchamiam program z daną clasą/ --app-id która ma swoje regóły w hypr config 
; jak jest uruchomiony to jedynie robię toggle 
; można rozbudować wraz z babashka.cli, aby przyjmować reguły, wtedy byłoby możliwe dodawanie aplikacji do jednego workspace
; pewnie trzeba sprawdzać workspace.name
  ; "workspace": {
  ;       "id": -98,
  ;       "name": "special:drop"
  ;   },
  ;   hyprctl dispatch exec "[workspace special silent; float; size 70% 60%; center] foot"


(defn- has-class 
  "Check if there a window with provided class name."
  [class]
  {:pre [(string? class)]}
  (-> (ps-error-handler! true "hyprctl clients -j")
                      (json/parse-string true)
                      (->> (some #(= (:class %) class) ))))

(defn- toggle
  [class cmd]
  {:pre [(string? class)(string? cmd)]}
  (if (has-class class)
    (ps-error-handler! true "hyprctl dispatch togglespecialworkspace " class)
    ;; maybe better to run by hyprctl exec
    (ps-error-handler! true cmd)))

(let [[class & cmd] *command-line-args*]
  (toggle class (str/join " " cmd)))


; (when (= *file* (System/getProperty "babashka.file"))
;   (cli/dispatch subcommands *command-line-args*))
;

(comment
  )

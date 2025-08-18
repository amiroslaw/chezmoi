#!/usr/bin/env bb
(require '[clojure.string :as str]
         '[babashka.cli :as cli]
         '[clojure.core.match :refer [match]]
         '[cheshire.core :as json])

; IMPORTANT, hypr rule can't move ???
; TODO
; videopopup did not send to special - it is pinned window

;  rozbudować, aby przyjmować reguły, wtedy byłoby możliwe dodawanie aplikacji do jednego workspace
;  hyprctl dispatch exec "[workspace special silent; float; size 70% 60% center] foot"

(def UNNAMED_PREFIX ";")
(defn- hypr-props
  "Fetches and parses JSON output from a hyprctl command."
  [cmd]
  {:pre [(string? cmd)], :post [(or (map? %) (sequential? %))]}
  (json/parse-string (ps-error-handler! true (format "hyprctl %s -j" cmd)) true))

(defn rofi-format-item
  "Formats a window item for rofi.
  'workspace-name :win-class #win-title"
  [win]
  {:pre [(map? win)], :post [(string? %)]}
  (let [workspace (last (str/split (get-in win [:workspace :name]) #":"))
        class (trim-col (last (str/split (:class win) #"\\.")) 10)
        title (:title win)]
    (format "%s\t :%s #%s" workspace class title)))

(defn- create-menu
  [windows prompt]
  {:pre [(sequential? windows) (string? prompt)]}
  (let [sorted-windows (sort-by #(get-in % [:workspace :name]) windows)
        window-items (map rofi-format-item sorted-windows)
        rofi-opts {:prompt (str prompt (count windows))
                   :width "80%"
                   :format \i
                   :keys [["Alt-k" "kill window"]]}
        {:keys [out exit key]} (rofi-menu!
                                 window-items
                                 rofi-opts)]
    (if exit
      {:selected (rofi-indexes->inputs out sorted-windows), :key key}
      (System/exit 0))))

(defn- filter-win-by-workspace
  [windows name]
  {:pre [(sequential? windows)], :post [(sequential? %)]}
  (->> windows
       (filter #(str/starts-with? (get-in % [:workspace :name]) name))))

(defn- focus-window
  "Focuses a window using its address."
  [win]
  {:pre [(and (map? win) (:address win))]}
  (ps-error-handler! true (str "hyprctl dispatch focuswindow address:" (:address win))))

(defn- kill-window
  "Kills a window using its address."
  [win]
  {:pre [(and (map? win) (:address win))]}
  (ps-error-handler! true (str "hyprctl dispatch closewindow address:" (:address win))))

(defn- show-menu
  [{:keys [prompt filter-fn]}]
  (let [clients (cond-> (hypr-props "clients")
                  filter-fn (filter-fn))
        {:keys [selected key]} (create-menu clients prompt)
        first-win (first selected)]
    (when first-win
      (if (= key 0)
        (kill-window first-win)
        (focus-window first-win)))))

(defn- scratchapd-list
  "Shows menu with all windows from all special workspaces."
  []
  (show-menu {:prompt "Scratchpads: ", :filter-fn #(filter-win-by-workspace % "special:")}))

(defn- detail->workspace-name
  "Extracts the workspace name from a details map."
  [detail]
  {:pre [(map? detail)], :post [(string? %)]}
  (last (str/split (:name detail) #":")))

;; TODO will it toggle pinned?
(defn- toggle
  "Toggles a special workspace. Dispatches based on the type of details:
  string - class from named scratchpad
  seq    - details from clients json
  map    - details from activewindow json"
  [details]
  {:post [(string? %)]}
  (cond (string? details)
          (ps-error-handler! true "hyprctl dispatch togglespecialworkspace " details)
        (map? details) (toggle (detail->workspace-name (:workspace details)))
        (sequential? details) (toggle (detail->workspace-name (first details)))))

(defn- toggle-named
  "Creates or toggles a named scratchpad based on a window class.
  The class must have a window rule in Hyprland.
  e.g. windowrule = workspace special:className, class:^(className)```"
  [class cmd]
  {:pre [(string? class) (string? cmd)]}
  (if (some #(= (:class %) class) (hypr-props "clients"))
    (toggle class)
    ;; maybe better to run by hyprctl exec
    (ps-error-handler! true cmd)))

(defn- special-workspaces
  "Returns workspaces, optionally filtered by a name prefix."
  ([] (special-workspaces ""))
  ([prefix] {:pre [(string? prefix)]} (special-workspaces (hypr-props "workspaces") prefix))
  ([workspaces prefix]
   {:pre [(sequential? workspaces)], :post [(sequential? %)]}
   (->> workspaces
        (filter #(str/starts-with? (:name %) (str "special:" prefix))))))

;; overcomplicated, when I pass list I know that it is empty
(defn- add-unnamed
  "Adds a new unnamed scratchpad with a generated name and returns the name."
  ([] (add-unnamed (special-workspaces UNNAMED_PREFIX)))
  ([unnamed-scratchpads]
   {:pre [(sequential? unnamed-scratchpads)], :post [(char? %)]}
   (let [scratchpad-name (char (+ (count unnamed-scratchpads) 97))]
     (ps-error-handler!
       true
       (str "hyprctl dispatch movetoworkspacesilent special:" UNNAMED_PREFIX scratchpad-name))
     scratchpad-name)))

;; todo maybe different name
(defn- manage-scratchpads
  "Creates or toggles a scratchpad based on the active window.
  - If focused window is in a scratchpad, toggles it.
  - If focused window is normal, creates a new unnamed scratchpad for it.
  - If no window is focused, or many, shows the scratchpad menu."
  [opts cmd] ; {:pre [(and (map? opts) (string? cmd))]} optional
  (let [active-win (hypr-props "activewindow")
        scratchpads (special-workspaces)
        unnamed (special-workspaces scratchpads UNNAMED_PREFIX)
        selected-scratchapad? (some #(= (:lastwindow %) (:address active-win)) scratchpads)]
    (if selected-scratchapad?
      (toggle active-win)
      (match [(empty? active-win) (count scratchpads) (count unnamed)]
        [true 0 0] (notify! " Scratchapd: Select a window")
        [true 1 0] (toggle scratchpads)
        [true _ 1] (toggle unnamed)
        [true _ _] (scratchapd-list)
        [false _ 0] (add-unnamed unnamed)
        [false _ 1] (toggle unnamed)
        :else (scratchapd-list)))))

(def spec
  {:spec
     {:named
        {:alias :n,
         :desc
           "Toggle a named scratchpad with provided class, if such a workspace doesn't exist, it will first generate it."},
      :toggle
        {:alias :t,
         :desc
           "Toggle an unnamed scratchpad, if such a workspace doesn't exist, it will first generate it."},
      :add {:alias :a, :desc "Add an unnamed scratchpad"},
      :list {:alias :l,
             :desc "Scratchpad list. It shows menu, only with windows on special workspaces - scratchpads"},
      :switcher
        {:alias :s,
         :desc "Windows switcher for all windows. It shows which workspaces the windows are on."},
      :help {:alias :h, :desc "Print help"}}})

(defn- print-help
  []
  (printf
    "Scratchpad implementation in Hyprland, written in Clojure.
A simple script that provides ergonomic workflow with scratchpads.
It provides two ways of managing special workspaces:

  1. Named scratchpads. Toggle or create a scratchpad with provided class. Script can take a scratchpad name and a command for launching a program in a special workspace. That command should have the window class which has to be the same as the scratchpad name.
  In Wayland programs often have a flag `--app-id` for setting a window class. 
  You can change scratchpad behaviour by adding rules in the Hyprland config.
  2. Unnamed scratchpads. In this mode the script generates a scratchpad for the active window. If that window is in a special workspace, it hides that window.
  %nOptions:%n%s
  %nUsage:
 To toggle a named scratchpad:
  scratchpad.clj -n monitor wezterm start --class monitor -- top
 bind = , F9, exec, '$XDG_CONFIG_HOME/hypr/scratchpad.clj' -u monitor wezterm start --class monitor -- top
 To toggle a scratchpad:
  scratchpad.clj -t
  %nDependencies:
   - babashka, rofi"
    (cli/format-opts spec)))

(defn- dispatch
  "Dispatches command-line arguments to the appropriate function."
  [parsed-args]
  {:pre [(map? parsed-args)]}
  (let [{:keys [opts args]} parsed-args]
    (cond (:switcher opts) (show-menu {:prompt "All windows: "})
          (:list opts) (scratchapd-list)
          (:toggle opts) (manage-scratchpads opts (str/join " " args))
          (:add opts) (add-unnamed)
          (:named opts) (toggle-named (:named opts) (str/join " " args))
          (:help opts) (print-help)
          :else (print-help))))

(when (= *file* (System/getProperty "babashka.file"))
  (dispatch (cli/parse-args *command-line-args* spec)))

(comment
  (require '[babashka.deps :as deps])
  (deps/add-deps '{:deps {io.github.paintparty/fireworks {:mvn/version "0.10.4"}}})
  (require '[fireworks.core :refer [? !? ?> !?>]]))
(comment
  (clojure.pprint/pprint workspace))

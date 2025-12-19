#!/usr/bin/env bb
(require '[clojure.string :as str]
         '[babashka.cli :as cli]
         '[babashka.process :as ps :refer [shell sh pipeline pb]]
         '[clojure.core.match :refer [match]]
         '[clojure.test :refer [is]]
         '[babashka.fs :as fs]
         '[cheshire.core :as json])
; TODO
; screen choice does not take an active output
; input for name

(declare subcommands)
(def default-format "webp")
(def grim-formats #{"png" "ppm" "jpeg"})
(def targets #{"region" "window" "output" "screen"})

(defn- handle-out
  [{:keys [out exit err]}]
  (if (zero? exit) ;; Should also be surrounded with try-catch
    out
    (notify-error! err)))

(defn- hypr-props
  "Fetches and parses JSON output from a hyprctl command."
  [cmd]
  {:pre [(is (string? cmd))], :post [(or (is map? %) (is sequential? %))]}
  (json/parse-string (ps-error-handler! true (format "hyprctl %s -j" cmd)) true))

(defn- grab-active-win
  "Retrieves information about the active window, including its title and geometry."
  []
  {:post [(is (map? %))]}
  (let [{[x y] :at, [w h] :size, title :title} (hypr-props "activewindow")
        title (str/escape title {\/ "", \$ "", \' "`"}) ] ;; :initialTitle
    {:name "Active window", :title title, :geometry (format "%s,%s %sx%s" x y w h)}))

(defn- grab-with-slurp
  "Uses 'slurp' to grab data"
  [flag]
  {:pre [(is (string? flag))], :post [(is (string? %))]}
  (-> (shell {:out :string} "slurp" flag)
      (:out)
      (str/trim)))


(defn- grab
  "Grabs screenshot geometry based on the specified target (region, window, output, or screen)"
  [target]
  {:pre [(is (string? target))], :post [(is (map? %))]}
  (match [target]
    ["region"] {:name "region", :geometry (grab-with-slurp "-d")}
    ["window"] (grab-active-win)
    ["output"] {:name "active-monitor"} ;; grim without the -g flag takes a screenshot of the active output
    ["screen"] {:name "all-monitors", :geometry (grab-with-slurp "-or")})) ;; it selects an output, not all

(defn- get-save-dir
  "Determines the directory for saving screenshots." 
  [output]
  {:post [(is (string? %))]}
  (or output
      (System/getenv "XDG_SCREENSHOTS_DIR")
      (System/getenv "XDG_PICTURES_DIR")
      (str (fs/home))))

(defn- get-save-filename
  "Generates a unique filename for a screenshot using a base name (title or name) and a timestamp."
  [{:keys [title name]}]
  {:post [(is (string? %))]}
  (let [date (.format (java.time.LocalDateTime/now)
                      (java.time.format.DateTimeFormatter/ofPattern "yy-MM-dd'T'HHmmss"))
        base-name (or title name)]
    (format "%s-%s" base-name date)))

(defn- convert-format   
  "Converts an image format"
  [input output]
  {:pre [(is (string? input)) (is (string? output))]}
  (handle-out (sh (format "%s %s %s" "magick" input output))))

(defn- save-screenshot
  "Takes a screenshot using grim and saves it to the specified path, optionally applying format and geometry options."
  [opts path]
  {:pre [(is (string? path))]}
  (let [args (cond-> []
               (:format opts) (conj "-t" (:format opts))
               (:geometry opts) (conj "-g" (format "'%s'" (:geometry opts))))]
    (println (str "grim " (str/join " " args) path))
    (handle-out (sh (str "grim " (str/join " " args) path))))) ;; ps-error-handler! doesn't work
        ; (:monitor opts) (conj "-o" ) ;; for a specific output

(defn- create-temp-dir   
  "Creates a temporary directory for screenshots."
  []
  {:post [(is (string? %)) (is (fs/directory? %))]}
  (str (fs/create-dirs (str (fs/temp-dir) "/clj-screenshots"))))

(defn- capture-screenshot-to-temp
  "Captures a screenshot to a temporary file with a given suffix and format (defaulting to ppm)."
  [target suffix & {:keys [format] :or {format "ppm"}}]
  (let [grab-info (grab target)
        basename (get-save-filename grab-info)
        dir (create-temp-dir)
        path (clojure.core/format " '%s/%s-%s.%s'" dir suffix basename format)]
    (save-screenshot (assoc grab-info :format format) path)
    {:name (:name grab-info) :basename basename :path-tmp path}))

(defn- save
  "Saves a screenshot to a file."
  [{opts :opts}]
  (let [grab-info (grab (:target opts))
        ext (:format opts)
        basename (get-save-filename grab-info)
        dir (get-save-dir (:output opts))
        path (format " '%s/%s.%s'" dir basename ext)]
    (if (contains? grim-formats ext)
      (save-screenshot (merge grab-info opts) path)
      (let [tmp-path (format " '%s/%s.ppm'" (create-temp-dir) basename)
            opts-with-ppm (assoc grab-info :format "ppm")]
        (save-screenshot opts-with-ppm tmp-path)
        (convert-format tmp-path path)))
    (notify! (str (:name grab-info) " screenshot") path)))

(defn- copy
  "Takes a screenshot, saves it to a temporary file, and then copies the image data to the clipboard."
  [{opts :opts}]
  (let [{:keys  [path-tmp name]} (capture-screenshot-to-temp (:target opts) "copy" :format "png")]
    (pipeline (pb (str "cat " path-tmp)) (pb "wl-copy --type image/png"))
    (notify! (str "Copied: " name))))

(defn- edit
  "Takes a screenshot, saves it to a temporary file, and then opens it in an image editor"
  [{opts :opts}]
  (let [{:keys [basename path-tmp]} (capture-screenshot-to-temp (:target opts) "edit" :format "ppm")
        dir-out (get-save-dir (:output opts))
        path-out (format "'%s/edit-%s.png'" dir-out basename)]
    (ps-error-handler! true (format "satty --filename %s --output-filename %s" path-tmp path-out))))

(defn- ocr
  "Performs OCR (Optical Character Recognition) using Tesseract, copies the extracted text to the clipboard"
  [{opts :opts}]
  (let [{:keys [basename path-tmp]} (capture-screenshot-to-temp (:target opts) "ocr" :format "ppm")
        dir (create-temp-dir)
        path-txt (format "%s/ocr-%s" dir basename)]
    (ps-error-handler! true (format "tesseract %s %s" path-tmp path-txt))
    (pipeline (pb "cat" (str path-txt ".txt")) (pb "wl-copy"))
    (notify! "Text copied to clipboard.")))

(defn- items->menu
  [items]
  {:pre [(is (sequential? items))]
   :post [(is (vector? %)) (every? string? %)]} 
  (->> items
       (mapv (juxt :cmds :desc))
       (mapv (fn [[k v]] (format "%s: %s" (first k) v)))))

(defn- action-menu
  "Displays a Rofi menu for selecting a screenshot action."
  []
  {:post [(is (string? %))]}
  (let [commands (subvec subcommands 3)
        menu (items->menu commands)
        {:keys [out exit]} (rofi-menu! menu {:prompt "Select action", :width "80%", :format \i})]
    (if exit (first (:cmds (first (rofi-indexes->inputs out commands)))) (System/exit 0))))

(def keys-format
  [["Alt-p" "png" "png"] ["Alt-j" "jpeg" "jpeg"] ["Alt-a" "avif!" "avif"] ["Alt-m" "ppm" "ppm"]])
(defn- target-menu
  "Displays a Rofi menu for selecting a screenshot target"
  [action]
  {:pre [(is (string? action))]}
  (let [menu-opt {:prompt "Select target - default window", :width "80%"}
        key-opt (when (= action "save")
                  {:keys keys-format, :msg (str "Screenshot format - default " default-format)})
        {:keys [out key exit]} (rofi-menu! targets (merge menu-opt key-opt))]
    (if exit {:target (first out), :key (last (get keys-format key))} {:target (first targets)})))

(defn- menu
  [opts]
  (let [action (action-menu)
        {:keys [target key]} (target-menu action)
        pic-format (if (and key (= action "save")) key default-format)
        action-fun (resolve (symbol action))]
    (Thread/sleep 300)
    (action-fun {:opts (assoc (:opts opts)
                         :target target
                         :format pic-format)})))

(def spec
  {:target
     {:alias :t,
      :require true,
      :default "window",
      :desc
        "Take a screenshot of:\n  region - selected region\n  window - active window\n  output - active output\n  screen - all visible outputs.",
      :validate {:pred (fn [m] (contains? targets m)),
                 :ex-msg (fn [m] (str "Not a valid target: " (:value m) "\tExpected: " targets))}}})

(def spec-file
  {:output {:desc "Directory for saving screenshots", :alias :o},
   :format
     {:desc
        "Choose file format. ImageMagick is required for formats other than PNG, JPEG, or PPM.",
      :default default-format,
      :default-desc (str default-format " is the default format."),
      :alias :f}})

(defn- print-help
  [_]
  (printf
    "A screenshot utility for Hyprland, written in Clojure.
  %nOptions:%n%s
Global options:%n%s
Options for `save` command:%n%s
Examples:
   screenshot.clj save -t window
  source <(screenshot.clj completions)  → source zsh completions
  %nUsage:
  %nDependencies:
   - babashka, rofi"
    (format-cmds! subcommands)
    (cli/format-opts {:spec spec})
    (cli/format-opts {:spec spec-file})))

(def subcommands
  [{:cmds [], :desc "Show help.", :fn print-help}
   {:cmds ["help"], :desc "Show help.", :fn print-help}
   {:cmds ["menu"], :desc "Screenshot menu", :fn menu, :spec spec-file}
   {:cmds ["save"],
    :desc "Save the screenshot to a regular file.",
    :fn save,
    :spec (merge spec spec-file)}
   {:cmds ["copy"], :desc "Copy a screenshot into the clipboard.", :fn copy, :spec spec}
   {:cmds ["ocr"], :desc "Save a screenshot to the tmp folder and copy text from it.", :fn ocr, :spec spec}
   {:cmds ["edit"],
    :desc "Open screenshot in the image editor.",
    :fn edit,
    :spec (merge spec spec-file)}]) ;; it needs only output from spec-file

(when (= *file* (System/getProperty "babashka.file"))
  (cli/dispatch (conj subcommands {:cmds ["completions"], :fn (partial completion! subcommands)})
                *command-line-args*))

(comment
  (require '[babashka.deps :as deps])
  (deps/add-deps '{:deps {io.github.paintparty/fireworks {:mvn/version "0.10.4"}}})
  (require '[fireworks.core :refer [? !? ?> !?>]]))
(deps/add-deps '{:deps {philoskim/debux {:mvn/version "0.9.1"}}})
(require '[debux.core :refer [dbg dbgn]])
; at size 333,293 308x180
; (defn- grab-active-output [])
    ; OUTPUT=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
    ; local active_workspace=`hyprctl -j activeworkspace`
    ; local monitors=`hyprctl -j monitors`
    ; Print "Monitors: %s\n" "$monitors"
    ; Print "Active workspace: %s\n" "$active_workspace"
    ; local current_monitor="$(echo $monitors | jq -r 'first(.[] | select(.activeWorkspace.id ==
    ; '$(echo $active_workspace | jq -r '.id')'))')"
    ; Print "Current output: %s\n" "$current_monitor"
    ; echo $current_monitor | jq -r '"\(.x),\(.y) \(.width/.scale|round)x\(.height/.scale|round)"'
(comment
  (cli/dispatch subcommands ["help"])
  (cli/dispatch subcommands ["save" "-t" "region"])
  (cli/dispatch subcommands ["save" "-t" "window"])
  (cli/dispatch subcommands ["save" "-t" "output"])
  (cli/dispatch subcommands ["save" "-t" "screen"])
  (cli/dispatch subcommands ["save" "-t" "window" "-o" "/home/miro"])
  (cli/dispatch subcommands ["save" "-t" "region" "-o" "/home/miro"])
  (cli/dispatch subcommands ["save" "-t" "window" "-o" "/home/miro" "-f" "png"])
  (cli/dispatch subcommands ["save" "-t" "window" "-o" "/home/miro" "-f" "avif"])
  (cli/dispatch subcommands ["save" "-t" "window" "-o" "/home/miro" "-f" "ppm"])
  (cli/dispatch subcommands ["save" "-t" "window" "-o" "/home/miro" "-f" "jxl"]) ;; jpeg xl
  (cli/dispatch subcommands ["copy" "-t" "window"])
  (cli/dispatch subcommands ["ocr" "-t" "window"])
  (cli/dispatch subcommands ["ocr" "-t" "region"])
  (cli/dispatch subcommands ["edit" "-t" "window" "-o" "/home/miro"])
  (cli/dispatch subcommands ["menu" "-o" "/home/miro"]))

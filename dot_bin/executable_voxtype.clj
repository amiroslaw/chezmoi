#!/usr/bin/env bb
;; TODO: add summary
;; save out to file?

(require '[babashka.cli :as cli]
         '[babashka.fs :as fs]
         '[babashka.process :as ps :refer [shell sh process check]]
         '[clojure.string :as str])

(def voxtype-dir
  (str (fs/path (fs/home) ".local/state/voxtype/failed-audio")))

(def default-model "parakeet-tdt-0.6b-v3-int8") ;; in vex type 2.0 change to gguf, but it runs on CPU

(def media-exts #{"wav" "mp3" "ogg" "flac" "m4a" "mp4" "mkv" "webm" "mov"})

(def cli-spec
  {:spec {:engine {:alias :e
                   :desc "Engine to pass to voxtype transcribe"}
          :model  {:alias :m
                   :desc "Model to pass to voxtype transcribe"}}})

(defn find-latest-file [dir]
  (->> (fs/list-dir dir)
       (filter fs/regular-file?)
       (filter #(contains? media-exts (str/lower-case (or (fs/extension %) ""))))
       (sort-by #(fs/last-modified-time %) #(compare %2 %1))
       first))

(defn convert-to-16k-wav
  "Converts input file to a temporary 16kHz mono WAV and returns [wav-path cleanup-fn]."
  [input-path]
  (let [tmp-wav (str (fs/create-temp-file {:prefix "voxtype-" :suffix ".wav"}))]
    (println "Converting to 16kHz mono WAV:" (fs/file-name input-path))
    (shell {:out :string :err :string}
           "ffmpeg" "-y" "-i" (str input-path)
           "-ar" "16000" "-ac" "1" "-c:a" "pcm_s16le" tmp-wav)
    [tmp-wav #(fs/delete-if-exists tmp-wav)]))

(defn prepare-input
  "If force-convert? is true (explicit file argument), always convert to 16kHz WAV.
   For directory-picked files, pass .wav directly or convert non-.wav files."
  [input-path force-convert?]
  (let [ext (str/lower-case (or (fs/extension input-path) ""))]
    (if (and (not force-convert?) (= ext "wav"))
      [(str input-path) (fn [])]
      (convert-to-16k-wav input-path))))

(defn copy-to-clipboard! [text]
  (shell ["wl-copy"] {:in text}))

(defn resolve-target
  "Returns {:path <Path> :force-convert? <bool>} or nil if not found."
  [arg]
  (if arg
    (let [p (fs/path arg)]
      (when (and (fs/exists? p) (fs/regular-file? p))
        {:path p :force-convert? true}))
    (when (fs/exists? voxtype-dir)
      (when-let [latest (find-latest-file voxtype-dir)]
        {:path latest :force-convert? false}))))

(defn -main []
  (let [{:keys [opts args]} (cli/parse-args *command-line-args* cli-spec)
        arg (first args)
        ;; Rule: - it can be change to sumcommand; transcribe and retry
        ;; - If user provides only model -> use only model
        ;; - If user provides model and engine -> use only model
        ;; - If user provides only engine -> use only engine
        ;; - If neither provided -> fallback to default model
        target-flags (cond
                       (:model opts)  ["--model" (:model opts)]
                       (:engine opts) ["--engine" (:engine opts)]
                       :else          ["--model" default-model])]
    (if-let [{:keys [path force-convert?]} (resolve-target arg)]
      (let [[wav-path cleanup!] (prepare-input path force-convert?)]
        (try
          (println "Transcribing with" (first target-flags) (second target-flags) "file:" (fs/file-name path))
          (let [cmd (into ["voxtype" "--quiet"] (concat target-flags ["transcribe" wav-path]))
                {:keys [out err exit]} @(ps/process cmd {:out :string :err :string})
                transcript (-> out str/trim str/split-lines last str/trim)]
            (if (zero? exit)
              (do
                (copy-to-clipboard! transcript)
                (notify! "Copied to clipboard:" transcript)
                (println "\nCopied to clipboard:\n" transcript))
              (do
                (binding [*out* *err*]
                  (notify-error! "voxtype failed:")
                  (println "voxtype failed:\n" err))
                (System/exit exit))))
          (finally
            (cleanup!))))
      (do
        (binding [*out* *err*]
          (if arg
            (println "File does not exist or is not a regular file:" arg)
            (println "No matching audio/video files found in:" voxtype-dir)))
        (System/exit 1)))))

(-main)

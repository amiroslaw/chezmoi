#!/usr/bin/env bb
;; TODO
;; add more resources - files ; pipe input
;; more advanced templates, json/edn file with model, temperature, language, placeholder.
; escape chars from text? idk if I need for the client
(require '[babashka.process :as ps :refer [$ shell process sh]]
         '[clojure.string :as str]
         '[babashka.cli :as cli]
         '[babashka.http-client :as http]
         '[clojure.test :refer [is]]
         '[clojure.core.match :refer [match]]
         '[cheshire.core :as json])

(declare subcommands)

(def prompt-prefix "Paste this prompt on the top of your answer. ")
(def analyze-text-prompt (str ". " prompt-prefix "Answer to that question based to following text:\n\n"))
(def templates {:summary              "Summarize following text:\n\n",
                :summary-short        "Summarize following text, be concise:\n\n"
                :summary-adoc         "Summarize (use asciidoc format with lists and bold text if needed) following text:\n\n",
                :grammar              "Modify the following text to improve only grammar and spelling. Don't note about 'modified text'. Don't wrap the answer with quotation marks.:\n\n"
                :grammar-explain      "Modify the following text to improve only grammar and spelling. Don't note about 'modified text'. Don't wrap the answer with quotation marks. Explain nontrivial mistakes.:\n\n"
                :translate-to-english "Translate the following text to English:\n\n",
                :translate-to-polish  "Translate the following text to Polish:\n\n",})

(def api-host (if-let [ollama-env (System/getenv "OLLAMA_API_HOST")]
                ollama-env
                "http://localhost:11434"))
(def term-run (str (System/getenv "TERM_LT") (System/getenv "TERM_LT_RUN")))
(def response-dir "/tmp/clj/")

(defn- select-template []
  (if-let [template
           (-> (map name (keys templates))
               (rofi-menu! {:prompt "Select template", :width "30ch"})
               :out
               first
               keyword
               templates)]
    template
    (System/exit 0)))

(defn- prompt-input []
  (let [input (rofi-input! {:prompt "ask  ", :width "70 %"})]
    (if (str/blank? input)
      (System/exit 0)
      input)))

;; todo export and get from GEMINI_API_KEY
(def gemini-api-key (let [path (str (System/getenv "PRIVATE") "/keys.properties")
                          key (get-properties! path "gemini_api_key")]
                      (if key key
                              (notify-error! (str "Gemini API key not found in: \n" path) true))))

(defprotocol Provider
  (request [this prompt])
  (models [this])
  (get-model [this] "Get model or default provided if nil passed in a record"))

(defn ollama-list-models
  "Fetch all available Ollama models using `ollama list` command."
  []
  (try
    (let [{:keys [exit out err]} (sh "ollama" "list")]
      (if (zero? exit)
        (->> (str/split-lines out)
             rest
             (remove str/blank?)
             (map (fn [line] (first (str/split (str/trim line) #"\s+"))))
             (remove str/blank?)
             vec)
        (do
          (println "DEBUG: ollama list failed:" err)
          [])))
    (catch Exception e
      (println "DEBUG: Error executing 'ollama list':" (.getMessage e))
      [])))

(defrecord Gemini [model-name]
  Provider
  (request [this prompt]
    (println "in gemini")
    (println model-name)
    (some-> (format "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" model-name gemini-api-key)
            (http/post {:headers {"Content-Type" "application/json"}
                        :body    (json/generate-string {:contents [{:parts [{:text prompt}]}]})
                        :throw false})
            http-error-handler!
            (get-in [:candidates 0 :content :parts 0 :text])
            str/trim))
  (models [this] [ (->Gemini "gemini-3.8-flash") 
                  (->Gemini "gemini-3.5-flash-lite")
                  (->Gemini "gemini-3.6-flash") 
                  (->Gemini "gemini-3-flash-preview") ; slow
                  ])
  (get-model [this] (or model-name "gemini-3.5-flash")))
  ;(get-model [this] (or model-name "gemini-3.5-flash-lite")))

(defrecord Ollama [model-name]
  Provider
  (request [this prompt]
    (some-> (str api-host "/api/generate")
            (http/post {:body  (json/generate-string {:model model-name, :prompt prompt, :stream false :think false})
                        :throw false})
            http-error-handler!
            :response
            str/trim))
  (models [this]
    (let [cli-models (ollama-list-models)]
      (if (seq cli-models)
        (mapv ->Ollama cli-models)
        (try
          (as-> (str api-host "/api/tags") p
                (http/get p {:throw false})
                (:body p)
                (json/parse-string p true)
                (:models p)
                (map :name p)
                (mapv (fn [m] (->Ollama m)) p))
          (catch Exception e
            (println "DEBUG: Ollama not available:" (.getMessage e))
            [])))))
  (get-model [this]
    (or model-name
      (if-let [env (System/getenv "AI_MODEL")]
        env
        "llama3:latest"))))

; (def default-model (->Gemini "gemini-3.5-flash-lite"))
(def default-model (->Gemini (get-model (->Gemini nil))))

(defn- rofi-model-list []
  (let [models (concat (models (->Gemini nil)) (models (->Ollama nil)))
        selected (-> models
                     (->> (map #(:model-name %)))
                     (rofi-menu! {:prompt "Select model", :format \i})
                     :out
                     first)]
    (if selected
      (nth models (parse-long selected))
      (System/exit 0))))

;;pobiera z mojej listy  api, nie można podać jedynie nazwy bo używam protocol, trzeba by dać parametr z providerem
(defn- create-model [model-name]
  (if-let [model (->> (concat (models (->Gemini nil)) (models (->Ollama nil)))
                      (filter #(= model-name (:model-name %)))
                      first)]
    model
    (notify-error! (str "Wrong model name: " model-name) true)))

(defn- query-ai [prompt opts]
  {:pre  [(is (string? prompt))]}
  (let [{:keys [model list]} opts ]
    (match [model list]
           [(m :guard some?) _] (request (create-model m) prompt)
           [nil true] (request (rofi-model-list) prompt)
           :else (request default-model prompt))))

(defn- fetch-page [url]
  (let [{:keys [exit out]} (sh "go-readability" "--text" url)]

    (if (zero? exit)
      out
      (notify-error! (str "Fetching html from page " url) true))))

; for rdrview
; (defn- html->txt [url]
;   (let [{:keys [exit out]} (sh {:in (fetch-page-html url)} "pandoc" "--from" "html" "--to" "plain" "--output" "-")]
;     (if (zero? exit)
;       out
;       (notify-error! (str "Converting html to text " url) true))))

(defn- get-text [opts]
  (cond
    (:url opts) (fetch-page (:url opts))
    (:primary opts) (:out (sh "clipcat.clj primary"))
    ; (:primary opts) (:out (sh "clipster --output -m '' --primary"))
    (:input opts) (:input opts)
    :else (:out (sh "clipcat.clj clip"))))
    ; :else (:out (sh "clipster --output -m '' --clipboard"))))

(defn- display-ai-response [response opts]
  (create-dir! response-dir)
  (let [file (.toString (fs/create-temp-file {:dir response-dir :prefix "chat-" :suffix ".adoc"}))]
    (spit file response)
    (case (:output opts)
      :scratchpad (scratchpad! file)
      :dialog (dialog! response)
      (println response))))

(defn- query->display [prompt opts]
  (-> prompt
      (query-ai opts)
      (display-ai-response opts)))

(defn- ask
  "Query AI with provided input."
  [args]
  (let [{:keys [dispatch opts]} args
        has-text-source (or (:clip opts) (:primary opts) (:url opts))]
    (println opts)
    (cond
      (:input opts) (query->display (str prompt-prefix (:input opts)) opts)
      has-text-source (query->display (str (prompt-input) analyze-text-prompt (get-text opts)) opts)
      :else (query->display (str prompt-prefix (prompt-input)) opts))))

(defn- action
  "Query AI where prompt is based on a template."
  [{opts :opts}]
  (let [{:keys [action-list template]} opts]
    (match [action-list template]
           [true _] (query->display (str (select-template) (get-text opts)) opts)
           [nil :summary] (query->display (str (:summary templates) (get-text opts)) opts)
           [nil t] (query->display (str (t templates) (get-text opts)) opts))))

(defn- provider-type-name [model]
  (or (last (str/split (str (type model)) #"\.")) "Unknown"))

(defn- resolve-provider-models
  "Returns a list of model records for the given provider.
   Defaults to Ollama models if provider is nil or not specified."
  [provider]
  (cond
    (satisfies? Provider provider)
    (models provider)

    (or (nil? provider) (str/blank? (str provider)))
    (models (->Ollama nil))

    :else
    (let [p (str/lower-case (name provider))]
      (case p
        "ollama" (models (->Ollama nil))
        "gemini" (models (->Gemini nil))
        "all"    (concat (models (->Ollama nil)) (models (->Gemini nil)))
        (do
          (println (format "Unknown provider '%s', defaulting to ollama" provider))
          (models (->Ollama nil)))))))

(def default-test-instruction "Respond with OK if you can read this.")

(defn test-models
  "Test AI models per provider with a given instruction."
  ([]
   (test-models nil default-test-instruction nil))
  ([arg]
   (cond
     (map? arg)
     (let [opts (or (:opts arg) arg)
           args-list (:args arg)
           provider (or (:provider opts) (:p opts))
           instruction (or (:instruction opts)
                           (:i opts)
                           (:input opts)
                           (first args-list)
                           default-test-instruction)]
       (test-models provider instruction opts))

     (or (keyword? arg)
         (satisfies? Provider arg)
         (and (string? arg) (contains? #{"ollama" "gemini" "all"} (str/lower-case arg))))
     (test-models arg default-test-instruction nil)

     :else
     (test-models nil arg nil)))
  ([provider instruction]
   (test-models provider instruction nil))
  ([provider instruction opts]
   (let [instruction (or instruction default-test-instruction)
         target-models (let [ms (resolve-provider-models provider)]
                         (if-let [filter-name (or (:model opts) (:m opts))]
                           (filter #(= filter-name (:model-name %)) ms)
                           ms))
         total (count target-models)]
     (println "==================================================")
     (println (format "Testing models (total: %d)" total))
     (println (format "Provider:    %s" (or provider "ollama (default)")))
     (println (format "Instruction: %s" instruction))
     (println "==================================================")
     (if (zero? total)
       (do
         (println "No models found to test.")
         [])
       ;; ollama returns token/sec in json, but gemini doesn't 
       (let [results (mapv
                      (fn [idx model]
                        (let [m-name (:model-name model)
                              p-name (provider-type-name model)]
                          (printf "\n[%d/%d] Testing %s (%s)...\n" (inc idx) total m-name p-name)
                          (flush)
                          (let [start-time (System/currentTimeMillis)]
                            (try
                              (let [res (request model instruction)
                                    dur (- (System/currentTimeMillis) start-time)]
                                (if (some? res)
                                  (do
                                    (printf "✓ OK (%d ms)\n" dur)
                                    (println "Response:")
                                    (println res)
                                    (println "--------------------------------------------------")
                                    {:model m-name :provider p-name :status :ok :duration-ms dur :response res})
                                  (do
                                    (printf "✗ FAILED (%d ms) - no response received\n" dur)
                                    (println "--------------------------------------------------")
                                    {:model m-name :provider p-name :status :error :duration-ms dur :error "No response"})))
                              (catch Exception e
                                (let [dur (- (System/currentTimeMillis) start-time)]
                                  (printf "✗ FAILED (%d ms) - %s\n" dur (.getMessage e))
                                  (println "--------------------------------------------------")
                                  {:model m-name :provider p-name :status :error :duration-ms dur :error (.getMessage e)}))))))
                      (range)
                      target-models)
             passed (count (filter #(= :ok (:status %)) results))
             failed (- total passed)]
         (println "\n==================== Summary ====================")
         (doseq [{:keys [model provider status duration-ms error]} results]
           (if (= :ok status)
             (printf "  [✓ OK]     %-35s (%s, %d ms)\n" model provider duration-ms)
             (printf "  [✗ FAILED] %-35s (%s, %d ms) - %s\n" model provider duration-ms (or error "Error"))))
         (println "=================================================")
         (printf "Total: %d | Passed: %d | Failed: %d\n\n" total passed failed)
         results)))))

(def test-models-per-provider test-models)

(def spec
  {:output {:desc     "Show AI answer in a text editor or a dialog [scratchpad | dialog]. Generated text is always saved in `tmp` folder"
            :coerce   :keyword
            :validate {:pred   #(contains? #{:scratchpad :dialog} %)
                       :ex-msg (fn [m] (str "Use one of those [scratchpad | dialog]. Provided not valid value for the :output: " (:value m)))}
            :alias    :o}
   :list   {:desc   "Choose an available model."
            :coerce :boolean
            :alias  :l}
   :model  {:desc  "Provide model name that you want to use."
            :alias :m}})

(def spec-source
  {:clip    {:desc   "Analyse text from clipboard - default."
             :coerce :boolean
             :alias  :c}
   :primary {:desc   "Analyse text from primary clipboard."
             :coerce :boolean
             :alias  :p}
   :input   {:desc  "Analyse text from terminal argument."
             :alias :i}
   :url     {:desc     "Analyse text from a web page."
             :validate {:pred url? :ex-msg (fn [m] (str "Not a url: " (:value m)))}
             :alias    :u}})

(def spec-template
  {:template    {:desc         "Analyse text from primary clipboard."
                 :coerce       :keyword
                 :default      :summary
                 :default-desc "Default: Summary text."
                 :alias        :t}
   :action-list {:desc   "Choose from available actions via a rofi menu."
                 :coerce :boolean
                 :alias  :a}
   ;; maybe add a config file for templates when I need more customisation like model, temperature, language in a json or edn file
   ;:template-file {:desc     "Analyse text from clipboard - default."
   ;                :default  (str (System/getenv "XDG_CONFIG_HOME") "/chat/template.properties")
   ;:coerce   :symbol
   ;:validate #((fs/regular-file? %))
   ;:alias    :f}
   })

(def spec-test
  {:provider    {:desc    "Provider to test [ollama | gemini | all] (default: ollama)."
                 :default "ollama"
                 :alias   :p}
   :instruction {:desc    "Instruction to send to each model (default: 'Respond with OK if you can read this.')."
                 :alias   :i}
   :model       {:desc    "Optionally test a specific model name only."
                 :alias   :m}})

(defn- print-help [_]
  (printf "Chat AI. An helper for interact with ollama. %n%s%s%n
  Options for `action` and `text` commands:%n%s%n
  Additional options for `action` command:%n%s%n
  Options for `test` command:%n%s%n
  Examples:
     chat.clj ask -l
     chat.clj text -i 'tell me a joke'
     chat.clj text -p -o display
     chat.clj action -p -a
     chat.clj action -o scratchpad -t 'summary-adoc' -u='https://en.wikipedia.org/wiki/Polish_hussars'
     chat.clj test
     chat.clj test -i 'Say hello in 5 words'
     chat.clj test -p gemini -i 'Tell me a joke'
     chat.clj test -p all
  %nDefault values can be override via system environment. The set values:
  default model = %s
  OLLAMA_API_HOST = %s
  TERM_LT and TERM_LT_RUN = %s
  %nDependencies:
   - ollama, clipcat, rofi
   - optional for `url` flag: go-readability, pandoc
   - optional for `scratchpad`: nvim "
          (format-cmds! subcommands)
          (cli/format-opts {:spec spec})
          (cli/format-opts {:spec spec-source})
          (cli/format-opts {:spec spec-template})
          (cli/format-opts {:spec spec-test})
          (:model-name default-model)
          api-host term-run))

(def subcommands
  [{:cmds ["ask"] :desc "Ask AI." :fn ask :spec spec}
   {:cmds ["text"] :desc "Ask about provided text." :fn ask :spec (merge spec spec-source)}
   {:cmds ["action"] :desc "Take an action from a template. If not provided text will be summarised."
    :fn   action :spec (merge spec spec-source spec-template)}
   {:cmds ["test"] :desc "Test models per provider with an instruction."
    :fn   test-models :spec spec-test}
   {:cmds [] :desc "Show help." :fn print-help}])

(when (= *file* (System/getProperty "babashka.file"))
  (cli/dispatch subcommands *command-line-args*))

(comment

  (deps/add-deps '{:deps {philoskim/debux {:mvn/version "0.9.1"}}})
  (require '[debux.core :refer :all])

  (require '[babashka.deps :as deps])
  (deps/add-deps '{:deps {djblue/portal {:mvn/version "0.58.1"}}})
  (require '[portal.api :as p])
  (add-tap #'p/submit)
  (def p (p/open {:launcher :intellij}))
  (tap> :hello)
  (load-file (str (System/getenv "HOME") "/Documents/dotfiles/common/scripts/.bin/clj/init.clj"))

  (deps/add-deps '{:deps {io.github.paintparty/fireworks {:mvn/version "0.10.4"}}})
  (require '[fireworks.core :refer [? !? ?> !?>]])
  )

(comment
  (cli/dispatch subcommands ["help"])
  (cli/dispatch subcommands ["ask"])
  (cli/dispatch subcommands ["ask" "-o" "dialog"])
  (cli/dispatch subcommands ["ask" "-o" "scratchpad"])
  (cli/dispatch subcommands ["ask" "-l"])
  (cli/dispatch subcommands ["text"])
  (cli/dispatch subcommands ["text" "-i" "what is 1+1" "-o" "dialog" "-l"])
  (cli/dispatch subcommands ["text" "-i" "what is 1+1" "-o" "dialog" "-m" "gemini-3-flash-preview"])
  (def wiki "https://pl.wikipedia.org/wiki/Prawo_natury")
  (cli/dispatch subcommands ["text" "-u" wiki "-l"])
  (cli/dispatch subcommands ["action"])
  (cli/dispatch subcommands ["action" "-o" "dialog" "-a"]) ; from clipboard
  (cli/dispatch subcommands ["action" "-o" "dialog" "-t" "translate-to-english" "-i" "Ala ma kota"])
  (cli/dispatch subcommands ["action" "-o" "dialog" "-u" "yt" "args" "llama"]) ; fail
  (cli/dispatch subcommands ["action" "-o" "dialog" "-u" wiki "-a"])
  (cli/dispatch subcommands ["action" "-o" "dialog" "-u" "https://sklep.galakta.pl/gry-planszowe/1438-filary-ziemi.html"])

  (test-models)
  (test-models "Say hello in 3 words")
  (test-models :ollama "Tell a joke")
  (test-models :gemini "Say OK")
  (test-models :all "Say OK")
  (cli/dispatch subcommands ["test"])
  (cli/dispatch subcommands ["test" "-i" "Say hello"])
  (cli/dispatch subcommands ["test" "-p" "gemini" "-i" "Say OK"])

  (html->txt "https://sklep.galakta.pl/gry-planszowe/1438-filary-ziemi.html")
  (def invalid-url "https://slep.galakta.pl/gry-planszowe/1438-filary-ziemi.html")
  (fetch-page-html invalid-url)
  (get-properties! "/home/miro/t.pro")
  (str (url? "https://search.brave.com/search"))
  (str (url? "www.brave.com/search"))
  (rofi-menu! (concat (models (->Gemini nil)) (models (->Ollama nil))) {:prompt "Select model"})
  )


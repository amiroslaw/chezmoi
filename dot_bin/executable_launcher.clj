#!/usr/bin/env bb
(require '[babashka.cli :as cli]
         '[babashka.classpath :as cp])
(cp/add-classpath (str (System/getenv "HOME") "/.bin/clj"))
(require '[util-media :as util])
;; TODO
;; maybe split into - scripts; rofi? or based on taks: system
; move launcher in hyprland
; maybe store cheatsheets in navi navi --tag-rules='OS'
(def HOME (or (System/getenv "HOME") "~/"))
(def CONFIG (or (System/getenv "XDG_CONFIG_HOME") "~/.config/"))
(def VIDEOS (or (System/getenv "XDG_VIDEOS_DIR") "~/Videos/"))
(def ROFI (or (System/getenv "ROFI") (str CONFIG "/rofi")))

(defn- scratchpad [title cmd]
  (format "scratchpad.clj -n %s %s" (name title) cmd))

(def duplicated {
  ;; TODO test
   :taskwarrior-tui { :abbr :tui :title :taskwarrior-tui :desc "taskwarrior-tui" :cmd ["task sync" (scratchpad :task (util/term-lt-app :task "taskwarrior-tui"))]}
  :task-add { :abbr :task :title :task-add :desc "add task to inbox" :cmd "todo.lua add" }
  :selection-paste { :abbr :sp :title :selection-paste :desc "selection paste" :cmd "clipcat.clj primary --paste"}
  :local-videos { :abbr :video :title :local-videos :desc "local videos" :cmd (str "setsid mpv.lua -o" VIDEOS)}
  :local-playlist { :abbr :lpl :title :local-playlist :desc "local video playlist" :cmd "setsid mpv.lua -o"}})

;; TODO I could do T istead of buld: :Kb instead of :bk, it would need `-case-sensitive`
(def cheatsheets {
:clip  [
  {:abbr :cl :title :clipboard-list :desc "clipboard list" :cmd "clipcat.clj menu --paste"}
  (:selection-paste duplicated)
  {:abbr :jc :title :join :desc "join" :cmd "clipcat.clj join --input"}
  {:abbr :rc :title :remove-item-clipboard :desc "remove item from clipboard" :cmd "clipcat-menu remove"}
  {:abbr :pc :title :previous-item-clipboard :desc "previous item from clipboard" :cmd "clipcat.clj clip --previous --paste"}
  {:abbr :nc :title :note-clipboard :desc "note from clipboard" :cmd "note.lua clip 1" }
  {:abbr :np :title :note-selection :desc "note from selection" :cmd  "note.lua sel 1"}
  {:abbr :ni :title :input-number-copied :desc "input for the number of copied elements" :cmd "note.lua clip" }
  {:abbr :nw :title :write-note :desc "write note" :cmd "note.lua write"} ]
	;;e "bash -c "clipcat-menu edit"" ;; not useful, also it doesn't work
:AI [
  {:abbr :qa :title :ask-question :desc "ask question" :cmd "chat.clj ask -o scratchpad" }
  {:abbr :ca :title :ask-about-copiet :desc "ask about copiet text" :cmd "chat.clj text -o scratchpad" }
  {:abbr :sa :title :ask-about-selected :desc "ask about selected text" :cmd "chat.clj text -o scratchpad --primary" }
  {:abbr :me :title :action-menu :desc "action menu" :cmd "chat.clj action -o scratchpad --action-list" }
  {:abbr :gr :title :grammar :desc "grammar" :cmd "chat.clj action -o scratchpad -t grammar" }
  {:abbr :eg :title :grammar-explain :desc "grammar explain" :cmd "chat.clj action -o scratchpad -t grammar-explain" }
  {:abbr :tp :title :translate-polish :desc "translate to polish" :cmd "chat.clj action -o scratchpad -t translate-to-polish" }
  {:abbr :te :title :translate-english :desc "translate to english" :cmd "chat.clj action -o scratchpad -t translate-to-english" } 
  {:abbr :sa :title :summary-adoc :desc "summary in adoc" :cmd "chat.clj action -o scratchpad -t summary-adoc" }
  {:abbr :ss :title :short-summary :desc "short summary" :cmd "chat.clj action -o scratchpad -t summary-short" } ] 
:media [
  (:local-playlist duplicated)
  {:abbr :nv :title :newsboat-videos :desc "newsboat videos" :cmd "db-search.clj --newsboat"}
  {:abbr :qv :title :qutebrowser-videos :desc "qutebrowser videos" :cmd "db-search.clj --qutebrowser"}
  {:abbr :video :title :local-videos :desc "local videos" :cmd (str "setsid mpv.lua -o " VIDEOS)}
  {:abbr :mpvs :title :slow-yt-search :desc "slow yt search" :cmd "mpv.lua -y"}
  {:abbr :syt :title :yt-search :desc "yt search" :cmd "yt.clj search --input"}
  {:abbr :cs :title :yt-search-clipboard :desc "yt search from clipboard" :cmd "yt.clj --clip"}
  {:abbr :ytpl :title :yt-channels :desc "yt channels" :cmd "yt.clj playlist --channel"} 
  {:abbr :rmmpd :title :remove-mpd :desc "remove a song that is playing" :cmd "rmrmpc-playing"}
  {:abbr :rmmpv :title :remove-mpv :desc "remove a video that is playing" :cmd "rmmpv-playing"}
  ]
:task [
  { :abbr :upd :title :update-taskwarrior :desc "update taskwarrior" :cmd "task sync" }
  { :abbr :pom :title :pomodoro-add :desc "start pomodoro" :cmd ["task sync" "pomodoro.lua add -n"] }
  { :abbr :at :title :task-add :desc "add task" :cmd "todo.lua add" }
  { :abbr :yl :title :show-taskwarrior-list :desc "show taskwarrior list in yad" :cmd "todo.lua show" }
  { :abbr :rp :title :pomodoro-repeat :desc "pomodoro repeat" :cmd "pomodoro.lua repeat -n" }
  { :abbr :pp :title :pomodoro-pause :desc "pomodoro pause" :cmd "pomodoro.lua pause -n" }
  { :abbr :mp :title :pomodoro-modify :desc "pomodoro modify" :cmd "pomodoro.lua modify" }
  { :abbr :sp :title :pomodoro-stop :desc "pomodoro stop" :cmd ["pomodoro.lua stop -n" "task sync"] }
  { :abbr :lp :title :pomodoro-menu :desc "pomodoro list menu" :cmd "pomodoro.lua menu -n" }
  { :abbr :np :title :pomodoro-notify :desc "pomodoro notify" :cmd "pomodoro.lua notify" }
  { :abbr :gry :title :grywalizacja :desc "grywalizacja" :cmd "java -jar ~/.local/bin/grywalizacja.jar" }
  { :abbr :cadd :title :gcal-add :desc "gcal add" :cmd "gcal-add.lua" }
  { :abbr :cshow :title :gcal-show :desc "gcal show" :cmd "gcal-show.sh" }
  { :abbr :cagenda :title :gcal-show-agenda :desc "gcal show agenda" :cmd "gcalcli --nocolor agenda --config-folder='/home/miro/.config/gcalcli'  | zenity --text-info" }
  (:taskwarrior-tui duplicated)
  (:task-add duplicated)
  { :abbr :fx :title :timefx :desc "timefx" :cmd "timefx" }]
:url [
  { :abbr :meurl :title :menu :desc "menu" :cmd "url.lua --menu --input"}
  { :abbr :rsvp :title :rsvp-reading-fast :desc "rsvp for reading fast" :cmd "url.lua --speed -n 1"}
  { :abbr :txt :title :conver-website-text :desc "conver a website to a text note" :cmd "url.lua --read -n 1"}
  { :abbr :kin :title :kindle :desc "kindle" :cmd "url.lua --kindle --email -n 1"}
  { :abbr :bkin :title :kindle-bulk :desc "kindle bulk" :cmd "url.lua --kindle --email -n 10"}
  { :abbr :mt :title :konvert-mega-torrent :desc "konvert mega to a torrent file" :cmd "url.lua --tor -n 1"}
  { :abbr :bmt :title :mega-tor-bulk :desc "konvert mega to a torrent file - bulk" :cmd "url.lua --tor -n 10"}
  { :abbr :fv :title :open-mpv-fullscreen :desc "open mpv fullscreen" :cmd "url.lua --mpvFullscreen -n 1"}
  { :abbr :bf :title :mpv-fs-bulk :desc "open mpv fullscreen bulk" :cmd "url.lua --mpvFullscreen -n 10"}
  { :abbr :ad :title :download-audio :desc "download audio" :cmd "url.lua --dlAudio -n 1"}
  { :abbr :bad :title :download-audio-bulk :desc "download audio - bulk" :cmd "url.lua --dlAudio -n 10"}
  { :abbr :gd :title :download-picture-gallery :desc "download picture gallery" :cmd "url.lua --gallery -n 1"}
  { :abbr :bgd :title :gallery-bulk :desc "download picture gallery - bulk" :cmd "url.lua --gallery -n 10"}
  { :abbr :vd :title :download-video :desc "download video" :cmd "url.lua --dlVideo -n 1"}
  { :abbr :bvd :title :download-video-bulk :desc "download video - bulk"   :cmd "url.lua --dlVideo -n 10"}
  { :abbr :wd :title :wget-download :desc "wget download" :cmd "url.lua --wget -n 1"}
  { :abbr :bwd :title :wget-bulk :desc "wget download" :cmd "url.lua --wget -n 10"} ]
:open [ ;; add more 
  { :abbr :opm :title :search-menu :desc "search menu" :cmd "search.lua --menu -input" }
  { :abbr :ops :title :search-menu-selection :desc "search menu selection" :cmd "search.lua --menu -p" }
  { :abbr :opc :title :search-menu-clip :desc "search menu clip" :cmd "search.lua --menu -c" }
  { :abbr :gso :title :google-selection :desc "google selection" :cmd "search.lua --google -p" }
  { :abbr :gco :title :google-clip :desc "google clip" :cmd "search.lua --google -c" }
  { :abbr :yso :title :yt-selection :desc "yt selection" :cmd "search.lua --yt -p" }
  { :abbr :yco :title :yt-clip :desc "yt clip" :cmd "search.lua --yt -c" }
  { :abbr :mso :title :map-selection :desc "map selection" :cmd "search.lua --maps -p" }
  { :abbr :mco :title :map-clip :desc "map clip" :cmd "search.lua --maps -c" }
  { :abbr :cio :title :cheat-input :desc "cheat input" :cmd "search.lua --cheat --input" }
  { :abbr :cso :title :cheat-selection :desc "cheat selection" :cmd "search.lua --cheat -p" }
  { :abbr :cco :title :cheat-clip :desc "cheat clip" :cmd "search.lua --cheat -c" } 
  { :abbr :wso :title :wiki-selection :desc "wiki selection" :cmd "search.lua --wiki -p" }
  { :abbr :wco :title :wiki-clip :desc "wiki clip" :cmd "search.lua --wiki -c" } ]
:translate [ ;; move from AI to this?
  { :abbr :ment :title :menu-trans :desc "menu translate" :cmd (str ROFI "/tran/trans-launcher.sh")}
  { :abbr :dso :title :diki-selection :desc "diki selection" :cmd "search.lua --diki -p" }
  { :abbr :dco :title :diki-clip :desc "diki clip" :cmd "search.lua --diki -c" }
  { :abbr :lso :title :deepl-selection :desc "deepl selection" :cmd "search.lua --deepl -p" }
  { :abbr :lco :title :deepl-clip :desc "deepl clip" :cmd "search.lua --deepl -c" }
  { :abbr :tso :title :translator-google-selection :desc "translator google selection" :cmd "search.lua --translator -p" } 
  { :abbr :tco :title :translator-google-clip :desc "translator google clip" :cmd "search.lua --translator -c" }
  { :abbr :enso :title :plen-trans-selection :desc "plen trans selection" :cmd "search.lua --plen -p" }
  { :abbr :enco :title :plen-trans-clip :desc "plen trans clip" :cmd "search.lua --plen -c" }
  { :abbr :plso :title :enpl-trans-selection :desc "enpl trans selection" :cmd "search.lua --enpl -p" }
  { :abbr :plco :title :enpl-trans-clip :desc "enpl trans clip" :cmd "search.lua --enpl -c" } ]
:apps [
       ;; chyba przenieść do hyprland, co z keychord?
  { :abbr :mnus :title :scripts :desc "list scripts" :cmd "sh -c 'ls ~/.bin | rofi -dmenu'" }
  { :abbr :music :title :music :desc "music player" :cmd (scratchpad :music (util/term-lt-app :music "rmpc"))}
  { :abbr :pueue :title :pueue-menu :desc "pueue menu" :cmd "qu.clj menu" }
  { :abbr :qbro :title :qutebrowser :desc "qutebrowser" :cmd "$XDG_CONFIG_HOME/qutebrowser/userscripts/session.sh" }
  { :abbr :qbroapp :title :qutebrowser-apps :desc "qutebrowser webapp" :cmd "$XDG_CONFIG_HOME/qutebrowser/userscripts/session.sh webapp" }
  { :abbr :brave :title :brave-browser :desc "brave browser" :cmd  "brave-browser --password-store=basic --args --disable-gpu --profile-directory='Default'" }
  { :abbr :borigin :title :brave-origin-browser :desc "brave origin browser" :cmd  "brave-origin --password-store=basic --args --disable-gpu --profile-directory='Default'" }
  { :abbr :note :title :notebook :desc "notebook" :cmd (format "wezterm start --class note --cwd '%s' -- nvim" (System/getenv "NOTE")) }
  ;; TODO veirfy if with keyword it will work
  { :abbr :rmr :title :restore-trash :desc "restore from trash" :cmd (util/term-lt-app :trash "gomi --restore") }
  { :abbr :fm :title :vifm :desc "vifm" :cmd (util/term-lt-app :vifm "vifm") }
  { :abbr :news :title :newsboat :desc "newsboat" :cmd (scratchpad :news (util/term-app :news "newsboat")) }
  { :abbr :drop :title :dropdown-terminal :desc "dropdown terminal" :cmd (scratchpad :drop (util/term-app :drop "")) }
  { :abbr :chat :title :nchat :desc "nchat" :cmd (scratchpad :chat (util/term-app "chat" "nchat")) }
  { :abbr :off :title :power-menu :desc "power menu" :cmd (format "rofi -show power-menu -modi power-menu:%s/power.sh" ROFI) }
  { :abbr :kee :title :keepassxc :desc "KeePassXC" :cmd "keecli.sh" }
  { :abbr :at :title :audio-toggle :desc "audio toggle" :cmd "audio.clj toggle" }
  { :abbr :am :title :audio-menu :desc "audio menu" :cmd "audio.clj menu" }
  { :abbr :idea :title :intellij :desc "intellij idea" :cmd "setsid /home/miro/Ext/idea-IU-233.14015.106/bin/idea.sh" }
  { :abbr :btop :title :top :desc "system monitor btop" :cmd (util/term-lt-app :top "btop")}
  (:taskwarrior-tui duplicated)
  (:task-add duplicated)
  (:selection-paste duplicated)
  (:local-playlist duplicated)
  (:local-videos duplicated)]
})

(defn- create-menu
  "Build rofi menu map from cheatsheets."
  ([]
   (let [all (for [[group cheats] cheatsheets
                   {:keys [abbr desc title] :as cheat} cheats]
               {:cheat cheat :item (format "%s - (%s) %s" (name abbr) group desc)})]
     {:cheats (mapv :cheat all)
      :menu   (mapv :item all)}))
  ([group]
   (let [cheats (get cheatsheets (keyword group))]
     {:cheats cheats
      :menu   (mapv #(format "%s - %s" (name (:abbr %)) (:desc %)) cheats)})))

(defn- exec-cmd
  "Execute a single command string or a vector of commands sequentially."
  [cmd]
  (println "exec-cmd:")
  (println cmd)
  (cond
    (string? cmd) (ps-error-handler! false cmd) ;; TODO change to true 
    (vector? cmd) (doseq [c cmd]
                    (ps-error-handler! false c))
    :else (notify-error! (format "could not execute %s" cmd) true)))

(defn run
  "Execute the first cheatsheet whose `:title` matches the given CLI argument."
  [cli-arg]
  (-> (for [[_ cheats] cheatsheets
           {:keys [title cmd]} cheats
        :when (= (keyword cli-arg)  title)]
      cmd)
      first
      exec-cmd))

(defn- run-rofi
  "Present a rofi menu."
  [{:keys [cheats menu]}]
  (let [prompt (format "Launcher (%s)" (count menu))
        {:keys [out exit]} (rofi-menu! menu {:prompt prompt, :width "500px", :matching "regex", :filter "^" :format \i, :auto-select true, :no-custom true :msg "Delete '^' for exploring"})]
    (if exit
      (->> out
           first
           parse-long
           (get cheats)
           :cmd
          exec-cmd)
      (System/exit 0)
      ; (println "exit ok")
      )))

(defn group-list 
  "List all groups"
  []
  (doseq [[group cheats] cheatsheets]
    (println (format "%s with elements %s" group (count cheats)))))

(def spec {:spec
           {:all {:alias :a :desc  "List all cheatsheets"}
            :group    {:alias :g :desc  "List cheatsheets group"}
            :cheat    {:alias :c :desc  "Execute a cheatsheet"}
            :list    {:alias :l :desc  "List groups"}
            :help        {:alias :h :desc "Print this help"}}})

(defn- print-help []
  (printf "A script for listing and executing applications or scripts.
  Options:%n%s
  %nSystem environment for running a terminal app:
  TERM_LT and TERM_LT_RUN = %s %s
  TERMINAL and TERM_RUN = %s %s
  %nDependencies:
   - quetebrowser, newsbout, rofi, mpv, pueue, and many more"
          (cli/format-opts spec)
          util/TERM_LT util/TERM_LT_RUN
          util/TERMINAL util/TERM_RUN))
(defn- cli
  "Dispatch CLI arguments to the appropriate handler."
  [opts]
  (cond
    (opts :all)   (run-rofi (create-menu))
    (opts :group) (run-rofi (create-menu (:group opts)))
    (opts :cheat) (run (:cheat opts))
    (opts :list) (group-list)
    (opts :help)  (print-help)
    :else         (print-help)))

(cli (cli/parse-opts *command-line-args* spec))

(comment
(run-rofi (create-menu))
(run :qutebrowser-videos)
(run :task-add) ; duplicated

  )


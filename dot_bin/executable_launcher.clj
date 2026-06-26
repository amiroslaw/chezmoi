#!/usr/bin/env bb

;; TODO
; add group flag
; maybe store cheatsheets in navi navi --tag-rules='OS'

(def terminal  (or (System/getenv "TERMINAL")    "wezterm"))
(def term-run  (or (System/getenv "TERM_RUN")    "-- '%s'"))
(def term-lt   (or (System/getenv "TERM_LT")     "foot"))
(def term-lt-run (or (System/getenv "TERM_LT_RUN") "-e '%s'"))
(def HOME (or (System/getenv "HOME") "~/"))
(def CONFIG (or (System/getenv "XDG_CONFIG_HOME") "~/.config/"))
(def VIDEOS (or (System/getenv "XDG_VIDEOS_DIR") "~/Videos/"))

(defn- term-lt-app [title cmd]
  (format (str term-lt term-lt-run) title cmd))
(defn- term-app [title cmd]
  (format (str terminal term-run) title cmd))
(defn- scratchpad [name cmd]
  (format "scratchpad.clj -n %s %s" name cmd))

;; TODO I could do T istead of buld: :Kb instead of :bk, it would need `-case-sensitive`
(def cheatsheets {
:clip  [
{:abbr :cl :desc "clipboard list" :cmd "clipcat.clj menu --paste"}
{:abbr :sp :desc "selection paste" :cmd "clipcat.clj primary --paste"}
{:abbr :jc :desc "join" :cmd "clipcat.clj join --input"}
{:abbr :rc :desc "remove item from clipboard" :cmd "clipcat-menu remove"}
{:abbr :pc :desc "previous item from clipboard" :cmd "clipcat.clj clip --previous --paste"}
{:abbr :nc :desc "note from clipboard" :cmd "note.lua clip 1" }
{:abbr :np :desc "note from selection" :cmd  "note.lua sel 1"}
{:abbr :ni :desc "input for the number of copied elements" :cmd "note.lua clip" }
{:abbr :nw :desc "write note" :cmd "note.lua write"} ]
	;;e "bash -c "clipcat-menu edit"" ;; not useful, also it doesn't work
:AI [
	{:abbr :qa :desc "ask question" :cmd "chat.clj ask -o scratchpad" }
	{:abbr :ca :desc "ask about copiet text" :cmd "chat.clj text -o scratchpad" }
	{:abbr :sa :desc "ask about selected text" :cmd "chat.clj text -o scratchpad --primary" }
	{:abbr :me :desc "action menu" :cmd "chat.clj action -o scratchpad --action-list" }
	{:abbr :sa :desc "summary in adoc" :cmd "chat.clj action -o scratchpad -t summary-adoc" }
	{:abbr :ss :desc "short summary" :cmd "chat.clj action -o scratchpad -t summary-short" }
	{:abbr :gr :desc "grammar" :cmd "chat.clj action -o scratchpad -t grammar" }
	{:abbr :eg :desc "grammar explain" :cmd "chat.clj action -o scratchpad -t grammar-explain" }
	{:abbr :tp :desc "translate to polish" :cmd "chat.clj action -o scratchpad -t translate-to-polish" }
	{:abbr :te :desc "translate to english" :cmd "chat.clj action -o scratchpad -t translate-to-english" } ]
:media [
  {:abbr :yt :desc "yt playlist" :cmd "setsid mpv.lua -o"}
  {:abbr :nv :desc "newsboat videos" :cmd "db-search.clj --newsboat"}
  {:abbr :qv :desc "qutebrowser videos" :cmd "db-search.clj --qutebrowser"}
  {:abbr :video :desc "local videos" :cmd (str "setsid mpv.lua -o" VIDEOS)}
  {:abbr :s :desc "slow yt search" :cmd "mpv.lua -y"}
  {:abbr :syt :desc "yt search" :cmd "yt.clj search --input"}
  {:abbr :c :desc "yt search from clipboard" :cmd "yt.clj --clip"}
  {:abbr :a :desc "yt channels" :cmd "yt.clj playlist --channel"} ]

:task [
  { :abbr :pom :desc "start pomodoro" :cmd "task sync && pomodoro.lua add -n" }
  { :abbr :at :desc "add task" :cmd "todo.lua add" }
  { :abbr :yl :desc "show taskwarrior list in yad" :cmd "todo.lua show" }
	{ :abbr :rp :desc "pomodoro repeat" :cmd "pomodoro.lua repeat -n" }
	{ :abbr :pp :desc "pomodoro pause" :cmd "pomodoro.lua pause -n" }
	{ :abbr :mp :desc "pomodoro modify" :cmd "pomodoro.lua modify" }
	{ :abbr :sp :desc "pomodoro stop" :cmd "pomodoro.lua stop -n && task sync" }
	{ :abbr :lp :desc "pomodoro list menu" :cmd "pomodoro.lua menu -n" }
	{ :abbr :np :desc "pomodoro notify" :cmd "pomodoro.lua notify" }
	{ :abbr :gry :desc "grywalizacja" :cmd "java -jar ~/.local/bin/grywalizacja.jar" }
	{ :abbr :fx :desc "timefx" :cmd "timefx" }
	{ :abbr :cadd :desc "gcal add" :cmd "gcal-add.lua" }
	{ :abbr :cshow :desc "gcal show" :cmd "gcal-show.sh" }
	{ :abbr :cagenda :desc "gcal show agenda" :cmd "gcalcli --nocolor agenda --config-folder='/home/miro/.config/gcalcli'  | zenity --text-info" }
   { :abbr :tui :desc "taskwarrior-tui" :cmd (str "task sync && " (scratchpad :task (term-lt-app "task" "taskwarrior-tui")))} ]
:url [
    {:abbr :mu :desc "menu" :cmd "url.lua --menu --input"}
    {:abbr :s :desc "rsvp for reading fast" :cmd "url.lua --speed -n 1"}
    {:abbr :r :desc "conver a website to a text note" :cmd "url.lua --read -n 1"}
	{ :abbr :k :desc "kindle":cmd "url.lua --kindle --email -n 1"}
    { :abbr :bk :desc "kindle bulk" :cmd "url.lua --kindle --email -n 10"}
	{ :abbr :m :desc "konvert mega to a torrent file" :cmd "url.lua --tor -n 1"}
    { :abbr :bm :desc "konvert mega to a torrent file - bulk" :cmd "url.lua --tor -n 10"}
	{ :abbr :f :desc "open mpv fullscreen" :cmd "url.lua --mpvFullscreen -n 1"}
    { :abbr :bf :desc "open mpv fullscreen bulk" :cmd "url.lua --mpvFullscreen -n 10"}
	{ :abbr :ad :desc "download audio" :cmd "url.lua --dlAudio -n 1"}
    { :abbr :bad :desc "download audio - bulk" :cmd "url.lua --dlAudio -n 10"}
	{ :abbr :gd :desc "download picture gallery" :cmd "url.lua --gallery -n 1"}
    { :abbr :bgd :desc "download picture gallery - bulk" :cmd "url.lua --gallery -n 10"}
	{ :abbr :vd :desc "download video" :cmd "url.lua --dlVideo -n 1"}
    { :abbr :bvd :desc "download video - bulk"   :cmd "url.lua --dlVideo -n 10"}
	{ :abbr :w :desc "wget download" :cmd "url.lua --wget -n 1"}
    { :abbr :bw :desc "wget download" :cmd "url.lua --wget -n 10"} ]
:open [
	; F1 (cmd notify-send search: "(capital-clipboard)\nm-menu input\np-menu primary\nc-menu clip\ng(G)-google\ny(Y)-yt\na(A)-maps\nw(W)-wiki\nd(D)-diki\nl(L)-deepL\nr(R)-translator\np(P)-pl-en trans\nt(T)-en-pl trans\nm(M)-tor\ni-cheatsh input\nk(K)-cheatsh")
	{ :abbr :m :desc "search menu" :cmd "search.lua --menu -input" }
	{ :abbr :p :desc "search menu selection" :cmd "search.lua --menu -p" }
	{ :abbr :c :desc "search menu clip" :cmd "search.lua --menu -c" }
	{ :abbr :g :desc "" :cmd "search.lua --google -p" }
    { :abbr :x :desc "" :cmd "search.lua --google -c" }
	{ :abbr :y :desc "" :cmd "search.lua --yt -p" }
    { :abbr :x :desc "" :cmd "search.lua --yt -c" }
	{ :abbr :a :desc "" :cmd "search.lua --maps -p" }
    { :abbr :x :desc "" :cmd "search.lua --maps -c" }
	{ :abbr :w :desc "" :cmd "search.lua --wiki -p" }
    { :abbr :x :desc "" :cmd "search.lua --wiki -c" }
	{ :abbr :d :desc "" :cmd "search.lua --diki -p" }
    { :abbr :x :desc "" :cmd "search.lua --diki -c" }
	{ :abbr :l :desc "" :cmd "search.lua --deepl -p" }
    { :abbr :x :desc "" :cmd "search.lua --deepl -c" }
	{ :abbr :r :desc "" :cmd "search.lua --translator -p" } 
    { :abbr :x :desc "" :cmd "search.lua --translator -c" }
	{ :abbr :e :desc "" :cmd "search.lua --plen -p" }
    { :abbr :x :desc "" :cmd "search.lua --plen -c" }
	{ :abbr :t :desc "" :cmd "search.lua --enpl -p" }
    { :abbr :x :desc "" :cmd "search.lua --enpl -c" }
	{ :abbr :i :desc "" :cmd "search.lua --cheat --input" }
	{ :abbr :k :desc "" :cmd "search.lua --cheat -p" }
    { :abbr :x :desc "" :cmd "search.lua --cheat -c" }
       ]
:apps [
       ;; chyba przenieść do hyprland, co z keychord?
  { :abbr :qu :desc "" :cmd "qu.clj menu" }
  { :abbr :qb :desc "" :cmd "$XDG_CONFIG_HOME/qutebrowser/userscripts/session.sh" }
  { :abbr :brave :desc "brave browser" :cmd  "brave-browser --password-store=basic --args --disable-gpu --profile-directory='Default'" }
  { :abbr :origin :desc "brave origin browser" :cmd  "brave-origin --password-store=basic --args --disable-gpu --profile-directory='Default'" }
  { :abbr :note :desc "" :cmd (format "wezterm start --class note --cwd '%s' -- nvim" (System/getenv "NOTE")) }
  ;; TODO veirfy if with keyword it will work
  { :abbr :trash :desc "" :cmd (term-lt-app :trash "gomi --restore") }
  { :abbr :vifm :desc "" :cmd (scratchpad :vifm (term-lt-app "vifm" "vifm")) }
  { :abbr :news :desc "" :cmd (scratchpad :news (term-app "news" "newsboat")) }
  { :abbr :quake :desc "" :cmd (scratchpad :drop (term-app "drop" "")) }
  { :abbr :chat :desc "" :cmd (scratchpad :chat (term-app "chat" "nchat")) }
  { :abbr :off :desc "" :cmd "rofi -show power-menu -modi power-menu:$ROFI/power.sh" }
  { :abbr :kee :desc "" :cmd "keecli.sh" }
  { :abbr :audio :desc "" :cmd "audio.clj toggle" }
  { :abbr :audio :desc "" :cmd "audio.clj menu" }
  { :abbr :idea :desc "" :cmd "setsid /home/miro/Ext/idea-IU-233.14015.106/bin/idea.sh" }
  ;; duplicated
  { :abbr :at :desc "add task" :cmd "todo.lua add" }
{:abbr :sp :desc "selection paste" :cmd "clipcat.clj primary --paste"}
  { :abbr :pom :desc "start pomodoro" :cmd "task sync && pomodoro.lua add -n" }
  {:abbr :yt :desc "yt playlist" :cmd "setsid mpv.lua -o"}
   { :abbr :tui :desc "taskwarrior-tui" :cmd (str "task sync && " (scratchpad :task (term-lt-app "task" "taskwarrior-tui")))} 
  {:abbr :video :desc "local videos" :cmd (str "setsid mpv.lua -o" VIDEOS)} ]
})

(defn- item->menu [item]
  {:pre  [(map? item)] :post [(string? %)]}
  (let [abbr (:abbr item)
      desc (:desc item)]
    (format "%s - %s" (name abbr)  desc)))
    ; (format "%s \t %s" abbr (media/trim-col desc))))

(defn- create-menu
  ([]
   (let [all (for [[group cheats] cheatsheets
                   {:keys [abbr desc] :as cheat} cheats]
               {:cheat  cheat :item (format "%s - (%s) %s" (name abbr) group desc)})]
     {:cheats   (mapv :cheat all)
      :menu (mapv :item all)}))
  ([group]
   (let [cheats (get cheatsheets group)]
     {:cheats   cheats
      :menu (mapv #(format "%s - %s" (name (:abbr %)) (:desc %)) cheats)})))

(defn- run-rofi [{:keys [cheats menu]}]
  ; (let [{:keys [cheats menu]} (menu-builder)
  (let [ prompt (format "Launcher (%s)" (count menu))
        {:keys [out exit]} (rofi-menu! menu {:prompt prompt, :width "500px", :matching "regex", :filter "^" :format \i, :auto-select true, :no-custom true :msg "Delete '^' for exploring"})]
    (if exit
      (->> out
           first
           parse-long
           (get cheats)
           :cmd)
      ;; todo
      ; (System/exit 0)
      (println "exit ok")
      )))

(defn- main [opts]
  ; (let [{:keys [cheats menu]} (if (:all opts) (menu-builder) )])
  (let [cmd (if-let [group (:group opts)]
              (run-rofi (create-menu group)) 
              (run-rofi (create-menu))) ]
      (ps-error-handler! false cmd) ;; TODO change to true 
    ))
(main nil)

(comment

(rofi-menu! [":a xxxx kwiat" ":a xxxx bat" "c"] {:prompt "Zmienioe ", :width "504px"
                            :matching "prefix"
  :auto-select true 
  :no-custom true})

(name :aaa)

(rofi-menu! (creat-menu :task) {:prompt "Zmienioe ", :width "504px"
                            :matching "" :format \i :auto-select true :no-custom true})
  )

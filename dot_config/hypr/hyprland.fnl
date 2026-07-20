(local u (require :util))
(local hl _G.hl) ;; removes error in diagnostics 

(let [init-path (.. HOME "/.bin/lua/init.lua")
      (loaded-chunk err) (loadfile init-path)]
  (if loaded-chunk
      (loaded-chunk) 
      (print (.. "Could not load init " (tostring err)))))

;{{{ ENVIRONMENT
;; See https://wiki.hyprland.org/Configuring/Environment-variables/
; toolkit backend
(hl.env "GDK_BACKEND" "wayland,x11,*")
(hl.env "SDL_VIDEODRIVER" "wayland")
(hl.env "CLUTTER_BACKEND" "wayland")
(hl.env "QT_QPA_PLATFORM" "wayland;xcb")
(hl.env "QT_AUTO_SCREEN_SCALE_FACTOR" "1")
(hl.env "QT_QPA_PLATFORMTHEME" "qt6ct")
(hl.env "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1")
(hl.env "XDG_CURRENT_DESKTOP" "Hyprland")
(hl.env "XDG_SESSION_TYPE" "wayland")
(hl.env "XDG_SESSION_DESKTOP" "Hyprland")
(hl.env "XCURSOR_SIZE" "8")
(hl.env "HYPRCURSOR_SIZE" "8")
;; fixes for applications
(hl.env "ANKI_WAYLAND" "1")
(hl.env "WEBKIT_DISABLE_COMPOSITING_MODE" "1")
;}}} 

;{{{ AUTOSTART
(hl.on "hyprland.start"
  (fn []
    (hl.exec_cmd "systemctl --user start hyprland-session.target")
    (hl.exec_cmd "systemctl --user start hyprpolkitagent")
    (hl.exec_cmd "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
; Start a custom session or import target manually (systemd doesn't allow direct starting of graphical-session.target, but importing environment helps systemd recognize the session)
    (hl.exec_cmd "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
; name has to match with the dir name in ~/.local/share/icons/
    (hl.exec_cmd "hyprctl setcursor GoogleDot-cursor 14")
    (hl.exec_cmd "sleep 1 && waybar &")
    (hl.exec_cmd TERMINAL)
    (hl.exec_cmd "$XDG_CONFIG_HOME/hypr/autostart.sh")))

(hl.on "hyprland.shutdown"
  (fn [] (os.execute "systemctl --user stop hyprland-session.target && sleep 0.1")))
;}}} 

;{{{ KEYBINDINGS
; See https://wiki.hyprland.org/Configuring/Keywords/
; Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
; https://www.toptal.com/developers/keycode
; TODO 
; bind = $mainMod, C, centerwindow, 
; bind = $mainMod, P, pin, 

; (map :A (fn [] (notify-error "test2" 4))  "test" )

;; Help / keybindings
(mapCtl :F1 (hl.dsp.exec_cmd (.. CONFIG "/hypr/hypr-keybinds.sh")) "Show keybindings")
(mapSft :F1 (hl.dsp.exec_cmd (.. CONFIG "/hypr/hypr-keybinds.sh --update")) "Show keybindings - update")

;; Terminal
(map :Return (hl.dsp.exec_cmd "wezterm start --always-new-process")  "Open terminal; new process" )
(mapSft :Return (hl.dsp.exec_cmd "wezterm start") "Open terminal")
(mapCtl :Return (hl.dsp.exec_cmd TERM_LT) "Open light terminal")

; Window management
(map :Q (hl.dsp.window.close) "Kill focused window")
(mapSft :Q (hl.dsp.exec_cmd "qu.clj kill-any") "Kill any queue job")
(map :Space (hl.dsp.window.float { :action "toggle" }) "Toggle floating mode")
(map :backslash (hl.dsp.layout "togglesplit") "Toggle split/orientation layout")
(map :F (hl.dsp.window.fullscreen { :mode 1 }) "Fullscreen show bar")
(mapCtl :F (hl.dsp.window.fullscreen { :mode 0 }) "Fullscreen without bar")

;; Focus
(map :U (hl.dsp.focus { :urgent_or_last true }) "Focus urgent or last window")
(map :Tab (hl.dsp.focus {:workspace "previous" }) "Last active workspace")
(hl.bind "ALT + Tab" (hl.dsp.window.cycle_next { :tiled true :floating false }) { :description "Cycle tiled windows on a workspace" })
(hl.bind "CTRL + Tab" (hl.dsp.window.cycle_next { :tiled true :floating true }) { :description "Cycle all windows" })

(local hjkl_binds [ { :key :H :direction :left } { :key :J :direction :down } { :key :K :direction :up } { :key :L :direction :right } ])
(each [_ bind (ipairs hjkl_binds)]
  (map bind.key (hl.dsp.focus { :direction bind.direction }) (.. "Focus " bind.direction))
  (mapCtl bind.key (hl.dsp.window.move { :direction bind.direction}) (.. "Move " bind.direction)))

;; Workspace navigation
(map :N (hl.dsp.focus {:workspace "m+1"}) "Next workspace")
(map :P (hl.dsp.focus {:workspace "m-1"}) "Previous workspace")
;; cycle only empty workspace; for all there is an argument r+1
(mapCtl :N (hl.dsp.focus {:workspace "empty:next"}) "Next empty workspace")
(mapCtl :P (hl.dsp.focus {:workspace "empty:prev"}) "Previous empty workspace")

;; Groups
(map :G (hl.dsp.group.toggle) "Toggle group")
(mapCtl :G (hl.dsp.group.lock_active) "Lock group")
(mapSft :H (hl.dsp.group.prev) "Focus previous in group")
(mapSft :L (hl.dsp.group.next) "Focus next in group")
(mapSft :K (hl.dsp.group.move_window { :forward false }) "Move group backward")
(mapSft :J (hl.dsp.group.move_window { :forward true }) "Move group forward")

;; Workspace switching (numbers)
(for [i 1 10]
  (local key (% i 10))
  (map key (hl.dsp.focus {:workspace i}) (.. "Switch to workspace " i))
  (mapSft key (hl.dsp.window.move { :workspace i }) (.. "Move window to workspace " i)))

;; Move/resize with arrow keys
(map :right (hl.dsp.window.move { :x 10 :y 0 :relative true }) { :description "Move right" :repeating true })
(map :left (hl.dsp.window.move { :x -10 :y 0 :relative true }) { :description "Move left" :repeating true })
(map :down (hl.dsp.window.move { :x 0 :y 10 :relative true }) { :description "Move down" :repeating true })
(map :up (hl.dsp.window.move { :x 0 :y -10 :relative true }) { :description "Move up" :repeating true })
; TODO idk if relative is necessary
(mapCtl :right (hl.dsp.window.resize { :x 10 :y 0 :relative true }) { :description "Resize right" :repeating true })
(mapCtl :left (hl.dsp.window.resize { :x -10 :y 0 :relative true }) { :description "Resize left" :repeating true })
(mapCtl :down (hl.dsp.window.resize { :x 0 :y 10 :relative true }) { :description "Resize down" :repeating true })
(mapCtl :up (hl.dsp.window.resize { :x 0 :y -10 :relative true }) { :description "Resize up" :repeating true })

(map :R u.switch-layout "Switch layout")
(mapCtl :R (hl.dsp.window.center) "Center window")
;; Mouse bindings
;; bindings with SUPER don't work
; right button
(hl.bind "ALT + mouse:273" (hl.dsp.window.resize)  { :mouse true })
; left button
(hl.bind "ALT + mouse:272" (hl.dsp.window.drag { :mouse true :drag true }))
; toggle float
(hl.bind "ALT + mouse:272" (hl.dsp.window.float { :action "toggle" }) { :mouse true :click true })
;; Scroll workspaces
(hl.bind "ALT + mouse_down" (hl.dsp.focus {:workspace "m-1"}))
(hl.bind "ALT + mouse_up" (hl.dsp.focus {:workspace "m+1"}))

;; Volume / Brightness
(map :Equal (hl.dsp.exec_cmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { :description "Volume up" :locked true :repeating true })
(map :Minus (hl.dsp.exec_cmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { :description "Volume down" :locked true :repeating true })
(map :Slash (hl.dsp.exec_cmd "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { :description "Toggle mute" :locked true })
(mapSft :Slash (hl.dsp.exec_cmd "audio.sh toggle") { :description "Toggle headset" :locked true })
(mapCtl :Slash (hl.dsp.exec_cmd "audio.sh") "Manage audio devices")

;; Hardware media keys
(hl.bind "XF86AudioRaiseVolume" (hl.dsp.exec_cmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { :description "Volume up" :locked true :repeating true })
(hl.bind "XF86AudioLowerVolume" (hl.dsp.exec_cmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { :description "Volume down" :locked true :repeating true })
(hl.bind "XF86AudioMute" (hl.dsp.exec_cmd "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { :description "Mute" :locked true })
(hl.bind "XF86AudioMicMute" (hl.dsp.exec_cmd "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") { :description "Mic mute" :locked true })
(hl.bind "XF86MonBrightnessUp" (hl.dsp.exec_cmd "brightnessctl -e4 -n2 set 5%+") { :description "Brightness up" :locked true :repeating true })
(hl.bind "XF86MonBrightnessDown" (hl.dsp.exec_cmd "brightnessctl -e4 -n2 set 5%-") { :description "Brightness down" :locked true :repeating true })

;; Media player, requires playerctl
(map :M (hl.dsp.exec_cmd "playerctl play-pause") { :description "Play/pause media" :locked true })
(map :Comma (hl.dsp.exec_cmd "playerctl previous") { :description "Previous track" :locked true })
(map :Period (hl.dsp.exec_cmd "playerctl next") { :description "Next track" :locked true })
(hl.bind "XF86AudioNext" (hl.dsp.exec_cmd "playerctl next") { :description "Next track" :locked true })
(hl.bind "XF86AudioPrev" (hl.dsp.exec_cmd "playerctl previous") { :description "Previous track" :locked true })
(hl.bind "XF86AudioPause" (hl.dsp.exec_cmd "playerctl play-pause") { :description "Pause" :locked true })
(hl.bind "XF86AudioPlay" (hl.dsp.exec_cmd "playerctl play-pause") { :description "Play" :locked true })
;}}} 

;{{{ APPS
; TODO disable-gpu not needed on PC, better to remove password-store
(map :F1 (hl.dsp.exec_cmd "launcher.clj -c brave-browser") "Run browser")
(map :F2 (hl.dsp.exec_cmd "launcher.clj -c intellij") "Run IntelliJ IDEA")
(map :F3 (hl.dsp.exec_cmd "launcher.clj -c vifm") "Run Vifm in terminal")
(map :F4 (hl.dsp.exec_cmd "pcmanfm") "Run file manager")
(map :F5 (hl.dsp.exec_cmd "keecli.sh") "Run KeePass CLI")
(map :F6 (hl.dsp.exec_cmd  "launcher.clj -c newsboat") "Run newsboat")
 ; "launcher.clj -c "
(map :F7 (hl.dsp.exec_cmd  "launcher.clj -c notebook") "Run note editor")
(map :F8 (hl.dsp.exec_cmd  "launcher.clj -c taskwarrior-tui") "Run taskwarrior")
(map :F9 (hl.dsp.exec_cmd "todo.lua add") "Add todo item")
(map :F10 (hl.dsp.exec_cmd "launcher.clj -c local-videos") "Open video")
(map :F11 (hl.dsp.exec_cmd "launcher.clj -c scripts") "Run script")
(map :F12 (hl.dsp.exec_cmd "launcher.clj -c power-menu") "Power menu")

;; Notifications
(map :Escape (hl.dsp.exec_cmd "makoctl dismiss -a") "Dismiss all notifications")
(mapSft :Escape (hl.dsp.exec_cmd "makoctl restore") "Restore notifications")

;; Scratchpad
(hl.bind "F12" (hl.dsp.exec_cmd  "launcher.clj -c dropdown-terminal") { :description "Dropdown terminal" })
;; TODO test
(mapCtl :M (hl.dsp.exec_cmd (.. "if ! pidof -x mpd; then mpd && mpDris2 && rmpc update; fi && launcher.clj -c music")) { :description "Music player" :locked true })
(map :D (hl.dsp.exec_cmd "scratchpad.clj --switcher") "List windows")
(mapCtl :D (hl.dsp.exec_cmd "scratchpad.clj --list") "List scratchpad windows")
(map :S (hl.dsp.exec_cmd "scratchpad.clj --toggle") "Toggle scratchpad")
(mapCtl :S (hl.dsp.exec_cmd "scratchpad.clj --add") "Add window to scratchpad")

;; Rofi
(mapSft :D (hl.dsp.exec_cmd "rofi -modi drun,keys,run -show drun -show-icons -sidebar-mode -monitor -4 -matching fuzzy") "App launcher menu")
(mapSft :M (hl.dsp.exec_cmd (.. DIR_ROFI "/mount-launcher.sh")) "Mount launcher")
(map :V (hl.dsp.exec_cmd "clipcat.clj menu --paste") "Clipboard menu")
(mapCtl :V (hl.dsp.exec_cmd "clipcat.clj clip --previous --paste") "Paste previous clipboard item")

;; Chat AI
(map :A (hl.dsp.exec_cmd "chat.clj ask --output scratchpad") "Ask chat AI")
(mapCtl :A (hl.dsp.exec_cmd "chat.clj action --action-list --output scratchpad") "AI action list")
(mapSft :A (hl.dsp.exec_cmd "chat.clj ask --list --output scratchpad") "Ask chat AI - choose model")

; (map :I (hl.dsp.exec_cmd "pkill -USR2 -x handy") "Toggle handy: speak to text")
(map :I (hl.dsp.exec_cmd "voxtype record toggle --model small") "Toggle speak to text - multi")
; (mapCtl :I (hl.dsp.exec_cmd "voxtype record toggle --model small") "Toggle speak to text - multilanguage")
;; SCROLL_LOCK is set default in voxtype and I can't disable it, idk if I can overwrite binding from voxtype
(hl.bind "SCROLL_LOCK" (hl.dsp.exec_cmd "voxtype record start --model small") {:description "Start speak to text - multi"})
(hl.bind "SCROLL_LOCK" (hl.dsp.exec_cmd "voxtype record stop") {:release true :description "Stop speak to text"})

; (hl.bind "PAUSE" (hl.dsp.exec_cmd "voxtype record start --model small") {:description "Start speak to text - multi"})
; (hl.bind "PAUSE" (hl.dsp.exec_cmd "voxtype record stop") {:release true :description "Stop speak to text"})


;; YouTube
(map :Y (hl.dsp.exec_cmd "yt.clj playlist --channel") "YT channel playlist")
(mapCtl :Y (hl.dsp.exec_cmd "yt.clj search --input") "Search YouTube")
(mapSft :Y (hl.dsp.exec_cmd "mpv.lua -o") "Video playlists")

;; Internet
(map :B (hl.dsp.exec_cmd "rofi-buku") "Launch Buku bookmarks")
(mapCtl :B (hl.dsp.exec_cmd "launcher.clj qutebrowser") "Restore Qutebrowser session")
(mapCtl :B (hl.dsp.exec_cmd "launcher.clj qutebrowser-apps") "Launch Qutebrowser webapp")

;; Pomodoro
(map :Z (hl.dsp.exec_cmd "pomodoro.lua add -n") "Start pomodoro")
(mapCtl :Z (hl.dsp.exec_cmd "pomodoro.lua stop -n && task sync") "Stop pomodoro and sync tasks")
(mapSft :Z (hl.dsp.exec_cmd "pomodoro.lua menu -n") "Pomodoro menu")

;; Trash / file management
(map :Delete (hl.dsp.exec_cmd "launcher.clj -c restore-trash") "Restore trashed files")
(mapSft :Delete (hl.dsp.exec_cmd "launcher.clj -c remove-mpv") "Remove MPV playing media")
(mapCtl :Delete (hl.dsp.exec_cmd "launcher.clj -c remove-mpd") "Remove MPD playing media")

;; System
(map :BackSpace (hl.dsp.exec_cmd  "launcher.clj -c top") "Launch system monitor")
(mapCtl :BackSpace (hl.dsp.exec_cmd (.. DIR_ROFI "/kill")) "Kill process via menu")
(mapSft :BackSpace (hl.dsp.exec_cmd "hyprctl kill") "Kill Hyprland")

;; Translate
(map :T (hl.dsp.exec_cmd "search.lua --enpl -c") "Translate clip (EN->PL)")
(mapCtl :T (hl.dsp.exec_cmd "search.lua --enpl -p") "Translate primary (EN->PL)")
(mapSft :T (hl.dsp.exec_cmd "launcher.clj -c menu-trans") "Launch translator menu")
;}}} 

;{{{ submaps
(mapSft :R (hl.dsp.submap "resize") "Submap resize")
(hl.define_submap "resize"
  (fn []
    (hl.bind :L (hl.dsp.window.resize {:x 10 :y 0 :relative true}) {:repeating true})
    (hl.bind :H (hl.dsp.window.resize {:x -10 :y 0 :relative true}) {:repeating true})
    (hl.bind :J (hl.dsp.window.resize {:x 0 :y 10 :relative true}) {:repeating true})
    (hl.bind :K (hl.dsp.window.resize {:x 0 :y -10 :relative true}) {:repeating true})
    ;; Escape returns to the global submap
    (hl.bind "escape" (hl.dsp.submap "reset"))))
;}}} 

;{{{ Input; Devices, LAYOUTS

; https://wiki.hyprland.org/Configuring/Variables/#input
(hl.config { :input { :numlock_by_default true
                      :kb_layout "pl"
                      :kb_variant ""
                      :kb_model ""
                      :kb_options ""
                      :kb_rules ""
                      :follow_mouse 1
                      :sensitivity 0
                      :scroll_method "2fg"
                      :touchpad { :scroll_factor 0.7
                                  :middle_button_emulation true
                                  :tap_to_click true
                                  :clickfinger_behavior false } } })

;; it doesn't work in my laptop
(hl.gesture { :fingers 3 :direction "horizontal" :action "workspace" })

; Example per-device config Per-device config options will overwrite your options set in the input section.
; https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
; 1 for the left button, 2 for the middle button (pressing the scroll wheel), and 3 for the right button
; sensitivity range -1.0 to 1.0
; hyprctl devices
(hl.device { :name "mosart-semi.-trust-wireless-mouse" :sensitivity 0.0 })
(hl.device { :name "kensington-usb-orbit"
             :sensitivity 1.0
             :middle_button_emulation true
             :scroll_button 3
             :scroll_button_lock false })
(hl.device { :name "logitech-mx-vertical-1" :sensitivity 1.0 })

;; LAYOUTS
; layout is set in look.config
(hl.config { :dwindle { :preserve_split true :force_split 2 } })
(hl.config { :master { :new_status "master" } })
(hl.config { :scrolling { :column_width 1 :follow_min_visible 1 } })

;; MISC SETTINGS
; TODO check it out 
; allow_workspace_cycles = true
; workspace_back_and_forth = true; fix popups? 
; allow_pin_fullscreen = true 
(hl.config { :binds { :drag_threshold 10 } })
(hl.config { :debug { :disable_logs false } })
;}}} 

(local monitor1 "DVI-D-1")
(local monitor2 "DVI-I-1")

(fn swap-monitor []
  (let [win (hl.get_active_window)]
    (when win
      (let [current-mon win.monitor.name
            target-mon  (if (= current-mon monitor1) monitor2 monitor1)]
        (hl.dispatch (hl.dsp.window.move {:monitor target-mon}))))))

(map :W swap-monitor "Swap windows")
; (map :W (hl.dsp.workspace.swap_monitors { :monitor1 "DVI-D-1" :monitor2 "DVI-I-1" }) "Swap windows")

; include joins files into one lua file
;; but require is bettter https://wiki.hypr.land/Configuring/Start/#require
(require :look)
(require :rules)
(require :monitor)
(require :animations.dynamic)
; (map :A (hl.dsp.exec_cmd "launcher.clj --all") "List all scripts")

; vi: foldmethod=marker

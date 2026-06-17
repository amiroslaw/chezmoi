(local hl _G.hl) ;; removes error in diagnostics 

; See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
; and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

; TODO add for each on the list for floating, scratchpad windows
; for _, class in ipairs(floating_classes) do
;   hl.window_rule({
;     match = {
;       class = class_match(class),
;     },
;     float = true,
;   })
; end

;; WINDOW RULES

; global
; layerrule = noanim, namespace:rofi
; Ignore maximize requests from apps. You'll probably like this.

(hl.window_rule { :name "suppress-maximize-events"
                  :match { :class ".*" }
				:suppress_event "maximize"})

(hl.window_rule { :name "fix-xwayland-drags"
                  :match { :class "^$"
                           :title "^$"
                           :xwayland true
                           :float true
                           :fullscreen false
                           :pin false }
                  :no_focus true })
; what is that?
; hl.window_rule({
;     name  = "move-hyprland-run",
;     match = { class = "hyprland-run" },
;     move  = "20 monitor_h-120",
;     float = true,
; })

(hl.window_rule { :name "workspace-fm"
                  :match { :initial_class "^(vifm)$" }
                  :workspace 3 })

(hl.window_rule { :name "workspace-top"
                  :match { :initial_class "^(top)$" }
                  :workspace 9 })

(hl.window_rule { :name "workspace-audio"
                  :match { :initial_class "^(audio)$" }
                  :workspace "5 silent" })

(hl.window_rule { :name "file-roller"
                  :match { :class "file-roller" }
                  :float true
                  :center true })

(hl.window_rule { :name "mpv"
                  :match { :class "mpv" }
                  :fullscreen true })

(hl.window_rule { :name "KeePassXC"
                  :match { :class "^(KeePassXC)$" }
                  :float true
                  :center true
                  :size [1100 600] })

(hl.window_rule { :name "windowrule-8"
                  :match { :title "^(pavucontrol)$" }
                  :float true })

(hl.window_rule { :name "windowrule-9"
                  :match { :class "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }
                  :center true })

(hl.window_rule { :name "windowrule-10"
                  :match { :title "^(blueman-manager)$" }
                  :float true })

(hl.window_rule { :name "windowrule-11"
                  :match { :title "^(nm-connection-editor)$" }
                  :float true })

(hl.window_rule { :name "windowrule-12"
                  :match { :class "zenity" }
                  :float true })

(hl.window_rule { :name "windowrule-13"
                  :match { :class "^([Yy]ad)$" }
                  :float true })

(hl.window_rule { :name "windowrule-14"
                  :match { :class "^([Qq]alculate-gtk)$" }
                  :float true })

(hl.window_rule { :name "windowrule-15"
                  :match { :class "menu" }
                  :float true })

;{{{ Scratchpads
(hl.window_rule { :name "scratch-drop"
                  :match { :class "^(drop)$" }
                  :workspace "special:drop"
                  :float true
                  :size ["monitor_w*0.9" "monitor_h*0.7"]
                  ; :max_size [1000 "monitor_h*0.7"]
                  :move ["monitor_w*0.05" 50] })

(hl.window_rule { :name "scratch-chat"
                  :match { :class "^(chat)$" }
                  :workspace "special:chat"
                  :size [1000 "monitor_h*0.9"] 
                  ; :size ["monitor_w*0.6" "monitor_h*0.9"] 
                  :float true })

(hl.window_rule { :name "scratch-news"
                  :match { :class "^(news)$" }
                  :workspace "special:news"
                  :float true
                  :size ["monitor_w*0.9" "monitor_h*0.8"] })

(hl.window_rule { :name "scratch-music"
                  :match { :class "^(music)$" }
                  :workspace "special:music"
                  :float true
                  :center false
                  :size [1000 "monitor_h*0.9"]
                  :max_size [1000 1000] })

(hl.window_rule { :name "scratch-cal"
                  :match { :class "^(cal)$" }
                  :workspace "special:cal"
                  :float true
                  :size ["monitor_w*0.8" "monitor_h*0.8"] })

(hl.window_rule { :name "scratch-task"
                  :match { :class "task" }
                  :workspace "special:task"
                  :float true
                  :center true
                  :size [1000 "monitor_h*0.9"] })
;}}} 

(hl.window_rule { :name "rsvp"
                  :match { :class "rsvp" }
                  :float true
                  :pin true
                  :center true
                  :size [1100 150] })

(hl.window_rule { :name "cheatsh"
                  :match { :class "cheatsh" }
                  :float true })

(hl.window_rule { :name "read"
                  :match { :class "read" }
                  :float true })

(hl.window_rule { :name "mpv-audio"
                  :match { :class "audio" }
                  :float true
                  :center true
                  :size [500 150] })

(hl.window_rule { :name "trash"
                  :match { :class "trash" }
                  :float true
                  :center true
                  :size [900 "monitor_h*0.9"] })

(hl.window_rule { :name "qutebrowser-popups"
                  :match { :class "qb" }
                  :float true
                  :center true
                  :size [900 600] })

(hl.window_rule { :name "ytfzf"
                  :match { :class "ytfzf" }
                  :float true
                  :center true
                  :size [1000 900] })

(hl.window_rule { :name "mpv-popup"
                  :match { :class "videopopup" }
                  :float true
                  :pin true
                  :keep_aspect_ratio true
                  :no_initial_focus true
                  ; :suppress_event "maximize"
                  :size [380 210]
                  :move ["monitor_w*1-383" "monitor_h*1-230"]
                  :rounding 0 })

(hl.window_rule { :name "windowrule-29"
                  :match { :class "application.Main" }
                  :float true })

(hl.window_rule { :name "timefx"
                  :match { :class "ovh.miroslaw.timefx.TimeFX" }
                  :float true })

;; Dialog windows
(hl.window_rule { :name "Modals"
                  :match { :modal true }
                  :center true
                  :float true })
(hl.window_rule { :name "Dialogs"
                  :match { :title "(Open File|Open|Save|Save As|Export|Import |Choose File|Rename)" }
                  :center true
                  :float true })
;; maybe remove
(hl.window_rule { :name "windowrule-32"
                  :match { :title "^(Open File)(.*)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-33"
                  :match { :title "^(Select a File)(.*)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-34"
                  :match { :title "^(Choose wallpaper)(.*)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-35"
                  :match { :title "^(Open Folder)(.*)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-36"
                  :match { :title "^(Save As)(.*)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-37"
                  :match { :title "^(Save As)$" }
                  :size ["monitor_w*0.7" "monitor_h*0.6"] })

(hl.window_rule { :name "windowrule-38"
                  :match { :title "^(Library)(.*)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-39"
                  :match { :title "^(File Upload)(.*)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-40"
                  :match { :title "^(.*)(wants to save)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-41"
                  :match { :title "^(.*)(wants to open)$" }
                  :center true
                  :float true })

(hl.window_rule { :name "windowrule-42"
                  :match { :initial_title "(Open Files)" }
                  :float true
                  :size ["monitor_w*0.7" "monitor_h*0.6"] })

(hl.window_rule { :name "windowrule-43"
                  :match { :class "MEGAsync" }
                  :float true
                  :fullscreen true })

; "Smart gaps" / "No gaps when only"
;  https://wiki.hyprland.org/Configuring/Workspace-Rules/
(hl.workspace_rule { :workspace "w[tv1]" :gaps_out 0 :gaps_in 0 })
(hl.workspace_rule { :workspace "f[1]"   :gaps_out 0 :gaps_in 0 })

(hl.window_rule { :name "gaps-1"
                  :match { :float false :workspace "w[tv1]" }
                  :border_size 0
                  :rounding 0 })

(hl.window_rule { :name "gaps-2"
                  :match { :float false :workspace "f[1]" }
                  :border_size 0
                  :rounding 0 })

;; LAYER RULES
(hl.layer_rule { :name "layerrule-1"
                  :match { :namespace "notifications" }
                  :blur true
                  :ignore_alpha 0
                  :order -3 })

(hl.layer_rule { :name "layerrule-2"
                  :match { :namespace "rofi" }
                  :blur true
                  :ignore_alpha 0
                  :dim_around true
                  :animation "popin 85%" })

; vi: foldmethod=marker


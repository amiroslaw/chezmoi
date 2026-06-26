;; LOOK AND FEEL

(local hl _G.hl) ;; removes error in diagnostics 

; https://wiki.hyprland.org/Configuring/Variables/#general
(hl.config { :general { :layout "dwindle"
                        :gaps_in 2
                        :gaps_out 2
                        :border_size 1
                        :col { :active_border { :colors ["rgba(33ccffee)" "rgba(00ff99ee)"] :angle 45 }
                               :inactive_border "rgba(595959aa)" }
                        :resize_on_border true ; Set to true enable resizing windows by clicking and dragging on borders and gaps
                        :allow_tearing false
                        :snap { :enabled true } }

; https://wiki.hyprland.org/Configuring/Variables/#decoration
             :decoration { :rounding 7
                           :rounding_power 2
                           :active_opacity 1.0
                           :inactive_opacity 1.0
                           :shadow { :enabled true :range 4 :render_power 3 :color "rgba(1a1a1aee)" }
                           :blur { :enabled true :size 3 :passes 1 :vibrancy 0.1696 } }

; https://wiki.hyprland.org/Configuring/Variables/#misc
	; new_window_takes_over_fullscreen = 1 # new window in fullscreen on top
             :misc { :on_focus_under_fullscreen 1
; if true, closing a fullscreen window makes the next windows in tilted mode, ok with 2 windows
; if false, even one window will in fullscreen mode
                     :exit_window_retains_fullscreen false
                     :force_default_wallpaper -1
                     :disable_hyprland_logo false
                     :enable_swallow true
                     :swallow_regex "^(chat)$" ; idk why it doesn't work
                     ; :swallow_regex "^(org.wezfurlong.wezterm|foot|footclient)$" 
                     } })

; ;; ANIMATIONS
; (hl.config { :animations { :enabled true } })
; (hl.curve "easeOutQuint" { :type "bezier" :points [[0.23 1] [0.32 1]] })
; (hl.curve "easeInOutCubic" { :type "bezier" :points [[0.65 0.05] [0.36 1]] })
; (hl.curve "linear" { :type "bezier" :points [[0 0] [1 1]] })
; (hl.curve "almostLinear" { :type "bezier" :points [[0.5 0.5] [0.75 1]] })
; (hl.curve "quick" { :type "bezier" :points [[0.15 0] [0.1 1]] })
; (hl.animation { :leaf "global"        :enabled true :speed 10   :bezier "default" })
; (hl.animation { :leaf "border"        :enabled true :speed 5.39 :bezier "easeOutQuint" })
; (hl.animation { :leaf "windows"       :enabled true :speed 4.79 :bezier "easeOutQuint" })
; (hl.animation { :leaf "windowsIn"     :enabled true :speed 4.1  :bezier "easeOutQuint" :style "popin 87%" })
; (hl.animation { :leaf "windowsOut"    :enabled true :speed 1.49 :bezier "linear"       :style "popin 87%" })
; (hl.animation { :leaf "fadeIn"        :enabled true :speed 1.73 :bezier "almostLinear" })
; (hl.animation { :leaf "fadeOut"       :enabled true :speed 1.46 :bezier "almostLinear" })
; (hl.animation { :leaf "fade"          :enabled true :speed 3.03 :bezier "quick" })
; (hl.animation { :leaf "layers"        :enabled true :speed 3.81 :bezier "easeOutQuint" })
; (hl.animation { :leaf "layersIn"      :enabled true :speed 4    :bezier "easeOutQuint" :style "fade" })
; (hl.animation { :leaf "layersOut"     :enabled true :speed 1.5  :bezier "linear"       :style "fade" })
; (hl.animation { :leaf "fadeLayersIn"  :enabled true :speed 1.79 :bezier "almostLinear" })
; (hl.animation { :leaf "fadeLayersOut" :enabled true :speed 1.39 :bezier "almostLinear" })
; (hl.animation { :leaf "workspaces"    :enabled true :speed 1.94 :bezier "almostLinear" :style "fade" })
; (hl.animation { :leaf "workspacesIn"  :enabled true :speed 1.21 :bezier "almostLinear" :style "fade" })
; (hl.animation { :leaf "workspacesOut" :enabled true :speed 1.94 :bezier "almostLinear" :style "fade" })

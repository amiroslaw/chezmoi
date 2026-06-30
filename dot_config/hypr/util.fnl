(global hl _G.hl) ;; removes error in diagnostics 

(global sup "SUPER")
(global HOME (os.getenv "HOME"))
(global CONFIG (or (os.getenv "XDG_CONFIG_HOME") (.. HOME "/.config")))
(global TERMINAL (or (os.getenv "TERMINAL") "wezterm"))
(global TERM_LT (or (os.getenv "TERM_LT") "foot"))
(global DIR_ROFI (or (os.getenv "ROFI") (.. CONFIG "/rofi")))

; TODO add bind without super
(global map (lambda [key cmd opts]
  (let [opts (if (= :string (type opts)) {:description opts} opts)]
    (hl.bind (.. "SUPER + " key) cmd opts))))
(global mapCtl (lambda [key cmd opts] (map (.. "CTRL + " key) cmd opts)))
(global mapSft (lambda [key cmd opts] (map (.. "SHIFT + " key) cmd opts)))
(global mapAlt (lambda [key cmd opts] (map (.. "ALT + " key) cmd opts)))

(lambda notify [msg icon]
          (let [icon (or icon :OK)]
            (hl.notification.create {:text msg :timeout 2000 :font_size 20 :icon icon})))
(global notify-send (fn [msg icon] (notify msg icon)))
(global notify-error (fn [msg] (notify msg :ERROR)))

(local M {})

(local layouts ["dwindle" "scrolling" "monocle"])
(fn M.switch-layout []
  (let [w (hl.get_active_workspace)
        current (. w :tiled_layout)
        idx (. (icollect [i layout (ipairs layouts)]
               (when (= layout current) i)) 1)
        next-index (+ 1 (% idx (# layouts)))
        next-layout (. layouts next-index)]
    (hl.exec_cmd (.. "notify-send " next-layout))
    (hl.workspace_rule {:workspace w.name :layout next-layout})))

M

; vi: foldmethod=marker

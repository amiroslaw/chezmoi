;; Swayimg configuration
;; Override any option via: swayimg --config="general.mode=gallery"
;; TODO mark
;; invert_marks in gallery
;; space for mark and go to next img

(local gallery swayimg.gallery)
(local slideshow swayimg.slideshow)
(local viewer swayimg.viewer)
(local imagelist swayimg.imagelist)
;; ----------------------------------
;; Helper functions
;; ----------------------------------

(var info_shown false)
(var is_viewer_animation_running true)

(fn run_cmd [fmt ...]
  (os.execute (string.format fmt ...)))

(fn bind [modes key action arg]
  (each [_ m (ipairs modes)]
    (m.on_key key (fn []
      (if (= (type action) :string)
        ((. m action) arg)
        (= (type action) :function)
        (action arg)
        (action))))))

(fn mv [x y]
  (fn []
    (let [wnd (swayimg.get_window_size)
          pos (viewer.get_position)]
      (viewer.set_abs_position
        (math.floor (+ pos.x (* wnd.width x)))
        (math.floor (+ pos.y (* wnd.height y)))))))

(fn zoom [dir]
  (fn []
    (let [pos (swayimg.get_mouse_pos)
          scale (viewer.get_scale)]
      (viewer.set_abs_scale (+ scale (* (/ scale 10) dir)) pos.x pos.y))))

(fn toggle_info []
  (if info_shown
    (do
      (swayimg.text.set_timeout 2)
      (swayimg.text.hide))
    (do
      (swayimg.text.set_timeout 0)
      (swayimg.text.show)))
  (set info_shown (not info_shown)))

(fn toggle_animation []
  (if is_viewer_animation_running
    (do
      (viewer.animation_stop)
      (set is_viewer_animation_running false))
    (do
      (viewer.animation_resume)
      (set is_viewer_animation_running true))))

(fn shell_quote [value]
  (.. "'" (string.gsub (tostring value) "'" "'\\''") "'"))

(fn get-mode []
  (let [mode_str (swayimg.get_mode)
        mode (case mode_str
                :viewer viewer
                :gallery gallery
                :slideshow slideshow
                _ nil)]
  mode))

(fn with_current_image [f]
  (let [mode (get-mode)
        image (mode.get_image)]
    (when (and image image.path)
      (f image.path))))

(fn get_marked_entries []
  (icollect [_ entry (ipairs (imagelist.get))]
    (when entry.mark entry)))

(fn get_marked_paths []
  (icollect [_ entry (ipairs (get_marked_entries))]
    entry.path))

(fn clear_all_marks []
  (let [total (length (imagelist.get))
		  mode (get-mode)]
    (when (> total 0)
      (mode.switch_image :first)
      (mode.mark_image false)
      (for [_ 1 (- total 1)]
        (mode.switch_image :next)
        (mode.switch_image :right)
        (mode.mark_image false)))))

;; gallery doesn't have next, but for clear_all_marks works
;; in gallery offset is invalid
(fn invert_marks []
  (let [total (length (imagelist.get))
		  mode (get-mode)]
    (when (> total 0)
      (mode.switch_image :first)
      (mode.switch_image :right)  
      (mode.mark_image)
      (for [_ 1 (- total 1)]
        (mode.switch_image :next)
        (mode.switch_image :right)
        (mode.mark_image)))))

;; ----------------------------------
;; Key bindings
;; ----------------------------------

(local all_modes [gallery viewer slideshow])
(local nav_modes [viewer slideshow])
(bind all_modes :F1 pring_marked)

;; Global bindings (all modes)
(bind all_modes :i swayimg.text.show)
(bind all_modes :Shift+i toggle_info)
(bind all_modes :q swayimg.exit)
(bind all_modes :g :switch_image :first)
(bind all_modes :Shift+g :switch_image :last)
(bind all_modes :Shift+r :reload)
(bind all_modes :m :mark_image)
(bind all_modes :Ctrl+m clear_all_marks)
(bind all_modes :Shift+m invert_marks)

;; Navigation (viewer + slideshow)
(bind nav_modes :p :switch_image :prev)
(bind nav_modes :n :switch_image :next)
(bind nav_modes :Space :switch_image :next)
(bind nav_modes :Shift+p :switch_image :prev_dir)
(bind nav_modes :Shift+n :switch_image :next_dir)
(bind nav_modes :Ctrl+r :switch_image :random)
(bind nav_modes :comma :prev_frame)
(bind nav_modes :period :next_frame)

;; Gallery navigation
(bind [gallery] :h :switch_image :left)
(bind [gallery] :j :switch_image :down)
(bind [gallery] :k :switch_image :up)
(bind [gallery] :l :switch_image :right)
(bind [gallery] :u :switch_image :pgdown)
(bind [gallery] :d :switch_image :pgup)

;; Mode switching
(bind [gallery slideshow] :Return #(swayimg.set_mode :viewer))
(viewer.on_key :t #(swayimg.set_mode :gallery))
(viewer.on_key :s #(swayimg.set_mode :slideshow))

;; Viewer movement
(viewer.on_key :l (mv -0.05 0))
(viewer.on_key :h (mv 0.05 0))
(viewer.on_key :j (mv 0 -0.05))
(viewer.on_key :k (mv 0 0.05))
(viewer.on_key :Shift+l (mv -0.15 0))
(viewer.on_key :Shift+h (mv 0.15 0))
(viewer.on_key :Shift+j (mv 0 -0.15))
(viewer.on_key :Shift+k (mv 0 0.15))

;; Viewer scale modes
(viewer.on_key :0 #(viewer.set_fix_scale :fit))
(viewer.on_key :w #(viewer.set_fix_scale :width))
(viewer.on_key :Shift+w #(viewer.set_fix_scale :height))
(viewer.on_key :z #(viewer.set_fix_scale :real))
(viewer.on_key :Shift+z #(viewer.set_fix_scale :fill))

;; Viewer transformations
(viewer.on_key :backslash #(viewer.flip_vertical))
(viewer.on_key :Shift+bar #(viewer.flip_horizontal))
(viewer.on_key :bracketleft #(viewer.rotate 90))
(viewer.on_key :bracketright #(viewer.rotate 270))
(viewer.on_key :a toggle_animation)

;; Gallery thumbnail size
(gallery.on_key :0 #(swayimg.gallery.set_thumb_size 200))
;; --------------------------------------------------
;;               custom functions               --
;; --------------------------------------------------

;; File operations
(bind all_modes :Delete (fn []
  (with_current_image (fn [path]
    (os.remove path)
    (run_cmd "notify-send \"File removed: %s\"" (shell_quote path))))))

(bind all_modes :x (fn []
  (with_current_image (fn [path]
    (run_cmd "gomi %s" (shell_quote path))
	(imagelist.remove path)
     (run_cmd "notify-send \"File moved to the trash: %s\"" (shell_quote path))))))

(bind all_modes :y (fn []
  (with_current_image (fn [path]
    (os.execute (.. "printf %s " (shell_quote path) " | wl-copy"))
    (os.execute (string.format "notify-send \"Copied file path %s\"" path))))))

(bind all_modes :c (fn []
  (with_current_image (fn [path]
    (run_cmd "basename \"%s\" | wl-copy" path)
    (run_cmd "notify-send \"Copied file name \"")))))

(bind all_modes :Ctrl+c (fn []
  (with_current_image (fn [path]
    (run_cmd (.. "cat " (shell_quote path) " | wl-copy"))))))

(bind all_modes :Ctrl+g (fn []
  (with_current_image (fn [path]
    (run_cmd (.. "gimp " (shell_quote path)))))))

(bind all_modes :e (fn []
  (with_current_image (fn [path]
    (run_cmd "satty --filename=%s" (shell_quote path))))))

(bind all_modes :o (fn []
  (with_current_image (fn [path]
    (run_cmd "tesseract \"%s\" \"%s\"" path path)
    (run_cmd "notify-send \"OCR finished\"")))))

(bind all_modes :r (fn []
  (with_current_image (fn [path]
    (run_cmd "\"$XDG_CONFIG_HOME/swayimg/rename.sh\" %s" (shell_quote path))))))

;; File operations on marked files (Shift variants)
(bind all_modes :Shift+Delete (fn []
  (each [_ path (ipairs (get_marked_paths))]
    (os.remove path)
    (run_cmd "notify-send \"File removed: %s\"" (shell_quote path)))))

(bind all_modes :Shift+x (fn []
  (each [_ path (ipairs (get_marked_paths))]
    (run_cmd "gomi %s" (shell_quote path))
    (imagelist.remove (shell_quote path))
     (run_cmd "notify-send \"File moved to the trash: %s\"" (shell_quote path)))))

(bind all_modes :Shift+y (fn []
  (let [paths (get_marked_paths)]
    (when (> (length paths) 0)
      (let [joined (table.concat paths "\n")]
        (os.execute (.. "printf %s " (shell_quote joined) " | wl-copy"))
         (run_cmd "notify-send \"Copied %d file paths\"" (length paths)))))))

(bind all_modes :Shift+c (fn []
  (let [paths (get_marked_paths)]
    (when (> (length paths) 0)
      (let [basenames (icollect [_ p (ipairs paths)]
                    (p:match "([^/]+)$"))
            joined (table.concat basenames "\n")]
        (os.execute (.. "printf %s " (shell_quote joined) " | wl-copy"))
        (run_cmd "notify-send \"Copied %d file names\"" (length paths)))))))

(bind all_modes :Shift+o (fn []
  (each [_ path (ipairs (get_marked_paths))]
    (run_cmd "tesseract \"%s\" \"%s\"" path path))
  (run_cmd "notify-send \"OCR finished on marked files\"")))

;; Move to folder (1-9)
(for [i 1 9]
  (let [key (tostring i)]
    (bind all_modes key (fn []
  (with_current_image (fn [path]
          (run_cmd "mkdir -p %d && mv \"%s\" %d" i path i)
          (run_cmd "notify-send \"Moved to folder: %d\"" i)
          (imagelist.remove path)))))

    (bind all_modes (.. "Ctrl+" key) (fn []
      (each [_ path (ipairs (get_marked_paths))]
        (run_cmd "mkdir -p %d && mv \"%s\" %d" i path i)
         (imagelist.remove path))
       (run_cmd "notify-send \"Moved to folder: %d\"" i)))))

;; Mouse zoom
(viewer.on_mouse :Ctrl-ScrollUp (fn []
  (let [pos (swayimg.get_mouse_pos)
        scale (viewer.get_scale)]
    (viewer.set_abs_scale (+ scale (/ scale 10)) pos.x pos.y))))

(viewer.on_key :Escape swayimg.exit)

;; ----------------------------------
;; Events
;; ----------------------------------
(swayimg.on_window_resize (fn []
  (viewer.set_fix_scale :optimal)
  (slideshow.set_fix_scale :optimal)))

(swayimg.gallery.on_image_change (fn []
  (let [image (gallery.get_image)]
    (swayimg.set_title (.. "Gallery: " image.path)))))

;; ----------------------------------
;; General config
;; ----------------------------------

(swayimg.set_mode :viewer)
(swayimg.enable_overlay true)
(swayimg.enable_decoration false)
(swayimg.set_title "swayimg")
(swayimg.enable_antialiasing true)
(swayimg.set_dnd_button :MouseRight)

;; ----------------------------------
;; Image list configuration
;; ----------------------------------

(imagelist.set_order :numeric)
(imagelist.enable_recursive false)
(imagelist.enable_adjacent false)

;; ----------------------------------
;; Color palette (Tokyo Night)
;; ----------------------------------
(local bg      0xff1a1b26)
(local surface 0xff1f2335)
(local surface2 0xff24283b)
(local border  0xff565f89)
(local fg      0xffa9b1d6)
(local blue    0xff7aa2f7)
(local purple  0xffbb9af7)
(local cyan    0xff7dcfff)
(local green   0xff9ece6a)
(local red     0xfff7768e)
(local orange  0xffff9e64)
(local yellow  0xffe0af68)
(local sel     0xff3d59a1)
(local shadow  bg)
(local window-bg bg)

;; ----------------------------------
;; Text overlay configuration
;; ----------------------------------

(swayimg.text.hide)
(swayimg.text.set_font "monospace")
(swayimg.text.set_size 14)
(swayimg.text.set_padding 7)
(swayimg.text.set_foreground fg)
(swayimg.text.set_background 0x00000000)
(swayimg.text.set_shadow shadow)

;; ----------------------------------
;; Viewer mode configuration
;; ----------------------------------

(viewer.set_default_scale :optimal)
(viewer.set_default_position :center)
(viewer.enable_centering true)
(viewer.enable_loop true)
(viewer.limit_preload 1)
(viewer.set_drag_button :MouseLeft)
(viewer.set_window_background window-bg)
(viewer.set_image_chessboard 20 surface surface2)
(viewer.set_mark_color purple)

(viewer.set_text :topleft [
  "File: {name}"
  "Format: {format}"
  "File size: {sizehr}"
  "File time: {time}"
  "EXIF date: {meta.Exif.Photo.DateTimeOriginal}"
  "EXIF camera: {meta.Exif.Image.Model}"])

(viewer.set_text :topright [
  "Image: {list.index} of {list.total}"
  "Frame: {frame.index} of {frame.total}"
  "Size: {frame.width}x{frame.height}"])

(viewer.set_text :bottomleft [
  "Scale: {scale}"])

;; ----------------------------------
;; Slideshow mode configuration
;; ----------------------------------

(slideshow.set_timeout 5)
(slideshow.set_default_scale :fit)
(slideshow.set_window_background :auto)
(slideshow.set_text :topleft ["{name}"])
(slideshow.set_mark_color purple)

;; ----------------------------------
;; Gallery mode configuration
;; ----------------------------------

(gallery.set_aspect :fill)
(gallery.set_thumb_size 200)
(gallery.set_padding_size 5)
(gallery.set_border_size 5)
(gallery.limit_cache 100)
(gallery.enable_preload false)
(gallery.enable_pstore false)
(gallery.set_border_color border)
(gallery.set_selected_scale 1.15)
(gallery.set_selected_color sel)
(gallery.set_unselected_color surface)
(gallery.set_window_color window-bg)
(gallery.set_mark_color purple)

(gallery.set_text :topleft ["File: {name}"])
(gallery.set_text :topright ["{list.index} of {list.total}"])

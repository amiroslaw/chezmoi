-- Any of these options can be overridden using the --config argument
-- $ swayimg --config="general.mode=gallery"
-- TODO move commands from pqivrc
-- escape "
-- jak funkcja nie ma argumentu to można bez () wysłać 
--swayimg.gallery.mark_image(state?: boolean)
--swayimg.gallery.get_image() -> swayimg.entry

local gallery = swayimg.gallery
local slideshow = swayimg.slideshow
local viewer = swayimg.viewer
local imagelist = swayimg.imagelist

----------------------------------
-- Helper functions
----------------------------------

local function bind(modes, key, method_name, arg)
	-- local list
	-- if type(modes) ~= "table" then table.insert(list, modes) else list = modes end
    for _, m in ipairs(modes) do
        m.on_key(key, function()
            return m[method_name](arg)
        end)
    end
end

local mv = function(x, y)
	return function()
		local wnd = swayimg.get_window_size()
		local pos = swayimg.viewer.get_position()
		swayimg.viewer.set_abs_position(math.floor(pos.x + wnd.width * x), math.floor(pos.y + wnd.height * y))
	end
end

local zoom = function(dir)
	return function()
		local pos = swayimg.get_mouse_pos()
		local scale = swayimg.viewer.get_scale()
		swayimg.viewer.set_abs_scale(scale + (scale / 10) * dir, pos.x, pos.y)
	end
end

local info_shown = false
local toggle_info = function()
	if info_shown then
		swayimg.text.set_timeout(2)
		swayimg.text.hide()
	else
		swayimg.text.set_timeout(0)
		swayimg.text.show()
	end
	info_shown = not info_shown
end

local is_viewer_animation_running = true
local function toggle_animation()
    if is_viewer_animation_running then
        swayimg.viewer.animation_stop()
        is_viewer_animation_running = false
    else
        swayimg.viewer.animation_resume()
        is_viewer_animation_running = true
    end
end

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end
local function with_current_image(fn)
	local image = swayimg.viewer.get_image()
	if not image or not image.path then
		return
	end
	fn(image.path)
end

-- swayimg.viewer.on_key("F1", function()
--   swayimg.viewer.help()
-- end)
--

local all_modes = { gallery, viewer, slideshow }
bind(all_modes, "g", "switch_image", "first")
bind(all_modes, "Shift+g", "switch_image", "first")
bind({viewer, slideshow}, "p", "switch_image", "prev")
bind({viewer, slideshow}, "n", "switch_image", "next")
bind({viewer, slideshow}, "Space", "switch_image", "next")
bind({viewer, slideshow}, "Shift+p", "switch_image", "prev_dir")
bind({viewer, slideshow}, "Shift+n", "switch_image", "next_dir")
bind({viewer, slideshow}, "Ctrl+r", "switch_image", "random")
bind({gallery}, "h", "switch_image", "left")
bind({gallery}, "j", "switch_image", "down")
bind({gallery}, "k", "switch_image", "up")
bind({gallery}, "l", "switch_image", "right")
bind({gallery}, "u", "switch_image", "pgdown")
bind({gallery}, "d", "switch_image", "pgup")
bind({gallery}, "m", "mark_image", true)

swayimg.viewer.on_key("l", mv(-0.05, 0))
swayimg.viewer.on_key("h", mv(0.05, 0))
swayimg.viewer.on_key("j", mv(0, -0.05))
swayimg.viewer.on_key("k", mv(0, 0.05))
swayimg.viewer.on_key("Shift+l", mv(-0.15, 0))
swayimg.viewer.on_key("Shift+h", mv(0.15, 0))
swayimg.viewer.on_key("Shift+j", mv(0, -0.15))
swayimg.viewer.on_key("Shift+k", mv(0, 0.15))
swayimg.viewer.on_key("i", swayimg.text.show)
swayimg.viewer.on_key("Shift+i", toggle_info)
swayimg.viewer.on_key("Escape", swayimg.exit)
swayimg.viewer.on_key("q", swayimg.exit)
swayimg.viewer.on_key("m", function()
	swayimg.set_mode("gallery")
end)
swayimg.viewer.on_key("comma", function()
    swayimg.viewer.prev_frame()
end)
swayimg.viewer.on_key("period", function()
    swayimg.viewer.next_frame()
end)
swayimg.viewer.on_key("s", function()
	swayimg.set_mode("slideshow")
end)
swayimg.viewer.on_key("a", toggle_animation)
swayimg.viewer.on_key("0", function()
	swayimg.viewer.set_fix_scale("fit")
end)
swayimg.viewer.on_key("w", function()
	swayimg.viewer.set_fix_scale("width")
end)
swayimg.viewer.on_key("Shift+w", function()
	swayimg.viewer.set_fix_scale("height")
end)
swayimg.viewer.on_key("z", function()
	swayimg.viewer.set_fix_scale("real")
end)
swayimg.viewer.on_key("Shift+z", function()
	swayimg.viewer.set_fix_scale("fill")
end)
swayimg.viewer.on_key("backslash", function()
	swayimg.viewer.flip_vertical()
end)
swayimg.viewer.on_key("Shift+bar", function()
	swayimg.viewer.flip_horizontal()
end)
swayimg.viewer.on_key("bracketleft", function()
	swayimg.viewer.rotate(90)
end)
swayimg.viewer.on_key("bracketright", function()
	swayimg.viewer.rotate(270)
end)

-- Delete: Deletes the current image file.
swayimg.viewer.on_key("Delete", function()
	with_current_image(function(path)
		os.remove(path)
	end)
end)

swayimg.viewer.on_key("x", function()
	with_current_image(function(path)
		os.execute(('gomi %s'):format(shell_quote(path)))
		os.execute(('notify-send "File removed: %s"'):format(shell_quote(path)))
	end)
end)

-- Copies the file path of the current image to the clipboard.
swayimg.viewer.on_key("y", function()
	with_current_image(function(path)
		os.execute("printf %s " .. shell_quote(path) .. " | wl-copy")
		os.execute(('notify-send "Copied file path %s"'):format(path))
	end)
end)

-- Ctrl+c: Copies the current image file to the clipboard.
swayimg.viewer.on_key("Ctrl+c", function()
	with_current_image(function(path)
		os.execute("cat " .. shell_quote(path) .. " | wl-copy")
	end)
end)
-- Ctrl+y = exec sh -c 'convert "%"  -quality 85 png:- | wl-copy --type image/png'

-- Ctrl+g: Opens the current image file in GIMP.
swayimg.viewer.on_key("Ctrl+g", function()
	with_current_image(function(path)
		os.execute("gimp " .. shell_quote(path))
	end)
end)

-- Ctrl+e: Opens the current image file in sttty.
swayimg.viewer.on_key("Ctrl+e", function()
	with_current_image(function(path)
		os.execute(('satty --filename=%s'):format(shell_quote(path)))
	end)
end)

-- ;ocr image
swayimg.viewer.on_key("e", function()
	with_current_image(function(path)
		os.execute(('tesseract "%s" "%s"'):format(path, path))
		os.execute('notify-send "OCR finished"')
	end)
end)

swayimg.viewer.on_key("r", function()
	with_current_image(function(path)
		os.execute(('"$XDG_CONFIG_HOME/swayimg/rename.sh" %s'):format(shell_quote(path)))
	end)
end)

for i = 1, 9 do
    for _, m in ipairs(all_modes) do
		m.on_key(i, function()
			local image = m.get_image()
			os.execute(('mkdir -p %d && mv "%s" %d'):format(i, image.path, i))
			os.execute('notify-send "Moved to folder: ' .. i .. '"')
			m.reload()
		end)
    end
end

-- bind Enter key to open image in viewer
swayimg.gallery.on_key("Return", function()
  swayimg.set_mode("viewer")
end)
swayimg.slideshow.on_key("Return", function()
  swayimg.set_mode("viewer")
end)

-- bind mouse vertical scroll button with pressed Ctrl to zoom in the image at mouse pointer coordinates
swayimg.viewer.on_mouse("Ctrl-ScrollUp", function()
  local pos = swayimg.get_mouse_pos()
  local scale = swayimg.viewer.get_scale()
  scale = scale + scale / 10
  swayimg.viewer.set_abs_scale(scale, pos.x, pos.y);
end)


--------------------------------------------------
--               General config                 --
--------------------------------------------------
swayimg.set_mode("viewer")                -- mode at startup
-- Sway/Hyprland only: create floating window above the currently focused one
swayimg.enable_overlay(true)
swayimg.enable_decoration(false)           -- window title/buttons/borders
swayimg.set_title("swayimg")
swayimg.enable_antialiasing(true)         -- anti-aliasing
swayimg.set_dnd_button("MouseRight")      -- drag-and-drop mouse button
-- Format specific parameters
-- swayimg.set_format_params('raw', { camera_wb = true }) -- use camera white balance

--------------------------------------------------
----          Image list configuration            ----
--------------------------------------------------
swayimg.imagelist.set_order("numeric")    -- list order
swayimg.imagelist.enable_recursive(false) -- recursive directory reading
swayimg.imagelist.enable_adjacent(false)  -- add adjacent files from same dir
-- swayimg.imagelist.enable_reverse(false)   -- reverse order

--------------------------------------------------
--          Text overlay configuration          --
--------------------------------------------------
swayimg.text.hide()
-- swayimg.text.set_timeout(5)               -- layer hide timeout
-- swayimg.text.set_status_timeout(3)        -- status message hide timeout
swayimg.text.set_font("monospace")        -- font name
swayimg.text.set_size(14)                 -- font size in pixels
swayimg.text.set_padding(7)              -- padding from window edge

swayimg.text.set_foreground(0xffcccccc)   -- foreground text color
swayimg.text.set_background(0x00000000)   -- text background color
swayimg.text.set_shadow(0x0d000000)       -- text shadow color

--------------------------------------------------
--              Image viewer mode               --
--------------------------------------------------
-- Default image scale (optimal/width/height/fit/fill/real/keep)
swayimg.viewer.set_default_scale("optimal")      -- default image scale
-- Initial image position on the window (center/top/bottom/free/...)
swayimg.viewer.set_default_position("center")    -- default image position
swayimg.viewer.enable_centering(true)            -- enable automatic centering
swayimg.viewer.enable_loop(true)                 -- enable image list loop mode
swayimg.viewer.limit_preload(1)                  -- number of images to preload
-- swayimg.viewer.limit_history(1)                  -- number of the history cache
swayimg.viewer.set_drag_button("MouseLeft")      -- mouse button to drag image
swayimg.viewer.set_window_background(0xff000000) -- window background color
swayimg.viewer.set_image_chessboard(20, 0xff333333, 0xff4c4c4c) -- chessboard
swayimg.viewer.set_mark_color(0xff808080)        -- mark icon color
swayimg.viewer.set_text("topleft", {             -- top left text block scheme
  "File: {name}",
  "Format: {format}",
  "File size: {sizehr}",
  "File time: {time}",
  "EXIF date: {meta.Exif.Photo.DateTimeOriginal}",
  "EXIF camera: {meta.Exif.Image.Model}"
})
swayimg.viewer.set_text("topright", {            -- top right text block scheme
  "Image: {list.index} of {list.total}",
  "Frame: {frame.index} of {frame.total}",
  "Size: {frame.width}x{frame.height}"
})
swayimg.viewer.set_text("bottomleft", {          -- bottom left text block scheme
  "Scale: {scale}"
})

-- Slide show mode, same config as for viewer mode with the following defaults:
swayimg.slideshow.set_timeout(5)                    -- timeout to switch image
swayimg.slideshow.set_default_scale("fit")          -- default image scale
swayimg.slideshow.set_window_background("auto")     -- window background mode
-- swayimg.slideshow.limit_history(0)                  -- number of the history cache
swayimg.slideshow.set_text("topleft", { "{name}" }) -- top left text block scheme

--------------------------------------------------
----                Gallery mode                  ----
--------------------------------------------------
swayimg.gallery.set_aspect("fill")                  -- thumbnail aspect ratio
swayimg.gallery.set_thumb_size(200)                 -- thumbnail size in pixels
swayimg.gallery.set_padding_size(5)                 -- padding between thumbnails
swayimg.gallery.set_border_size(5)                  -- border size for selected thumbnail
swayimg.gallery.set_border_color(0xffaaaaaa)        -- border color for selected thumbnail
swayimg.gallery.set_selected_scale(1.15)            -- scale for selected thumbnail
swayimg.gallery.set_selected_color(0xff404040)      -- background color for selected thumbnail
swayimg.gallery.set_unselected_color(0xff202020)    -- background color for unselected thumbnail
swayimg.gallery.set_window_color(0xff000000)        -- window background color
swayimg.gallery.limit_cache(100)                    -- number of thumbnails stored in memory
swayimg.gallery.enable_preload(false)               -- preloading invisible thumbnails
swayimg.gallery.enable_pstore(false)                -- enable persistent storage for thumbnails
swayimg.gallery.set_text("topleft", {               -- top left text block scheme
  "File: {name}"
})
swayimg.gallery.set_text("topright", {              -- top right text block scheme
  "{list.index} of {list.total}"
})

-- Key and mouse bindings in gallery mode (example only, not all):


--
-- Other configuration examples
--

-- force set scale mode on window resize (useful for tiling compositors)
swayimg.on_window_resize(function()
  swayimg.viewer.set_fix_scale("optimal")
end)

-- set a custom window title in gallery mode
swayimg.gallery.on_image_change(function()
  local image = swayimg.gallery.get_image()
  swayimg.set_title("Gallery: "..image.path)
end)

-- -- bind the Delete key in slide show mode to delete the current file and display a status message
-- swayimg.slideshow.on_key("Delete", function()
--   local image = swayimg.slideshow.get_image()
--   os.remove(image.path)
--   swayimg.text.set_status("File "..image.path.." removed")
-- end)


-- -- print paths to all marked files by pressing Ctrl-p in gallery mode
-- swayimg.gallery.on_key("Ctrl-p", function()
--   local entries = swayimg.imagelist.get()
--   for _, entry in ipairs(entries) do
--     if entry.mark then
--         print(entry.path)
--     end
--   end
-- end)
-- -- print paths to all marked files by pressing Ctrl-p in gallery mode
-- swayimg.gallery.on_key("Ctrl+p", function()
--   local entries = swayimg.imagelist.get()
--   for _, entry in ipairs(entries) do
--     if entry.mark then
--         print(entry.path)
--     end
--   end
-- end)

-- local modes = { "viewer", "gallery", "slideshow" }
-- for _, mode in ipairs(modes) do
--     local m = swayimg[mode]
--     m.on_key("Space", function()
--         m.switch_image("last")
--     end)
-- end

-- swayimg.viewer.on_key("e", function()
-- 	with_current_image(function(path)
-- 		os.execute(('%s'):format(shell_quote(path)))
-- 		os.execute('notify-send ""')
-- 	end)
-- end)

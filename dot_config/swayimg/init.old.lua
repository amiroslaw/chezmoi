-- Swayimg configuration
-- Override any option via: swayimg --config="general.mode=gallery"
--

local gallery = swayimg.gallery
local slideshow = swayimg.slideshow
local viewer = swayimg.viewer
local imagelist = swayimg.imagelist

----------------------------------
-- Helper functions
----------------------------------

local function bind(modes, key, action, arg)
  for _, m in ipairs(modes) do
    m.on_key(key, function()
      if type(action) == "string" then
        return m[action](arg)
      elseif type(action) == "function" then
        return action(arg)
      else
        return action()
      end
    end)
  end
end

local function mv(x, y)
  return function()
    local wnd = swayimg.get_window_size()
    local pos = viewer.get_position()
    viewer.set_abs_position(
      math.floor(pos.x + wnd.width * x),
      math.floor(pos.y + wnd.height * y)
    )
  end
end

local function zoom(dir)
  return function()
    local pos = swayimg.get_mouse_pos()
    local scale = viewer.get_scale()
    viewer.set_abs_scale(scale + (scale / 10) * dir, pos.x, pos.y)
  end
end

local info_shown = false
local function toggle_info()
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
    viewer.animation_stop()
    is_viewer_animation_running = false
  else
    viewer.animation_resume()
    is_viewer_animation_running = true
  end
end

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function with_current_image(fn)
  local image = nil
  local mode = swayimg.get_mode()
  if mode == "viewer" then
    image = viewer.get_image()
  elseif mode == "gallery" then
    image = gallery.get_image()
  elseif mode == "slideshow" then
    image = slideshow.get_image()
  end
  if image and image.path then
    fn(image.path)
  end
end

local function get_marked_paths()
  local entries = imagelist.get()
  local marked = {}
  for _, entry in ipairs(entries) do
    if entry.mark then
      table.insert(marked, entry.path)
    end
  end
  return marked
end

local function run_cmd(fmt, ...)
  os.execute(fmt:format(...))
end

----------------------------------
-- Key bindings
----------------------------------

local all_modes = { gallery, viewer, slideshow }
local nav_modes = { viewer, slideshow }

-- Global bindings (all modes)
bind(all_modes, "i", swayimg.text.show)
bind(all_modes, "Shift+i", toggle_info)
bind(all_modes, "q", swayimg.exit)
bind(all_modes, "g", "switch_image", "first")
bind(all_modes, "Shift+g", "switch_image", "last")
bind(all_modes, "Shift+r", "reload")
bind(all_modes, "m", "mark_image")

-- Navigation (viewer + slideshow)
bind(nav_modes, "p", "switch_image", "prev")
bind(nav_modes, "n", "switch_image", "next")
bind(nav_modes, "Space", "switch_image", "next")
bind(nav_modes, "Shift+p", "switch_image", "prev_dir")
bind(nav_modes, "Shift+n", "switch_image", "next_dir")
bind(nav_modes, "Ctrl+r", "switch_image", "random")
bind(nav_modes, "comma", "prev_frame")
bind(nav_modes, "period", "next_frame")

-- Gallery navigation
bind({ gallery }, "h", "switch_image", "left")
bind({ gallery }, "j", "switch_image", "down")
bind({ gallery }, "k", "switch_image", "up")
bind({ gallery }, "l", "switch_image", "right")
bind({ gallery }, "u", "switch_image", "pgdown")
bind({ gallery }, "d", "switch_image", "pgup")

-- Mode switching
bind({ gallery, slideshow }, "Return", swayimg.set_mode, "viewer")
viewer.on_key("t", function() swayimg.set_mode("gallery") end)
viewer.on_key("s", function() swayimg.set_mode("slideshow") end)

-- Viewer movement
viewer.on_key("l", mv(-0.05, 0))
viewer.on_key("h", mv(0.05, 0))
viewer.on_key("j", mv(0, -0.05))
viewer.on_key("k", mv(0, 0.05))
viewer.on_key("Shift+l", mv(-0.15, 0))
viewer.on_key("Shift+h", mv(0.15, 0))
viewer.on_key("Shift+j", mv(0, -0.15))
viewer.on_key("Shift+k", mv(0, 0.15))

-- Viewer scale modes
viewer.on_key("0", function() viewer.set_fix_scale("fit") end)
viewer.on_key("w", function() viewer.set_fix_scale("width") end)
viewer.on_key("Shift+w", function() viewer.set_fix_scale("height") end)
viewer.on_key("z", function() viewer.set_fix_scale("real") end)
viewer.on_key("Shift+z", function() viewer.set_fix_scale("fill") end)

-- Viewer transformations
viewer.on_key("backslash", function() viewer.flip_vertical() end)
viewer.on_key("Shift+bar", function() viewer.flip_horizontal() end)
viewer.on_key("bracketleft", function() viewer.rotate(90) end)
viewer.on_key("bracketright", function() viewer.rotate(270) end)
viewer.on_key("a", toggle_animation)

-- Gallery thumbnail size
gallery.on_key("0", function() swayimg.gallery.set_thumb_size(200) end)

--------------------------------------------------
--               custom functions               --
--------------------------------------------------

-- File operations
bind(all_modes, "Delete", function()
  with_current_image(function(path)
    os.remove(path)
    run_cmd('notify-send "File removed: %s"', shell_quote(path))
  end)
end)

bind(all_modes, "x", function()
  with_current_image(function(path)
    run_cmd("gomi %s", shell_quote(path))
    run_cmd('notify-send "File moved to the trash: %s"', shell_quote(path))
  end)
end)

bind(all_modes, "y", function()
	with_current_image(function(path)
		os.execute("printf %s " .. shell_quote(path) .. " | wl-copy")
		os.execute(('notify-send "Copied file path %s"'):format(path))
	end)
end)

bind(all_modes, "c", function()
  with_current_image(function(path)
    run_cmd('basename "%s" | wl-copy', path)
    run_cmd('notify-send "Copied file name "')
  end)
end)

bind(all_modes, "Ctrl+c", function()
  with_current_image(function(path)
    run_cmd("cat " .. shell_quote(path) .. " | wl-copy")
  end)
end)

bind(all_modes, "Ctrl+g", function()
  with_current_image(function(path)
    run_cmd("gimp " .. shell_quote(path))
  end)
end)

bind(all_modes, "e", function()
  with_current_image(function(path)
    run_cmd('satty --filename=%s', shell_quote(path))
  end)
end)

bind(all_modes, "o", function()
  with_current_image(function(path)
    run_cmd('tesseract "%s" "%s"', path, path)
    run_cmd('notify-send "OCR finished"')
  end)
end)

bind(all_modes, "r", function()
  with_current_image(function(path)
    run_cmd('"$XDG_CONFIG_HOME/swayimg/rename.sh" %s', shell_quote(path))
  end)
end)

-- File operations on marked files (Shift variants)
bind(all_modes, "Shift+Delete", function()
  for _, path in ipairs(get_marked_paths()) do
    os.remove(path)
    run_cmd('notify-send "File removed: %s"', shell_quote(path))
  end
end)

bind(all_modes, "Shift+x", function()
  for _, path in ipairs(get_marked_paths()) do
    run_cmd("gomi %s", shell_quote(path))
    run_cmd('notify-send "File moved to the trash: %s"', shell_quote(path))
  end
end)

bind(all_modes, "Shift+y", function()
  local paths = get_marked_paths()
  if #paths > 0 then
    local joined = table.concat(paths, "\n")
    os.execute("printf %s " .. shell_quote(joined) .. " | wl-copy")
    run_cmd('notify-send "Copied %d file paths"', #paths)
  end
end)

bind(all_modes, "Shift+c", function()
  local paths = get_marked_paths()
  if #paths > 0 then
    local basenames = {}
    for _, p in ipairs(paths) do
      local name = p:match("([^/]+)$")
      basenames[#basenames + 1] = name
    end
    local joined = table.concat(basenames, "\n")
    os.execute("printf %s " .. shell_quote(joined) .. " | wl-copy")
    run_cmd('notify-send "Copied %d file names"', #paths)
  end
end)

bind(all_modes, "Shift+o", function()
  for _, path in ipairs(get_marked_paths()) do
    run_cmd('tesseract "%s" "%s"', path, path)
  end
  run_cmd('notify-send "OCR finished on marked files"')
end)

-- Move to folder (1-9)
for i = 1, 9 do
  local key = tostring(i)
  bind(all_modes, key, function()
    local image = gallery.get_image()
    if image and image.path then
      run_cmd('mkdir -p %d && mv "%s" %d', i, image.path, i)
      run_cmd('notify-send "Moved to folder: %d"', i)
      imagelist.remove(image.path)
    end
  end)

  bind(all_modes, "Ctrl+" .. key, function()
    for _, path in ipairs(get_marked_paths()) do
      run_cmd('mkdir -p %d && mv "%s" %d', i, path, i)
      imagelist.remove(path)
    end
    run_cmd('notify-send "Moved to folder: %d"', i)
  end)
end

-- Mouse zoom
viewer.on_mouse("Ctrl-ScrollUp", function()
  local pos = swayimg.get_mouse_pos()
  local scale = viewer.get_scale()
  viewer.set_abs_scale(scale + scale / 10, pos.x, pos.y)
end)

viewer.on_key("Escape", swayimg.exit)

----------------------------------
-- Events
----------------------------------
swayimg.on_window_resize(function()
  viewer.set_fix_scale("optimal")
  slideshow.set_fix_scale("optimal")
end)

swayimg.gallery.on_image_change(function()
  local image = gallery.get_image()
  swayimg.set_title("Gallery: " .. image.path)
end)

----------------------------------
-- General config
----------------------------------

swayimg.set_mode("viewer")
swayimg.enable_overlay(true)
swayimg.enable_decoration(false)
swayimg.set_title("swayimg")
swayimg.enable_antialiasing(true)
swayimg.set_dnd_button("MouseRight")

----------------------------------
-- Image list configuration
----------------------------------

imagelist.set_order("numeric")
imagelist.enable_recursive(false)
imagelist.enable_adjacent(false)

----------------------------------
-- Text overlay configuration
----------------------------------

swayimg.text.hide()
swayimg.text.set_font("monospace")
swayimg.text.set_size(14)
swayimg.text.set_padding(7)
swayimg.text.set_foreground(0xffcccccc)
swayimg.text.set_background(0x00000000)
swayimg.text.set_shadow(0x0d000000)

----------------------------------
-- Viewer mode configuration
----------------------------------

viewer.set_default_scale("optimal")
viewer.set_default_position("center")
viewer.enable_centering(true)
viewer.enable_loop(true)
viewer.limit_preload(1)
viewer.set_drag_button("MouseLeft")
viewer.set_window_background(0xff000000)
viewer.set_image_chessboard(20, 0xff333333, 0xff4c4c4c)
viewer.set_mark_color(0xff808080)

viewer.set_text("topleft", {
  "File: {name}",
  "Format: {format}",
  "File size: {sizehr}",
  "File time: {time}",
  "EXIF date: {meta.Exif.Photo.DateTimeOriginal}",
  "EXIF camera: {meta.Exif.Image.Model}"
})

viewer.set_text("topright", {
  "Image: {list.index} of {list.total}",
  "Frame: {frame.index} of {frame.total}",
  "Size: {frame.width}x{frame.height}"
})

viewer.set_text("bottomleft", {
  "Scale: {scale}"
})

----------------------------------
-- Slideshow mode configuration
----------------------------------

slideshow.set_timeout(5)
slideshow.set_default_scale("fit")
slideshow.set_window_background("auto")
slideshow.set_text("topleft", { "{name}" })

----------------------------------
-- Gallery mode configuration
----------------------------------

gallery.set_aspect("fill")
gallery.set_thumb_size(200)
gallery.set_padding_size(5)
gallery.set_border_size(5)
gallery.set_border_color(0xffaaaaaa)
gallery.set_selected_scale(1.15)
gallery.set_selected_color(0xff404040)
gallery.set_unselected_color(0xff202020)
gallery.set_window_color(0xff000000)
gallery.limit_cache(100)
gallery.enable_preload(false)
gallery.enable_pstore(false)

gallery.set_text("topleft", { "File: {name}" })
gallery.set_text("topright", { "{list.index} of {list.total}" })

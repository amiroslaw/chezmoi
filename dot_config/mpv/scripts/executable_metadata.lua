local msg = require 'mp.msg'
msg.info("Metadata script loading...")

local function showMetadata()
	msg.info("Collecting metadata...")
	local properties = { 'title', 'comment', 'artist', 'date', 'description'}
	local metadata = {}
	for _,prop in ipairs(properties) do
		table.insert(metadata, '== ' .. prop)
		local val =	mp.get_property_osd("metadata/" .. prop)
		msg.verbose("Property " .. prop .. ": " .. tostring(val))
		table.insert(metadata,	val)
		table.insert(metadata, "")
	end
	local text = table.concat(metadata, '\n')

	local editor = os.getenv('GUI_EDITOR') or os.getenv('EDITOR') or 'xdg-open'
	local fileName = os.tmpname() .. '.adoc'
	msg.info("Writing metadata to " .. fileName .. " and opening with " .. editor)

	local file, err = io.open(fileName, 'w')
	if not file then
		msg.error("Could not open temp file for writing: " .. tostring(err))
		return
	end
	file:write(text)
	file:close()

	local cmd = string.format('%s "%s"', editor, fileName)
	msg.info("Executing command: " .. cmd)
	local res, exit_type, exit_code = os.execute(cmd)

	if res == 0 or res == true then
		msg.info("Editor closed successfully.")
	else
		msg.error("Command failed: " .. tostring(res) .. " (Type: " .. tostring(exit_type) .. ", Code: " .. tostring(exit_code) .. ")")
		os.execute('notify-send "could not open metadata in editor"')
	end
end

mp.add_forced_key_binding(nil, "show-metadata", showMetadata)

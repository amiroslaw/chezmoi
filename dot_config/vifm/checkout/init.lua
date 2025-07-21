--[[

Provides :MkCd command that creates some path and enters it reporting if
something went wrong.

Usage example:

    :MkCd dir/sub

--]]

local function checkout(info)

	test = info.path
	-- os.execute('notify-send ' .. test)
    local path = info.argv[1]
	-- os.execute('notify-send ' .. path)

	-- cmd = string.format("vim +%s +cgetbuffer +%s +bd! +cc%d %s", vifm.escape(tmp))
    local exitcode = vifm.run { cmd = 'notify-send ' .. 'test' }
    return exitcode == 0

end

local added = vifm.cmds.add {
    name = "Checkout",
    description = "Checkout git branch",
    handler = checkout,
    maxargs = 1,
}
if not added then
    vifm.sb.error("Failed to register :Checkout")
end

return {}

#!/bin/luajit

HELP = [[
Utils for working with notes.
note.lua clip|sel|write|-h [number]
List of the options:
	clip, clipboard - clip notes from secondary clipboard 
	sel, selection - clip notes from primary (selection) clipboard 
	write - write note form form input
	task - write task form form input
	number - number of clipboard history, if it will be empty, input form will appear
	-h help - write help

-- dependency: rofi, clipcat
]]
FILE_PATH = os.getenv('NOTE') ..  '/clip.adoc'
-- in todo.lua there is the same but with /Zadania/inbox.adoc
TASK_PATH = os.getenv('NOTE') ..  '/Zadania/day.adoc'
action = arg[1]

if not action then 
	notifyError('Provide argument')
end

function clipster(clipboard) 
	local clipType = clipboard
	return function()
		local clipboardAmount = 1
		if not arg[2] then clipboardAmount = rofiNumberInput('Number of clips') 
		else
			clipboardAmount = arg[2]
		end

		local clipElements = {}
		local clipsterOutput = io.popen("clipcat.clj " .. clipType .. " -n " .. clipboardAmount + 1):read('*a')
		assert(#clipsterOutput ~= 0, "Can not get clipboard history")
		return clipsterOutput
	end
end

function writeNote() 
	return '\n' .. rofiInput({prompt = 'Note', width = '70%'}) .. '\n'
end

function writeTask()
	local task = rofiInput({prompt = 'Task', width = '70%'}) .. '\n'
	os.execute(string.format('sed -i "1i * [ ] %s" %s', task, TASK_PATH))
end

function writeToFile(text) 
	file = io.open(FILE_PATH, "a+")
	file:write('\n' .. text)
	file:close()
	return 'Copied to ' .. FILE_PATH
end

local switch = (function(name)
	local sw = {
		["clip"]= clipster('join'),
		["clipboard"]= clipster('join'),
		["sel"]= clipster('primary'),
		["selection"]= clipster('primary'),
		["write"] = writeNote,
		["task"] = writeTask,
		["-h"]= function() print(HELP); os.exit() end,
		["#default"]= clipster('join'),
	}
	return (sw[name]and{sw[name]}or{sw["#default"]})[1]
end)

local exec = switch(action)
local ok, val = pcall(exec)

if not ok then
	log(val, 'ERROR')
	notifyError(val)
else
	local ok, out = pcall(writeToFile, val)
	notify(val)
end


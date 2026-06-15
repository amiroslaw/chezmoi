-- S-k - jump to help page
-- free keybinding leader-b/B
-- TODO
-- now I can remove duplication if I have 2 the same bindings for different modes 
-- for example nmap and vmap 
-- lsp_map to my function
-- correct x/o [local]leader
-- add shortcuts like in shell imap('<C-e>', 'normal A')
-- VARIABLES
local HOME = os.getenv 'HOME'

--{{{ lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
-- }}} 

-- Autocommands {{{
vim.api.nvim_create_autocmd( -- go to last loc when opening a buffe
	'BufReadPost',
	{
		command = [[if @% !~# '\.git[\/\\]COMMIT_EDITMSG$' && line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif]],
	}
)

local update_config = vim.api.nvim_create_augroup('update-chezmoi-config', { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
	group = update_config,
  pattern = os.getenv("HOME") .. "/.local/share/chezmoi/*",
  callback = function(args)
	  -- the --force flag, will override files in ~/.config
    vim.fn.system({ "chezmoi", "apply", "--force", "--source-path", args.file })
  end,
  desc = "Apply chezmoi changes after writing a chezmoi file",
})
-- has to be after chezmoi apply, but even that 
vim.api.nvim_create_autocmd("BufWritePost", {
	group = update_config,
  pattern = "*.fnl",
  callback = function(args)
    local file = vim.fn.expand("%:p")

    if not file:match("/.local/share/chezmoi/") then
      return
    end

    local home = os.getenv("HOME")
    local rel = file:gsub("^" .. home .. "/.local/share/chezmoi/", "")
    local out = home .. "/" .. rel:gsub("%.fnl$", ".lua"):gsub("^dot_", ".")
	vim.schedule(function()
		vim.fn.jobstart({
		  "sh", "-c",
		  "LUA=luajit fennel --compile " .. file .. " > " .. out
		})
    end)
  end,
})

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
	pattern = { '*.json' },
	command = [[set filetype=json]],
})
-- doesn't work well and runs plugin
-- vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
-- 	pattern = { '*.edn' },
-- 	command = [[set filetype=clojure]],
-- })

-- add a file to fasder index
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  callback = function(args)
    local file = args.file
    if file == "" then return end
    if vim.bo.buftype ~= "" then return end
    if vim.fn.filereadable(file) == 0 then return end
	local path = vim.fn.fnamemodify(file, ":p")
    if vim.fn.filereadable(path) == 0 then return end
    vim.system({ "fasder", "-A", path })
  end,
})

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
	pattern = { '/tmp/*' },
	command = [[set filetype=text]],
})
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
	pattern = { 'qutebrowser-editor-*', 'compose.txt', '/tmp/*.md', '/tmp/txt/*' },
	command = [[setlocal spell spelllang=en | startinsert]],
})
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
	pattern = { '*.{md,mdwn,mkd,mkdn,mark,markdown}' },
	command = [[set filetype=markdown]],
})
vim.api.nvim_create_autocmd( -- Prefer Neovim terminal insert mode to normal mode. IDK if it's default mode
	'BufEnter', {
	pattern = { 'term://*' },
	command = [[startinsert]],
})
vim.api.nvim_create_autocmd('TextYankPost', {
	command = 'silent! lua vim.highlight.on_yank {timeout=600}',
	group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }), -- clear true is default
})
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
	pattern = { '*.todo' },
	command = [[set filetype=todo]],
})
-- compile and execute 
local lang_maps = {
	python = { exec = "python %" },
	lua = { exec = "lua %" },
	fennel = { exec = "fennel %" },
	java = { build = "javac %", exec = "java %:r" },
	sh = { exec = "./%" },
	-- TODO
	typescript = { build = "deno compile %", exec = "deno run %" },
	javascript = { build = "deno compile %", exec = "deno run %" },
}
for lang, data in pairs(lang_maps) do
	if data.build ~= nil then
		vim.api.nvim_create_autocmd(
			"FileType",
			{ command = "nnoremap <Leader>c :!" .. data.build .. "<CR>", pattern = lang }
		)
	end
	vim.api.nvim_create_autocmd(
		"FileType",
		{ command = "nnoremap <Leader>e :split<CR>:terminal " .. data.exec .. "<CR>", pattern = lang }
	)
end
-- doesn't work with keybinding in zsh
-- autocmd BufDelete * if len(filter(range(1, bufnr('$')), '! empty(bufname(v:val)) && buflisted(v:val)')) == 1 | quit | endif 
-- }}} 

-- SETTINGS {{{
-- vim.o.ch = 0 -- hide command, from v8

-- New UI opt-in
require('vim._core.ui2').enable({})
vim.cmd("packadd nvim.undotree")
-- vim.cmd("packadd nvim.difftool")

vim.o.termguicolors = true
vim.b.buftype = '' -- fix Cannot write buftype option is set
vim.o.switchbuf   = 'usetab'       -- Use already opened buffers when switching
vim.o.laststatus = 3
-- vim.b.timeoutlen = 500 -- Time in milliseconds to wait for a mapped sequence to complete.
-- podpowiedzi
vim.o.wildmode = 'longest,list,full'
--" Status bar
vim.cmd 'filetype plugin indent on'
vim.o.encoding = 'utf-8'
vim.o.fileencoding = 'utf-8'
vim.o.fileencodings = 'utf-8', 'latin1'
vim.o.spelloptions  = 'camel' -- Treat camelCase word parts as separate words
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- it fixes nvim-cmp plugin

-- UI =========================================================================
vim.o.colorcolumn    = '+1'       -- Draw column on the right of maximum width
vim.o.number         = true       -- Show line numbers
vim.o.list           = true       -- Show helpful text indicators
-- vim.o.pumheight      = 10         -- Make popup menu smaller
vim.o.signcolumn     = 'yes'      -- Always show signcolumn (less flicker)
vim.o.splitkeep      = 'screen'   -- Reduce scroll during window split
vim.o.winborder      = 'single'   -- Use border in floating windows

-- Folds (see `:h fold-commands`, `:h zM`, `:h zR`, `:h zA`, `:h zj`)
vim.o.foldnestmax = 10       -- Limit number of fold levels
vim.o.foldlevelstart = 9 -- unfold at start - don't work after changes

-- IncSearch
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = true
-- substitution
--
vim.o.inccommand = 'split'
vim.o.clipboard = 'unnamedplus'
--vim.o.clipboard^='unnamedplus'
--vim.opt.clipboard:append('unnamedplus')

vim.o.smartindent = true
vim.opt.linebreak = true     -- Don't split words in the middle
vim.opt.breakindent = true   -- Indent wrapped lines to match the start of the line
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
-- vim.o.expandtab = true -- convert tab to spaces
vim.o.scrolloff = 5 -- margin
vim.o.hidden = true

--" highlighting cursor
vim.wo.cursorline = true
vim.wo.cursorcolumn = true

vim.opt.iskeyword:append('-') -- words separeted by - will recognise as a one word

-- diff mode
vim.opt.diffopt = {
"internal",
"filler",
"closeoff",
"context:12",
"algorithm:histogram",
"linematch:200",
"indent-heuristic",
"iwhite" -- I toggle this one, it doesn't fit all cases.
}

-- }}} 

-- SHORTCUTS {{{
-- map functions {{{

local key = vim.keymap.set
function map(mode, shortcut, command, desc, opts)
  if type(desc) == "table" and opts == nil then
    opts = desc
    desc = nil
  end
  opts = opts or {}
  if desc then opts.desc = desc end
  -- if opts.silent == nil then opts.silent = true end
  vim.keymap.set(mode, shortcut, command, opts)
end

function nmap(shortcut, command, desc, opts)
	map('n', shortcut, command, desc, opts)
end
function imap(shortcut, command, desc, opts)
	map('i', shortcut, command, desc, opts)
end
function vmap(shortcut, command, desc, opts)
	map('v', shortcut, command, desc, opts)
end
function tmap(shortcut, command, desc, opts)
	map('t', shortcut, command, desc, opts)
end
function xmap(shortcut, command, desc, opts)
	map('x', shortcut, command, desc, opts)
end
function omap(shortcut, command, desc, opts)
	map('o', shortcut, command, desc, opts)
end

function leader(mode, suffix, command, desc, opts)
  map(mode, '<leader>' .. suffix, command, desc, opts)
end
function nleader(suffix, command, desc, opts)
  map('n', '<leader>' .. suffix, command, desc, opts)
end
function vleader(suffix, command, desc, opts)
  map('v', '<leader>' .. suffix, command, desc, opts)
end

function locLeader(mode, suffix, command, desc, opts)
  map(mode, '<LocalLeader>' .. suffix, command, desc, opts)
end
function nlocLeader(suffix, command, desc, opts)
  map('n', '<LocalLeader>' .. suffix, command, desc, opts)
end

function vlocLeader(suffix, command, desc, opts)
  map('v', '<LocalLeader>' .. suffix, command, desc, opts)
end
-- }}} 
map({ 'n', 'v', 'o' }, ',', '<Nop>')
-- map({ 'n', 'v', 'o' }, 't', '<Nop>') -- doesn't fix the problem of not showing keybinding
nmap('t', '<Nop>', 'Disable t key')

vim.g.mapleader = ';'
vim.g.maplocalleader=" " --space
nmap('<F1>', ':messages<CR>', 'Open taskwarrior TUI')
nmap('<F5>', '<cmd>restart<cr>', 'Reload')
nmap('<F7>', ':!preview-ascii.sh % <CR>', 'adoc preview')

-- nmap('x', '"_x') -- doesn't add to register from `x`, will brake xp
nmap('<C-/>', ':nohlsearch<cr>', 'Clear search highlights')
nmap('<F4>', ':term taskwarrior-tui<CR>', 'Open taskwarrior TUI')
nmap(',l', '<cmd>luafile dev/init.lua<cr>', 'Reload dev init.lua', {}) -- for plugin development
nmap('Zz', ' :q! <cr>', 'Quit without saving')
imap('<c-z>', '<Esc>:wq<CR>', 'Save and quit')
-- nmap('ZZ', ' :write | bdelete!<cr>')

-- move lines up and down
nmap('<c-a-j>', ':m .+1<CR>', 'Move line down')
nmap('<c-a-k>', ':m .-2<CR>', 'Move line up')
imap('<c-A-j>', '<Esc>:m .+1<CR>==gi', 'Move line down')
imap('<c-A-k>', '<Esc>:m .-2<CR>==gi', 'Move line up')
vmap('<c-a-j>', ":m '>+1<CR>gv-gv", 'Move selected lines down')
vmap('<c-a-k>', ':m .-2<CR>gv=gv', 'Move selected lines up')

nmap('gf', '<c-w>gf', 'Go to file in new tab') -- open file in a new tab
vmap('gf', '<c-w>gf', 'Go to file in new tab')
nmap('gF', '<c-w>vgf', 'Go to file in vertical split') -- in vertical split
vmap('gF', '<c-w>vgf', 'Go to file in vertical split')

-- page scroll, override defaults
nmap('<C-d>', '<C-f> <cr>', 'Page down', { nowait = true })
imap('<C-d>', '<C-o><c-d>', 'Page down', { nowait = true })
nmap('<C-u>', '<C-b> <cr>', 'Page up')
imap('<C-u>', '<C-o><c-u>', 'Page up')
nmap('<C-a-d>', '<C-d> <cr>', 'Half page down')
nmap('<C-a-u>', '<C-u> <cr>', 'Half page up')
--folds
nmap('zn', ']z <cr>', 'Next fold start')
nmap('zp', '[z <cr>', 'Previous fold start')
nmap('zo', 'zO <cr>', 'Open all folds')
nmap('zO', 'zo <cr>', 'Open fold')

nmap('<Esc><Esc>', ':w<CR>', 'Save on double escape') -- saving 2x esc
-- TODO check out
nmap('<leader>sudo ', ':w !sudo tee % <CR><CR>', 'Save with sudo') -- leader to backslash \w saving as root
nmap('<S-X>', '<C-^>', 'Alternate file') -- alternate-file file that was last edited in the current window.

-- coping and pasting
-- nmap('P', ':pu<cr>') -- use yanky
-- TODO check out
nleader('P', [["_diwP]], 'Paste over same text') -- keep pasting over the same thing
nmap('Y', 'y$', 'Yank to end of line') -- from nvim 0.6 it's by default
imap('<C-v>', '<Esc>pa ', 'Paste')
-- move to the nexst/previous occurrence
nmap('<A-a>', '#', 'Previous occurrence')
nmap('<A-d>', '*', 'Next occurrence')
--" insert, redline bash shortcuts
-- move to the nexst/previous word/char; move to begginig/end of line
imap('<A-f>', '<C-o>w', 'Next word')
imap('<A-b>', '<C-o>b', 'Previous word')
imap('<C-f>', '<C-o>l', 'Right char')
imap('<C-b>', '<C-o>h', 'Left char')
imap('<C-a>', '<C-o>0', 'Start of line') -- or not blank _
imap('<C-e>', '<C-o>$', 'End of line') -- or not blank g_

-- jump paragraphs next line in insert mode
nmap('<C-j>', 'gj', 'Move down visual line')
nmap('<C-k>', 'gk', 'Move up visual line')
imap('<C-j>', '<Esc>gj', 'Move down visual line')
imap('<C-k>', '<Esc>gk', 'Move up visual line')
nmap('<C-l>', '{', 'Previous paragraph')
nmap('<C-h>', '}', 'Next paragraph')
vmap('<C-l>', '{', 'Previous paragraph')
vmap('<C-h>', '}', 'Next paragraph')
imap('<C-l>', '<Esc>{', 'Previous paragraph') -- can't override
imap('<C-h>', '<Esc>}', 'Next paragraph')


-- Tabs, windows and terminal{{{

-- Tabs
nmap('<tab>', 'gt', 'Next tab')
nmap('<s-tab>', 'gT', 'Previous tab')
nmap('<C-t>', ':tabnew<CR>', 'New tab')
-- nmap('<LocalLeader>ss', ':split<CR>')
-- nmap('<LocalLeader>sv', ':vs<CR>')

-- windows split also in terminal mode
tmap('<A-h>', '<C-\\><C-N><C-w>h', 'Move left in terminal')
tmap('<A-j>', '<C-\\><C-N><C-w>j', 'Move down in terminal')
tmap('<A-k>', '<C-\\><C-N><C-w>k', 'Move up in terminal')
tmap('<A-l>', '<C-\\><C-N><C-w>l', 'Move right in terminal')
imap('<A-h>', '<C-\\><C-N><C-w>h', 'Move left')
imap('<A-j>', '<C-\\><C-N><C-w>j', 'Move down')
imap('<A-k>', '<C-\\><C-N><C-w>k', 'Move up')
imap('<A-l>', '<C-\\><C-N><C-w>l', 'Move right')
nmap('<A-h>', '<C-w>h', 'Move left')
nmap('<A-j>', '<C-w>j', 'Move down')
nmap('<A-k>', '<C-w>k', 'Move up')
nmap('<A-l>', '<C-w>l', 'Move right')

-- Terminal
-- Make escape work in the Neovim terminal.
tmap('<Esc>', '<C-\\><C-n>', 'Escape from terminal')
-- Prefer Neovim terminal insert mode to normal mode.
nmap('<F2>', ':vsplit term://zsh<cr>', 'Open vertical terminal')
nmap('<F14>', ':split term://zsh<cr>', 'Open horizontal terminal') -- S-F2
-- }}} 

--""""""""""""""""""
--""""" NOTE TAKING
--dictionary
vim.cmd 'syntax spell toplevel'
--togle spellcheck
nmap('<C-A-s>', ':set spell!<cr> ', 'Toggle spellcheck')
nmap('<S-A-s>', ':setlocal spell spelllang=pl<cr>', 'Set Polish spellcheck')
imap('<S-A-s>', '<cmd>setlocal spell spelllang=pl<cr>', 'Set Polish spellcheck')
nmap('<A-s>', ':setlocal spell spelllang=en_us<CR>', 'Set English spellcheck')
imap('<A-s>', '<cmd>setlocal spell spelllang=en_us<CR>', 'Set English spellcheck')
nlocLeader('t', ':.!trans -shell pl:en -show-original n  -show-prompt-message n -show-languages n -no-ansi ', 'Translate PL to EN')
nlocLeader('T', ':.!trans -shell en:pl -show-original n  -show-prompt-message n -show-languages n -no-ansi ', 'Translate EN to PL')
nmap('<C-e>', 'z=', 'Spelling suggestions')
-- imap('<C-e>', '<C-o>z=') -- wrong? and occupied
nmap('<S-e>', '[s', 'Previous spelling error')
nmap('<a-e>', '[s1z=`]', 'Auto correct last spelling error') -- auto correction for the last occurrence
vmap('<a-e>', '[s1z=`]', 'Auto correct last spelling error')
imap('<a-e>', '<Esc>[s1z=`]a', 'Auto correct last spelling error')
-- capitalize The first word in the sentence and the word under the cursor
nlocLeader('U', '<c-(>~A', 'Capitalize word')
nlocLeader('u', 'b~A', 'Capitalize sentence')
-- imap('<LocalLeader>u', '<Esc><c-(>~A') -- find shortcut

--replace from selection/ substitution, produce error but it's workaround for showing command line mode
vmap('<A-r>', '"hy:%s/<C-r>h//g<left><left><cmd>', 'Replace visual selection')
-- vmap('<S-A-r>', '"hy:%s/<C-r>h/^M/g<left><left><cmd>') -- add special char for enter c-v enter
nmap('yu', ':let @+ = expand("%:p")<cr>', 'Copy file path to clipboard') -- copy current file path and name into clipboard
-- }}} 

-- TEXT OBJECTS {{{
-- current line e.g. yol
-- xmap('il', '^vg_')
xmap('ol', '^og_', 'Select line')
omap('ol', ':normal vol<CR>', 'Select line in operator mode')
-- all document
xmap('oa', ':<c-u>normal! G$Vgg0<cr>', 'Select all')
omap('oa', ':<c-u>normal! GVgg<cr>', 'Select all in operator mode') 
-- }}}

-- MACROS {{{
--"""" kindle put cursor on ===
vim.fn.setreg('k', 'd3joj' )
-- code
vim.fn.setreg('m', 'Vf{%y' ) -- copy method with curry bracket 
-- adoc
vim.fn.setreg('p', '$a  +j0') -- add `+` new line
vim.fn.setreg('h', 'pA[') -- link from selection
-- list l - unordered; o - ordered; z - task
vim.fn.setreg('l', '0i* ')
vim.fn.setreg('o', '0i. ')
vim.fn.setreg('z', '0i* [ ] ')
-- markdown
-- dwie spacje na koncu linii s
vim.fn.setreg('s', '$a  j0')
vim.fn.setreg('b', 'ggO- (pbi#bi[po') -- bookmarks should copy word
vim.fn.setreg('u', 'a]()hp0i[') -- markdown link
vim.fn.setreg('f', 'f)a kb  ') 
-- }}} 

-- PLUGINS {{{ 
	-- Move small configuration to plugins.lua, left only shortcuts
require("lazy").setup("plugins")
nmap('<F11>', ':Lazy<CR>', 'Open Lazy')

nmap('t;', ':AerialToggle<CR>', 'AerialToggle')


-- nmap('<leader>f', '<cmd> lua vim.lsp.buf.format() <cr>')
-- vmap('<leader>f', '<cmd> lua vim.lsp.buf.format() <cr>')

nleader("f", function()
    require("conform").format({ lsp_format = "fallback", })
end, "Format current file")

vmap("<leader>f", function()
    require("conform").format({ lsp_format = "fallback", })
end, "Format selection")

-- require("conform").formatters.stylua = {
-- 	args = { '--config-path', vim.fn.expand '~/.config/stylua/stylua.toml' },
-- }

-- nmap('<leader>f', '<cmd> lua conform.format() <cr>')
-- vmap('<leader>f', '<cmd> lua conform.format() <cr>')

--""""""""""""""""""
-- https://github.com/sbdchd/neoformat
vmap('<a-f>', ':Neoformat! java astyle <CR>', 'Format Java with astyle')
nmap('<a-f>', ':Neoformat! java astyle <CR>', 'Format Java with astyle')

--""""""""""""""""""
-- https://github.com/is0n/fm-nvim
nleader('w', ':TaskWarriorTUI <cr>', 'Open TaskWarrior TUI')
nmap('<F3>', ':Vifm<CR>', 'Open Vifm')
nleader('n', ':Vifm<CR>', 'Open Vifm')
nleader('N', ':Ranger<CR>', 'Open Ranger')
-- nmap(',g', ':Lazygit <cr>') -- neogit

--""""""""""""""""""
-- surround
-- visual mode  + S"
nleader('s', 'ysiW', 'Surround word with', { noremap = false }) -- surround a word
-- <leader>S witch-key
require("nvim-surround").setup({
    surrounds = {
            ["l"] =  { -- surround text and append url in asciidoc
				add = { {vim.fn.getreg("+") .. "["},{ "]"} }
			},
            ["L"] =  {
				add = {"", "[" .. vim.fn.getreg("+") .. "]"}
			}
    },
})

--""""""""""""""""""
-- jqx https://github.com/gennaro-tedesco/nvim-jqx
nmap('<leader>x', '<Plug>JqxList', 'List jqx results', { noremap = false })

--""""""""""""""""""
-- startify disable changing dir
vim.g.startify_change_to_dir = 0

--"""""""""""""""""
-- repeat
vim.cmd 'silent! call repeat#set("\\<Plug>MyWonderfulMap", v:count)'

-- https://github.com/folke/which-key.nvim
require("which-key").setup {
  preset = "helix",
  plugins = { spelling = { enabled = true, sugesstions = 20, ignore_missing = true }, },
}

-- {{{ nvim-autopairs https://github.com/windwp/nvim-autopairs?tab=readme-ov-file#fastwrap
require('nvim-autopairs').setup({
    fast_wrap = { map = '<M-t>', },
})
--}}}
-- taskmaker {{{
vlocLeader('w', '<cmd>TaskmakerAddTasks <CR>', 'Add tasks from selection')
nlocLeader('x', '<cmd>TaskmakerToggle <CR>', 'Toggle taskmaker') -- }}} 

-- Windows {{{
nleader('M', '<Cmd>WindowsToggleAutowidth<CR>', 'Toggle auto width')
nleader('m', '<Cmd>WindowsMaximize<CR>', 'Maximize window') -- }}} 

-- calendar.vim {{{
vim.cmd 'source ~/Documents/Ustawienia/private/calendar.vim'
vim.g.calendar_google_calendar = 1
vim.g.calendar_google_task = 1
vim.g.calendar_first_day = 'monday'
vim.g.calendar_calendar_candidates = {'arek', 'warrior', 'inwestycje'}
vim.g.calendar_views = {'month', 'day_7', 'day', 'agenda'} -- I'm not sure about agenda
vim.g.calendar_cyclic_view = 1

nmap('<F9>', ':Calendar -view=day_7<CR>', 'Open calendar week view')
nmap('<F21>', ':Calendar -view=year -split=horizontal -position=below -height=10 <CR>', 'Open calendar year view') -- shift F9 -- }}} 

-- marks {{{
-- https://github.com/chentoast/marks.nvim
require('marks').setup {
	mappings = {
		preview = 'm;', -- m;a show mark in popup
		set_bookmark0 = 'm0',
		toggle = 'mm', -- set_next = 'mm', it's the same
		delete_buf = 'mx',
		next = 'mn',
		prev = 'mp',
		next_bookmark = 'mN', -- next in the current group
		prev_bookmark = 'mP',
		delete_bookmark = 'mX',
		annotate = 'm/', -- only for groupmarks
	},
	bookmark_0 = { -- groupmarks remove by dm0
		sign = '⚑',
		virt_text = 'TODO',
	},
}
nmap('ml', ':MarksListBuf<cr>', 'List marks in buffer')
nmap('mA', ':MarksListAll<cr>', 'List all marks')
nmap('mL', ':BookmarksListAll<cr>', 'List all bookmarks') -- groupmarks
-- }}} 

-- undo tree  native {{{
nmap('<A-u>', ':Undotree<cr>', 'Toggle undo tree')
if vim.fn.has 'persistent_undo' == 1 then
	vim.o.undodir = HOME .. '/.local/share/nvim/undo'
	vim.o.undofile = true
end -- }}} 

-- lazyList {{{
nmap('glt', ":LazyList '.'<CR>", 'LazyList title') -- title
vmap('glt', ":LazyList '.'<CR>", 'LazyList title')
nmap('gll', ":LazyList '* '<CR>", 'LazyList unordered') -- unordered list
vmap('gll', ":LazyList '* '<CR>", 'LazyList unordered')
nmap('gll2', ":LazyList '** '<CR>", 'LazyList unordered level 2')
vmap('gll2', ":LazyList '** '<CR>", 'LazyList unordered level 2')
nmap('gll3', ":LazyList '*** '<CR>", 'LazyList unordered level 3')
vmap('gll3', ":LazyList '*** '<CR>", 'LazyList unordered level 3')
nmap('glo', ":LazyList '. '<CR>", 'LazyList ordered') -- ordered list
vmap('glo', ":LazyList '. '<CR>", 'LazyList ordered')
nmap('glo2', ":LazyList '.. '<CR>", 'LazyList ordered level 2')
vmap('glo2', ":LazyList '.. '<CR>", 'LazyList ordered level 2')
nmap('glo3', ":LazyList '... '<CR>", 'LazyList ordered level 3')
vmap('glo3', ":LazyList '... '<CR>", 'LazyList ordered level 3')
nmap('glz', ":LazyList '* [ ] '<CR>", 'LazyList task') -- task
vmap('glz', ":LazyList '* [ ] '<CR>", 'LazyList task')
nmap('glz2', ":LazyList '** [ ] '<CR>", 'LazyList task level 2')
vmap('glz2', ":LazyList '** [ ] '<CR>", 'LazyList task level 2')
nmap('glz3', ":LazyList '*** [ ] '<CR>", 'LazyList task level 3')
vmap('glz3', ":LazyList '*** [ ] '<CR>", 'LazyList task level 3')
nmap('gln', ":LazyList ':NOTE '<CR>", 'LazyList NOTE') --asciidoc admonitions
vmap('gln', ":LazyList ':NOTE '<CR>", 'LazyList NOTE')
nmap('gli', ":LazyList ':IMPORTANT '<CR>", 'LazyList IMPORTANT')
vmap('gli', ":LazyList ':IMPORTANT '<CR>", 'LazyList IMPORTANT')
nmap('glw', ":LazyList ':WARNING '<CR>", 'LazyList WARNING')
vmap('glw', ":LazyList ':WARNING '<CR>", 'LazyList WARNING')
nmap('glp', ":LazyList ':TIP '<CR>", 'LazyList TIP')
vmap('glp', ":LazyList ':TIP '<CR>", 'LazyList TIP')
nmap('glc', ":LazyList ':CAUTION '<CR>", 'LazyList CAUTION')
vmap('glc', ":LazyList ':CAUTION '<CR>", 'LazyList CAUTION')
nmap('gl1', ":LazyList '= '<CR>", 'LazyList header level 1') -- header
vmap('gl1', ":LazyList '= '<CR>", 'LazyList header level 1')
nmap('gl2', ":LazyList '== '<CR>", 'LazyList header level 2')
vmap('gl2', ":LazyList '== '<CR>", 'LazyList header level 2')
nmap('gl3', ":LazyList '=== '<CR>", 'LazyList header level 3')
vmap('gl3', ":LazyList '=== '<CR>", 'LazyList header level 3')
nmap('gl4', ":LazyList '==== '<CR>", 'LazyList header level 4')
vmap('gl4', ":LazyList '==== '<CR>", 'LazyList header level 4')
nmap('gl5', ":LazyList '===== '<CR>", 'LazyList header level 5')
vmap('gl5', ":LazyList '===== '<CR>", 'LazyList header level 5')
nmap('glmm', ":LazyList '- '<CR>", 'LazyList markdown unordered') -- markdown
vmap('glmm', ":LazyList '- '<CR>", 'LazyList markdown unordered')
nmap('glmo', ":LazyList '1. '<CR>", 'LazyList markdown ordered')
vmap('glmo', ":LazyList '1. '<CR>", 'LazyList markdown ordered')
-- }}} 

-- vim-asciidoctor {{{
--  https://github.com/habamax/vim-asciidoctor
nmap('<F19>', ':Asciidoctor2DOCX<CR>', 'Convert asciidoctor to DOCX') -- S-F7
vim.g.asciidoctor_syntax_conceal = 1
vim.g.asciidoctor_folding = 2
vim.g.asciidoctor_folding_level = 6
vim.g.asciidoctor_fenced_languages = { 'java', 'typescript', 'javascript', 'bash', 'html', 'xml', 'lua', 'css', 'sql', 'clojure', 'fennel' } -- 'fennel' 'kotlin' add syntax TODO
-- vim.g.asciidoctor_syntax_indented = 0
-- vim.g.asciidoctor_fold_options = 0
vim.g.asciidoctor_img_paste_command = 'xclip -selection clipboard -t image/png -o > %s%s'
nmap('<A-p>', ':AsciidoctorPasteImage<CR>', 'Paste image in asciidoctor') -- }}} 

-- vim-markdown syntax {{{
vim.g.vim_markdown_fenced_languages = 'java=java'
vim.g.vim_markdown_toc_autofit = 1
vim.g.vim_markdown_folding = 0
vim.g.vim_markdown_fold_options = 0
-- vim.g.vim_markdown_folding_level = 6
-- vim.g.vim_markdown_folding_style_pythonic = 1 -- }}} 

-- TAGBAR {{{
nmap('<leader>t', ':TagbarToggle<CR>', 'Toggle tagbar')
vim.g.tagbar_autoclose = 1
vim.g.tagbar_autofocus = 1
vim.g.tagbar_zoomwidth = 0
vim.g.tagbar_sort = 0
vim.wo.conceallevel = 3
vim.g.tagbar_type_asciidoctor = {
	ctagstype = 'asciidoc',
	kinds =  {
		'h:table of contents',
		'a:anchors:1',
		't:titles:1',
		'n:includes:1',
		'i:images:1',
		'I:inline images:1'
		}
}
vim.g.tagbar_type_markdown = {
    ctagstype = 'markdown',
    kinds = {'h:table of contents' }
 } -- }}} 

-- RestNvim {{{
-- https://github.com/NTBBloodbath/rest.nvim#usage
nmap('<leader>r', '<Plug>RestNvim<cr>', 'Run HTTP request', { noremap = false })
nmap('<leader>rr', '<Plug>RestNvimLast<cr>', 'Run last HTTP request', { noremap = false })
nmap('<leader>rp', '<Plug>RestNvimPreview<cr>', 'Preview HTTP request', { noremap = false }) -- }}} 

-- browser.nvim {{{
-- https://github.com/lalitmee/browse.nvim 
local bookmarks = {
    ['youtube'] = 'https://www.youtube.com/results?search_query=%s',
    ['map'] = 'https://www.google.com/maps?q=%s',
	['diki']= 'https://www.diki.pl/slownik-angielskiego?q=%s',
	['deepl'] ='https://www.deepl.com/en/translator#en/pl/%s',
    ['translator'] = 'https://translate.google.pl/?hl=pl#pl/en/%s',
    ['cambridge'] = 'https://dictionary.cambridge.org/spellcheck/english/?q=%s', 
    ['thesaurus'] = 'https://www.thesaurus.com/browse/%s?s=t',
    ['allegro']= 'https://allegro.pl/listing?string=%s',
	['ceneo']= 'https://www.ceneo.pl/;szukaj-%s',
    ['wiki-pl'] = 'https://pl.wikipedia.org/wiki/%s',
    ['wiki-en'] = 'https://en.wikipedia.org/wiki/%s',
    ['arch-wiki'] = 'https://wiki.archlinux.org/?search=%s',
    ['videos-brave'] = 'https://search.brave.com/videos?q=%s',
    ['brave'] = 'https://search.brave.com/search?q=%s',
	["gh"] = "https://github.com/search?q=%s",
	["gh_repo"] = "https://github.com/search?q=%s&type=repositories",
    ['AI-perplexity'] = 'https://www.perplexity.ai/search?q=%s',
    ['AI-phind'] = 'https://www.phind.com/search?q=%s',
    ['AI-felo'] = 'https://felo.ai/search?q=%s',
    ['AI-iask'] = 'https://iask.ai/?mode=question&options[detail_level]=concise&q=%s',
    ['AI-iask-advanced'] = 'https://iask.ai/?mode=advanced&options[detail_level]=comprehensive&q=%s',
    ['AI-you'] = 'https://you.com/search?fromSearchBar=true&tbm=youchat&q=%s',
	-- ["github"] = { -- in groups doesn't work selection 
 --      ["name"] = "Group: github",
 --      ["code_search"] = "https://github.com/search?q=%s&type=code",
 --      ["issues_search"] = "https://github.com/search?q=%s&type=issues",
 --      ["pulls_search"] = "https://github.com/search?q=%s&type=pullrequests",
  -- },
}
local browse = require('browse')
browse.setup({
  provider = "brave", -- duckduckgo, bing
  bookmarks = bookmarks
})

nmap('gs', ':execute "normal viw" | lua require"browse".input_search()<cr>', 'Search word')
vmap('gs', '<cmd>lua require"browse".input_search()<cr>', 'Search selection')
nmap('go', ':execute "normal viw" | lua require"browse".open_bookmarks()<cr>', 'Open bookmark for word')
vmap('go', '<cmd>lua require"browse".open_bookmarks()<cr>', 'Open bookmark for selection')
-- maybe chnage order to gbs; gbo; gwd
nmap('<Leader>ga', '<cmd>lua require"browse".browse()<cr>', 'Browse all') -- all options
nmap('<Leader>gss', ':execute "normal vis" | lua require"browse".input_search()<cr>', 'Search sentence') -- sentence
nmap('<Leader>gsb', ':execute "normal vib" | lua require"browse".input_search()<cr>', 'Search bracket') -- bracket
nmap('<Leader>gs"', [[:execute 'normal vi"' | lua require"browse".input_search()<cr>]], 'Search double quotes')
nmap("<Leader>gs'", [[:execute "normal vi'" | lua require"browse".input_search()<cr>]], 'Search single quotes')
nmap('<Leader>gos', ':execute "normal vis" | lua require"browse".open_bookmarks()<cr>', 'Open bookmark for sentence')
nmap('<Leader>gob', ':execute "normal vib" | lua require"browse".open_bookmarks()<cr>', 'Open bookmark for bracket')
nmap('<Leader>go"', [[:execute 'normal vi"' | lua require"browse".open_bookmarks()<cr>]], 'Open bookmark for double quotes')
nmap("<Leader>go'", [[:execute "normal vi'" | lua require"browse".open_bookmarks()<cr>]], 'Open bookmark for single quotes')
nmap('<Leader>gd', ':execute "normal viw" | lua require"browse.devdocs".search_with_filetype()<cr>', 'Search devdocs for word') -- search devdocs with context of filetype
vmap('<Leader>gd', '<cmd>lua require"browse.devdocs".search_with_filetype()<cr>', 'Search devdocs for selection') -- selection doesn't work
-- }}} 

-- Telescope {{{
--  https://github.com/nvim-telescope/telescope.nvim#pickers
-- excluded files and folders in .ignore
vim.o.maxmempattern = 3000 -- fix pattern uses more memory than 'maxmempattern', default is 2000


local telescope = require 'telescope'
if telescope then
-- TODO: it doesn't recognise filetype
local function aerial_collumn()
	local ft = vim.bo.filetype
	-- vim.notify("ft " .. ft, vim.log.levels.INFO)
	if ft == "asciidoctor" or ft == "asciidoc" then
	  -- Available modes: symbols, lines, both
	  return "lines"
	else
	  return "lines"
	  -- return "both"
	end
  end
local actions = require "telescope.actions"
local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
	telescope.setup {
		defaults = {
			prompt_prefix = '   ',
			file_ignore_patterns = { 'tags' },
			layout_strategy = 'flex', -- center, cursor
			width_padding = 30,
			layout_config = {
				flex = {
					flip_columns = 150, -- is less than that will act like the vertical strategy, and otherwise like the horizontal strategy.
				},
				horizontal = { width = 0.99, height = 0.99, preview_width = 0.7 },
				vertical = { width = 0.99, height = 0.99, preview_height = 0.7 },
			},
			mappings = { -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/mappings.lua
				i = {
					['<C-j>'] = 'move_selection_next',
					['<C-k>'] = 'move_selection_previous',
					-- ['<C-Space>'] = 'select_default',
					['<C-w>'] = 'which_key',
					['<C-n>'] = 'cycle_history_next',
					['<C-p>'] = 'cycle_history_prev',
					['<C-x>'] = actions.close, -- IDK why default c-c doesn't work
					['<C-h>'] = actions.select_horizontal,
					['<C-CR>'] = actions.file_tab,
					['<a-a>'] = actions.add_selected_to_qflist,
					['<a-q>'] = actions.smart_send_to_qflist + actions.open_qflist, -- send all if not selected
					["<C-space>"] = actions.to_fuzzy_refine, -- is it from telescope-live-grep-args.nvim, with out it refine for grep_word_under_cursor doesn't work?
						-- ["<cr>"] = function(bufnr) require("telescope.actions.set").edit(bufnr, "tab drop") end  
					},
				},
			},
		pickers = {
			buffers = { mappings = { i = { ["<CR>"] = actions.select_tab_drop } } },-- go to tab if open
				},
		  extensions = { 
			aerial = {
				show_columns = aerial_collumn()
			},
			  -- heading = { treesitter = true, picker_opts = { max_level = 6, }}, 
		  },
		}

	nmap('<c-s>', '<cmd>Telescope live_grep<cr>', 'Live grep')
	-- COOL
	nmap("<a-c-s>", live_grep_args_shortcuts.grep_word_under_cursor, 'Telescope live grep - under cursor') -- there is also grep_word_under_cursor_current_buffer
	vmap("<a-c-s>", live_grep_args_shortcuts.grep_visual_selection, 'Telescope live grep - visual')
	nmap('ts', '<cmd>Telescope grep_string grep_open_files=true<cr>', 'Grep string in open files') --  string under your cursor or selection in your current working directory
	nmap('tp', '<cmd>Telescope find_files<cr>', 'Find files')
	-- nmap('tp', '<cmd>Telescope find_files find_command=rg,--hidden,--files<cr>') -- with hidden files
	nmap('to', '<cmd>Telescope oldfiles<cr>', 'Recent files')
	nmap('tf', '<cmd>Telescope lsp_document_symbols symbols=function,method,constant<cr>', 'LSP symbols')
	nmap('td', '<cmd>Telescope diagnostics bufnr=0<cr> ', 'Diagnostics in current buffer')

	nmap('tl', '<cmd>Telescope current_buffer_fuzzy_find skip_empty_lines=true<cr>', 'Search in current buffer') -- lines in file
	nmap('tJ', '<cmd>Telescope jumplist sort_lastused=true <cr> ', 'Jumplist') -- I changed source code for showing only current file, idk if sort_lastused works
	nmap('ta', '<cmd>Telescope buffers ignore_current_buffer=true sort_mru=true show_all_buffers=false<cr>', 'Find buffers') -- closed files, and buffers
	nmap('tq', '<cmd>Telescope quickfix<cr> ', 'Quickfix list') -- quickfix history
	nmap('tb', '<cmd>Telescope git_branches<cr>', 'Git branches')
	nmap('tg', '<cmd>Telescope git_status<cr>', 'Git status')
	nmap('tn', '<cmd>Telescope loclist<cr> ', 'Location list')
	nmap('tc', '<cmd>Telescope commands <cr> ', 'Commands')
	nmap('th', '<cmd>Telescope help_tags<cr> ', 'Help tags') -- nivm api
	nmap('tH', '<cmd>Telescope command_history<cr> ', 'Command history')
	nmap('tK', '<cmd>Telescope keymaps<cr>', 'Keymaps')
	nmap('tr', '<cmd>Telescope registers<cr>', 'Registers')
	nmap('tk', '<cmd>Telescope spell_suggest<cr>', 'Spell suggestions')
	nmap('t/', '<cmd>Telescope search_history<cr> ', 'Search history')
	nmap('t1', '<cmd>Telescope man_pages<cr>', 'Man pages')
	nmap('tC', '<cmd>Telescope colorscheme<cr>', 'Colorschemes')
	nmap('tm', '<cmd>Telescope marks<cr>', 'Marks') -- list of the pickers
	nmap('ti', '<cmd>Telescope<cr>', 'Telescope picker list') -- list of the pickers
	telescope.load_extension 'jumps'
	nmap('tu', '<cmd>Telescope jumps changes <cr>', 'Jump changes')
	nmap('tj', '<cmd>Telescope jumps jumpbuff <cr>', 'Jump buffer')
	telescope.load_extension 'luasnip'
	nmap('tU', '<cmd>Telescope luasnip <cr>', 'Lua snippets')
	telescope.load_extension('smart_open')
	nmap('<c-f>', '<cmd>Telescope smart_open <cr>', 'Smart open')
	telescope.load_extension "aerial"
	nmap('tt', '<cmd>Telescope aerial<cr>', 'outline/header picker') -- list of the pickers
	-- telescope.load_extension 'heading' -- doesn't work with many entities 
	-- nmap('tt', '<cmd>Telescope heading sorting_strategy=ascending, <cr>', 'Heading search')
-- Reverses the list so the order is flipped inside the picker window
	-- nmap('tt', function()
	--   require('telescope').extensions.heading.heading({
	-- 	sorting_strategy = "ascending",
	-- 	layout_config = {
	-- 	  prompt_position = "top", -- Moves the input prompt to the top for natural reading
	-- 	},
	--   })
	-- end, 'Heading search')
	-- telescope.load_extension("yank_history") 
	-- nmap('ty', '<cmd>Telescope yank_history <cr>')
end -- }}} 

-- urlview {{{ 
-- https://github.com/axieax/urlview.nvim
nmap('<Leader>u', ':UrlView<cr>', 'View URLs in buffer') 
-- }}} 

-- previm {{{
--  https://github.com/previm/previm
vim.g.previm_open_cmd = 'firefox'
nmap('<leader>v', ':PrevimOpen <CR>', 'Open preview')
-- vim.g.previm_enable_realtime =  1
-- to change style turn 0 to 1 in previm_disable_default_css and put path to
vim.g.previm_disable_default_css = 1
vim.g.previm_custom_css_path = HOME .. '/.config/nvim/custom/md-prev.css' -- }}} 

-- yanky {{{
	-- maybe causes crash
-- https://github.com/gbprod/yanky.nvim#%EF%B8%8F-special-put
nmap('p', "<Plug>(YankyPutAfter)", 'Put after', { noremap = false })
nmap('P', "<Plug>(YankyPutAfterLinewise)", 'Put after linewise', { noremap = false })
-- nmap('y', "<Plug>(YankyYank)", { noremap = false }) -- preserve_cursor_position
nmap('<c-p>', ':YankyRingHistory <cr>', 'Yanky history') -- list; can be manage by Telescope
xmap('p', "<Plug>(YankyPutAfter)", 'Put after in visual', { noremap = false })
nmap("<A-n>", "<Plug>(YankyCycleForward)", 'Cycle yank forward', { noremap = false })
nmap("<A-p>", "<Plug>(YankyCycleBackward)", 'Cycle yank backward', { noremap = false }) 
-- }}} 

-- nvim-cmp {{{
-- https://github.com/hrsh7th/nvim-cmp
local cmp = require 'cmp'
cmp.setup {
    snippet = {
      expand = function(args)
        require'luasnip'.lsp_expand(args.body)
      end
    },
	mapping = {
		-- ['<CR>'] = cmp.mapping(cmp.mapping.confirm { select = true }, { 'i', 'c' }),
		-- https://github.com/hrsh7th/nvim-cmp/issues/1716 matchSuffix
		['<C-l>'] = cmp.mapping(cmp.mapping.confirm { select = true, behavior = cmp.ConfirmBehavior.Replace }, { 'i', 'c' }),
		['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select }, { 'i', 'c' }),
		['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select }, { 'i', 'c' }),
		['<C-e>'] = cmp.mapping { i = cmp.mapping.abort(), c = cmp.mapping.close() }, -- cancel autocomplation
		['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }), -- start popup menu
		['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
	},
	sources = { -- order is important
		{ name = 'luasnip', keyword_length = 1 },
		{ name = 'nvim_lsp' },
		{ name = 'buffer', keyword_length = 2, option = { keyword_pattern = [[\k\+]] } },
		{ name = 'nvim_lua' },
		{ name = 'path' },
		{ name = 'calc' },
	},
	completion = {
		completeopt = 'menu,menuone,noinsert',
		keyword_length = 3,
	},

	formatting = {
		format = function(entry, item)
			item.kind = ' '
			item.menu = ({
				buffer = '',
				luasnip = '',
				nvim_lsp = '',
				nvim_lua = '',
			path = '',
				calc = '',
				dictionary = '',
			})[entry.source.name]
			return item
		end,
	},
	experimental = {
		ghost_text = true -- like chatgpt virtual text
	  }
}
-- CMD mode - if you are in that mode and put / or : ' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
	sources = {
		{ name = 'buffer' },
	},
})
cmp.setup.cmdline(':', {
	sources = {
		{ name = 'cmdline' },
		{ name = 'cmdline_history' },
		{ name = 'path' },
	},
})

-- https://github.com/uga-rosa/cmp-dictionary
-- TODO limit output
cmp.setup.filetype({ 'markdown', 'asciidoctor', 'text' }, {
	sources = {
		{ name = 'luasnip', keyword_length = 1 }, 
		{ name = 'buffer', keyword_length = 2, option = { keyword_pattern = [[\k\+]] } },
		{ name = 'path' },
		{ name = 'calc' },
		{ name = 'dictionary' },
	}
})
local dict = require("cmp_dictionary")
local dirEn = HOME .. '/.config/rofi/scripts/expander/en-popular'
local dirPl = HOME .. '/.config/rofi/scripts/expander/pl-popular'

dict.setup {
	paths = { dirEn, dirPl },
	exact_length = 4, -- -1 only exact the same prefix; should be gratter than keyword_length
	-- max_number_items = 9,
	debug = false,
} 
-- }}}

-- gitsigns {{{
require('gitsigns').setup {
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns
		-- Navigation in diff-mode there are [c ]c
		nmap(',n', function()
			if vim.wo.diff then
				return ',n'
			end
			vim.schedule(function()
				gs.next_hunk()
			end)
			return '<Ignore>'
		end, 'GIT: Next hunk', { expr = true, buffer = bufnr })
 
		nmap(',p', function()
			if vim.wo.diff then
				return ',p'
			end
			vim.schedule(function()
				gs.prev_hunk()
			end)
			return '<Ignore>'
		end, 'GIT: prev hunk', { expr = true, buffer = bufnr })
		-- can be convert to  vim.keymap.set
		nmap(',r', ':Gitsigns reset_hunk<CR>', 'Reset hunk')
		vmap(',r', ':Gitsigns reset_hunk<CR>', 'Reset hunk')
		nmap(',v', '<cmd>Gitsigns preview_hunk_inline<CR>', 'Preview hunk')
		-- nmap(',d', '<cmd>Gitsigns diffthis<CR>')
		nmap(',D', '<cmd>lua require"gitsigns".diffthis("~")<CR>', 'Diff this against HEAD')
		nmap(',t', '<cmd>Gitsigns toggle_deleted<CR>', 'Toggle deleted')
		nmap(',l', '<cmd>Gitsigns setloclist<CR>', 'Set location list') -- quickfix setqflist

		-- Text object
		omap('oh', ':<C-U>Gitsigns select_hunk<CR>', 'Select hunk operator')
		xmap('oh', ':<C-U>Gitsigns select_hunk<CR>', 'Select hunk visual')
	end,
} -- }}} 

--{{{ diffview https://github.com/sindrets/diffview.nvim
local actions = require("diffview.actions")
local function toggle_diffview(cmd)
  if next(require("diffview.lib").views) == nil then
    vim.cmd(cmd)
    vim.cmd("DiffviewToggleFiles")
  else
    vim.cmd("DiffviewClose")
  end
end
nmap(',h', function() toggle_diffview('DiffviewFileHistory') end, 'Diffview view history files in repo.')
nmap(',F', function() toggle_diffview('DiffviewFileHistory %') end, 'Diffview view history for the current file.')
nmap(',f', function() toggle_diffview('DiffviewFileHistory % --base=LOCAL') end, 'Diffview view history for the current file. Local base.')
nmap(',d', function() toggle_diffview('DiffviewOpen') end, 'Diffview')
nmap(',m', function() toggle_diffview('DiffviewOpen master') end, 'Diffview master')

require("diffview").setup({
  enhanced_diff_hl = true, -- See |diffview-config-enhanced_diff_hl|
  use_icons = true,         -- Requires nvim-web-devicons
  show_help_hints = true,   -- Show hints for how to open the help panel
  watch_index = true,       -- Update views and index buffers when the git index changes.
  view = { -- For more info, see |diffview-config-view.x.layout|.
    --    |'diff3_horizontal' |'diff3_mixed' |'diff4_mixed'
    merge_tool = {
      layout = "diff3_horizontal",
      disable_diagnostics = true,   -- Temporarily disable diagnostics for diff buffers while in the view.
      winbar_info = true,           -- See |diffview-config-view.x.winbar_info|
    },
  },

  keymaps = {
    disable_defaults = false, -- Disable the default keymaps
    view = {
      -- The `view` bindings are active in the diff buffers, only when the current
      -- tabpage is a Diffview.
      { "n", ",p",      "[c"    ,                  { desc = "jump to the previous conflict" } },
      { "n", ",n",         "]c" ,                  { desc = "jump to the next conflict" } },
      { "n", "[x",          actions.prev_conflict,                  { desc = "In the merge-tool: jump to the previous conflict" } },
      { "n", "]x",          actions.next_conflict,                  { desc = "In the merge-tool: jump to the next conflict" } },
    },
  },
}) --}}} 

--{{{ neogit https://github.com/NeogitOrg/neogit
local neogit = require('neogit')
nmap(",g", neogit.open, "Open Neogit UI")
nmap(",hp", "<cmd>Neogit pull<CR>", "Neogit pull")
nmap(",hP", "<cmd>Neogit push<CR>", "Neogit push")
nmap(",b", ":Telescope git_branches<CR>", "Neogit push", { silent = true })
nmap(",cn", "<cmd>Neogit commit<CR>", "Neogit commit")
nmap(",ca", function()
  neogit.actions.stage.stage_all()
  neogit.open({ "commit" })
end, "Stage all and commit")

nmap(",cc", function()
  local msg = vim.fn.input("Commit message: ")
  if msg ~= "" then
    vim.fn.system("git add -u")
    vim.fn.system("git commit -m " .. vim.fn.shellescape(msg))
    print("Committed with message: " .. msg)
  else
    print("Commit aborted: no message provided")
  end
end, { desc = "Stage all untracked and commit with prompt" })

nmap(",s", function()
  local msg = vim.fn.input("Stash message: ")
  if msg ~= "" then
    vim.fn.system("git stash push -m " .. vim.fn.shellescape(msg))
    print("Stashed with message: " .. msg)
  else
    print("Stash aborted: no message provided")
  end
end, "Stash with prompt")

nmap(",ca", function()
	vim.fn.system("git add -u")
	vim.fn.system("git commit --amend --no-edit")
	print("Amended last commit with staged changes (message unchanged)")
end, "Amend tracked")

neogit.setup {
graph_style = "kitty",
} --}}} 

-- translate {{{
--https://github.com/uga-rosa/translate.nvim
-- let g:deepl_api_auth_key = 'MY_AUTH_KEY'
-- command = "deepl_free", -- require credit card
xmap('<LocalLeader>ee', '<Cmd>Translate EN -source=PL<CR>', 'Translate PL to EN')
nmap('<LocalLeader>ee', '<Cmd>Translate EN -source=PL<CR>', 'Translate PL to EN')
nmap('<LocalLeader>er', 'viw:Translate EN -source=PL -output=replace<CR>', 'Translate word PL to EN and replace')
xmap('<LocalLeader>er', 'viw:Translate EN -source=PL -output=replace<CR>', 'Translate selection PL to EN and replace')
nmap('<LocalLeader>pp', '<Cmd>Translate PL -source=EN<CR>', 'Translate EN to PL')
xmap('<LocalLeader>pp', '<Cmd>Translate PL -source=EN<CR>', 'Translate EN to PL')
nmap('<LocalLeader>pr', 'viw:Translate PL -source=EN -output=replace<CR>', 'Translate word EN to PL and replace')
xmap('<LocalLeader>pr', 'viw:Translate PL -source=EN -output=replace<CR>', 'Translate selection EN to PL and replace')
-- }}} 

-- grammarous {{{
vim.g['grammarous#use_vim_spelllang'] = 1
-- vim.g['grammarous#enable_spell_check'] = 1
-- https://github.com/rhysd/vim-grammarous/issues/110#issuecomment-1404863074
vim.g['grammarous#jar_url'] = 'https://www.languagetool.org/download/LanguageTool-5.9.zip' 
nlocLeader('cc', '<cmd>GrammarousCheck --lang=en<CR>', 'Grammar check English')
nlocLeader('cp', '<cmd>GrammarousCheck --lang=pl <CR>', 'Grammar check Polish')
nlocLeader('ch', '<Plug>(grammarous-move-to-previous-error)', 'Previous grammar error', { noremap = false }) -- Move cursor to the previous error
nlocLeader('cl', '<Plug>(grammarous-move-to-next-error)', 'Next grammar error', { noremap = false }) -- Move cursor to the next error
nlocLeader('cf', '<Plug>(grammarous-fixit)', 'Fix grammar error', { noremap = false }) --	Fix the error under the cursor automatically
 -- }}} 

-- nap-nvim {{{
-- Quickly jump between next and previous NeoVim buffer, tab, file, spell, change list, jump list quickfix, diagnostic, etc. 
require("nap").setup({
    next_prefix = "<a-o>",
    prev_prefix = "<a-i>",
    next_repeat = "<c-o>",
    prev_repeat = "<c-i>",
    operators = {   ["c"] = {
        next = { rhs = '<Plug>(grammarous-move-to-next-error)', opts = {desc = "grammarous-move-to-next", noremap = false} },
        prev = { rhs = '<Plug>(grammarous-move-to-previous-error)', opts = {desc = "grammarous-move-to-prev", noremap = false} },
        mode = { "n" },
    }, },
})
-- }}} 

-- ZenMode {{{
-- https://github.com/folke/zen-mode.nvim
nmap('<F6>', ':ZenMode <CR>', 'Toggle Zen mode')
-- }}} 

-- LuaSnip {{{
nmap('<F16>', '<cmd>lua require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/luasnippets/"})<cr>', 'Reload LuaSnippets')
nmap('<F17>', '<cmd>lua require("luasnip.loaders").edit_snippet_files()<CR>', 'Edit snippet files') -- S-F5
local ls = require("luasnip")
-- tab stopped work
-- vim.keymap.set({"i", "s"}, "<TAB>", function() if ls.expand_or_jumpable() then ls.expand_or_jump() end end, {silent = true})
-- vim.keymap.set({"i", "s"}, "<S-TAB>", function() ls.jump(-1) end, {silent = true})

-- TODO convert to map
vim.cmd[[
imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 
smap <silent><expr> <Tab> luasnip#jumpable(1) ? '<Plug>luasnip-jump-next' : '<Tab>' 
imap <silent><expr> <S-Tab> luasnip#jumpable(-1) ? '<Plug>luasnip-jump-prev' : '<S-Tab>' 
smap <silent><expr> <S-Tab> luasnip#jumpable(-1) ? '<Plug>luasnip-jump-prev' : '<S-Tab>' 
]]

map({"i", "s"}, "<C-h>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, 'luasnip next choice', {silent = true})
-- }}} 

--{{{ ogpt https://github.com/huynle/ogpt.nvim
nlocLeader('oo', '<cmd>OGPT<CR>', 'OGPT')
nlocLeader('oa', '<cmd>OGPTActAs<CR>', 'OGPTActAs')
locLeader({"n", "v"}, 'oe', "<cmd>OGPTEditWithInstruction<CR>", "Edit with instruction")
locLeader({"n", "v"}, 'oc', "<cmd>OGPTRun grammar-append<CR>", "Grammar Correction")
imap('<c-x>', "<esc><cmd>OGPTRun grammar-append<CR>", "Grammar Correction")
locLeader({"n", "v"}, 'oC', "<cmd>OGPTRun grammar-append-explain<CR>", "Grammar Correction with explanation")
locLeader({"n", "v"}, 'ol', "<cmd>OGPTRun translate-append<CR>", "Translate to english")
locLeader({"n", "v"}, 'oL', "<cmd>OGPTRun translate-append polish<CR>", "Translate to polish")
locLeader({"n", "v"}, 'ok', "<cmd>OGPTRun keywords<CR>", "Keywords")
locLeader({"n", "v"}, 'oj', "<cmd>OGPTRun javdoc<CR>", "Java documentation")
locLeader({"n", "v"}, 'ot', "<cmd>OGPTRun add_tests<CR>", "Add Tests")
locLeader({"n", "v"}, 'oi', "<cmd>OGPTRun optimize_code<CR>", "Optimize Code")
locLeader({"n", "v"}, 'os', "<cmd>OGPTRun summarize<CR>", "Summarize")
locLeader({"n", "v"}, 'ob', "<cmd>OGPTRun fix_bugs<CR>", "Fix Bugs")
locLeader({"n", "v"}, 'ox', "<cmd>OGPTRun explain_code<CR>", "Explain Code")
locLeader({"n", "v"}, 'or', "<cmd>OGPTRun code_readability_analysis<CR>", "Code Readability Analysis")
locLeader({"n", "v"}, 'of', "<cmd>OGPTRun format-adoc table<CR>", "Format asciidoc table")
--}}} 

-- {{{  Substitute. nvim  https://github.com/gbprod/substitute.nvim
require("substitute").setup({
  on_substitute = require("yanky.integration").substitute(),
})
nlocLeader('s', require('substitute').operator, 'Substitute [text object]', { noremap = true })
nlocLeader('ss', require('substitute').line, 'Substitute - line', { noremap = true })
nlocLeader('S', require('substitute').eol, 'Substitute - eol', { noremap = true })
xmap('<LocalLeader>s', require('substitute').visual, 'Substitute', { noremap = true })
-- range, idk how does it work it alway apply to a paragraph
nmap('<S-A-r>', require('substitute.range').word, 'Substitute - range under a word', { noremap = true })
-- nmap('<A-r>', function() require('substitute.range').word({range = { motion = '%' }}) end, { noremap = true, desc ='Substitute - word in file'}) -- it doesn't work for whole file 
--}}}

--}}}

-- LSP Tree-sitter Diagnostics {{{

require("mason").setup()

vim.lsp.enable({
	'marksman',
	"bashls",
	"docker_language_server",
	"fennel_ls",
	"clojure_lsp",
	"lua_ls",
	"templ",
-- 'java_language_server'
  -- "css_ls",
  -- "html_ls",
})

-- 1. Configure nvim definitions
local current_file = vim.api.nvim_buf_get_name(0)
local is_nvim_config = vim.fs.root(current_file, { "init.lua" }) and string.match(current_file, "nvim")

local lua_library = {}
if is_nvim_config then
  lua_library = {
    vim.env.VIMRUNTIME,
    vim.fs.joinpath(vim.env.VIMRUNTIME, "lua"),
  }
end

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        checkThirdParty = false,
        library = lua_library,
      },
      completion = { callSnippet = "Replace" },
    },
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
  callback = function(event)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if client and client:supports_method("textDocument/completion") then
	  vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
	end
		local lsp_map = function(keys, func, desc, mode)
			mode = mode or 'n'
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
		end
		-- HELP
		-- hover on fun - doc and params list
		-- TODO convert to my map ??
		nmap('grs', vim.lsp.buf.signature_help, 'LSP: [S]ignature help', { buffer = event.buf})
		lsp_map('grh', vim.lsp.buf.hover, '[H]over')

		-- Rename the variable under your cursor.
		lsp_map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

		-- JUMP
		-- Jump to the definition of the word under your cursor.
		--  This is where a variable was first declared, or where a function is defined, etc.
		--  To jump back, press <C-t>.
		lsp_map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
		-- Find references for the word under your cursor.
		lsp_map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
		-- Jump to the implementation of the word under your cursor.
		--  Useful when your language has ways of declaring types without an actual implementation.
		lsp_map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
		-- WARN: This is not Goto Definition, this is Goto Declaration.
		--  For example, in C this would take you to the header.
		lsp_map('grd', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

		-- FIND
		-- Fuzzy find all the symbols in your current document.
		--  Symbols are things like variables, functions, types, etc.
		lsp_map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
		-- Fuzzy find all the symbols in your current workspace.
		--  Similar to document symbols, except searches over your entire project.
		lsp_map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

		-- Diagnostic
		lsp_map('gre', require('telescope.builtin').diagnostics, 'Show [E]rrors')
		lsp_map(',j', function() vim.diagnostic.jump({count= 1,float = true}) end, 'Go to next error')
		lsp_map(',k', function() vim.diagnostic.jump({count= -1,float = true}) end, 'Go to prev error')

		-- Execute a code action, usually your cursor needs to be on top of an error
		-- or a suggestion from your LSP for this to activate.
		lsp_map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

		-- Jump to the type of the word under your cursor.
		--  Useful when you're not sure what type a variable is and you want to see
		--  the definition of its *type*, not where it was *defined*.
		lsp_map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Keep foldmethod=marker from modeline even with the LSP",
  callback = function(args)
    local bufnr = args.buf
    -- Gets the first and last 5 lines of the file (usually the modeling is there)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 5, false)
    local last_lines = vim.api.nvim_buf_get_lines(bufnr, -5, -1, false)
    for _, line in ipairs(last_lines) do table.insert(lines, line) end

    local has_marker_modeline = false
    for _, line in ipairs(lines) do
      if line:match("foldmethod=marker") or line:match("fdm=marker") then
        has_marker_modeline = true
        break
      end
    end

    if has_marker_modeline then
      vim.schedule(function()
        vim.wo.foldmethod = "marker"
      end)
    end
  end,
})

-- Increase alt-enter; decrease alt-backspace selection
vim.keymap.set({'n', 'x', 'i'}, '<A-CR>', function()
	if vim.api.nvim_get_mode().mode == 'i' then
		vim.cmd('normal! <C-O>')
	end
	require('vim.treesitter._select').select_parent(vim.v.count1)
end, {desc = "Increase selection"})

vim.keymap.set('x', '<A-BS>', function()
	require('vim.treesitter._select').select_child(vim.v.count1)
end, {desc = "Decrease selection"})

-- -- Diagnostic Config See :help vim.diagnostic.Opts
vim.diagnostic.config({
	virtual_lines = true,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
	},
	-- virtual_text = true,
	--underline = true,
-- 	underline = { severity = vim.diagnostic.severity.ERROR },
-- 	virtual_text = {
-- 		source = "if_many",
-- 		spacing = 2,
-- 		format = function(diagnostic)
-- 			local diagnostic_message = {
-- 				[vim.diagnostic.severity.ERROR] = diagnostic.message,
-- 				[vim.diagnostic.severity.WARN] = diagnostic.message,
-- 				[vim.diagnostic.severity.INFO] = diagnostic.message,
-- 				[vim.diagnostic.severity.HINT] = diagnostic.message,
-- 			}
-- 			return diagnostic_message[diagnostic.severity]
-- 		end,
-- 	},
})

--{{{ markview https://github.com/OXY2DEV/markview.nvim
require("markview").setup({
	enable = false,
    preview = {
		map_gx = true,
		enable_hybrid_mode = true,
		},
    yaml = {
		enable = true,
		},
    asciidoc_inline = {
		enable = false, -- this plugin does't work good with adoc
		},
    asciidoc = {
		enable = false,
		section_titles = {
			shift_width = 1,
		},
    },
	markdown = {
        headings = {
            heading_1 = { icon_hl = "@markup.link", icon = "[%d] " },
            heading_2 = { icon_hl = "@markup.link", icon = "[%d.%d] " },
            heading_3 = { icon_hl = "@markup.link", icon = "[%d.%d.%d] " }
        }, },
})
require("markview.extras.editor").setup();
require("markview.extras.headings").setup();
require("markview.extras.checkboxes").setup();
--}}} 

-- }}} 

-- COLORSCHEMES {{{
local function getBackground(hour)
		local hour = hour and hour or 20
		local currentHour = tonumber(os.date '%H')
		if currentHour > 5 and currentHour < hour then
			return 'light'
		else
			return 'dark'
		end
end
-- vim.cmd 'colorscheme catppuccin-nvim'
-- vim.cmd 'colorscheme flattened_light'
-- vim.cmd [[let ayucolor="light" ]]
local colorscheme_default = "solarized8_high"
local colorscheme_treesitter = "tokyonight-storm"
vim.g.tokyonight_style = "moon"

vim.cmd("colorscheme " .. colorscheme_treesitter)
local adoc_theme_group = vim.api.nvim_create_augroup("AdocThemeToggler", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = adoc_theme_group,
    -- Nasłuchujemy wejścia do KAŻDEGO pliku, aby precyzyjnie kontrolować globalny motyw
    pattern = "*",
    callback = function()
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(0) then return end
            
            local ft = vim.bo.filetype
            
            if ft == "asciidoc" or ft == "asciidoctor" then
                if vim.g.colors_name ~= colorscheme_default then
                    vim.cmd("colorscheme " .. colorscheme_default)
                    vim.opt.background = getBackground()
                end
            else
                if vim.g.colors_name ~= colorscheme_treesitter then
                    vim.cmd("colorscheme " .. colorscheme_treesitter)
                end
            end
        end)
    end,
})

-- }}} 

-- set complete+=kspell spellcheck complete
-- vim: foldmethod=marker

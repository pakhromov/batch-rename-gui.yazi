local get_selected = ya.sync(function(_)
	local paths = {}
	for _, file in pairs(cx.active.selected) do
		paths[#paths + 1] = tostring(file.url)
	end
	return paths
end)

local function fail(s)
	ya.notify({ title = "smart-rename", content = s, level = "error", timeout = 5 })
end

return {
	entry = function(_, job)
		local paths = get_selected()

		if #paths <= 1 then
			ya.emit("rename", { cursor = "before_ext" })
			return
		end

		local exe, args
		if job and job.args and job.args[1] then
			exe = job.args[1]
			args = {}
			for i = 2, #job.args do args[#args + 1] = job.args[i] end
		else
			local editor = os.getenv("VISUAL") or os.getenv("EDITOR")
			if not editor then
				return fail("No editor configured. Set $VISUAL or $EDITOR, or pass one via: plugin smart-rename -- <editor>")
			end
			-- Split "editor flags" into exe + args
			local parts = {}
			for part in editor:gmatch("%S+") do parts[#parts + 1] = part end
			exe = table.remove(parts, 1)
			args = parts
		end

		local tmp_out = Command("mktemp"):output()
		if not tmp_out then return fail("Failed to create temp file") end
		local tmp = tmp_out.stdout:gsub("%s+$", "")

		local f = io.open(tmp, "w")
		if not f then return fail("Failed to write temp file") end
		for _, path in ipairs(paths) do
			f:write((path:match("([^/]+)$") or path) .. "\n")
		end
		f:close()

		-- Open editor in background — inotifywait handles the wait
		args[#args + 1] = tmp
		Command(exe):arg(args):spawn()

		-- Block until the file is saved
		local inotify = Command("inotifywait")
			:arg({ "-e", "close_write,modify", tmp })
			:stderr(Command.NULL)
			:spawn()
		if inotify then inotify:wait() end

		local rf = io.open(tmp, "r")
		if not rf then return fail("Failed to read temp file") end
		local new_names = {}
		for line in rf:lines() do new_names[#new_names + 1] = line end
		rf:close()

		if #new_names ~= #paths then
			return fail(string.format(
				"Line count mismatch: expected %d, got %d. No files renamed.",
				#paths, #new_names
			))
		end

		local function free_dest(dir, name)
			local dest = dir .. "/" .. name
			if not fs.cha(Url(dest)) then return dest end
			local stem, ext = name:match("^(.+)(%.[^%.]+)$")
			if not stem then stem, ext = name, "" end
			local i = 1
			while true do
				dest = dir .. "/" .. stem .. "_" .. i .. ext
				if not fs.cha(Url(dest)) then return dest end
				i = i + 1
			end
		end

		for i, old_path in ipairs(paths) do
			local new_name = new_names[i]
			local old_name = old_path:match("([^/]+)$") or old_path
			if new_name and new_name ~= "" and new_name ~= old_name then
				local dir = old_path:match("^(.+)/[^/]+$") or "."
				Command("mv"):arg({ old_path, free_dest(dir, new_name) }):status()
			end
		end
	end,
}

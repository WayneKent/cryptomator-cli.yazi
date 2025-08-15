local get_vault_path = ya.sync(function()
	local current_dir_files = cx.active.current.files

	local has_cryptomator_file = false

	for i = 1, #current_dir_files do
		local file = current_dir_files[i]
		if file then
			local url = file.url
			local name = url.name
			if name:match('.cryptomator$') then
				has_cryptomator_file = true
				break
			end
		end
	end

	if has_cryptomator_file then
		return cx.active.current.cwd
	end

	if cx.active.preview.folder then
		local current_preview_dir_files = cx.active.preview.folder.files

		for i = 1, #current_preview_dir_files do
			local file = current_preview_dir_files[i]
			if file then
				local url = file.url
				local name = url.name
				if name:match('.cryptomator$') then
					has_cryptomator_file = true
					break
				end
			end
		end

		if has_cryptomator_file then
			return cx.active.preview.folder.cwd
		end
	end

	return nil
end)

local get_working_and_preview_paths = ya.sync(function()
	local res = {}
	res.current_dir = cx.active.current.cwd

	if cx.active.preview.folder then
		res.current_preview_dir = cx.active.preview.folder.cwd
	else
		res.current_preview_dir = nil
	end

	return res
end)

local function expand_home(path)
	if path:sub(1, 1) == '~' then
		local home = os.getenv('HOME')
		if not home then
			return path
		end
		if path:sub(2, 2) == '/' or path:sub(2, 2) == '' then
			return home .. path:sub(2)
		end
	end
	return path
end

local get_config = ya.sync(function(state)
	local mount_parent = '~/mnt'
	if state and state.mount_parent then
		mount_parent = state.mount_parent
	end

	return {
		mount_parent = expand_home(mount_parent),
	}
end)

local function random8(segment)
	local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
	local result = ''
	local start_idx = 1
	local end_idx = #chars
	if segment and type(segment) == 'number' and segment > 0 then
		local segment_size = math.floor(#chars / 4)
		start_idx = (segment - 1) * segment_size + 1
		end_idx = segment * segment_size
		if start_idx > #chars then
			start_idx = #chars
		end
		if end_idx > #chars then
			end_idx = #chars
		end
	end
	local segment_chars = chars:sub(start_idx, end_idx)

	math.randomseed(os.time())
	for _ = 1, 8 do
		local rand = math.random(1, #segment_chars)
		result = result .. segment_chars:sub(rand, rand)
	end
	return result
end

local function read_pid(path)
	local handle = io.open(path, 'r')
	if not handle then
		return nil
	end

	local last_number
	for line in handle:lines() do
		local num = tonumber(line)
		if num then
			last_number = num
		end
	end

	handle:close()
	return last_number
end

local function kill(path, mount_point)
	local pid = read_pid(path)
	if pid then
		local _, _ = Command('kill'):arg({
			tostring(pid),
		}):status()

		ya.sleep(1)

		local still_mounted = os.execute(string.format('mount | grep -q ".* on %s type .*"', mount_point))

		if still_mounted then
			ya.notify({
				title = 'cryptomator-cli error',
				content = 'umount vault failed, try to later',
				timeout = 5,
				level = 'error',
			})

			return false
		end

		local _, _ = fs.remove('file', Url(path))
		local _, _ = fs.remove('dir', Url(mount_point))
	else
		ya.notify({
			title = 'cryptomator-cli error',
			content = 'pid file not found',
			timeout = 10,
			level = 'error',
		})
		return false
	end
	return true
end

return {
	setup = function(state, opts)
		if opts and opts.mount_parent then
			state.mount_parent = opts.mount_parent
		end
	end,
	entry = function(_, job)
		local is_umount = job.args.umount

		if is_umount then
			local path = get_working_and_preview_paths()

			local umount_success = false

			local current_dir_mounted =
				os.execute(string.format('mount | grep -q ".* on %s type .*"', tostring(path.current_dir)))

			if current_dir_mounted then
				local tmp_file = string.format('/tmp/%s.pid', path.current_dir.name)
				ya.emit('cd', { '..' })
				ya.sleep(0.5)
				umount_success = kill(tmp_file, path.current_dir)
			else
				local preview_dir_mounted = path.current_preview_dir
					and os.execute(
						string.format('mount | grep -q ".* on %s type .*"', tostring(path.current_preview_dir))
					)

				if preview_dir_mounted then
					local tmp_file = string.format('/tmp/%s.pid', path.current_preview_dir.name)
					umount_success = kill(tmp_file, path.current_preview_dir)
				else
					ya.notify({
						title = 'cryptomator-cli',
						content = 'Neither the current directory nor the preview directory is a mount point.',
						timeout = 10,
						level = 'warn',
					})
					return
				end
			end

			if umount_success then
				ya.notify({
					title = 'cryptomator-cli',
					content = 'umount vault successfully',
					timeout = 10,
					level = 'info',
				})
			end
		else
			local config = get_config()

			local mount_parent = config.mount_parent

			local vault_path = get_vault_path()

			if vault_path == nil then
				ya.notify({
					title = 'cryptomator-cli Error',
					content = 'No vault found in current or preview directory.',
					timeout = 10,
					level = 'error',
				})
				return
			end

			local vault_password, event = ya.input({
				title = 'Cryptomator vault password:',
				position = { 'center', w = 50 },
				obscure = true,
			})

			if event == 0 then
				return
			elseif event == 2 then
				ya.notify({
					title = 'cryptomator-cli',
					content = 'Vault mounting aborted: user cancelled password input.',
					timeout = 3,
					level = 'info',
				})
				return
			end

			vault_password = tostring(vault_password)

			local mount_point = string.format('%s/%s', mount_parent, vault_path.name)

			local mount_point_url = Url(mount_point)

			local mount_point_cha = fs.cha(mount_point_url, false)

			if mount_point_cha then
				mount_point = string.format('%s-%s', mount_point, random8())
				mount_point_url = Url(mount_point)
			end

			local password_file_url = Url('/tmp/' .. random8(1) .. '-' .. random8(2))

			local ok, err = fs.write(password_file_url, vault_password)

			if not ok then
				ya.notify({
					title = 'cryptomator-cli Error',
					content = 'Failed to write password to temp file: ' .. tostring(err),
					timeout = 10,
					level = 'error',
				})
				return
			end

			local ok, _ = fs.create('dir_all', Url(mount_point))

			if not ok then
				ya.notify({
					title = 'cryptomator-cli Error',
					content = 'Failed to create mount point: ' .. tostring(err),
					timeout = 10,
					level = 'error',
				})
			end

			local cmd = string.format(
				'cryptomator-cli unlock --password:file \'%s\' \'%s\' --mountPoint \'%s\' --mounter org.cryptomator.frontend.fuse.mount.LinuxFuseMountProvider >/dev/null 2>&1 & echo $!',
				password_file_url,
				vault_path,
				mount_point
			)

			local handle = io.popen(cmd)

			if not handle then
				ya.notify({
					title = 'cryptomator-cli Error',
					content = 'Check if cryptomator-cli is installed',
					timeout = 10,
					level = 'error',
				})
				return
			end

			local pid = handle:read('*n')
			handle:close()

			ya.sleep(1)

			local success = os.execute(string.format('mount | grep -q ".* on %s type .*"', mount_point))

			if success then
				ya.notify({
					title = 'cryptomator-cli',
					content = string.format('Mounted %s to %s successfully', vault_path.name, mount_point),
					timeout = 10,
					level = 'info',
				})
			else
				ya.notify({
					title = 'cryptomator-cli Error',
					content = 'Password may be wrong. Try mounting manually.',
					timeout = 10,
					level = 'error',
				})
			end

			local ok, _ = fs.remove('file', password_file_url)

			if not ok then
				ya.notify({
					title = 'cryptomator-cli Warning',
					content = 'Failed to delete temp password file\n' .. 'Please manually remove:\n' .. tostring(
						password_file_url
					),
					timeout = 10,
					level = 'error',
				})
			end

			local pid_file_url = Url(string.format('/tmp/%s.pid', mount_point_url.name))

			local ok, _ = fs.write(pid_file_url, pid)

			if not ok then
				ya.notify({
					title = 'cryptomator-cli Warning',
					content = 'Failed to save PID file\n\n'
						.. 'To unmount later, manually run:\n'
						.. 'kill '
						.. tostring(pid),
					timeout = 15,
					level = 'warn',
				})
			end
		end
	end,
}

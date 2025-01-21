local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

local M = {}

local function flatten(tbl)
	return vim.iter(tbl):flatten():totable()
end

M.ext_config = {
	-- extra git args, usually first arg will be git rev
	git_args = {},
	-- passed to previewers.new_termopen_previewer, will be flattened
	preview_get_command = function(opts, entry)
		return {
			"git",
			"diff",
			"-p",
			opts.git_args,
			"--",
			entry.absolute,
		}
	end,
	-- todo add cwd here??, but termopen does not support it currently
}

function M.setup(opts)
	M.ext_config = vim.tbl_deep_extend("force", M.ext_config, opts or {})

	vim.api.nvim_create_user_command("GitDiffStat", function(ev)
		M.git_diff_stat(vim.tbl_deep_extend("force", M.ext_config, { git_args = ev.fargs }))
	end, {
		nargs = "*",
	})
end

local function get_git_root()
	local out = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
	if out.code ~= 0 then
		error(out.stderr)
	end
	return vim.trim(out.stdout)
end

---@return boolean
local function assert_diff_exists(git_args)
	local out = vim.system(flatten({ "git", "diff", "--exit-code", "--quiet", git_args })):wait()
	if out.code == 0 then
		print("No diff")
		return false
	end
	if out.code ~= 1 then
		error(out.stderr)
	end

	return true
end

function M.git_diff_stat(opts)
	opts = vim.tbl_deep_extend("force", M.ext_config, opts or {})

	local git_root = get_git_root()

	if not assert_diff_exists(opts.git_args) then
		return
	end

	pickers
		.new(opts, {
			prompt_title = "git diff " .. table.concat(opts.git_args, " "),
			finder = finders.new_oneshot_job(
				flatten({
					"git",
					"--no-pager",
					"diff",
					"--numstat",
					"--no-color",
					"--no-ext-diff",
					opts.git_args,
				}),
				{
					entry_maker = function(entry)
						local utils = require("telescope.utils")

						local added, removed, relative = entry:match(".-(%d+).-(%d+).-(%S.*)")
						added = added or 0
						removed = removed or 0

						local absolute = vim.fs.joinpath(git_root, relative)

						return {
							display = function()
								local added_str = string.format("%3d ", added)
								local removed_str = string.format("%3d", removed)

								local added_removed_str = string.format("%s%s  ", added_str, removed_str)
								local filepath_str = utils.transform_path(opts, relative)

								local path_style = {
									{ { 0, #added_str }, "Added" },
									{ { #added_str, #added_str + #removed_str }, "Removed" },
								}

								local filepath_icon_str, hl_group, icon =
									utils.transform_devicons(relative, filepath_str)

								if hl_group then
									filepath_str = filepath_icon_str
									table.insert(
										path_style,
										{ { #added_removed_str, #added_removed_str + #icon }, hl_group }
									)
								end

								return added_removed_str .. filepath_str, path_style
							end,
							ordinal = relative,
							value = absolute, -- this has to be absolute, as select action could edit wrong file
							absolute = absolute,
						}
					end,
				}
			),
			sorter = conf.file_sorter(opts),
			previewer = previewers.new_termopen_previewer({
				title = "Diff",
				get_command = function(entry)
					return flatten(opts.preview_get_command(opts, entry))
				end,
			}),
		})
		:find()
end

return M

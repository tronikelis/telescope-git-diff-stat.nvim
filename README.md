# telescope git diff stat picker

Like git status, but better

![Image](https://github.com/user-attachments/assets/19e9deae-4cc9-4681-89cc-93a3d76947fd)

<!--toc:start-->
- [telescope git diff stat picker](#telescope-git-diff-stat-picker)
    - [GitDiffStat user command](#gitdiffstat-user-command)
    - [Config](#config)
    - [Requirements](#requirements)
<!--toc:end-->

Quick setup

```lua
local extensions = require("telescope").extensions

require("telescope").load_extension("git_diff_stat")

vim.keymap.set("n", "<leader>gd", extensions.git_diff_stat.git_diff_stat)
```

### GitDiffStat user command

Loading the extension creates the `GitDiffStat [..args]` command.
`args` will be passed to the underlying `git diff` call


- `:GitDiffStat HEAD~2` check what changed 2 commits before
- `:GitDiffStat --staged` include index


### Config

You can pass these into the picker, or set them via `telescope.setup`

```lua
{
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
}
```

### Requirements

- bash
- git
- awk
- wc

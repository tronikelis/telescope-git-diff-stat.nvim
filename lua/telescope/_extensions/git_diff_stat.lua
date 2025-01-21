return require("telescope").register_extension({
	setup = require("telescope-git-diff-stat").setup,
	exports = {
		git_diff_stat = require("telescope-git-diff-stat").git_diff_stat,
	},
})

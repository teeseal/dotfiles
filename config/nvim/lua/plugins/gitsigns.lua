return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add          = { text = "│" },
            change       = { text = "│" },
            delete       = { text = "_" },
            topdelete    = { text = "‾" },
            changedelete = { text = "~" },
            untracked    = { text = "┆" },
        },
        current_line_blame = false,
    },
    keys = {
        {
            "]c",
            function()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                else
                    vim.schedule(require("gitsigns").next_hunk)
                end
            end,
            desc = "Next git hunk",
        },
        {
            "[c",
            function()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                else
                    vim.schedule(require("gitsigns").prev_hunk)
                end
            end,
            desc = "Prev git hunk",
        },
        {
            "<leader>hs",
            function()
                require("gitsigns").stage_hunk()
            end,
            desc = "Stage hunk",
        },
        {
            "<leader>hr",
            function()
                require("gitsigns").reset_hunk()
            end,
            desc = "Reset hunk",
        },
        {
            "<leader>hp",
            function()
                require("gitsigns").preview_hunk()
            end,
            desc = "Preview hunk",
        },
        {
            "<leader>hb",
            function()
                require("gitsigns").blame_line()
            end,
            desc = "Blame line",
        },
    },
}

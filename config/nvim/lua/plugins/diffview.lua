return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewFileHistory",
        "DiffviewFocusFiles",
        "DiffviewRefresh",
    },
    keys = {
        {
            "<leader>gd",
            "<cmd>DiffviewOpen<cr>",
            desc = "Diff all changes",
        },
    },
    config = function()
        require("diffview").setup({
            keymaps = {
                view = {
                    { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
                },
                file_panel = {
                    { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
                },
                file_history_panel = {
                    { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
                },
            },
        })
        vim.opt.fillchars:append({ diff = "╱" })
    end,
}

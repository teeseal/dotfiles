return {
    "akinsho/bufferline.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "famiu/bufdelete.nvim",
    },
    event = "VeryLazy",
    keys = {
        {
            "<S-l>",
            "<cmd>BufferLineCycleNext<cr>",
            desc = "Next buffer",
        },
        {
            "<S-h>",
            "<cmd>BufferLineCyclePrev<cr>",
            desc = "Prev buffer",
        },
        {
            "<leader>bp",
            "<cmd>BufferLinePick<cr>",
            desc = "Pick buffer",
        },
        {
            "<leader>bc",
            "<cmd>Bdelete<cr>",
            desc = "Close buffer",
        },
    },
    opts = {
        options = {
            mode = "buffers",
            diagnostics = "nvim_lsp",
            close_command = "Bdelete! %d",
            right_mouse_command = "Bdelete! %d",
            offsets = {
                {
                    filetype = "neo-tree",
                    text = "File Explorer",
                    highlight = "Directory",
                    text_align = "left",
                },
            },
        },
    },
}

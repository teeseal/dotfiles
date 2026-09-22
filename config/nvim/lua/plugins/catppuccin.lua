return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "mocha",
            transparent_background = true,
            float = {
                transparent = true,
            },
            integrations = {
                cmp = true,
                treesitter = true,
                bufferline = true,
                neotree = true,
            },
        })
        vim.cmd.colorscheme("catppuccin")
    end,
}

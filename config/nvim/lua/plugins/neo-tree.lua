return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    lazy = false,
    keys = {
        {
            "<leader>e",
            "<cmd>Neotree toggle<cr>",
            desc = "Toggle file explorer",
        },
        {
            "<leader>fe",
            "<cmd>Neotree reveal<cr>",
            desc = "Reveal current file in explorer",
        },
        {
            "<leader>gs",
            "<cmd>Neotree float git_status<cr>",
            desc = "Git status (new/changed files)",
        },
    },
    opts = {
        filesystem = {
            hijack_netrw_behavior = "disabled",
            window = {
                position = "left",
                width = 30,
                mappings = {
                    ["<space>"] = false,
                    ["h"] = "close_node",
                    ["l"] = "open",
                    ["L"] = { "toggle_preview", config = { use_float = true } },
                    ["ga"] = "git_add_file",
                    ["gA"] = "git_add_all",
                    ["gu"] = "git_unstage_file",
                    ["gr"] = "git_revert_file",
                    ["gc"] = "git_commit",
                    ["gp"] = "git_push",
                    ["gg"] = "git_commit_and_push",
                },
            },
            filtered_items = {
                visible = true,
                hide_dotfiles = false,
                hide_gitignored = false,
            },
            follow_current_file = {
                enabled = false,
            },
        },
        default_component_configs = {
            indent = {
                with_expanders = true,
            },
        },
    },
    config = function(_, opts)
        require("neo-tree").setup(opts)

        -- Deferring to after Neovim's own startup redraw makes the initial
        -- paint feel instant, with the tree popping in a moment later
        -- instead of blocking/delaying that first frame.
        vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            callback = function()
                vim.schedule(function()
                    vim.cmd("Neotree show")

                    -- `nvim .` creates a placeholder buffer named after the
                    -- directory; close it now that neo-tree has taken over.
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        local name = vim.api.nvim_buf_get_name(buf)
                        if name ~= "" and vim.fn.isdirectory(name) == 1 then
                            vim.api.nvim_buf_delete(buf, { force = true })
                        end
                    end

                    -- Deleting that buffer leaves its window showing a new
                    -- empty [No Name] buffer. Keep that window around (it's
                    -- the normal editing window telescope/other pickers open
                    -- files into) but mark the buffer unlisted so it never
                    -- shows up in bufferline.
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
                        if ft ~= "neo-tree" and vim.api.nvim_buf_get_name(buf) == "" then
                            vim.api.nvim_set_option_value("buflisted", false, { buf = buf })
                        end
                    end
                end)
            end,
        })
    end,
}

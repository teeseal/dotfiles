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
        git_status = {
            window = {
                mappings = {
                    ["<space>"] = false,
                    ["h"] = "close_node",
                    ["l"] = "open",
                    ["L"] = "focus_preview",
                    ["U"] = "git_unstage_all",
                    ["D"] = "git_diff_file",
                    ["P"] = "git_preview_diff",
                },
            },
        },
        commands = {
            git_unstage_all = function(_)
                vim.fn.system({ "git", "reset" })
                require("neo-tree.events").fire_event(require("neo-tree.events").GIT_EVENT)
            end,
            -- Side-by-side, syntax-highlighted diff preview for the file
            -- under cursor (HEAD vs working tree), rendered with Neovim's
            -- native diff mode across two floating windows -- visually
            -- similar to Diffview, but without leaving the git status
            -- window or opening a full Diffview session.
            git_preview_diff = function(state)
                local node = state.tree:get_node()
                if node.type == "message" then
                    return
                end

                local path = node:get_id()
                local dir = vim.fn.fnamemodify(path, ":h")
                local root = vim.trim(vim.fn.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }))
                if vim.v.shell_error ~= 0 or root == "" then
                    vim.notify("Not inside a git repo: " .. path, vim.log.levels.WARN)
                    return
                end
                local relpath = path:sub(#root + 2)

                local old_lines = vim.fn.systemlist({ "git", "-C", root, "show", "HEAD:" .. relpath })
                local old_exists = vim.v.shell_error == 0
                if not old_exists then
                    old_lines = {}
                end

                local new_lines = {}
                if vim.fn.filereadable(path) == 1 then
                    new_lines = vim.fn.readfile(path)
                end

                if old_exists and vim.deep_equal(old_lines, new_lines) then
                    vim.notify("No diff for " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
                    return
                end

                local ft = vim.filetype.match({ filename = path }) or ""

                local width = math.floor(vim.o.columns * 0.9)
                local height = math.floor(vim.o.lines * 0.8)
                local row_start = math.floor((vim.o.lines - height) / 2)
                local col_start = math.floor((vim.o.columns - width) / 2)
                local half_width = math.floor((width - 1) / 2)

                local function make_float(lines, title, col)
                    local buf = vim.api.nvim_create_buf(false, true)
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                    vim.bo[buf].filetype = ft
                    vim.bo[buf].bufhidden = "wipe"
                    vim.bo[buf].modifiable = false
                    local win = vim.api.nvim_open_win(buf, false, {
                        relative = "editor",
                        width = half_width,
                        height = height,
                        row = row_start,
                        col = col,
                        border = "rounded",
                        title = title,
                        title_pos = "center",
                    })
                    return buf, win
                end

                local old_buf, old_win = make_float(old_lines, " HEAD ", col_start)
                local new_buf, new_win = make_float(
                    new_lines,
                    " Working Tree: " .. vim.fn.fnamemodify(path, ":t") .. " ",
                    col_start + half_width + 1
                )

                for _, win in ipairs({ old_win, new_win }) do
                    vim.wo[win].diff = true
                    vim.wo[win].wrap = false
                    vim.wo[win].scrollbind = true
                    vim.wo[win].cursorbind = true
                end

                vim.api.nvim_set_current_win(new_win)

                local closed = false
                local function close_all()
                    if closed then
                        return
                    end
                    closed = true
                    for _, win in ipairs({ old_win, new_win }) do
                        if vim.api.nvim_win_is_valid(win) then
                            vim.api.nvim_win_close(win, true)
                        end
                    end
                end

                for _, buf in ipairs({ old_buf, new_buf }) do
                    vim.keymap.set("n", "q", close_all, { buffer = buf, nowait = true, silent = true })
                    vim.keymap.set("n", "<esc>", close_all, { buffer = buf, nowait = true, silent = true })

                    -- Auto-close as soon as focus leaves either float, so
                    -- running another command (e.g. <leader>ff) doesn't
                    -- leave them stuck on screen.
                    vim.api.nvim_create_autocmd("WinLeave", {
                        buffer = buf,
                        once = true,
                        callback = close_all,
                    })
                end
            end,
            git_diff_file = function(state)
                local node = state.tree:get_node()
                if node.type == "message" then
                    return
                end
                local path = node:get_id()
                -- Without --untracked-files=false, Diffview's file panel
                -- always lists every untracked file repo-wide alongside the
                -- pathspec-filtered target -- upstream's untracked-file
                -- lookup ignores path_args entirely (git ls-files --others
                -- with no pathspec). Since this command is for viewing one
                -- file's diff, hide untracked files so only that file shows.
                vim.cmd("DiffviewOpen --untracked-files=false -- " .. vim.fn.fnameescape(path))
            end,
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

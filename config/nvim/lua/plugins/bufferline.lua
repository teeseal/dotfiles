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
    config = function(_, opts)
        -- Per-file git status cache, keyed by absolute path. Populated async
        -- (see refresh_git_status below) and read synchronously from
        -- get_element_icon, since that callback fires on every render.
        local git_status_cache = {}

        -- Mirrors neo-tree's git_status symbols/highlights (see
        -- lua/neo-tree/defaults.lua and lua/neo-tree/ui/highlights.lua) so
        -- tabs use the exact same icons and colors as the file explorer.
        local icon_map = {
            added     = { icon = "✚", hl = "NeoTreeGitAdded" },
            deleted   = { icon = "✖", hl = "NeoTreeGitDeleted" },
            modified  = { icon = "", hl = "NeoTreeGitModified" },
            renamed   = { icon = "󰁕", hl = "NeoTreeGitRenamed" },
            untracked = { icon = "", hl = "NeoTreeGitUntracked" },
            ignored   = { icon = "", hl = "NeoTreeGitIgnored" },
            conflict  = { icon = "", hl = "NeoTreeGitConflict" },
        }

        -- Classifies a 2-character `git status --porcelain` code the same
        -- way neo-tree does: conflicts first, then whichever of the
        -- worktree/staged columns has a change.
        local function classify(code)
            if code == "??" then
                return "untracked"
            elseif code == "!!" then
                return "ignored"
            end

            local staged, worktree = code:sub(1, 1), code:sub(2, 2)
            if staged == "U" or worktree == "U"
                or (staged == "A" and worktree == "A")
                or (staged == "D" and worktree == "D") then
                return "conflict"
            end

            local change = worktree ~= " " and worktree or staged
            local kinds = { A = "added", D = "deleted", R = "renamed", M = "modified" }
            return kinds[change]
        end

        local function refresh_git_status(bufnr)
            if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
                return
            end

            local path = vim.api.nvim_buf_get_name(bufnr)
            if path == "" then
                return
            end

            -- Skip virtual buffers from plugins like diffview.nvim
            -- ("diffview:///...") or fugitive ("fugitive://...") -- these
            -- aren't real files on disk, so fnamemodify/git status on them
            -- either errors out (ENOENT on the fake cwd) or is meaningless.
            if path:match("^%a[%w+.-]*://") then
                return
            end

            if vim.fn.filereadable(path) ~= 1 then
                return
            end

            vim.system(
                { "git", "status", "--porcelain", "--ignored", "--", path },
                { cwd = vim.fn.fnamemodify(path, ":h") },
                vim.schedule_wrap(function(res)
                    local out = res.code == 0 and vim.trim(res.stdout or "") or ""
                    local kind = out ~= "" and classify(out:sub(1, 2)) or nil
                    git_status_cache[path] = kind and icon_map[kind] or nil

                    local ok, bufferline_ui = pcall(require, "bufferline.ui")
                    if ok then
                        bufferline_ui.refresh()
                    end
                end)
            )
        end

        opts.options.get_element_icon = function(element)
            local status = git_status_cache[element.path]
            if status then
                return status.icon, status.hl
            end

            local ok, devicons = pcall(require, "nvim-web-devicons")
            if ok then
                return devicons.get_icon(vim.fn.fnamemodify(element.path, ":t"), element.extension, { default = true })
            end
        end

        require("bufferline").setup(opts)

        -- bufferline loads on VeryLazy, which fires after startup's initial
        -- BufEnter for any file opened via the command line. Sweep already
        -- loaded/listed buffers once so that first buffer isn't stuck on the
        -- plain filetype icon until it's re-entered or written.
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
                refresh_git_status(bufnr)
            end
        end

        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
            callback = function(event)
                refresh_git_status(event.buf)
            end,
        })

        -- gitsigns fires this whenever it re-diffs a buffer, which is a
        -- reliable trigger for staged/unstaged changes made outside of
        -- normal buffer writes (e.g. staging a hunk, running git commands).
        vim.api.nvim_create_autocmd("User", {
            pattern = "GitSignsUpdate",
            callback = function(event)
                local bufnr = event.data and event.data.buffer
                if bufnr then
                    refresh_git_status(bufnr)
                end
            end,
        })
    end,
}

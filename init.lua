-- disable netrw at the very start of your init.lua for nvim-tree (nvim-tree is intended as a full replacement)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

vim.g.mapleader = "\\" -- Make sure to set `mapleader` brfore lazy so your mappings are correct
vim.g.maplocalleader = "\\" -- Same for `maplocalleader`

-- smart case, ignore case, tab settings, highlight search on, incremental search on, autoindent on
vim.opt.ignorecase=true
vim.opt.smartcase=true
vim.opt.tabstop=2
vim.opt.shiftwidth=2
vim.opt.expandtab=true
vim.opt.hlsearch=true
vim.opt.incsearch=true
vim.opt.autoindent=true
vim.opt.number=true
vim.opt.updatetime=100 -- so vim-gitgutter will update faster

-- Lazy.nvim configuration
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- lsp-zero config
local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({
    buffer = bufnr,
    preserve_mappings = false
  })
end)

-- luasnip setup
require("luasnip.loaders.from_vscode").lazy_load()

-- nvim-cmp autocomplete
local cmp = require('cmp')
local luasnip = require("luasnip")
cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i','c'}),
    ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'i','c'}),
    ['<CR>'] = cmp.mapping.confirm({select = true}), -- Allow Enter to select completion, automatically select the first entry
    ["<Tab>"] = cmp.mapping(function(fallback) -- Allow Tab to go to the next autocompleted function signature attribute
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback) -- Allow Shift-Tab to go to the previous autocompleted function signature attribute
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' }, -- For luasnip users.
    { name = 'treesitter' },
  })
})

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
require('lspconfig')['gopls'].setup {
  cmd = {'gopls'},
  -- on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    gopls = {
      experimentalPostfixCompletions = true,
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
    },
  },
  init_options = {
    usePlaceholders = true,
  }
}

-- Mason with default config
require("mason").setup()

-- Colors for menus so they aren't hot pink
vim.cmd [[ hi Pmenu guibg=#191e29 ]]
vim.cmd [[ hi PmenuSel guibg=#2f394f ]]

-- Extra syntax highlighting
require('nvim-treesitter.configs').setup({
  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
})

-- Associate certain non-.rb files that are still ruby files to the ruby filetype
vim.api.nvim_command('au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,Thorfile,config.ru,*.thor} set ft=ruby')

-- configure format on save specifically including goimports
local format_on_save = require("format-on-save")
local formatters = require("format-on-save.formatters")

format_on_save.setup({
  exclude_path_patterns = {
    "/node_modules/",
    ".local/share/nvim/lazy",
  },
  formatter_by_ft = {
    css = formatters.lsp,
    html = formatters.lsp,
    java = formatters.lsp,
    javascript = formatters.lsp,
    json = formatters.lsp,
    lua = formatters.lsp,
    markdown = formatters.prettierd,
    openscad = formatters.lsp,
    python = formatters.black,
    rust = formatters.lsp,
    scad = formatters.lsp,
    scss = formatters.lsp,
    sh = formatters.shfmt,
    terraform = formatters.lsp,
    typescript = formatters.prettierd,
    typescriptreact = formatters.prettierd,
    yaml = formatters.lsp,

    go = {
      formatters.shell({ cmd = { "goimports" } }), -- goimports fixes imports _and_ formats like gofmt
    },
  }
})

-- colorscheme
vim.cmd[[colorscheme tokyonight-night]]

require('lint').linters_by_ft = {
  go = {'golangcilint',}
}

vim.api.nvim_create_autocmd({ "BufModifiedSet", "BufEnter" }, {
  callback = function()

    -- try_lint without arguments runs the linters defined in `linters_by_ft`
    -- for the current filetype
    require("lint").try_lint()
  end,
})


-- I don't know how to do this in whichkey register
vim.keymap.set("n", "<leader>t", [[:Telescope find_files<CR>]])

require('telescope').setup{
  pickers = {
    find_files = {
      hidden = true
    }
  },
  defaults = {
    file_ignore_patterns = {".git/"},
    mappings = {
      n = {
    	  ['<C-d>'] = require('telescope.actions').delete_buffer
      },
      i = {
        ['<C-d>'] = require('telescope.actions').delete_buffer
      }
    }
  },
}

local config = { -- Specify configuration
  go_test_args = {
    "-v",
  },
}
-- Set up neotest with the rspec plugin
require("neotest").setup({
  adapters = {
    require("neotest-rspec"),
    require("neotest-golang")(config),
    -- require("neotest-golang"),
  },
})

-- Set up and document custom keymaps
local wk = require("which-key")
wk.add({
  { "<leader>a", group = "live grep" },
  { "<leader>aw", "<cmd>Telescope live_grep <cr>", desc = "Live Grep" },
  { "<leader>aa", "<cmd>BlameToggle <cr>", desc = "Toggle Git Blame" },
  { "<leader>b", group = "buffer" },
  { "<leader>be", "<cmd>Telescope buffers<cr>", desc = "Buffer Explorer" },
  { "<leader>f", group = "find" },
  { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
  { "<leader>n", group = "nvim-tree-shortcuts, highlight" },
  { "<leader>nf", "<cmd>NvimTreeFindFile<cr>", desc = "NvimTreeFindFile" },
  { "<leader>nh", "<cmd>nohlsearch<cr>", desc = "nohlsearch" },
  { "<leader>nt", "<cmd>NvimTreeToggle<cr>", desc = "NvimTree" },
  { "<leader>s", group = "test running" },
  { "<leader>st",
    function()
      neotest = require('neotest')
      neotest.run.run()
      neotest.summary.open()
    end,
    desc = "Run the closest test to the cursor" },
  { "<leader>ss",
    function()
      neotest = require('neotest')
      neotest.run.run(vim.fn.expand('%'))
      neotest.summary.open()
    end,
    desc = "Run the tests for the whole file" },
  { "<leader>sv",
    function()
      neotest = require('neotest')
      neotest.summary.toggle()
    end,
  desc = "Run the tests for the whole file" },
  { "<leader>ws", "<cmd>StripWhitespace<cr>", desc = "Strip trailing whitespace" },
})

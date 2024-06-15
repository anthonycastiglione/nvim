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

-- I don't know how to do this in whichkey register
vim.keymap.set("n", "<leader>t", [[:Telescope find_files<CR>]])

require('telescope').setup{
  defaults = {
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

-- Set up and document custom keymaps
local wk = require("which-key")
wk.register({
  a = {
    name = "live grep", -- optional group name
    w = { "<cmd>Telescope live_grep <cr>", "Live Grep" }, -- create a binding with label
    },
  b = {
    name = "buffer",
    e = { "<cmd>Telescope buffers<cr>", "Buffer Explorer" }, 
  },
  f = {
    name = "find",
    h = { "<cmd>Telescope help_tags<cr>", "Help Tags" },
  },
  n = {
    name = "nvim-tree-shortcuts, highlight",
    t = { "<cmd>NvimTreeToggle<cr>", "NvimTree" },
    f = { "<cmd>NvimTreeFindFile<cr>", "NvimTreeFindFile" },
    h = { "<cmd>nohlsearch<cr>", "nohlsearch" }
  },
}, { prefix = "<leader>" })

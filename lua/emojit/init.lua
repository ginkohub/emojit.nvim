local data = require("emojit.data")
local M = {}

local function create_window_layout()
  local ui = vim.api.nvim_list_uis()[1]
  local width = 42 -- Wide enough for ~10 emojis per row
  local height = 15
  local row = (ui.height - height) / 2
  local col = (ui.width - width) / 2

  -- Results buffer and window
  local res_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(res_buf, "filetype", "emojit")
  local res_opts = {
    relative = "editor",
    width = width,
    height = height - 5,
    col = col,
    row = row + 3,
    style = "minimal",
    border = "rounded",
    title = " Results ",
    title_pos = "center",
  }
  local res_win = vim.api.nvim_open_win(res_buf, false, res_opts)
  vim.api.nvim_win_set_option(res_win, "cursorline", true)

  -- Input buffer and window
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(input_buf, "filetype", "emojit")
  local input_opts = {
    relative = "editor",
    width = width,
    height = 1,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Search Emoji ",
    title_pos = "center",
  }
  local input_win = vim.api.nvim_open_win(input_buf, true, input_opts)

  -- Footer buffer and window (Action hints)
  local footer_buf = vim.api.nvim_create_buf(false, true)
  local footer_opts = {
    relative = "editor",
    width = width,
    height = 1,
    col = col,
    row = row + height - 1,
    style = "minimal",
    border = "rounded",
  }
  local footer_win = vim.api.nvim_open_win(footer_buf, false, footer_opts)
  vim.api.nvim_buf_set_lines(footer_buf, 0, -1, false, { " <Enter> Select | <Esc> Close " })
  vim.api.nvim_win_set_option(footer_win, "winhl", "Normal:Comment")

  return {
    input_buf = input_buf,
    input_win = input_win,
    res_buf = res_buf,
    res_win = res_win,
    footer_buf = footer_buf,
    footer_win = footer_win,
  }
end

local function filter_emojis(query)
  if query == "" then
    return data.emojis
  end

  local results = {}
  query = query:lower()
  for _, emoji in ipairs(data.emojis) do
    if emoji.name:lower():find(query, 1, true) then
      table.insert(results, emoji)
    end
  end
  return results
end

function M.open()
  local layout = create_window_layout()
  local current_results = data.emojis

  local columns = 8
  local function update_display()
    local lines = {}
    if #current_results == 0 then
      lines = { "  No results found" }
    else
      local current_line = ""
      for i, emoji in ipairs(current_results) do
        current_line = current_line .. string.format(" %s ", emoji.char)
        if i % columns == 0 then
          table.insert(lines, current_line)
          current_line = ""
        end
      end
      if current_line ~= "" then
        table.insert(lines, current_line)
      end
    end

    vim.api.nvim_buf_set_option(layout.res_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(layout.res_buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(layout.res_buf, "modifiable", false)

    if #current_results > 0 then
      -- Position cursor on the first emoji character (index 1 after the leading space at 0)
      vim.api.nvim_win_set_cursor(layout.res_win, { 1, 1 })
    end
  end

  update_display()

  -- Input handling
  vim.api.nvim_buf_attach(layout.input_buf, false, {
    on_lines = function()
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(layout.input_buf) then
          return
        end
        local query = vim.api.nvim_buf_get_lines(layout.input_buf, 0, 1, false)[1] or ""
        current_results = filter_emojis(query)
        update_display()
      end)
    end,
  })

  local function close_all()
    if vim.api.nvim_win_is_valid(layout.input_win) then
      vim.api.nvim_win_close(layout.input_win, true)
    end
    if vim.api.nvim_win_is_valid(layout.res_win) then
      vim.api.nvim_win_close(layout.res_win, true)
    end
    if vim.api.nvim_win_is_valid(layout.footer_win) then
      vim.api.nvim_win_close(layout.footer_win, true)
    end
  end

  local function select_emoji()
    if #current_results == 0 then
      close_all()
      return
    end

    local cursor = vim.api.nvim_win_get_cursor(layout.res_win)
    local row = cursor[1]
    local col = math.floor(cursor[2] / 4) + 1
    local idx = (row - 1) * columns + col
    local emoji = current_results[idx]

    close_all()

    if emoji then
      local r, c = unpack(vim.api.nvim_win_get_cursor(0))
      vim.api.nvim_buf_set_text(0, r - 1, c, r - 1, c, { emoji.char })
      vim.api.nvim_win_set_cursor(0, { r, c + #emoji.char })
    end
  end

  -- Keymaps for input window
  local input_map_opts = { noremap = true, silent = true, buffer = layout.input_buf }
  vim.keymap.set("i", "<Esc>", close_all, input_map_opts)
  vim.keymap.set("i", "<CR>", select_emoji, input_map_opts)

  local function move_cursor(dr, dc)
    local cur = vim.api.nvim_win_get_cursor(layout.res_win)
    local r, c = cur[1], cur[2]
    local new_r = r + dr
    local new_c = c + (dc * 4)

    local lines = vim.api.nvim_buf_get_lines(layout.res_buf, 0, -1, false)
    local line_count = #lines
    
    if new_r >= 1 and new_r <= line_count then
      local line = lines[new_r]
      -- Ensure we don't move past the end of the line
      -- Each emoji cell " 😀 " is 4 bytes. 
      if new_c >= 1 and new_c < #line then
        vim.api.nvim_win_set_cursor(layout.res_win, { new_r, new_c })
      end
    end
  end

  vim.keymap.set("i", "<C-n>", function() move_cursor(1, 0) end, input_map_opts)
  vim.keymap.set("i", "<C-p>", function() move_cursor(-1, 0) end, input_map_opts)
  vim.keymap.set("i", "<C-f>", function() move_cursor(0, 1) end, input_map_opts)
  vim.keymap.set("i", "<C-b>", function() move_cursor(0, -1) end, input_map_opts)

  -- Normal mode keymaps for both windows
  local function set_common_maps(buf)
    local m_opts = { noremap = true, silent = true, buffer = buf }
    vim.keymap.set("n", "q", close_all, m_opts)
    vim.keymap.set("n", "<Esc>", close_all, m_opts)
    vim.keymap.set("n", "<CR>", select_emoji, m_opts)
  end

  set_common_maps(layout.input_buf)
  set_common_maps(layout.res_buf)

  -- Start in insert mode
  vim.cmd("startinsert")
end

function M.setup(opts)
  -- Configuration can be handled here in the future
end

return M

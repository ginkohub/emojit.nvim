local data = require("emojit.data")
local M = {}

local config = {
  columns = 10,
  width = 42,
  height = 15,
}

local state = {
  is_open = false,
  layout = nil,
  origin_win = nil,
}

local function create_window_layout()
  local uis = vim.api.nvim_list_uis()
  if #uis == 0 then return nil end
  local ui = uis[1]
  local width = config.width
  local height = config.height
  local row = (ui.height - height) / 2
  local col = (ui.width - width) / 2

  -- Results buffer and window (Main Grid)
  local res_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", "emojit", { buf = res_buf })
  local res_opts = {
    relative = "editor",
    width = width,
    height = height - 2,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Emojit ",
    title_pos = "center",
  }
  local res_win = vim.api.nvim_open_win(res_buf, true, res_opts)
  vim.api.nvim_set_option_value("cursorline", true, { win = res_win })

  -- Footer window (Tooltips only)
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
  vim.api.nvim_set_option_value("winhl", "Normal:Comment", { win = footer_win })

  return {
    res_buf = res_buf,
    res_win = res_win,
    footer_buf = footer_buf,
    footer_win = footer_win,
  }
end

local function get_current_idx(res_win, columns)
  local cursor = vim.api.nvim_win_get_cursor(res_win)
  local row = cursor[1]
  local byte_col = cursor[2]
  
  local line_idx = (row - 1) * columns
  local current_byte = 0
  local col_idx = 0
  
  for i = 1, columns do
    local emoji_idx = line_idx + i
    local emoji = data.emojis[emoji_idx]
    if not emoji then break end
    
    local cell_start = current_byte
    local cell_end = current_byte + 1 + #emoji.char + 1
    
    if byte_col >= cell_start and byte_col < cell_end then
      col_idx = i
      break
    end
    current_byte = cell_end
  end
  
  if col_idx == 0 then return nil end
  return line_idx + col_idx
end

function M.open()
  if state.is_open then return end

  state.origin_win = vim.api.nvim_get_current_win()
  state.layout = create_window_layout()
  if not state.layout then
    vim.notify("emojit: cannot open in headless mode", vim.log.levels.WARN)
    return
  end

  state.is_open = true
  local columns = config.columns

  local function update_footer(text)
    text = text or " Select emojis (Esc/q to close)"
    vim.api.nvim_buf_set_lines(state.layout.footer_buf, 0, -1, false, { " " .. text })
  end

  local function update_display()
    local lines = {}
    local current_line = ""
    for i, emoji in ipairs(data.emojis) do
      current_line = current_line .. string.format(" %s ", emoji.char)
      if i % columns == 0 then
        table.insert(lines, current_line)
        current_line = ""
      end
    end
    if current_line ~= "" then table.insert(lines, current_line) end

    vim.api.nvim_set_option_value("modifiable", true, { buf = state.layout.res_buf })
    vim.api.nvim_buf_set_lines(state.layout.res_buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = state.layout.res_buf })
    vim.api.nvim_win_set_cursor(state.layout.res_win, { 1, 1 })
  end

  update_display()
  update_footer()

  local function close_all()
    state.is_open = false
    if vim.api.nvim_win_is_valid(state.layout.res_win) then
      vim.api.nvim_win_close(state.layout.res_win, true)
    end
    if vim.api.nvim_win_is_valid(state.layout.footer_win) then
      vim.api.nvim_win_close(state.layout.footer_win, true)
    end
  end

  local function insert_emoji()
    local idx = get_current_idx(state.layout.res_win, columns)
    local emoji = idx and data.emojis[idx]

    if emoji and vim.api.nvim_win_is_valid(state.origin_win) then
      local r, c = unpack(vim.api.nvim_win_get_cursor(state.origin_win))
      local buf = vim.api.nvim_win_get_buf(state.origin_win)
      vim.api.nvim_buf_set_text(buf, r - 1, c, r - 1, c, { emoji.char })
      -- Move cursor after inserted emoji in origin window
      vim.api.nvim_win_set_cursor(state.origin_win, { r, c + #emoji.char })
    end
  end

  -- Tooltip on move
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = state.layout.res_buf,
    callback = function()
      local idx = get_current_idx(state.layout.res_win, columns)
      local emoji = idx and data.emojis[idx]
      if emoji then
        update_footer(emoji.name)
      else
        update_footer()
      end
    end,
  })

  -- Keymaps
  local opts = { noremap = true, silent = true, buffer = state.layout.res_buf }
  vim.keymap.set("n", "<CR>", insert_emoji, opts)
  vim.keymap.set("n", "q", close_all, opts)
  vim.keymap.set("n", "<Esc>", close_all, opts)
  
  -- Mouse support
  vim.keymap.set("n", "<LeftRelease>", function()
    -- Small delay to let the cursor settle on the click position
    vim.schedule(insert_emoji)
  end, opts)

  -- Grid Navigation (Normal mode)
  local function move_cursor(dr, dc)
    local cur = vim.api.nvim_win_get_cursor(state.layout.res_win)
    local row = cur[1]
    local current_idx = get_current_idx(state.layout.res_win, columns)
    if not current_idx then return end
    
    local current_col = ((current_idx - 1) % columns) + 1
    local new_row = row + dr
    local new_col = current_col + dc
    
    if new_row < 1 then new_row = 1 end
    local total_rows = math.ceil(#data.emojis / columns)
    if new_row > total_rows then new_row = total_rows end
    if new_col < 1 then new_col = 1 end
    if new_col > columns then new_col = columns end
    
    local new_idx = (new_row - 1) * columns + new_col
    if new_idx > #data.emojis then
      new_idx = #data.emojis
      new_row = math.ceil(new_idx / columns)
      new_col = ((new_idx - 1) % columns) + 1
    end
    
    local new_byte_offset = 0
    local row_start_idx = (new_row - 1) * columns
    for i = 1, new_col - 1 do
      local e = data.emojis[row_start_idx + i]
      new_byte_offset = new_byte_offset + 1 + #e.char + 1
    end
    new_byte_offset = new_byte_offset + 1
    vim.api.nvim_win_set_cursor(state.layout.res_win, { new_row, new_byte_offset })
  end

  vim.keymap.set("n", "j", function() move_cursor(1, 0) end, opts)
  vim.keymap.set("n", "k", function() move_cursor(-1, 0) end, opts)
  vim.keymap.set("n", "l", function() move_cursor(0, 1) end, opts)
  vim.keymap.set("n", "h", function() move_cursor(0, -1) end, opts)
end

function M.setup(opts)
  opts = opts or {}
  config.columns = opts.columns or config.columns
  config.width = opts.width or config.width
  config.height = opts.height or config.height
end

return M

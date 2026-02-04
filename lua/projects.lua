local M = {}

local MiniPick = require("mini.pick")

local DATA_FILE = vim.fn.stdpath("data") .. "/projects.lua"

-- Utils

local function normalize(path)
  return vim.fn.fnamemodify(path, ":p"):gsub("\\", "/")
end

local function basename(path)
  return vim.fn.fnamemodify(path, ":t")
end

-- Load / Save

local function load_projects()
  local ok, data = pcall(dofile, DATA_FILE)

  if ok and type(data) == "table" then
    return data
  end

  return {}
end

local function save_projects(list)
  local f = assert(io.open(DATA_FILE, "w"))

  f:write("return {\n")

  for _, p in ipairs(list) do
    f:write(string.format(
      "  { name = %q, path = %q },\n",
      p.name,
      p.path
    ))
  end

  f:write("}\n")
  f:close()
end

-- Clean dead entries

local function clean_projects(list)
  local alive = {}

  for _, p in ipairs(list) do
    if type(p) == "table"
      and type(p.name) == "string"
      and type(p.path) == "string"
      and vim.loop.fs_stat(p.path)
    then
      table.insert(alive, p)
    end
  end

  return alive
end

-- Public API

--  Add current working directory
function M.add()
  local cwd = normalize(vim.fn.getcwd())
  local name = basename(cwd)

  local list = clean_projects(load_projects())

  for _, p in ipairs(list) do
    if p.path == cwd then
      vim.notify("Project already added", vim.log.levels.INFO)
      return
    end
  end

  table.insert(list, {
    name = name,
    path = cwd,
  })

  save_projects(list)

  vim.notify("Added project: " .. name)
end

--  Remove current working directory
function M.remove()
  local cwd = normalize(vim.fn.getcwd())

  local list = load_projects()
  local new = {}

  local removed = false

  for _, p in ipairs(list) do
    if p.path ~= cwd then
      table.insert(new, p)
    else
      removed = true
    end
  end

  save_projects(new)

  if removed then
    vim.notify("Removed project")
  else
    vim.notify("Project not found", vim.log.levels.WARN)
  end
end

--  Pick project
function M.pick()
  local list = clean_projects(load_projects())
  save_projects(list)

  if #list == 0 then
    vim.notify("No projects saved", vim.log.levels.WARN)
    return
  end

  local items = {}

  for _, p in ipairs(list) do
    table.insert(items, {
      text = string.format("%-20s %s", p.name, p.path),
      name = p.name,
      path = p.path,
    })
  end

  MiniPick.start({
    source = {
      name = "Projects",
      items = items,

      choose = function(item)
				vim.api.nvim_set_current_dir(item.path)
        vim.cmd("bd")
        vim.cmd("Oil")
      end,
    },
  })
end

return M


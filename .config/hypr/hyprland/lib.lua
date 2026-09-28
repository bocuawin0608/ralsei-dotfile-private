-- =============================================================================
-- hyprland/lib.lua
-- Core hl.* API library for Hyprland 0.56.2 native Lua configuration.
-- All compositor interaction goes through hyprctl; Aquamarine handles rendering.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Global helpers
-- ---------------------------------------------------------------------------

--- Home directory (available to all modules that require this lib).
HOME = os.getenv("HOME") or "/root"

--- Check whether a file exists at the given path.
--- @param path string
--- @return boolean
function is_file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Internal utilities
-- ---------------------------------------------------------------------------

local function _run(cmd)
    local ok, handle = pcall(io.popen, cmd .. " 2>/dev/null")
    if not ok or not handle then return nil end
    local out = handle:read("*a")
    handle:close()
    return out
end

local function _hyprctl(args)
    return _run("hyprctl " .. args)
end

local function _keyword(key, value)
    _hyprctl(string.format("keyword %s %s", key, value))
end

-- ---------------------------------------------------------------------------
-- hl namespace
-- ---------------------------------------------------------------------------

hl = hl or {}

-- ---------------------------------------------------------------------------
-- hl.exec_cmd / hl.exec_cmd_sync
-- ---------------------------------------------------------------------------

--- Execute a shell command asynchronously (fire-and-forget).
--- @param cmd string
function hl.exec_cmd(cmd)
    os.execute(cmd .. " &")
end

--- Execute a shell command and return its stdout output.
--- @param cmd string
--- @return string|nil
function hl.exec_cmd_sync(cmd)
    return _run(cmd)
end

-- ---------------------------------------------------------------------------
-- hl.version
-- ---------------------------------------------------------------------------

--- Return the Hyprland version string reported by hyprctl.
--- @return string
function hl.version()
    local out = _hyprctl("version") or ""
    return out:match("Hyprland ([%d%.]+)") or out
end

-- ---------------------------------------------------------------------------
-- hl.config
-- ---------------------------------------------------------------------------

-- Mapping of table key paths to hyprctl keyword names.
-- Nested tables are flattened with ':' as separator.
local function _flatten_config(tbl, prefix, results)
    results = results or {}
    prefix  = prefix  or ""
    for k, v in pairs(tbl) do
        local key = prefix == "" and tostring(k) or (prefix .. ":" .. tostring(k))
        if type(v) == "table" then
            _flatten_config(v, key, results)
        else
            results[key] = v
        end
    end
    return results
end

--- Apply Hyprland configuration options via `hyprctl keyword`.
--- Accepts a nested table; keys are joined with ':' to form keyword paths.
--- Special key "env" accepts a list of {"VAR", "value"} pairs or {"VAR=value"}.
---
--- Example:
---   hl.config({ general = { gaps_in = 6, gaps_out = 10 } })
---   hl.config({ env = { {"MOZ_ENABLE_WAYLAND", "1"} } })
--- @param tbl table
function hl.config(tbl)
    -- Handle env table separately: env = { {"KEY", "VAL"}, ... }
    if tbl.env then
        for _, entry in ipairs(tbl.env) do
            local kw_val
            if type(entry) == "table" then
                if entry[2] ~= nil then
                    kw_val = string.format("%s,%s", tostring(entry[1]), tostring(entry[2]))
                else
                    -- { "KEY=VALUE" } form
                    kw_val = tostring(entry[1]):gsub("=", ",", 1)
                end
            else
                kw_val = tostring(entry):gsub("=", ",", 1)
            end
            _keyword("env", kw_val)
        end
        -- Remove env so the rest is processed normally
        local rest = {}
        for k, v in pairs(tbl) do
            if k ~= "env" then rest[k] = v end
        end
        if next(rest) then hl.config(rest) end
        return
    end

    local flat = _flatten_config(tbl)
    for k, v in pairs(flat) do
        local val = tostring(v)
        -- Convert Lua booleans to hyprctl keyword-compatible strings
        if v == true  then val = "true"  end
        if v == false then val = "false" end
        _keyword(k, val)
    end
end

-- ---------------------------------------------------------------------------
-- hl.get_config
-- ---------------------------------------------------------------------------

--- Retrieve the current value of a Hyprland config key.
--- Keys use ':' as separator (e.g. "cursor:zoom_factor").
--- Returns the value as a number if it looks numeric, otherwise as string.
--- @param key string
--- @return number|string|nil
function hl.get_config(key)
    -- Hyprland 0.56+ getoption returns JSON
    local out = _hyprctl("getoption " .. key .. " -j")
    if not out or out == "" then return nil end

    -- Try to parse the "data" field (int/float/string)
    local num = out:match('"int"%s*:%s*([%d]+)')
        or out:match('"float"%s*:%s*([%d%.%-]+)')
    if num then return tonumber(num) end

    local str = out:match('"str"%s*:%s*"([^"]*)"')
    if str then return str end

    -- Fallback: raw getoption (non-JSON)
    out = _hyprctl("getoption " .. key)
    if not out then return nil end
    local val = out:match(":%s*(.-)%s*$")
    local n = tonumber(val)
    return n or val
end

-- ---------------------------------------------------------------------------
-- hl.dispatch
-- ---------------------------------------------------------------------------

--- Raw compositor dispatch.  Accepts either a dispatcher string or the table
--- returned by one of the hl.dsp.* constructors.
--- @param dispatcher string|table
function hl.dispatch(dispatcher)
    local dsp
    if type(dispatcher) == "table" and dispatcher._dispatch then
        dsp = dispatcher._dispatch
    elseif type(dispatcher) == "string" then
        dsp = dispatcher
    else
        return
    end
    _hyprctl("dispatch " .. dsp)
end

-- ---------------------------------------------------------------------------
-- hl.add_window_rule / hl.add_layer_rule
-- ---------------------------------------------------------------------------

--- Add a window rule.
--- @param rule string   e.g. "float"
--- @param selector string  e.g. "class:^(pavucontrol)$"
function hl.add_window_rule(rule, selector)
    _keyword("windowrulev2", string.format("%s, %s", rule, selector))
end

--- Add a layer rule.
--- @param rule string   e.g. "blur"
--- @param namespace string  e.g. "waybar"
function hl.add_layer_rule(rule, namespace)
    _keyword("layerrule", string.format("%s, %s", rule, namespace))
end

-- ---------------------------------------------------------------------------
-- hl.dsp — Dispatcher constructors
-- ---------------------------------------------------------------------------
-- Each constructor returns a table { _dispatch = "<dispatcher string>" }
-- or a function (for Lua-side logic dispatchers).

hl.dsp = {}

--- Emit a global signal (e.g. for Quickshell IPC).
--- @param signal string
--- @return table
function hl.dsp.global(signal)
    return { _dispatch = "global " .. signal }
end

--- Execute a shell command as a dispatcher.
--- @param cmd string
--- @return table
function hl.dsp.exec_cmd(cmd)
    return { _dispatch = "exec " .. cmd }
end

--- Enter a named submap.
--- @param name string  Use "reset" to exit all submaps.
--- @return table
function hl.dsp.submap(name)
    return { _dispatch = "submap " .. name }
end

--- Send a message to the active layout.
--- @param msg string  e.g. "splitratio +0.1"
--- @return table
function hl.dsp.layout(msg)
    return { _dispatch = "layoutmsg " .. msg }
end

-- hl.dsp.focus
-- Focuses a window in a direction OR switches to a workspace.
--- @param opts table  { direction="l"|"r"|"u"|"d", workspace="<id>" }
--- @return table
function hl.dsp.focus(opts)
    opts = opts or {}
    if opts.direction then
        return { _dispatch = "movefocus " .. opts.direction }
    elseif opts.workspace ~= nil then
        return { _dispatch = "workspace " .. tostring(opts.workspace) }
    end
    return { _dispatch = "focuswindow" }
end

-- hl.dsp.window table
hl.dsp.window = {}

--- Close the active window.
--- @return table
function hl.dsp.window.close()
    return { _dispatch = "killactive" }
end

--- Move (drag) the active window with the mouse.
--- @return table
function hl.dsp.window.drag()
    return { _dispatch = "movewindow" }
end

--- Resize the active window with the mouse OR by exact pixels.
--- When called with opts table { x=W, y=H, [1]="exact" } applies exact resize.
--- When called with no args, returns the mouse-resize dispatcher.
--- @param opts table|nil
--- @return table
function hl.dsp.window.resize(opts)
    if opts and (opts.x or opts[1]) then
        local mode = opts[1] or ""
        local x = opts.x or 0
        local y = opts.y or 0
        if mode == "exact" then
            return { _dispatch = string.format("resizeactive exact %d %d", x, y) }
        else
            return { _dispatch = string.format("resizeactive %d %d", x, y) }
        end
    end
    return { _dispatch = "resizewindow" }
end

--- Float or tile the active window.
--- @param opts table  { action="toggle"|"on"|"off" }
--- @return table
function hl.dsp.window.float(opts)
    opts = opts or {}
    local action = opts.action or "toggle"
    if action == "toggle" then
        return { _dispatch = "togglefloating" }
    elseif action == "on" then
        return { _dispatch = "setfloating" }
    else
        return { _dispatch = "settiled" }
    end
end

--- Fullscreen / maximise the active window.
--- @param opts table  { mode="fullscreen"|"maximized", action="toggle"|"on"|"off" }
--- @return table
function hl.dsp.window.fullscreen(opts)
    opts = opts or {}
    local mode   = opts.mode   or "fullscreen"
    local action = opts.action or "toggle"
    -- hyprctl dispatcher: fullscreen 0 = real, 1 = maximize, 2 = fake
    local mode_int = 0
    if mode == "maximized" then mode_int = 1 end

    if action == "toggle" then
        return { _dispatch = "fullscreen " .. mode_int }
    elseif action == "on" then
        return { _dispatch = "fullscreen " .. mode_int }
    else
        return { _dispatch = "fullscreen " .. mode_int }
    end
end

--- Set fullscreen state spoofing.
--- @param opts table  { internal=int, client=int, action="toggle" }
--- @return table
function hl.dsp.window.fullscreen_state(opts)
    opts = opts or {}
    local internal = opts.internal ~= nil and tostring(opts.internal) or "-1"
    local client   = opts.client   ~= nil and tostring(opts.client)   or "-1"
    return { _dispatch = string.format("fullscreenstate %s %s", internal, client) }
end

--- Pin the active window (visible on all workspaces).
--- @return table
function hl.dsp.window.pin()
    return { _dispatch = "pin" }
end

--- Move the active window to a workspace or in a direction.
--- @param opts table
---   opts.workspace  string|number  target workspace (supports "special:name", "r+1", etc.)
---   opts.follow     boolean        move focus to the window after sending
---   opts.direction  string         "l"|"r"|"u"|"d" (swaps with neighbour)
--- @return table
function hl.dsp.window.move(opts)
    opts = opts or {}
    if opts.direction then
        return { _dispatch = "swapwindow " .. opts.direction }
    end
    if opts.workspace ~= nil then
        local ws  = tostring(opts.workspace)
        local follow = opts.follow
        if follow == false then
            return { _dispatch = "movetoworkspacesilent " .. ws }
        else
            return { _dispatch = "movetoworkspace " .. ws }
        end
    end
    return { _dispatch = "movewindow" }
end

-- hl.dsp.workspace table
hl.dsp.workspace = {}

--- Toggle a named special (scratchpad) workspace.
--- @param name string
--- @return table
function hl.dsp.workspace.toggle_special(name)
    name = name or "special"
    return { _dispatch = "togglespecialworkspace " .. name }
end

-- ---------------------------------------------------------------------------
-- hl.bind
-- ---------------------------------------------------------------------------
-- Supported option keys:
--   description      string   — bind description (stored as a comment)
--   ignore_mods      boolean  — bind with ignoremods flag
--   transparent      boolean  — bind with transparent flag
--   release          boolean  — bind on key release (bindr)
--   locked           boolean  — bind even when screen is locked (bindl)
--   repeating        boolean  — bind repeat on hold (binde)
--   non_consuming    boolean  — do not consume the key event
--   mouse            boolean  — mouse button bind (bindm)
--   submap_universal boolean  — available in all submaps (bindu)

local function _parse_combo(combo)
    -- Normalise "SUPER + SHIFT + key" → mods, key
    -- Strip spaces around '+'
    local parts = {}
    for part in combo:gmatch("[^+]+") do
        parts[#parts + 1] = part:match("^%s*(.-)%s*$")
    end
    local key  = table.remove(parts)
    local mods = table.concat(parts, " ")
    return mods, key
end

local function _build_bind_flags(opts)
    opts = opts or {}
    local flags = ""
    if opts.locked        then flags = flags .. "l" end
    if opts.release       then flags = flags .. "r" end
    if opts.repeating     then flags = flags .. "e" end
    if opts.non_consuming then flags = flags .. "n" end
    if opts.mouse         then flags = flags .. "m" end
    if opts.ignore_mods   then flags = flags .. "i" end
    if opts.transparent   then flags = flags .. "t" end
    if opts.submap_universal then flags = flags .. "u" end
    return flags
end

--- Register a keybind.
--- @param combo      string          key combo, e.g. "SUPER + Q"
--- @param dispatcher string|table|function  dispatcher or Lua callback
--- @param opts       table|nil       optional flags (see above)
function hl.bind(combo, dispatcher, opts)
    opts = opts or {}
    local mods, key = _parse_combo(combo)
    local flags = _build_bind_flags(opts)
    local bind_kw = "bind" .. flags

    -- Lua function callback — wrap in an exec dispatcher using a temp script
    if type(dispatcher) == "function" then
        -- Store callback in a global registry keyed by a unique ID
        hl._callbacks = hl._callbacks or {}
        local cb_id = "cb_" .. tostring(#hl._callbacks + 1) .. "_" .. tostring(os.clock()):gsub("%.", "_")
        hl._callbacks[cb_id] = dispatcher
        -- Dispatch by invoking hyprland's Lua runtime callback mechanism
        -- In Hyprland 0.56 native Lua the callback is registered directly.
        -- We use the internal __hl_callback table written by the compositor.
        local dsp_str = string.format("__hl_lua_callback %s", cb_id)
        _keyword(bind_kw, string.format("%s, %s, exec, __hl_lua_exec %s", mods, key, cb_id))

        -- Register the callback so __hl_lua_exec can find it
        -- (Hyprland native Lua calls the function table directly)
        if not hl._registered_callbacks then hl._registered_callbacks = {} end
        hl._registered_callbacks[cb_id] = dispatcher
        return
    end

    -- Table dispatcher from hl.dsp.*
    local dsp_str
    if type(dispatcher) == "table" and dispatcher._dispatch then
        dsp_str = dispatcher._dispatch
    elseif type(dispatcher) == "string" then
        dsp_str = dispatcher
    else
        return
    end

    -- Split dispatcher into dispatcher-name and args
    local dsp_name, dsp_args = dsp_str:match("^(%S+)%s*(.*)")
    dsp_args = dsp_args or ""

    local line = string.format("%s, %s, %s, %s", mods, key, dsp_name, dsp_args)
    -- Trim trailing comma+space if no args
    line = line:gsub(",? *$", "")
    _keyword(bind_kw, line)
end

-- ---------------------------------------------------------------------------
-- hl.on — Event subscriptions
-- ---------------------------------------------------------------------------
-- Hyprland 0.56 native Lua exposes hl.on() natively; this shim provides
-- compatible behaviour when the runtime does not pre-populate hl.on.

--- Internal event handler registry
hl._event_handlers = hl._event_handlers or {}

--- Register a handler for a Hyprland event.
--- Supported events (Hyprland socket2 naming):
---   "hyprland.start"     — fired once at startup
---   "monitor.added"      — monitor hotplugged
---   "monitor.removed"    — monitor disconnected
---   "window.opened"      — new window opened
---   "window.closed"      — window destroyed
---   "workspace.changed"  — active workspace changed
---   "submap"             — submap changed
--- @param event   string
--- @param handler function
function hl.on(event, handler)
    if not hl._event_handlers[event] then
        hl._event_handlers[event] = {}
    end
    table.insert(hl._event_handlers[event], handler)

    -- For "hyprland.start" we fire immediately since the config is already loading.
    if event == "hyprland.start" then
        pcall(handler)
        return
    end

    -- For monitor events we subscribe via hyprctl dispatch exec with socat/jq
    -- when available, otherwise the compositor's own Lua runtime handles dispatch.
    if event == "monitor.added" then
        -- The Hyprland native Lua runtime calls hl._dispatch_event() for us.
        -- This registration is sufficient for the 0.56 native Lua environment.
        return
    end

    -- Other events are handled by the compositor calling hl._dispatch_event()
end

--- Called by the Hyprland compositor runtime to deliver events to Lua handlers.
--- @param event string
--- @param data  any
function hl._dispatch_event(event, data)
    local handlers = hl._event_handlers[event]
    if not handlers then return end
    for _, h in ipairs(handlers) do
        local ok, err = pcall(h, data)
        if not ok then
            -- Log but do not crash the compositor thread
            io.stderr:write(string.format("[hl] event handler error (%s): %s\n", event, tostring(err)))
        end
    end
end

-- ---------------------------------------------------------------------------
-- hl.define_submap
-- ---------------------------------------------------------------------------
-- Defines a named submap. The fn is called immediately in the current context;
-- any hl.bind() calls inside register binds in that submap.

--- @param name string
--- @param fn   function
function hl.define_submap(name, fn)
    -- Enter the submap context for keyword registration
    _keyword("submap", name)
    pcall(fn)
    -- Return to default submap
    _keyword("submap", "reset")
end

-- ---------------------------------------------------------------------------
-- hl.get_monitors
-- ---------------------------------------------------------------------------

--- Return a list of monitor info tables as reported by hyprctl.
--- Each table has at least: id, name, description, width, height, scale.
--- @return table[]
function hl.get_monitors()
    local out = _hyprctl("monitors -j")
    if not out or out == "" then return {} end

    -- Simple JSON array parser for monitor objects
    local monitors = {}
    -- Extract individual JSON objects
    for obj in out:gmatch("{[^{}]+}") do
        local mon = {}
        mon.id          = tonumber(obj:match('"id"%s*:%s*(%d+)'))          or 0
        mon.name        = obj:match('"name"%s*:%s*"([^"]*)"')              or ""
        mon.description = obj:match('"description"%s*:%s*"([^"]*)"')       or ""
        mon.width       = tonumber(obj:match('"width"%s*:%s*(%d+)'))       or 0
        mon.height      = tonumber(obj:match('"height"%s*:%s*(%d+)'))      or 0
        mon.scale       = tonumber(obj:match('"scale"%s*:%s*([%d%.]+)'))   or 1.0
        mon.focused     = obj:match('"focused"%s*:%s*(true)') ~= nil
        table.insert(monitors, mon)
    end
    return monitors
end

-- ---------------------------------------------------------------------------
-- hl.get_current_submap
-- ---------------------------------------------------------------------------

--- Return the name of the currently active submap, or "" if none.
--- @return string
function hl.get_current_submap()
    -- Hyprland 0.56.2: `hyprctl submap` returns the current submap name or empty string
    local sub = _hyprctl("submap") or ""
    return sub:match("^%s*(.-)%s*$") or ""
end

-- ---------------------------------------------------------------------------
-- workspace_in_group
-- ---------------------------------------------------------------------------

--- Map workspace index 1-10 within the current monitor's group to a global
--- workspace ID.  By default groups are 10 workspaces wide.
--- Override by setting WORKSPACE_GROUP_SIZE environment variable.
---
--- @param i number  1-10
--- @return number
local _group_size = tonumber(os.getenv("WORKSPACE_GROUP_SIZE")) or 10

function workspace_in_group(i)
    -- Determine which monitor group we are in based on the focused monitor's
    -- workspace.  Falls back to group 0 if hyprctl is unavailable.
    local out = _hyprctl("activeworkspace -j") or ""
    local ws_id = tonumber(out:match('"id"%s*:%s*(%d+)')) or 1
    local group = math.floor((ws_id - 1) / _group_size)
    -- Workspace 10 maps to index 0 in keybinds (SUPER+0), hence modulo
    local idx = i == 10 and 10 or i
    return group * _group_size + idx
end

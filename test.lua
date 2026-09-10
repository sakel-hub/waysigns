-- Mock Luanti core environment for unit testing waysigns
if not string.split then
    rawset(string, 'split', function(str, sep)
        local parts = {}
        local pattern = string.format("([^%s]+)", sep)
        for part in str:gmatch(pattern) do
            table.insert(parts, part)
        end
        return parts
    end)
end

core = {
    get_current_modname = function() return 'waysigns' end,
    get_modpath = function() return '.' end,
    get_translator = function() return function(s, ...)
        local args = {...}
        return s:gsub('@(%d+)', function(n) return tostring(args[tonumber(n)] or '') end)
    end end,
    settings = {
        get = function(self, k) return nil end,
        get_bool = function(self, k, def) return def end,
    },
    registered_nodes = {
        ['default:sign_wall_wood'] = {
            description = 'Wooden Sign',
            tiles = {'default_sign_wall_wood.png'},
            drawtype = 'nodebox',
        },
        ['default:sign_wall_steel'] = {
            description = 'Steel Sign',
            tiles = {'default_sign_wall_steel.png'},
            drawtype = 'nodebox',
        },
        ['custom:road_sign'] = {
            description = 'Road Sign',
            tiles = {'road_sign.png'},
            drawtype = 'signlike',
            groups = {sign = 1},
        }
    },
    get_item_group = function(name, group)
        local n = core.registered_nodes[name]
        return (n and n.groups and n.groups[group]) or 0
    end,
    get_meta = function(pos)
        _G.mock_world_meta = _G.mock_world_meta or {}
        local k = pos and string.format('%d,%d,%d', math.floor((pos.x or 0) + 0.5), math.floor((pos.y or 0) + 0.5), math.floor((pos.z or 0) + 0.5))
        if k and not pos.meta and _G.mock_world_meta[k] then
            pos.meta = _G.mock_world_meta[k]
        else
            pos.meta = pos.meta or {}
            if k then _G.mock_world_meta[k] = pos.meta end
        end
        return {
            get_string = function(self, key)
                return pos.meta and pos.meta[key] or ''
            end,
            set_string = function(self, key, val)
                pos.meta = pos.meta or {}
                pos.meta[key] = val
            end,
            get_inventory = function(self)
                return pos.inv
            end,
        }
    end,
    inventorycube = function(img1, img2, img3)
        img2 = img2 or img1
        img3 = img3 or img1
        return '[inventorycube{' .. img1:gsub('%^', '&') .. '{' .. img2:gsub('%^', '&') .. '{' .. img3:gsub('%^', '&')
    end,
    check_player_privs = function(player, priv)
        return not not (player and player.privs and player.privs[priv])
    end,
    is_protected = function(pos, player_name)
        return pos.is_protected == true
    end,
    registered_items = setmetatable({}, {
        __index = function(_, k)
            return (core.registered_nodes and core.registered_nodes[k])
                or (core.registered_craftitems and core.registered_craftitems[k])
                or (core.registered_tools and core.registered_tools[k])
        end,
    }),
    raycast = function() return function() return nil end end,
    register_globalstep = function() end,
    register_on_joinplayer = function() end,
    register_on_leaveplayer = function() end,
    register_on_dieplayer = function() end,
    register_on_punchnode = function() end,
    register_on_dignode = function() end,
    register_on_placenode = function() end,
    registered_on_shutdown = {},
    register_on_shutdown = function(cb)
        table.insert(core.registered_on_shutdown, cb)
    end,
    global_exists = function(name) return _G[name] ~= nil end,
    registered_entities = {},
    registered_tools = {},
    register_tool = function(name, def)
        core.registered_tools[name] = def
    end,
    registered_crafts = {},
    register_craft = function(def)
        table.insert(core.registered_crafts, def)
    end,
    registered_on_player_receive_fields = {},
    register_on_player_receive_fields = function(cb)
        table.insert(core.registered_on_player_receive_fields, cb)
    end,
    show_formspec = function(player_name, formname, formspec)
        _G.last_shown_formspec = { player_name = player_name, formname = formname, formspec = formspec }
    end,
    close_formspec = function(player_name, formname)
        _G.last_closed_formspec = { player_name = player_name, formname = formname }
    end,
    sound_play = function(sound, spec)
        _G.last_sound_play = { sound = sound, spec = spec }
    end,
    formspec_escape = function(text)
        return (tostring(text or ''):gsub('\\', '\\\\'):gsub('%[', '\\['):gsub('%]', '\\]'):gsub(';', '\\;'):gsub(',', '\\,'):gsub('%%$', '\\$'))
    end,
    record_protection_violation = function(pos, player_name)
        _G.last_protection_violation = { pos = pos, player_name = player_name }
    end,
    chat_send_player = function(player_name, msg)
        _G.last_chat_message = { player = player_name, message = msg }
    end,
    register_lbm = function() end,
    register_chatcommand = function() end,
    register_on_mods_loaded = function(cb) cb() end,
    override_item = function(name, redefinition)
        local def = core.registered_nodes[name]
        assert(def, 'Item not registered: ' .. name)
        for k, v in pairs(redefinition) do
            rawset(def, k, v)
        end
    end,
    get_objects_inside_radius = function(pos, r) return _G.mock_objects or {} end,
    get_connected_players = function() return _G.mock_players or {} end,
    get_player_window_information = function() return nil end,
    get_us_time = function() return math.floor(os.clock() * 1000000) end,
    find_nodes_with_meta = function(minp, maxp) return {} end,
    after = function(delay, func) func() end,
    get_node = function(pos) return {name = 'air', param1 = 0, param2 = 0} end,
    _mod_storage_store = {},
    get_mod_storage = function()
        return {
            get_string = function(self, key)
                return core._mod_storage_store[key] or ''
            end,
            set_string = function(self, key, val)
                core._mod_storage_store[key] = val
            end,
        }
    end,
    write_json = function(data)
        core._mod_storage_store['__last_table__'] = data
        return '{"valid":true}'
    end,
    parse_json = function(str)
        return core._mod_storage_store['__last_table__'] or {}
    end,
    line_of_sight = function(pos1, pos2)
        if core._line_of_sight_override ~= nil then
            return core._line_of_sight_override
        end
        return true
    end,
    strip_colors = function(str) return str:gsub('\x1b%(c@[^)]*%)', ''):gsub('\x1b%(b@[^)]*%)', '') end,
    strip_escapes = function(str) return str:gsub('\x1b%b()', ''):gsub('\x1bE', ''):gsub('\x1b(.)', ''):gsub('\x1b', '') end,
    colorize = function(color, str) return '\x1b(c@' .. color .. ')' .. tostring(str or '') .. '\x1b(c@#ffffff)' end,
    get_color_escape_sequence = function(color) return '' end,
    hash_node_position = function(p)
        return (p.x or 0) + 65536 * ((p.y or 0) + 65536 * (p.z or 0))
    end,
    pos_to_string = function(p)
        return string.format("(%d,%d,%d)", p.x or 0, p.y or 0, p.z or 0)
    end,
    wallmounted_to_dir = function(param2)
        local p = (param2 or 0) % 8
        local dirs = {
            [0] = { x = 0, y = 1, z = 0 },
            [1] = { x = 0, y = -1, z = 0 },
            [2] = { x = 1, y = 0, z = 0 },
            [3] = { x = -1, y = 0, z = 0 },
            [4] = { x = 0, y = 0, z = 1 },
            [5] = { x = 0, y = 0, z = -1 },
        }
        return dirs[p] or { x = 0, y = 1, z = 0 }
    end,
    facedir_to_dir = function(param2)
        local p = (param2 or 0) % 4
        local dirs = {
            [0] = { x = 0, y = 0, z = 1 },
            [1] = { x = 1, y = 0, z = 0 },
            [2] = { x = 0, y = 0, z = -1 },
            [3] = { x = -1, y = 0, z = 0 },
        }
        return dirs[p] or { x = 0, y = 0, z = 1 }
    end,
    fourdir_to_dir = function(param2)
        local p = (param2 or 0) % 4
        local dirs = {
            [0] = { x = 0, y = 0, z = 1 },
            [1] = { x = 1, y = 0, z = 0 },
            [2] = { x = 0, y = 0, z = -1 },
            [3] = { x = -1, y = 0, z = 0 },
        }
        return dirs[p] or { x = 0, y = 0, z = 1 }
    end,
    yaw_to_dir = function(yaw)
        return {
            x = -math.sin(yaw),
            y = 0,
            z = math.cos(yaw),
        }
    end,
}

if not ItemStack then
    ItemStack = function(item)
        local name = ''
        local count = 1
        local wear = 0
        if type(item) == 'string' then
            name = item
        elseif type(item) == 'table' then
            name = item.name or ''
            count = item.count or 1
            wear = item.wear or 0
        end
        local stack
        stack = {
            name = name,
            count = count,
            wear = wear,
            get_name = function(self) return self.name end,
            get_count = function(self) return self.count end,
            get_wear = function(self) return self.wear end,
            is_empty = function(self) return (self.count or 0) <= 0 or (self.name or '') == '' end,
            set_count = function(self, c) self.count = c end,
            add_wear = function(self, amount)
                self.wear = math.min(65535, self.wear + amount)
                if self.wear >= 65535 then
                    self.count = 0
                    self.name = ''
                end
            end,
            add_wear_by_uses = function(self, max_uses)
                if max_uses <= 0 then return end
                self:add_wear(math.floor(65535 / max_uses))
            end,
        }
        return stack
    end
end

vector = {
    new = function(x, y, z) return {x = x or 0, y = y or 0, z = z or 0} end,
    add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
    subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
    multiply = function(a, s) return {x = a.x * s, y = a.y * s, z = a.z * s} end,
    dot = function(a, b) return (a.x * b.x) + (a.y * b.y) + (a.z * b.z) end,
    equals = function(a, b) return a and b and a.x == b.x and a.y == b.y and a.z == b.z end,
    round = function(p) return {x = math.floor(p.x + 0.5), y = math.floor(p.y + 0.5), z = math.floor(p.z + 0.5)} end,
    distance = function(a, b)
        local dx = a.x - b.x
        local dy = a.y - b.y
        local dz = a.z - b.z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end,
}

if not bit then
    local has_bit, mod_bit = pcall(require, 'bit')
    if has_bit and type(mod_bit) == 'table' then
        bit = mod_bit
    else
        local has_bit32, mod_bit32 = pcall(require, 'bit32')
        if has_bit32 and type(mod_bit32) == 'table' then
            bit = mod_bit32
        else
            local function band2(a, b)
                local res = 0
                local bitval = 1
                a = math.floor(a) % 4294967296
                b = math.floor(b) % 4294967296
                while a > 0 and b > 0 do
                    local ra = a % 2
                    local rb = b % 2
                    if ra == 1 and rb == 1 then
                        res = res + bitval
                    end
                    a = (a - ra) / 2
                    b = (b - rb) / 2
                    bitval = bitval * 2
                end
                return res
            end

            local function bor2(a, b)
                local res = 0
                local bitval = 1
                a = math.floor(a) % 4294967296
                b = math.floor(b) % 4294967296
                while a > 0 or b > 0 do
                    local ra = a % 2
                    local rb = b % 2
                    if ra == 1 or rb == 1 then
                        res = res + bitval
                    end
                    a = (a - ra) / 2
                    b = (b - rb) / 2
                    bitval = bitval * 2
                end
                return res
            end

            bit = {
                band = function(...)
                    local args = {...}
                    local res = args[1] or 0
                    for i = 2, #args do
                        res = band2(res, args[i])
                    end
                    return res
                end,
                bor = function(...)
                    local args = {...}
                    local res = args[1] or 0
                    for i = 2, #args do
                        res = bor2(res, args[i])
                    end
                    return res
                end,
                lshift = function(a, b)
                    return math.floor(a * (2 ^ b)) % 4294967296
                end,
                rshift = function(a, b)
                    return math.floor((math.floor(a) % 4294967296) / (2 ^ b))
                end,
            }
        end
    end
end

local script_dir = '.'
local info = debug.getinfo(1, 'S')
if info and info.source and info.source:sub(1, 1) == '@' then
    script_dir = info.source:sub(2):match('^(.*[/\\])') or '.'
    if (script_dir:sub(-1) == '/' or script_dir:sub(-1) == '\\') and #script_dir > 1 then
        script_dir = script_dir:sub(1, -2)
    end
end

dofile(script_dir .. '/api.lua')
dofile(script_dir .. '/compat.lua')
dofile(script_dir .. '/marker.lua')

print('--- Test 1: wrap_text short text ---')
local res1 = waysigns.wrap_text('Hello World', 30, 5)
assert(#res1.pages == 1, 'Expected 1 page')
assert(res1.pages[1][1].text == 'Hello World', 'Expected Hello World')
print('PASS Test 1')

print('--- Test 2: wrap_text preserved line breaks & signs_lib color codes ---')
local res2 = waysigns.wrap_text("#c Hello world\nLine 2\n#e Warning", 30, 5)
assert(#res2.pages[1] == 3, 'Expected 3 lines')
assert(res2.pages[1][1].text == 'Hello world', 'Expected "#c" stripped from "Hello world"')
assert(res2.pages[1][1].color == 0xFF5555, 'Expected bright red color 0xFF5555 for #c')
assert(res2.pages[1][2].text == 'Line 2', 'Expected Line 2')
assert(res2.pages[1][3].text == 'Warning', 'Expected Warning')
assert(res2.pages[1][3].color == 0xFFFF55, 'Expected yellow color 0xFFFF55 for #e')
print('PASS Test 2')

print('--- Test 3: wrap_text word wrap on spaces ---')
local long_sentence = 'This is a very long announcement designed to test the word wrapping algorithm properly without hyphenating prematurely.'
local res3 = waysigns.wrap_text(long_sentence, 25, 5)
assert(#res3.pages[1] > 1, 'Expected multiple lines')
for _, line in ipairs(res3.pages[1]) do
    assert(#line.text <= 25, 'Line length exceeded max_chars: ' .. line.text)
end
print('PASS Test 3')

print('--- Test 4: wrap_text pagination ---')
local multi_line = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7"
local res4 = waysigns.wrap_text(multi_line, 30, 4)
assert(#res4.pages == 2, 'Expected 2 pages for 7 lines with max 4')
assert(#res4.pages[1] == 4, 'Page 1 should have 4 lines')
assert(#res4.pages[2] == 3, 'Page 2 should have 3 lines')
print('PASS Test 4')

print('--- Test 5: Dynamic scaled texture composition ---')
local tex = waysigns.get_background_texture('default_sign_wall_wood.png', 240, 80, 1.0, false)
assert(tex:find('default_sign_wall_wood%.png'), 'Expected wood texture')
assert(tex:find('%^%[resize:240x80'), 'Expected scaled single base texture')
assert(tex:find('%^%[colorize:#060402:160'), 'Expected deep wood contrast glaze (#060402:160)')
assert(tex:find('%^%[opacity:255'), 'Expected full opacity')
-- Check caching
local tex2 = waysigns.get_background_texture('default_sign_wall_wood.png', 240, 80, 1.0, false)
assert(tex == tex2, 'Expected cached texture string')
print('PASS Test 5')

print('--- Test 6: Sign detection, clean_tile_name & signs_lib crop ---')
local pos_wood = {x = 10, y = 1, z = 5, meta = {text = '#c Shop: Bread for 1 Gold'}}
local data_wood = waysigns.get_sign_data(pos_wood, {name = 'default:sign_wall_wood', param2 = 0})
assert(data_wood ~= nil, 'Expected sign data')
assert(data_wood.wrapped.pages[1][1].text == 'Shop: Bread for 1 Gold', 'Expected #c stripped')
assert(data_wood.wrapped.pages[1][1].color == 0xFF5555, 'Expected red text color')
assert(data_wood.is_metal == false, 'Expected wood sign')

local pos_steel = {x = 10, y = 1, z = 6, meta = {infotext = '"Caution: High Voltage"'}}
local data_steel = waysigns.get_sign_data(pos_steel, {name = 'default:sign_wall_steel', param2 = 0})
assert(data_steel ~= nil, 'Expected steel sign data')
assert(data_steel.wrapped.pages[1][1].text == 'Caution: High Voltage', 'Infotext quotes not stripped')
assert(data_steel.is_metal == true, 'Expected steel sign')

local pos_generic = {x = 10, y = 1, z = 7, meta = {text = 'Road to Castle'}}
local data_generic = waysigns.get_sign_data(pos_generic, {name = 'custom:road_sign', param2 = 0})
assert(data_generic ~= nil, 'Expected generic sign detection')
assert(data_generic.tile == 'road_sign.png', 'Expected custom road sign tile')

-- Test signs_lib 64x32 dual-tile cropping
core.registered_nodes['signs:sign_wall_wood'] = {
    description = 'Signslib Wooden Sign',
    tiles = {'signs_lib_sign_wall_wooden.png', 'signs_lib_sign_wall_wooden_edges.png'},
    drawtype = 'nodebox',
}
local pos_slib = {x = 12, y = 1, z = 5, meta = {text = 'SignsLib Board'}}
local data_slib = waysigns.get_sign_data(pos_slib, {name = 'signs:sign_wall_wood', param2 = 0})
assert(data_slib ~= nil, 'Expected sign data for signslib')
assert(data_slib.tile:find('%^%[sheet:2x1:0,0'), 'Expected sheet crop for signs_lib 64x32 texture')
local slib_tex = waysigns.get_background_texture(data_slib.tile, 280, 80, 1.0, false)
assert(slib_tex:find('signs_lib_sign_wall_wooden%.png%^%[sheet:2x1:0,0%^%[resize:280x80'), 'Expected cropped front face resized')
print('PASS Test 6')

print('--- Test 7: Player state, render HUD & removal ---')
local hud_active_count = 0
local next_hud_id = 0
local mock_player = {
    get_player_name = function() return 'TestPlayer' end,
    hud_add = function(self, def)
        next_hud_id = next_hud_id + 1
        hud_active_count = hud_active_count + 1
        return next_hud_id
    end,
    hud_change = function(self, id, stat, val) end,
    hud_remove = function(self, id)
        hud_active_count = hud_active_count - 1
    end,
}

local state = waysigns.get_or_create_player_state(mock_player)
state.current_sign_pos = pos_wood
state.current_sign_data = data_wood
state.current_sign_normal = vector.new(0, 0, 1)
state.opacity = 1.0

waysigns.render_hud(mock_player, state)
assert(state.is_visible == true, 'Expected visible state')
assert(state.hud_bg_id ~= nil, 'Expected bg HUD id')
assert(#state.hud_line_ids > 0, 'Expected line HUD ids')

waysigns.remove_all_huds(mock_player)
assert(state.is_visible == false, 'Expected hidden state')
assert(hud_active_count == 0, 'Expected all HUDs removed')
print('PASS Test 7')

print('--- Test 8: Back-and-forth sign switching (No stuck HUD) ---')
-- Simulate player looking at Sign 1
waysigns.show_hud(mock_player, pos_wood, data_wood, vector.new(0, 0, 1))
assert(state.is_visible == true, 'HUD should be visible for sign 1')
assert(vector.equals(state.current_sign_pos, pos_wood), 'Pos should be sign 1')
local bg1 = state.hud_bg_id

-- Player immediately turns head to Sign 2 (slib sign)
waysigns.show_hud(mock_player, pos_slib, data_slib, vector.new(0, 0, 1))
assert(state.is_visible == true, 'HUD should be visible for sign 2')
assert(vector.equals(state.current_sign_pos, pos_slib), 'Pos should be updated to sign 2')
assert(state.current_sign_data.raw_text == 'SignsLib Board', 'Data should be sign 2')
local bg2 = state.hud_bg_id
assert(bg1 ~= bg2, 'Old HUD element must be cleanly replaced with new HUD element')

-- Player turns back to Sign 1
waysigns.show_hud(mock_player, pos_wood, data_wood, vector.new(0, 0, 1))
assert(state.is_visible == true, 'HUD should be visible for sign 1 again')
assert(vector.equals(state.current_sign_pos, pos_wood), 'Pos should be back to sign 1')
assert(state.current_sign_data.raw_text == '#c Shop: Bread for 1 Gold', 'Data should be sign 1')
print('PASS Test 8')

print('--- Test 9: Distance and check interval verification ---')
assert(waysigns.settings.max_distance >= 4.0, 'Expected detection distance to be at least 4 blocks away')
assert(waysigns.settings.check_interval <= 0.05, 'Expected check interval to be 0.05s or less')
print('PASS Test 9')

print('--- Test 10: basic_signs dual-tile sheet cropping & registration ---')
core.registered_nodes['basic_signs:sign_wall_steel_green'] = {
    description = 'Green Steel Sign',
    tiles = {
        'basic_signs_steel_green.png',
        'signs_lib_sign_wall_steel_edges.png',
        nil,
        nil,
        'default_steel_block.png'
    },
    inventory_image = 'basic_signs_steel_green_inv.png',
    drawtype = 'nodebox',
}
local pos_bs_green = {x = 15, y = 1, z = 5, meta = {text = 'Green Steel Signboard'}}
local data_bs_green = waysigns.get_sign_data(pos_bs_green, {name = 'basic_signs:sign_wall_steel_green', param2 = 0})
assert(data_bs_green ~= nil, 'Expected sign data for basic_signs green')
assert(data_bs_green.tile:find('%^%[sheet:2x1:0,0'), 'basic_signs_steel_green texture must be cropped with sheet:2x1:0,0')
assert(data_bs_green.is_metal == true, 'Expected basic_signs steel to be metal')

-- Test basic_signs glass
core.registered_nodes['basic_signs:sign_wall_glass'] = {
    description = 'Glass Sign',
    tiles = {
        {name = 'basic_signs_sign_wall_glass.png', backface_culling = true},
        'basic_signs_sign_wall_glass_edges.png',
        'basic_signs_pole_mount_glass.png'
    },
    drawtype = 'nodebox',
}
local pos_bs_glass = {x = 15, y = 1, z = 6, meta = {text = 'Glass Notice'}}
local data_bs_glass = waysigns.get_sign_data(pos_bs_glass, {name = 'basic_signs:sign_wall_glass', param2 = 0})
assert(data_bs_glass ~= nil, 'Expected sign data for basic_signs glass')
assert(data_bs_glass.tile:find('%^%[sheet:2x1:0,0'), 'basic_signs glass texture must be cropped with sheet:2x1:0,0')
print('PASS Test 10')

print('--- Test 11: get_effective_scale responsiveness ---')
-- Default without window info (mock returns nil)
assert(waysigns.get_effective_scale(mock_player) == 2.0, 'Expected default 2.0 scale')

-- Mock window info for 1920x1080
core.get_player_window_information = function(pname)
    return { size = { x = 1920, y = 1080 } }
end
assert(waysigns.get_effective_scale(mock_player) == 2.0, 'Expected 2.0 scale on 1080p')

-- Mock window info for small screen 800x600
core.get_player_window_information = function(pname)
    return { size = { x = 800, y = 600 } }
end
local small_scale = waysigns.get_effective_scale(mock_player)
assert(small_scale < 2.0 and small_scale >= 1.0, 'Expected adaptive downscaling on 800x600')
print('PASS Test 11 (scaled to ' .. small_scale .. ' on 800x600)')

print('--- Test 12: 2x HUD overlay dimensions and typography ---')
core.get_player_window_information = function(pname)
    return { size = { x = 1920, y = 1080 } }
end
waysigns.settings.display_mode = 'overlay'

local captured_hud_defs = {}
local mock_screen_player = {
    get_player_name = function() return 'ScreenPlayer' end,
    hud_add = function(self, def)
        table.insert(captured_hud_defs, def)
        return #captured_hud_defs
    end,
    hud_change = function(self, id, stat, val)
        if captured_hud_defs[id] then
            captured_hud_defs[id][stat] = val
        end
    end,
    hud_remove = function(self, id)
        captured_hud_defs[id] = nil
    end,
    get_inventory = function(self) return nil end,
    get_wielded_item = function(self) return nil end,
    get_properties = function(self) return { eye_height = 1.625 } end,
    get_hp = function(self) return 20 end,
    is_player = function(self) return true end,
    is_valid = function(self) return true end,
}

local screen_state = waysigns.get_or_create_player_state(mock_screen_player)
screen_state.current_sign_pos = pos_bs_green
screen_state.current_sign_data = data_bs_green
screen_state.opacity = 1.0

waysigns.render_hud(mock_screen_player, screen_state)
assert(#captured_hud_defs >= 2, 'Expected background and text HUD elements')

-- Inspect background element
local bg_elem = captured_hud_defs[1]
assert(bg_elem.type == 'image', 'Expected screen image HUD element')
assert(bg_elem.position.y == waysigns.settings.overlay_pos_y, 'Expected overlay_pos_y Y position, got ' .. tostring(bg_elem.position.y))
assert(bg_elem.text:find('%^%[resize:'), 'Expected resize modifier on background')

-- Inspect text element
local text_elem = captured_hud_defs[2]
assert(text_elem.type == 'text', 'Expected text HUD element')
assert(text_elem.size and text_elem.size.x == 2.0, 'Expected 2.0 font size scale')
assert(text_elem.style == 1, 'Expected bold font style (1)')
print('PASS Test 12')

print('--- Test 13: Aspect ratio detection from node_box & registration ---')
-- Default sign with wallmounted nodebox
local test_node_def = {
    drawtype = 'nodebox',
    node_box = {
        type = 'wallmounted',
        wall_side = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375}
    }
}
local detected_ar = waysigns.get_aspect_ratio('default:sign_wall_wood', test_node_def, nil)
assert(math.abs(detected_ar - 1.40) < 0.02, 'Expected ~1.40 aspect ratio for standard sign, got ' .. detected_ar)

-- Square mailbox registration
local mailbox_def = {
    drawtype = 'normal',
    node_box = { type = 'regular' }
}
local mailbox_reg = { aspect_ratio = 1.0 }
local mb_ar = waysigns.get_aspect_ratio('xdecor:mailbox', mailbox_def, mailbox_reg)
assert(mb_ar == 1.0, 'Expected 1.0 aspect ratio for mailbox, got ' .. mb_ar)
print('PASS Test 13')

print('--- Test 14: HUD Board width/height matches sign aspect ratio ---')
-- 1. Standard sign (aspect ratio 1.40)
waysigns.remove_all_huds(mock_screen_player)
captured_hud_defs = {}
screen_state.current_sign_pos = pos_bs_green
screen_state.current_sign_data = data_bs_green
screen_state.opacity = 1.0

waysigns.render_hud(mock_screen_player, screen_state)
local bg_text_standard = captured_hud_defs[screen_state.hud_bg_id].text
local w1, h1 = bg_text_standard:match('%^%[resize:(%d+)x(%d+)')
w1, h1 = tonumber(w1), tonumber(h1)
assert(w1 and h1, 'Expected resize dimensions in texture string')
local ratio1 = w1 / h1
assert(math.abs(ratio1 - 1.40) < 0.05, 'Expected board aspect ratio close to 1.40, got ' .. ratio1 .. ' (' .. w1 .. 'x' .. h1 .. ')')

-- 2. Square mailbox (aspect ratio 1.0)
core.registered_nodes['xdecor:mailbox'] = {
    description = 'Mailbox',
    tiles = {'xdecor_mailbox_top.png', 'xdecor_mailbox_bottom.png', 'xdecor_mailbox_side.png'},
    drawtype = 'normal',
    node_box = { type = 'regular' },
}
local pos_mailbox = {x = 10, y = 1, z = 10, meta = {text = 'Mail for Player1'}}
local data_mailbox = waysigns.get_sign_data(pos_mailbox, {name = 'xdecor:mailbox', param2 = 0})
assert(data_mailbox ~= nil, 'Expected sign data for mailbox')
assert(data_mailbox.aspect_ratio == 1.0, 'Expected mailbox aspect ratio 1.0')

waysigns.remove_all_huds(mock_screen_player)
captured_hud_defs = {}
screen_state.current_sign_pos = pos_mailbox
screen_state.current_sign_data = data_mailbox
screen_state.opacity = 1.0

waysigns.render_hud(mock_screen_player, screen_state)
local bg_text_mb = captured_hud_defs[screen_state.hud_bg_id].text
local w2, h2 = bg_text_mb:match('%^%[resize:(%d+)x(%d+)')
w2, h2 = tonumber(w2), tonumber(h2)
assert(w2 and h2, 'Expected resize dimensions for mailbox')
local ratio2 = w2 / h2
assert(math.abs(ratio2 - 1.0) < 0.02, 'Expected square mailbox board (1.0 ratio), got ' .. ratio2 .. ' (' .. w2 .. 'x' .. h2 .. ')')
print('PASS Test 14 (Standard: ' .. w1 .. 'x' .. h1 .. ' [AR ' .. string.format('%.2f', ratio1) .. '], Mailbox: ' .. w2 .. 'x' .. h2 .. ' [AR ' .. string.format('%.2f', ratio2) .. '])')

print('--- Test 15: Purge sign text entities ---')
local removed_entities = {}
local mock_ent1 = {
    is_player = function() return false end,
    get_luaentity = function() return { name = 'signs_lib:text' } end,
    remove = function(self) table.insert(removed_entities, 'signs_lib:text') end,
}
local mock_ent2 = {
    is_player = function() return false end,
    get_luaentity = function() return { name = 'mcl_signs:text' } end,
    remove = function(self) table.insert(removed_entities, 'mcl_signs:text') end,
}
local mock_ent_other = {
    is_player = function() return false end,
    get_luaentity = function() return { name = 'mobs_animal:cow' } end,
    remove = function(self) table.insert(removed_entities, 'mobs_animal:cow') end,
}
_G.mock_objects = { mock_ent1, mock_ent2, mock_ent_other }
waysigns.purge_sign_entities({x = 10, y = 5, z = 20})
assert(#removed_entities == 2, 'Expected exactly 2 sign text entities removed, got ' .. #removed_entities)
assert(removed_entities[1] == 'signs_lib:text', 'Expected signs_lib:text removed')
assert(removed_entities[2] == 'mcl_signs:text', 'Expected mcl_signs:text removed')
print('PASS Test 15')

print('--- Test 16: Entity suppression neutralization ---')
_G.signs_lib = {
    spawn_entity = function() return 'old_entity' end,
    set_obj_text = function() end,
}
core.registered_entities['signs_lib:text'] = {
    on_activate = function() return 'active' end,
    on_step = function() return 'step' end,
}
-- Re-run compat suppression hook
local _ = dofile(script_dir .. '/compat.lua')
removed_entities = {}
local spawn_result = signs_lib.spawn_entity({x = 10, y = 5, z = 20}, 'some_texture', '')
assert(spawn_result == nil, 'Expected signs_lib.spawn_entity to return nil')
assert(#removed_entities == 2, 'Expected spawn_entity to trigger purge')

local test_self = { object = { remove = function() table.insert(removed_entities, 'self_removed') end } }
core.registered_entities['signs_lib:text'].on_activate(test_self)
assert(removed_entities[#removed_entities] == 'self_removed', 'Expected on_activate to call self.object:remove()')
_G.mock_objects = nil
print('PASS Test 16')

print('--- Test 17: Precise face center calculation (get_sign_face_pos) ---')
local sign_pos_test = { x = 10, y = 5, z = 20 }
local norm_test = { x = 0, y = 0, z = 1 }
-- 1. Direct hit on sign face (is_attached_above = false)
local hit_point1 = { x = 10.3, y = 5.2, z = 19.5625 }
local face_pos1 = waysigns.get_sign_face_pos(sign_pos_test, norm_test, hit_point1, false)
-- X and Y must be centered on the sign node (10, 5)
assert(face_pos1.x == 10, 'Expected face X to match sign node center 10, got ' .. face_pos1.x)
assert(face_pos1.y == 5, 'Expected face Y to match sign node center 5, got ' .. face_pos1.y)
-- Z must be 0.02m off the contact surface (19.5625 + 0.02 = 19.5825)
assert(math.abs(face_pos1.z - 19.5825) < 0.001, 'Expected face Z 19.5825, got ' .. face_pos1.z)

-- 2. Hit on wall backing (is_attached_above = true)
local hit_wall = { x = 10.1, y = 5.4, z = 19.5 }
local face_pos2 = waysigns.get_sign_face_pos(sign_pos_test, norm_test, hit_wall, true)
assert(face_pos2.x == 10 and face_pos2.y == 5, 'Expected face X/Y centered on sign')
-- Z must be wall (19.5) + sign thickness (0.0625) + skin offset (0.02) = 19.5825
assert(math.abs(face_pos2.z - 19.5825) < 0.001, 'Expected attached face Z 19.5825, got ' .. face_pos2.z)

-- 3. Fallback when intersection_point is nil
local face_fallback = waysigns.get_sign_face_pos(sign_pos_test, norm_test, nil, false)
assert(face_fallback.x == 10 and face_fallback.y == 5, 'Expected fallback X/Y centered on sign')
assert(math.abs(face_fallback.z - 19.5825) < 0.001, 'Expected fallback face Z 19.5825, got ' .. face_fallback.z)
print('PASS Test 17')

print('--- Test 18: HUD positioning in waypoint and overlay modes ---')
-- 1. Waypoint mode: world_pos is sign_face_pos
waysigns.settings.display_mode = 'waypoint'
waysigns.remove_all_huds(mock_screen_player)
captured_hud_defs = {}
screen_state.current_sign_pos = sign_pos_test
screen_state.sign_face_pos = face_pos1
screen_state.current_sign_data = data_mailbox
screen_state.opacity = 1.0

waysigns.render_hud(mock_screen_player, screen_state)
do
    local wp_bg = captured_hud_defs[screen_state.hud_bg_id]
    assert(wp_bg.type == 'image_waypoint', 'Expected image_waypoint for waypoint mode')
    assert(wp_bg.world_pos.z == face_pos1.z, 'Expected waypoint world_pos to equal sign_face_pos')
    local wp_line = captured_hud_defs[screen_state.hud_line_ids[1]]
    assert(wp_line.type == 'waypoint', 'Expected waypoint for text line in waypoint mode')
    assert(not wp_line.name:find('\27'), 'Waypoint name must not contain escape sequences to prevent unescape_translate warnings')
end

-- 2. Overlay mode: position is centered at { x = 0.5, y = 0.50 }
waysigns.settings.display_mode = 'overlay'
waysigns.settings.overlay_pos_y = 0.50
waysigns.remove_all_huds(mock_screen_player)
captured_hud_defs = {}
screen_state.current_sign_pos = sign_pos_test
screen_state.current_sign_data = data_mailbox
screen_state.opacity = 1.0

waysigns.render_hud(mock_screen_player, screen_state)
local ov_bg = captured_hud_defs[screen_state.hud_bg_id]
assert(ov_bg.type == 'image', 'Expected image for overlay mode')
assert(ov_bg.position.x == 0.5 and ov_bg.position.y == 0.50, 'Expected overlay centered at {0.5, 0.50}, got {' .. ov_bg.position.x .. ', ' .. ov_bg.position.y .. '}')
print('PASS Test 18')

print('--- Test 19: Synchronized fade-out: ARGB text alpha, background retention, removal order ---')
waysigns.settings.display_mode = 'overlay'
waysigns.remove_all_huds(mock_screen_player)
captured_hud_defs = {}

-- 1. Setup sign and initiate fade-out
screen_state.current_sign_pos = sign_pos_test
screen_state.current_sign_data = data_mailbox
screen_state.opacity = 0.50
screen_state.target_opacity = 0.0 -- fading out!

waysigns.render_hud(mock_screen_player, screen_state)
local bg_during_fade = captured_hud_defs[screen_state.hud_bg_id]
local line_during_fade = captured_hud_defs[screen_state.hud_line_ids[1]]

-- Inspect background opacity byte: 0.5 ^ 0.6 = 0.6597 -> ~168/255
local bg_op_val = tonumber(bg_during_fade.text:match('%^%[opacity:(%d+)'))
assert(bg_op_val and bg_op_val > 150, 'Expected background to maintain higher opacity during fade out (expected >150, got ' .. tostring(bg_op_val) .. ')')

-- Inspect text color: clean 24-bit RGB color without high-byte overflow
local text_color_num = line_during_fade.number
assert(text_color_num > 0 and text_color_num <= 0xFFFFFF, 'Expected clean 24-bit RGB color, got ' .. tostring(text_color_num))
assert(bit.band(bit.rshift(text_color_num, 24), 0xFF) == 0, 'Expected no high alpha byte to prevent signed integer overflow, got ' .. tostring(text_color_num))

-- 2. Verify removal order in remove_all_huds (lines removed BEFORE background)
local hud_removal_sequence = {}
local orig_hud_remove = mock_screen_player.hud_remove
mock_screen_player.hud_remove = function(self, id)
    table.insert(hud_removal_sequence, id)
    orig_hud_remove(self, id)
end

local saved_bg_id = screen_state.hud_bg_id
local saved_line_id = screen_state.hud_line_ids[1]

waysigns.remove_all_huds(mock_screen_player)
mock_screen_player.hud_remove = orig_hud_remove

assert(#hud_removal_sequence >= 2, 'Expected at least 2 hud elements removed')
assert(hud_removal_sequence[1] == saved_line_id, 'Expected text line to be removed FIRST')
assert(hud_removal_sequence[#hud_removal_sequence] == saved_bg_id, 'Expected background to be removed LAST')
print('PASS Test 19')

print('--- Test 20: Smooth fade-in animation, ease-out quadratic easing & transition lifecycle ---')
-- 1. Mathematical verification of ease_out_quad
assert(waysigns.ease_out_quad(0.0) == 0.0, 'ease_out_quad(0.0) should be 0.0')
assert(waysigns.ease_out_quad(1.0) == 1.0, 'ease_out_quad(1.0) should be 1.0')
assert(waysigns.ease_out_quad(0.5) == 0.75, 'ease_out_quad(0.5) should be 0.75')
assert(waysigns.ease_out_quad(-0.5) == 0.0, 'ease_out_quad should clamp lower bound to 0.0')
assert(waysigns.ease_out_quad(1.5) == 1.0, 'ease_out_quad should clamp upper bound to 1.0')
-- Concave property: progress is faster at start, smoothly decelerating at end
assert(waysigns.ease_out_quad(0.2) > 0.2, 'Expected ease_out_quad(0.2) to be ahead of linear')
assert(waysigns.ease_out_quad(0.8) > 0.8, 'Expected ease_out_quad(0.8) to be ahead of linear')

-- 2. Mock environment for player raycast in update_player
mock_screen_player.get_pos = function() return vector.new(15, 1, 3) end
mock_screen_player.get_look_dir = function() return vector.new(0, 0, 1) end
mock_screen_player.get_properties = function() return { eye_height = 1.625 } end

core.get_node_or_nil = function(pos)
    if vector.equals(pos, pos_bs_green) then
        return { name = 'basic_signs:sign_wall_steel_green', param2 = 0 }
    end
    return nil
end

local raycast_hit_sign = false
core.raycast = function(...)
    if raycast_hit_sign then
        local first = true
        return function()
            if first then
                first = false
                return {
                    type = 'node',
                    under = pos_bs_green,
                    intersection_normal = vector.new(0, 0, 1),
                    intersection_point = { x = 15, y = 1, z = 5 },
                }
            end
            return nil
        end
    end
    return function() return nil end
end

-- Ensure clean starting state
waysigns.remove_all_huds(mock_screen_player)
waysigns.settings.fade_time = 0.3
waysigns.settings.check_interval = 0.05
screen_state.check_timer = 0

-- 3. Initial detection: Player looks at sign
raycast_hit_sign = true
-- First step: raycast triggers show_hud, initializing opacity at 0.0, then steps by dtime=0.1
waysigns.update_player(mock_screen_player, 0.1)
assert(screen_state.is_visible == true, 'Expected HUD to become visible')
assert(screen_state.target_opacity == 1.0, 'Expected target_opacity to be 1.0')
-- After dtime=0.1s with fade_time=0.3s: opacity should be 0.1 / 0.3 = ~0.3333
assert(math.abs(screen_state.opacity - (0.1 / 0.3)) < 0.01, 'Expected opacity ~0.3333, got ' .. screen_state.opacity)

-- Verify eased HUD attributes at step 1:
-- eased = 0.3333 * (2 - 0.3333) = 0.5555 -> opacity byte = math.floor(0.5555 * 255) = 141
local bg_step1 = captured_hud_defs[screen_state.hud_bg_id]
local line_step1 = captured_hud_defs[screen_state.hud_line_ids[1]]
local bg_op1 = tonumber(bg_step1.text:match('%^%[opacity:(%d+)'))
assert(bg_op1 and math.abs(bg_op1 - 141) <= 2, 'Expected background opacity around 141, got ' .. tostring(bg_op1))
assert(line_step1.number > 0 and line_step1.number <= 0xFFFFFF, 'Expected valid 24-bit RGB text color')
assert(bit.band(bit.rshift(line_step1.number, 24), 0xFF) == 0, 'Expected no high alpha byte')

-- Step 2: advance by another dtime=0.1s -> opacity = 0.2 / 0.3 = ~0.6667
waysigns.update_player(mock_screen_player, 0.1)
assert(math.abs(screen_state.opacity - (0.2 / 0.3)) < 0.01, 'Expected opacity ~0.6667, got ' .. screen_state.opacity)
-- eased = 0.6667 * (2 - 0.6667) = 0.8888 -> opacity byte = math.floor(0.8888 * 255) = 226
local bg_step2 = captured_hud_defs[screen_state.hud_bg_id]
local line_step2 = captured_hud_defs[screen_state.hud_line_ids[1]]
local bg_op2 = tonumber(bg_step2.text:match('%^%[opacity:(%d+)'))
assert(bg_op2 and math.abs(bg_op2 - 225) <= 4, 'Expected background opacity around 225, got ' .. tostring(bg_op2))
assert(line_step2.number > 0 and line_step2.number <= 0xFFFFFF, 'Expected valid 24-bit RGB text color')
assert(bit.band(bit.rshift(line_step2.number, 24), 0xFF) == 0, 'Expected no high alpha byte')

-- Step 3: advance by another dtime=0.1s -> opacity reaches 1.0
waysigns.update_player(mock_screen_player, 0.1)
assert(screen_state.opacity == 1.0, 'Expected opacity to reach solid 1.0')
local bg_step3 = captured_hud_defs[screen_state.hud_bg_id]
local line_step3 = captured_hud_defs[screen_state.hud_line_ids[1]]
local bg_op3 = tonumber(bg_step3.text:match('%^%[opacity:(%d+)'))
assert(bg_op3 == 255, 'Expected full 255 background opacity, got ' .. tostring(bg_op3))
assert(line_step3.number > 0 and line_step3.number <= 0xFFFFFF, 'Expected valid 24-bit RGB text color')
assert(bit.band(bit.rshift(line_step3.number, 24), 0xFF) == 0, 'Expected no high alpha byte')

-- 4. Player looks away, initiating fade-out
raycast_hit_sign = false
waysigns.update_player(mock_screen_player, 0.1)
assert(screen_state.target_opacity == 0.0, 'Expected target_opacity 0.0 after looking away')
assert(math.abs(screen_state.opacity - (0.2 / 0.3)) < 0.01, 'Expected opacity to decrease towards 0.6667, got ' .. screen_state.opacity)

-- 5. Mid-animation reversal: player quickly looks back at the same sign before fade-out finished
raycast_hit_sign = true
local prev_op = screen_state.opacity
waysigns.update_player(mock_screen_player, 0.05)
assert(screen_state.target_opacity == 1.0, 'Expected target_opacity to return to 1.0')
-- Opacity should have smoothly reversed and increased without dropping to zero!
assert(screen_state.opacity > prev_op, 'Expected opacity to climb up from previous value')
assert(screen_state.is_visible == true, 'HUD must stay continuously visible during reversal')
print('PASS Test 20')

print('--- Test 21: street_signs blade cropping & highway gantry aspects ---')
core.registered_nodes['street_signs:street_sign_bispot'] = {
    description = 'Intersection Street Blade',
    tiles = {'street_signs_basic.png'},
    drawtype = 'nodebox',
}
local pos_street = {x = 20, y = 1, z = 1, meta = {text = 'Elm St / 5th Ave'}}
local data_street = waysigns.get_sign_data(pos_street, {name = 'street_signs:street_sign_bispot', param2 = 0})
assert(data_street ~= nil, 'Expected street sign data')
assert(data_street.aspect_ratio == 3.2, 'Expected 3.2 aspect ratio for street blade')
assert(data_street.tile:find('%[combine:32x10:0,%-2='), 'Expected combine 32x10 crop for street blade, got ' .. data_street.tile)

core.registered_nodes['street_signs:sign_highway_2x1_blue'] = {
    description = '2x1 Blue Highway Sign',
    tiles = {'street_signs_generic_highway_2x1_blue.png'},
    drawtype = 'nodebox',
}
core.registered_nodes['street_signs:sign_highway_3x1_yellow'] = {
    description = '3x1 Yellow Highway Sign',
    tiles = {'street_signs_generic_highway_3x1_yellow.png'},
    drawtype = 'nodebox',
}
local pos_highway = {x = 21, y = 1, z = 1, meta = {text = 'Downtown Exit 12'}}
local data_highway = waysigns.get_sign_data(pos_highway, {name = 'street_signs:sign_highway_2x1_blue', param2 = 0})
assert(data_highway ~= nil, 'Expected highway gantry sign data')
assert(data_highway.aspect_ratio == 2.2, 'Expected 2.2 aspect ratio for 2x1 highway gantry')
assert(data_highway.text_color == 0xFFFFFF, 'Expected white text on blue highway sign')

local pos_highway_y = {x = 21, y = 2, z = 1, meta = {text = 'Downtown Exit 12'}}
local data_highway_y = waysigns.get_sign_data(pos_highway_y, {name = 'street_signs:sign_highway_3x1_yellow', param2 = 0})
assert(data_highway_y ~= nil, 'Expected yellow highway gantry sign data')
assert(data_highway_y.aspect_ratio == 2.5, 'Expected 2.5 aspect ratio for 3x1 highway sign')
assert(data_highway_y.text_color == 0x222222, 'Expected dark text on yellow highway sign')
print('PASS Test 21')

print('--- Test 22: display_modpack display_text & aspect ratios ---')
core.registered_nodes['boards:board_wall_black'] = {
    description = 'Black Notice Board',
    tiles = {'board_black_front.png'},
    drawtype = 'nodebox',
}
local pos_board = {x = 22, y = 1, z = 1, meta = {display_text = 'Town Hall Meeting Tonight'}}
local data_board = waysigns.get_sign_data(pos_board, {name = 'boards:board_wall_black', param2 = 0})
assert(data_board ~= nil, 'Expected board data')
assert(data_board.raw_text == 'Town Hall Meeting Tonight', 'Expected display_text extraction')
assert(data_board.aspect_ratio == 1.8, 'Expected 1.8 aspect ratio for notice board')
assert(data_board.tile == 'board_black_front.png', 'Expected board_black_front tile')

core.registered_nodes['steles:stele_wood'] = {
    description = 'Wooden Stele',
    tiles = {'default_sign_wall_wood.png'},
    drawtype = 'nodebox',
}
local pos_stele = {x = 23, y = 1, z = 1, meta = {display_text = 'Ancient Monolith'}}
local data_stele = waysigns.get_sign_data(pos_stele, {name = 'steles:stele_wood', param2 = 0})
assert(data_stele ~= nil, 'Expected stele data')
assert(data_stele.aspect_ratio == 0.7, 'Expected 0.7 tall vertical aspect ratio for stele')
print('PASS Test 22')

print('--- Test 23: signs_rx dynamic scale & color metadata ---')
local pos_rx_wide = {x = 24, y = 1, z = 1, meta = {text = 'Wide Trail Sign', scale = 'wide', color = 'teal'}}
local data_rx_wide = waysigns.get_sign_data(pos_rx_wide, {name = 'default:sign_wall_wood', param2 = 0})
assert(data_rx_wide ~= nil, 'Expected signs_rx wide data')
assert(data_rx_wide.aspect_ratio == 2.1, 'Expected 2.1 aspect ratio for scale=wide')
assert(data_rx_wide.tile:find('%^%[colorize:#005533:140'), 'Expected teal colorize tint on tile')

local pos_rx_tall = {x = 25, y = 1, z = 1, meta = {text = 'Tall Pillar Sign', scale = 'tall', color = 'maroon'}}
local data_rx_tall = waysigns.get_sign_data(pos_rx_tall, {name = 'default:sign_wall_wood', param2 = 0})
assert(data_rx_tall ~= nil, 'Expected signs_rx tall data')
assert(data_rx_tall.aspect_ratio == 1.0, 'Expected 1.0 aspect ratio for scale=tall')
assert(data_rx_tall.tile:find('%^%[colorize:#550033:140'), 'Expected maroon colorize tint on tile')
print('PASS Test 23')

print('--- Test 24: breadcrumbs, locks, mcl_signs & edge case fallbacks ---')
-- breadcrumbs label extraction
core.registered_nodes['breadcrumbs:marker'] = {
    description = 'Cave Marker',
    tiles = {'breadcrumbs_wall.png^breadcrumbs_text.png'},
    drawtype = 'signlike',
}
local pos_bc = {x = 26, y = 1, z = 1, meta = {label = 'Shaft B -> Diamond Mine'}}
local data_bc = waysigns.get_sign_data(pos_bc, {name = 'breadcrumbs:marker', param2 = 0})
assert(data_bc ~= nil, 'Expected breadcrumbs data')
assert(data_bc.raw_text == 'Shaft B -> Diamond Mine', 'Expected label extraction for breadcrumbs')
assert(data_bc.aspect_ratio == 1.0, 'Expected 1.0 aspect ratio for cave marker')

-- locks composite texture cleanup
core.registered_nodes['locks:shared_locked_sign_wall'] = {
    description = 'Locked Sign Wall',
    tiles = {'locks_lock16.png^default_sign_wood.png'},
    drawtype = 'nodebox',
}
local pos_lock = {x = 27, y = 1, z = 1, meta = {text = 'Vault: Authorized Only'}}
local data_lock = waysigns.get_sign_data(pos_lock, {name = 'locks:shared_locked_sign_wall', param2 = 0})
assert(data_lock ~= nil, 'Expected locks sign data')
assert(not data_lock.tile:find('locks_lock16'), 'Lock overlay icon must be stripped, got: ' .. data_lock.tile)
assert(data_lock.tile == waysigns.FALLBACK_WOOD or data_lock.tile:find('sign_.*wood'), 'Base wood tile must be extracted, got: ' .. data_lock.tile)

-- mcl_signs multiline text1..4
core.registered_nodes['mcl_signs:wall_sign_crimson'] = {
    description = 'Crimson Wall Sign',
    tiles = {'mcl_core_planks_crimson.png'},
    drawtype = 'nodebox',
}
local pos_mcl = {x = 28, y = 1, z = 1, meta = {
    text1 = 'Nether Portal',
    text2 = 'Fortress North',
    text3 = 'Keep Weapons Ready',
    text4 = 'Danger!'
}}
local data_mcl = waysigns.get_sign_data(pos_mcl, {name = 'mcl_signs:wall_sign_crimson', param2 = 0})
assert(data_mcl ~= nil, 'Expected mcl_signs data')
assert(data_mcl.raw_text:find('Nether Portal\nFortress North\nKeep Weapons Ready\nDanger!'), 'Expected multiline text1..4 extraction')
assert(data_mcl.tile == 'mcl_core_planks_crimson.png', 'Expected crimson plank texture')

-- Multi-tile scanning: choose sign face over mounting sticks
core.registered_nodes['custom:pole_and_sign'] = {
    description = 'Sign with Pole and Edge',
    tiles = {
        'default_steel_block.png',       -- face 1: mounting pole
        'custom_oak_sign_front.png',     -- face 2: actual sign face
        'custom_oak_sign_edges.png',     -- face 3: edge border
    },
    drawtype = 'nodebox',
    groups = {sign = 1},
}
local pos_pole = {x = 29, y = 1, z = 1, meta = {text = 'Multi-face Test'}}
local data_pole = waysigns.get_sign_data(pos_pole, {name = 'custom:pole_and_sign', param2 = 0})
assert(data_pole ~= nil, 'Expected data for multi-face sign')
assert(data_pole.tile == 'custom_oak_sign_front.png', 'Expected custom_oak_sign_front chosen over pole/edges, got: ' .. data_pole.tile)

-- Edge cases & Fallback handling
local bg_nil = waysigns.get_background_texture(nil, 200, 80, 1.0, false)
assert(bg_nil:find(waysigns.FALLBACK_WOOD), 'Expected wood fallback for nil tile')

local bg_steel_nil = waysigns.get_background_texture('', 200, 80, 1.0, true)
assert(bg_steel_nil:find(waysigns.FALLBACK_STEEL), 'Expected steel fallback for empty tile')

local bg_cube = waysigns.get_background_texture('[inventorycube{stone.png{stone.png{stone.png', 200, 80, 1.0, false)
assert(bg_cube:find(waysigns.FALLBACK_WOOD), 'Expected fallback for [inventorycube')

local bg_anim = waysigns.get_background_texture('animated.png^[verticalframe:16:0', 200, 80, 1.0, true)
assert(bg_anim:find('animated.png') and bg_anim:find('%[verticalframe:16:0'), 'Expected verticalframe frame 0 preserved in background texture, got: ' .. bg_anim)

local bg_unbalanced = waysigns.get_background_texture('((unclosed.png', 200, 80, 1.0, false)
assert(bg_unbalanced:find(waysigns.FALLBACK_WOOD), 'Expected fallback for unbalanced parentheses')

-- Dimension clamping in get_background_texture
local bg_neg = waysigns.get_background_texture('default_sign_wall_wood.png', -50, 0, 1.5, false)
assert(bg_neg:find('%[resize:48x24'), 'Expected clamped minimum dimensions 48x24, got ' .. bg_neg)

-- Screen fitting in render_hud: on an 800x600 compact screen, max board dimensions are clamped
local compact_player = {
    get_player_name = function() return 'CompactPlayer' end,
    hud_add = function() return 1 end,
    hud_change = function() end,
    hud_remove = function() end,
}
core.get_player_window_information = function()
    return { size = { x = 800, y = 600 } }
end
local compact_state = waysigns.get_or_create_player_state(compact_player)
compact_state.current_sign_data = data_mcl
compact_state.current_sign_pos = pos_mcl
compact_state.opacity = 1.0
compact_state.target_opacity = 1.0
waysigns.render_hud(compact_player, compact_state)
-- Check cached texture dimensions created during render_hud
local last_tex = waysigns.texture_cache[compact_state.current_sign_data.tile .. '_'] or ''
for k, _ in pairs(waysigns.texture_cache) do
    if k:find('mcl_core_planks_crimson') then
        last_tex = k
        break
    end
end
local fitted_w, fitted_h = last_tex:match('_(%d+)x(%d+)_')
assert(fitted_w and tonumber(fitted_w) <= 680, 'Board width must fit within 85% of screen (<=680), got: ' .. tostring(fitted_w))
assert(fitted_h and tonumber(fitted_h) <= 420, 'Board height must fit within 70% of screen (<=420), got: ' .. tostring(fitted_h))
print('PASS Test 24')

print('--- Test 25: Universal entity suppression across all 8 entity types ---')
local orig_get_objs_t25 = core.get_objects_inside_radius
local entities_purged = {}
local mock_ent_obj = function(ename)
    return {
        is_player = function() return false end,
        get_luaentity = function() return { name = ename } end,
        remove = function() table.insert(entities_purged, ename) end,
    }
end

local all_suppressed_types = {
    'signs_lib:text',
    'mcl_signs:text',
    'rp_signs:sign_text',
    'signs:display_text',
    'boards:display_text',
    'steles:display_text',
    'ucsigns:text',
    'jp_signs:text_entity',
}

core.get_objects_inside_radius = function(pos, r)
    local objs = {}
    for _, t in ipairs(all_suppressed_types) do
        table.insert(objs, mock_ent_obj(t))
    end
    -- Also include innocent player entity that must NOT be removed
    table.insert(objs, {
        is_player = function() return false end,
        get_luaentity = function() return { name = 'mobs_animal:cow' } end,
        remove = function() error('Must not remove innocent entity!') end,
    })
    return objs
end

waysigns.purge_sign_entities({x = 50, y = 1, z = 50})
assert(#entities_purged == 8, 'Expected all 8 sign text entities purged, got: ' .. #entities_purged)

-- Verify display_api.update_entities hook is neutralized
_G.display_api = {
    update_entities = function() error('Original display_api should have been hooked!') end
}
-- Re-run suppression to hook mock display_api
if waysigns.settings.disable_sign_entities then
    local dapi = rawget(_G, 'display_api')
    if dapi and dapi.update_entities then
        rawset(dapi, 'update_entities', function(pos)
            waysigns.purge_sign_entities(pos)
        end)
    end
end
entities_purged = {}
_G.display_api.update_entities({x = 50, y = 1, z = 50})
assert(#entities_purged == 8, 'display_api hook must trigger purge_sign_entities')
core.get_objects_inside_radius = orig_get_objs_t25
print('PASS Test 25')

print('--- Test 26: Auto-contrast, luminance calculation, and light backgrounds ---')
-- 1. Luminance calculation
assert(math.abs(waysigns.get_luminance(0x000000) - 0.0) < 0.01, 'Black luminance must be ~0.0')
assert(math.abs(waysigns.get_luminance(0xFFFFFF) - 1.0) < 0.01, 'White luminance must be ~1.0')
local lum_charcoal = waysigns.get_luminance(0x222222)
assert(lum_charcoal > 0.10 and lum_charcoal < 0.20, 'Charcoal luminance must be ~0.13')

-- 2. Light background detection
assert(waysigns.is_light_background('street_signs_warning.png') == true, 'Warning sign must be detected as light')
assert(waysigns.is_light_background('signs_poster.png') == true, 'Paper poster must be detected as light')
assert(waysigns.is_light_background('basic_signs_sign_wall_plastic.png') == true, 'Plastic sign must be detected as light')
assert(waysigns.is_light_background('default_sign_wall_wood.png') == false, 'Wood sign must not be light background')
assert(waysigns.is_light_background('default_sign_wall_steel.png') == false, 'Steel sign must not be light background')
assert(waysigns.is_light_background(waysigns.FALLBACK_WOOD) == false, 'Waysigns wood fallback must not be light background')
assert(waysigns.is_light_background(waysigns.FALLBACK_STEEL) == false, 'Waysigns steel fallback must not be light background')

-- 3. Adaptive contrast in 'auto' mode
waysigns.settings.contrast_mode = 'auto'
-- On dark wood: dark text (0x222222) should be boosted to bright white (0xFFFFFF)
local c_wood_dark = waysigns.get_contrast_color(0x222222, false)
assert(c_wood_dark == 0xFFFFFF, 'Dark text on dark background must become 0xFFFFFF')
-- On dark wood: bright red (#c 0xFF5555) should be preserved
local c_wood_red = waysigns.get_contrast_color(0xFF5555, false)
assert(c_wood_red == 0xFF5555, 'Bright red text on dark background should be preserved')

-- On yellow warning sign: dark text (0x222222) should remain dark (0x222222)
local c_warn_dark = waysigns.get_contrast_color(0x222222, true)
assert(c_warn_dark == 0x222222, 'Dark text on light background must stay dark')
-- On yellow warning sign: white text (0xFFFFFF) should become dark charcoal (0x111111) for readability
local c_warn_white = waysigns.get_contrast_color(0xFFFFFF, true)
assert(c_warn_white == 0x111111, 'White text on light background must become dark charcoal (0x111111)')

-- 4. Light background textures should not have dark colorize tint
local warn_tex = waysigns.get_background_texture('street_signs_warning.png', 240, 100, 1.0, true, true)
assert(not warn_tex:find('%[colorize:'), 'Naturally light background should not have colorize glaze')

-- 5. Full render_hud auto-contrast verification
local mock_p = {
    hud_adds = {},
    hud_changes = {},
    hud_removes = {},
    get_player_name = function() return 'contrast_tester' end,
    hud_add = function(self, def)
        table.insert(self.hud_adds, def)
        return #self.hud_adds
    end,
    hud_change = function(self, id, field, val)
        table.insert(self.hud_changes, {id = id, field = field, val = val})
    end,
    hud_remove = function(self, id)
        table.insert(self.hud_removes, id)
    end,
    get_look_pitch = function() return 0 end,
    get_look_yaw = function() return 0 end,
    get_pos = function() return {x = 0, y = 0, z = 0} end,
    get_eye_offset = function() return {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0} end,
    get_fov = function() return 0 end,
    get_window_info = function() return {real_gui_scaling = 1.0, size = {x = 1920, y = 1080}} end,
}
local p_state = waysigns.get_or_create_player_state(mock_p)
p_state.opacity = 1.0
p_state.target_opacity = 1.0
p_state.current_sign_pos = {x = 0, y = 1, z = 2}
p_state.sign_face_pos = {x = 0, y = 1, z = 2}
p_state.current_sign_data = {
    tile = 'default_sign_wall_wood.png',
    text = 'Dark Text on Wood',
    is_metal = false,
    is_light_bg = false,
    text_color = 0x222222, -- black text from signs_lib
    wrapped = {
        pages = {
            { { text = 'Dark Text on Wood', color = 0x222222 } }
        },
        total_lines = 1,
        max_line_len = 17,
    }
}
waysigns.render_hud(mock_p, p_state, 0.05)
local contrast_elem = mock_p.hud_adds[2]
assert(contrast_elem ~= nil, 'Expected HUD text element created')
local r_byte = bit.band(bit.rshift(contrast_elem.number, 16), 0xFF)
local g_byte = bit.band(bit.rshift(contrast_elem.number, 8), 0xFF)
local b_byte = bit.band(contrast_elem.number, 0xFF)
assert(r_byte == 255 and g_byte == 255 and b_byte == 255, 'Text color on dark wood must be boosted to white 255,255,255. Got: ' .. r_byte .. ',' .. g_byte .. ',' .. b_byte)
print('PASS Test 26')

print('--- Test 27: street_signs warning, service, detour & 3D mesh fallbacks ---')
core.registered_nodes['street_signs:sign_warning_3_line'] = {
    description = 'Warning Sign 3 Lines',
    tiles = {'street_signs_warning.png'},
    drawtype = 'nodebox',
}
local pos_warn = {x = 27, y = 1, z = 1, meta = {text = 'SHARP CURVE\nAHEAD'}}
local data_warn = waysigns.get_sign_data(pos_warn, {name = 'street_signs:sign_warning_3_line', param2 = 0})
assert(data_warn ~= nil, 'Expected warning sign data')
assert(data_warn.tile:find('%^%[sheet:2x1:0,0'), 'Warning sign must be cropped with sheet:2x1:0,0, got ' .. data_warn.tile)

core.registered_nodes['street_signs:sign_divided_highway_with_cross_road'] = {
    description = 'Divided Highway With Cross Road',
    tiles = {'street_signs_divided_highway_with_cross_road.png'},
    drawtype = 'nodebox',
}
local pos_cross = {x = 27, y = 2, z = 1, meta = {text = 'CROSS ROAD'}}
local data_cross = waysigns.get_sign_data(pos_cross, {name = 'street_signs:sign_divided_highway_with_cross_road', param2 = 0})
assert(data_cross ~= nil, 'Expected cross road sign data')
assert(data_cross.tile:find('%[combine:256x256:0,0='), 'Divided highway cross road must be cropped with combine:256x256:0,0=, got ' .. data_cross.tile)

-- Service sign 2x1 crop (hospital, fuel, food, lodging)
core.registered_nodes['street_signs:sign_service_hospital'] = {
    description = 'Hospital Sign',
    tiles = {'street_signs_service_hospital.png'},
    drawtype = 'nodebox',
}
local pos_hosp = {x = 27, y = 3, z = 1, meta = {text = 'Hospital Emergency'}}
local data_hosp = waysigns.get_sign_data(pos_hosp, {name = 'street_signs:sign_service_hospital', param2 = 0})
assert(data_hosp ~= nil, 'Expected hospital sign data')
assert(data_hosp.tile:find('%^%[sheet:2x1:0,0'), 'Hospital service sign must be sliced with sheet:2x1:0,0 to avoid tiled backing, got: ' .. data_hosp.tile)
assert(data_hosp.aspect_ratio == 1.0, 'Service signs must have square 1.0 aspect ratio')

-- Detour sign 1x2 crop
core.registered_nodes['street_signs:sign_detour_right_m4_10'] = {
    description = 'Detour Right',
    tiles = {'street_signs_detour_right_m4_10.png'},
    drawtype = 'nodebox',
}
local pos_detour = {x = 27, y = 4, z = 1, meta = {text = 'DETOUR'}}
local data_detour = waysigns.get_sign_data(pos_detour, {name = 'street_signs:sign_detour_right_m4_10', param2 = 0})
assert(data_detour ~= nil, 'Expected detour sign data')
assert(data_detour.tile:find('%^%[sheet:1x2:0,0'), 'Detour sign must be sliced with sheet:1x2:0,0 to avoid vertical tiled backing, got: ' .. data_detour.tile)
assert(data_detour.aspect_ratio == 2.67, 'Detour sign must have aspect ratio 2.67')

-- 3D Mesh signs fallback (US route, interstate shields, ucsigns)
core.registered_nodes['street_signs:sign_us_interstate'] = {
    description = 'US Interstate Sign',
    tiles = {'street_signs_us_interstate.png'},
    drawtype = 'mesh',
}
local pos_interstate = {x = 27, y = 5, z = 1, meta = {text = 'I-95 North'}}
local data_interstate = waysigns.get_sign_data(pos_interstate, {name = 'street_signs:sign_us_interstate', param2 = 0})
assert(data_interstate ~= nil, 'Expected interstate sign data')
assert(data_interstate.tile == waysigns.FALLBACK_STEEL, 'Interstate mesh sign must fall back to clean steel plaque! Got: ' .. data_interstate.tile)
assert(data_interstate.aspect_ratio == 1.0, 'Interstate sign must have square 1.0 aspect ratio')

core.registered_nodes['ucsigns:wall_sign_wood'] = {
    description = 'UC Wooden Wall Sign',
    tiles = {'ucsigns_wood.png'},
    drawtype = 'mesh',
}
local pos_uc = {x = 27, y = 6, z = 1, meta = {text = 'Village Library'}}
local data_uc = waysigns.get_sign_data(pos_uc, {name = 'ucsigns:wall_sign_wood', param2 = 0})
assert(data_uc ~= nil, 'Expected ucsigns data')
assert(data_uc.tile == waysigns.FALLBACK_WOOD, 'ucsigns 3D mesh sign must fall back to clean wood plaque! Got: ' .. data_uc.tile)
print('PASS Test 27')

print('--- Test 28: display_modpack wooden direction arrow sign cropping ---')
core.registered_nodes['signs:wooden_left_sign'] = {
    description = 'Left Wooden Sign',
    tiles = {'signs_wooden_direction.png'},
    drawtype = 'nodebox',
}
core.registered_nodes['signs:wooden_right_sign'] = {
    description = 'Right Wooden Sign',
    tiles = {'signs_wooden_direction.png'},
    drawtype = 'nodebox',
}
local pos_dir_l = {x = 28, y = 1, z = 1, meta = {text = 'Campground'}}
local data_dir_l = waysigns.get_sign_data(pos_dir_l, {name = 'signs:wooden_left_sign', param2 = 0})
assert(data_dir_l ~= nil, 'Expected left wooden sign data')
assert(data_dir_l.tile:find('%^%[sheet:1x2:0,0'), 'Direction sign must be cropped with sheet:1x2:0,0, got ' .. data_dir_l.tile)
local data_dir_r = waysigns.get_sign_data(pos_dir_l, {name = 'signs:wooden_right_sign', param2 = 0})
assert(data_dir_r.tile:find('%^%[sheet:1x2:0,0'), 'Right direction sign must also be cropped with sheet:1x2:0,0, got ' .. data_dir_r.tile)
print('PASS Test 28')

print('--- Test 29: hiking signs high-contrast trail plaques ---')
core.registered_nodes['hiking:signred'] = {
    description = 'Hiking Sign Red',
    tiles = {'hiking_white.png'},
    drawtype = 'nodebox',
}
core.registered_nodes['hiking:sign_leftgreen'] = {
    description = 'Hiking Sign Left Green',
    tiles = {'hiking_white.png'},
    drawtype = 'nodebox',
}
core.registered_nodes['hiking:signyellow'] = {
    description = 'Hiking Sign Yellow',
    tiles = {'hiking_white.png'},
    drawtype = 'nodebox',
}
core.registered_nodes['hiking:pole_signblue'] = {
    description = 'Hiking Pole Sign Blue',
    tiles = {'hiking_white.png'},
    drawtype = 'nodebox',
}
local pos_hike = {x = 29, y = 1, z = 1, meta = {text = 'Ridge Trail\nElev. 2400m'}}
local data_hike_red = waysigns.get_sign_data(pos_hike, {name = 'hiking:signred', param2 = 0})
assert(data_hike_red ~= nil, 'Expected hiking sign data')
assert(data_hike_red.tile:find(waysigns.FALLBACK_WOOD .. '%^%[colorize:#991111:40'), 'Hiking red sign must use clean color-glazed wood plaque, got: ' .. data_hike_red.tile)
assert(data_hike_red.text_color == 0xFFFFFF, 'Hiking red sign must have crisp white text')
assert(data_hike_red.aspect_ratio == 1.4, 'Hiking rectangle sign must have 1.4 aspect ratio')

local data_hike_left = waysigns.get_sign_data(pos_hike, {name = 'hiking:sign_leftgreen', param2 = 0})
assert(data_hike_left.aspect_ratio == 2.2, 'Hiking left arrow must have aspect ratio 2.2')
assert(data_hike_left.tile:find(waysigns.FALLBACK_WOOD .. '%^%[colorize:#117722:40'), 'Hiking green arrow must use green glazed wood plaque')

local data_hike_yellow = waysigns.get_sign_data(pos_hike, {name = 'hiking:signyellow', param2 = 0})
assert(data_hike_yellow.text_color == 0x111111, 'Hiking yellow sign must use dark charcoal text for high contrast')
assert(data_hike_yellow.is_light_bg == true, 'Hiking yellow sign must be flagged as light background')

local data_hike_pole = waysigns.get_sign_data(pos_hike, {name = 'hiking:pole_signblue', param2 = 0})
assert(data_hike_pole.is_metal == true, 'Hiking pole sign must be metal')
assert(data_hike_pole.tile:find(waysigns.FALLBACK_STEEL .. '%^%[sheet:2x1:0,0%^%[colorize:#113399:35'), 'Hiking pole sign must use steel sliced plaque')
print('PASS Test 29')

print('--- Test 30: glass signs dynamic frosted backing ---')
-- Dark text on glass sign: gets milky white frosted backing
local glass_bg_dark = waysigns.get_background_texture('basic_signs_sign_wall_glass.png^[sheet:2x1:0,0', 280, 100, 1.0, false, true, true)
assert(glass_bg_dark:find('%[fill:280x100:#f4f8fcf8'), 'Glass sign with dark text must have milky pearl frosted fill backing layer, got: ' .. glass_bg_dark)
assert(glass_bg_dark:find('basic_signs_sign_wall_glass.png', 1, true), 'Glass sign background must layer original glass tile over fill, got: ' .. glass_bg_dark)
assert(glass_bg_dark:find('%[opacity:40'), 'Glass gloss sheen must be subdued with opacity:40, got: ' .. glass_bg_dark)

-- Bright text on glass sign: gets obsidian dark frosted backing
local glass_bg_light = waysigns.get_background_texture('basic_signs_sign_wall_glass.png^[sheet:2x1:0,0', 280, 100, 1.0, false, false, false)
assert(glass_bg_light:find('%[fill:280x100:#080c16f8'), 'Glass sign with bright text must have obsidian dark frosted fill backing layer, got: ' .. glass_bg_light)

-- Standard wood sign must not have fill
local wood_bg = waysigns.get_background_texture('default_sign_wall_wood.png', 280, 100, 1.0, false)
assert(not wood_bg:find('%[fill:'), 'Standard wood sign must NOT have frosted fill')
print('PASS Test 30')

print('--- Test 31: showroom param2 orientation verification ---')
-- Simulate get_param2
local function sim_get_param2(nodename, face_dir, is_wall)
    local def = core.registered_nodes[nodename]
    if not def then return 0 end
    local is_facing_east = (face_dir.x > 0)
    if def.paramtype2 == "wallmounted" then
        if is_wall then
            return is_facing_east and 3 or 2
        else
            return 1
        end
    elseif def.paramtype2 == "facedir" then
        return is_facing_east and 3 or 1
    end
    return 0
end

core.registered_nodes['test:wall_node'] = {paramtype2 = 'wallmounted'}
core.registered_nodes['test:facedir_node'] = {paramtype2 = 'facedir'}

local dir_facing_east = {x = 1, y = 0, z = 0}
local dir_facing_west = {x = -1, y = 0, z = 0}

-- West wall exhibit (faces East):
assert(sim_get_param2('test:wall_node', dir_facing_east, true) == 3, 'West wallmounted must be param2=3')
assert(sim_get_param2('test:facedir_node', dir_facing_east, true) == 3, 'West facedir must be param2=3')

-- East wall exhibit (faces West):
assert(sim_get_param2('test:wall_node', dir_facing_west, true) == 2, 'East wallmounted must be param2=2')
assert(sim_get_param2('test:facedir_node', dir_facing_west, true) == 1, 'East facedir must be param2=1')

-- Floor mounted exhibit:
assert(sim_get_param2('test:wall_node', dir_facing_east, false) == 1, 'Floor wallmounted must be param2=1')
print('PASS Test 31')

print('--- Test 32: WCAG AAA dynamic contrast ratio verification & render_hud glass adaptation ---')
local function get_contrast_ratio(lum1, lum2)
    local l1 = math.max(lum1, lum2)
    local l2 = math.min(lum1, lum2)
    return (l1 + 0.05) / (l2 + 0.05)
end

-- 1. Dark charcoal text (0x111111) on milky white backing (L = 0.94)
local lum_white_bg = 0.94
local lum_charcoal_text = waysigns.get_luminance(0x111111)
local ratio_white_bg = get_contrast_ratio(lum_white_bg, lum_charcoal_text)
assert(ratio_white_bg >= 7.0, 'Dark text on milky frosted backing must achieve WCAG AAA contrast (>= 7.0:1), got: ' .. ratio_white_bg)

-- 2. Crisp white text (0xFFFFFF) on obsidian backing (L = 0.02)
local lum_obsidian_bg = 0.02
local lum_white_text = waysigns.get_luminance(0xFFFFFF)
local ratio_dark_bg = get_contrast_ratio(lum_obsidian_bg, lum_white_text)
assert(ratio_dark_bg >= 7.0, 'White text on obsidian frosted backing must achieve WCAG AAA contrast (>= 7.0:1), got: ' .. ratio_dark_bg)

-- 3. In-engine render_hud dynamic backing test on glass sign with dark text
core.registered_nodes['basic_signs:sign_glass_yard'] = {
    description = 'Glass Yard Sign',
    tiles = {'basic_signs_sign_wall_glass.png'},
    drawtype = 'nodebox',
}
local mock_glass_p = {
    hud_adds = {},
    hud_changes = {},
    hud_removes = {},
    get_player_name = function() return 'glass_tester' end,
    hud_add = function(self, def)
        table.insert(self.hud_adds, def)
        return #self.hud_adds
    end,
    hud_change = function(self, id, field, val)
        table.insert(self.hud_changes, {id = id, field = field, val = val})
    end,
    hud_remove = function(self, id)
        table.insert(self.hud_removes, id)
    end,
    get_look_pitch = function() return 0 end,
    get_look_yaw = function() return 0 end,
    get_pos = function() return {x = 0, y = 0, z = 0} end,
    get_eye_offset = function() return {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0} end,
    get_fov = function() return 0 end,
    get_window_info = function() return {real_gui_scaling = 1.0, size = {x = 1920, y = 1080}} end,
}
local glass_state = waysigns.get_or_create_player_state(mock_glass_p)
glass_state.opacity = 1.0
glass_state.target_opacity = 1.0
glass_state.current_sign_pos = {x = 5, y = 1, z = 5}
glass_state.sign_face_pos = {x = 5, y = 1, z = 5}
glass_state.current_sign_node = {name = 'basic_signs:sign_glass_yard'}
glass_state.current_sign_data = {
    tile = 'basic_signs_sign_wall_glass.png',
    text = 'Quiet Zone\nLibrary Ahead',
    is_metal = false,
    text_color = 0x111111, -- dark text
    wrapped = {
        pages = {
            { { text = 'Quiet Zone', color = 0x111111 }, { text = 'Library Ahead', color = 0x111111 } }
        },
        total_lines = 2,
        max_line_len = 13,
    }
}
waysigns.render_hud(mock_glass_p, glass_state, 0.05)
local glass_hud_bg = mock_glass_p.hud_adds[1]
assert(glass_hud_bg ~= nil, 'Expected glass HUD bg element')
assert(glass_hud_bg.text:find('%[fill:.*:#f4f8fcf8'), 'Glass sign with dark text must render with milky white frosted backing, got: ' .. glass_hud_bg.text)

-- 4. In-engine render_hud on glass sign with white text
waysigns.remove_all_huds(mock_glass_p)
mock_glass_p.hud_adds = {}
glass_state.current_sign_data = {
    tile = 'basic_signs_sign_wall_glass.png',
    text = 'White Text on Glass',
    is_metal = false,
    text_color = 0xFFFFFF, -- white text
    wrapped = {
        pages = {
            { { text = 'White Text on Glass', color = 0xFFFFFF } }
        },
        total_lines = 1,
        max_line_len = 19,
    }
}
waysigns.render_hud(mock_glass_p, glass_state, 0.05)
local glass_hud_bg2 = mock_glass_p.hud_adds[1]
assert(glass_hud_bg2 ~= nil, 'Expected glass HUD bg element')
assert(glass_hud_bg2.text:find('%[fill:.*:#080c16f8'), 'Glass sign with white text must render with obsidian dark frosted backing, got: ' .. glass_hud_bg2.text)
print('PASS Test 32')

-- =========================================================================
-- Test 33: extract_text ignores empty and placeholder text (e.g. '(Empty)')
-- =========================================================================
print('--- Test 33: extract_text ignores empty and placeholder text ---')
local mock_meta_rx = {
    get_string = function(self, key)
        return self._fields[key] or ''
    end,
    _fields = {}
}

-- 1. signs_rx "(Empty)" default message
mock_meta_rx._fields = { text = '(Empty)', infotext = '"(Empty)"' }
assert(waysigns.extract_text(mock_meta_rx) == nil, 'Expected nil for (Empty) text')

-- 2. Lowercase "(empty)"
mock_meta_rx._fields = { text = '(empty)', infotext = '' }
assert(waysigns.extract_text(mock_meta_rx) == nil, 'Expected nil for (empty) text')

-- 3. Bare "Empty"
mock_meta_rx._fields = { text = 'Empty', infotext = '' }
assert(waysigns.extract_text(mock_meta_rx) == nil, 'Expected nil for Empty text')

-- 4. Whitespace only
mock_meta_rx._fields = { text = '   \n  \t  ', infotext = '' }
assert(waysigns.extract_text(mock_meta_rx) == nil, 'Expected nil for whitespace text')

-- 5. Multi-line sign fields with only empty/placeholder
mock_meta_rx._fields = { text1 = '(Empty)', text2 = '', text3 = '', text4 = '' }
assert(waysigns.extract_text(mock_meta_rx) == nil, 'Expected nil for multi-line (Empty)')

-- 6. Valid text preserved
mock_meta_rx._fields = { text = 'Town Hall\nKeep Left' }
assert(waysigns.extract_text(mock_meta_rx) == 'Town Hall\nKeep Left', 'Expected valid text preserved')

print('PASS Test 33')

-- =========================================================================
-- Test 34: ucsigns wood variants, generic 3D mesh fallbacks, and wooden contrast
-- =========================================================================
print('--- Test 34: ucsigns wood variants, generic 3D mesh fallbacks, and wooden contrast ---')

-- 1. ucsigns acacia wall sign -> acacia tinted clean wood plaque
core.registered_nodes['ucsigns:wall_sign_acacia'] = {
    description = 'Acacia Wood Sign',
    drawtype = 'mesh',
    mesh = 'mcl_signs_signonwallmount.obj',
    tiles = {'mcl_signs_sign_greyscale.png^default_acacia_wood.png'},
    groups = {ucsign = 1, choppy = 1},
}
local pos_acacia = {x = 30, y = 1, z = 1, meta = {text = 'Savanna Outpost'}}
local data_acacia = waysigns.get_sign_data(pos_acacia, {name = 'ucsigns:wall_sign_acacia', param2 = 0})
assert(data_acacia ~= nil, 'Expected ucsigns acacia sign data')
assert(data_acacia.tile:find(waysigns.FALLBACK_WOOD .. '%^%[colorize:#a03818:50'), 'ucsigns acacia sign must use acacia tinted clean wood plaque! Got: ' .. data_acacia.tile)
assert(data_acacia.aspect_ratio == 1.4, 'ucsigns sign must have 1.4 aspect ratio')

-- 2. ucsigns pine standing sign -> dark pine tinted clean wood plaque
core.registered_nodes['ucsigns:standing_sign_pine'] = {
    description = 'Pine Wood Sign',
    drawtype = 'mesh',
    mesh = 'mcl_signs_sign.obj',
    tiles = {'mcl_signs_sign_greyscale.png^default_pine_wood.png'},
    groups = {ucsign = 1, choppy = 1},
}
local pos_pine = {x = 30, y = 1, z = 2, meta = {text = 'Taiga Trail'}}
local data_pine = waysigns.get_sign_data(pos_pine, {name = 'ucsigns:standing_sign_pine', param2 = 0})
assert(data_pine ~= nil, 'Expected ucsigns pine sign data')
assert(data_pine.tile:find(waysigns.FALLBACK_WOOD .. '%^%[colorize:#22150a:70'), 'ucsigns pine sign must use dark pine tinted clean wood plaque! Got: ' .. data_pine.tile)

-- 3. Generic 3D mesh node fallback (not pre-registered)
core.registered_nodes['mymod:mesh_board_oak'] = {
    description = 'Oak Mesh Board',
    drawtype = 'mesh',
    mesh = 'custom_mesh_board.obj',
    tiles = {'custom_mesh_uv_map.png'},
    groups = {sign = 1, wood = 1},
}
local pos_mesh_board = {x = 30, y = 1, z = 3, meta = {text = 'Custom Mesh Notice'}}
local data_mesh_board = waysigns.get_sign_data(pos_mesh_board, {name = 'mymod:mesh_board_oak', param2 = 0})
assert(data_mesh_board ~= nil, 'Expected custom mesh board sign data')
assert(data_mesh_board.tile == waysigns.FALLBACK_WOOD, 'Generic wood mesh sign must fall back to clean wood plaque! Got: ' .. data_mesh_board.tile)

-- 4. Deep contrast glaze on wooden signs
local wood_bg_glazed = waysigns.get_background_texture('default_sign_wall_wood.png', 280, 100, 1.0, false, false, false)
assert(wood_bg_glazed:find('%[colorize:#060402:160'), 'Wood sign background must receive deep contrast glaze (#060402:160), got: ' .. wood_bg_glazed)

-- 5. Text luminance boost on wood background: dark/muted colors (lum < 0.50) boosted to white
local muted_grey = 0x555555 -- luminance ~ 0.33
local boosted = waysigns.get_contrast_color(muted_grey, false)
assert(boosted == 0xFFFFFF, 'Muted text on dark/wood background must be boosted to white, got: ' .. string.format('0x%06X', boosted))

-- 6. Light background: bright colors (lum > 0.50) darkened to charcoal
local bright_yellow = 0xFFFF55 -- luminance ~ 0.93
local darkened = waysigns.get_contrast_color(bright_yellow, true)
assert(darkened == 0x111111, 'Bright text on light background must be darkened to 0x111111, got: ' .. string.format('0x%06X', darkened))

print('PASS Test 34')

print('--- Test 35: High-contrast 24-bit RGB color fidelity (Hospital sign at 411,15,-600) ---')
local hosp_pos = {
    x = 411, y = 15, z = -600,
    meta = {
        text = '#a Emergency Medical Ward\nFirst Aid & Healing Salves\nStaff On Duty 24/7a\n',
        infotext = 'Emergency Medical Ward',
    }
}
local hosp_node = {name = 'basic_signs:sign_wall_steel_green', param2 = 2}
local hosp_sign_data = waysigns.get_sign_data(hosp_pos, hosp_node)
assert(hosp_sign_data ~= nil, 'Expected sign data for hospital green steel sign')

-- 1. Verify wrapped lines and color extraction: Line 1 = #a (0x55FF55 green), Lines 2 & 3 = white (0xFFFFFF)
local hosp_lines = hosp_sign_data.wrapped.pages[1]
assert(#hosp_lines == 3, 'Expected 3 lines, got ' .. #hosp_lines)
assert(hosp_lines[1].text == 'Emergency Medical Ward', 'Line 1 text mismatch')
assert(hosp_lines[1].color == 0x55FF55, 'Line 1 must be bright green (0x55FF55), got: ' .. string.format('0x%06X', hosp_lines[1].color))
assert(hosp_lines[2].text == 'First Aid & Healing Salves', 'Line 2 text mismatch')
assert(hosp_lines[2].color == 0xFFFFFF, 'Line 2 must be white (0xFFFFFF), got: ' .. string.format('0x%06X', hosp_lines[2].color))
assert(hosp_lines[3].text == 'Staff On Duty 24/7a', 'Line 3 text mismatch')
assert(hosp_lines[3].color == 0xFFFFFF, 'Line 3 must be white (0xFFFFFF), got: ' .. string.format('0x%06X', hosp_lines[3].color))

-- 2. Verify render_hud assigns clean 24-bit RGB numbers without bit 31 overflow across all opacity states
local mock_hosp_player = {
    hud_adds = {},
    hud_changes = {},
    hud_add = function(self, def)
        table.insert(self.hud_adds, def)
        return #self.hud_adds
    end,
    hud_change = function(self, id, stat, val)
        self.hud_changes[id] = self.hud_changes[id] or {}
        self.hud_changes[id][stat] = val
    end,
    hud_remove = function() end,
    get_player_name = function() return 'JohnnyBravo' end,
}

local hosp_state = {
    opacity = 1.0,
    target_opacity = 1.0,
    current_page = 1,
    page_timer = 0,
    hud_line_ids = {},
    current_sign_pos = hosp_pos,
    sign_face_pos = hosp_pos,
    current_sign_data = hosp_sign_data,
    current_sign_node = hosp_node,
}

waysigns.render_hud(mock_hosp_player, hosp_state)

-- HUD line 1 (array index 1 in hud_line_ids)
local line1_id = hosp_state.hud_line_ids[1]
local line1_def = mock_hosp_player.hud_adds[line1_id]
assert(line1_def.number == 0x55FF55, 'Line 1 HUD number must be 0x55FF55 green, got: ' .. string.format('0x%06X', line1_def.number))
assert(bit.band(bit.rshift(line1_def.number, 24), 0xFF) == 0, 'Line 1 must not have high byte set')

-- HUD line 2
local line2_id = hosp_state.hud_line_ids[2]
local line2_def = mock_hosp_player.hud_adds[line2_id]
assert(line2_def.number == 0xFFFFFF, 'Line 2 HUD number must be 0xFFFFFF white, got: ' .. string.format('0x%06X', line2_def.number))
assert(bit.band(bit.rshift(line2_def.number, 24), 0xFF) == 0, 'Line 2 must not have high byte set')

-- 3. Verify fade-in step (opacity = 0.4) also maintains exact 24-bit RGB colors without dimming to black
hosp_state.opacity = 0.4
waysigns.render_hud(mock_hosp_player, hosp_state)
local ch1_num = (mock_hosp_player.hud_changes[line1_id] and mock_hosp_player.hud_changes[line1_id].number) or line1_def.number
local ch2_num = (mock_hosp_player.hud_changes[line2_id] and mock_hosp_player.hud_changes[line2_id].number) or line2_def.number
assert(ch1_num == 0x55FF55, 'Line 1 must stay 0x55FF55 green during fade-in, got: ' .. string.format('0x%06X', ch1_num))
assert(ch2_num == 0xFFFFFF, 'Line 2 must stay 0xFFFFFF white during fade-in, got: ' .. string.format('0x%06X', ch2_num))

print('PASS Test 35')

print('--- Test 36: Optional street_signs entity preservation toggle ---')
local function run_test_36()
    -- 1. Verify setting default is false
    assert(waysigns.settings.enable_street_signs_entities == false, 'enable_street_signs_entities must default to false')

    -- 2. When toggle is false: entities on street_signs are purged
    local orig_get_objects_t36 = core.get_objects_inside_radius
    local entities_purged_t36 = {}
    local mock_ent_t36 = function(ename, pos)
        return {
            is_player = function() return false end,
            get_luaentity = function() return { name = ename } end,
            get_pos = function() return pos end,
            remove = function() table.insert(entities_purged_t36, ename) end,
        }
    end

    local pos_street_t36 = {x = 100, y = 1, z = 100}
    local pos_wood_t36 = {x = 200, y = 1, z = 200}

    local world_nodes = {
        ['100,1,100'] = { name = 'street_signs:sign_basic' },
        ['200,1,200'] = { name = 'signs_lib:sign_wall_wood' },
    }
    core.get_node = function(pos)
        local key = string.format('%d,%d,%d', math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5))
        return world_nodes[key] or { name = 'air' }
    end

    -- With enable_street_signs_entities = false
    waysigns.settings.enable_street_signs_entities = false
    entities_purged_t36 = {}
    core.get_objects_inside_radius = function(pos, r)
        return {
            mock_ent_t36('signs_lib:text', pos_street_t36),
            mock_ent_t36('mcl_signs:text', pos_street_t36),
        }
    end
    waysigns.purge_sign_entities(pos_street_t36)
    assert(#entities_purged_t36 == 2, 'With toggle false, all entities at street_signs must be purged')

    -- 3. With enable_street_signs_entities = true:
    waysigns.settings.enable_street_signs_entities = true

    -- Purge at street_signs node: should exit early and purge NOTHING
    entities_purged_t36 = {}
    waysigns.purge_sign_entities(pos_street_t36)
    assert(#entities_purged_t36 == 0, 'With toggle true, purge_sign_entities at street_signs pos must not purge anything')

    -- Purge at non-street_signs node (e.g. wood sign): signs_lib:text MUST still be purged
    entities_purged_t36 = {}
    core.get_objects_inside_radius = function(pos, r)
        return {
            mock_ent_t36('signs_lib:text', pos_wood_t36),
        }
    end
    waysigns.purge_sign_entities(pos_wood_t36)
    assert(#entities_purged_t36 == 1, 'signs_lib:text at wood sign must still be purged even with street_signs toggle true')

    -- If an adjacent non-street node purges and finds an entity located at street_signs pos:
    -- It must NOT remove signs_lib:text that belongs to street_signs, but MUST remove others
    entities_purged_t36 = {}
    core.get_objects_inside_radius = function(pos, r)
        return {
            mock_ent_t36('signs_lib:text', pos_street_t36),
            mock_ent_t36('mcl_signs:text', pos_street_t36),
        }
    end
    world_nodes['101,1,100'] = { name = 'default:dirt' }
    waysigns.purge_sign_entities({x = 101, y = 1, z = 100})
    assert(#entities_purged_t36 == 1 and entities_purged_t36[1] == 'mcl_signs:text',
        'signs_lib:text on street_signs must be preserved, but mcl_signs:text must be removed')

    -- 4. Test signs_lib.spawn_entity & set_obj_text delegation
    local orig_spawn_called
    local orig_set_text_called
    _G.signs_lib = {
        spawn_entity = function(pos, texture, glow)
            orig_spawn_called = true
            return { name = 'spawned_obj' }
        end,
        set_obj_text = function(pos, text, glow)
            orig_set_text_called = true
        end,
    }

    local orig_spawn = signs_lib.spawn_entity
    local orig_set_text = signs_lib.set_obj_text
    rawset(signs_lib, 'spawn_entity', function(pos, texture, glow)
        if waysigns.settings.enable_street_signs_entities then
            local node = core.get_node(pos)
            if node and node.name and node.name:match('^street_signs:') then
                return orig_spawn(pos, texture, glow)
            end
        end
        waysigns.purge_sign_entities(pos)
        return nil
    end)
    rawset(signs_lib, 'set_obj_text', function(pos, text, glow)
        if waysigns.settings.enable_street_signs_entities then
            local node = core.get_node(pos)
            if node and node.name and node.name:match('^street_signs:') then
                return orig_set_text(pos, text, glow)
            end
        end
        waysigns.purge_sign_entities(pos)
    end)

    -- Calling spawn_entity on street_signs node delegates to original signs_lib
    orig_spawn_called = false
    local spawned = signs_lib.spawn_entity(pos_street_t36, 'street_blade.png', 0)
    assert(orig_spawn_called == true, 'spawn_entity on street_signs node must call original signs_lib')
    assert(spawned and spawned.name == 'spawned_obj', 'Must return spawned object')

    -- Calling spawn_entity on wood sign suppresses and returns nil
    orig_spawn_called = false
    local spawned_wood = signs_lib.spawn_entity(pos_wood_t36, 'wood_sign.png', 0)
    assert(orig_spawn_called == false, 'spawn_entity on wood sign must not call original signs_lib')
    assert(spawned_wood == nil, 'spawn_entity on wood sign must return nil')

    -- Calling set_obj_text on street_signs node delegates to original
    orig_set_text_called = false
    signs_lib.set_obj_text(pos_street_t36, 'Main St', 0)
    assert(orig_set_text_called == true, 'set_obj_text on street_signs node must call original signs_lib')

    -- Calling set_obj_text on wood sign suppresses
    orig_set_text_called = false
    signs_lib.set_obj_text(pos_wood_t36, 'Secret Base', 0)
    assert(orig_set_text_called == false, 'set_obj_text on wood sign must not call original signs_lib')

    -- 5. Test entity on_activate & on_step hooks
    local removed_entities_t36 = {}
    local mock_entity_instance = function(ename, pos)
        return {
            name = ename,
            object = {
                get_pos = function() return pos end,
                remove = function() table.insert(removed_entities_t36, ename) end,
            },
        }
    end

    local ent_def_slib = {
        on_activate = function(self) self.activated = true end,
        on_step = function(self) self.stepped = true end,
    }
    core.registered_entities['signs_lib:text'] = ent_def_slib

    local orig_act = ent_def_slib.on_activate
    local orig_stp = ent_def_slib.on_step
    ent_def_slib.on_activate = function(self)
        if waysigns.settings.enable_street_signs_entities then
            local p = self.object and self.object.get_pos and self.object:get_pos()
            if p then
                local n = core.get_node(vector.round(p))
                if n and n.name and n.name:match('^street_signs:') then
                    return orig_act(self)
                end
            end
        end
        self.object:remove()
    end
    ent_def_slib.on_step = function(self)
        if waysigns.settings.enable_street_signs_entities then
            local p = self.object and self.object.get_pos and self.object:get_pos()
            if p then
                local n = core.get_node(vector.round(p))
                if n and n.name and n.name:match('^street_signs:') then
                    return orig_stp(self)
                end
            end
        end
        self.object:remove()
    end

    -- on_activate at street_signs: signs_lib:text remains alive and activates
    removed_entities_t36 = {}
    local street_ent = mock_entity_instance('signs_lib:text', pos_street_t36)
    ent_def_slib.on_activate(street_ent)
    assert(#removed_entities_t36 == 0, 'signs_lib:text at street_signs must not be removed on activate')
    assert(street_ent.activated == true, 'signs_lib:text at street_signs must execute original on_activate')

    -- on_activate at wood sign: signs_lib:text is removed
    removed_entities_t36 = {}
    local wood_ent = mock_entity_instance('signs_lib:text', pos_wood_t36)
    ent_def_slib.on_activate(wood_ent)
    assert(#removed_entities_t36 == 1, 'signs_lib:text at wood sign must be removed on activate')

    -- Reset setting back to default
    waysigns.settings.enable_street_signs_entities = false
    core.get_objects_inside_radius = orig_get_objects_t36
end
run_test_36()
print('PASS Test 36')

-- =========================================================================
-- Test 37: Reusable helpers, round_pos, window size, and clean_line fast path
-- =========================================================================
print('--- Test 37: Reusable helpers, round_pos, window size, and clean_line fast path ---')
local function run_test_37()
    -- 1. round_pos tests
    assert(waysigns.round_pos(nil) == nil, 'round_pos(nil) must return nil')
    local rounded = waysigns.round_pos({ x = 2.4, y = 5.6, z = -1.1 })
    assert(rounded.x == 2 and rounded.y == 6 and rounded.z == -1, 'round_pos must round properly')

    -- 2. get_player_window_size tests
    assert(waysigns.get_player_window_size(nil) == nil, 'get_player_window_size(nil) must return nil')
    local mock_win_p = {
        get_player_name = function() return 'test_window_p' end
    }
    core.get_player_window_information = function(pname)
        if pname == 'test_window_p' then
            return { size = { x = 1920, y = 1080 } }
        end
        return nil
    end
    local w, h = waysigns.get_player_window_size(mock_win_p)
    assert(w == 1920 and h == 1080, 'get_player_window_size must return width and height')

    -- Invalid / zero window size
    core.get_player_window_information = function()
        return { size = { x = 0, y = 0 } }
    end
    local inv_w, inv_h = waysigns.get_player_window_size(mock_win_p)
    assert(inv_w == nil and inv_h == nil, 'get_player_window_size must return nil on 0 dimension')

    -- 3. clean_line fast-path and codes
    local plain_txt, col_nil = waysigns.clean_line('Plain road sign')
    assert(plain_txt == 'Plain road sign', 'clean_line must return unmodified plain text')
    assert(col_nil == nil, 'plain text has no detected color')

    local colored_txt, col_val = waysigns.clean_line('#fBright White Text')
    assert(colored_txt == 'Bright White Text', 'clean_line must strip signs_lib code')
    assert(col_val == 0xFFFFFF, 'detected color must be white')

    -- 4. get_sign_face_pos attach_offset
    local norm_z = { x = 0, y = 0, z = 1 }
    local hit_z = { x = 10, y = 2, z = 0.5 }
    local pos_z = { x = 10, y = 2, z = 0 }
    local face_attached = waysigns.get_sign_face_pos(pos_z, norm_z, hit_z, true)
    -- Expected: 0.5 + 1.0 * (0.0625 + 0.02) = 0.5825
    assert(math.abs(face_attached.z - 0.5825) < 0.0001, 'get_sign_face_pos must calculate correct offset for attached sign')
end
run_test_37()
print('PASS Test 37')

print('--- Test 38: Dynamic texture extraction from registered node definitions ---')
local function run_test_38()
    -- 1. signs:paper_poster with 6-tile box definition (sides 1-5, front 6)
    core.registered_nodes['signs:paper_poster'] = {
        description = 'Paper Poster',
        tiles = {
            'signs_poster_sides.png', 'signs_poster_sides.png', 'signs_poster_sides.png',
            'signs_poster_sides.png', 'signs_poster_sides.png', 'signs_poster.png',
        },
        drawtype = 'nodebox',
    }
    local pos_poster = {x = 38, y = 1, z = 1, meta = {text = 'Reward: 100 Gold Coins'}}
    local data_poster = waysigns.get_sign_data(pos_poster, {name = 'signs:paper_poster', param2 = 0})
    assert(data_poster ~= nil, 'Expected paper poster sign data')
    assert(data_poster.tile == 'signs_poster.png', 'Expected front face signs_poster.png extracted dynamically from tile 6, got: ' .. tostring(data_poster.tile))
    assert(data_poster.is_light_bg == true, 'Paper poster must have light background')

    -- 2. signs_road with 6-tile box definition (resolving real front faces over sides)
    core.registered_nodes['signs_road:blue_street_sign'] = {
        description = 'Blue Street Sign',
        tiles = {
            'signs_road_sides.png', 'signs_road_sides.png', 'signs_road_sides.png',
            'signs_road_sides.png', 'signs_road_sides.png', 'signs_road_blue_street.png',
        },
        drawtype = 'nodebox',
    }
    core.registered_nodes['signs_road:yellow_street_sign'] = {
        description = 'Yellow Street Sign',
        tiles = {
            'signs_road_sides.png', 'signs_road_sides.png', 'signs_road_sides.png',
            'signs_road_sides.png', 'signs_road_sides.png', 'signs_road_yellow_street.png',
        },
        drawtype = 'nodebox',
    }
    local pos_road_b = {x = 38, y = 2, z = 1, meta = {text = 'Ocean Drive'}}
    local data_road_b = waysigns.get_sign_data(pos_road_b, {name = 'signs_road:blue_street_sign', param2 = 0})
    assert(data_road_b ~= nil, 'Expected blue street sign data')
    assert(data_road_b.tile == 'signs_road_blue_street.png', 'Expected front face blue street sign dynamically extracted from tile 6, got: ' .. tostring(data_road_b.tile))
    assert(data_road_b.text_color == 0xFFFFFF, 'Blue street sign must have white text')

    local pos_road_y = {x = 38, y = 3, z = 1, meta = {text = 'Detour Way'}}
    local data_road_y = waysigns.get_sign_data(pos_road_y, {name = 'signs_road:yellow_street_sign', param2 = 0})
    assert(data_road_y ~= nil, 'Expected yellow street sign data')
    assert(data_road_y.tile == 'signs_road_yellow_street.png', 'Expected front face yellow street sign dynamically extracted from tile 6, got: ' .. tostring(data_road_y.tile))
    assert(data_road_y.text_color == 0x1A1A1A, 'Yellow street sign must have dark text')
    assert(data_road_y.is_light_bg == true, 'Yellow street sign must have is_light_bg = true')

    -- 3. Dynamic texture pack / upstream node override reflection
    waysigns.invalidate_cache(pos_poster)
    core.registered_nodes['signs:paper_poster'].tiles = {'custom_pack_poster.png'}
    local data_override = waysigns.get_sign_data(pos_poster, {name = 'signs:paper_poster', param2 = 0})
    assert(data_override.tile == 'custom_pack_poster.png', 'Texture pack override must dynamically update the sign face texture')

    -- 4. Fallback behavior when registered node has no tiles
    core.registered_nodes['signs:wooden_long_sign'] = {
        description = 'Wooden Long Sign Without Tiles',
    }
    local pos_notile = {x = 38, y = 4, z = 1, meta = {text = 'No Tile Sign'}}
    local data_notile = waysigns.get_sign_data(pos_notile, {name = 'signs:wooden_long_sign', param2 = 0})
    assert(data_notile ~= nil, 'Expected sign data')
    assert(data_notile.tile == waysigns.FALLBACK_WOOD, 'Sign without node tiles must fall back to FALLBACK_WOOD, got: ' .. tostring(data_notile.tile))
end
run_test_38()
print('PASS Test 38')

print('--- Test 39: Throttled entity purging behavior & ABM recreation mitigation ---')
local function run_test_39()
    local purge_calls = 0
    local last_purged = nil
    local orig_purge = waysigns.purge_sign_entities
    waysigns.purge_sign_entities = function(pos)
        purge_calls = purge_calls + 1
        last_purged = pos
    end

    local test_pname = 'PurgeTestPlayer'
    local p_pos = { x = 0, y = 0, z = 0 }
    local p_look = { x = 1, y = 0, z = 0 }
    local test_player = {
        get_player_name = function() return test_pname end,
        get_pos = function() return p_pos end,
        get_look_dir = function() return p_look end,
        get_properties = function() return { eye_height = 1.5 } end,
        hud_add = function() return 1 end,
        hud_change = function() end,
        hud_remove = function() end,
    }

    local sign_pos_a = { x = 39, y = 1, z = 1, meta = { text = 'Sign A' } }
    local sign_pos_b = { x = 39, y = 1, z = 2, meta = { text = 'Sign B' } }
    core.registered_nodes['default:sign_wall_wood'] = { description = 'Sign' }
    local orig_get_node = core.get_node_or_nil
    core.get_node_or_nil = function(pos)
        if vector.equals(pos, sign_pos_a) or vector.equals(pos, sign_pos_b) then
            return { name = 'default:sign_wall_wood', param2 = 0 }
        end
        return orig_get_node and orig_get_node(pos)
    end

    local raycast_target = sign_pos_a
    core.raycast = function()
        local yielded = false
        return function()
            if not yielded and raycast_target then
                yielded = true
                return {
                    type = 'node',
                    under = raycast_target,
                    intersection_normal = vector.new(0, 0, 1),
                    intersection_point = raycast_target,
                }
            end
            return nil
        end
    end

    waysigns.remove_all_huds(test_player)
    local t_state = waysigns.get_or_create_player_state(test_player)
    waysigns.settings.disable_sign_entities = true
    waysigns.settings.check_interval = 0.05

    -- 1. Initial look at Sign A: must trigger immediate purge
    purge_calls = 0
    waysigns.update_player(test_player, 0.05)
    assert(purge_calls == 1, 'Expected immediate entity purge on first look at sign, got ' .. purge_calls)
    assert(vector.equals(last_purged, sign_pos_a), 'Expected purge at sign_pos_a')

    -- 2. Staring at Sign A for several steps (e.g. 0.5s): must NOT trigger repeated purges (throttled)
    for _ = 1, 10 do
        waysigns.update_player(test_player, 0.05)
    end
    assert(purge_calls == 1, 'Expected entity purge to be throttled while staring at same sign, got ' .. purge_calls)

    -- 3. Staring reaches 2.0s: periodic sweep must trigger to catch any ABM-spawned entities
    for _ = 1, 35 do
        waysigns.update_player(test_player, 0.05)
    end
    assert(purge_calls >= 2, 'Expected periodic 2.0s purge sweep to trigger for ABM mitigation, got ' .. purge_calls)
    local calls_after_sweep = purge_calls

    -- 4. Looking away: raycast hits nothing
    raycast_target = nil
    waysigns.update_player(test_player, 0.05)
    assert(t_state.purge_timer == 0, 'Expected purge_timer to reset to 0 when looking away')
    assert(t_state.last_purged_pos == nil, 'Expected last_purged_pos to reset to nil when looking away')

    -- 5. Looking at a different sign (Sign B): must trigger immediate purge of Sign B
    raycast_target = sign_pos_b
    waysigns.update_player(test_player, 0.05)
    assert(purge_calls == calls_after_sweep + 1, 'Expected immediate purge when looking at a new sign')
    assert(vector.equals(last_purged, sign_pos_b), 'Expected purge at sign_pos_b')

    -- Cleanup
    waysigns.remove_all_huds(test_player)
    waysigns.purge_sign_entities = orig_purge
    core.get_node_or_nil = orig_get_node
end
run_test_39()
print('PASS Test 39')

print('--- Test 40: Instant HUD display mode (fade_time = 0.0) ---')
local function run_test_40()
    local test_pname = 'InstantTestPlayer'
    local hud_elements = {}
    local test_player = {
        get_player_name = function() return test_pname end,
        get_pos = function() return { x = 0, y = 0, z = 0 } end,
        get_look_dir = function() return { x = 1, y = 0, z = 0 } end,
        get_properties = function() return { eye_height = 1.5 } end,
        hud_add = function(self, def)
            table.insert(hud_elements, def)
            return #hud_elements
        end,
        hud_change = function(self, id, stat, val)
            if hud_elements[id] then
                hud_elements[id][stat] = val
            end
        end,
        hud_remove = function(self, id)
            hud_elements[id] = nil
        end,
    }

    local sign_pos = { x = 40, y = 1, z = 1, meta = { text = 'Instant Read' } }
    local orig_get_node = core.get_node_or_nil
    core.get_node_or_nil = function(pos)
        if vector.equals(pos, sign_pos) then
            return { name = 'default:sign_wall_wood', param2 = 0 }
        end
        return orig_get_node and orig_get_node(pos)
    end

    local raycast_target = sign_pos
    core.raycast = function()
        local yielded = false
        return function()
            if not yielded and raycast_target then
                yielded = true
                return {
                    type = 'node',
                    under = raycast_target,
                    intersection_normal = vector.new(0, 0, 1),
                    intersection_point = raycast_target,
                }
            end
            return nil
        end
    end

    waysigns.remove_all_huds(test_player)
    local t_state = waysigns.get_or_create_player_state(test_player)
    local orig_fade = waysigns.settings.fade_time
    waysigns.settings.fade_time = 0.0

    -- 1. Point at sign: HUD should be visible at 1.0 opacity on first step
    waysigns.update_player(test_player, 0.05)
    assert(t_state.is_visible == true, 'HUD must become visible immediately')
    assert(t_state.opacity == 1.0, 'Opacity must immediately be 1.0 in instant mode, got ' .. t_state.opacity)
    assert(t_state.target_opacity == 1.0, 'Target opacity must be 1.0')

    -- 2. Look away: HUD should be cleaned up immediately on the same step
    raycast_target = nil
    waysigns.update_player(test_player, 0.05)
    assert(t_state.is_visible == false, 'HUD must be hidden immediately on looking away in instant mode')
    assert(t_state.opacity == 0.0, 'Opacity must be 0.0')
    assert(t_state.hud_bg_id == nil, 'Background HUD ID must be cleared')

    -- Restore fade setting
    waysigns.settings.fade_time = orig_fade
    waysigns.remove_all_huds(test_player)
    core.get_node_or_nil = orig_get_node
end
run_test_40()
print('PASS Test 40')

print('--- Test 41: Packet optimization in render_hud during opacity fade ---')
local function run_test_41()
    local test_pname = 'PacketOptPlayer'
    local changed_stats = {}
    local hud_elements = {}
    local test_player = {
        get_player_name = function() return test_pname end,
        get_pos = function() return { x = 0, y = 0, z = 0 } end,
        get_look_dir = function() return { x = 1, y = 0, z = 0 } end,
        get_properties = function() return { eye_height = 1.5 } end,
        hud_add = function(self, def)
            table.insert(hud_elements, def)
            return #hud_elements
        end,
        hud_change = function(self, id, stat, val)
            table.insert(changed_stats, stat)
            if hud_elements[id] then
                hud_elements[id][stat] = val
            end
        end,
        hud_remove = function(self, id)
            hud_elements[id] = nil
        end,
    }

    local sign_pos = { x = 41, y = 1, z = 1, meta = { text = 'Packet Test Line 1\nLine 2' } }

    waysigns.remove_all_huds(test_player)
    local t_state = waysigns.get_or_create_player_state(test_player)
    local sign_data = waysigns.get_sign_data(sign_pos, { name = 'default:sign_wall_wood', param2 = 0 })

    t_state.current_sign_pos = sign_pos
    t_state.current_sign_data = sign_data
    t_state.current_sign_normal = waysigns.DEFAULT_NORMAL
    t_state.sign_face_pos = sign_pos
    t_state.current_page = 1
    t_state.opacity = 0.2
    t_state.target_opacity = 1.0

    -- 1. Initial render: creates HUD elements (hud_add)
    waysigns.render_hud(test_player, t_state)
    assert(#hud_elements >= 3, 'Expected background and 2 text lines created')
    assert(#changed_stats == 0, 'First render should only call hud_add, no hud_change')

    -- 2. Opacity transition step: advance opacity to 0.5 without changing page or scale
    t_state.opacity = 0.5
    changed_stats = {}
    waysigns.render_hud(test_player, t_state)

    -- Verify that ONLY text and number were updated, and NO redundant offset, size, or position packets were sent
    local has_redundant = false
    for _, stat in ipairs(changed_stats) do
        if stat == 'offset' or stat == 'size' or stat == 'position' or stat == 'scale' then
            has_redundant = true
            break
        end
    end
    assert(not has_redundant, 'Redundant hud_change calls (offset/size/position) detected during opacity fade!')
    assert(#changed_stats > 0, 'Expected hud_change called for text and number')

    waysigns.remove_all_huds(test_player)
end
run_test_41()
print('PASS Test 41')

print('--- Test 42: Front-face pointing detection & back/side HUD suppression ---')
;(function()
    -- Register test directional sign nodes
    core.registered_nodes['test:wall_sign'] = {
        description = 'Test Wallmounted Sign',
        drawtype = 'nodebox',
        paramtype2 = 'wallmounted',
    }
    core.registered_nodes['test:facedir_sign'] = {
        description = 'Test Facedir Sign',
        drawtype = 'nodebox',
        paramtype2 = 'facedir',
    }

    -- 1. Verify get_sign_front_dir for wallmounted nodes
    -- param2=4: attached to +Z wall (back points +Z {0,0,1}) -> front must point -Z {0,0,-1}
    local wall_node_pz = { name = 'test:wall_sign', param2 = 4 }
    local front_pz = waysigns.get_sign_front_dir(wall_node_pz)
    assert(front_pz and front_pz.z == -1 and front_pz.x == 0 and front_pz.y == 0,
        'Wallmounted param2=4 (+Z wall) must have front pointing -Z {0,0,-1}')

    -- param2=5: attached to -Z wall (back points -Z {0,0,-1}) -> front must point +Z {0,0,1}
    local wall_node_nz = { name = 'test:wall_sign', param2 = 5 }
    local front_nz = waysigns.get_sign_front_dir(wall_node_nz)
    assert(front_nz and front_nz.z == 1 and front_nz.x == 0 and front_nz.y == 0,
        'Wallmounted param2=5 (-Z wall) must have front pointing +Z {0,0,1}')

    -- param2=2: attached to +X wall (back points +X {1,0,0}) -> front must point -X {-1,0,0}
    local wall_node_px = { name = 'test:wall_sign', param2 = 2 }
    local front_px = waysigns.get_sign_front_dir(wall_node_px)
    assert(front_px and front_px.x == -1 and front_px.y == 0 and front_px.z == 0,
        'Wallmounted param2=2 (+X wall) must have front pointing -X {-1,0,0}')

    -- 2. Verify get_sign_front_dir for facedir nodes
    -- param2=0: faces -Z (back points +Z {0,0,1}) -> front must point -Z {0,0,-1}
    local fdir_node_0 = { name = 'test:facedir_sign', param2 = 0 }
    local front_fdir_0 = waysigns.get_sign_front_dir(fdir_node_0)
    assert(front_fdir_0 and front_fdir_0.z == -1,
        'Facedir param2=0 must have front pointing -Z')

    -- param2=2: faces +Z (back points -Z {0,0,-1}) -> front must point +Z {0,0,1}
    local fdir_node_2 = { name = 'test:facedir_sign', param2 = 2 }
    local front_fdir_2 = waysigns.get_sign_front_dir(fdir_node_2)
    assert(front_fdir_2 and front_fdir_2.z == 1,
        'Facedir param2=2 must have front pointing +Z')

    -- 3. Direct evaluation of is_pointing_front_face
    local test_sign = { name = 'test:wall_sign', param2 = 4 } -- front is {0, 0, -1}
    local front_hit_normal = vector.new(0, 0, -1)
    local back_hit_normal = vector.new(0, 0, 1)
    local side_hit_normal = vector.new(1, 0, 0)
    local top_hit_normal = vector.new(0, 1, 0)

    local look_towards_sign = vector.new(0, 0, 1) -- player looking in +Z direction towards sign at larger Z
    local look_away_from_sign = vector.new(0, 0, -1) -- player looking in -Z direction (behind sign)

    -- Case A: Front face hit with incoming look direction -> TRUE
    assert(waysigns.is_pointing_front_face(test_sign, front_hit_normal, look_towards_sign) == true,
        'Pointing at front face must return true')

    -- Case B: Back face hit -> FALSE
    assert(waysigns.is_pointing_front_face(test_sign, back_hit_normal, look_away_from_sign) == false,
        'Pointing at back face must return false')

    -- Case C: Side edge hit -> FALSE
    assert(waysigns.is_pointing_front_face(test_sign, side_hit_normal, look_towards_sign) == false,
        'Pointing at side edge must return false')

    -- Case D: Top edge hit -> FALSE
    assert(waysigns.is_pointing_front_face(test_sign, top_hit_normal, look_towards_sign) == false,
        'Pointing at top edge must return false')

    -- 4. Full raycast integration with update_player
    local sign_pos = { x = 40, y = 1, z = 40, meta = { text = 'Front Only Warning Sign' } }
    local mock_face_player = {
        name = 'FrontTester',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        is_valid = function() return true end,
        hud_add = function() return 1 end,
        hud_change = function() end,
        hud_remove = function() end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_window_size = function() return { x = 1920, y = 1080 } end,
        get_fov = function() return 0 end,
    }

    core.get_node_or_nil = function(p)
        if vector.equals(p, sign_pos) then
            return { name = 'test:wall_sign', param2 = 4 } -- front is -Z
        end
        return nil
    end

    local simulated_ray_hit = nil
    core.raycast = function()
        local yielded = false
        return function()
            if not yielded and simulated_ray_hit then
                yielded = true
                return simulated_ray_hit
            end
            return nil
        end
    end

    waysigns.settings.fade_time = 0.0 -- instant HUD for deterministic assertions
    local player_state = waysigns.get_or_create_player_state(mock_face_player)

    -- Step 1: Player looks at FRONT face of the sign (from z=38 looking +Z toward z=40)
    mock_face_player.get_pos = function() return vector.new(40, 1, 38) end
    mock_face_player.get_look_dir = function() return vector.new(0, 0, 1) end
    simulated_ray_hit = {
        type = 'node',
        under = sign_pos,
        intersection_normal = vector.new(0, 0, -1), -- front normal points towards -Z
        intersection_point = { x = 40, y = 1, z = 39.95 },
    }
    player_state.check_timer = 0
    waysigns.update_player(mock_face_player, 0.1)
    assert(player_state.is_visible == true, 'HUD must be visible when pointing at FRONT face')
    assert(vector.equals(player_state.current_sign_pos, sign_pos), 'current_sign_pos must match sign_pos')

    -- Step 2: Player turns around and looks at BACK face of the sign (from z=42 looking -Z toward z=40)
    mock_face_player.get_pos = function() return vector.new(40, 1, 42) end
    mock_face_player.get_look_dir = function() return vector.new(0, 0, -1) end
    simulated_ray_hit = {
        type = 'node',
        under = sign_pos,
        intersection_normal = vector.new(0, 0, 1), -- back normal points towards +Z
        intersection_point = { x = 40, y = 1, z = 40.05 },
    }
    player_state.check_timer = 0
    waysigns.update_player(mock_face_player, 0.1)
    assert(player_state.is_visible == false, 'HUD must NOT be visible when pointing at BACK face')
    assert(player_state.current_sign_pos == nil, 'current_sign_pos must be cleared on back face')

    -- Step 3: Player looks at SIDE edge of the sign
    mock_face_player.get_pos = function() return vector.new(38, 1, 40) end
    mock_face_player.get_look_dir = function() return vector.new(1, 0, 0) end
    simulated_ray_hit = {
        type = 'node',
        under = sign_pos,
        intersection_normal = vector.new(-1, 0, 0), -- side normal
        intersection_point = { x = 39.5, y = 1, z = 40 },
    }
    player_state.check_timer = 0
    waysigns.update_player(mock_face_player, 0.1)
    assert(player_state.is_visible == false, 'HUD must NOT be visible when pointing at SIDE edge')

    waysigns.remove_all_huds(mock_face_player)
    return true
end)()
print('PASS Test 42')

--- Test 43: Dead player raycast short-circuit and HUD suppression ---
;(function()
    print('--- Test 43: Dead player raycast short-circuit and HUD suppression ---')

    local mock_meta = {}
    local p_hp = 20
    local mock_dead_player = {
        name = 'DeadTester',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        is_valid = function() return true end,
        get_hp = function() return p_hp end,
        set_hp = function(_self, hp) p_hp = hp end,
        get_meta = function()
            return {
                get_string = function(_self, k) return mock_meta[k] or '' end,
                set_string = function(_self, k, v) mock_meta[k] = v end,
            }
        end,
        hud_add = function() return 100 end,
        hud_change = function() end,
        hud_remove = function() end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_window_size = function() return { x = 1920, y = 1080 } end,
        get_fov = function() return 0 end,
        get_pos = function() return vector.new(10, 1, 10) end,
        get_look_dir = function() return vector.new(0, 0, 1) end,
    }

    -- 1. Verify waysigns.is_player_dead
    assert(waysigns.is_player_dead(mock_dead_player) == false, 'Living player with HP 20 must not be dead')
    p_hp = 0
    assert(waysigns.is_player_dead(mock_dead_player) == true, 'Player with HP 0 must be dead')
    p_hp = 20
    mock_meta['deathstats:death_active'] = '1'
    assert(waysigns.is_player_dead(mock_dead_player) == true, 'Player with deathstats:death_active must be dead')
    mock_meta['deathstats:death_active'] = ''
    assert(waysigns.is_player_dead(mock_dead_player) == false, 'Player with cleared metadata and HP 20 must be alive')

    -- 2. Verify waysigns.show_hud rejects dead player
    p_hp = 0
    local sign_pos = { x = 10, y = 1, z = 12 }
    local sign_data = {
        nodename = 'default:sign_wall_wood',
        tile = 'default_wood.png',
        raw_text = 'Test Sign',
        wrapped = { pages = { { 'Test Sign' } }, max_line_len = 9 },
        is_metal = false,
    }
    waysigns.show_hud(mock_dead_player, sign_pos, sign_data)
    local dead_state = waysigns.players['DeadTester']
    assert(not dead_state or dead_state.is_visible == false, 'show_hud must not show HUD for dead player')

    -- 3. Verify update_player short-circuits and skips core.raycast completely when dead
    local raycast_call_count = 0
    core.raycast = function()
        raycast_call_count = raycast_call_count + 1
        return function() return nil end
    end

    waysigns.settings.check_interval = 0.05
    dead_state = waysigns.get_or_create_player_state(mock_dead_player)
    dead_state.check_timer = 1.0 -- ensure timer would trigger raycast if alive

    waysigns.update_player(mock_dead_player, 0.1)
    assert(raycast_call_count == 0, 'core.raycast must NEVER be called when player is dead')
    assert(dead_state.check_timer == 0, 'check_timer must be reset when dead')

    -- 4. Verify cleanup when dying while HUD is active
    p_hp = 20
    dead_state.is_visible = true
    dead_state.hud_bg_id = 101
    dead_state.opacity = 1.0
    dead_state.current_sign_pos = sign_pos
    dead_state.current_sign_data = sign_data

    -- Player dies: next update_player must clean up all HUD elements
    p_hp = 0
    waysigns.update_player(mock_dead_player, 0.05)
    assert(dead_state.is_visible == false, 'HUD must be hidden when dead')
    assert(dead_state.hud_bg_id == nil, 'hud_bg_id must be cleared when dead')
    assert(dead_state.opacity == 0, 'opacity must be 0 when dead')
    assert(raycast_call_count == 0, 'core.raycast still must not be called')

    -- 5. Verify on_dieplayer cleans up state and resets timers
    p_hp = 20
    dead_state.is_visible = true
    dead_state.hud_bg_id = 102
    dead_state.opacity = 1.0
    dead_state.check_timer = 0.04
    waysigns.on_dieplayer(mock_dead_player)
    assert(dead_state.is_visible == false, 'on_dieplayer must remove HUD')
    assert(dead_state.hud_bg_id == nil, 'on_dieplayer must clear hud_bg_id')
    assert(dead_state.check_timer == 0, 'on_dieplayer must reset check_timer')

    -- 6. Verify raycasting resumes when player respawns (HP > 0)
    p_hp = 20
    dead_state.check_timer = 1.0
    waysigns.update_player(mock_dead_player, 0.1)
    assert(raycast_call_count == 1, 'core.raycast must resume when player respawns with HP > 0')

    waysigns.remove_all_huds(mock_dead_player)
    return true
end)()
print('PASS Test 43')

print('--- Test 44: Infotext node detection & data extraction ---')
assert((function()
    core.registered_nodes['default:chest'] = {
        description = 'Chest',
        tiles = {'default_chest_top.png', 'default_chest_top.png', 'default_chest_side.png', 'default_chest_side.png', 'default_chest_side.png', 'default_chest_front.png'},
        walkable = true,
    }
    core.registered_nodes['default:furnace'] = {
        description = 'Furnace',
        tiles = {'default_furnace_top.png', 'default_furnace_bottom.png', 'default_furnace_side.png', 'default_furnace_side.png', 'default_furnace_side.png', 'default_furnace_front.png'},
        walkable = true,
    }

    local pos_chest = { x = 20, y = 5, z = 30, meta = { infotext = 'Locked Chest (Alice)' } }
    local node_chest = { name = 'default:chest', param2 = 0 }

    -- Verify it is NOT detected by get_sign_data
    local sign_data = waysigns.get_sign_data(pos_chest, node_chest)
    assert(sign_data == nil, 'Chest must not be detected as a sign')

    -- Verify get_node_infotext_data correctly extracts infotext
    local info_data = waysigns.get_node_infotext_data(pos_chest, node_chest)
    assert(info_data ~= nil, 'Infotext node must be recognized')
    assert(info_data.is_infotext == true, 'is_infotext must be true')
    assert(info_data.raw_text == 'Locked Chest (Alice)', 'Text must match infotext')
    assert(info_data.wrapped.pages[1][1].text == 'Locked Chest (Alice)', 'Wrapped text matches')
    assert(info_data.aspect_ratio == 1.0, 'Aspect ratio must be square 1:1 (1.0), got ' .. tostring(info_data.aspect_ratio))
    -- Front face texture detection (face 6 / 'front' keyword instead of face 1 'top')
    assert(info_data.tile == 'default_chest_front.png', 'Expected front face texture default_chest_front.png, got ' .. tostring(info_data.tile))

    -- Verify quote unwrapping & front face detection for furnace
    local pos_furnace = { x = 20, y = 5, z = 31, meta = { infotext = '"Furnace active (cooked: 45%)"' } }
    local node_furnace = { name = 'default:furnace', param2 = 0 }
    local f_data = waysigns.get_node_infotext_data(pos_furnace, node_furnace)
    assert(f_data ~= nil, 'Furnace infotext must be recognized')
    assert(f_data.raw_text == 'Furnace active (cooked: 45%)', 'Quotes must be unwrapped')
    assert(f_data.tile == 'default_furnace_front.png', 'Expected front face texture default_furnace_front.png, got ' .. tostring(f_data.tile))

    -- Verify mesh node uses fallback texture instead of UV map
    core.registered_nodes['mymod:mesh_machine'] = {
        description = 'Mesh Machine',
        drawtype = 'mesh',
        mesh = 'mymod_machine.obj',
        tiles = {'mymod_machine_uv.png'},
        walkable = true,
    }
    local pos_mesh = { x = 20, y = 5, z = 34, meta = { infotext = 'Centrifuge running' } }
    local node_mesh = { name = 'mymod:mesh_machine', param2 = 0 }
    local mesh_data = waysigns.get_node_infotext_data(pos_mesh, node_mesh)
    assert(mesh_data ~= nil, 'Mesh machine infotext must be recognized')
    assert(mesh_data.tile == waysigns.FALLBACK_STEEL or mesh_data.tile == waysigns.FALLBACK_WOOD, 'Mesh node must use fallback texture instead of UV map')
    assert(mesh_data.tile ~= 'mymod_machine_uv.png', 'Mesh node must not use raw mesh texture')

    -- Verify 2-tile node (e.g. barrel/trunk) selects side/front tile (tile 2) instead of top tile (tile 1)
    core.registered_nodes['mymod:barrel'] = {
        description = 'Storage Barrel',
        tiles = {'barrel_top.png', 'barrel_side.png'},
        walkable = true,
    }
    local pos_barrel = { x = 20, y = 5, z = 35, meta = { infotext = 'Apples (48)' } }
    local node_barrel = { name = 'mymod:barrel', param2 = 0 }
    local barrel_data = waysigns.get_node_infotext_data(pos_barrel, node_barrel)
    assert(barrel_data ~= nil, 'Barrel infotext must be recognized')
    assert(barrel_data.tile == 'barrel_side.png', '2-tile node must choose side/front tile barrel_side.png, got ' .. tostring(barrel_data.tile))

    -- Verify 3-tile node (e.g. bookshelf) selects side/front tile (tile 3) instead of top (tile 1) or bottom (tile 2)
    core.registered_nodes['default:bookshelf'] = {
        description = 'Bookshelf',
        tiles = {'default_wood.png', 'default_wood.png', 'default_bookshelf.png'},
        walkable = true,
    }
    local pos_shelf = { x = 20, y = 5, z = 36, meta = { infotext = 'Ancient Lore' } }
    local node_shelf = { name = 'default:bookshelf', param2 = 0 }
    local shelf_data = waysigns.get_node_infotext_data(pos_shelf, node_shelf)
    assert(shelf_data ~= nil, 'Bookshelf infotext must be recognized')
    assert(shelf_data.tile == 'default_bookshelf.png', '3-tile node must choose side tile default_bookshelf.png, got ' .. tostring(shelf_data.tile))

    -- Verify locked chest selects lock front face (tile 6) instead of top (tile 1)
    core.registered_nodes['default:chest_locked'] = {
        description = 'Locked Chest',
        tiles = {'default_chest_top.png', 'default_chest_top.png', 'default_chest_side.png', 'default_chest_side.png', 'default_chest_side.png', 'default_chest_lock.png'},
        walkable = true,
    }
    local pos_lock_chest = { x = 20, y = 5, z = 37, meta = { infotext = 'Personal Vault' } }
    local node_lock_chest = { name = 'default:chest_locked', param2 = 0 }
    local lock_data = waysigns.get_node_infotext_data(pos_lock_chest, node_lock_chest)
    assert(lock_data ~= nil, 'Locked chest infotext must be recognized')
    assert(lock_data.tile == 'default_chest_lock.png', 'Locked chest must choose lock front tile default_chest_lock.png, got ' .. tostring(lock_data.tile))

    -- Verify empty or placeholder infotext returns nil
    local pos_empty = { x = 20, y = 5, z = 32, meta = { infotext = '   ' } }
    assert(waysigns.get_node_infotext_data(pos_empty, node_chest) == nil, 'Empty infotext must return nil')
    local pos_placeholder = { x = 20, y = 5, z = 33, meta = { infotext = '(empty)' } }
    assert(waysigns.get_node_infotext_data(pos_placeholder, node_chest) == nil, 'Placeholder (empty) must return nil')

    return true
end)())
print('PASS Test 44')

print('--- Test 45: Top-half 3D waypoint position calculation ---')
assert((function()
    local node_pos = { x = 10, y = 2, z = 15 }
    local norm_z = { x = 0, y = 0, z = 1 }
    local hit_point = { x = 10.2, y = 2.0, z = 15.5 }

    -- Standard sign: Y remains at node_pos.y (2.0)
    local sign_pos = waysigns.get_sign_face_pos(node_pos, norm_z, hit_point, false, false)
    assert(math.abs(sign_pos.y - 2.0) < 0.001, 'Sign Y must be at node center (2.0), got: ' .. sign_pos.y)

    -- Infotext node: Y must be offset to top half (pos.y + 0.35 = 2.35)
    local infotext_pos = waysigns.get_sign_face_pos(node_pos, norm_z, hit_point, false, true)
    local expected_y = node_pos.y + (waysigns.settings.infotext_pos_y_offset or 0.35)
    assert(math.abs(infotext_pos.y - expected_y) < 0.001, 'Infotext Y must be on top half of node (' .. expected_y .. '), got: ' .. infotext_pos.y)
    assert(infotext_pos.y > node_pos.y, 'Infotext Y must be strictly greater than node center')
    assert(infotext_pos.y <= node_pos.y + 0.5, 'Infotext Y must stay within node top bound (pos.y + 0.5)')

    -- Side face -X
    local norm_x = { x = -1, y = 0, z = 0 }
    local hit_point_x = { x = 9.5, y = 2.0, z = 15.3 }
    local infotext_pos_x = waysigns.get_sign_face_pos(node_pos, norm_x, hit_point_x, false, true)
    assert(math.abs(infotext_pos_x.y - expected_y) < 0.001, 'Infotext Y must be on top half for X face')
    assert(infotext_pos_x.x < node_pos.x, 'Infotext X must be positioned in front of -X face')

    -- Top face +Y
    local norm_y = { x = 0, y = 1, z = 0 }
    local hit_point_y = { x = 10.0, y = 2.5, z = 15.0 }
    local infotext_pos_top = waysigns.get_sign_face_pos(node_pos, norm_y, hit_point_y, false, true)
    assert(infotext_pos_top.y > node_pos.y + 0.5, 'Top face waypoint must be positioned above node top surface')

    return true
end)())
print('PASS Test 45')

print('--- Test 46: Separate sizing and overlay positioning ---')
assert((function()
    local p_scale = {
        get_player_name = function() return 'test_player_scale' end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_pos = function() return { x = 0, y = 0, z = 0 } end,
        get_look_dir = function() return { x = 0, y = 0, z = 1 } end,
        get_meta = function() return { get_string = function() return '' end } end,
    }

    -- 1. Verify separate scale
    waysigns.settings.hud_scale = 2.5
    waysigns.settings.infotext_scale = 1.3
    local sign_scale = waysigns.get_effective_scale(p_scale, false)
    local info_scale = waysigns.get_effective_scale(p_scale, true)
    assert(sign_scale == 2.5, 'Sign scale must match hud_scale (2.5), got ' .. sign_scale)
    assert(info_scale == 1.3, 'Infotext scale must match infotext_scale (1.3), got ' .. info_scale)

    -- Reset to defaults
    waysigns.settings.hud_scale = 2.0
    waysigns.settings.infotext_scale = 2.0

    -- 2. Verify separate overlay positioning in render_hud
    local orig_display_mode = waysigns.settings.display_mode
    waysigns.settings.display_mode = 'overlay'
    waysigns.settings.overlay_pos_y = 0.50
    waysigns.settings.infotext_overlay_pos_y = 0.38

    local huds_created = {}
    local p_overlay = {
        get_player_name = function() return 'test_player_overlay' end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_pos = function() return { x = 0, y = 0, z = 0 } end,
        get_look_dir = function() return { x = 0, y = 0, z = 1 } end,
        get_meta = function() return { get_string = function() return '' end } end,
        hud_add = function(self, def)
            local id = #huds_created + 1
            huds_created[id] = def
            return id
        end,
        hud_change = function(self, id, stat, val)
            if huds_created[id] then
                huds_created[id][stat] = val
            end
        end,
        hud_remove = function(self, id)
            huds_created[id] = nil
        end,
    }

    -- Render sign HUD in overlay mode
    local sign_data = {
        nodename = 'default:sign_wall_wood',
        raw_text = 'Town Hall',
        tile = 'waysigns_sign_wood.png',
        aspect_ratio = 1.40,
        wrapped = waysigns.wrap_text('Town Hall', nil, nil, 0xFFFFFF),
        is_infotext = false,
    }
    waysigns.show_hud(p_overlay, { x = 0, y = 1, z = 2 }, sign_data, { x = 0, y = 0, z = 1 }, { x = 0, y = 1, z = 1.5 })
    local bg_sign = huds_created[1]
    assert(bg_sign ~= nil and bg_sign.position.y == 0.50, 'Sign overlay must be at overlay_pos_y (0.50), got: ' .. tostring(bg_sign and bg_sign.position.y))

    waysigns.remove_all_huds(p_overlay)
    huds_created = {}

    -- Render infotext HUD in overlay mode
    local chest_data = {
        nodename = 'default:chest',
        raw_text = 'Storage Chest',
        tile = 'waysigns_sign_steel.png',
        aspect_ratio = 1.0,
        wrapped = waysigns.wrap_text('Storage Chest', 24, 4, 0xFFFFFF),
        is_infotext = true,
    }
    waysigns.show_hud(p_overlay, { x = 0, y = 1, z = 2 }, chest_data, { x = 0, y = 0, z = 1 }, { x = 0, y = 1, z = 1.5 })
    local bg_chest = huds_created[1]
    assert(bg_chest ~= nil and bg_chest.position.y == 0.38, 'Infotext overlay must be at infotext_overlay_pos_y (0.38), got: ' .. tostring(bg_chest and bg_chest.position.y))
    -- Verify square 1:1 dimensions in texture specification (e.g. resize:224x224)
    local tex_w, tex_h = bg_chest.text:match('resize:(%d+)x(%d+)')
    assert(tex_w ~= nil and tex_w == tex_h, 'Infotext background plaque must be square 1:1, got ' .. tostring(tex_w) .. 'x' .. tostring(tex_h))

    waysigns.remove_all_huds(p_overlay)
    waysigns.settings.display_mode = orig_display_mode
    return true
end)())
print('PASS Test 46')

print('--- Test 47: Omnidirectional raycast detection for infotext nodes ---')
assert((function()
    local huds_active = {}
    local p_omni = {
        get_player_name = function() return 'test_player_omni' end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_pos = function() return { x = 0, y = 0, z = 0 } end,
        get_look_dir = function() return { x = 0, y = 0, z = 1 } end,
        get_meta = function() return { get_string = function() return '' end } end,
        get_inventory = function() return nil end,
        hud_add = function(self, def)
            local id = #huds_active + 1
            huds_active[id] = def
            return id
        end,
        hud_change = function(self, id, stat, val)
            if huds_active[id] then
                huds_active[id][stat] = val
            end
        end,
        hud_remove = function(self, id)
            huds_active[id] = nil
        end,
    }

    local chest_pos = { x = 0, y = 1, z = 3, meta = { infotext = 'Community Resources' } }
    core.get_node_or_nil = function(p)
        if vector.equals(p, chest_pos) then
            return { name = 'default:chest', param2 = 0 }
        end
        return { name = 'air', param2 = 0 }
    end

    -- 1. Pointing at back face of chest (norm: {0, 0, -1})
    core.raycast = function()
        local yielded = false
        return function()
            if not yielded then
                yielded = true
                return {
                    type = 'node',
                    under = chest_pos,
                    above = { x = 0, y = 1, z = 2 },
                    intersection_normal = { x = 0, y = 0, z = -1 },
                    intersection_point = { x = 0.5, y = 1.0, z = 2.5 },
                }
            end
            return nil
        end
    end

    waysigns.settings.check_interval = 0.05
    local omni_state = waysigns.get_or_create_player_state(p_omni)
    omni_state.check_timer = 0.06

    -- Must show HUD even from back face
    waysigns.update_player(p_omni, 0.06)
    assert(omni_state.is_visible == true, 'Infotext node HUD must show from any face (omnidirectional)')
    assert(omni_state.current_sign_data ~= nil and omni_state.current_sign_data.is_infotext == true, 'Active data must be infotext')
    assert(omni_state.current_sign_data.raw_text == 'Community Resources', 'Extracted text must match')

    -- 2. Verify waysigns_enable_node_infotext = false disables detection
    waysigns.settings.enable_node_infotext = false
    waysigns.remove_all_huds(p_omni)
    omni_state.check_timer = 0.06
    waysigns.update_player(p_omni, 0.06)
    assert(omni_state.is_visible == false, 'Infotext HUD must not show when enable_node_infotext is false')

    -- Restore setting
    waysigns.settings.enable_node_infotext = true
    waysigns.remove_all_huds(p_omni)
    return true
end)())
print('PASS Test 47')

print('--- Test 48: Escape sequence and translation tag sanitization ---')
assert((function()
    -- 1. Verify strip_all_escapes handles translation sequences with no leftover \x1b
    local raw_trans = '\x1b(T@x_farming)Hive position\x1bE: (1022, 1002, 1000)'
    local cleaned = waysigns.strip_all_escapes(raw_trans)
    assert(cleaned == 'Hive position: (1022, 1002, 1000)', 'Translation tags must be completely stripped')
    assert(not cleaned:find('\x1b'), 'Cleaned string must not contain any \\x1b bytes')

    -- 2. Verify clean_line removes translation tags and extracts colors
    local colored_trans = '\x1b(c@#FFAA00)\x1b(T@default)Chest\x1bE'
    local c_line, c_col = waysigns.clean_line(colored_trans)
    assert(c_line == 'Chest', 'clean_line must strip both color and translation tags')
    assert(c_col == 0xFFAA00, 'clean_line must extract 24-bit color')
    assert(not c_line:find('\x1b'), 'clean_line output must contain no \\x1b')

    -- 3. Verify get_node_infotext_data sanitizes translation sequences from node metadata
    local bee_pos = { x = 10, y = 1, z = 10, meta = {
        infotext = '\x1b(T@x_farming)Occupancy\x1bE: 1 / 3\n\x1b(T@x_farming)Saturation\x1bE: 5 / 5'
    } }
    core.registered_nodes['x_farming:beehive'] = {
        description = 'Beehive',
        tiles = { 'x_farming_beehive.png' },
    }
    local info_data = waysigns.get_node_infotext_data(bee_pos, { name = 'x_farming:beehive', param2 = 0 })
    assert(info_data ~= nil, 'Must extract infotext data')
    assert(not info_data.raw_text:find('\x1b'), 'raw_text must have no escape sequences')
    assert(info_data.raw_text == 'Occupancy: 1 / 3\nSaturation: 5 / 5', 'Extracted infotext must match unescaped text')

    -- 4. Verify wrap_text on long text with translation sequences does not split escape codes
    local long_trans = '\x1b(T@x_farming)Extremely long translation heading description text for node\x1bE'
    local wrapped = waysigns.wrap_text(long_trans, 20, 5, 0xFFFFFF)
    for _, page in ipairs(wrapped.pages) do
        for _, line_obj in ipairs(page) do
            assert(not line_obj.text:find('\x1b'), 'Wrapped line text must never contain \\x1b: ' .. line_obj.text)
        end
    end

    -- 5. Broken / unterminated escape sequences do not crash or emit \x1b
    local broken = 'Warning: \x1b(T@unknown unclosed'
    local clean_broken = waysigns.strip_all_escapes(broken)
    assert(not clean_broken:find('\x1b'), 'Broken unclosed escape sequence must be eliminated')

    return true
end)())
print('PASS Test 48')

print('--- Test 49: Combined multi-layer textures and texture transformations ---')
assert((function()
    -- 1. x_farming:bee_hive_saturated: front texture + honey overlay combined
    core.registered_nodes['x_farming:bee_hive_saturated'] = {
        description = 'Beehive (Saturated)',
        tiles = {
            'x_farming_bee_hive_top.png',
            'x_farming_bee_hive_bottom.png',
            'x_farming_bee_hive_side.png^x_farming_bee_hive_saturated_overlay.png',
            'x_farming_bee_hive_side.png^x_farming_bee_hive_saturated_overlay.png',
            'x_farming_bee_hive_side.png^x_farming_bee_hive_saturated_overlay.png',
            'x_farming_bee_hive_front.png^x_farming_bee_hive_saturated_overlay.png',
        },
        walkable = true,
    }

    local hive_pos = { x = 40, y = 5, z = 50, meta = {
        infotext = 'Honey ready for harvest: 3 / 3'
    } }
    local hive_node = { name = 'x_farming:bee_hive_saturated', param2 = 0 }
    local hive_data = waysigns.get_node_infotext_data(hive_pos, hive_node)
    assert(hive_data ~= nil, 'Saturated beehive infotext must be recognized')
    local expected_tile = 'x_farming_bee_hive_front.png^x_farming_bee_hive_saturated_overlay.png'
    assert(hive_data.tile == expected_tile,
        'Beehive must combine front and overlay textures! Got: ' .. tostring(hive_data.tile))

    -- Verify get_background_texture groups the combined layers with parentheses
    local bg_tex = waysigns.get_background_texture(hive_data.tile, 224, 224, 1.0, false)
    assert(bg_tex:find('%(' .. expected_tile:gsub('([%^%.])', '%%%1') .. '%)%^%[resize:224x224'),
        'Background texture must group combined layers in parentheses before resizing! Got: ' .. bg_tex)

    -- 2. Layers with texture transformations (e.g. ^[transformFX)
    local transformed_tile = 'obsidian_chest_front.png^[transformFX^obsidian_chest_lock.png^[transformFX'
    core.registered_nodes['mymod:chest_transformed'] = {
        description = 'Transformed Chest',
        tiles = {
            'top.png', 'bottom.png', 'side.png', 'side.png', 'side.png',
            transformed_tile,
        },
        walkable = true,
    }
    local trans_pos = { x = 40, y = 5, z = 51, meta = { infotext = 'Transformed Vault' } }
    local trans_node = { name = 'mymod:chest_transformed', param2 = 0 }
    local trans_data = waysigns.get_node_infotext_data(trans_pos, trans_node)
    assert(trans_data ~= nil, 'Transformed chest must be recognized')
    assert(trans_data.tile == transformed_tile,
        'Texture transformations must be preserved across layers! Got: ' .. tostring(trans_data.tile))

    local bg_trans = waysigns.get_background_texture(trans_data.tile, 224, 224, 1.0, true)
    assert(bg_trans:find('%(' .. transformed_tile:gsub('([%^%[%].])', '%%%1') .. '%)%^%[resize:224x224'),
        'Transformed layers must be grouped in parentheses before resize! Got: ' .. bg_trans)

    -- 3. Node with node_def.overlay_tiles
    core.registered_nodes['mymod:overlay_shelf'] = {
        description = 'Overlay Shelf',
        tiles = {
            'shelf_top.png', 'shelf_bottom.png', 'shelf_side.png',
            'shelf_side.png', 'shelf_side.png', 'shelf_front.png',
        },
        overlay_tiles = {
            '', '', '',
            '', '', 'shelf_front_paint.png',
        },
        walkable = true,
    }
    local shelf_pos = { x = 40, y = 5, z = 52, meta = { infotext = 'Painted Shelf' } }
    local shelf_node = { name = 'mymod:overlay_shelf', param2 = 0 }
    local shelf_data = waysigns.get_node_infotext_data(shelf_pos, shelf_node)
    assert(shelf_data ~= nil, 'Overlay shelf must be recognized')
    assert(shelf_data.tile == 'shelf_front.png^shelf_front_paint.png',
        'Node overlay_tiles must be combined with base tiles! Got: ' .. tostring(shelf_data.tile))

    -- 4. Verify signs_lib obsolete text layer is still cleanly stripped from signs
    core.registered_nodes['signs:sign_with_text_layer'] = {
        description = 'Sign With Text Layer',
        tiles = { 'sign_wood.png^signs_lib_text.png' },
        drawtype = 'nodebox',
    }
    local s_pos = { x = 40, y = 5, z = 53, meta = { text = 'Road Ahead' } }
    local s_node = { name = 'signs:sign_with_text_layer', param2 = 0 }
    local s_data = waysigns.get_sign_data(s_pos, s_node)
    assert(s_data ~= nil, 'Sign must be recognized')
    assert(s_data.tile == 'sign_wood.png',
        'Obsolete signs_lib_text.png must be stripped from signs! Got: ' .. tostring(s_data.tile))

    return true
end)())
print('PASS Test 49')

;(function()
    local function MockItemStack(name, count)
        return {
            is_empty = function(self) return (count or 0) <= 0 or (name or '') == '' end,
            get_name = function(self) return name or '' end,
            get_count = function(self) return count or 0 end,
            get_short_description = function(self) return nil end,
            get_description = function(self)
                local def = (core.registered_items and core.registered_items[name])
                    or (core.registered_nodes and core.registered_nodes[name])
                return def and def.description or name
            end,
        }
    end

    local function MockInventory(lists)
        return {
            get_list = function(self, name) return lists[name] end,
            get_lists = function(self) return lists end,
            is_empty = function(self, name)
                local l = lists[name]
                if not l then return true end
                for _, s in ipairs(l) do
                    if not s:is_empty() then return false end
                end
                return true
            end,
        }
    end

    print('--- Test 50: Item texture resolver (waysigns.get_item_texture) ---')
assert((function()
    core.registered_items = setmetatable(core.registered_items or {}, {
        __index = function(_, k)
            return (core.registered_nodes and core.registered_nodes[k])
                or (core.registered_craftitems and core.registered_craftitems[k])
                or (core.registered_tools and core.registered_tools[k])
        end,
    })
    core.registered_tools = core.registered_tools or {}
    core.registered_craftitems = core.registered_craftitems or {}
    core.registered_items['default:apple'] = {
        description = 'Apple',
        inventory_image = 'default_apple.png',
    }
    core.registered_tools['default:pick_steel'] = {
        description = 'Steel Pickaxe',
        inventory_image = 'default_tool_steelpick.png',
    }
    core.registered_nodes['default:stone'] = {
        description = 'Stone',
        tiles = { 'default_stone.png' },
        drawtype = 'normal',
    }
    core.registered_nodes['flowers:rose'] = {
        description = 'Red Rose',
        tiles = { 'flower_rose.png' },
        drawtype = 'plantlike',
    }

    -- 1. 2D craftitem uses inventory_image
    local tex_apple = waysigns.get_item_texture('default:apple')
    assert(tex_apple == 'default_apple.png', 'Expected default_apple.png, got: ' .. tostring(tex_apple))

    -- 2. 2D tool uses inventory_image
    local tex_pick = waysigns.get_item_texture('default:pick_steel')
    assert(tex_pick == 'default_tool_steelpick.png', 'Expected steel pick icon, got: ' .. tostring(tex_pick))

    -- 3. 3D cube node synthesizes inventory cube
    local tex_stone = waysigns.get_item_texture('default:stone')
    assert(tex_stone:find('%[inventorycube'), 'Cube node must synthesize inventorycube, got: ' .. tostring(tex_stone))
    assert(tex_stone:find('default_stone.png'), 'Inventorycube must contain stone tile')

    -- 4. Plantlike node returns flat tile without inventory cube
    local tex_rose = waysigns.get_item_texture('flowers:rose')
    assert(tex_rose == 'flower_rose.png', 'Plantlike node must return flat tile, got: ' .. tostring(tex_rose))

    -- 5. Blank/unknown fallback
    assert(waysigns.get_item_texture('') == 'waysigns_blank.png', 'Empty name must return blank')
    assert(waysigns.get_item_texture('unknown:mod_item') == 'unknown_item.png', 'Unregistered item must return unknown_item.png')

    return true
end)())
print('PASS Test 50')

print('--- Test 51: Node inventory extraction & aggregation (Option A) ---')
assert((function()
    core.registered_items['default:wood'] = { description = 'Wooden Planks', inventory_image = 'default_wood.png' }
    core.registered_items['default:coal_lump'] = { description = 'Coal Lump', inventory_image = 'default_coal.png' }

    local chest_inv = MockInventory({
        main = {
            MockItemStack('default:wood', 64),
            MockItemStack('default:wood', 32),  -- Duplicate stack: must be aggregated!
            MockItemStack('default:apple', 12),
            MockItemStack('default:stone', 50),
            MockItemStack('default:pick_steel', 1),
            MockItemStack('default:coal_lump', 20), -- 5th distinct item
            MockItemStack('', 0),               -- Empty slot
        }
    })
    local pos_chest = { x = 60, y = 10, z = 10, inv = chest_inv, meta = { infotext = 'Storage Chest' } }
    local node_chest = { name = 'default:chest', param2 = 0 }

    local qv = waysigns.extract_node_inventory(pos_chest, node_chest, core.get_meta(pos_chest), nil, 4)
    assert(qv ~= nil, 'Inventory quickview must not be nil')
    assert(qv.total_items == (64 + 32 + 12 + 50 + 1 + 20), 'Total items count mismatch: ' .. tostring(qv.total_items))
    assert(qv.total_distinct == 5, 'Total distinct items must be 5, got: ' .. tostring(qv.total_distinct))
    assert(#qv.items == 4, 'Max slots 4 must limit returned items to 4, got: ' .. tostring(#qv.items))
    assert(qv.overflow == 1, 'Overflow must be 1 for 5 items with limit 4, got: ' .. tostring(qv.overflow))

    -- Verify aggregation
    assert(qv.items[1].name == 'default:wood', 'First item must be wood')
    assert(qv.items[1].count == 96, 'Wood stacks must be aggregated to 96 (64 + 32), got: ' .. tostring(qv.items[1].count))

    -- Verify Option A Text Line Summary
    assert(qv.summary:find('96x'), 'Summary must contain 96x: ' .. qv.summary)
    assert(qv.summary:find('12x'), 'Summary must contain 12x: ' .. qv.summary)
    assert(qv.summary:find('%(%+1%)'), 'Summary must indicate (+1) overflow: ' .. qv.summary)

    -- Test empty container returns nil
    local empty_inv = MockInventory({ main = { MockItemStack('', 0), MockItemStack('', 0) } })
    local pos_empty = { x = 60, y = 10, z = 11, inv = empty_inv, meta = { infotext = 'Empty Chest' } }
    assert(waysigns.extract_node_inventory(pos_empty, node_chest, core.get_meta(pos_empty), nil, 4) == nil,
        'Empty container must return nil')

    return true
end)())
print('PASS Test 51')

print('--- Test 52: Container security, locked chests, and protection ---')
assert((function()
    core.registered_items['default:diamond'] = { description = 'Diamond', inventory_image = 'default_diamond.png' }
    local secret_inv = MockInventory({
        main = { MockItemStack('default:diamond', 99) }
    })
    local pos_locked = {
        x = 60, y = 10, z = 12,
        inv = secret_inv,
        meta = { infotext = 'Locked Chest (owned by Alice)', owner = 'Alice' },
    }
    local node_locked = { name = 'default:chest_locked', param2 = 0 }

    local player_bob = {
        get_player_name = function(self) return 'Bob' end,
        privs = {},
    }
    local player_alice = {
        get_player_name = function(self) return 'Alice' end,
        privs = {},
    }
    local player_admin = {
        get_player_name = function(self) return 'Bob' end,
        privs = { protection_bypass = true },
    }

    -- 1. Bob (non-owner, no bypass) -> Quickview MUST BE SUPPRESSED!
    local bob_qv = waysigns.extract_node_inventory(pos_locked, node_locked, core.get_meta(pos_locked), player_bob)
    assert(bob_qv == nil, 'Private locked chest contents must NOT be leaked to Bob!')
    local bob_data = waysigns.get_node_infotext_data(pos_locked, node_locked, player_bob)
    assert(bob_data ~= nil, 'Node infotext label must still be shown')
    assert(not bob_data.text:find('Diamond'), 'Diamond must NOT appear in Bob infotext text!')
    assert(bob_data.quickview_items == nil, 'Bob must receive nil quickview_items')

    -- 2. Alice (owner) -> Quickview items MUST be visible!
    local alice_qv = waysigns.extract_node_inventory(pos_locked, node_locked, core.get_meta(pos_locked), player_alice)
    assert(alice_qv ~= nil, 'Alice must be able to view her own locked chest!')
    local alice_data = waysigns.get_node_infotext_data(pos_locked, node_locked, player_alice)
    assert(alice_data.quickview_items[1].name == 'default:diamond', 'Alice must receive diamonds in quickview_items')
    assert(not alice_data.text:find('Diamond'), 'Option 2: Diamond summary omitted from header text when visual quickview is active')

    -- 3. Admin with protection_bypass -> Quickview items visible
    local admin_qv = waysigns.extract_node_inventory(pos_locked, node_locked, core.get_meta(pos_locked), player_admin)
    assert(admin_qv ~= nil, 'Admin with protection_bypass must be allowed to inspect chest')

    return true
end)())
print('PASS Test 52')

print('--- Test 53: Background texture dock blitting & cache key isolation ---')
assert((function()
    local items = {
        { name = 'default:wood', count = 64, icon = 'default_wood.png' },
        { name = 'default:apple', count = 12, icon = 'default_apple.png' },
    }

    -- 1. Verify get_background_texture blits dock when items are provided
    local bg_tex = waysigns.get_background_texture('default_wood.png', 180, 180, 1.0, false, false, false, false, items)
    assert(bg_tex:find('%[combine:180x180'), 'Must contain combine modifier with board dimensions: ' .. bg_tex)
    assert(bg_tex:find('%[fill\\:18x18\\:#000000a0'), 'Must contain slot bezels: ' .. bg_tex)
    assert(bg_tex:find('default_wood%.png'), 'Must contain wood icon: ' .. bg_tex)
    assert(bg_tex:find('default_apple%.png'), 'Must contain apple icon: ' .. bg_tex)

    -- 2. Verify cache key isolation between different inventory states
    local items2 = {
        { name = 'default:diamond', count = 5, icon = 'default_diamond.png' }
    }
    local bg_tex2 = waysigns.get_background_texture('default_wood.png', 180, 180, 1.0, false, false, false, false, items2)
    assert(bg_tex ~= bg_tex2, 'Different inventory items must produce distinct textures!')
    assert(bg_tex2:find('default_diamond%.png'), 'Must contain diamond icon in second texture')

    -- 3. Verify standard background call without items does not include dock
    local bg_plain = waysigns.get_background_texture('default_wood.png', 180, 180, 1.0, false, false, false, false, nil)
    assert(not bg_plain:find('%[fill\\:18x18'), 'Plain background must not contain slot bezels')

    return true
end)())
print('PASS Test 53')
end)()

;(function()
    local function MockItemStack(name, count)
        return {
            get_name = function() return name end,
            get_count = function() return count end,
            is_empty = function() return (not name or name == '' or count <= 0) end,
            get_short_description = function() return nil end,
            get_description = function() return nil end,
        }
    end

    local function MockInventory(lists)
        return {
            get_list = function(self, name) return lists[name] end,
            get_lists = function(self) return lists end,
            is_empty = function(self, name)
                local l = lists[name]
                if not l then return true end
                for _, s in ipairs(l) do
                    if not s:is_empty() then return false end
                end
                return true
            end,
        }
    end

    print('--- Test 54: Player-bound (x_obsidianmese:chest) & detached inventory extraction ---')
    core.registered_items['default:obsidian'] = { description = 'Obsidian', inventory_image = 'default_obsidian.png' }
    core.registered_items['default:mese_crystal'] = { description = 'Mese Crystal', inventory_image = 'default_mese_crystal.png' }

    local player_inv = MockInventory({
        ['x_obsidianmese:chest'] = {
            MockItemStack('default:obsidian', 10),
            MockItemStack('default:mese_crystal', 5),
            MockItemStack('', 0),
        },
        ['enderchest'] = {
            MockItemStack('default:diamond', 64),
        },
    })
    local pbound_player = {
        get_player_name = function() return 'Alice' end,
        get_inventory = function() return player_inv end,
    }

    local pos_obsidian = { x = 70, y = 10, z = 20, meta = { infotext = 'Obsidian Mese Chest' } }
    local node_obsidian = { name = 'x_obsidianmese:chest', param2 = 0 }

    -- 1. Verify player-bound inventory extraction for x_obsidianmese:chest
    local qv_obs = waysigns.extract_node_inventory(pos_obsidian, node_obsidian, core.get_meta(pos_obsidian), pbound_player)
    assert(qv_obs ~= nil, 'x_obsidianmese:chest must extract player-bound inventory')
    assert(#qv_obs.items == 2, 'Must contain 2 occupied items (ignoring empty slot), got: ' .. #qv_obs.items)
    assert(qv_obs.items[1].name == 'default:obsidian' and qv_obs.items[1].count == 10)
    assert(qv_obs.items[2].name == 'default:mese_crystal' and qv_obs.items[2].count == 5)

    -- 2. Verify x_obsidianmese:chest_open (swapped open node state) resolves correctly
    local node_obsidian_open = { name = 'x_obsidianmese:chest_open', param2 = 0 }
    local qv_obs_open = waysigns.extract_node_inventory(pos_obsidian, node_obsidian_open, core.get_meta(pos_obsidian), pbound_player)
    assert(qv_obs_open ~= nil, 'x_obsidianmese:chest_open must resolve base name inventory')
    assert(#qv_obs_open.items == 2)

    -- 3. Verify enderchest player-bound fallback
    local pos_ender = { x = 71, y = 10, z = 20, meta = { infotext = 'Ender Chest' } }
    local node_ender = { name = 'default:enderchest', param2 = 0 }
    local qv_ender = waysigns.extract_node_inventory(pos_ender, node_ender, core.get_meta(pos_ender), pbound_player)
    assert(qv_ender ~= nil, 'Enderchest must extract from player enderchest inventory')
    assert(qv_ender.items[1].name == 'default:diamond' and qv_ender.items[1].count == 64)

    -- 4. Verify detached inventory via core.get_inventory and metadata link
    local detached_inv = MockInventory({
        storage = { MockItemStack('default:gold_ingot', 16) }
    })
    core.registered_items['default:gold_ingot'] = { description = 'Gold Ingot', inventory_image = 'default_gold_ingot.png' }
    local orig_get_inv = core.get_inventory
    core.get_inventory = function(loc)
        if loc and loc.type == 'detached' and loc.name == 'bank_vault' then
            return detached_inv
        end
        return orig_get_inv and orig_get_inv(loc)
    end
    local pos_detached = { x = 72, y = 10, z = 20, meta = { infotext = 'Bank Safe', detached_inventory = 'bank_vault' } }
    local node_detached = { name = 'bank:vault_safe', param2 = 0 }
    local qv_detached = waysigns.extract_node_inventory(pos_detached, node_detached, core.get_meta(pos_detached), pbound_player)
    assert(qv_detached ~= nil, 'Detached inventory must be extracted via metadata inv link')
    assert(qv_detached.items[1].name == 'default:gold_ingot' and qv_detached.items[1].count == 16)

    -- 5. Verify custom inventory resolver registration
    waysigns.register_inventory_resolver('custom:crate', function(_pos, _node, _meta, _player)
        return { MockItemStack('default:wood', 42) }
    end)
    local pos_custom = { x = 73, y = 10, z = 20, meta = { infotext = 'Custom Crate' } }
    local node_custom = { name = 'custom:crate', param2 = 0 }
    local qv_custom = waysigns.extract_node_inventory(pos_custom, node_custom, core.get_meta(pos_custom), pbound_player)
    assert(qv_custom ~= nil, 'Custom resolver must be invoked')
    assert(qv_custom.items[1].name == 'default:wood' and qv_custom.items[1].count == 42)

    print('PASS Test 54')

    print('--- Test 55: Multi-row quickview grid & zero empty slots ---')
    local items12 = {}
    for i = 1, 12 do
        items12[i] = { name = 'mod:item_' .. i, count = i, icon = 'mod_item_' .. i .. '.png' }
    end

    -- 1. Verify 12 items creates a 2-row grid with proportionally scaled slots (37x37 on w=380)
    local bg_12 = waysigns.get_background_texture('default_wood.png', 380, 380, 1.0, false, false, false, false, items12)
    assert(bg_12:find('%[fill\\:37x37\\:#000000a0'), '12 items must scale proportionally to 37x37 slot size for w=380, got: ' .. bg_12)
    assert(bg_12:find('mod_item_1%.png') and bg_12:find('mod_item_12%.png'), 'All 12 items must be blitted')

    local count_bezels = 0
    for _ in bg_12:gmatch('%[fill\\:37x37') do
        count_bezels = count_bezels + 1
    end
    assert(count_bezels == 12, 'Exactly 12 slot bezels must be rendered (0 empty slots), got: ' .. count_bezels)

    -- 2. Verify 24 items creates a 3-row grid with proportionally scaled slots (39x39 on w=400)
    local items24 = {}
    for i = 1, 24 do
        items24[i] = { name = 'mod:gem_' .. i, count = i, icon = 'gem_' .. i .. '.png' }
    end
    local bg_24 = waysigns.get_background_texture('default_wood.png', 400, 400, 1.0, false, false, false, false, items24)
    assert(bg_24:find('%[fill\\:39x39\\:#000000a0'), '24 items must scale proportionally to 39x39 slot size for w=400, got: ' .. bg_24)
    local count_bezels24 = 0
    for _ in bg_24:gmatch('%[fill\\:39x39') do
        count_bezels24 = count_bezels24 + 1
    end
    assert(count_bezels24 == 24, 'Exactly 24 slot bezels must be rendered, got: ' .. count_bezels24)

    -- 3. Verify extract_node_inventory omits empty slots from chest
    local mixed_stacks = {}
    for i = 1, 8 do
        mixed_stacks[#mixed_stacks + 1] = MockItemStack('default:obsidian', i)
        mixed_stacks[#mixed_stacks + 1] = MockItemStack('', 0) -- empty slot
    end
    local mixed_inv = MockInventory({ main = mixed_stacks })
    local pos_mixed = { x = 74, y = 10, z = 20, inv = mixed_inv, meta = { infotext = 'Mixed Chest' } }
    local node_mixed = { name = 'default:chest', param2 = 0 }
    local qv_mixed = waysigns.extract_node_inventory(pos_mixed, node_mixed, core.get_meta(pos_mixed), pbound_player, 32)
    assert(qv_mixed ~= nil)
    assert(#qv_mixed.items == 1, 'Only 1 distinct non-empty item must be extracted, got: ' .. #qv_mixed.items)
    assert(qv_mixed.items[1].count == 36, 'Aggregated obsidian count must be 36 (1+2+..+8)')

    -- 4. Verify summary text does not truncate item names or cut off inventory list
    local multi_items = {}
    for i = 1, 7 do
        multi_items[#multi_items + 1] = MockItemStack('default:reinforced_item_' .. i, i)
        core.registered_items['default:reinforced_item_' .. i] = { description = 'Reinforced Crystal Ingot ' .. i }
    end
    local multi_inv = MockInventory({ main = multi_items })
    local pos_multi = { x = 75, y = 10, z = 20, inv = multi_inv, meta = { infotext = 'Large Chest' } }
    local qv_multi = waysigns.extract_node_inventory(pos_multi, node_mixed, core.get_meta(pos_multi), pbound_player, 32)
    assert(#qv_multi.items == 7, 'Visual items must contain all 7 items, got: ' .. #qv_multi.items)
    -- Verify no item name truncation with '..'
    assert(not qv_multi.summary:find('%.%.'), 'Item descriptions must NOT be truncated with .., got: ' .. qv_multi.summary)
    assert(qv_multi.summary:find('Reinforced Crystal Ingot 1'), 'Full item name must be preserved')
    assert(qv_multi.summary:find('Reinforced Crystal Ingot 7'), 'All 7 items must be listed without 4-item cap')
    -- Overflow indicator only when distinct items exceed limit
    local qv_overflow = waysigns.extract_node_inventory(pos_multi, node_mixed, core.get_meta(pos_multi), pbound_player, 4)
    assert(qv_overflow.summary:find('%(%+3%)'), 'Overflow indicator (+3) only appears when limit 4 is exceeded')

    print('PASS Test 55')

    print('--- Test 56: Top-right pagination badge positioning & smart wrapping ---')
    local mock_hud_player = {
        hud_adds = {},
        hud_changes = {},
        hud_removes = {},
        get_player_name = function() return 'page_tester' end,
        hud_add = function(self, def)
            table.insert(self.hud_adds, def)
            return #self.hud_adds
        end,
        hud_change = function(self, id, field, val)
            table.insert(self.hud_changes, { id = id, field = field, val = val })
        end,
        hud_remove = function(self, id)
            table.insert(self.hud_removes, id)
        end,
    }
    local page_state = waysigns.get_or_create_player_state(mock_hud_player)
    page_state.opacity = 1.0
    page_state.target_opacity = 1.0
    page_state.current_sign_pos = { x = 80, y = 10, z = 30 }
    page_state.sign_face_pos = { x = 80, y = 10, z = 30 }
    page_state.current_page = 1
    page_state.current_sign_data = {
        tile = 'default_wood.png',
        text = 'Page 1 Content\nPage 2 Content',
        is_metal = false,
        text_color = 0xFFFFFF,
        is_infotext = true,
        quickview_items = {
            { name = 'default:wood', count = 10, icon = 'default_wood.png' }
        },
        wrapped = {
            pages = {
                { { text = 'Line 1 Page 1', color = 0xFFFFFF } },
                { { text = 'Line 1 Page 2', color = 0xFFFFFF } },
            },
            total_lines = 2,
            max_line_len = 13,
        }
    }
    waysigns.render_hud(mock_hud_player, page_state)
    assert(page_state.hud_page_id ~= nil, 'Multi-page sign must create hud_page_id element')
    local page_hud_elem = mock_hud_player.hud_adds[page_state.hud_page_id]
    assert(page_hud_elem ~= nil, 'Page HUD element must exist')
    assert(page_hud_elem.text == '[1/2]', 'Page indicator text must be [1/2], got: ' .. tostring(page_hud_elem.text))
    assert(page_hud_elem.offset.x > 0, 'Page badge offset.x must be positive (right side), got: ' .. tostring(page_hud_elem.offset.x))
    assert(page_hud_elem.offset.y < 0, 'Page badge offset.y must be negative (top header), got: ' .. tostring(page_hud_elem.offset.y))

    -- 2. Verify Smart Wrapping (Option D): 30 chars per line and 5 lines prevents spurious page splits
    local long_title = 'Reinforced Diamond Storage Crate'
    local long_info_data = waysigns.wrap_text(long_title, 30, 5, 0xFFFFFF)
    assert(#long_info_data.pages == 1, 'Long title must fit on single page with 30-char/5-line wrapping, got pages: ' .. #long_info_data.pages)
    assert(long_info_data.total_lines == 2, 'Expected 2 wrapped lines')

    -- 3. Verify scroll delay (4.0s default) and pagination cycling
    assert(waysigns.settings.scroll_delay == 4.0, 'waysigns.settings.scroll_delay must be 4.0s, got: ' .. tostring(waysigns.settings.scroll_delay))

    print('PASS Test 56')
end)()

;(function()
    print('--- Test 57: Stable square infotext plaque, Option 2 clean title, in-place HUD updates & animated frame cropping ---')

    local function MockItemStack(name, count)
        return {
            get_name = function() return name end,
            get_count = function() return count end,
            is_empty = function() return (not name or name == '' or count <= 0) end,
            get_short_description = function() return nil end,
            get_description = function() return nil end,
        }
    end

    local function MockInventory(lists)
        return {
            get_list = function(self, name) return lists[name] end,
            get_lists = function(self) return lists end,
            is_empty = function(self, name)
                local l = lists[name]
                if not l then return true end
                for _, s in ipairs(l) do
                    if not s:is_empty() then return false end
                end
                return true
            end,
        }
    end

    local test_player = {
        hud_adds = {},
        hud_changes = {},
        hud_removes = {},
        get_player_name = function() return 'test_player_57' end,
        hud_add = function(self, def)
            table.insert(self.hud_adds, def)
            return #self.hud_adds
        end,
        hud_change = function(self, id, field, val)
            table.insert(self.hud_changes, { id = id, field = field, val = val })
        end,
        hud_remove = function(self, id)
            table.insert(self.hud_removes, id)
        end,
        get_inventory = function() return nil end,
    }

    -- 1. Option 1: Constant stable square plaque size for infotext
    -- Sizing must be identical regardless of item count (empty chest vs full chest)
    local empty_chest_data = {
        nodename = 'default:chest',
        raw_text = 'Storage Chest',
        text = 'Storage Chest',
        tile = 'default_chest_front.png',
        is_metal = false,
        text_color = 0xFFFFFF,
        aspect_ratio = 1.0,
        is_infotext = true,
        quickview_items = nil,
        wrapped = waysigns.wrap_text('Storage Chest', 30, 5, 0xFFFFFF)
    }

    local full_items = {}
    for i = 1, 24 do
        full_items[i] = { name = 'mod:item_' .. i, count = 64, icon = 'item_' .. i .. '.png' }
    end
    local full_chest_data = {
        nodename = 'default:chest',
        raw_text = 'Storage Chest',
        text = 'Storage Chest',
        tile = 'default_chest_front.png',
        is_metal = false,
        text_color = 0xFFFFFF,
        aspect_ratio = 1.0,
        is_infotext = true,
        quickview_items = full_items,
        wrapped = waysigns.wrap_text('Storage Chest', 30, 5, 0xFFFFFF)
    }

    waysigns.settings.infotext_scale = 2.0
    local pstate1 = waysigns.get_or_create_player_state(test_player)
    pstate1.opacity = 1.0
    pstate1.target_opacity = 1.0
    pstate1.current_sign_pos = { x = 90, y = 1, z = 90 }
    pstate1.current_sign_data = empty_chest_data
    waysigns.render_hud(test_player, pstate1)
    local empty_bg_tex = test_player.hud_adds[pstate1.hud_bg_id].text
    local empty_w, empty_h = empty_bg_tex:match('%[resize:(%d+)x(%d+)')
    assert(empty_w and empty_h, 'Must find resize modifier in empty chest background texture')
    assert(empty_w == empty_h, 'Option 1: Infotext plaque must be perfectly square, got ' .. empty_w .. 'x' .. empty_h)

    -- Render full chest with 24 items
    waysigns.remove_all_huds(test_player)
    test_player.hud_adds = {}
    local pstate2 = waysigns.get_or_create_player_state(test_player)
    pstate2.opacity = 1.0
    pstate2.target_opacity = 1.0
    pstate2.current_sign_pos = { x = 90, y = 1, z = 90 }
    pstate2.current_sign_data = full_chest_data
    waysigns.render_hud(test_player, pstate2)
    local full_bg_tex = test_player.hud_adds[pstate2.hud_bg_id].text
    local full_w, full_h = full_bg_tex:match('%[resize:(%d+)x(%d+)')
    assert(full_w == empty_w and full_h == empty_h, 'Option 1: Empty chest and full chest must have identical plaque dimensions! empty=' .. empty_w .. 'x' .. empty_h .. ', full=' .. full_w .. 'x' .. full_h)
    assert(tonumber(empty_w) == math.floor(160 * 2.0), 'Plaque size at default infotext_scale 2.0 must be floor(160*2.0)=320, got: ' .. empty_w)

    -- 2. Option 2: Clean title in header when visual quickview is displayed
    local chest_inv = MockInventory({
        main = {
            MockItemStack('default:wood', 64),
            MockItemStack('default:apple', 10),
        }
    })
    local pos_chest = { x = 91, y = 1, z = 91, inv = chest_inv, meta = { infotext = 'Personal Vault' } }
    local node_chest = { name = 'default:chest', param2 = 0 }
    local vault_data = waysigns.get_node_infotext_data(pos_chest, node_chest, test_player)
    assert(vault_data ~= nil, 'Vault data must be extracted')
    assert(vault_data.quickview_items and #vault_data.quickview_items == 2, 'Vault must have 2 quickview items')
    assert(vault_data.raw_text == 'Personal Vault', 'Option 2: raw_text must be clean title only, got: ' .. vault_data.raw_text)
    assert(vault_data.text == 'Personal Vault', 'Option 2: text must be clean title only')

    -- When quickview is disabled, raw_text falls back to title without items
    waysigns.settings.enable_inventory_quickview = false
    waysigns.node_cache = {}
    local vault_no_qv = waysigns.get_node_infotext_data(pos_chest, node_chest, test_player)
    assert(vault_no_qv.quickview_items == nil, 'Quickview items must be nil when setting disabled')
    assert(vault_no_qv.raw_text == 'Personal Vault', 'Title only when quickview disabled')
    waysigns.settings.enable_inventory_quickview = true
    waysigns.node_cache = {}

    -- 3. In-place update on text_changed & Packet Flood Elimination
    waysigns.remove_all_huds(test_player)
    test_player.hud_adds = {}
    test_player.hud_changes = {}
    test_player.hud_removes = {}

    -- Initial show_hud call
    local sign_pos = { x = 100, y = 5, z = 100 }
    waysigns.show_hud(test_player, sign_pos, empty_chest_data)
    local pstate_sign = waysigns.players['test_player_57']
    pstate_sign.opacity = 1.0 -- Simulated fade complete
    local bg_id = pstate_sign.hud_bg_id
    local line_id = pstate_sign.hud_line_ids[1]
    assert(bg_id ~= nil and line_id ~= nil, 'HUD elements must be created')
    assert(#test_player.hud_removes == 0, 'No removals on initial show')

    -- Chest metadata updates while player is looking at it (e.g. inventory changes or infotext update)
    local chest_updated_data = {
        nodename = 'default:chest',
        raw_text = 'Storage Chest (Updated)',
        text = 'Storage Chest (Updated)',
        tile = 'default_chest_front.png',
        is_metal = false,
        text_color = 0xFFFFFF,
        aspect_ratio = 1.0,
        is_infotext = true,
        quickview_items = nil,
        wrapped = waysigns.wrap_text('Storage Chest (Updated)', 30, 5, 0xFFFFFF)
    }

    local prev_removes_count = #test_player.hud_removes
    local prev_adds_count = #test_player.hud_adds
    waysigns.show_hud(test_player, sign_pos, chest_updated_data)

    -- In-place update must NOT call remove_all_huds or recreate elements from scratch
    assert(#test_player.hud_removes == prev_removes_count, 'In-place update must NOT tear down HUDs! Removes: ' .. #test_player.hud_removes)
    assert(#test_player.hud_adds == prev_adds_count, 'In-place update must NOT re-add HUDs! Adds: ' .. #test_player.hud_adds)
    assert(pstate_sign.opacity == 1.0, 'In-place update must preserve solid opacity=1.0 without restarting fade')

    -- Verify delta tracking: calling render_hud again with identical data produces ZERO hud_change calls
    local changes_before = #test_player.hud_changes
    waysigns.render_hud(test_player, pstate_sign)
    local changes_after = #test_player.hud_changes
    assert(changes_before == changes_after, 'Delta tracking must skip redundant hud_change packets when content is identical! Before: ' .. changes_before .. ', After: ' .. changes_after)

    -- 4. Animated texture sheet detection & frame 0 cropping
    local orig_get_modpath = core.get_modpath
    core.get_modpath = function(m)
        if m == 'xdecor' then
            return '/Users/juraj/Library/Application Support/minetest/mods/xdecor'
        end
        return orig_get_modpath and orig_get_modpath(m) or '.'
    end
    waysigns.animated_frame_cache = {}

    -- 4a. Animation table in tile definition with disk-backed PNG inspection (xdecor:television 16x128 strip -> 8 frames)
    local anim_tile_def = {
        name = 'xdecor_television_front_animated.png',
        animation = { type = 'vertical_frames', aspect_w = 16, aspect_h = 16, length = 80.0 }
    }
    local tv_node_def = {
        description = 'Television',
        tiles = {
            'tv_side.png', 'tv_side.png', 'tv_side.png', 'tv_side.png', 'tv_side.png',
            anim_tile_def
        }
    }
    core.registered_nodes['xdecor:tv'] = tv_node_def
    local tv_front = waysigns.get_node_infotext_data({ x = 105, y = 1, z = 105, meta = { infotext = 'Television' } }, { name = 'xdecor:tv', param2 = 0 }, test_player)
    assert(tv_front ~= nil, 'Television data must be extracted')
    assert(tv_front.tile:find('%[verticalframe:8:0'), 'Animated 16x128 TV strip must be cropped to frame 0 with [verticalframe:8:0, got: ' .. tv_front.tile)

    -- 4b. Animation table when file is not on disk: crops frame 0 via [combine
    local anim_no_file = {
        name = 'virtual_animated_flame.png',
        animation = { type = 'vertical_frames', aspect_w = 16, aspect_h = 16 }
    }
    local clean_no_file = waysigns.clean_tile_name(anim_no_file, false, 'custom:flame')
    assert(clean_no_file:find('%[combine:16x16:0,0=virtual_animated_flame%.png'), 'Virtual animation without disk file must crop top frame via [combine, got: ' .. clean_no_file)

    -- 4c. Existing [verticalframe in tile string normalized to frame 0
    local bg_custom_frame = waysigns.get_background_texture('custom_torch.png^[verticalframe:16:7', 224, 224, 1.0, true)
    assert(bg_custom_frame:find('%[verticalframe:16:0'), 'Existing verticalframe:16:7 must be normalized to verticalframe:16:0, got: ' .. bg_custom_frame)

    -- 4d. waysigns.get_texture_frame_count inspection
    local frames = waysigns.get_texture_frame_count('xdecor_television_front_animated.png', 'xdecor', 16, 16)
    assert(frames == 8, 'get_texture_frame_count must detect 8 frames for xdecor_television_front_animated.png, got: ' .. tostring(frames))

    core.get_modpath = orig_get_modpath
    print('PASS Test 57')
end)()

;(function()
    print('--- Test 58: Compact quickview item sizing & bounds containment on square plaques ---')

    local function make_items(count)
        local list = {}
        for i = 1, count do
            list[i] = { name = 'mod:item_' .. i, count = i * 2, icon = 'item_' .. i .. '.png' }
        end
        return list
    end

    -- 1. Standard square infotext plaque at scale 1.4 (w = 224, h = 224)
    local w, h = 224, 224

    -- Test 1 row (8 items)
    local items8 = make_items(8)
    local bg8 = waysigns.get_background_texture('default_chest_front.png', w, h, 1.0, false, false, false, false, items8)
    assert(bg8:find('%[fill\\:22x22\\:#000000a0'), '1 row (8 items) must use 22x22 slots')
    assert(bg8:find('%^%[resize\\:18x18'), '1 row (8 items) must use 18x18 icons')
    -- Check that coordinates fit within plaque boundaries
    for sx, sy in bg8:gmatch(':([%-%d]+),([%-%d]+)=%[fill\\:22x22') do
        local x_num, y_num = tonumber(sx), tonumber(sy)
        assert(x_num >= 10 and (x_num + 22) <= (w - 10), 'Slot X=' .. x_num .. ' must fit inside w=' .. w)
        assert(y_num >= 10 and (y_num + 22) <= (h - 8), 'Slot Y=' .. y_num .. ' must fit inside h=' .. h)
    end

    -- Test 2 rows (16 items)
    local items16 = make_items(16)
    local bg16 = waysigns.get_background_texture('default_chest_front.png', w, h, 1.0, false, false, false, false, items16)
    assert(bg16:find('%[fill\\:22x22\\:#000000a0'), '2 rows (16 items) must use 22x22 slots')
    assert(bg16:find('%^%[resize\\:18x18'), '2 rows (16 items) must use 18x18 icons')
    for sx, sy in bg16:gmatch(':([%-%d]+),([%-%d]+)=%[fill\\:22x22') do
        local x_num, y_num = tonumber(sx), tonumber(sy)
        assert(x_num >= 10 and (x_num + 22) <= (w - 10), 'Slot X=' .. x_num .. ' must fit inside w=' .. w)
        assert(y_num >= 10 and (y_num + 22) <= (h - 8), 'Slot Y=' .. y_num .. ' must fit inside h=' .. h)
    end

    -- Test 3 rows (24 items)
    local items24 = make_items(24)
    local bg24 = waysigns.get_background_texture('default_chest_front.png', w, h, 1.0, false, false, false, false, items24)
    assert(bg24:find('%[fill\\:22x22\\:#000000a0'), '3 rows (24 items) must use 22x22 slots')
    assert(bg24:find('%^%[resize\\:18x18'), '3 rows (24 items) must use 18x18 icons')
    for sx, sy in bg24:gmatch(':([%-%d]+),([%-%d]+)=%[fill\\:22x22') do
        local x_num, y_num = tonumber(sx), tonumber(sy)
        assert(x_num >= 10 and (x_num + 22) <= (w - 10), 'Slot X=' .. x_num .. ' must fit inside w=' .. w)
        assert(y_num >= 10 and (y_num + 22) <= (h - 8), 'Slot Y=' .. y_num .. ' must fit inside h=' .. h)
    end

    -- Test 4 rows (32 items, 8x4 grid)
    local items32 = make_items(32)
    local bg32 = waysigns.get_background_texture('default_chest_front.png', w, h, 1.0, false, false, false, false, items32)
    assert(bg32:find('%[fill\\:22x22\\:#000000a0'), '4 rows (32 items) must use 22x22 slots')
    assert(bg32:find('%^%[resize\\:18x18'), '4 rows (32 items) must use 18x18 icons')
    for sx, sy in bg32:gmatch(':([%-%d]+),([%-%d]+)=%[fill\\:22x22') do
        local x_num, y_num = tonumber(sx), tonumber(sy)
        assert(x_num >= 10 and (x_num + 22) <= (w - 10), 'Slot X=' .. x_num .. ' must fit inside w=' .. w)
        assert(y_num >= 10 and (y_num + 22) <= (h - 8), 'Slot Y=' .. y_num .. ' must fit inside h=' .. h)
    end

    -- 2. Scaling with plaque width / waysigns_infotext_scale
    -- Scale 1.0 (w = 160, h = 160)
    local w_10, h_10 = 160, 160
    local bg_s10 = waysigns.get_background_texture('default_chest_front.png', w_10, h_10, 1.0, false, false, false, false, items32)
    assert(bg_s10:find('%[fill\\:16x16\\:#000000a0'), 'Scale 1.0 plaque (160x160) must scale slots to 16x16')
    assert(bg_s10:find('%^%[resize\\:13x13'), 'Scale 1.0 plaque (160x160) must scale icons to 13x13')
    for sx, sy in bg_s10:gmatch(':([%-%d]+),([%-%d]+)=%[fill\\:16x16') do
        local x_num, y_num = tonumber(sx), tonumber(sy)
        assert(x_num >= 0 and (x_num + 16) <= w_10, 'Scale 1.0 slot X=' .. x_num .. ' must fit inside w=' .. w_10)
        assert(y_num >= 0 and (y_num + 16) <= h_10, 'Scale 1.0 slot Y=' .. y_num .. ' must fit inside h=' .. h_10)
    end

    -- Scale 2.0 (w = 320, h = 320)
    local w_20, h_20 = 320, 320
    local bg_s20 = waysigns.get_background_texture('default_chest_front.png', w_20, h_20, 1.0, false, false, false, false, items32)
    assert(bg_s20:find('%[fill\\:31x31\\:#000000a0'), 'Scale 2.0 plaque (320x320) must scale slots to 31x31')
    assert(bg_s20:find('%^%[resize\\:26x26'), 'Scale 2.0 plaque (320x320) must scale icons to 26x26')

    -- Scale 2.5 (w = 400, h = 400)
    local w_25, h_25 = 400, 400
    local bg_s25 = waysigns.get_background_texture('default_chest_front.png', w_25, h_25, 1.0, false, false, false, false, items32)
    assert(bg_s25:find('%[fill\\:39x39\\:#000000a0'), 'Scale 2.5 plaque (400x400) must scale slots to 39x39')
    assert(bg_s25:find('%^%[resize\\:32x32'), 'Scale 2.5 plaque (400x400) must scale icons to 32x32')

    -- 3. Dynamic change of waysigns_infotext_scale in render_hud
    local scale_test_player = {
        hud_adds = {},
        hud_changes = {},
        hud_removes = {},
        get_player_name = function() return 'scale_tester' end,
        hud_add = function(self, def)
            table.insert(self.hud_adds, def)
            return #self.hud_adds
        end,
        hud_change = function(self, id, field, val)
            table.insert(self.hud_changes, { id = id, field = field, val = val })
        end,
        hud_remove = function(self, id)
            table.insert(self.hud_removes, id)
        end,
    }
    local chest_data_scaling = {
        nodename = 'default:chest',
        raw_text = 'Chest',
        text = 'Chest',
        tile = 'default_chest_front.png',
        is_metal = false,
        text_color = 0xFFFFFF,
        aspect_ratio = 1.0,
        is_infotext = true,
        quickview_items = items32,
        wrapped = waysigns.wrap_text('Chest', 30, 5, 0xFFFFFF)
    }

    -- Render at default infotext_scale = 1.4
    waysigns.settings.infotext_scale = 1.4
    local pstate_scale = waysigns.get_or_create_player_state(scale_test_player)
    pstate_scale.opacity = 1.0
    pstate_scale.target_opacity = 1.0
    pstate_scale.current_sign_pos = { x = 1, y = 2, z = 3 }
    pstate_scale.current_sign_data = chest_data_scaling
    waysigns.render_hud(scale_test_player, pstate_scale)
    local tex_14 = scale_test_player.hud_adds[pstate_scale.hud_bg_id].text
    assert(tex_14:find('%[fill\\:22x22'), 'infotext_scale 1.4 must render 22x22 slots')
    assert(tex_14:find('%^%[resize\\:18x18'), 'infotext_scale 1.4 must render 18x18 icons')

    -- Change setting to infotext_scale = 2.0
    waysigns.settings.infotext_scale = 2.0
    waysigns.render_hud(scale_test_player, pstate_scale)
    local tex_20 = pstate_scale.rendered_bg_texture
    assert(tex_20:find('%[fill\\:31x31'), 'infotext_scale 2.0 must scale slots up to 31x31, got: ' .. tostring(tex_20))
    assert(tex_20:find('%^%[resize\\:26x26'), 'infotext_scale 2.0 must scale icons up to 26x26')

    -- Reset setting to default 2.0
    waysigns.settings.infotext_scale = 2.0

    print('PASS Test 58')
end)()

print('--- Test 59: Hex color code escape sequences in clean_line ---')
;(function()
    -- 1. Standard 6-digit #RRGGBB
    local l6, c6 = waysigns.clean_line('\27(c@#55FF55)Hospital')
    assert(l6 == 'Hospital', 'clean_line must strip 6-digit engine color escape, got: ' .. l6)
    assert(c6 == 0x55FF55, 'clean_line must detect 0x55FF55 for #55FF55, got: ' .. string.format('0x%06X', c6 or 0))

    -- 2. 3-digit shorthand #RGB (e.g. #5F5 -> #55FF55)
    local l3, c3 = waysigns.clean_line('\27(c@#5F5)Emergency')
    assert(l3 == 'Emergency', 'clean_line must strip 3-digit engine color escape, got: ' .. l3)
    assert(c3 == 0x55FF55, 'clean_line must expand #5F5 to 0x55FF55, got: ' .. string.format('0x%06X', c3 or 0))

    -- 3. 8-digit #RRGGBBAA with alpha channel (e.g. #FF8800CC -> #FF8800)
    local l8, c8 = waysigns.clean_line('\27(c@#FF8800CC)Warning')
    assert(l8 == 'Warning', 'clean_line must strip 8-digit engine color escape, got: ' .. l8)
    assert(c8 == 0xFF8800, 'clean_line must extract RGB from 8-digit hex #FF8800CC, got: ' .. string.format('0x%06X', c8 or 0))

    -- 4. Normal line without color escape
    local lplain, cplain = waysigns.clean_line('Simple Text')
    assert(lplain == 'Simple Text' and cplain == nil, 'clean_line must leave plain text intact')

    print('PASS Test 59')
end)()

print('--- Test 60: Unowned container in protected area respecting locks ---')
;(function()
    local function MockItemStack(name, count)
        return {
            is_empty = function(self) return (count or 0) <= 0 or (name or '') == '' end,
            get_name = function(self) return name or '' end,
            get_count = function(self) return count or 0 end,
            get_short_description = function(self) return nil end,
            get_description = function(self) return name end,
        }
    end

    local function MockInventory(lists)
        return {
            get_list = function(self, name) return lists[name] end,
            get_lists = function(self) return lists end,
        }
    end

    waysigns.settings.quickview_respect_locks = true
    local prot_pos = { x = 40, y = 5, z = 60 }
    local node = { name = 'default:chest' }
    local meta = {
        get_string = function(self, key)
            if key == 'owner' then return '' end
            return ''
        end,
        get_inventory = function(self)
            return MockInventory({ main = { MockItemStack('default:gold_ingot', 10) } })
        end
    }
    local player_intruder = {
        get_player_name = function() return 'intruder' end
    }

    -- 1. When area is protected against intruder
    local orig_is_protected = core.is_protected
    core.is_protected = function(pos, name)
        if pos.x == 40 and name == 'intruder' then
            return true
        end
        return false
    end

    local qv_blocked = waysigns.extract_node_inventory(prot_pos, node, meta, player_intruder)
    assert(qv_blocked == nil, 'Unowned container in protected area must be blocked when quickview_respect_locks is true')

    -- 2. When area is NOT protected (public area)
    waysigns.clear_caches()
    core.is_protected = function(pos, name) return false end
    local qv_allowed = waysigns.extract_node_inventory(prot_pos, node, meta, player_intruder)
    assert(qv_allowed ~= nil and #qv_allowed.items > 0, 'Unowned container in uninhibited public area must be visible')

    core.is_protected = orig_is_protected
    waysigns.clear_caches()
    print('PASS Test 60')
end)()

print('--- Test 61: Infotext multi-viewer cache isolation and 0.5s throttling ---')
;(function()
    local function MockItemStack(name, count)
        return {
            is_empty = function(self) return (count or 0) <= 0 or (name or '') == '' end,
            get_name = function(self) return name or '' end,
            get_count = function(self) return count or 0 end,
            get_short_description = function(self) return nil end,
            get_description = function(self) return name end,
        }
    end

    local function MockInventory(lists)
        return {
            get_list = function(self, name) return lists[name] end,
            get_lists = function(self) return lists end,
        }
    end

    waysigns.settings.enable_inventory_quickview = true
    waysigns.settings.quickview_respect_locks = true

    local chest_pos = { x = 80, y = 10, z = 90 }
    local chest_node = { name = 'default:chest_locked' }

    local chest_meta = {
        get_string = function(self, key)
            if key == 'infotext' then return 'Locked Chest' end
            if key == 'owner' then return 'alice' end
            return ''
        end,
        get_inventory = function(self)
            return MockInventory({ main = { MockItemStack('default:diamond', 64) } })
        end
    }

    local orig_get_meta = core.get_meta
    core.get_meta = function(p)
        if p.x == 80 then return chest_meta end
        return orig_get_meta(p)
    end

    local alice_player = {
        get_player_name = function() return 'alice' end
    }
    local bob_player = {
        get_player_name = function() return 'bob' end
    }

    -- 1. Alice (owner) queries infotext data
    local alice_data = waysigns.get_node_infotext_data(chest_pos, chest_node, alice_player)
    assert(alice_data ~= nil, 'Alice should receive infotext data')
    assert(alice_data.quickview_items ~= nil and #alice_data.quickview_items == 1,
        'Alice (owner) must see the diamond quickview')

    -- 2. Bob (visitor) queries the same locked chest
    local bob_data = waysigns.get_node_infotext_data(chest_pos, chest_node, bob_player)
    assert(bob_data ~= nil, 'Bob should receive infotext data')
    assert(bob_data.quickview_items == nil,
        'Bob (visitor) must NOT see quickview items due to cache isolation')

    -- 3. Verify Alice still sees her cached quickview items
    local alice_data2 = waysigns.get_node_infotext_data(chest_pos, chest_node, alice_player)
    assert(alice_data2.quickview_items ~= nil and #alice_data2.quickview_items == 1,
        'Alice must still see her diamond quickview upon immediate re-query')

    core.get_meta = orig_get_meta
    print('PASS Test 61')
end)()

print('--- Test 62: Bounded FIFO cache eviction (MAX_TEXTURE_CACHE & MAX_NODE_CACHE) ---')
;(function()
    waysigns.clear_caches()
    -- 1. Test texture cache bounds
    waysigns.MAX_TEXTURE_CACHE = 10 -- Temporarily lower bound for fast test
    for i = 1, 15 do
        waysigns.set_cached_texture('key_' .. i, 'tex_' .. i)
    end
    -- Keys 1..5 should have been evicted, 6..15 should exist
    for i = 1, 5 do
        assert(waysigns.texture_cache['key_' .. i] == nil, 'Oldest texture key_' .. i .. ' should have been evicted')
    end
    for i = 6, 15 do
        assert(waysigns.texture_cache['key_' .. i] == 'tex_' .. i, 'Recent texture key_' .. i .. ' must remain cached')
    end
    waysigns.MAX_TEXTURE_CACHE = 500

    -- 2. Test node cache bounds
    waysigns.MAX_NODE_CACHE = 10 -- Temporarily lower bound for fast test
    for i = 1, 15 do
        waysigns.set_cached_node('node_key_' .. i, { id = i })
    end
    for i = 1, 5 do
        assert(waysigns.node_cache['node_key_' .. i] == nil, 'Oldest node_key_' .. i .. ' should have been evicted')
    end
    for i = 6, 15 do
        assert(waysigns.node_cache['node_key_' .. i] ~= nil and waysigns.node_cache['node_key_' .. i].id == i,
            'Recent node_key_' .. i .. ' must remain cached')
    end
    waysigns.MAX_NODE_CACHE = 1000

    print('PASS Test 62')
end)()

print('--- Test 63: Node inscription, metadata priority, plaque styles & cache invalidation ---')
;(function()
    waysigns.clear_caches()
    core.registered_nodes['default:stone'] = {
        description = 'Stone',
        tiles = { 'default_stone.png' },
    }
    local pos = { x = 15, y = 2, z = 35 }
    local node = { name = 'default:stone', param2 = 0 }

    -- Verify node starts with no inscription
    local empty_inscr = waysigns.get_node_inscription(pos)
    assert(empty_inscr == nil, 'Expected no inscription initially')

    -- Inscribe node with custom slate plaque and radiant gold text
    waysigns.set_node_inscription(pos, "Vault Entrance\nAuthorized Personnel Only", "slate", "gold", "alice")

    -- Verify stored metadata
    local meta = core.get_meta(pos)
    assert(meta:get_string('waysigns_text') == "Vault Entrance\nAuthorized Personnel Only", 'Expected waysigns_text')
    assert(meta:get_string('waysigns_plaque') == 'slate', 'Expected waysigns_plaque slate')
    assert(meta:get_string('waysigns_color') == 'gold', 'Expected waysigns_color gold')
    assert(meta:get_string('waysigns_author') == 'alice', 'Expected waysigns_author alice')

    -- Verify helper getter
    local read_inscr = waysigns.get_node_inscription(pos)
    assert(read_inscr ~= nil, 'Expected get_node_inscription to return table')
    assert(read_inscr.text == "Vault Entrance\nAuthorized Personnel Only", 'Text mismatch')
    assert(read_inscr.plaque == 'slate', 'Plaque mismatch')
    assert(read_inscr.color == 'gold', 'Color mismatch')
    assert(read_inscr.author == 'alice', 'Author mismatch')

    -- Verify extract_text priority: waysigns_text overrides any other metadata keys (infotext, text)
    meta:set_string('infotext', 'Conflicting Infotext')
    meta:set_string('text', 'Conflicting Text')
    assert(waysigns.extract_text(meta) == "Vault Entrance\nAuthorized Personnel Only",
        'waysigns_text must take highest priority in extract_text')

    -- Verify get_sign_data recognizes inscribed ordinary node and applies chosen plaque & color
    local sign_data = waysigns.get_sign_data(pos, node)
    assert(sign_data ~= nil, 'get_sign_data should recognize inscribed node')
    assert(sign_data.tile == 'waysigns_sign_slate.png', 'Expected custom slate plaque texture, got ' .. tostring(sign_data.tile))
    assert(sign_data.text_color == 0xFFD700, 'Expected gold text color 0xFFD700, got ' .. string.format('0x%06X', sign_data.text_color))
    assert(sign_data.aspect_ratio == 1.4, 'Expected standard 1.4 plaque aspect ratio')

    -- Test plaque option fallbacks
    -- 1. Wood plaque
    waysigns.set_node_inscription(pos, "Wood Sign", "wood", "white", "alice")
    local wood_data = waysigns.get_sign_data(pos, node)
    assert(wood_data.tile == 'waysigns_sign_wood.png', 'Expected waysigns_sign_wood.png')
    assert(wood_data.text_color == 0xFFFFFF, 'Expected white text color')

    -- 2. Steel plaque
    waysigns.set_node_inscription(pos, "Steel Sign", "steel", "cyan", "alice")
    local steel_data = waysigns.get_sign_data(pos, node)
    assert(steel_data.tile == 'waysigns_sign_steel.png', 'Expected waysigns_sign_steel.png')
    assert(steel_data.text_color == 0x00E5FF, 'Expected cyan text color')

    -- 3. Gold plaque
    waysigns.set_node_inscription(pos, "Royal Sign", "gold", "green", "alice")
    local gold_data = waysigns.get_sign_data(pos, node)
    assert(gold_data.tile == 'waysigns_sign_gold.png', 'Expected waysigns_sign_gold.png')
    assert(gold_data.text_color == 0x76FF03, 'Expected lime green text color')

    -- 4. Glass plaque
    waysigns.set_node_inscription(pos, "Glass Notice", "glass", "red", "alice")
    local glass_data = waysigns.get_sign_data(pos, node)
    assert(glass_data.tile == 'waysigns_sign_glass.png', 'Expected waysigns_sign_glass.png')
    assert(glass_data.text_color == 0xFF5252, 'Expected crimson red text color')

    -- 5. Default plaque: falls back to node texture (default_stone.png)
    waysigns.set_node_inscription(pos, "Default Plaque", "default", "dark", "alice")
    local def_data = waysigns.get_sign_data(pos, node)
    assert(def_data.tile == 'default_stone.png', 'Default plaque should use node tile default_stone.png')
    assert(def_data.text_color == 0x222222, 'Expected dark text color')

    -- Test cache invalidation
    local hash = core.hash_node_position(pos)
    assert(waysigns.node_cache[hash] ~= nil, 'get_sign_data should have populated node cache')
    waysigns.set_node_inscription(pos, "Updated Inscription", "wood", "white", "alice")
    assert(waysigns.node_cache[hash] == nil, 'set_node_inscription must invalidate node cache')

    print('PASS Test 63')
end)()

print('--- Test 64: Entity inscription, get_entity_inscription_data & collisionbox waypoint positioning ---')
;(function()
    local entity_pos = { x = 50, y = 10, z = 75 }
    local mock_ent = { name = 'mobs_npc:trader' }
    local mock_obj = {
        _is_valid = true,
        _pos = entity_pos,
        infotext = '',
        is_player = function(self) return false end,
        is_valid = function(self) return self._is_valid end,
        get_pos = function(self) return self._pos end,
        get_properties = function(self)
            return {
                collisionbox = { -0.35, 0.0, -0.35, 0.35, 1.8, 0.35 }
            }
        end,
        set_properties = function(self, props)
            if props.infotext ~= nil then
                self.infotext = props.infotext
            end
        end,
        get_luaentity = function(self)
            return mock_ent
        end,
    }

    -- Verify entity starts un-inscribed
    assert(waysigns.get_entity_inscription(mock_obj) == nil, 'Entity should have no inscription initially')
    assert(waysigns.get_entity_inscription_data(mock_obj) == nil, 'Entity data should be nil without inscription')

    -- Inscribe entity
    waysigns.set_entity_inscription(mock_obj, "Merchant Bob\nRare Minerals & Potions", "gold", "cyan", "alice")

    -- Verify object internal fields and infotext property
    assert(mock_obj._waysigns_text == "Merchant Bob\nRare Minerals & Potions", 'Entity _waysigns_text mismatch')
    assert(mock_obj._waysigns_plaque == 'gold', 'Entity _waysigns_plaque mismatch')
    assert(mock_obj._waysigns_color == 'cyan', 'Entity _waysigns_color mismatch')
    assert(mock_obj._waysigns_author == 'alice', 'Entity _waysigns_author mismatch')
    assert(mock_obj.infotext == "Merchant Bob\nRare Minerals & Potions", 'Entity infotext property should be updated')

    -- Verify get_entity_inscription helper
    local inscr = waysigns.get_entity_inscription(mock_obj)
    assert(inscr ~= nil, 'get_entity_inscription returned nil')
    assert(inscr.text == "Merchant Bob\nRare Minerals & Potions")
    assert(inscr.plaque == 'gold')
    assert(inscr.color == 'cyan')
    assert(inscr.author == 'alice')

    -- Verify get_entity_inscription_data resolution
    local data = waysigns.get_entity_inscription_data(mock_obj)
    assert(data ~= nil, 'get_entity_inscription_data returned nil')
    assert(data.text == "Merchant Bob\nRare Minerals & Potions")
    assert(data.tile == 'waysigns_sign_gold.png', 'Expected gold plaque tile')
    assert(data.text_color == 0x00E5FF, 'Expected cyan text color 0x00E5FF')
    assert(#data.pages == 1, 'Expected 1 page')
    assert(#data.pages[1] == 2, 'Expected 2 lines on page 1')

    -- Verify 3D waypoint position anchored above entity collisionbox:
    -- entity_pos.y (10) + collisionbox max_y (1.8) + offset (0.35) = 12.15
    assert(data.face_pos ~= nil, 'Expected face_pos')
    assert(data.face_pos.x == 50, 'face_pos x mismatch')
    assert(math.abs(data.face_pos.y - 12.15) < 0.001, 'Expected face_pos y = 12.15, got ' .. tostring(data.face_pos.y))
    assert(data.face_pos.z == 75, 'face_pos z mismatch')

    -- Test default plaque for entities (falls back to neutral wood)
    waysigns.set_entity_inscription(mock_obj, "Default Plaque Entity", "default", "white", "alice")
    local ent_def_data = waysigns.get_entity_inscription_data(mock_obj)
    assert(ent_def_data.tile == 'waysigns_sign_wood.png', 'Entity default plaque should fall back to waysigns_sign_wood.png')

    print('PASS Test 64')
end)()

print('--- Test 65: Marker tool registration, crafting, protection checks & durability ---')
;(function()
    -- 1. Tool registration & properties
    local marker_tool = core.registered_tools['waysigns:marker']
    assert(marker_tool ~= nil, 'waysigns:marker tool must be registered')
    assert(marker_tool.inventory_image == 'waysigns_marker.png', 'Marker inventory_image must be waysigns_marker.png')
    assert(marker_tool.wield_image == 'waysigns_marker.png^[transformR270', 'Marker wield_image must be rotated 270 deg (^[transformR270)')
    assert(marker_tool.groups and marker_tool.groups.tool == 1, 'Marker must be in tool group')

    -- 2. Shapeless craft recipe registration
    local found_craft = false
    for _, craft in ipairs(core.registered_crafts) do
        if craft.output == 'waysigns:marker' and craft.type == 'shapeless' then
            local r = craft.recipe
            assert(#r == 3, 'Craft recipe must have 3 ingredients')
            assert(r[1] == 'default:coal_lump' and r[2] == 'default:steel_ingot' and r[3] == 'group:stick',
                'Recipe ingredients must match coal + steel + stick')
            found_craft = true
            break
        end
    end
    assert(found_craft, 'Craft recipe for waysigns:marker must be registered')

    -- 3. Area protection enforcement on use
    local target_pos = { x = 100, y = 20, z = 100 }
    local pointed_node = { type = 'node', under = target_pos }

    local intruder_player = {
        name = 'bob_intruder',
        get_player_name = function(self) return self.name end,
        is_player = function(self) return true end,
        get_player_control = function() return {} end,
        privs = {},
    }

    local owner_player = {
        name = 'alice_owner',
        get_player_name = function(self) return self.name end,
        is_player = function(self) return true end,
        get_player_control = function() return {} end,
        privs = {},
        wielded = ItemStack({ name = 'waysigns:marker', count = 1, wear = 0 }),
        get_wielded_item = function(self) return self.wielded end,
        set_wielded_item = function(self, stack) self.wielded = stack end,
    }

    _G.last_shown_formspec = nil
    _G.last_protection_violation = nil
    local orig_is_protected = core.is_protected
    core.is_protected = function(pos, player_name)
        return player_name == 'bob_intruder'
    end

    -- Bob (intruder) right clicks protected node -> blocked
    local stack_bob = ItemStack('waysigns:marker')
    marker_tool.on_place(stack_bob, intruder_player, pointed_node)
    assert(_G.last_shown_formspec == nil, 'Formspec must NOT open for intruder on protected node')
    assert(_G.last_protection_violation ~= nil and _G.last_protection_violation.player_name == 'bob_intruder',
        'Protection violation must be recorded for intruder')

    -- Alice (owner) right clicks -> permitted, formspec opens
    _G.last_protection_violation = nil
    marker_tool.on_place(owner_player.wielded, owner_player, pointed_node)
    assert(_G.last_shown_formspec ~= nil, 'Formspec must open for owner')
    assert(_G.last_shown_formspec.formname == 'waysigns:inscribe', 'Formname must be waysigns:inscribe')
    assert(_G.last_shown_formspec.player_name == 'alice_owner', 'Player name mismatch in formspec')

    -- Verify latest formspec version 6 and modern styled layout
    local fs = _G.last_shown_formspec.formspec
    assert(fs:find('formspec_version%[6%]'), 'Formspec must use formspec_version[6]')
    assert(fs:find('size%[10.2,9.6%]'), 'Formspec size must be 10.2x9.6')
    assert(fs:find('image%[0.40,0.22;0.50,0.50;waysigns_marker.png%]'), 'Header missing marker icon')
    assert(fs:find('button_exit%[9.40,0.20;0.55,0.55;close_btn;✕%]'), 'Top-right "X" close button missing or not button_exit')
    assert(fs:find('style%[save:hovered;'), 'Save button missing hovered style')
    assert(fs:find('style%[save:pressed;'), 'Save button missing pressed style')
    assert(fs:find('style%[erase:hovered;'), 'Erase button missing hovered style')
    assert(fs:find('style%[erase:pressed;'), 'Erase button missing pressed style')
    assert(fs:find('style%[cancel:hovered;'), 'Cancel button missing hovered style')
    assert(fs:find('style%[cancel:pressed;'), 'Cancel button missing pressed style')
    assert(fs:find('style_type%[button,button_exit;border=true;content_offset=0;font=bold%]'), 'Button style_type must have border=true for bgcolor rendering')
    assert(fs:find('style%[save;border=true;bgcolor=#2e7d32'), 'Save button must have border=true and bgcolor')
    assert(fs:find('style%[erase;border=true;bgcolor=#7f1d1d'), 'Erase button must have border=true and bgcolor')
    assert(fs:find('style%[cancel;border=true;bgcolor=#374151'), 'Cancel button must have border=true and bgcolor')
    assert(fs:find('style%[check_len;border=true;bgcolor=#242834'), 'Check button must have border=true and bgcolor')
    assert(fs:find('style%[close_btn;border=false'), 'Close button must have border=false for flat look')
    assert(fs:find('style_type%[button:pressed,button_exit:pressed;content_offset=0,1%]'), 'Tactile button depression missing')
    assert(fs:find('Inscription Text %(max 250 chars%):'), 'Formspec missing explicit limit in label (max 250 chars)')
    assert(fs:find('button%[6.30,1.15;1.20,0.42;check_len;Check%]'), 'Formspec missing Check button')
    assert(fs:find('label%[7.65,1.35;'), 'Formspec missing character counter label')
    assert(fs:find('0 / 250 chars'), 'Live character counter must display initial 0 / 250 chars')
    assert(fs:find('textarea%[0.50,1.65;9.20,1.85;inscription;;%]'), 'Formspec missing modern textarea')
    assert(fs:find('image_button%[0.50,4.10;1.30,1.05;.-;plaque_sel_default;%]'), 'Default plaque thumbnail swatch missing')
    assert(fs:find('image_button%[2.08,4.10;1.30,1.05;waysigns_sign_wood.png;plaque_sel_wood;%]'), 'Wood plaque thumbnail swatch missing')
    assert(fs:find('image_button%[3.66,4.10;1.30,1.05;waysigns_sign_steel.png;plaque_sel_steel;%]'), 'Steel plaque thumbnail swatch missing')
    assert(fs:find('image_button%[5.24,4.10;1.30,1.05;waysigns_sign_slate.png;plaque_sel_slate;%]'), 'Slate plaque thumbnail swatch missing')
    assert(fs:find('image_button%[6.82,4.10;1.30,1.05;waysigns_sign_gold.png;plaque_sel_gold;%]'), 'Gold plaque thumbnail swatch missing')
    assert(fs:find('image_button%[8.40,4.10;1.30,1.05;waysigns_sign_glass.png;plaque_sel_glass;%]'), 'Glass plaque thumbnail swatch missing')

    -- Plaque and color dropdowns must be completely removed in favor of thumbnails
    assert(not fs:find('dropdown%['), 'Dropdowns must be removed from the formspec')

    -- Color swatches must use dynamic [fill:32x32:<hex> image_button textures instead of grey buttons
    assert(fs:find('image_button%[0.50,5.95;0.95,0.90;%[fill:32x32:#FFFFFF;color_sel_white;%]'), 'White color swatch with [fill:32x32: missing')
    assert(fs:find('image_button%[1.65,5.95;0.95,0.90;%[fill:32x32:#FFD700;color_sel_gold;%]'), 'Gold color swatch with [fill:32x32: missing')
    assert(fs:find('image_button%[2.80,5.95;0.95,0.90;%[fill:32x32:#00E5FF;color_sel_cyan;%]'), 'Cyan color swatch with [fill:32x32: missing')
    assert(fs:find('image_button%[0.50,7.00;0.95,0.90;%[fill:32x32:#76FF03;color_sel_green;%]'), 'Green color swatch with [fill:32x32: missing')
    assert(fs:find('image_button%[1.65,7.00;0.95,0.90;%[fill:32x32:#FF5252;color_sel_red;%]'), 'Red color swatch with [fill:32x32: missing')
    assert(fs:find('image_button%[2.80,7.00;0.95,0.90;%[fill:32x32:#222222;color_sel_dark;%]'), 'Dark walnut color swatch with [fill:32x32: missing')

    assert(fs:find('Live Plaque Preview:'), 'Live plaque preview card missing')
    assert(fs:find('button_exit%[7.30,8.50;2.40,0.80;cancel;Cancel%]'), 'Cancel button must be button_exit to close dialog')

    -- 4. Test interactive plaque thumbnail click (updates preview, character counter, and golden halo)
    local receive_cb = core.registered_on_player_receive_fields[1]
    assert(receive_cb ~= nil, 'receive_fields callback must be registered')
    receive_cb(owner_player, 'waysigns:inscribe', { plaque_sel_steel = '', inscription = 'Fortress Guard' })
    local updated_fs = _G.last_shown_formspec.formspec
    assert(updated_fs:find('box%[3.61,4.05;1.40,1.15;#ffd700%]'), 'Steel swatch must have golden halo when selected')
    assert(updated_fs:find('image%[4.30,6.05;5.30,1.80;waysigns_sign_steel.png%]'), 'Live preview must display steel plaque texture')
    assert(updated_fs:find('Fortress Guard'), 'Live preview must display updated inscription text')
    assert(updated_fs:find('14 / 250 chars'), 'Live character counter must update to 14 / 250 chars')

    -- 4b. Test color swatch click updates preview color and golden halo immediately
    receive_cb(owner_player, 'waysigns:inscribe', { color_sel_green = '' })
    local green_fs = _G.last_shown_formspec.formspec
    assert(green_fs:find('c@#76FF03%)Fortress Guard'), 'Live preview text must update to Lime Green (#76FF03)')
    assert(green_fs:find('box%[0.46,6.96;1.05,0.98;#ffd700%]'), 'Lime green color swatch must have golden halo')

    -- 4c. Test color palette swatch click (Cyan)
    receive_cb(owner_player, 'waysigns:inscribe', { color_sel_cyan = '' })
    local cyan_fs = _G.last_shown_formspec.formspec
    assert(cyan_fs:find('c@#00E5FF%)Fortress Guard'), 'Live preview text must update to Cyan (#00E5FF)')
    assert(cyan_fs:find('box%[2.76,5.91;1.05,0.98;#ffd700%]'), 'Cyan color swatch must have golden halo')

    -- 4d. Test gold plaque thumbnail swatch click
    receive_cb(owner_player, 'waysigns:inscribe', { plaque_sel_gold = '' })
    local gold_plaque_fs = _G.last_shown_formspec.formspec
    assert(gold_plaque_fs:find('image%[4.30,6.05;5.30,1.80;waysigns_sign_gold.png%]'), 'Live preview must update to Gold plaque texture')
    assert(gold_plaque_fs:find('box%[6.77,4.05;1.40,1.15;#ffd700%]'), 'Gold swatch must have golden halo')

    -- 4e. Test wood plaque thumbnail swatch click
    receive_cb(owner_player, 'waysigns:inscribe', { plaque_sel_wood = '' })
    local wood_plaque_fs = _G.last_shown_formspec.formspec
    assert(wood_plaque_fs:find('image%[4.30,6.05;5.30,1.80;waysigns_sign_wood.png%]'), 'Live preview must update to Wood plaque texture')
    assert(wood_plaque_fs:find('box%[2.03,4.05;1.40,1.15;#ffd700%]'), 'Wood swatch must have golden halo')

    -- 4f. Test frosted glass plaque thumbnail swatch click
    receive_cb(owner_player, 'waysigns:inscribe', { plaque_sel_glass = '' })
    local glass_plaque_fs = _G.last_shown_formspec.formspec
    assert(glass_plaque_fs:find('image%[4.30,6.05;5.30,1.80;waysigns_sign_glass.png%]'), 'Live preview must update to Glass plaque texture')
    assert(glass_plaque_fs:find('box%[8.35,4.05;1.40,1.15;#ffd700%]'), 'Glass swatch must have golden halo')

    -- 4g. Test Check button synchronizes typed text, counter, and live preview on demand
    receive_cb(owner_player, 'waysigns:inscribe', { check_len = 'Check', inscription = 'Quick Check Preview' })
    local check_fs = _G.last_shown_formspec.formspec
    assert(check_fs:find('19 / 250 chars'), 'Check button must synchronize character counter to 19 / 250 chars')
    assert(check_fs:find('Quick Check Preview'), 'Check button must update live preview with typed text')

    -- 4h. Test character counter warning (>= 90%) and exceeded (> max) colorization
    receive_cb(owner_player, 'waysigns:inscribe', { color_sel_cyan = '', inscription = string.rep('x', 225) })
    local warn_fs = _G.last_shown_formspec.formspec
    assert(warn_fs:find('c@#ffd700%)225 / 250 chars'), 'Counter must turn gold (#ffd700) when >= 90% max chars')

    receive_cb(owner_player, 'waysigns:inscribe', { color_sel_cyan = '', inscription = string.rep('x', 255) })
    local exceed_fs = _G.last_shown_formspec.formspec
    assert(exceed_fs:find('c@#ff5252%)255 / 250 %(Too long!%)'), 'Counter must turn red (#ff5252) and show (Too long!)')

    -- 4i. Test Smart Validation on Save (Option 2A): reject & re-open with warning when exceeding max chars
    _G.last_chat_message = nil
    local too_long_text = string.rep('W', 260)
    receive_cb(owner_player, 'waysigns:inscribe', { save = 'Save Inscription', inscription = too_long_text })
    local rejected_fs = _G.last_shown_formspec.formspec
    assert(rejected_fs:find('c@#ff5252%)260 / 250 %(Too long!%)'), 'Editor must re-open with red warning when exceeding max chars on save')
    assert(_G.last_chat_message ~= nil and _G.last_chat_message.message:find('exceeds maximum length of 250 characters'),
        'Chat warning must be sent on exceeding max characters on save')
    local meta_before_save = core.get_meta(target_pos)
    assert(meta_before_save:get_string('waysigns_text') ~= too_long_text, 'Node metadata must NOT be saved when exceeding limit')
    assert(owner_player.wielded:get_wear() == 0, 'Wear must NOT be consumed when saving exceeds limit')

    -- 5. Test Cancel button closes formspec
    _G.last_closed_formspec = nil
    receive_cb(owner_player, 'waysigns:inscribe', { cancel = 'Cancel' })
    assert(_G.last_closed_formspec ~= nil and _G.last_closed_formspec.player_name == 'alice_owner' and _G.last_closed_formspec.formname == 'waysigns:inscribe',
        'Cancel button must call core.close_formspec')

    -- 6. Test top-right "X" button closes formspec
    marker_tool.on_place(owner_player.wielded, owner_player, pointed_node)
    _G.last_closed_formspec = nil
    receive_cb(owner_player, 'waysigns:inscribe', { close_btn = '✕' })
    assert(_G.last_closed_formspec ~= nil and _G.last_closed_formspec.player_name == 'alice_owner' and _G.last_closed_formspec.formname == 'waysigns:inscribe',
        'Top-right close button must call core.close_formspec')

    -- 7. Submit formspec: protection check on receive_fields (TOCTOU protection)

    -- Bob opened formspec before protection was set
    core.is_protected = function(pos, player_name) return false end
    marker_tool.on_place(stack_bob, intruder_player, pointed_node)
    assert(_G.last_shown_formspec ~= nil, 'Formspec opened when area was unprotected')

    -- Area is now protected against Bob
    core.is_protected = function(pos, player_name) return player_name == 'bob_intruder' end
    _G.last_protection_violation = nil
    receive_cb(intruder_player, 'waysigns:inscribe', { save = 'Save Inscription', inscription = 'Hacked!' })
    assert(_G.last_protection_violation ~= nil and _G.last_protection_violation.player_name == 'bob_intruder',
        'Submit from intruder on newly-protected node must trigger protection violation')

    -- Alice (owner) re-opens formspec and submits valid inscription
    marker_tool.on_place(owner_player.wielded, owner_player, pointed_node)
    _G.last_sound_play = nil
    local initial_wear = owner_player.wielded:get_wear()
    assert(initial_wear == 0, 'Initial wear should be 0')

    receive_cb(owner_player, 'waysigns:inscribe', {
        save = 'Save Inscription',
        inscription = 'Safe Haven',
        plaque = 'Steel Plaque',
        color = 'Warm Gold'
    })

    -- Verify metadata written
    local meta = core.get_meta(target_pos)
    assert(meta:get_string('waysigns_text') == 'Safe Haven', 'waysigns_text should be Safe Haven')
    assert(meta:get_string('waysigns_plaque') == 'steel', 'waysigns_plaque should be steel')
    assert(meta:get_string('waysigns_color') == 'gold', 'waysigns_color should be gold')
    assert(meta:get_string('waysigns_author') == 'alice_owner', 'waysigns_author should be alice_owner')

    -- Verify durability wear applied (1 use out of 100 = 655 wear)
    local new_wear = owner_player.wielded:get_wear()
    assert(new_wear == math.floor(65535 / 100), 'Expected 1 use of wear (655), got ' .. new_wear)
    assert(_G.last_sound_play ~= nil and _G.last_sound_play.sound == 'default_place_node', 'Expected placement sound')

    core.is_protected = orig_is_protected
    print('PASS Test 65')
end)()

print('--- Test 66: Inscription erasing & zero durability consumption ---')
;(function()
    local target_pos = { x = 110, y = 20, z = 110 }
    waysigns.set_node_inscription(target_pos, "Temporary Note", "wood", "white", "alice_owner")

    local owner_player = {
        name = 'alice_owner',
        get_player_name = function(self) return self.name end,
        is_player = function(self) return true end,
        get_player_control = function() return {} end,
        privs = {},
        wielded = ItemStack({ name = 'waysigns:marker', count = 1, wear = 1500 }),
        get_wielded_item = function(self) return self.wielded end,
        set_wielded_item = function(self, stack) self.wielded = stack end,
    }

    local marker_tool = core.registered_tools['waysigns:marker']
    local pointed_node = { type = 'node', under = target_pos }

    -- 1. Open formspec on node
    marker_tool.on_place(owner_player.wielded, owner_player, pointed_node)

    -- 2. Click Erase
    local receive_cb = core.registered_on_player_receive_fields[1]
    receive_cb(owner_player, 'waysigns:inscribe', { erase = 'Erase' })

    -- Verify node metadata is cleared
    local meta = core.get_meta(target_pos)
    assert(meta:get_string('waysigns_text') == '', 'waysigns_text must be empty string after erase')
    assert(waysigns.get_node_inscription(target_pos) == nil, 'get_node_inscription must return nil after erase')

    -- Verify tool durability: MUST NOT CONSUME WEAR ON ERASE
    assert(owner_player.wielded:get_wear() == 1500,
        'Erasing must consume 0 wear, wear remained ' .. owner_player.wielded:get_wear())

    -- 3. Test entity erasing
    local mock_obj = {
        _is_valid = true,
        _pos = { x = 110, y = 21, z = 110 },
        infotext = 'Guard Robot',
        is_player = function(self) return false end,
        is_valid = function(self) return self._is_valid end,
        get_pos = function(self) return self._pos end,
        get_properties = function(self) return {} end,
        set_properties = function(self, props) if props.infotext ~= nil then self.infotext = props.infotext end end,
        get_luaentity = function(self) return { name = 'mobs:guard' } end,
    }
    waysigns.set_entity_inscription(mock_obj, "Guard Robot", "steel", "red", "alice_owner")
    assert(waysigns.get_entity_inscription(mock_obj) ~= nil, 'Entity must have inscription')

    -- Open formspec on entity
    local pointed_obj = { type = 'object', ref = mock_obj }
    marker_tool.on_place(owner_player.wielded, owner_player, pointed_obj)

    -- Click Erase
    receive_cb(owner_player, 'waysigns:inscribe', { erase = 'Erase' })

    -- Verify entity fields and infotext cleared
    assert(waysigns.get_entity_inscription(mock_obj) == nil, 'Entity inscription must be nil after erase')
    assert(mock_obj.infotext == '', 'Entity infotext property must be cleared')
    assert(owner_player.wielded:get_wear() == 1500, 'Erasing entity must consume 0 wear')

    print('PASS Test 66')
end)()

print('--- Test 67: Scribe Sense - Marker-Wield Proximity Waypoints ---')
;(function()
    local orig_raycast = core.raycast
    core.raycast = function() return function() return nil end end
    local orig_get_objects = core.get_objects_inside_radius
    core.get_objects_inside_radius = function(pos, r)
        return _G.mock_objects or {}
    end

    -- 1. Spatial Registry persistence and key generation
    local p1 = { x = 10, y = 5, z = 20 }
    local k1 = waysigns.pos_to_key(p1)
    assert(k1 == '10,5,20', 'Key format must be X,Y,Z integer coordinates, got: ' .. tostring(k1))

    waysigns.register_inscribed_pos(p1, { author = 'alice', plaque = 'wood', color = 'gold' })
    local entry = waysigns.get_inscribed_pos(p1)
    assert(entry ~= nil, 'Entry must be in spatial registry')
    assert(entry.plaque == 'wood' and entry.color == 'gold' and entry.author == 'alice', 'Entry metadata mismatch')

    -- Persistence test: save and reload from mod storage
    waysigns.save_inscribed_registry()
    waysigns.inscribed_blocks = {}
    assert(waysigns.get_inscribed_pos(p1) == nil, 'Registry must be empty after reset')
    waysigns.load_inscribed_registry()
    assert(waysigns.get_inscribed_pos(p1) ~= nil, 'Registry must restore from mod storage')

    -- 2. Dig node / destruction unregistration
    waysigns.on_dignode(p1)
    assert(waysigns.get_inscribed_pos(p1) == nil, 'on_dignode must unregister position from spatial index')

    -- 3. Self-healing on get_node_inscription
    local p2 = { x = 15, y = 2, z = 15 }
    local meta2 = core.get_meta(p2)
    meta2:set_string('waysigns_text', 'Ancient Relic')
    meta2:set_string('waysigns_plaque', 'slate')
    meta2:set_string('waysigns_color', 'cyan')
    meta2:set_string('waysigns_author', 'sense_tester')
    assert(waysigns.get_inscribed_pos(p2) == nil, 'Initially not in spatial registry')
    local insc = waysigns.get_node_inscription(p2)
    assert(insc ~= nil and insc.text == 'Ancient Relic', 'Must return valid inscription')
    assert(waysigns.get_inscribed_pos(p2) ~= nil, 'get_node_inscription must self-heal spatial registry')

    -- 4. Proximity Waypoints Lifecycle & Marker Wield Detection
    local sense_player = {
        name = 'sense_tester',
        pos = { x = 15, y = 2, z = 10 }, -- 5m away from p2 (15, 2, 15)
        look_dir = { x = 0, y = 0, z = 1 },
        wielded = ItemStack({ name = 'default:pick_steel', count = 1 }),
        hud_adds = {},
        hud_removes = {},
        hud_changes = {},
        get_player_name = function(self) return self.name end,
        is_player = function(self) return true end,
        is_valid = function(self) return true end,
        get_pos = function(self) return self.pos end,
        get_look_dir = function(self) return self.look_dir end,
        get_properties = function(self) return { eye_height = 1.625 } end,
        get_wielded_item = function(self) return self.wielded end,
        hud_add = function(self, def)
            table.insert(self.hud_adds, def)
            return #self.hud_adds
        end,
        hud_remove = function(self, id)
            table.insert(self.hud_removes, id)
        end,
        hud_change = function(self, id, stat, val)
            table.insert(self.hud_changes, { id = id, stat = stat, val = val })
        end,
    }

    -- Far-away node at (100, 2, 100)
    local p_far = { x = 100, y = 2, z = 100 }
    waysigns.set_node_inscription(p_far, 'Far away temple', 'gold', 'white', 'monk')

    -- Nearby inscribed entity at (17, 2, 12) (distance ~3m from player)
    local luaent_table = { name = 'npc:trader' }
    local mock_ent = {
        _is_valid = true,
        _pos = { x = 17, y = 2, z = 12 },
        is_player = function(self) return false end,
        is_valid = function(self) return self._is_valid end,
        get_pos = function(self) return self._pos end,
        get_properties = function(self) return {} end,
        set_properties = function(self, _) end,
        get_luaentity = function(self) return luaent_table end,
    }
    waysigns.set_entity_inscription(mock_ent, 'Trader Joe', 'wood', 'gold', 'admin')
    _G.mock_objects = { mock_ent }

    local pstate = waysigns.get_or_create_player_state(sense_player)

    -- Case 4A: Player wields pickaxe (not marker) -> NO waypoints should be created
    waysigns.update_player(sense_player, 0.2)
    assert(#sense_player.hud_adds == 0, 'No waypoints should be added when wielding pickaxe')
    assert(next(pstate.marker_waypoints) == nil, 'marker_waypoints table must be empty')

    -- Case 4B: Player equips waysigns:marker -> Proximity waypoints appear
    sense_player.wielded = ItemStack({ name = 'waysigns:marker', count = 1 })
    waysigns.update_player(sense_player, 0.2)

    assert(#sense_player.hud_adds >= 2, 'Must create waypoints for nearby node and nearby entity, got adds: ' .. #sense_player.hud_adds)
    local wp_node = pstate.marker_waypoints['15,2,15']
    assert(wp_node ~= nil, 'Waypoint for nearby node must exist')
    assert(sense_player.hud_adds[wp_node.hud_id].type == 'image_waypoint', 'HUD type must be image_waypoint')
    assert(sense_player.hud_adds[wp_node.hud_id].text:find('waysigns_waypoint.png%^%[opacity:'), 'Must use waypoint beacon icon with opacity modifier')
    assert(sense_player.hud_adds[wp_node.hud_id].scale and sense_player.hud_adds[wp_node.hud_id].scale.x >= 3.0,
        'Marker waypoint scale must be scaled up for visibility (>= 3.0)')
    assert(sense_player.hud_adds[wp_node.hud_id].z_index == -350,
        'Must have z_index -350 (rendered behind sign/infotext plaques at -300 and text at -290)')

    -- Far-away node must NOT have a waypoint
    assert(pstate.marker_waypoints['100,2,100'] == nil, 'Far-away node must not be in waypoints')

    -- Nearby entity must have a waypoint
    local ent_key = 'ent_' .. tostring(mock_ent)
    local wp_ent = pstate.marker_waypoints[ent_key]
    assert(wp_ent ~= nil, 'Entity waypoint must exist')

    -- Distance-based opacity progression check:
    -- Node at (15, 2, 15) is ~5.09m away from player eye; entity at (17, 2, 12) is ~2.96m away
    -- Closer markers have lower translucency (higher opacity); distant markers are progressively more translucent (lower opacity)
    local node_tex = sense_player.hud_adds[wp_node.hud_id].text
    local ent_tex = sense_player.hud_adds[wp_ent.hud_id].text
    local node_op = tonumber(node_tex:match('%^%[opacity:(%d+)'))
    local ent_op = tonumber(ent_tex:match('%^%[opacity:(%d+)'))
    assert(node_op ~= nil and ent_op ~= nil, 'Waypoints must have opacity modifier in texture string')
    assert(ent_op > node_op, string.format('Closer waypoint (op=%d) must have lower translucency (more opaque) than distant waypoint (op=%d)', ent_op, node_op))

    -- Dynamic scale update check
    waysigns.settings.marker_sense_scale = 5.0
    waysigns.update_player(sense_player, 0.2)
    local found_scale_change = false
    for _, ch in ipairs(sense_player.hud_changes) do
        if ch.id == wp_node.hud_id and ch.stat == 'scale' and ch.val and ch.val.x == 5.0 then
            found_scale_change = true
            break
        end
    end
    assert(found_scale_change, 'HUD scale change must be sent when marker_sense_scale changes')
    waysigns.settings.marker_sense_scale = 4.0

    -- View direction / FOV turnaround check:
    -- Add an inscribed node behind player (player is at 15, 2, 10, looking +Z)
    local p_behind = { x = 15, y = 2, z = 5 }
    waysigns.set_node_inscription(p_behind, 'Hidden Stash', 'slate', 'cyan', 'miner')

    -- Player looking forward (+Z): p2 is visible, p_behind is hidden
    waysigns.update_player(sense_player, 0.2)
    assert(pstate.marker_waypoints['15,2,15'] ~= nil, 'Target in front (+Z) must be visible')
    assert(pstate.marker_waypoints['15,2,5'] == nil, 'Target behind player must be hidden (out of sight)')

    -- Player turns around to look in -Z direction:
    sense_player.look_dir = { x = 0, y = 0, z = -1 }
    waysigns.update_player(sense_player, 0.2)
    -- Now p_behind is in sight and appears; p2 (15, 2, 15) is out of sight and hidden!
    assert(pstate.marker_waypoints['15,2,5'] ~= nil, 'Target now in sight (-Z) must appear')
    assert(pstate.marker_waypoints['15,2,15'] == nil, 'Target now out of sight must be hidden')

    -- Turn back to +Z
    sense_player.look_dir = { x = 0, y = 0, z = 1 }
    waysigns.update_player(sense_player, 0.2)
    assert(pstate.marker_waypoints['15,2,15'] ~= nil, 'Target restored when turning back')
    assert(pstate.marker_waypoints['15,2,5'] == nil, 'Target behind hidden again')
    waysigns.on_dignode(p_behind)

    -- Cap active proximity waypoints to nearest N targets (default 12)
    assert(waysigns.settings.marker_sense_max == 12, 'Default marker_sense_max must be 12')
    local cap_test_positions = {}
    for i = 1, 14 do
        local p_cap = { x = 8 + i, y = 2, z = 13 }
        waysigns.set_node_inscription(p_cap, 'Cap Node ' .. i, 'wood', 'white', 'tester')
        table.insert(cap_test_positions, p_cap)
    end
    waysigns.update_player(sense_player, 0.2)
    local active_count = 0
    for _ in pairs(pstate.marker_waypoints) do
        active_count = active_count + 1
    end
    assert(active_count <= waysigns.settings.marker_sense_max,
        string.format('Active waypoints count (%d) must not exceed marker_sense_max (%d)', active_count, waysigns.settings.marker_sense_max))
    assert(active_count == 12, string.format('Expected exactly 12 active waypoints when capped, got %d', active_count))
    for _, p_cap in ipairs(cap_test_positions) do
        waysigns.on_dignode(p_cap)
    end
    waysigns.update_player(sense_player, 0.2)

    -- Case 4C: Direct Gaze Suppression (when player aims directly at the sign)
    pstate.is_visible = true
    pstate.current_sign_pos = { x = 15, y = 2, z = 15 }
    waysigns.update_marker_waypoints(sense_player, pstate)

    -- Node waypoint should be suppressed so full plaque HUD takes center stage!
    assert(pstate.marker_waypoints['15,2,15'] == nil, 'Waypoint must be suppressed when looking directly at sign')
    -- Entity waypoint remains
    assert(pstate.marker_waypoints[ent_key] ~= nil, 'Entity waypoint should still remain visible')

    -- Stop looking directly at sign
    pstate.is_visible = false
    pstate.current_sign_pos = nil
    waysigns.update_marker_waypoints(sense_player, pstate)
    assert(pstate.marker_waypoints['15,2,15'] ~= nil, 'Waypoint restored after looking away')

    -- Case 4D: Line of sight obstruction
    core._line_of_sight_override = false
    waysigns.update_marker_waypoints(sense_player, pstate)
    assert(next(pstate.marker_waypoints) == nil, 'All waypoints must be suppressed when line of sight is blocked')
    core._line_of_sight_override = nil

    -- Restore waypoints with line of sight clear
    waysigns.update_marker_waypoints(sense_player, pstate)
    assert(pstate.marker_waypoints['15,2,15'] ~= nil, 'Waypoint restored with line of sight clear')

    -- Case 4E: Switching away from marker -> instant cleanup
    sense_player.wielded = ItemStack({ name = 'default:sword_diamond', count = 1 })
    local removes_before = #sense_player.hud_removes
    waysigns.update_player(sense_player, 0.2)
    assert(#sense_player.hud_removes > removes_before, 'Switching away from marker must remove HUD waypoints')
    assert(next(pstate.marker_waypoints) == nil, 'marker_waypoints must be empty after switching away')

    -- Case 4F: Death / Disconnect cleanup
    sense_player.wielded = ItemStack({ name = 'waysigns:marker', count = 1 })
    waysigns.update_player(sense_player, 0.2)
    assert(next(pstate.marker_waypoints) ~= nil, 'Waypoints active before death')

    waysigns.on_dieplayer(sense_player)
    assert(next(pstate.marker_waypoints) == nil, 'on_dieplayer must remove all marker waypoints')

    waysigns.update_player(sense_player, 0.2)
    assert(next(pstate.marker_waypoints) ~= nil, 'Waypoints active before leave')

    waysigns.on_leaveplayer(sense_player)
    assert(waysigns.players['sense_tester'] == nil, 'Player state must be nil after on_leaveplayer')

    _G.mock_objects = nil
    core.raycast = orig_raycast
    core.get_objects_inside_radius = orig_get_objects
    print('PASS Test 67')
end)()

print('--- Test 68: Inscribed nodes with infotext & inventory quickview overlay, and sign node exclusion from marker tool ---')
;(function()
    local function MockItemStack(name, count)
        return {
            is_empty = function(self) return (count or 0) <= 0 or (name or '') == '' end,
            get_name = function(self) return name or '' end,
            get_count = function(self) return count or 0 end,
            get_short_description = function(self) return nil end,
            get_description = function(self)
                local def = (core.registered_items and core.registered_items[name])
                    or (core.registered_nodes and core.registered_nodes[name])
                return def and def.description or name
            end,
        }
    end

    local function MockInventory(lists)
        return {
            get_list = function(self, name) return lists[name] end,
            get_lists = function(self) return lists end,
            is_empty = function(self, name)
                local l = lists[name]
                if not l then return true end
                for _, s in ipairs(l) do
                    if not s:is_empty() then return false end
                end
                return true
            end,
        }
    end

    core.registered_items['default:diamond'] = { description = 'Diamond', inventory_image = 'default_diamond.png' }
    core.registered_items['default:gold_ingot'] = { description = 'Gold Ingot', inventory_image = 'default_gold_ingot.png' }
    core.registered_items['default:steel_ingot'] = { description = 'Steel Ingot', inventory_image = 'default_steel_ingot.png' }

    -- 1. Sign Node Recognition & Exclusion from Inscription Tool
    local sign_wood = { name = 'default:sign_wall_wood', param2 = 4 }
    local sign_steel = { name = 'basic_signs:sign_wall_steel', param2 = 0 }
    local sign_aspen = { name = 'ucsigns:sign_aspen', param2 = 0 }
    local chest_node = { name = 'default:chest', param2 = 0 }
    local stone_node = { name = 'default:stone', param2 = 0 }
    local signal_wire = { name = 'mesecons:signal_wire', param2 = 0 }

    core.registered_nodes['basic_signs:sign_wall_steel'] = {
        description = 'Steel Wall Sign',
        drawtype = 'nodebox',
        groups = { sign = 1 },
    }
    core.registered_nodes['ucsigns:sign_aspen'] = {
        description = 'Aspen UCSign',
        drawtype = 'mesh',
        groups = { ucsign = 1 },
    }
    core.registered_nodes['mesecons:signal_wire'] = {
        description = 'Signal Wire',
        groups = { dig_immediate = 3 },
    }

    assert(waysigns.is_sign_node(sign_wood) == true, 'default:sign_wall_wood must be recognized as sign node')
    assert(waysigns.is_sign_node(sign_steel) == true, 'basic_signs:sign_wall_steel must be recognized as sign node')
    assert(waysigns.is_sign_node(sign_aspen) == true, 'ucsigns:sign_aspen must be recognized as sign node')
    assert(waysigns.is_sign_node(chest_node) == false, 'default:chest must NOT be recognized as sign node')
    assert(waysigns.is_sign_node(stone_node) == false, 'default:stone must NOT be recognized as sign node')
    assert(waysigns.is_sign_node(signal_wire) == false, 'mesecons:signal_wire must NOT be recognized as sign node')

    -- 2. Marker tool interaction on sign nodes must be excluded with player notification
    local sign_pos = { x = 600, y = 5, z = 600 }
    local orig_get_node_or_nil = core.get_node_or_nil
    local orig_get_node = core.get_node
    core.get_node_or_nil = function(p)
        if p.x == 600 then return sign_wood end
        return orig_get_node_or_nil and orig_get_node_or_nil(p)
    end
    core.get_node = function(p)
        if p.x == 600 then return sign_wood end
        return orig_get_node(p)
    end

    local test_player = {
        get_player_name = function() return 'tester' end,
        is_player = function() return true end,
        get_wielded_item = function(self) return self.wielded end,
        set_wielded_item = function(self, item) self.wielded = item end,
        wielded = ItemStack('waysigns:marker'),
        privs = {},
    }

    _G.last_chat_message = nil
    _G.last_shown_formspec = nil

    -- a. on_use_marker right-click on sign node
    local ret_item = waysigns.on_use_marker(test_player.wielded, test_player, { type = 'node', under = sign_pos })
    assert(_G.last_chat_message ~= nil and _G.last_chat_message.message:find('Signs already have editable text'),
        'Using marker on a sign node must alert player that signs already have editable text')
    assert(_G.last_shown_formspec == nil, 'Formspec must NOT open when marker used on a sign node')
    assert(ret_item:get_wear() == 0, 'No wear should be consumed when marker is rejected on sign node')

    -- b. show_node_inscription_formspec called directly on sign node
    _G.last_chat_message = nil
    waysigns.show_node_inscription_formspec(test_player, sign_pos)
    assert(_G.last_chat_message ~= nil and _G.last_chat_message.message:find('Signs already have editable text'),
        'show_node_inscription_formspec must reject sign nodes with alert')
    assert(_G.last_shown_formspec == nil, 'Formspec must NOT open for sign node')

    -- c. set_node_inscription called on sign node
    local inscribe_result = waysigns.set_node_inscription(sign_pos, 'Hacked text', 'slate', 'white', 'tester')
    assert(inscribe_result == false, 'set_node_inscription must return false on sign node')
    local sign_meta = core.get_meta(sign_pos)
    assert(sign_meta:get_string('waysigns_text') == '', 'waysigns_text must NOT be saved on a sign node')

    -- 3. Inscribed container with both custom waysign text, infotext, and inventory quickview
    local vault_pos = { x = 700, y = 10, z = 700 }
    local vault_node = { name = 'default:chest', param2 = 0 }
    core.get_node_or_nil = function(p)
        if p.x == 600 then return sign_wood end
        if p.x == 700 then return vault_node end
        return orig_get_node_or_nil and orig_get_node_or_nil(p)
    end
    core.get_node = function(p)
        if p.x == 600 then return sign_wood end
        if p.x == 700 then return vault_node end
        return orig_get_node(p)
    end

    local vault_items = {
        MockItemStack('default:diamond', 16),
        MockItemStack('default:gold_ingot', 32),
        MockItemStack('default:steel_ingot', 48),
    }
    local vault_inv = MockInventory({ main = vault_items })
    local vault_meta = core.get_meta(vault_pos)
    vault_meta:set_string('owner', 'alice')
    vault_meta:set_string('infotext', 'Treasury Safe (Owner: alice)')
    vault_pos.inv = vault_inv

    local alice_player = {
        get_player_name = function() return 'alice' end,
        is_player = function() return true end,
        hud_elements = {},
        hud_removes = {},
        hud_adds = {},
        hud_changes = {},
        hud_add = function(self, def)
            local id = #self.hud_elements + 1
            self.hud_elements[id] = def
            table.insert(self.hud_adds, { id = id, def = def })
            return id
        end,
        hud_change = function(self, id, stat, val)
            if self.hud_elements[id] then
                self.hud_elements[id][stat] = val
                table.insert(self.hud_changes, { id = id, stat = stat, val = val })
            end
        end,
        hud_remove = function(self, id)
            self.hud_elements[id] = nil
            table.insert(self.hud_removes, id)
        end,
    }

    local bob_player = {
        get_player_name = function() return 'bob' end,
        is_player = function() return true end,
    }

    -- Inscribe the chest with custom waysigns marker text
    local inscribe_ok = waysigns.set_node_inscription(vault_pos, 'Outpost Alpha', 'gold', 'cyan', 'alice')
    assert(inscribe_ok == true, 'set_node_inscription must succeed on generic container node')

    -- Alice (owner) queries sign data
    local alice_data = waysigns.get_sign_data(vault_pos, vault_node, alice_player)
    assert(alice_data ~= nil, 'waysigns.get_sign_data must return sign data for inscribed container')
    assert(alice_data.has_inscription == true, 'sign_data.has_inscription must be true')
    assert(alice_data.is_infotext == true, 'sign_data.is_infotext must be true for container node')
    assert(alice_data.text:find('Outpost Alpha', 1, true) ~= nil, 'sign_data.text must include custom waysign text')
    assert(alice_data.text:find('Treasury Safe', 1, true) ~= nil, 'sign_data.text must include node infotext')
    assert(alice_data.quickview_items ~= nil and #alice_data.quickview_items == 3,
        'Owner Alice must receive extracted quickview_items')
    assert(alice_data.quickview_items[1].name == 'default:diamond', 'First quickview item must be diamond')

    -- Bob (visitor) queries sign data (security isolation)
    local bob_data = waysigns.get_sign_data(vault_pos, vault_node, bob_player)
    assert(bob_data ~= nil, 'Bob should see sign data')
    assert(bob_data.text:find('Outpost Alpha', 1, true) ~= nil, 'Bob should see waysigns text')
    assert(bob_data.text:find('Treasury Safe', 1, true) ~= nil, 'Bob should see infotext')
    assert(bob_data.quickview_items == nil, 'Bob must NOT receive private container items')

    -- Verify HUD rendering for Alice
    local pstate = waysigns.get_or_create_player_state(alice_player)
    pstate.current_sign_pos = vault_pos
    pstate.current_sign_data = alice_data
    pstate.sign_face_pos = { x = 700, y = 10.35, z = 700 }
    pstate.opacity = 1.0
    pstate.target_opacity = 1.0
    waysigns.render_hud(alice_player, pstate)

    assert(pstate.hud_bg_id ~= nil, 'Background image HUD element must be created')
    local vault_bg_elem = alice_player.hud_elements[pstate.hud_bg_id]
    assert(vault_bg_elem ~= nil, 'Background HUD element definition must exist')
    assert(vault_bg_elem.text:find('%[combine:'), 'Background texture must composite container quickview dock')
    assert(vault_bg_elem.text:find('default_diamond%.png'), 'Background texture must include diamond item texture')

    -- Check rendered line text elements
    assert(pstate.hud_line_ids and #pstate.hud_line_ids >= 2, 'HUD must render multiple lines of text')
    local line1 = alice_player.hud_elements[pstate.hud_line_ids[1]]
    local line2 = alice_player.hud_elements[pstate.hud_line_ids[2]]
    assert(line1.text:find('Outpost Alpha'), 'First rendered line must contain custom waysign text')
    assert(line2.text:find('Treasury Safe'), 'Second rendered line must contain infotext')

    waysigns.remove_all_huds(alice_player)
    core.get_node_or_nil = orig_get_node_or_nil
    core.get_node = orig_get_node
    print('PASS Test 68')
end)()

print('--- Test 69: Dynamic discovery of inscribed nodes, waypoint title labels, and self-healing ---')
;(function()
    local orig_find_nodes = core.find_nodes_with_meta
    local orig_line_of_sight = core.line_of_sight
    core.line_of_sight = function() return true end

    -- 1. Setup mock find_nodes_with_meta
    local test_meta_nodes = {}
    core.find_nodes_with_meta = function(minp, maxp)
        local found = {}
        for _, p in ipairs(test_meta_nodes) do
            if p.x >= minp.x and p.x <= maxp.x and
               p.y >= minp.y and p.y <= maxp.y and
               p.z >= minp.z and p.z <= maxp.z then
                table.insert(found, p)
            end
        end
        return found
    end

    local function MockItemStack(name, count)
        return {
            is_empty = function(self) return (count or 0) <= 0 or (name or '') == '' end,
            get_name = function(self) return name or '' end,
            get_count = function(self) return count or 0 end,
        }
    end

    local p_pos = { x = 800, y = 10, z = 805 }
    local p_look = { x = 0, y = 0, z = -1 }
    local dyn_player = {
        name = 'dyn_tester',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        is_valid = function() return true end,
        get_hp = function() return 20 end,
        get_pos = function() return p_pos end,
        get_look_dir = function() return p_look end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_window_size = function() return { x = 1920, y = 1080 } end,
        get_wielded_item = function(self) return self.wielded end,
        wielded = MockItemStack('waysigns:marker', 1),
        hud_elements = {},
        hud_adds = {},
        hud_changes = {},
        hud_removes = {},
        hud_add = function(self, def)
            local id = #self.hud_elements + 1
            self.hud_elements[id] = def
            table.insert(self.hud_adds, { id = id, def = def })
            return id
        end,
        hud_change = function(self, id, stat, val)
            if self.hud_elements[id] then
                self.hud_elements[id][stat] = val
                table.insert(self.hud_changes, { id = id, stat = stat, val = val })
            end
        end,
        hud_remove = function(self, id)
            self.hud_elements[id] = nil
            table.insert(self.hud_removes, id)
        end,
    }

    -- 2. Place an unindexed inscribed node at (800, 10, 800)
    local unindexed_pos = { x = 800, y = 10, z = 800 }
    local unindexed_key = waysigns.pos_to_key(unindexed_pos)
    waysigns.unregister_inscribed_pos(unindexed_pos, true) -- ensure empty
    table.insert(test_meta_nodes, unindexed_pos)

    local unindexed_meta = core.get_meta(unindexed_pos)
    unindexed_meta:set_string('waysigns_text', 'Hidden Sanctuary')
    unindexed_meta:set_string('waysigns_plaque', 'gold')
    unindexed_meta:set_string('waysigns_color', 'gold')
    unindexed_meta:set_string('waysigns_author', 'juraj')

    local dyn_pstate = waysigns.get_or_create_player_state(dyn_player)
    dyn_pstate.marker_last_discover = false -- force discovery run

    -- Execute waypoint update
    waysigns.update_marker_waypoints(dyn_player, dyn_pstate)

    -- Assert dynamic discovery succeeded
    local unindexed_entry = waysigns.get_inscribed_pos(unindexed_pos)
    assert(unindexed_entry ~= nil,
        'unindexed inscribed node must be dynamically discovered and registered')
    assert(unindexed_entry.text == 'Hidden Sanctuary',
        'registered position text must match waysigns_text')

    -- Assert active waypoint was created as image-only indicator (no text label)
    local wp = dyn_pstate.marker_waypoints[unindexed_key]
    assert(wp ~= nil, 'Waypoint for discovered node must exist in marker_waypoints')
    assert(wp.hud_id ~= nil, 'Waypoint must have hud_id (image indicator)')
    assert(wp.label_id == nil, 'Waypoint must NOT have label_id (image indicator only)')

    local icon_elem = dyn_player.hud_elements[wp.hud_id]
    assert(icon_elem ~= nil, 'HUD element for icon must exist in player state')
    assert(icon_elem.type == 'image_waypoint', 'HUD element must be image_waypoint')
    assert(icon_elem.text:find('waysigns_waypoint'), 'HUD element must display waypoint texture')

    -- 4. Test gaze suppression
    dyn_pstate.is_visible = true
    dyn_pstate.current_sign_pos = unindexed_pos
    waysigns.update_marker_waypoints(dyn_player, dyn_pstate)
    assert(dyn_pstate.marker_waypoints[unindexed_key] == nil,
        'Waypoint must be suppressed when player looks directly at the sign')

    -- Look away -> restored
    dyn_pstate.is_visible = false
    dyn_pstate.current_sign_pos = nil
    waysigns.update_marker_waypoints(dyn_player, dyn_pstate)
    assert(dyn_pstate.marker_waypoints[unindexed_key] ~= nil,
        'Waypoint must be restored after looking away')

    -- 5. Test self-healing in get_sign_data
    core.registered_nodes['default:wood'] = { description = 'Wooden Planks', tiles = {'default_wood.png'} }
    local heal_sign_pos = { x = 810, y = 10, z = 800 }
    waysigns.unregister_inscribed_pos(heal_sign_pos, true)
    local heal_sign_meta = core.get_meta(heal_sign_pos)
    heal_sign_meta:set_string('waysigns_text', 'Self Healed Sign')
    heal_sign_meta:set_string('waysigns_plaque', 'slate')
    heal_sign_meta:set_string('waysigns_color', 'cyan')

    local sdata = waysigns.get_sign_data(heal_sign_pos, { name = 'default:wood' }, dyn_player)
    assert(sdata ~= nil, 'get_sign_data must return data')
    local heal_sign_entry = waysigns.get_inscribed_pos(heal_sign_pos)
    assert(heal_sign_entry ~= nil,
        'get_sign_data must self-heal and register unindexed inscribed position')
    assert(heal_sign_entry.text == 'Self Healed Sign',
        'Self-healed registry must retain sign text')

    -- 6. Test self-healing in get_node_infotext_data
    local heal_info_pos = { x = 820, y = 10, z = 800 }
    waysigns.unregister_inscribed_pos(heal_info_pos, true)
    local heal_info_meta = core.get_meta(heal_info_pos)
    heal_info_meta:set_string('infotext', 'Furnace (Ore: 5)')
    heal_info_meta:set_string('waysigns_text', 'Smeltery Hub')
    heal_info_meta:set_string('waysigns_plaque', 'steel')
    heal_info_meta:set_string('waysigns_color', 'orange')

    local idata = waysigns.get_node_infotext_data(heal_info_pos, { name = 'default:furnace' }, dyn_player)
    assert(idata ~= nil, 'get_node_infotext_data must return data')
    local heal_info_entry = waysigns.get_inscribed_pos(heal_info_pos)
    assert(heal_info_entry ~= nil,
        'get_node_infotext_data must self-heal and register unindexed container position')
    assert(heal_info_entry.text == 'Smeltery Hub',
        'Self-healed registry must retain container waysign text')

    -- Cleanup
    waysigns.remove_marker_waypoints(dyn_player, dyn_pstate)
    waysigns.remove_all_huds(dyn_player)
    core.find_nodes_with_meta = orig_find_nodes
    core.line_of_sight = orig_line_of_sight
    print('PASS Test 69')
end)()

print('--- Test 70: Plaque material style node texture detection (mesh fallback & animated 1st frame crop) ---')
;(function()
    waysigns.clear_caches()
    local test_player = {
        get_player_name = function() return 'artisan' end,
        get_wielded_item = function() return { get_name = function() return 'waysigns:marker' end } end,
    }

    -- 1. Verify waysigns.get_node_front_tile is exposed
    assert(type(waysigns.get_node_front_tile) == 'function', 'waysigns.get_node_front_tile must be exposed on waysigns')

    -- 2. Mesh node: Verify fallback plaque is used instead of distorted UV map in formspec and in-world
    core.registered_nodes['mymod:mesh_pillar'] = {
        description = 'Ancient Mesh Pillar',
        drawtype = 'mesh',
        mesh = 'ancient_pillar.obj',
        tiles = { 'ancient_pillar_uv_map.png' },
    }
    local pos_mesh = { x = 40, y = 1, z = 40 }
    local node_mesh = { name = 'mymod:mesh_pillar', param2 = 0 }

    local pos_anim = { x = 41, y = 1, z = 40 }
    local node_anim = { name = 'mymod:animated_furnace', param2 = 0 }

    local world_nodes = {
        [waysigns.pos_to_key(pos_mesh)] = node_mesh,
        [waysigns.pos_to_key(pos_anim)] = node_anim,
    }
    local orig_get_node = core.get_node
    local orig_get_node_or_nil = core.get_node_or_nil
    core.get_node = function(p)
        local k = waysigns.pos_to_key(p)
        if world_nodes[k] then return world_nodes[k] end
        return orig_get_node(p)
    end
    core.get_node_or_nil = function(p)
        local k = waysigns.pos_to_key(p)
        if world_nodes[k] then return world_nodes[k] end
        return orig_get_node_or_nil and orig_get_node_or_nil(p)
    end

    local form_sent = nil
    local orig_show_formspec = core.show_formspec
    core.show_formspec = function(_pname, _fname, form)
        form_sent = form
    end

    waysigns.show_node_inscription_formspec(test_player, pos_mesh)
    assert(form_sent ~= nil, 'Formspec must be generated for mesh node')
    assert(not form_sent:find('ancient_pillar_uv_map%.png'),
        'Mesh node UV map must NEVER be used in plaque material style or swatches!')
    assert(form_sent:find(waysigns.FALLBACK_WOOD),
        'Mesh node default plaque option must use FALLBACK_WOOD as fallback swatch')

    -- Save inscription with plaque = 'default'
    waysigns.set_node_inscription(pos_mesh, "Ancient Pillar Inscription", "default", "white", "artisan")

    -- In-world sign data for inscribed mesh node must also use clean fallback
    local mesh_sign_data = waysigns.get_sign_data(pos_mesh, node_mesh)
    assert(mesh_sign_data ~= nil, 'get_sign_data must recognize inscribed mesh node')
    assert(mesh_sign_data.tile == waysigns.FALLBACK_WOOD,
        'Inscribed mesh node with default plaque must use FALLBACK_WOOD, got: ' .. tostring(mesh_sign_data.tile))
    assert(mesh_sign_data.tile ~= 'ancient_pillar_uv_map.png',
        'Inscribed mesh node must never use raw mesh UV map in-world')

    -- 3. Animated texture: Verify 1st frame is cropped with [combine / [verticalframe in formspec and in-world
    core.registered_nodes['mymod:animated_furnace'] = {
        description = 'Arcane Furnace',
        tiles = {
            'furnace_top.png', 'furnace_bottom.png', 'furnace_side.png',
            'furnace_side.png', 'furnace_side.png',
            {
                name = 'arcane_furnace_animated.png',
                animation = { type = 'vertical_frames', aspect_w = 16, aspect_h = 16, length = 2.0 }
            }
        }
    }

    -- Open inscription formspec for animated node
    form_sent = nil
    waysigns.show_node_inscription_formspec(test_player, pos_anim)
    assert(form_sent ~= nil, 'Formspec must be generated for animated node')
    assert(not form_sent:find(';arcane_furnace_animated%.png;'),
        'Full un-cropped animated texture strip must NEVER be used in plaque swatches')
    assert(form_sent:find('%[combine:16x16:0,0=arcane_furnace_animated%.png')
        or form_sent:find('%[verticalframe:%d+:0'),
        'Animated texture must be cropped to 1st frame (frame 0) in plaque style swatches and preview')

    -- Save inscription with plaque = 'default'
    waysigns.set_node_inscription(pos_anim, "Arcane Smelter", "default", "gold", "artisan")

    -- In-world sign data for inscribed animated node must also crop to 1st frame
    local anim_sign_data = waysigns.get_sign_data(pos_anim, node_anim)
    assert(anim_sign_data ~= nil, 'get_sign_data must recognize inscribed animated node')
    assert(anim_sign_data.tile:find('%[combine:16x16:0,0=arcane_furnace_animated%.png')
        or anim_sign_data.tile:find('%[verticalframe:%d+:0'),
        'Inscribed animated node in-world must crop plaque tile to 1st frame, got: ' .. tostring(anim_sign_data.tile))

    -- Infotext extraction on animated node must also crop to 1st frame
    local anim_info_data = waysigns.get_node_infotext_data(pos_anim, node_anim)
    assert(anim_info_data ~= nil, 'get_node_infotext_data must recognize inscribed animated node')
    assert(anim_info_data.tile:find('%[combine:16x16:0,0=arcane_furnace_animated%.png')
        or anim_info_data.tile:find('%[verticalframe:%d+:0'),
        'Inscribed animated node infotext plaque must crop to 1st frame, got: ' .. tostring(anim_info_data.tile))

    -- 4. Direct verification of waysigns.get_node_front_tile detection re-use
    local mesh_tile = waysigns.get_node_front_tile(core.registered_nodes['mymod:mesh_pillar'], 'mymod:mesh_pillar', false)
    assert(mesh_tile == waysigns.FALLBACK_WOOD, 'get_node_front_tile must return FALLBACK_WOOD for mesh node')

    local mesh_metal_tile = waysigns.get_node_front_tile(core.registered_nodes['mymod:mesh_pillar'], 'mymod:mesh_steel_pillar', true)
    assert(mesh_metal_tile == waysigns.FALLBACK_STEEL, 'get_node_front_tile must return FALLBACK_STEEL for metal mesh node')

    local anim_tile = waysigns.get_node_front_tile(core.registered_nodes['mymod:animated_furnace'], 'mymod:animated_furnace', true)
    assert(anim_tile:find('%[combine:16x16:0,0=arcane_furnace_animated%.png') or anim_tile:find('%[verticalframe:'),
        'get_node_front_tile must crop animated front face to 1st frame')

    core.show_formspec = orig_show_formspec
    core.get_node = orig_get_node
    print('PASS Test 70')
end)()

--- Test 71: Marker right-click (on_place) delegation to interactive nodes (default:chest, doors) vs sneak & left-click (on_use)
;(function()
    print('--- Test 71: Marker right-click delegation to on_rightclick (chests, doors) vs sneak & left-click ---')
    local marker_tool = core.registered_tools['waysigns:marker']
    assert(marker_tool ~= nil, 'waysigns:marker must be registered')
    assert(marker_tool.on_place ~= nil, 'waysigns:marker must have on_place')
    assert(marker_tool.on_use ~= nil, 'waysigns:marker must have on_use')

    local chest_opened
    local chest_pos = { x = 40, y = 5, z = 40 }
    core.registered_nodes['test:chest'] = {
        description = 'Test Chest',
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            chest_opened = true
            return itemstack
        end,
    }
    local orig_get_node = core.get_node
    local orig_get_node_or_nil = core.get_node_or_nil
    local function mock_node_fn(pos)
        if pos.x == chest_pos.x and pos.y == chest_pos.y and pos.z == chest_pos.z then
            return { name = 'test:chest', param2 = 0 }
        elseif pos.x == 50 then
            return { name = 'default:stone', param2 = 0 }
        end
        return orig_get_node(pos)
    end
    core.get_node = mock_node_fn
    core.get_node_or_nil = mock_node_fn

    local normal_player = {
        name = 'test_steve',
        get_player_name = function(self) return self.name end,
        is_player = function(self) return true end,
        get_player_control = function(self) return { sneak = false } end,
        privs = {},
        wielded = ItemStack('waysigns:marker'),
        get_wielded_item = function(self) return self.wielded end,
        set_wielded_item = function(self, stack) self.wielded = stack end,
    }

    local sneak_player = {
        name = 'test_steve',
        get_player_name = function(self) return self.name end,
        is_player = function(self) return true end,
        get_player_control = function(self) return { sneak = true } end,
        privs = {},
        wielded = ItemStack('waysigns:marker'),
        get_wielded_item = function(self) return self.wielded end,
        set_wielded_item = function(self, stack) self.wielded = stack end,
    }

    local orig_show_formspec = core.show_formspec
    local shown_formspec
    core.show_formspec = function(player_name, formname, formspec)
        shown_formspec = { player_name = player_name, formname = formname, formspec = formspec }
    end

    local pointed_chest = { type = 'node', under = chest_pos }
    local pointed_stone = { type = 'node', under = { x = 50, y = 5, z = 50 } }

    -- 1. Normal right-click on chest -> executes chest on_rightclick (opens chest, does NOT show inscription formspec)
    chest_opened = false
    shown_formspec = nil
    marker_tool.on_place(normal_player.wielded, normal_player, pointed_chest)
    assert(chest_opened == true, 'Normal right-click on test:chest must execute chest on_rightclick')
    assert(shown_formspec == nil, 'Normal right-click on test:chest must NOT open inscription formspec')

    -- 2. Sneak + right-click on chest -> bypasses chest on_rightclick and opens inscription formspec
    chest_opened = false
    shown_formspec = nil
    marker_tool.on_place(sneak_player.wielded, sneak_player, pointed_chest)
    assert(chest_opened == false, 'Sneak right-click on test:chest must bypass chest on_rightclick')
    assert(shown_formspec ~= nil and shown_formspec.formname == 'waysigns:inscribe',
        'Sneak right-click on test:chest must open waysigns:inscribe formspec')

    -- 3. Left-click (on_use) on chest -> opens inscription formspec directly
    chest_opened = false
    shown_formspec = nil
    marker_tool.on_use(normal_player.wielded, normal_player, pointed_chest)
    assert(chest_opened == false, 'Left-click (on_use) on test:chest must not execute chest on_rightclick')
    assert(shown_formspec ~= nil and shown_formspec.formname == 'waysigns:inscribe',
        'Left-click (on_use) on test:chest must open waysigns:inscribe formspec')

    -- 4. Normal right-click on non-interactive node (default:stone) -> opens inscription formspec
    shown_formspec = nil
    marker_tool.on_place(normal_player.wielded, normal_player, pointed_stone)
    assert(shown_formspec ~= nil and shown_formspec.formname == 'waysigns:inscribe',
        'Normal right-click on non-interactive node must open waysigns:inscribe formspec')

    -- 5. Entity right-click delegation
    local entity_clicked
    local dummy_entity = {
        is_valid = function(self) return true end,
        is_player = function(self) return false end,
        get_pos = function(self) return { x = 60, y = 5, z = 60 } end,
        get_properties = function(self) return {} end,
        get_luaentity = function(self)
            return {
                on_rightclick = function(self_ent, clicker)
                    entity_clicked = true
                end,
            }
        end,
    }
    local pointed_obj = { type = 'object', ref = dummy_entity }

    -- Normal right-click on entity with on_rightclick -> executes luaentity on_rightclick
    entity_clicked = false
    shown_formspec = nil
    marker_tool.on_place(normal_player.wielded, normal_player, pointed_obj)
    assert(entity_clicked == true, 'Normal right-click on interactive entity must execute luaentity on_rightclick')
    assert(shown_formspec == nil, 'Normal right-click on interactive entity must NOT open inscription formspec')

    -- Sneak right-click on entity with on_rightclick -> opens inscription formspec
    entity_clicked = false
    shown_formspec = nil
    marker_tool.on_place(sneak_player.wielded, sneak_player, pointed_obj)
    assert(entity_clicked == false, 'Sneak right-click on entity must bypass entity on_rightclick')
    assert(shown_formspec ~= nil and shown_formspec.formname == 'waysigns:inscribe',
        'Sneak right-click on entity must open waysigns:inscribe formspec')

    core.show_formspec = orig_show_formspec
    core.get_node = orig_get_node
    core.get_node_or_nil = orig_get_node_or_nil
    print('PASS Test 71')
end)()

--- Test 72: Decorative beveled frame in get_background_texture (No corner rivets)
;(function()
    print('--- Test 72: Decorative beveled frame in get_background_texture (No corner rivets) ---')
    waysigns.clear_caches()
    waysigns.settings.show_frame = true

    -- Width 440, Height 314
    local frame_tex = waysigns.get_background_texture('default_wood.png', 440, 314, 1.0, false, false, false, false, nil)
    assert(frame_tex ~= nil, 'Must return background texture')
    assert(frame_tex:find('waysigns_frame_vignette%.png%^%[resize:440x314'),
        'Frame vignette must be applied when show_frame is enabled')
    assert(not frame_tex:find('waysigns_corner'),
        'Corner rivets must not be present in background texture')

    -- Disabled show_frame
    waysigns.clear_caches()
    waysigns.settings.show_frame = false
    local no_frame_tex = waysigns.get_background_texture('default_wood.png', 440, 314, 1.0, false, false, false, false, nil)
    assert(not no_frame_tex:find('waysigns_frame_vignette'),
        'Frame vignette must not be present when show_frame is false')
    assert(not no_frame_tex:find('waysigns_corner'),
        'Corner rivets must not be present when show_frame is false')

    -- Light background (vignette suppressed to avoid muddying light plaque)
    waysigns.clear_caches()
    waysigns.settings.show_frame = true
    local light_frame_tex = waysigns.get_background_texture('default_wood.png', 440, 314, 1.0, false, true, false, false, nil)
    assert(not light_frame_tex:find('waysigns_frame_vignette'),
        'Frame vignette must be suppressed on light backgrounds')
    assert(not light_frame_tex:find('waysigns_corner'),
        'Corner rivets must not be present on light backgrounds')

    waysigns.settings.show_frame = true
    print('PASS Test 72')
end)()

--- Test 73: UTF-8 character length counting in marker formspec
;(function()
    print('--- Test 73: UTF-8 character length counting in marker formspec ---')
    -- 'Příliš žluťoučký kůň úpěl ďábelské ódy' (Czech pangram): 38 UTF-8 characters, 53 raw bytes
    local utf8_sample = 'Příliš žluťoučký kůň úpěl ďábelské ódy'
    assert(#utf8_sample == 53, 'Sample string raw byte count must be 53')

    -- Internal char count helper check
    local _, count = utf8_sample:gsub('[^\128-\191]', '')
    assert(count == 38, 'UTF-8 character counting must return 38 characters, got: ' .. tostring(count))

    -- Check character limit in formspec submission
    local cz_player = {
        name = 'czech_scribe',
        is_player = function(self) return true end,
        get_player_name = function(self) return self.name end,
        get_wielded_item = function(self) return ItemStack('waysigns:marker') end,
        set_wielded_item = function(self, s) end,
    }
    local pos = { x = 120, y = 5, z = 120 }
    waysigns.show_node_inscription_formspec(cz_player, pos)

    -- Create a 240-character string using 2-byte UTF-8 characters (e.g. 'č' repeated 240 times -> 480 bytes)
    local long_utf8 = string.rep('č', 240)
    assert(#long_utf8 == 480, '240 chars of č must be 480 bytes')

    -- Setting text <= max_chars (250) must succeed even though byte count (480) > 250!
    waysigns.settings.marker_max_chars = 250
    local last_chat = ''
    local orig_chat = core.chat_send_player
    core.chat_send_player = function(name, msg) last_chat = msg end

    local fields_ok = {
        save = 'Save Inscription',
        inscription = long_utf8,
        plaque = 'wood',
        color = 'white',
    }
    local handled = core.registered_on_player_receive_fields[1](cz_player, 'waysigns:inscribe', fields_ok)
    assert(handled == true or handled == nil, 'Formspec submission should succeed')
    local saved = waysigns.get_node_inscription(pos)
    assert(saved ~= nil and saved.text == long_utf8, '240 UTF-8 characters (480 bytes) must save successfully without byte-limit error')

    -- Now test 260 characters of 'č' (520 bytes) -> must be rejected (> 250 chars)
    local too_long_utf8 = string.rep('č', 260)
    local fields_fail = {
        save = 'Save Inscription',
        inscription = too_long_utf8,
        plaque = 'wood',
        color = 'white',
    }
    waysigns.show_node_inscription_formspec(cz_player, pos)
    core.registered_on_player_receive_fields[1](cz_player, 'waysigns:inscribe', fields_fail)
    assert(last_chat:find('maximum length of 250 characters'), 'Must reject when character count exceeds 250')

    core.chat_send_player = orig_chat
    print('PASS Test 73')
end)()

--- Test 74: Ghost waypoint self-healing on destroyed nodes
;(function()
    print('--- Test 74: Ghost waypoint self-healing on destroyed nodes ---')
    local ghost_pos = { x = 900, y = 15, z = 900 }

    -- Register an inscribed node
    waysigns.register_inscribed_pos(ghost_pos, {
        text = 'Ancient Monolith',
        plaque = 'slate',
        color = 'cyan',
        author = 'explorer',
    })
    assert(waysigns.get_inscribed_pos(ghost_pos) ~= nil, 'Position must be in registry initially')

    -- Simulate TNT explosion / WorldEdit clearing node and wiping metadata
    local ghost_meta = core.get_meta(ghost_pos)
    ghost_meta:set_string('waysigns_text', '')
    ghost_meta:set_string('waysigns_inscribed', '')

    -- Mock player holding marker near ghost node
    local test_player = {
        name = 'cleaner',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        is_valid = function() return true end,
        get_pos = function() return { x = 900, y = 15, z = 895 } end,
        get_look_dir = function() return { x = 0, y = 0, z = 1 } end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_wielded_item = function() return ItemStack('waysigns:marker') end,
        hud_add = function() return 1 end,
        hud_change = function() end,
        hud_remove = function() end,
    }
    local cleaner_state = waysigns.get_or_create_player_state(test_player)

    -- Execute waypoint check
    waysigns.update_marker_waypoints(test_player, cleaner_state, 0.25)

    -- Verify self-healing: ghost position is purged from spatial registry!
    assert(waysigns.get_inscribed_pos(ghost_pos) == nil,
        'update_marker_waypoints must self-heal and purge ghost node whose inscription metadata was destroyed')
    assert(cleaner_state.marker_waypoints['900,15,900'] == nil,
        'Ghost node must NOT be added as active waypoint candidate')
    print('PASS Test 74')
end)()

--- Test 75: Tool durability helper (waysigns.consume_marker_durability) and is_metal_node
;(function()
    print('--- Test 75: Tool durability helper and is_metal_node helper ---')
    -- 1. Verify waysigns.is_metal_node
    assert(type(waysigns.is_metal_node) == 'function', 'waysigns.is_metal_node must be a function')
    assert(waysigns.is_metal_node('default:steelblock') == true, 'steelblock must be metal')
    assert(waysigns.is_metal_node('default:iron_ore') == true, 'iron_ore must be metal')
    assert(waysigns.is_metal_node('default:stone') == true, 'stone must be metal/stone')
    assert(waysigns.is_metal_node('default:furnace') == true, 'furnace must be metal/stone')
    assert(waysigns.is_metal_node('default:copperblock') == true, 'copperblock must be metal')
    assert(waysigns.is_metal_node('default:wood') == false, 'wood must not be metal')
    assert(waysigns.is_metal_node('default:tree') == false, 'tree must not be metal')
    assert(waysigns.is_metal_node('default:glass') == false, 'glass must not be metal')

    -- Node def group check
    local metal_group_def = { groups = { metal = 1 } }
    assert(waysigns.is_metal_node('custom:weird_block', metal_group_def) == true, 'group metal=1 must be metal')
    local stone_cracky_def = { groups = { cracky = 2 } }
    assert(waysigns.is_metal_node('custom:hard_rock', stone_cracky_def) == true, 'cracky non-choppy must be metal/stone')

    -- 2. Verify waysigns.consume_marker_durability
    assert(type(waysigns.consume_marker_durability) == 'function', 'consume_marker_durability must be a function')

    local marker_stack = ItemStack('waysigns:marker')
    local player_inv = {
        wielded = marker_stack,
        get_player_name = function() return 'craftsman' end,
        get_wielded_item = function(self) return self.wielded end,
        set_wielded_item = function(self, stack) self.wielded = stack end,
    }

    waysigns.settings.marker_uses = 100
    local consumed = waysigns.consume_marker_durability(player_inv, { x = 0, y = 0, z = 0 })
    assert(consumed == true, 'Must return true when durability is consumed')
    assert(player_inv.wielded:get_wear() > 0, 'Wielded marker must accumulate wear')

    -- Player holding a different tool -> no consumption
    player_inv.wielded = ItemStack('default:pick_wood')
    local consumed_other = waysigns.consume_marker_durability(player_inv, { x = 0, y = 0, z = 0 })
    assert(consumed_other == false, 'Must return false when wielded item is not waysigns:marker')

    print('PASS Test 75')
end)()

--- Test 76: Unified Spatial Block Partitioning and Localized Scribe Sense
;(function()
    print('--- Test 76: Unified Spatial Block Partitioning and Localized Scribe Sense ---')
    -- 1. pos_to_block_key verification
    local pos_a = { x = 35, y = -10, z = 160 }
    local expected_bkey = math.floor(35/16) .. ',' .. math.floor(-10/16) .. ',' .. math.floor(160/16)
    local actual_bkey = waysigns.pos_to_block_key(pos_a)
    assert(actual_bkey == expected_bkey, 'pos_to_block_key must return mapblock coordinates ' .. expected_bkey .. ', got ' .. tostring(actual_bkey))

    -- 2. Storage hierarchy in inscribed_blocks
    waysigns.register_inscribed_pos(pos_a, { text = 'Block Test', plaque = 'wood', color = 'white' }, true)
    local pkey_a = waysigns.pos_to_key(pos_a)
    assert(waysigns.inscribed_blocks[actual_bkey] ~= nil, 'Mapblock bucket must exist')
    assert(waysigns.inscribed_blocks[actual_bkey][pkey_a] ~= nil, 'Position entry must exist inside mapblock bucket')
    assert(waysigns.get_inscribed_pos(pos_a) ~= nil, 'get_inscribed_pos must return entry')

    -- 3. Unregistration cleans up empty mapblock bucket
    waysigns.unregister_inscribed_pos(pos_a, true)
    assert(waysigns.get_inscribed_pos(pos_a) == nil, 'Position entry must be removed')
    assert(waysigns.inscribed_blocks[actual_bkey] == nil, 'Empty mapblock bucket must be cleaned up to prevent memory leaks')

    -- 4. Localized lookup: position outside sense range mapblocks is never checked
    local far_pos = { x = 2000, y = 100, z = 2000 }
    waysigns.register_inscribed_pos(far_pos, { text = 'Far Post', plaque = 'slate', color = 'gold' }, true)
    local near_pos = { x = 10, y = 5, z = 10 }
    waysigns.register_inscribed_pos(near_pos, { text = 'Near Post', plaque = 'gold', color = 'cyan' }, true)

    local meta_near = core.get_meta(near_pos)
    meta_near:set_string('waysigns_text', 'Near Post')

    local p_test = {
        name = 'ranger',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        is_valid = function() return true end,
        get_pos = function() return { x = 10, y = 5, z = 8 } end,
        get_look_dir = function() return { x = 0, y = 0, z = 1 } end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_wielded_item = function() return ItemStack('waysigns:marker') end,
        hud_elements = {},
        hud_add = function(self, def)
            local id = #self.hud_elements + 1
            self.hud_elements[id] = def
            return id
        end,
        hud_change = function() end,
        hud_remove = function(self, id) self.hud_elements[id] = nil end,
    }
    local rstate = waysigns.get_or_create_player_state(p_test)
    waysigns.update_marker_waypoints(p_test, rstate, 0.25)

    local near_key = waysigns.pos_to_key(near_pos)
    local far_key = waysigns.pos_to_key(far_pos)
    assert(rstate.marker_waypoints[near_key] ~= nil, 'Near waypoint must be active')
    assert(rstate.marker_waypoints[far_key] == nil, 'Far waypoint outside local mapblocks must not be active')

    -- Cleanup
    waysigns.unregister_inscribed_pos(near_pos, true)
    waysigns.unregister_inscribed_pos(far_pos, true)
    waysigns.remove_marker_waypoints(p_test, rstate)
    print('PASS Test 76')
end)()

--- Test 77: Node metadata formspec passthrough
;(function()
    print('--- Test 77: Node metadata formspec passthrough ---')
    local furnace_pos = { x = 500, y = 10, z = 500 }
    local furnace_meta = core.get_meta(furnace_pos)
    furnace_meta:set_string('formspec', 'size[8,9]list[current_name;main;0,0;8,4;]')
    core.registered_nodes['default:furnace'] = {
        description = 'Furnace',
        tiles = { 'default_furnace.png' },
    }

    local orig_get_node_or_nil = core.get_node_or_nil
    core.get_node_or_nil = function(pos)
        if pos and pos.x == 500 and pos.y == 10 and pos.z == 500 then
            return { name = 'default:furnace' }
        elseif pos and pos.x == 501 and pos.y == 10 and pos.z == 500 then
            return { name = 'default:stone' }
        end
        return orig_get_node_or_nil and orig_get_node_or_nil(pos)
    end

    local mock_user = {
        name = 'smelter',
        is_player = function() return true end,
        get_player_name = function(self) return self.name end,
        ctrl = { sneak = false },
        get_player_control = function(self) return self.ctrl end,
        get_wielded_item = function() return ItemStack('waysigns:marker') end,
        set_wielded_item = function() end,
    }

    local pt = { type = 'node', under = furnace_pos, above = { x = 500, y = 11, z = 500 } }
    local marker_item = ItemStack('waysigns:marker')

    -- Case 1: Right-click without sneak -> returns nil (engine passthrough to formspec)
    _G.last_shown_formspec = nil
    mock_user.ctrl.sneak = false
    local t77_res1 = waysigns.on_place_marker(marker_item, mock_user, pt)
    assert(t77_res1 == nil, 'on_place_marker must return nil for node with metadata formspec when not sneaking')
    assert(_G.last_shown_formspec == nil, 'WaySigns formspec must NOT open on standard right-click of furnace')

    -- Case 2: Right-click WITH sneak -> opens inscription formspec
    mock_user.ctrl.sneak = true
    local t77_res2 = waysigns.on_place_marker(marker_item, mock_user, pt)
    assert(t77_res2 ~= nil, 'on_place_marker must return itemstack when sneaking')
    assert(_G.last_shown_formspec ~= nil, 'WaySigns inscription formspec must open when sneak-right-clicking furnace')
    assert(_G.last_shown_formspec.formname == 'waysigns:inscribe', 'Formspec opened must be waysigns:inscribe')

    -- Case 3: Left-click (punch / on_use) -> opens inscription formspec even without sneaking
    _G.last_shown_formspec = nil
    mock_user.ctrl.sneak = false
    local t77_res3 = waysigns.on_use_marker(marker_item, mock_user, pt)
    assert(t77_res3 ~= nil, 'on_use_marker must return itemstack')
    assert(_G.last_shown_formspec ~= nil and _G.last_shown_formspec.formname == 'waysigns:inscribe',
        'on_use_marker must open inscription formspec on furnace')

    -- Case 4: Node without formspec and without on_rightclick (plain stone) -> opens inscription formspec on right-click
    local stone_pos = { x = 501, y = 10, z = 500 }
    core.get_meta(stone_pos):set_string('formspec', '')
    local pt_stone = { type = 'node', under = stone_pos, above = { x = 501, y = 11, z = 500 } }
    _G.last_shown_formspec = nil
    mock_user.ctrl.sneak = false
    local t77_res4 = waysigns.on_place_marker(marker_item, mock_user, pt_stone)
    assert(t77_res4 ~= nil, 'on_place_marker on non-interactive node must return itemstack')
    assert(_G.last_shown_formspec ~= nil and _G.last_shown_formspec.formname == 'waysigns:inscribe',
        'Right-click on plain node must open inscription formspec')

    core.get_node_or_nil = orig_get_node_or_nil
    print('PASS Test 77')
end)()

--- Test 78: Deferred read-time registry saves and persistence hooks
;(function()
    print('--- Test 78: Deferred read-time registry saves and persistence hooks ---')
    -- Track calls to storage:set_string
    local save_count = 0
    local orig_get_mod_storage = core.get_mod_storage
    core.get_mod_storage = function()
        local s = orig_get_mod_storage()
        local orig_set_string = s.set_string
        s.set_string = function(self, k, v)
            if k == 'inscribed_blocks' then
                save_count = save_count + 1
            end
            return orig_set_string(self, k, v)
        end
        return s
    end

    local test_pos = { x = 1100, y = 20, z = 1100 }
    waysigns.unregister_inscribed_pos(test_pos, true)
    local meta = core.get_meta(test_pos)
    meta:set_string('waysigns_text', 'Read Time Discovery')
    meta:set_string('waysigns_plaque', 'wood')
    meta:set_string('waysigns_color', 'white')

    save_count = 0

    -- Query inscription via get_node_inscription
    local insc = waysigns.get_node_inscription(test_pos)
    assert(insc ~= nil and insc.text == 'Read Time Discovery', 'get_node_inscription must return inscription')
    assert(waysigns.get_inscribed_pos(test_pos) ~= nil, 'Position must be self-healed in in-memory spatial index')
    assert(save_count == 0, 'get_node_inscription must NOT call storage:set_string (no_save = true)')

    -- Query sign data via get_sign_data
    local sign_pos = { x = 1102, y = 20, z = 1100 }
    waysigns.unregister_inscribed_pos(sign_pos, true)
    local sign_meta = core.get_meta(sign_pos)
    sign_meta:set_string('waysigns_text', 'Sign Read Discovery')
    sign_meta:set_string('waysigns_plaque', 'slate')
    local sdata = waysigns.get_sign_data(sign_pos, { name = 'default:wood' }, nil)
    assert(sdata ~= nil, 'get_sign_data must return data')
    assert(waysigns.get_inscribed_pos(sign_pos) ~= nil, 'Sign position must be self-healed in memory')
    assert(save_count == 0, 'get_sign_data must NOT trigger disk I/O save')

    -- Execute shutdown hook -> persists to mod storage
    assert(#core.registered_on_shutdown > 0, 'Server shutdown hook must be registered')
    for _, shutdown_fn in ipairs(core.registered_on_shutdown) do
        shutdown_fn()
    end
    assert(save_count >= 1, 'Server shutdown hook must save spatial registry to mod storage')

    -- Restore original storage function & cleanup
    core.get_mod_storage = orig_get_mod_storage
    waysigns.unregister_inscribed_pos(test_pos, true)
    waysigns.unregister_inscribed_pos(sign_pos, true)
    print('PASS Test 78')
end)()

--- Test 79: Unloaded mapblock protection (ignore nodes never purged)
;(function()
    print('--- Test 79: Unloaded mapblock protection (ignore nodes never purged) ---')
    local unloaded_pos = { x = 1200, y = 10, z = 1200 }

    waysigns.register_inscribed_pos(unloaded_pos, {
        text = 'Unloaded Waystone',
        plaque = 'slate',
        color = 'cyan',
        author = 'miner',
    })
    assert(waysigns.get_inscribed_pos(unloaded_pos) ~= nil, 'Unloaded pos must be in spatial registry')

    -- Mock get_node_or_nil returning { name = 'ignore' }
    local orig_get_node_or_nil = core.get_node_or_nil
    core.get_node_or_nil = function(pos)
        if vector.equals(pos, unloaded_pos) then
            return { name = 'ignore', param1 = 0, param2 = 0 }
        end
        return orig_get_node_or_nil(pos)
    end

    local test_player = {
        name = 'spelunker',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        is_valid = function() return true end,
        get_pos = function() return { x = 1200, y = 10, z = 1195 } end,
        get_look_dir = function() return { x = 0, y = 0, z = 1 } end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_wielded_item = function() return ItemStack('waysigns:marker') end,
        hud_add = function() return 1 end,
        hud_change = function() end,
        hud_remove = function() end,
    }
    local player_state = waysigns.get_or_create_player_state(test_player)

    waysigns.update_marker_waypoints(test_player, player_state, 0.25)

    -- Verify that position was NOT erroneously purged!
    assert(waysigns.get_inscribed_pos(unloaded_pos) ~= nil,
        'update_marker_waypoints must NOT purge valid inscribed nodes in unloaded/generating (ignore) mapblocks')

    -- Cleanup
    core.get_node_or_nil = orig_get_node_or_nil
    waysigns.unregister_inscribed_pos(unloaded_pos, true)
    print('PASS Test 79')
end)()

--- Test 80: Low-ceiling / tunnel line-of-sight face probe fallback
;(function()
    print('--- Test 80: Low-ceiling / tunnel line-of-sight face probe fallback ---')
    local tunnel_pos = { x = 1300, y = 5, z = 1300 }
    waysigns.register_inscribed_pos(tunnel_pos, {
        text = 'Mine Shaft 4',
        plaque = 'wood',
        color = 'gold',
        author = 'digger',
    })

    local tunnel_meta = core.get_meta(tunnel_pos)
    tunnel_meta:set_string('waysigns_text', 'Mine Shaft 4')
    tunnel_meta:set_string('waysigns_inscribed', 'true')

    local orig_get_node_or_nil = core.get_node_or_nil
    core.get_node_or_nil = function(pos)
        if vector.equals(pos, tunnel_pos) then
            return { name = 'default:stone', param1 = 0, param2 = 0 }
        end
        return orig_get_node_or_nil(pos)
    end

    -- In a 2-high tunnel, cand.pos at y + 0.65 (y = 5.65) hits ceiling stone at y = 6.
    -- Face probe at the node front surface (y ~ 5.0 - 5.3) is in open air.
    local orig_los = core.line_of_sight
    local los_probes = {}
    core.line_of_sight = function(pos1, pos2)
        los_probes[#los_probes + 1] = pos2
        -- If probing target_pos at y + 0.65 -> blocked by ceiling (return false)
        if math.abs(pos2.y - 5.65) < 0.05 then
            return false
        end
        -- Face probe at visible surface -> unobstructed line of sight (return true)
        return true
    end

    local test_player = {
        name = 'tunnel_rat',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        is_valid = function() return true end,
        get_pos = function() return { x = 1300, y = 5, z = 1296 } end,
        get_look_dir = function() return { x = 0, y = 0, z = 1 } end,
        get_properties = function() return { eye_height = 1.625 } end,
        get_wielded_item = function() return ItemStack('waysigns:marker') end,
        hud_add = function(self, def)
            self._last_hud = def
            return 999
        end,
        hud_change = function() end,
        hud_remove = function() end,
    }
    local player_state = waysigns.get_or_create_player_state(test_player)

    waysigns.update_marker_waypoints(test_player, player_state, 0.25)

    -- Must have probed at least 2 points: the ceiling target pos and the face probe
    assert(#los_probes >= 2, 'Must have attempted face probe when ceiling candidate was blocked')
    assert(player_state.marker_waypoints['1300,5,1300'] ~= nil, 'Waypoint must be visible via face probe fallback')
    assert(test_player._last_hud ~= nil, 'HUD waypoint must be added')
    -- World pos should be the adjusted face pos (y close to 5, not 5.65)
    assert(math.abs(test_player._last_hud.world_pos.y - 5.65) > 0.1,
        'Waypoint world_pos must be placed on visible node face, not inside ceiling')

    -- Cleanup
    core.line_of_sight = orig_los
    core.get_node_or_nil = orig_get_node_or_nil
    waysigns.unregister_inscribed_pos(tunnel_pos, true)
    print('PASS Test 80')
end)()

--- Test 81: Unloaded and ungenerated node safety in marker tools
;(function()
    print('--- Test 81: Unloaded and ungenerated node safety in marker tools ---')
    local ungenerated_pos = { x = 9999, y = 9999, z = 9999 }
    local orig_get_node_or_nil = core.get_node_or_nil

    -- 1. Test when node is completely nil (unloaded/uninitialized)
    core.get_node_or_nil = function(pos)
        if vector.equals(pos, ungenerated_pos) then
            return nil
        end
        return orig_get_node_or_nil(pos)
    end

    local test_player = {
        name = 'explorer',
        get_player_name = function(self) return self.name end,
        is_player = function() return true end,
        get_player_control = function() return {} end,
        privs = {},
    }

    _G.last_shown_formspec = nil
    -- Must not raise an error or open a formspec
    waysigns.show_node_inscription_formspec(test_player, ungenerated_pos)
    assert(_G.last_shown_formspec == nil, 'show_node_inscription_formspec must not open formspec when node is nil')

    local marker_stack = ItemStack('waysigns:marker')
    local pointed = { type = 'node', under = ungenerated_pos }
    local res_use = waysigns.on_use_marker(marker_stack, test_player, pointed)
    assert(res_use ~= nil, 'on_use_marker must return itemstack on nil node')
    assert(_G.last_shown_formspec == nil, 'on_use_marker must not open formspec on nil node')

    local res_place = waysigns.on_place_marker(marker_stack, test_player, pointed)
    assert(res_place ~= nil, 'on_place_marker must return itemstack on nil node')

    -- 2. Test when node is 'ignore' (unloaded/generating mapblock)
    core.get_node_or_nil = function(pos)
        if vector.equals(pos, ungenerated_pos) then
            return { name = 'ignore', param1 = 0, param2 = 0 }
        end
        return orig_get_node_or_nil(pos)
    end

    _G.last_shown_formspec = nil
    waysigns.show_node_inscription_formspec(test_player, ungenerated_pos)
    assert(_G.last_shown_formspec == nil, 'show_node_inscription_formspec must not open formspec on ignore node')

    res_use = waysigns.on_use_marker(marker_stack, test_player, pointed)
    assert(res_use ~= nil, 'on_use_marker must return itemstack on ignore node')
    assert(_G.last_shown_formspec == nil, 'on_use_marker must not open formspec on ignore node')

    res_place = waysigns.on_place_marker(marker_stack, test_player, pointed)
    assert(res_place ~= nil, 'on_place_marker must return itemstack on ignore node')

    -- Cleanup
    core.get_node_or_nil = orig_get_node_or_nil
    print('PASS Test 81')
end)()

--- Test 82: Mod storage resilience during on_shutdown when core.get_mod_storage() returns nil
;(function()
    print('--- Test 82: Mod storage resilience during on_shutdown when core.get_mod_storage() returns nil ---')
    local saved_json = nil
    local mock_storage = {
        get_string = function(self, k) return '' end,
        set_string = function(self, k, v)
            if k == 'inscribed_blocks' then
                saved_json = v
            end
        end,
    }

    -- Prime the cached storage reference
    waysigns.mod_storage = mock_storage

    -- Simulate Luanti on_shutdown environment where get_current_modname() is empty and get_mod_storage() returns nil
    local orig_get_mod_storage = core.get_mod_storage
    core.get_mod_storage = function()
        return nil
    end

    -- Call save_inscribed_registry: must NOT throw attempt to index local 'storage' (a nil value)
    local test_pos = { x = 777, y = 10, z = 777 }
    waysigns.register_inscribed_pos(test_pos, {
        text = 'Shutdown Waypoint',
        plaque = 'gold',
        color = 'gold',
        author = 'admin',
    }, true)

    waysigns.save_inscribed_registry()
    assert(saved_json ~= nil, 'save_inscribed_registry must successfully save to cached storage when get_mod_storage() is nil')
    local last_saved = core._mod_storage_store['__last_table__']
    assert(last_saved ~= nil, 'Saved storage must contain serialized table')
    local bkey = waysigns.pos_to_block_key(test_pos)
    local pkey = waysigns.pos_to_key(test_pos)
    assert(last_saved[bkey] and last_saved[bkey][pkey] and last_saved[bkey][pkey].text == 'Shutdown Waypoint',
        'Saved JSON store must contain inscription data')

    -- Edge case: even if cached storage is completely nil, must return gracefully without error
    waysigns.mod_storage = nil
    waysigns.save_inscribed_registry()

    -- Cleanup
    core.get_mod_storage = orig_get_mod_storage
    waysigns.mod_storage = orig_get_mod_storage()
    waysigns.unregister_inscribed_pos(test_pos, true)
    print('PASS Test 82')
end)()

print('--- Test 83: Silent protection checks without chat spam and TTL caching ---')
;(function()
    waysigns.clear_caches()

    local prot_pos = { x = 999, y = 5, z = 999 }
    local node = { name = 'default:chest' }
    local meta = {
        get_inventory = function()
            return {
                get_list = function(self, lname)
                    if lname == 'main' then
                        return {
                            {
                                is_empty = function() return false end,
                                get_name = function() return 'default:gold_ingot' end,
                                get_count = function() return 10 end,
                                get_short_description = function() return 'Gold Ingot' end,
                            }
                        }
                    end
                    return {}
                end
            }
        end,
        get_string = function(self, k) return '' end,
    }

    local chat_spam_count = 0
    local orig_chat = core.chat_send_player
    local orig_violation = core.record_protection_violation
    local orig_is_protected = core.is_protected
    local is_protected_call_count = 0

    core.chat_send_player = function(name, msg)
        chat_spam_count = chat_spam_count + 1
    end

    core.record_protection_violation = function(pos, name)
        chat_spam_count = chat_spam_count + 1
    end

    -- Simulate a protection mod (like protector) that sends chat messages during core.is_protected
    core.is_protected = function(pos, name)
        is_protected_call_count = is_protected_call_count + 1
        if name == 'intruder' then
            core.chat_send_player(name, 'This area is protected by Protector.')
            return true
        end
        return false
    end

    local intruder_player = {
        get_player_name = function() return 'intruder' end,
    }

    -- 1. Extract inventory on protected container: must return nil and NEVER spam chat
    local qv = waysigns.extract_node_inventory(prot_pos, node, meta, intruder_player)
    assert(qv == nil, 'Protected container must return nil for intruder')
    assert(chat_spam_count == 0, 'Zero chat messages or violations must be sent during passive pointing (got ' .. chat_spam_count .. ')')
    assert(is_protected_call_count == 1, 'is_protected should be called once on initial query')

    -- 2. Repeated check within TTL (1.0s) should hit protection_cache without calling core.is_protected
    local qv2 = waysigns.extract_node_inventory(prot_pos, node, meta, intruder_player)
    assert(qv2 == nil, 'Protected container must return nil on cached query')
    assert(is_protected_call_count == 1, 'Repeated raycast check within TTL must use protection_cache (expected 1 call, got ' .. is_protected_call_count .. ')')
    assert(chat_spam_count == 0, 'Cached check must remain completely silent')

    -- 3. Cache invalidation on punch/dig/place at this position
    waysigns.invalidate_cache(prot_pos)
    local qv3 = waysigns.extract_node_inventory(prot_pos, node, meta, intruder_player)
    assert(qv3 == nil, 'Protected container still blocked')
    assert(is_protected_call_count == 2, 'Cache invalidation must force fresh query on next check')
    assert(chat_spam_count == 0, 'Fresh check must also be silenced')

    -- 4. Protection bypass privilege skips core.is_protected completely
    local orig_check_privs = core.check_player_privs
    core.check_player_privs = function(player, priv)
        return priv == 'protection_bypass'
    end
    local qv_bypass = waysigns.extract_node_inventory(prot_pos, node, meta, intruder_player)
    assert(qv_bypass ~= nil and #qv_bypass.items > 0, 'Player with protection_bypass can see container items')
    assert(is_protected_call_count == 2, 'Bypass check must short-circuit before calling is_protected')

    -- 5. Cleanup on player leave
    waysigns.on_leaveplayer(intruder_player)
    local hash = core.hash_node_position(prot_pos)
    local key = hash .. ':intruder'
    assert(waysigns.protection_cache[key] == nil, 'Player protection_cache entries must be cleared on disconnect')

    -- Restore mocks
    core.chat_send_player = orig_chat
    core.record_protection_violation = orig_violation
    core.is_protected = orig_is_protected
    core.check_player_privs = orig_check_privs
    waysigns.clear_caches()
    print('PASS Test 83')
end)()

-- [Test 84 deferred to owner color feature]

print('================ ALL 83 UNIT TESTS PASSED ================')







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
        return {
            get_string = function(self, key)
                return pos.meta and pos.meta[key] or ''
            end
        }
    end,
    raycast = function() return function() return nil end end,
    register_globalstep = function() end,
    register_on_joinplayer = function() end,
    register_on_leaveplayer = function() end,
    register_on_dieplayer = function() end,
    register_on_punchnode = function() end,
    register_on_dignode = function() end,
    register_on_placenode = function() end,
    global_exists = function(name) return _G[name] ~= nil end,
    registered_entities = {},
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
    after = function(delay, func) func() end,
    get_node = function(pos) return {name = 'air', param1 = 0, param2 = 0} end,
    strip_colors = function(str) return str:gsub('\x1b%b()', ''):gsub('\x1b(.)', '') end,
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

vector = {
    new = function(x, y, z) return {x = x or 0, y = y or 0, z = z or 0} end,
    add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
    subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
    multiply = function(a, s) return {x = a.x * s, y = a.y * s, z = a.z * s} end,
    dot = function(a, b) return (a.x * b.x) + (a.y * b.y) + (a.z * b.z) end,
    equals = function(a, b) return a and b and a.x == b.x and a.y == b.y and a.z == b.z end,
    round = function(p) return {x = math.floor(p.x + 0.5), y = math.floor(p.y + 0.5), z = math.floor(p.z + 0.5)} end,
}

bit = bit or {
    band = function(...)
        local args = {...}
        local res = args[1] or 0
        for i = 2, #args do res = res & args[i] end
        return res
    end,
    bor = function(...)
        local args = {...}
        local res = args[1] or 0
        for i = 2, #args do res = res | args[i] end
        return res
    end,
    lshift = function(a, b) return a << b end,
    rshift = function(a, b) return a >> b end,
}

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
    get_luaentity = function() return { name = 'signs_lib:text' } end,
    remove = function(self) table.insert(removed_entities, 'signs_lib:text') end,
}
local mock_ent2 = {
    get_luaentity = function() return { name = 'mcl_signs:text' } end,
    remove = function(self) table.insert(removed_entities, 'mcl_signs:text') end,
}
local mock_ent_other = {
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
local wp_bg = captured_hud_defs[screen_state.hud_bg_id]
assert(wp_bg.type == 'image_waypoint', 'Expected image_waypoint for waypoint mode')
assert(wp_bg.world_pos.z == face_pos1.z, 'Expected waypoint world_pos to equal sign_face_pos')

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
assert(bg_op2 and math.abs(bg_op2 - 226) <= 2, 'Expected background opacity around 226, got ' .. tostring(bg_op2))
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
assert(bg_anim:find(waysigns.FALLBACK_STEEL), 'Expected fallback for [verticalframe')

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
local entities_purged = {}
local mock_ent_obj = function(ename)
    return {
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
local ch1_num = mock_hosp_player.hud_changes[line1_id].number or line1_def.number
local ch2_num = mock_hosp_player.hud_changes[line2_id].number or line2_def.number
assert(ch1_num == 0x55FF55, 'Line 1 must stay 0x55FF55 green during fade-in, got: ' .. string.format('0x%06X', ch1_num))
assert(ch2_num == 0xFFFFFF, 'Line 2 must stay 0xFFFFFF white during fade-in, got: ' .. string.format('0x%06X', ch2_num))

print('PASS Test 35')

print('--- Test 36: Optional street_signs entity preservation toggle ---')
local function run_test_36()
    -- 1. Verify setting default is false
    assert(waysigns.settings.enable_street_signs_entities == false, 'enable_street_signs_entities must default to false')

    -- 2. When toggle is false: entities on street_signs are purged
    local entities_purged_t36 = {}
    local mock_ent_t36 = function(ename, pos)
        return {
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

print('================ ALL 41 UNIT TESTS PASSED ================')

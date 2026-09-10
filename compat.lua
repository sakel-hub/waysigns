--[[
    WaySigns. Dynamic HUD waypoints and backgrounds for signs in Luanti.
    Copyright (C) 2026 SaKeL

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, see <https://www.gnu.org/licenses/>.
--]]

-- Register standard Luanti Game signs if present
if core.get_modpath('default') then
    waysigns.register_sign('default:sign_wall_wood', {
        tile = 'default_sign_wall_wood.png',
        text_color = 0xFFFFFF,
        is_metal = false,
        aspect_ratio = 1.4,
    })

    waysigns.register_sign('default:sign_wall_steel', {
        tile = 'default_sign_wall_steel.png',
        text_color = 0xEEEEEE,
        is_metal = true,
        aspect_ratio = 1.4,
    })
end

-- Register signs_lib signs if present
if core.get_modpath('signs_lib') then
    local signs_lib_materials = {
        'wood', 'steel', 'cedar', 'oak', 'pine', 'birch', 'willow',
        'rubber_tree', 'redwood', 'frost', 'yellow_wood', 'palm', 'acacia',
        'aspen', 'junglewood'
    }

    for _, mat in ipairs(signs_lib_materials) do
        local is_steel = (mat == 'steel')
        local tile_name = is_steel and 'signs_lib_sign_wall_steel.png^[sheet:2x1:0,0'
            or 'signs_lib_sign_wall_wooden.png^[sheet:2x1:0,0'

        waysigns.register_sign('signs:sign_wall_' .. mat, {
            tile = tile_name,
            text_color = 0xFFFFFF,
            is_metal = is_steel,
            aspect_ratio = 1.4,
        })

        waysigns.register_sign('signs:sign_post_' .. mat, {
            tile = tile_name,
            text_color = 0xFFFFFF,
            is_metal = is_steel,
            aspect_ratio = 1.4,
        })

        waysigns.register_sign('signs:sign_hanging_' .. mat, {
            tile = tile_name,
            text_color = 0xFFFFFF,
            is_metal = is_steel,
            aspect_ratio = 1.4,
        })

        waysigns.register_sign('signs:sign_yard_' .. mat, {
            tile = tile_name,
            text_color = 0xFFFFFF,
            is_metal = is_steel,
            aspect_ratio = 1.4,
        })
    end

    -- Patch signs_lib registered nodes so wooden signs default to high-contrast white text ('f')
    -- rather than illegible black ('0') when edited or rendered
    core.register_on_mods_loaded(function()
        for _, nodename in ipairs({'default:sign_wall_wood', 'default:sign_wall_steel'}) do
            local ndef = core.registered_nodes[nodename]
            if ndef and (not ndef.default_color or ndef.default_color == '0') then
                core.override_item(nodename, { default_color = 'f' })
            end
        end
        for _, mat in ipairs(signs_lib_materials) do
            for _, prefix in ipairs({'signs:sign_wall_', 'signs:sign_post_', 'signs:sign_hanging_', 'signs:sign_yard_'}) do
                local nodename = prefix .. mat
                local ndef = core.registered_nodes[nodename]
                if ndef and (not ndef.default_color or ndef.default_color == '0') then
                    core.override_item(nodename, { default_color = 'f' })
                end
            end
        end
    end)
end

-- Register basic_signs if present
if core.get_modpath('basic_signs') then
    local bs_materials = {
        { name = 'locked', is_metal = true, color = 0xEEEEEE, is_light_bg = false },
        { name = 'glass', is_metal = false, color = 0xFFFFFF, is_glass = true },
        { name = 'obsidian_glass', is_metal = false, color = 0xFFFFFF, is_glass = true },
        { name = 'plastic', is_metal = false, color = 0x222222, is_light_bg = true },
    }

    for _, def in ipairs(bs_materials) do
        local tile = 'basic_signs_sign_wall_' .. def.name .. '.png^[sheet:2x1:0,0'
        local mdef = {
            tile = tile,
            text_color = def.color,
            is_metal = def.is_metal,
            is_light_bg = def.is_light_bg,
            is_glass = def.is_glass,
            aspect_ratio = 1.4,
        }
        waysigns.register_sign('basic_signs:sign_wall_' .. def.name, mdef)
        waysigns.register_sign('basic_signs:sign_' .. def.name .. '_onpole', mdef)
        waysigns.register_sign('basic_signs:sign_' .. def.name .. '_onpole_horiz', mdef)
        waysigns.register_sign('basic_signs:sign_' .. def.name .. '_hanging', mdef)
        waysigns.register_sign('basic_signs:sign_' .. def.name .. '_yard', mdef)
    end

    local bs_colors = {
        { 'green', 0xFFFFFF, false },
        { 'yellow', 0x222222, true },
        { 'red', 0xFFFFFF, false },
        { 'white_red', 0xEE3333, true },
        { 'white_black', 0x222222, true },
        { 'orange', 0x222222, true },
        { 'blue', 0xFFFFFF, false },
        { 'brown', 0xFFFFFF, false },
    }

    for _, cdef in ipairs(bs_colors) do
        local cname = cdef[1]
        local ccolor = cdef[2]
        local clight = cdef[3]
        local tile = 'basic_signs_steel_' .. cname .. '.png^[sheet:2x1:0,0'
        local sdef = {
            tile = tile,
            text_color = ccolor,
            is_metal = true,
            is_light_bg = clight,
            aspect_ratio = 1.4,
        }

        waysigns.register_sign('basic_signs:sign_wall_steel_' .. cname, sdef)
        waysigns.register_sign('basic_signs:sign_steel_' .. cname .. '_onpole', sdef)
        waysigns.register_sign('basic_signs:sign_steel_' .. cname .. '_onpole_horiz', sdef)
        waysigns.register_sign('basic_signs:sign_steel_' .. cname .. '_hanging', sdef)
        waysigns.register_sign('basic_signs:sign_steel_' .. cname .. '_yard', sdef)
    end
end

-- Register xdecor mailbox / notices if present
if core.get_modpath('xdecor') then
    waysigns.register_sign('xdecor:mailbox', {
        tile = 'xdecor_mailbox_side.png',
        text_color = 0xFFFFFF,
        is_metal = true,
        aspect_ratio = 1.0,
    })
end

-- Register street_signs (road, street blades, and highway signs) if present
if core.get_modpath('street_signs') then
    -- 1. Street name blades: crop to single front blade (32x10)
    local street_blade_def = {
        tile = '[combine:32x10:0,-2=street_signs_basic.png',
        text_color = 0xFFFFFF,
        is_metal = true,
        aspect_ratio = 3.2,
    }
    waysigns.register_sign('street_signs:sign_basic', street_blade_def)
    waysigns.register_sign('street_signs:sign_basic_top_only', street_blade_def)
    waysigns.register_sign('street_signs:street_sign_bispot', street_blade_def)
    waysigns.register_sign('street_signs:street_sign_quadspot', street_blade_def)

    -- 2. Highway gantries (small, medium, large, and 1x1-4x1 across green, blue, yellow, orange)
    -- All highway signs are 1x2 sheets: top half is front face, bottom half is gray back
    local highway_sizes = {
        small = 2.0,
        medium = 2.0,
        large = 2.5,
        ['1x1'] = 2.0,
        ['2x1'] = 2.2,
        ['3x1'] = 2.5,
        ['4x1'] = 2.5,
    }
    local highway_colors = {
        green = 0xFFFFFF,
        blue = 0xFFFFFF,
        yellow = 0x222222,
        orange = 0x222222,
    }
    for size, ar in pairs(highway_sizes) do
        for color, text_col in pairs(highway_colors) do
            local hdef = {
                tile = 'street_signs_generic_highway_' .. size .. '_' .. color .. '.png^[sheet:1x2:0,0',
                text_color = text_col,
                is_metal = true,
                is_light_bg = (color == 'yellow' or color == 'orange'),
                aspect_ratio = ar,
            }
            waysigns.register_sign('street_signs:sign_highway_' .. size .. '_' .. color, hdef)
            waysigns.register_sign('street_signs:sign_highway_widefont_' .. size .. '_' .. color, hdef)
        end
    end

    -- 3. Standard warning and distance text signs (2x1 sheets: left half is diamond)
    local warn_yellow = {
        tile = 'street_signs_warning.png^[sheet:2x1:0,0',
        text_color = 0x222222,
        is_metal = true,
        is_light_bg = true,
        aspect_ratio = 1.2,
    }
    local warn_orange = {
        tile = 'street_signs_warning_orange.png^[sheet:2x1:0,0',
        text_color = 0x222222,
        is_metal = true,
        is_light_bg = true,
        aspect_ratio = 1.2,
    }
    waysigns.register_sign('street_signs:sign_warning_3_line', warn_yellow)
    waysigns.register_sign('street_signs:sign_warning_4_line', warn_yellow)
    waysigns.register_sign('street_signs:sign_warning_orange_3_line', warn_orange)
    waysigns.register_sign('street_signs:sign_warning_orange_4_line', warn_orange)
    waysigns.register_sign('street_signs:sign_distance_2_lines', warn_yellow)
    waysigns.register_sign('street_signs:sign_distance_2_lines_orange', warn_orange)

    -- 4. Divided highway signs
    waysigns.register_sign('street_signs:sign_divided_highway_begins', warn_yellow)
    waysigns.register_sign('street_signs:sign_divided_highway_ends', warn_yellow)
    waysigns.register_sign('street_signs:sign_divided_highway_with_cross_road', {
        tile = '[combine:256x256:0,0=street_signs_divided_highway_with_cross_road.png',
        text_color = 0x222222,
        is_metal = true,
        is_light_bg = true,
        aspect_ratio = 1.2,
    })

    -- 5. Service signs (2x1 sheet: left half is front face)
    local service_hospital = { tile = 'street_signs_service_hospital.png^[sheet:2x1:0,0', text_color = 0xFFFFFF, is_metal = true, aspect_ratio = 1.0 }
    local service_fuel = { tile = 'street_signs_service_fuel.png^[sheet:2x1:0,0', text_color = 0xFFFFFF, is_metal = true, aspect_ratio = 1.0 }
    local service_food = { tile = 'street_signs_service_food.png^[sheet:2x1:0,0', text_color = 0xFFFFFF, is_metal = true, aspect_ratio = 1.0 }
    local service_lodging = { tile = 'street_signs_service_lodging.png^[sheet:2x1:0,0', text_color = 0xFFFFFF, is_metal = true, aspect_ratio = 1.0 }
    waysigns.register_sign('street_signs:sign_service_hospital', service_hospital)
    waysigns.register_sign('street_signs:sign_service_fuel', service_fuel)
    waysigns.register_sign('street_signs:sign_service_food', service_food)
    waysigns.register_sign('street_signs:sign_service_lodging', service_lodging)

    -- 6. US Highway & Interstate shields (3D mesh models: use clean steel signboard plaque fallback)
    local us_shield_def = { tile = waysigns.FALLBACK_STEEL, text_color = 0xFFFFFF, is_metal = true, aspect_ratio = 1.0 }
    waysigns.register_sign('street_signs:sign_us_interstate', us_shield_def)
    waysigns.register_sign('street_signs:sign_us_route', us_shield_def)

    -- 7. Detour signs (1x2 vertical sheet: top half is front arrow)
    local detour_def = { tile = 'street_signs_detour_right_m4_10.png^[sheet:1x2:0,0', text_color = 0x111111, is_metal = true, is_light_bg = true, aspect_ratio = 2.67 }
    local detour_l_def = { tile = 'street_signs_detour_left_m4_10.png^[sheet:1x2:0,0', text_color = 0x111111, is_metal = true, is_light_bg = true, aspect_ratio = 2.67 }
    waysigns.register_sign('street_signs:sign_detour_right_m4_10', detour_def)
    waysigns.register_sign('street_signs:sign_detour_left_m4_10', detour_l_def)
end

-- Register display_modpack (signs, boards, steles) if present
if not core.get_modpath('signs_lib') and (core.get_modpath('signs') or core.get_modpath('display_modpack')) then
    local display_wood = { text_color = 0xFFFFFF, is_metal = false, aspect_ratio = 1.4 }
    waysigns.register_sign('signs:sign_wall_wood', display_wood)
    waysigns.register_sign('signs:sign_post_wood', display_wood)
    waysigns.register_sign('signs:sign_yard_wood', display_wood)
    waysigns.register_sign('signs:sign_hanging_wood', display_wood)
end

if core.get_modpath('signs') or core.get_modpath('display_modpack') then
    waysigns.register_sign('signs:paper_poster', {
        text_color = 0x1A1A1A,
        is_metal = false,
        is_light_bg = true,
        aspect_ratio = 0.8,
    })
    local dir_wood = { text_color = 0xFFFFFF, is_metal = false, aspect_ratio = 2.0 }
    waysigns.register_sign('signs:wooden_left_sign', dir_wood)
    waysigns.register_sign('signs:wooden_right_sign', dir_wood)
    waysigns.register_sign('signs:wooden_sign', { text_color = 0xFFFFFF, is_metal = false, aspect_ratio = 1.2 })
    waysigns.register_sign('signs:wooden_long_sign', { text_color = 0xFFFFFF, is_metal = false, aspect_ratio = 2.3 })
    waysigns.register_sign('signs:label_small', { text_color = 0x1A1A1A, is_metal = false, is_light_bg = true, aspect_ratio = 1.0 })
    waysigns.register_sign('signs:label_medium', { text_color = 0x1A1A1A, is_metal = false, is_light_bg = true, aspect_ratio = 1.0 })
end

if core.get_modpath('signs_road') or core.get_modpath('display_modpack') then
    local road_blue = { text_color = 0xFFFFFF, is_metal = true, aspect_ratio = 1.2 }
    waysigns.register_sign('signs_road:blue_street_sign', road_blue)
    waysigns.register_sign('signs_road:green_street_sign', road_blue)
    waysigns.register_sign('signs_road:white_street_sign', { text_color = 0x1A1A1A, is_metal = true, is_light_bg = true, aspect_ratio = 1.2 })
    waysigns.register_sign('signs_road:yellow_street_sign', { text_color = 0x1A1A1A, is_metal = true, is_light_bg = true, aspect_ratio = 1.2 })
end

if core.get_modpath('boards') or core.get_modpath('display_modpack') then
    local board_def = { text_color = 0xFFFFFF, is_metal = true, aspect_ratio = 1.8 }
    waysigns.register_sign('boards:board_wall_black', board_def)
    waysigns.register_sign('boards:board_wall_green', board_def)
    waysigns.register_sign('boards:black_board', board_def)
    waysigns.register_sign('boards:green_board', board_def)
end

if core.get_modpath('steles') or core.get_modpath('display_modpack') then
    local stele_def = { text_color = 0xFFFFFF, is_metal = false, aspect_ratio = 0.7 }
    waysigns.register_sign('steles:stele_wood', stele_def)
    waysigns.register_sign('steles:sandstone_stele', {
        text_color = 0x1A1A1A,
        is_metal = false,
        is_light_bg = true,
        aspect_ratio = 0.7,
    })
    waysigns.register_sign('steles:stone_stele', {
        text_color = 0xFFFFFF,
        is_metal = true,
        aspect_ratio = 0.7,
    })
end

-- Register locks shared locked sign if present
if core.get_modpath('locks') then
    waysigns.register_sign('locks:shared_locked_sign_wall', {
        tile = waysigns.FALLBACK_WOOD,
        text_color = 0xFFFFFF,
        is_metal = false,
        aspect_ratio = 1.4,
    })
end

-- Register breadcrumbs cave marker if present
if core.get_modpath('breadcrumbs') then
    waysigns.register_sign('breadcrumbs:marker', {
        tile = 'breadcrumbs_wall.png',
        text_color = 0xFFFFFF,
        is_metal = false,
        aspect_ratio = 1.0,
    })
end

-- Register mcl_signs (VoxeLibre / MineClone2 / Mineclonia) if present
if core.get_modpath('mcl_signs') then
    local mcl_woods = {
        'wood', 'acacia', 'birch', 'dark_oak', 'jungle', 'spruce',
        'mangrove', 'cherry', 'bamboo', 'crimson', 'warped'
    }
    for _, w in ipairs(mcl_woods) do
        local mcl_tile = (w == 'crimson') and 'mcl_core_planks_crimson.png'
            or (w == 'warped') and 'mcl_core_planks_warped.png'
            or (core.get_modpath('mcl_core') and ('mcl_core_planks_' .. (w == 'wood' and 'oak' or w) .. '.png'))
            or waysigns.FALLBACK_WOOD
        local sdef = { tile = mcl_tile, text_color = 0xFFFFFF, is_metal = false, aspect_ratio = 1.4 }
        waysigns.register_sign('mcl_signs:wall_sign_' .. w, sdef)
        waysigns.register_sign('mcl_signs:standing_sign_' .. w, sdef)
        waysigns.register_sign('mcl_signs:hanging_sign_' .. w, sdef)
    end
end

-- Register jp_signs (Japanese signs) if present
if core.get_modpath('jp_signs') then
    waysigns.register_sign('jp_signs:board', {
        tile = waysigns.FALLBACK_WOOD,
        text_color = 0xFFFFFF,
        is_metal = false,
        aspect_ratio = 1.4,
    })
end

-- Register ucsigns if present (3D mesh signs: use clean oak wood plaque fallback)
if core.get_modpath('ucsigns') then
    local uc_def = {
        tile = waysigns.FALLBACK_WOOD,
        text_color = 0xFFFFFF,
        is_metal = false,
        aspect_ratio = 1.4,
    }
    waysigns.register_sign('ucsigns:wall_sign_wood', uc_def)
    waysigns.register_sign('ucsigns:standing_sign_wood', uc_def)

    -- Custom resolver for all ucsigns wood and standing sign variants
    table.insert(waysigns.custom_resolvers, function(pos, node)
        if node.name:find('^ucsigns:') or core.get_item_group(node.name, 'ucsign') > 0 then
            local meta = core.get_meta(pos)
            local text = waysigns.extract_text(meta)
            if not text then return nil end
            local is_metal = waysigns.is_metal_node(node.name)
            local wood_base = waysigns.FALLBACK_WOOD
            local tile = is_metal and waysigns.FALLBACK_STEEL or wood_base
            local nname = node.name:lower()
            if not is_metal then
                if nname:find('acacia') then
                    tile = wood_base .. '^[colorize:#a03818:50'
                elseif nname:find('aspen') or nname:find('birch') then
                    tile = wood_base .. '^[colorize:#e5d5b0:40'
                elseif nname:find('jungle') then
                    tile = wood_base .. '^[colorize:#4e2210:60'
                elseif nname:find('pine') or nname:find('spruce') or nname:find('dark') then
                    tile = wood_base .. '^[colorize:#22150a:70'
                end
            end
            return {
                text = text,
                tile = tile,
                text_color = 0xFFFFFF,
                is_metal = is_metal,
                aspect_ratio = 1.4,
            }
        end
        return nil
    end)
end

-- Register hiking signs if present
-- Uses clean wooden trail plaques with trail color glazes, ensuring 100% readable text without pixel noise
if core.get_modpath('hiking') then
    local hiking_colours = {
        { name = 'red', colour = '991111', is_light = false, text_col = 0xFFFFFF },
        { name = 'blue', colour = '113399', is_light = false, text_col = 0xFFFFFF },
        { name = 'green', colour = '117722', is_light = false, text_col = 0xFFFFFF },
        { name = 'yellow', colour = 'bb9911', is_light = true, text_col = 0x111111 },
    }
    local hiking_styles = {
        { id = 'sign', ar = 1.4 },
        { id = 'sign_left', ar = 2.2 },
        { id = 'sign_right', ar = 2.2 },
        { id = 'peak', ar = 1.4 },
        { id = 'peak_left', ar = 2.2 },
        { id = 'peak_right', ar = 2.2 },
        { id = 'spring', ar = 1.4 },
        { id = 'spring_left', ar = 2.2 },
        { id = 'spring_right', ar = 2.2 },
        { id = 'castle', ar = 1.4 },
        { id = 'castle_left', ar = 2.2 },
        { id = 'castle_right', ar = 2.2 },
        { id = 'educational', ar = 1.4 },
        { id = 'educational_left', ar = 2.2 },
        { id = 'educational_right', ar = 2.2 },
        { id = 'local', ar = 1.4 },
        { id = 'local_left', ar = 2.2 },
        { id = 'local_right', ar = 2.2 },
        { id = 'end', ar = 1.4 },
    }
    for _, c in ipairs(hiking_colours) do
        for _, s in ipairs(hiking_styles) do
            local wall_tile = waysigns.FALLBACK_WOOD .. '^[colorize:#' .. c.colour .. ':40'
            local pole_tile = waysigns.FALLBACK_STEEL .. '^[sheet:2x1:0,0^[colorize:#' .. c.colour .. ':35'

            local hdef_wall = {
                tile = wall_tile,
                text_color = c.text_col,
                is_metal = false,
                is_light_bg = c.is_light,
                aspect_ratio = s.ar,
            }
            local hdef_pole = {
                tile = pole_tile,
                text_color = c.text_col,
                is_metal = true,
                is_light_bg = c.is_light,
                aspect_ratio = s.ar,
            }
            waysigns.register_sign('hiking:' .. s.id .. c.name, hdef_wall)
            waysigns.register_sign('hiking:pole_' .. s.id .. c.name, hdef_pole)
            waysigns.register_sign('hiking:pole2_' .. s.id .. c.name, hdef_pole)
        end
    end
end

---Split composite texture string by overlay operator '^' (ignoring '^[' modifiers and parenthesized groups)
---Preserves texture modifiers (e.g. ^[transformFX, ^[sheet:...) attached to each layer
---@param str string Raw composite texture string
---@return string[] layers Array of texture layer strings
local function split_texture_layers(str)
    local layers = {}
    local cur = {}
    local i = 1
    local len = #str
    local paren_depth = 0
    while i <= len do
        local c = str:sub(i, i)
        if c == '(' then
            paren_depth = paren_depth + 1
            table.insert(cur, c)
        elseif c == ')' then
            paren_depth = math.max(0, paren_depth - 1)
            table.insert(cur, c)
        elseif c == '^' and paren_depth == 0 and str:sub(i + 1, i + 1) ~= '[' then
            table.insert(layers, table.concat(cur))
            cur = {}
        else
            table.insert(cur, c)
        end
        i = i + 1
    end
    if #cur > 0 then
        table.insert(layers, table.concat(cur))
    end
    return layers
end

---Check if a layer in a composite texture is an obsolete sign text or entity artifact
---@param layer string Layer texture string
---@return boolean is_artifact True if the layer should be discarded
local function is_unwanted_sign_artifact(layer)
    local lower = layer:lower()
    if lower:find('signs_lib_text')
        or lower:find('mcl_signs_text')
        or lower:find('_text%.png')
        or lower:find('sign_text%.png')
        or lower:find('lock16%.png')
        or lower:find('signs_lib_lock')
        or lower:find('_edges%.png')
        or lower:find('_inv%.png')
        or lower:find('pole_mount') then
        return true
    end
    return false
end

waysigns.animated_frame_cache = waysigns.animated_frame_cache or {}

---Inspect PNG image header or animation metadata to determine vertical frame count
---@param base string Clean texture filename (e.g. "xdecor_television_front_animated.png")
---@param modname string|nil Inferred mod name (e.g. "xdecor")
---@param aspect_w number|nil Frame width (default 16)
---@param aspect_h number|nil Frame height (default 16)
---@return number num_frames Detected number of vertical frames (>= 1)
function waysigns.get_texture_frame_count(base, modname, aspect_w, aspect_h)
    if not base or base == '' then return 1 end
    if waysigns.animated_frame_cache[base] ~= nil then
        return waysigns.animated_frame_cache[base]
    end

    aspect_w = aspect_w or 16
    aspect_h = aspect_h or 16

    local candidates = {}
    if modname then
        local mp = core.get_modpath(modname)
        if mp then
            table.insert(candidates, mp .. '/textures/' .. base)
        end
    end
    local inferred_mod = base:match('^([%w_]+)_')
    if inferred_mod and inferred_mod ~= modname then
        local mp = core.get_modpath(inferred_mod)
        if mp then
            table.insert(candidates, mp .. '/textures/' .. base)
        end
    end

    for _, path in ipairs(candidates) do
        local f = io.open(path, 'rb')
        if f then
            local header = f:read(24)
            f:close()
            if header and #header >= 24 and header:sub(1, 8) == '\137PNG\r\n\026\n' and header:sub(13, 16) == 'IHDR' then
                local b = { header:byte(17, 24) }
                local pw = b[1] * 16777216 + b[2] * 65536 + b[3] * 256 + b[4]
                local ph = b[5] * 16777216 + b[6] * 65536 + b[7] * 256 + b[8]
                if pw > 0 and ph > pw then
                    local frame_h = math.floor(pw * (aspect_h / aspect_w))
                    if frame_h > 0 then
                        local num_frames = math.floor(ph / frame_h)
                        if num_frames > 1 then
                            waysigns.animated_frame_cache[base] = num_frames
                            return num_frames
                        end
                    end
                end
                waysigns.animated_frame_cache[base] = 1
                return 1
            end
        end
    end

    waysigns.animated_frame_cache[base] = 1
    return 1
end

---Sanitize and extract the clean base texture name from a node definition tile
---Combines multi-layer visual specs (e.g. beehive honey overlays, state overlays)
---while stripping obsolete sign text entities and preserving layer transformations.
---Detects animated texture sheets (e.g. xdecor:television, furnaces, torches) and crops frame 0.
---@param raw_tile any String or table definition from node_def.tiles
---@param is_metal boolean|nil Whether sign is metal/stone (determines fallback texture)
---@param nodename string|nil Technical node name for mod/asset location
---@return string tile_str Sanitized clean texture filename for background generation
local function clean_tile_name(raw_tile, is_metal, nodename)
    local fallback = is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD
    if not raw_tile then
        return fallback
    end

    local anim_def = nil
    local tile_str = ''
    if type(raw_tile) == 'string' then
        tile_str = raw_tile
    elseif type(raw_tile) == 'table' then
        if raw_tile.animation then
            anim_def = raw_tile.animation
        end
        if raw_tile.name then
            tile_str = raw_tile.name
            if raw_tile.color and raw_tile.color ~= 'white' and raw_tile.color ~= '' then
                tile_str = tile_str .. '^[multiply:' .. raw_tile.color
            end
        end
    end

    if tile_str == '' then
        return fallback
    end

    -- Edge cases: inventorycube or unbalanced parentheses
    if tile_str:find('%[inventorycube') then
        return fallback
    end

    -- Normalize any existing verticalframe animation to crop frame 0
    if tile_str:find('%[verticalframe') then
        tile_str = tile_str:gsub('%[verticalframe:(%d+):%d+', '[verticalframe:%1:0')
    end

    local open_paren, close_paren = 0, 0
    if tile_str:find('[()]') then
        local _, open_count = tile_str:gsub('%(', '')
        local _, close_count = tile_str:gsub('%)', '')
        open_paren, close_paren = open_count, close_count
        if open_paren ~= close_paren then
            return fallback
        end
    end

    -- If composite texture (contains '^' separating texture layers), filter out obsolete
    -- sign text entities, edges, and mount artifacts while combining all valid visual layers
    -- and preserving texture transformations.
    -- NOTE: If the texture is an intentional grouped composite (e.g. hiking textures like "((hiking_white..."),
    -- preserve the expression intact.
    local is_grouped_composite = (tile_str:sub(1, 1) == '(' and open_paren == close_paren and open_paren > 0)

    if not is_grouped_composite and (tile_str:find('%^[^%[]') or (tile_str:find('%^') and not tile_str:find('%^%['))) then
        local raw_layers = split_texture_layers(tile_str)
        local valid_layers = {}
        for _, layer in ipairs(raw_layers) do
            local clean_layer = layer:match('^%s*(.-)%s*$')
            if clean_layer and clean_layer ~= '' and not is_unwanted_sign_artifact(clean_layer) then
                table.insert(valid_layers, clean_layer)
            end
        end

        if #valid_layers > 0 then
            tile_str = table.concat(valid_layers, '^')
        else
            return fallback
        end
    end

    -- Strip existing resize modifier if present so get_background_texture resizes cleanly
    tile_str = tile_str:gsub('%^%[resize:%d+x%d+', '')

    if is_grouped_composite then
        return tile_str
    end

    -- Extract base filename for sheet/edge inspection
    local base = tile_str:match('^([^%^%[]+)')
    if not base or not base:find('%.png$') then
        base = tile_str:find('%.png$') and tile_str or fallback
    end

    local lower_base = base:lower()
    if lower_base:find('_inv%.png$') or lower_base:find('_edges%.png$') or lower_base:find('_sides%.png$') or lower_base:find('lock16%.png$')
        or lower_base:find('mcl_signs') or lower_base:find('ucsigns') then
        return fallback
    end

    -- Vertical animation sheets: crop 1st frame (frame 0) so sheets are never squished into plaques
    if not tile_str:find('%[verticalframe') and not tile_str:find('%[combine:') and not is_grouped_composite then
        local aspect_w = anim_def and anim_def.aspect_w or 16
        local aspect_h = anim_def and anim_def.aspect_h or 16
        local modname = nodename and nodename:match('^([%w_]+):')
        local num_frames = waysigns.get_texture_frame_count(base, modname, aspect_w, aspect_h)
        if num_frames > 1 then
            tile_str = tile_str .. '^[verticalframe:' .. num_frames .. ':0'
        elseif anim_def and (anim_def.type == 'vertical_frames' or anim_def.type == nil) then
            tile_str = '[combine:' .. aspect_w .. 'x' .. aspect_h .. ':0,0=' .. tile_str
        end
    end

    -- 1. signs_lib or basic_signs 64x32 dual sign front/back sheet (2x1 grid: front is 0,0)
    local is_dual_2x1_sheet = lower_base:find('signs_lib_sign_')
        or (lower_base:find('basic_signs_') and not lower_base:find('_edges') and not lower_base:find('_inv') and not lower_base:find('pole_mount'))

    if is_dual_2x1_sheet and not tile_str:find('%^%[sheet:') then
        return tile_str .. '^[sheet:2x1:0,0'
    end

    -- 2. street_signs intersection street blade: crop to single front blade (32x10)
    if lower_base:find('street_signs_basic') and not tile_str:find('%[combine:') then
        return '[combine:32x10:0,-2=' .. base
    end

    -- 3. street_signs generic highway signs & detour arrows (1x2 vertical sheet: top half is front face)
    local is_1x2_sheet = lower_base:find('street_signs_generic_highway_')
        or lower_base:find('street_signs_detour_')
        or lower_base:find('street_signs_one_way_')
        or lower_base:find('street_signs_large_arrow_')
        or lower_base:find('street_signs_roundabout_directional')
    if is_1x2_sheet and not lower_base:find('_edges') and not lower_base:find('_inv') and not tile_str:find('%^%[sheet:') then
        return tile_str .. '^[sheet:1x2:0,0'
    end

    -- 4. street_signs warning, services, distances, traffic rules (2x1 sheet: left half is front face)
    local is_2x1_street_sheet = lower_base:find('street_signs_warning')
        or lower_base:find('street_signs_service_')
        or lower_base:find('street_signs_distance_')
        or lower_base:find('street_signs_speed_')
        or lower_base:find('street_signs_stop')
        or lower_base:find('street_signs_yield')
        or lower_base:find('street_signs_do_not_')
        or lower_base:find('street_signs_wrong_way')
        or lower_base:find('street_signs_divided_highway_begins')
        or lower_base:find('street_signs_divided_highway_ends')
        or lower_base:find('street_signs_road_turns_')
        or lower_base:find('street_signs_side_road_')
        or lower_base:find('street_signs_left_lane_')
        or lower_base:find('street_signs_right_lane_')
        or lower_base:find('street_signs_pedestrian_')
        or lower_base:find('street_signs_circular_')
        or lower_base:find('street_signs_cross_road_')
    if is_2x1_street_sheet and not lower_base:find('_inv') and not lower_base:find('_edges') and not tile_str:find('%^%[sheet:') then
        return tile_str .. '^[sheet:2x1:0,0'
    end

    -- 5. street_signs divided highway with cross road: 256x410 (top 256x256 is front diamond)
    if lower_base:find('street_signs_divided_highway_with_cross_road') and not lower_base:find('_inv') and not tile_str:find('%[combine:') then
        return '[combine:256x256:0,0=' .. base
    end

    -- 6. signs_wooden_direction (display_modpack): 1x2 sheet (top half 16x8 is front arrow)
    if lower_base:find('signs_wooden_direction') and not tile_str:find('%^%[sheet:') then
        return tile_str .. '^[sheet:1x2:0,0'
    end

    return tile_str
end
waysigns.clean_tile_name = clean_tile_name

---Check if a node is a dedicated sign with native editable text
---@param node table|nil Node table containing node name and param2
---@return boolean is_sign True if node is a recognized physical sign
function waysigns.is_sign_node(node)
    if not node or not node.name then
        return false
    end
    if waysigns.registered_signs and waysigns.registered_signs[node.name] then
        return true
    end
    if (core.get_item_group(node.name, 'sign') > 0)
        or (core.get_item_group(node.name, 'board') > 0)
        or (core.get_item_group(node.name, 'ucsign') > 0) then
        return true
    end
    local node_def = core.registered_nodes[node.name]
    if node_def then
        if node_def.drawtype == 'signlike' then
            return true
        end
        if (node_def._sign_texture and node_def._sign_texture ~= '')
            or (node_def._itemframe_texture and node_def._itemframe_texture ~= '') then
            return true
        end
    end
    local nname = node.name:lower()
    if nname:find('signal') or nname:find('design') then
        return false
    end
    if nname:find('sign') or nname:find('notice') or nname:find('board') or nname:find('stele') then
        return true
    end
    return false
end

---Extract the best front-face texture for a node definition (e.g. chest front, furnace front).
---Detects mesh nodes and uses a fallback texture instead of distorted UV mesh maps.
---Prioritizes 'front'/'face' keywords and uses Luanti standard face 6 (-Z) for 6-tile nodeboxes.
---Detects animated textures and crops to the 1st frame.
---@param node_def table|nil Node definition table from core.registered_nodes
---@param nodename string|nil Technical node name
---@param is_metal boolean Whether node is metal/stone
---@return string tile Clean front tile texture name or fallback
local function get_node_front_tile(node_def, nodename, is_metal)
    local fallback = is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD
    if not node_def then
        return fallback
    end
    nodename = nodename or ''

    -- 1. Detect mesh nodes: mesh UV maps cannot be mapped cleanly to 2D boards, so use fallback
    local is_mesh = (node_def.drawtype == 'mesh')
        or (node_def.mesh ~= nil and node_def.mesh ~= '')
        or (node_def.visual == 'mesh')
        or not not nodename:find('^ucsigns:')
        or not not nodename:find('mesh')
        or (core.get_item_group(nodename, 'mesh') > 0)
        or (core.get_item_group(nodename, 'ucsign') > 0)

    if is_mesh then
        return fallback
    end

    local raw_tiles = node_def.tiles or node_def.tile_images
    if not raw_tiles then
        if node_def.inventory_image and node_def.inventory_image ~= '' then
            return clean_tile_name(node_def.inventory_image, is_metal, nodename) or fallback
        end
        return fallback
    end

    if type(raw_tiles) == 'string' and raw_tiles ~= '' then
        return clean_tile_name(raw_tiles, is_metal, nodename) or fallback
    end

    if type(raw_tiles) ~= 'table' or #raw_tiles == 0 then
        return fallback
    end

    local function get_tile_candidate(t, idx)
        if not node_def.overlay_tiles or type(node_def.overlay_tiles) ~= 'table' or not node_def.overlay_tiles[idx] then
            return t
        end
        local ot = node_def.overlay_tiles[idx]
        local base_str = (type(t) == 'string' and t) or (type(t) == 'table' and t.name) or ''
        local ot_str = (type(ot) == 'string' and ot) or (type(ot) == 'table' and ot.name) or ''
        if ot_str ~= '' then
            if type(ot) == 'table' and ot.color and ot.color ~= 'white' and ot.color ~= '' then
                ot_str = ot_str .. '^[multiply:' .. ot.color
            end
            local comb_name = (base_str ~= '' and (base_str .. '^' .. ot_str)) or ot_str
            if type(t) == 'table' and t.animation then
                return { name = comb_name, animation = t.animation }
            end
            return comb_name
        end
        return t
    end

    -- 2. Priority 1: Check for explicit front-facing keywords across all tile definitions
    -- (front, face, door, lock, panel, screen, dial, meter, gauge, display)
    local front_keywords = {
        'front', 'face', 'door', 'lock', 'panel', 'screen',
        'dial', 'meter', 'gauge', 'display', 'window',
    }
    for idx, t in ipairs(raw_tiles) do
        local raw_name = (type(t) == 'string' and t) or (type(t) == 'table' and t.name) or ''
        local lower = raw_name:lower()
        for _, kw in ipairs(front_keywords) do
            if lower:find(kw) then
                local cand = get_tile_candidate(t, idx)
                local cleaned = clean_tile_name(cand, is_metal, nodename)
                if cleaned and cleaned ~= fallback then
                    return cleaned
                end
                break
            end
        end
    end

    -- 3. Priority 2: In Luanti standard cube/nodebox mapping, tile min(6, #raw_tiles) is the front face:
    -- 1 = +Y (top), 2 = -Y (bottom), 3 = +X (right), 4 = -X (left), 5 = +Z (back), 6 = -Z (front).
    -- For 2 tiles (top, sides/bottom), tile 2 is the front/side face.
    -- For 3 tiles (top, bottom, sides), tile 3 is the front/side face.
    -- For 4 tiles, tile 4 is front. For 5 tiles, tile 5 is front. For 6 tiles, tile 6 is front.
    if #raw_tiles >= 2 then
        local front_idx = math.min(6, #raw_tiles)
        local front_cand = get_tile_candidate(raw_tiles[front_idx], front_idx)
        local cleaned = clean_tile_name(front_cand, is_metal, nodename)
        if cleaned and cleaned ~= fallback then
            return cleaned
        end
    end

    -- 4. Priority 3: Check remaining side faces (indices 3, 4, 5, 2), avoiding index 1 (top face)
    for _, idx in ipairs({ 3, 4, 5, 2 }) do
        if raw_tiles[idx] then
            local cleaned = clean_tile_name(raw_tiles[idx], is_metal, nodename)
            if cleaned and cleaned ~= fallback then
                return cleaned
            end
        end
    end

    -- 5. Priority 4: Reverse search through tiles ignoring any tile containing 'top' or 'up'
    for i = #raw_tiles, 1, -1 do
        local t = raw_tiles[i]
        local raw_name = (type(t) == 'string' and t) or (type(t) == 'table' and t.name) or ''
        local lower = raw_name:lower()
        if not lower:find('top') and not lower:find('up') then
            local cleaned = clean_tile_name(t, is_metal, nodename)
            if cleaned and cleaned ~= fallback then
                return cleaned
            end
        end
    end

    -- 6. Last resort: any valid cleaned tile
    for _, t in ipairs(raw_tiles) do
        local cleaned = clean_tile_name(t, is_metal, nodename)
        if cleaned and cleaned ~= fallback then
            return cleaned
        end
    end

    return fallback
end
waysigns.get_node_front_tile = get_node_front_tile

---Check if a node at position is a recognized sign and return its extracted data
---Scans node cache, custom resolvers, pre-registered signs, and generic sign detection fallbacks.
---@param pos Vector 3D integer coordinate of the node
---@param node table Node table containing node name and orientation param2
---@param player ObjectRef|nil Pointing player object
---@return table|nil sign_data Extracted sign definition table or nil if not a sign
function waysigns.get_sign_data(pos, node, player)
    local pos_key = core.hash_node_position(pos)
    local player_name = player and player:get_player_name() or ''
    local cached_node = waysigns.node_cache[pos_key]
    local cached = (cached_node and cached_node.by_player and cached_node.by_player[player_name])
        or (cached_node and not cached_node.by_player and cached_node)

    local meta = core.get_meta(pos)
    local waysigns_text = meta:get_string('waysigns_text')
    local has_inscription = (waysigns_text ~= '' and waysigns.is_valid_sign_text(waysigns_text))

    local text
    local clean_info = nil

    if has_inscription then
        if not waysigns.get_inscribed_pos(pos) then
            waysigns.register_inscribed_pos(pos, {
                author = meta:get_string('waysigns_author'),
                plaque = meta:get_string('waysigns_plaque'),
                color = meta:get_string('waysigns_color'),
                text = waysigns_text,
            }, true)
        end

        local raw_infotext = meta:get_string('infotext')
        if raw_infotext and raw_infotext ~= '' and raw_infotext:find('%S') then
            local cleaned = waysigns.strip_all_escapes and waysigns.strip_all_escapes(raw_infotext) or raw_infotext
            if cleaned and cleaned ~= '' and cleaned:find('%S') then
                local unwrapped = cleaned:match('^"(.*)"$')
                local cand = (unwrapped and unwrapped ~= '') and unwrapped or cleaned
                if waysigns.is_valid_sign_text(cand) then
                    clean_info = cand
                end
            end
        end

        if clean_info and clean_info ~= '' and clean_info ~= waysigns_text
            and clean_info:lower() ~= waysigns_text:lower()
            and not waysigns_text:find(clean_info, 1, true)
            and not clean_info:find(waysigns_text, 1, true) then
            text = waysigns_text .. '\n' .. clean_info
        else
            text = waysigns_text
        end
    else
        text = waysigns.extract_text(meta)
        if not text then
            return nil
        end
    end

    -- Check dynamic metadata from signs_rx, waysigns marker, or other custom systems
    local rx_scale = meta:get_string('scale')
    local rx_color = meta:get_string('color')
    local waysigns_plaque = meta:get_string('waysigns_plaque')
    local waysigns_color = meta:get_string('waysigns_color')

    -- 1. Custom registered resolvers
    for _, resolver in ipairs(waysigns.custom_resolvers) do
        local custom_data = resolver(pos, node)
        if custom_data and custom_data.text and custom_data.text ~= '' then
            custom_data.nodename = node.name
            custom_data.raw_text = custom_data.text
            custom_data.aspect_ratio = custom_data.aspect_ratio or waysigns.get_aspect_ratio(node.name, nil, nil)
            custom_data.wrapped = waysigns.wrap_text(custom_data.text, nil, nil, custom_data.text_color)
            waysigns.set_cached_node(pos_key, custom_data)
            return custom_data
        end
    end

    local node_def = core.registered_nodes[node.name]
    if not node_def then
        return nil
    end

    -- 2. Pre-registered signs
    local reg_def = waysigns.registered_signs[node.name]
    local is_metal = (reg_def and reg_def.is_metal)
        or waysigns.is_metal_node(node.name, node_def)
    local is_glass = (reg_def and reg_def.is_glass) or false

    local is_dedicated_sign = waysigns.is_sign_node(node)
    local is_sign = has_inscription or is_dedicated_sign or (reg_def ~= nil)

    if not is_sign then
        return nil
    end

    -- Container inventory quickview extraction
    local qv
    if waysigns.settings.enable_inventory_quickview then
        qv = waysigns.extract_node_inventory(pos, node, meta, player)
    end
    local has_visual_quickview = qv and qv.items and #qv.items > 0
    if not has_visual_quickview and qv and qv.summary and qv.summary ~= '' then
        text = text .. '\n' .. qv.summary
    end
    local inv_hash = qv and qv.inv_hash or ''

    local now = core.get_us_time() / 1000000
    if cached and cached.nodename == node.name and cached.raw_text == text
        and cached.rx_scale == rx_scale and cached.rx_color == rx_color
        and cached.waysigns_plaque == waysigns_plaque and cached.waysigns_color == waysigns_color
        and cached.inv_hash == inv_hash and cached.timestamp and (now - cached.timestamp < 0.5) then
        return cached
    end

    -- Determine base tile from node definition or registration
    local is_mesh_sign = (node_def.drawtype == 'mesh')
        or not not node.name:find('^ucsigns:')
        or (core.get_item_group(node.name, 'ucsign') > 0)
        or not not node_def.mesh
        or (node_def.visual == 'mesh')
        or not not node.name:find('mesh')
        or (core.get_item_group(node.name, 'mesh') > 0)

    local base_tile = nil
    if not is_dedicated_sign and not reg_def then
        base_tile = get_node_front_tile(node_def, node.name, is_metal)
    elseif is_mesh_sign then
        local fallback_wood = waysigns.FALLBACK_WOOD
        if is_metal then
            base_tile = waysigns.FALLBACK_STEEL
        else
            local nname = node.name:lower()
            if nname:find('acacia') then
                base_tile = fallback_wood .. '^[colorize:#a03818:50'
            elseif nname:find('aspen') or nname:find('birch') then
                base_tile = fallback_wood .. '^[colorize:#e5d5b0:40'
            elseif nname:find('jungle') then
                base_tile = fallback_wood .. '^[colorize:#4e2210:60'
            elseif nname:find('pine') or nname:find('spruce') or nname:find('dark') then
                base_tile = fallback_wood .. '^[colorize:#22150a:70'
            else
                base_tile = fallback_wood
            end
        end
    elseif node_def._itemframe_texture and node_def._itemframe_texture ~= '' then
        base_tile = clean_tile_name(node_def._itemframe_texture, is_metal, node.name)
    elseif node_def._sign_texture and node_def._sign_texture ~= '' then
        base_tile = clean_tile_name(node_def._sign_texture, is_metal, node.name)
    elseif (node_def.tiles and (type(node_def.tiles) == 'table' or type(node_def.tiles) == 'string'))
        or (node_def.tile_images and (type(node_def.tile_images) == 'table' or type(node_def.tile_images) == 'string')) then
        local raw_tiles = node_def.tiles or node_def.tile_images
        local tile_candidates = {}
        if type(raw_tiles) == 'table' then
            -- Face 6 is Luanti standard front face for facedir/nodebox
            if #raw_tiles >= 6 then
                table.insert(tile_candidates, raw_tiles[6])
            end
            for i, t in ipairs(raw_tiles) do
                if i ~= 6 then
                    table.insert(tile_candidates, t)
                end
            end
        elseif type(raw_tiles) == 'string' and raw_tiles ~= '' then
            table.insert(tile_candidates, raw_tiles)
        end

        local best_tile = nil
        local fallback_tile = nil
        local fallback = is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD
        for _, t in ipairs(tile_candidates) do
            local cleaned = clean_tile_name(t, is_metal, node.name)
            if cleaned and cleaned ~= fallback then
                local lower = cleaned:lower()
                if lower:find('sign') or lower:find('board') or lower:find('blade') or lower:find('stele')
                    or lower:find('poster') or lower:find('label') or lower:find('front') then
                    best_tile = cleaned
                    break
                elseif not best_tile then
                    best_tile = cleaned
                end
            elseif not fallback_tile and cleaned then
                fallback_tile = cleaned
            end
        end
        base_tile = best_tile or fallback_tile or clean_tile_name(tile_candidates[1], is_metal, node.name)
    elseif node_def.inventory_image and node_def.inventory_image ~= '' then
        base_tile = clean_tile_name(node_def.inventory_image, is_metal, node.name)
    end

    local text_color
    local tile
    local aspect_ratio

    if reg_def and not has_inscription then
        is_metal = reg_def.is_metal or false
        text_color = reg_def.text_color or (is_metal and 0xEEEEEE or 0xFFFFFF)
        local raw_tile = reg_def.tile or base_tile or (is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD)
        tile = clean_tile_name(raw_tile, is_metal, node.name)
        aspect_ratio = reg_def.aspect_ratio or waysigns.get_aspect_ratio(node.name, node_def, reg_def)
    else
        local chosen_tile = nil
        if has_inscription and waysigns_plaque ~= '' and waysigns.PLAQUE_STYLES and waysigns.PLAQUE_STYLES[waysigns_plaque] then
            chosen_tile = waysigns.PLAQUE_STYLES[waysigns_plaque]
            is_metal = (waysigns_plaque == 'steel' or waysigns_plaque == 'slate' or waysigns_plaque == 'gold')
            is_glass = (waysigns_plaque == 'glass')
        end

        if has_inscription and waysigns_color ~= '' and waysigns.INSCRIPTION_COLORS and waysigns.INSCRIPTION_COLORS[waysigns_color] then
            text_color = waysigns.INSCRIPTION_COLORS[waysigns_color]
        else
            text_color = is_metal and 0xEEEEEE or 0xFFFFFF
        end

        local raw_tile = chosen_tile or base_tile or (is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD)
        tile = clean_tile_name(raw_tile, is_metal, node.name)
        aspect_ratio = (has_inscription and 1.40) or waysigns.get_aspect_ratio(node.name, node_def, nil)
    end

    -- Hiking directional arrow detection
    if node.name:find('hiking:arrow') or node.name:find('direction') then
        aspect_ratio = 2.2
    end

    -- Support signs_rx dynamic scale metadata
    if rx_scale ~= '' then
        local scale_ar = {
            wide = 2.1,
            tall = 1.0,
            large = 1.45,
            small = 1.45,
        }
        if scale_ar[rx_scale] then
            aspect_ratio = scale_ar[rx_scale]
        end
    end

    -- Support signs_rx dynamic color metadata
    if rx_color ~= '' then
        local rx_tints = {
            teal = '#005533:140',
            purple = '#330055:140',
            olive = '#335500:140',
            indigo = '#003355:140',
            maroon = '#550033:140',
            red = '#550000:140',
            green = '#005500:140',
            blue = '#000055:140',
            brown = '#442200:140',
            black = '#000000:160',
            gray = '#333333:120',
        }
        if rx_tints[rx_color] then
            tile = tile .. '^[colorize:' .. rx_tints[rx_color]
        end
    end

    local is_light_bg
    if reg_def and reg_def.is_light_bg ~= nil then
        is_light_bg = reg_def.is_light_bg
    else
        is_light_bg = waysigns.is_light_background(tile, node.name)
    end

    local is_infotext = (has_inscription and not is_dedicated_sign and (clean_info ~= nil or has_visual_quickview)) or nil
    local data = {
        nodename = node.name,
        raw_text = text,
        text = text,
        tile = tile,
        is_metal = is_metal,
        is_glass = is_glass,
        is_light_bg = is_light_bg,
        text_color = text_color,
        aspect_ratio = aspect_ratio,
        rx_scale = rx_scale,
        rx_color = rx_color,
        waysigns_plaque = waysigns_plaque,
        waysigns_color = waysigns_color,
        wrapped = waysigns.wrap_text(text, 30, 5, text_color),
        has_inscription = has_inscription,
        is_dedicated_sign = is_dedicated_sign,
        is_infotext = is_infotext,
        quickview_items = qv and qv.items or nil,
        items = qv and qv.items or nil,
        inv_hash = inv_hash,
        timestamp = now,
    }

    if qv or (player and player_name ~= '') then
        local entry = waysigns.node_cache[pos_key]
        if not entry or not entry.by_player then
            entry = { by_player = {} }
            waysigns.set_cached_node(pos_key, entry)
        end
        entry.by_player[player_name] = data
    else
        waysigns.set_cached_node(pos_key, data)
    end
    return data
end

---Retrieve the visual texture representation for an item or node name
---@param item_name string Registered item or node name (e.g. "default:apple", "default:wood")
---@return string texture Texture specifier or image filename
function waysigns.get_item_texture(item_name)
    if not item_name or item_name == '' or item_name == 'air' or item_name == 'ignore' then
        return 'waysigns_blank.png'
    end

    local def = core.registered_items[item_name]

    if not def then
        return 'unknown_item.png'
    end

    if def.inventory_image and def.inventory_image ~= '' then
        return def.inventory_image
    end

    if def.wield_image and def.wield_image ~= '' then
        return def.wield_image
    end

    if def.tiles and #def.tiles > 0 then
        local function extract_tile_name(t)
            if type(t) == 'table' then
                return t.name or 'unknown_node.png'
            elseif type(t) == 'string' then
                return t
            end
            return 'unknown_node.png'
        end

        local t1 = extract_tile_name(def.tiles[1])
        local dt = def.drawtype
        if dt == 'plantlike' or dt == 'plantlike_rooted' or dt == 'torchlike'
            or dt == 'signlike' or dt == 'raillike' or dt == 'fencelike' then
            return t1
        end

        local t2 = extract_tile_name(def.tiles[3] or def.tiles[1])
        local t3 = extract_tile_name(def.tiles[5] or def.tiles[3] or def.tiles[1])
        return core.inventorycube(t1, t2, t3)
    end

    return 'unknown_item.png'
end

---Extract and aggregate items stored in a pointed container node
---@param pos Vector Node position
---@param node table Node table { name = string, param2 = integer }
---@param meta any Node metadata reference
---@param player ObjectRef|nil Pointing player object
---@param max_slots integer|nil Maximum item slots to return (default 4)
---@return table|nil result Inventory quickview result table or nil if empty/unauthorized
function waysigns.extract_node_inventory(pos, node, meta, player, max_slots)
    if not node or not node.name then
        return nil
    end

    -- Respect container locks and protection in multiplayer
    local respect_locks = waysigns.settings.quickview_respect_locks
    if respect_locks ~= false then
        local is_bypass = player and core.check_player_privs(player, 'protection_bypass')
        if not is_bypass then
            local owner = (meta and meta:get_string('owner')) or ''
            if owner ~= '' then
                if not player then
                    return nil
                end
                local player_name = player:get_player_name()
                local is_owner = (owner == player_name)
                if not is_owner then
                    return nil
                end
            end
            if player then
                local player_name = player:get_player_name()
                if waysigns.is_protected(pos, player_name, true) then
                    return nil
                end
            end
        end
    end

    local item_order = {}
    local item_map = {}
    local total_item_count = 0

    local function add_stacks(stacks)
        if not stacks then return end
        for _, stack in ipairs(stacks) do
            if stack and not stack:is_empty() then
                local item_name = stack:get_name()
                local count = stack:get_count()
                total_item_count = total_item_count + count
                if not item_map[item_name] then
                    local item_def = core.registered_items[item_name] or {}
                    local desc = stack:get_short_description()
                    if not desc or desc == '' then
                        desc = stack:get_description()
                    end
                    if not desc or desc == '' then
                        desc = item_def.description or item_name
                    end
                    desc = waysigns.strip_all_escapes(desc)
                    desc = desc:gsub('[\r\n].*$', ''):gsub('^%s+', ''):gsub('%s+$', '')
                    if desc == '' then
                        desc = item_name
                    end
                    local entry = {
                        name = item_name,
                        count = 0,
                        desc = desc,
                        icon = waysigns.get_item_texture(item_name),
                    }
                    item_map[item_name] = entry
                    item_order[#item_order + 1] = entry
                end
                item_map[item_name].count = item_map[item_name].count + count
            end
        end
    end

    local function inspect_inv_lists(inv)
        if not inv then return false end
        local checked_lists = {}
        local list_names = {}
        local priority_lists = { 'main', 'dst', 'src', 'fuel', 'books', 'vessels', 'storage', 'input', 'output' }
        for _, lname in ipairs(priority_lists) do
            if not checked_lists[lname] and inv.get_list and inv:get_list(lname) then
                checked_lists[lname] = true
                list_names[#list_names + 1] = lname
            end
        end
        if inv.get_lists then
            local all_lists = inv:get_lists()
            if all_lists then
                local extra_lists = {}
                for lname, _ in pairs(all_lists) do
                    if not checked_lists[lname] then
                        checked_lists[lname] = true
                        extra_lists[#extra_lists + 1] = lname
                    end
                end
                table.sort(extra_lists)
                for _, lname in ipairs(extra_lists) do
                    list_names[#list_names + 1] = lname
                end
            end
        end
        local found = false
        for _, lname in ipairs(list_names) do
            local list = inv:get_list(lname)
            if list and #list > 0 then
                add_stacks(list)
                found = true
            end
        end
        return found
    end

    local base_name = node.name:gsub('_open$', '')

    -- 1. Check custom resolvers registered via waysigns.register_inventory_resolver
    local custom_resolver = waysigns.custom_inventory_resolvers and (waysigns.custom_inventory_resolvers[node.name] or waysigns.custom_inventory_resolvers[base_name])
    if custom_resolver then
        local res = custom_resolver(pos, node, meta, player)
        if res then
            if res.get_list or res.get_lists then
                inspect_inv_lists(res)
            elseif type(res) == 'table' then
                add_stacks(res)
            end
        end
    end

    -- 2. Inspect standard node inventory
    if #item_order == 0 and meta then
        local inv = meta:get_inventory()
        if inv then
            inspect_inv_lists(inv)
        end
    end

    -- 3. Check player-bound inventory (e.g. x_obsidianmese:chest, enderchests)
    if #item_order == 0 and player and player.get_inventory then
        local pinv = player:get_inventory()
        if pinv and pinv.get_list then
            local plist = pinv:get_list(node.name) or pinv:get_list(base_name)
            if (not plist or #plist == 0) and (node.name:find('enderchest') or node.name:find('ender_chest')) then
                plist = pinv:get_list('enderchest') or pinv:get_list('mcl_enderchest')
            end
            if plist then
                add_stacks(plist)
            end
        end
    end

    -- 4. Check detached inventory referenced in node metadata
    if #item_order == 0 and meta then
        local det_name = meta:get_string('detached_inventory')
        if det_name == '' then
            det_name = meta:get_string('inv_id')
        end
        if det_name == '' then
            det_name = meta:get_string('inv_name')
        end
        if det_name ~= '' then
            local dinv = core.get_inventory({ type = 'detached', name = det_name })
            if dinv then
                inspect_inv_lists(dinv)
            end
        end
    end

    if #item_order == 0 then
        return nil
    end

    local default_limit = waysigns.settings.quickview_max_slots or 32
    local limit = math.max(1, math.min(32, max_slots or default_limit))
    local slots = {}
    for i = 1, math.min(#item_order, limit) do
        slots[#slots + 1] = item_order[i]
    end
    local overflow = math.max(0, #item_order - limit)

    -- Option A: Text Line Summary (e.g. "64x Wood, 12x Apple, 1x Steel Pickaxe")
    -- Do not truncate item names or inventory items; 5-line wrapping with pagination displays full content
    local summary_parts = {}
    for i = 1, math.min(#item_order, limit) do
        local it = item_order[i]
        summary_parts[#summary_parts + 1] = it.count .. 'x ' .. it.desc
    end
    local summary_text = table.concat(summary_parts, ', ')
    if overflow > 0 then
        summary_text = summary_text .. ' (+' .. overflow .. ')'
    end

    local hash_parts = {}
    for _, it in ipairs(item_order) do
        hash_parts[#hash_parts + 1] = it.name .. '=' .. it.count
    end
    local inv_hash = table.concat(hash_parts, ';')

    return {
        items = slots,
        all_items = item_order,
        total_items = total_item_count,
        total_distinct = #item_order,
        overflow = overflow,
        summary = summary_text,
        inv_hash = inv_hash,
    }
end

---Check if a node at position has valid infotext metadata and return its extracted data
---Used for interactive nodes (chests, furnaces, machines, containers, etc.)
---@param pos Vector 3D integer coordinate of the node
---@param node table Node table containing node name and orientation param2
---@param player ObjectRef|nil Pointing player object
---@return table|nil infotext_data Extracted infotext data table or nil if empty/no infotext
function waysigns.get_node_infotext_data(pos, node, player)
    local meta = core.get_meta(pos)
    local raw_infotext = meta:get_string('infotext')
    local waysigns_text = meta:get_string('waysigns_text')
    local has_waysigns = (waysigns_text ~= '' and waysigns.is_valid_sign_text(waysigns_text))

    if not has_waysigns and (not raw_infotext or raw_infotext == '' or not raw_infotext:find('%S')) then
        return nil
    end

    if has_waysigns then
        if not waysigns.get_inscribed_pos(pos) then
            waysigns.register_inscribed_pos(pos, {
                author = meta:get_string('waysigns_author'),
                plaque = meta:get_string('waysigns_plaque'),
                color = meta:get_string('waysigns_color'),
                text = waysigns_text,
            }, true)
        end
    end

    local clean_info = nil
    if raw_infotext and raw_infotext ~= '' and raw_infotext:find('%S') then
        local cleaned = waysigns.strip_all_escapes and waysigns.strip_all_escapes(raw_infotext) or raw_infotext
        if cleaned and cleaned ~= '' and cleaned:find('%S') then
            local unwrapped = cleaned:match('^"(.*)"$')
            local cand_str = (unwrapped and unwrapped ~= '') and unwrapped or cleaned
            if waysigns.is_valid_sign_text(cand_str) then
                clean_info = cand_str
            end
        end
    end

    local cand
    if has_waysigns and clean_info then
        if clean_info ~= waysigns_text
            and clean_info:lower() ~= waysigns_text:lower()
            and not waysigns_text:find(clean_info, 1, true)
            and not clean_info:find(waysigns_text, 1, true) then
            cand = waysigns_text .. '\n' .. clean_info
        else
            cand = waysigns_text
        end
    elseif has_waysigns then
        cand = waysigns_text
    elseif clean_info then
        cand = clean_info
    else
        return nil
    end

    local pos_key = core.hash_node_position(pos)
    local player_name = player and player:get_player_name() or ''
    local cached_node = waysigns.node_cache[pos_key]
    local cached = (cached_node and cached_node.by_player and cached_node.by_player[player_name])
        or (cached_node and not cached_node.by_player and cached_node)

    -- Container inventory quickview extraction (with 0.5s throttling)
    local now = core.get_us_time() / 1000000
    if cached and cached.nodename == node.name and cached.cand == cand and cached.timestamp and (now - cached.timestamp < 0.5) then
        return cached
    end

    local qv
    if waysigns.settings.enable_inventory_quickview then
        qv = waysigns.extract_node_inventory(pos, node, meta, player)
    end

    local has_visual_quickview = qv and qv.items and #qv.items > 0
    local full_cand = cand
    if not has_visual_quickview and qv and qv.summary and qv.summary ~= '' then
        full_cand = cand .. '\n' .. qv.summary
    end

    local inv_hash = qv and qv.inv_hash or ''
    if cached and cached.nodename == node.name and cached.raw_text == full_cand and cached.inv_hash == inv_hash and cached.is_infotext then
        cached.timestamp = now
        return cached
    end

    local node_def = core.registered_nodes[node.name]
    local is_metal = waysigns.is_metal_node(node.name, node_def)

    local base_tile = get_node_front_tile(node_def, node.name, is_metal)
    local text_color = nil

    if has_waysigns then
        local waysigns_plaque = meta:get_string('waysigns_plaque')
        local waysigns_color = meta:get_string('waysigns_color')
        if waysigns_plaque ~= '' and waysigns.PLAQUE_STYLES and waysigns.PLAQUE_STYLES[waysigns_plaque] then
            base_tile = waysigns.PLAQUE_STYLES[waysigns_plaque]
            is_metal = (waysigns_plaque == 'steel' or waysigns_plaque == 'slate' or waysigns_plaque == 'gold')
        end
        if waysigns_color ~= '' and waysigns.INSCRIPTION_COLORS and waysigns.INSCRIPTION_COLORS[waysigns_color] then
            text_color = waysigns.INSCRIPTION_COLORS[waysigns_color]
        end
    end

    local is_light_bg = waysigns.is_light_background(base_tile, node.name)
    if not text_color then
        text_color = is_light_bg and 0x222222 or 0xFFFFFF
    end

    -- Wrapped lines for infotext: allow up to 30 chars per line and 5 lines for balanced presentation
    local wrapped = waysigns.wrap_text(full_cand, 30, 5, text_color)

    local data = {
        nodename = node.name,
        raw_text = full_cand,
        text = full_cand,
        cand = cand,
        tile = base_tile,
        is_metal = is_metal,
        is_light_bg = is_light_bg,
        text_color = text_color,
        aspect_ratio = has_waysigns and 1.40 or 1.0,
        wrapped = wrapped,
        is_infotext = true,
        has_inscription = has_waysigns,
        quickview_items = qv and qv.items or nil,
        items = qv and qv.items or nil,
        inv_hash = inv_hash,
        timestamp = now,
    }

    local entry = waysigns.node_cache[pos_key]
    if not entry or not entry.by_player then
        entry = { by_player = {} }
        waysigns.set_cached_node(pos_key, entry)
    end
    entry.by_player[player_name] = data
    return data
end

---Retrieve extracted inscription sign data for an active entity
---@param object ObjectRef Entity reference
---@return table|nil sign_data Extracted sign data or nil if not inscribed
function waysigns.get_entity_inscription_data(object)
    if not object or not object.get_pos then
        return nil
    end

    local pos = object:get_pos()
    if not pos then
        return nil
    end

    local lua_ent = object:get_luaentity()
    local text = (lua_ent and lua_ent._waysigns_text) or (type(object) == 'table' and object._waysigns_text) or nil
    if not text or text == '' then
        local props = object:get_properties()
        if props and props.infotext and props.infotext ~= '' then
            text = props.infotext
        end
    end

    if not waysigns.is_valid_sign_text(text) then
        return nil
    end

    local plaque = (lua_ent and lua_ent._waysigns_plaque) or (type(object) == 'table' and object._waysigns_plaque) or 'default'
    local color_name = (lua_ent and lua_ent._waysigns_color) or (type(object) == 'table' and object._waysigns_color) or 'white'

    local tile = waysigns.PLAQUE_STYLES[plaque] or waysigns.FALLBACK_WOOD
    local is_metal = (plaque == 'steel' or plaque == 'slate' or plaque == 'gold')
    local is_glass = (plaque == 'glass')
    local is_light_bg = waysigns.is_light_background(tile)
    local text_color = waysigns.INSCRIPTION_COLORS[color_name] or (is_light_bg and 0x222222 or 0xFFFFFF)

    local props = object:get_properties() or {}
    local height = 1.0
    if props.collisionbox and type(props.collisionbox) == 'table' and props.collisionbox[5] then
        height = math.max(0.3, props.collisionbox[5])
    elseif props.visual_size and type(props.visual_size) == 'table' and props.visual_size.y then
        height = math.max(0.3, props.visual_size.y)
    end

    local waypoint_pos = {
        x = pos.x,
        y = pos.y + height + 0.35,
        z = pos.z,
    }

    local wrapped = waysigns.wrap_text(text, 26, 4, text_color)

    return {
        nodename = (lua_ent and lua_ent.name) or 'entity',
        raw_text = text,
        text = text,
        tile = tile,
        is_metal = is_metal,
        is_glass = is_glass,
        is_light_bg = is_light_bg,
        text_color = text_color,
        aspect_ratio = 1.4,
        wrapped = wrapped,
        pages = wrapped.pages,
        is_entity = true,
        pos = waypoint_pos,
        face_pos = waypoint_pos,
        plaque = plaque,
        waysigns_plaque = plaque,
        color = color_name,
        waysigns_color = color_name,
        author = (lua_ent and lua_ent._waysigns_author) or (type(object) == 'table' and object._waysigns_author) or nil,
    }
end

--------------------------------------------------------------------------------
-- 3rd Party Sign Text Entity Suppression & Cleanup
--------------------------------------------------------------------------------

local orig_signs_lib_spawn_entity
local orig_signs_lib_set_obj_text
local orig_ent_hooks = {}

local SUPPRESSED_ENTITIES = {
    ['signs_lib:text'] = true,
    ['mcl_signs:text'] = true,
    ['rp_signs:sign_text'] = true,
    ['signs:display_text'] = true,
    ['boards:display_text'] = true,
    ['steles:display_text'] = true,
    ['ucsigns:text'] = true,
    ['jp_signs:text_entity'] = true,
}

---Check if position belongs to a street_signs node that should have entities preserved
---@param pos Vector|nil 3D coordinate vector to test
---@return boolean is_street True if node is a preserved street_signs node
local function is_preserved_street_sign(pos)
    if not waysigns.settings.enable_street_signs_entities or not pos then
        return false
    end
    local rpos = waysigns.round_pos(pos)
    local node = core.get_node(rpos)
    if node and node.name:match('^street_signs:') then
        return true
    end
    -- If entity is offset into air in front of the sign face, check adjacent neighbors
    if node and node.name == 'air' then
        local offsets = {
            { x = 1, y = 0, z = 0 }, { x = -1, y = 0, z = 0 },
            { x = 0, y = 1, z = 0 }, { x = 0, y = -1, z = 0 },
            { x = 0, y = 0, z = 1 }, { x = 0, y = 0, z = -1 },
        }
        for _, off in ipairs(offsets) do
            local npos = vector.add(rpos, off)
            local nnode = core.get_node(npos)
            if nnode and nnode.name:match('^street_signs:') then
                if vector.distance(pos, npos) <= 0.65 then
                    return true
                end
            end
        end
    end
    return false
end

---Determine if an active in-world entity should be purged by WaySigns
---Suppresses 3rd party sign text floating entities to eliminate server entity limits and lag spikes.
---If waysigns_enable_street_signs_entities is true, permits signs_lib:text attached to street_signs:* nodes.
---@param obj ObjectRef Active object reference in world
---@param luaentity table Lua entity table containing .name
---@return boolean should_remove True if entity is a 3rd party text entity that should be removed
local function should_remove_sign_entity(obj, luaentity)
    local ename = luaentity and luaentity.name
    if not ename then
        return false
    end
    if not SUPPRESSED_ENTITIES[ename] and not ename:find('sign.*text') and not ename:find('display.*text') then
        return false
    end
    if ename == 'signs_lib:text' and obj and obj.get_pos and is_preserved_street_sign(obj:get_pos()) then
        return false
    end
    return true
end

---Purge any 3rd party sign text entities located in or adjacent to a sign node
---Scans a 0.7m radius around the sign position and purges matching attached text entities.
---@param pos Vector 3D grid position of the sign node to purge entities around
function waysigns.purge_sign_entities(pos)
    if not pos or is_preserved_street_sign(pos) then
        return
    end
    local objects = core.get_objects_inside_radius(pos, 0.7)
    for _, obj in ipairs(objects) do
        local luaentity = obj:get_luaentity()
        if luaentity and should_remove_sign_entity(obj, luaentity) then
            obj:remove()
        end
    end
end

---Hook 3rd party sign mod spawning routines to suppress text entities at the source
---Intersects signs_lib.spawn_entity, display_api.update_entities, and entity on_activate/on_step handlers.
---Prevents entity creation while preserving underlying sign text and editing functionality.
local function apply_entity_suppression()
    if not waysigns.settings.disable_sign_entities then
        return
    end

    -- 1. Neutralize signs_lib spawning functions (preserving street_signs if enabled)
    if core.global_exists('signs_lib') then
        if not orig_signs_lib_spawn_entity then
            orig_signs_lib_spawn_entity = signs_lib.spawn_entity
        end
        if not orig_signs_lib_set_obj_text then
            orig_signs_lib_set_obj_text = signs_lib.set_obj_text
        end

        rawset(signs_lib, 'spawn_entity', function(pos, texture, glow)
            if is_preserved_street_sign(pos) and orig_signs_lib_spawn_entity then
                return orig_signs_lib_spawn_entity(pos, texture, glow)
            end
            waysigns.purge_sign_entities(pos)
            return nil
        end)
        rawset(signs_lib, 'set_obj_text', function(pos, text, glow)
            if is_preserved_street_sign(pos) and orig_signs_lib_set_obj_text then
                return orig_signs_lib_set_obj_text(pos, text, glow)
            end
            waysigns.purge_sign_entities(pos)
        end)
    end

    -- 2. Neutralize display_modpack / display_api spawning functions
    local dapi = rawget(_G, 'display_api')
    if dapi and dapi.update_entities then
        rawset(dapi, 'update_entities', function(pos)
            waysigns.purge_sign_entities(pos)
        end)
    end

    -- 3. Hook on_activate and on_step on known sign text entities so existing
    -- saved entities self-destruct upon loading from mapblocks
    local sign_entity_names = {
        'signs_lib:text',
        'mcl_signs:text',
        'rp_signs:sign_text',
        'signs:display_text',
        'boards:display_text',
        'steles:display_text',
        'ucsigns:text',
        'jp_signs:text_entity',
    }
    for _, ent_name in ipairs(sign_entity_names) do
        local ent_def = core.registered_entities[ent_name]
        if ent_def then
            if not orig_ent_hooks[ent_name] then
                orig_ent_hooks[ent_name] = {
                    on_activate = ent_def.on_activate,
                    on_step = ent_def.on_step,
                }
            end
            rawset(ent_def, 'on_activate', function(self, staticdata, dtime_s)
                if ent_name == 'signs_lib:text' and self.object and self.object.get_pos and is_preserved_street_sign(self.object:get_pos()) then
                    local orig_act = orig_ent_hooks[ent_name] and orig_ent_hooks[ent_name].on_activate
                    if orig_act then
                        return orig_act(self, staticdata, dtime_s)
                    end
                    return
                end
                if self.object then
                    self.object:remove()
                end
            end)
            rawset(ent_def, 'on_step', function(self, dtime)
                if ent_name == 'signs_lib:text' and self.object and self.object.get_pos and is_preserved_street_sign(self.object:get_pos()) then
                    local orig_step = orig_ent_hooks[ent_name] and orig_ent_hooks[ent_name].on_step
                    if orig_step then
                        return orig_step(self, dtime)
                    end
                    return
                end
                if self.object then
                    self.object:remove()
                end
            end)
        end
    end
end

if waysigns.settings.disable_sign_entities then
    -- Run immediately during mod load
    apply_entity_suppression()

    -- Also run on mods_loaded to ensure late entity registrations are intercepted
    core.register_on_mods_loaded(apply_entity_suppression)

    -- 3. Register LBM to purge entities whenever mapblocks load into memory
    core.register_lbm({
        name = 'waysigns:purge_sign_entities',
        label = 'Purge 3rd party sign text entities',
        nodenames = { 'group:sign', 'group:board' },
        run_at_every_load = true,
        action = function(pos, node)
            if is_preserved_street_sign(pos) then
                return
            end
            waysigns.purge_sign_entities(pos)
        end,
    })

    -- 4. Admin chatcommand to purge loaded sign entities across all players
    core.register_chatcommand('waysigns_purge_entities', {
        params = '',
        description = 'Purges all 3rd party sign text entities around connected players',
        privs = { server = true },
        func = function(_name)
            local count = 0
            local seen = {}
            for _, player in ipairs(core.get_connected_players()) do
                local ppos = player:get_pos()
                if ppos then
                    local objects = core.get_objects_inside_radius(ppos, 64)
                    for _, obj in ipairs(objects) do
                        if not seen[obj] then
                            seen[obj] = true
                            local luaentity = obj:get_luaentity()
                            if luaentity and should_remove_sign_entity(obj, luaentity) then
                                obj:remove()
                                count = count + 1
                            end
                        end
                    end
                end
            end
            return true, ('Purged %d sign text entities around connected players.'):format(count)
        end,
    })
end


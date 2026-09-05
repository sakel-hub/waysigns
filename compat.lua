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
    License along with this library; if not, write to juraj.vajda@gmail.com
--]]

-- Register standard Minetest Game signs if present
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
            local is_metal = not not (node.name:find('steel')
                or node.name:find('metal')
                or node.name:find('iron'))
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

---Sanitize and extract the clean base texture name from a node definition tile
---Extracts single textures from composites or multi-layer specs while stripping lock/text overlays.
---@param raw_tile any String or table definition from node_def.tiles
---@param is_metal boolean|nil Whether sign is metal/stone (determines fallback texture)
---@return string tile_str Sanitized clean texture filename for background generation
local function clean_tile_name(raw_tile, is_metal)
    local fallback = is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD
    if not raw_tile then
        return fallback
    end

    local tile_str = ''
    if type(raw_tile) == 'string' then
        tile_str = raw_tile
    elseif type(raw_tile) == 'table' and raw_tile.name then
        tile_str = raw_tile.name
    end

    if tile_str == '' then
        return fallback
    end

    -- Edge cases: inventorycube, verticalframe animations, or unbalanced parentheses
    if tile_str:find('%[inventorycube') or tile_str:find('%[verticalframe') then
        return fallback
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

    -- If composite texture (contains '^' separating texture layers), extract the underlying
    -- sign/background layer while discarding locks, overlays, text glyphs, and edge trims.
    -- NOTE: If the texture is an intentional grouped composite (e.g. hiking textures like "((hiking_white..."),
    -- preserve the expression intact.
    local is_grouped_composite = (tile_str:sub(1, 1) == '(' and open_paren == close_paren and open_paren > 0)

    if not is_grouped_composite and (tile_str:find('%^[^%[]') or (tile_str:find('%^') and not tile_str:find('%^%['))) then
        local candidates = {}
        for part in tile_str:gmatch('([^%^]+)') do
            local clean_part = part:match('^%s*(.-)%s*$')
            if clean_part:find('%.png') then
                table.insert(candidates, clean_part)
            end
        end
        local chosen = nil
        for _, c in ipairs(candidates) do
            local lower = c:lower()
            if not lower:find('_text')
                and not lower:find('_lock')
                and not lower:find('lock16')
                and not lower:find('_icon')
                and not lower:find('_edges')
                and not lower:find('_inv')
                and not lower:find('pole_mount')
                and not lower:find('mcl_signs')
                and not lower:find('ucsigns') then
                chosen = c
                if lower:find('sign') or lower:find('wood') or lower:find('steel')
                    or lower:find('board') or lower:find('wall') or lower:find('plank') then
                    break
                end
            end
        end
        if chosen then
            tile_str = chosen
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

---Check if a node at position is a recognized sign and return its extracted data
---Scans node cache, custom resolvers, pre-registered signs, and generic sign detection fallbacks.
---@param pos Vector 3D integer coordinate of the node
---@param node table Node table containing node name and orientation param2
---@return table|nil sign_data Extracted sign definition table or nil if not a sign
function waysigns.get_sign_data(pos, node)
    local pos_key = core.hash_node_position(pos)
    local cached = waysigns.node_cache[pos_key]
    local meta = core.get_meta(pos)
    local text = waysigns.extract_text(meta)
    if not text then
        return nil
    end

    -- Check dynamic metadata from signs_rx or other custom systems
    local rx_scale = meta:get_string('scale')
    local rx_color = meta:get_string('color')

    if cached and cached.nodename == node.name and cached.raw_text == text and cached.rx_scale == rx_scale and cached.rx_color == rx_color then
        return cached
    end

    -- 1. Custom registered resolvers
    for _, resolver in ipairs(waysigns.custom_resolvers) do
        local custom_data = resolver(pos, node)
        if custom_data and custom_data.text and custom_data.text ~= '' then
            custom_data.nodename = node.name
            custom_data.raw_text = custom_data.text
            custom_data.aspect_ratio = custom_data.aspect_ratio or waysigns.get_aspect_ratio(node.name, nil, nil)
            custom_data.wrapped = waysigns.wrap_text(custom_data.text, nil, nil, custom_data.text_color)
            waysigns.node_cache[pos_key] = custom_data
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
        or not not (node.name:find('steel')
            or node.name:find('iron')
            or node.name:find('metal')
            or node.name:find('stone'))

    -- Determine base tile from node definition or registration
    local is_mesh_sign = (node_def.drawtype == 'mesh')
        or not not node.name:find('^ucsigns:')
        or (core.get_item_group(node.name, 'ucsign') > 0)
        or not not node_def.mesh

    local base_tile = nil
    if is_mesh_sign then
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
        base_tile = clean_tile_name(node_def._itemframe_texture, is_metal)
    elseif node_def._sign_texture and node_def._sign_texture ~= '' then
        base_tile = clean_tile_name(node_def._sign_texture, is_metal)
    elseif (node_def.tiles and (type(node_def.tiles) == 'table' or type(node_def.tiles) == 'string'))
        or (node_def.tile_images and (type(node_def.tile_images) == 'table' or type(node_def.tile_images) == 'string')) then
        local raw_tiles = node_def.tiles or node_def.tile_images
        local tile_candidates = {}
        if type(raw_tiles) == 'table' then
            -- Face 6 is Minetest standard front face for facedir/nodebox
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
            local cleaned = clean_tile_name(t, is_metal)
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
        base_tile = best_tile or fallback_tile or clean_tile_name(tile_candidates[1], is_metal)
    elseif node_def.inventory_image and node_def.inventory_image ~= '' then
        base_tile = clean_tile_name(node_def.inventory_image, is_metal)
    end

    local text_color
    local tile
    local aspect_ratio

    if reg_def then
        is_metal = reg_def.is_metal or false
        text_color = reg_def.text_color or (is_metal and 0xEEEEEE or 0xFFFFFF)
        local raw_tile = reg_def.tile or base_tile or (is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD)
        tile = clean_tile_name(raw_tile, is_metal)
        aspect_ratio = reg_def.aspect_ratio or waysigns.get_aspect_ratio(node.name, node_def, reg_def)
    else
        -- 3. Generic sign detection
        local is_sign = (core.get_item_group(node.name, 'sign') > 0)
            or (core.get_item_group(node.name, 'board') > 0)
            or (node_def.drawtype == 'signlike')
            or not not (node.name:find('sign')
                or node.name:find('notice')
                or node.name:find('board')
                or node.name:find('stele')
                or node.name:find('marker'))

        if not is_sign then
            return nil
        end

        text_color = is_metal and 0xEEEEEE or 0xFFFFFF
        local raw_tile = base_tile or (is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD)
        tile = clean_tile_name(raw_tile, is_metal)
        aspect_ratio = waysigns.get_aspect_ratio(node.name, node_def, nil)
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

    local data = {
        nodename = node.name,
        raw_text = text,
        text = text,
        tile = tile,
        is_metal = is_metal,
        is_light_bg = is_light_bg,
        text_color = text_color,
        aspect_ratio = aspect_ratio,
        rx_scale = rx_scale,
        rx_color = rx_color,
        wrapped = waysigns.wrap_text(text, nil, nil, text_color)
    }

    waysigns.node_cache[pos_key] = data
    return data
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
    local node = core.get_node(waysigns.round_pos(pos))
    return not not (node and node.name:match('^street_signs:'))
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
                self.object:remove()
            end)
            rawset(ent_def, 'on_step', function(self, dtime)
                if ent_name == 'signs_lib:text' and self.object and self.object.get_pos and is_preserved_street_sign(self.object:get_pos()) then
                    local orig_step = orig_ent_hooks[ent_name] and orig_ent_hooks[ent_name].on_step
                    if orig_step then
                        return orig_step(self, dtime)
                    end
                    return
                end
                self.object:remove()
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


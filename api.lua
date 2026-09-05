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

local S = core.get_translator(core.get_current_modname())

---@class WaySignsSignDef
---@field tile string Base texture name for background
---@field text_color number 0xRRGGBB integer color
---@field is_metal boolean Whether sign is metal/stone instead of wood
---@field aspect_ratio number|nil Width-to-height aspect ratio of the sign face (default 1.40)

---@class WaySignsPlayerState
---@field current_sign_pos Vector|nil
---@field current_sign_data table|nil
---@field current_sign_normal Vector|nil
---@field sign_face_pos Vector|nil
---@field current_page integer
---@field page_timer number
---@field hud_bg_id number|nil
---@field hud_line_ids number[]
---@field hud_page_id number|nil
---@field hud_display_mode string|nil
---@field opacity number
---@field target_opacity number
---@field is_visible boolean
---@field check_timer number
---@field purge_timer number
---@field last_purged_pos Vector|nil
---@field rendered_page integer|nil
---@field rendered_scale number|nil

---@class WaySignsCachedNode
---@field text string
---@field data table
---@field timestamp number

---@class WaySigns
waysigns = {
    settings = {
        display_mode = core.settings:get('waysigns_display_mode') or 'waypoint',
        max_distance = tonumber(core.settings:get('waysigns_max_distance')) or 4.5,
        check_interval = tonumber(core.settings:get('waysigns_check_interval')) or 0.05,
        fade_time = tonumber(core.settings:get('waysigns_fade_time')) or 0.3,
        hud_scale = tonumber(core.settings:get('waysigns_hud_scale')) or 2.0,
        match_aspect_ratio = core.settings:get_bool('waysigns_match_aspect_ratio', true),
        disable_sign_entities = core.settings:get_bool('waysigns_disable_sign_entities', true),
        enable_street_signs_entities = core.settings:get_bool('waysigns_enable_street_signs_entities', false),
        overlay_pos_y = tonumber(core.settings:get('waysigns_overlay_pos_y')) or 0.50,
        max_chars_per_line = tonumber(core.settings:get('waysigns_max_chars_per_line')) or 30,
        max_lines = tonumber(core.settings:get('waysigns_max_lines')) or 5,
        auto_scroll = core.settings:get_bool('waysigns_auto_scroll', true),
        scroll_delay = tonumber(core.settings:get('waysigns_scroll_delay')) or 2.5,
        show_frame = core.settings:get_bool('waysigns_show_frame', true),
        contrast_mode = core.settings:get('waysigns_contrast_mode') or 'auto',
        background_darkness = tonumber(core.settings:get('waysigns_background_darkness')) or 0.40,
    },
    registered_signs = {},
    custom_resolvers = {},
    ---@type table<string, WaySignsPlayerState>
    players = {},
    ---@type table<number|string, WaySignsCachedNode>
    node_cache = {},
    ---@type table<string, string>
    texture_cache = {},
    FALLBACK_WOOD = 'waysigns_sign_wood.png',
    FALLBACK_STEEL = 'waysigns_sign_steel.png',
    DEFAULT_NORMAL = { x = 0, y = 0, z = 1 },
}

---Round a 3D position vector to integer grid coordinates
---@param p Vector|nil 3D coordinate vector to round
---@return Vector|nil rounded_pos Position vector rounded to integer coordinates, or nil if input is nil
function waysigns.round_pos(p)
    if not p then
        return nil
    end
    return vector.round(p)
end

---Get player's window / screen dimensions if available
---@param player ObjectRef Player object to inspect
---@return number|nil screen_w Screen width in pixels, or nil if unavailable
---@return number|nil screen_h Screen height in pixels, or nil if unavailable
function waysigns.get_player_window_size(player)
    if not core.get_player_window_information or not player then
        return nil, nil
    end
    local name = player:get_player_name()
    local info = core.get_player_window_information(name)
    if info and info.size and info.size.x and info.size.x > 0 and info.size.y and info.size.y > 0 then
        return info.size.x, info.size.y
    end
    return nil, nil
end

---Calculate effective HUD scale factoring in user setting and player screen resolution
---@param player ObjectRef Target player to calculate HUD scaling for
---@return number scale Effective HUD scale factor adapted for screen boundaries
function waysigns.get_effective_scale(player)
    local base_scale = math.max(1.0, math.min(3.5, waysigns.settings.hud_scale or 2.0))
    local screen_w, screen_h = waysigns.get_player_window_size(player)
    if not screen_w or not screen_h then
        return base_scale
    end

    -- Ensure overlay fits comfortably within any screen resolution
    -- On compact/mobile screens, cap scale so board never exceeds 75% width or 45% height
    local max_fit_scale_w = (screen_w * 0.75) / 380
    local max_fit_scale_h = (screen_h * 0.45) / 160
    local max_allowed = math.min(max_fit_scale_w, max_fit_scale_h)

    local effective = math.min(base_scale, max_allowed)
    -- Round to 1 decimal place for clean scaling and caching
    effective = math.floor(effective * 10 + 0.5) / 10
    return math.max(1.0, math.min(3.5, effective))
end

---Register custom sign definition for static node types
---@param nodename string Technical node name (e.g. 'default:sign_wall_wood')
---@param def WaySignsSignDef Pre-configured sign definition table
function waysigns.register_sign(nodename, def)
    waysigns.registered_signs[nodename] = def
end

---Register a custom dynamic resolver callback for complex or modpack signs
---@param fn fun(pos: Vector, node: table): table|nil Custom resolver function
function waysigns.register_resolver(fn)
    table.insert(waysigns.custom_resolvers, fn)
end

---Invalidate cached sign metadata at a given position
---Called automatically when signs are punched, placed, or dug
---@param pos Vector 3D position where sign modification occurred
function waysigns.invalidate_cache(pos)
    waysigns.node_cache[core.hash_node_position(pos)] = nil
end

---Check if text string is non-empty and not a generic placeholder
---@param str string|nil Raw candidate string
---@return boolean is_valid True if string has meaningful text
local function is_valid_sign_text(str)
    if not str or str == '' or not str:find('%S') then
        return false
    end
    -- Strip leading and trailing whitespace so surrounding spaces do not bypass placeholder checks
    local trimmed = str:match('^%s*(.-)%s*$')
    local lower = trimmed:lower()
    if lower == '(empty)' or lower == 'empty' or lower == '"(empty)"' or lower == '""' then
        return false
    end
    return true
end

---Extract clean text from node metadata across various sign mod conventions
---Supports standard text, display_text, label, and mcl_signs text1..text4
---@param meta NodeMetaRef Node metadata reference from core.get_meta(pos)
---@return string|nil text Clean sign text string, or nil if empty or placeholder
function waysigns.extract_text(meta)
    -- 1. Standard text field (Minetest Game, signs_lib, basic_signs, signs_rx, hiking, locks, jp_signs)
    local text = meta:get_string('text')
    if is_valid_sign_text(text) then
        return text
    end

    -- 2. display_modpack (signs, boards, steles, signs_road, signs_extra, markdown_poster)
    local display_text = meta:get_string('display_text')
    if is_valid_sign_text(display_text) then
        return display_text
    end

    -- 3. breadcrumbs (FaceDeer path marker signs)
    local label = meta:get_string('label')
    if is_valid_sign_text(label) then
        return label
    end

    -- 4. Multi-line sign fields (mcl_signs / VoxeLibre / MineClone2 / Mineclonia)
    local t1 = meta:get_string('text1')
    local t2 = meta:get_string('text2')
    local t3 = meta:get_string('text3')
    local t4 = meta:get_string('text4')
    if (t1 and t1:find('%S')) or (t2 and t2:find('%S')) or (t3 and t3:find('%S')) or (t4 and t4:find('%S')) then
        local lines = {}
        if t1 ~= '' then table.insert(lines, t1) end
        if t2 ~= '' then table.insert(lines, t2) end
        if t3 ~= '' then table.insert(lines, t3) end
        if t4 ~= '' then table.insert(lines, t4) end
        local combined = table.concat(lines, '\n')
        if is_valid_sign_text(combined) then
            return combined
        end
    end

    -- 5. Fallback infotext (strip outer quotes or translation wrappers e.g. "Some text")
    local infotext = meta:get_string('infotext')
    if infotext and infotext ~= '' and infotext:find('%S') then
        local unwrapped = infotext:match('^"(.*)"$')
        local cand = (unwrapped and unwrapped ~= '') and unwrapped or infotext
        if is_valid_sign_text(cand) then
            return cand
        end
    end

    return nil
end

---CGA / Linux / IRC color palette used by signs_lib and terminal signs
local CGA_COLORS = {
    ['0'] = 0x222222, -- black (boosted for readability)
    ['1'] = 0x3355FF, -- dark blue
    ['2'] = 0x22CC22, -- dark green
    ['3'] = 0x22CCCC, -- dark cyan
    ['4'] = 0xEE3333, -- dark red
    ['5'] = 0xDD22DD, -- dark magenta
    ['6'] = 0xE68A00, -- brown / orange
    ['7'] = 0xCCCCCC, -- light gray
    ['8'] = 0x888888, -- dark gray
    ['9'] = 0x5588FF, -- bright blue
    ['a'] = 0x55FF55, -- bright green
    ['b'] = 0x55FFFF, -- bright cyan
    ['c'] = 0xFF5555, -- bright red (e.g. #c Hello world)
    ['d'] = 0xFF55FF, -- bright magenta
    ['e'] = 0xFFFF55, -- yellow
    ['f'] = 0xFFFFFF, -- white
}

---Calculate perceived luminance of an RGB color (0.0 to 1.0)
---Uses standard ITU-R BT.601 formula: 0.299*R + 0.587*G + 0.114*B
---@param color number 0xRRGGBB integer color
---@return number luminance
function waysigns.get_luminance(color)
    if not color or type(color) ~= 'number' then
        return 1.0
    end
    local r = bit.band(bit.rshift(color, 16), 0xFF) / 255
    local g = bit.band(bit.rshift(color, 8), 0xFF) / 255
    local b = bit.band(color, 0xFF) / 255
    return 0.299 * r + 0.587 * g + 0.114 * b
end

---Determine if a sign background texture or node name is naturally bright/light (e.g. warning yellow, white, paper)
---@param tile string|nil Background texture name
---@param nodename string|nil Technical node name
---@return boolean is_light True if the sign surface is naturally bright
function waysigns.is_light_background(tile, nodename)
    local s = ((tile or '') .. ' ' .. (nodename or '')):lower()
    if s:find('warning') or s:find('yellow') or s:find('white') or s:find('paper')
       or s:find('poster') or s:find('plastic') or s:find('sandstone') or s:find('orange')
       or s:find('gold') or s:find('parchment') then
        return true
    end
    return false
end

---Determine optimal contrast-adjusted text color for the given background according to WCAG standards
---@param color number 0xRRGGBB integer color
---@param is_light_bg boolean Whether the background is bright/light
---@return number adjusted_color 0xRRGGBB integer color with high visual contrast
function waysigns.get_contrast_color(color, is_light_bg)
    local mode = waysigns.settings.contrast_mode or 'auto'
    if mode == 'preserve' then
        return color or 0xFFFFFF
    end

    if mode == 'bright_text' then
        if not color or waysigns.get_luminance(color) < 0.45 then
            return 0xFFFFFF
        end
        return color
    end

    -- 'auto' mode: adaptive luminance balancing
    local c = color or 0xFFFFFF
    local lum = waysigns.get_luminance(c)

    if not is_light_bg then
        -- Dark background (wood, steel, obsidian, blackboard):
        -- Dark or muted text (black, charcoal, dark blue/gray) must be brightened to crisp white
        if lum < 0.50 then
            return 0xFFFFFF
        end
        return c
    else
        -- Light background (yellow warning diamond, white steel, paper poster, milky glass):
        -- Very bright text (white, pale yellow) must be darkened to crisp charcoal (WCAG AAA >= 7.0:1)
        if lum > 0.50 then
            return 0x111111
        end
        return c
    end
end

---Strip color codes and handle escape sequences (signs_lib, engine escapes)
---@param raw_line string Raw text line possibly containing engine escape codes or signs_lib '#' tags
---@return string clean_line Line with color codes and escape sequences stripped
---@return number|nil detected_color 0xRRGGBB color if detected in the line, or nil
function waysigns.clean_line(raw_line)
    if not raw_line then
        return '', nil
    end

    local line = raw_line

    -- Fast-path for plain text lines without engine color escapes or signs_lib '#' tags
    if not line:find('#') and not line:find('\x1b') then
        return line, nil
    end

    -- 1. Strip Luanti engine color escape sequences (\x1b...)
    line = core.strip_colors(line)

    -- 2. Protect escaped signs_lib characters: ## -> \1, #^ -> \2
    line = line:gsub('##', '\1'):gsub('#%^', '\2')

    -- 3. Detect any CGA color code in this line
    local detected_color = nil
    for code in line:gmatch('#([0-9a-fA-F])') do
        local c = code:lower()
        if CGA_COLORS[c] then
            detected_color = CGA_COLORS[c]
        end
    end

    -- 4. Strip signs_lib color codes #[0-9a-fA-F], including optional trailing space
    line = line:gsub('#[0-9a-fA-F]%s?', '')

    -- 5. Restore escaped characters
    line = line:gsub('\1', '#'):gsub('\2', '^')

    return line, detected_color
end

---@class WaySignsLine
---@field text string
---@field color number

---@class WaySignsWrapResult
---@field pages WaySignsLine[][]
---@field total_lines integer
---@field max_line_len integer

---Smart word-wrapping and line splitting algorithm
---@param raw_text string Full sign text to wrap and paginate
---@param max_chars integer|nil Maximum character width per line (defaults to settings)
---@param max_lines integer|nil Maximum lines per page (defaults to settings)
---@param default_color number|nil Fallback color if no color tags are present
---@return WaySignsWrapResult result Wrapped lines split into pages with metrics
function waysigns.wrap_text(raw_text, max_chars, max_lines, default_color)
    max_chars = max_chars or waysigns.settings.max_chars_per_line
    max_lines = max_lines or waysigns.settings.max_lines
    default_color = default_color or 0xFFFFFF

    -- Normalize CRLF to LF
    local clean_text = raw_text:gsub('\r\n', '\n'):gsub('\r', '\n')
    local raw_lines = clean_text:split('\n', true)
    local wrapped_lines = {}
    local max_len = 0

    for _, raw_line in ipairs(raw_lines) do
        local line, line_color = waysigns.clean_line(raw_line)
        local active_color = line_color or default_color

        -- Trim trailing whitespace
        line = line:gsub('%s+$', '')

        if #line == 0 then
            -- Empty line preserved
            table.insert(wrapped_lines, { text = '', color = active_color })
        elseif #line <= max_chars then
            table.insert(wrapped_lines, { text = line, color = active_color })
            if #line > max_len then
                max_len = #line
            end
        else
            -- Word wrap long line
            local current_line = ''
            for word in line:gmatch('%S+') do
                if #current_line == 0 then
                    if #word > max_chars then
                        -- Word itself is larger than max_chars, chunk it
                        for i = 1, #word, max_chars do
                            local part = word:sub(i, i + max_chars - 1)
                            table.insert(wrapped_lines, { text = part, color = active_color })
                            if #part > max_len then
                                max_len = #part
                            end
                        end
                    else
                        current_line = word
                    end
                else
                    if #current_line + 1 + #word <= max_chars then
                        current_line = current_line .. ' ' .. word
                    else
                        table.insert(wrapped_lines, { text = current_line, color = active_color })
                        if #current_line > max_len then
                            max_len = #current_line
                        end
                        if #word > max_chars then
                            for i = 1, #word, max_chars do
                                local part = word:sub(i, i + max_chars - 1)
                                table.insert(wrapped_lines, { text = part, color = active_color })
                                if #part > max_len then
                                    max_len = #part
                                end
                            end
                            current_line = ''
                        else
                            current_line = word
                        end
                    end
                end
            end

            if #current_line > 0 then
                table.insert(wrapped_lines, { text = current_line, color = active_color })
                if #current_line > max_len then
                    max_len = #current_line
                end
            end
        end
    end

    if #wrapped_lines == 0 then
        wrapped_lines = { { text = '', color = default_color } }
    end

    -- Split lines into pages
    local pages = {}
    local current_page = {}

    for _, w_line in ipairs(wrapped_lines) do
        table.insert(current_page, w_line)
        if #current_page >= max_lines then
            table.insert(pages, current_page)
            current_page = {}
        end
    end

    if #current_page > 0 or #pages == 0 then
        table.insert(pages, current_page)
    end

    return {
        pages = pages,
        total_lines = #wrapped_lines,
        max_line_len = math.max(12, max_len)
    }
end

---Inspect node selection or collision box to calculate the physical face aspect ratio
---@param box_def table|nil Node box definition table
---@return number|nil aspect_ratio Calculated width-to-height ratio, or nil if invalid
local function inspect_box(box_def)
    if not box_def or type(box_def) ~= 'table' then
        return nil
    end
    local t = box_def.type
    local coords = nil
    if t == 'wallmounted' then
        coords = box_def.wall_side or box_def.wall_top or box_def.wall_bottom
    elseif t == 'fixed' then
        if type(box_def.fixed) == 'table' then
            if type(box_def.fixed[1]) == 'number' and #box_def.fixed >= 6 then
                coords = box_def.fixed
            elseif type(box_def.fixed[1]) == 'table' and #box_def.fixed[1] >= 6 then
                coords = box_def.fixed[1]
            end
        end
    elseif t == 'regular' then
        return 1.0
    end

    if coords and #coords >= 6 then
        local dx = math.abs(coords[4] - coords[1])
        local dy = math.abs(coords[5] - coords[2])
        local dz = math.abs(coords[6] - coords[3])
        -- Find thickness (min), height (mid), and width (max) using scalar math without table allocation
        local min_dim = math.min(dx, dy, dz)
        local max_dim = math.max(dx, dy, dz)
        local mid_dim = (dx + dy + dz) - min_dim - max_dim
        local minor = mid_dim
        local major = max_dim
        if minor > 0.01 and major > 0.01 then
            local ratio = major / minor
            if ratio >= 0.5 and ratio <= 3.5 then
                -- Round to 2 decimal places (e.g. 1.40)
                return math.floor(ratio * 100 + 0.5) / 100
            end
        end
    end
    return nil
end

---Determine the visual aspect ratio (width / height) of a sign node
---@param nodename string Technical node name
---@param node_def table|nil Registered node definition from core.registered_nodes
---@param reg_def WaySignsSignDef|nil Custom registration definition
---@return number aspect_ratio Width-to-height aspect ratio (e.g. 1.40 for standard signs, 3.20 for street blades)
function waysigns.get_aspect_ratio(nodename, node_def, reg_def)
    if reg_def and reg_def.aspect_ratio and reg_def.aspect_ratio > 0 then
        return reg_def.aspect_ratio
    end

    if not node_def then
        return 1.40
    end

    local ratio = inspect_box(node_def.node_box) or inspect_box(node_def.selection_box)
    if ratio then
        return ratio
    end

    return 1.40
end

---Create or retrieve cached dynamic background texture matching sign plaque
---@param base_tile string|nil Base texture name
---@param width integer Plaque width in pixels
---@param height integer Plaque height in pixels
---@param alpha number Opacity from 0.0 to 1.0
---@param is_metal boolean|nil Whether sign is metal/stone
---@param is_light_bg boolean|nil Whether background is naturally bright
---@param is_text_dark boolean|nil Whether text drawn on plaque is dark
---@param is_glass boolean|nil Whether sign is glass
---@return string texture_spec Minetest composite texture string
function waysigns.get_background_texture(base_tile, width, height, alpha, is_metal, is_light_bg, is_text_dark, is_glass)
    local w = math.max(48, math.floor(tonumber(width) or 220))
    local h = math.max(24, math.floor(tonumber(height) or 100))
    local a = math.min(1.0, math.max(0.0, tonumber(alpha) or 1.0))
    local opacity_byte = math.floor(a * 255)

    local fallback = is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD
    local tile = base_tile
    if not tile or tile == '' or type(tile) ~= 'string' then
        tile = fallback
    end

    -- Edge cases: animated or inventory cube textures or unbalanced parentheses cannot be scaled
    if tile:find('%[inventorycube') or tile:find('%[verticalframe') then
        tile = fallback
    elseif tile:find('[()]') then
        local _, open_paren = tile:gsub('%(', '')
        local _, close_paren = tile:gsub('%)', '')
        if open_paren ~= close_paren then
            tile = fallback
        end
    end

    if is_light_bg == nil then
        is_light_bg = waysigns.is_light_background(tile)
    end
    if is_text_dark == nil then
        is_text_dark = (is_light_bg == true)
    end

    local darkness = math.min(0.8, math.max(0.0, tonumber(waysigns.settings.background_darkness) or 0.40))
    local dark_byte = math.floor(darkness * 255)

    local is_glass_sign = is_glass or not not tile:find('glass')
    local cache_key = tile .. '_' .. w .. 'x' .. h .. '_' .. (is_metal and 'm' or 'w') .. '_' .. (is_glass_sign and 'g' or 'ng') .. '_' .. (is_light_bg and 'l' or 'd') .. '_' .. (is_text_dark and 'td' or 'tl') .. '_' .. dark_byte .. '_' .. opacity_byte
    local cached = waysigns.texture_cache[cache_key]
    if cached then
        return cached
    end

    -- Background glaze:
    -- Naturally light signs (yellow warning, white steel, paper poster) stay vibrant without dark tint.
    -- Glass signs receive a high-contrast frosted backing (milky pearl for dark text, deep obsidian for light text)
    -- with subdued specular sheen (opacity 40) so characters never clash with bright reflections or the world behind.
    -- Wood signs receive a deep, warm dark-walnut contrast glaze (#060402:160) ensuring > 7.0:1 WCAG AAA
    -- readability without washing out natural wood grain.
    local base_layer
    if is_glass_sign then
        local frosted_backing = is_text_dark and ('[fill:' .. w .. 'x' .. h .. ':#f4f8fcf8')
            or ('[fill:' .. w .. 'x' .. h .. ':#080c16f8')
        local glass_sheen = '(' .. tile .. '^[opacity:40^[resize:' .. w .. 'x' .. h .. ')'
        base_layer = '(' .. frosted_backing .. '^' .. glass_sheen .. ')'
    elseif is_light_bg or dark_byte == 0 then
        base_layer = tile .. '^[resize:' .. w .. 'x' .. h
    else
        local tint_color = is_metal and ('#181818:' .. dark_byte)
            or ('#060402:' .. math.max(dark_byte, 160))
        base_layer = tile .. '^[resize:' .. w .. 'x' .. h .. '^[colorize:' .. tint_color
    end

    local full_texture = base_layer
    if waysigns.settings.show_frame then
        local corner_inset = math.min(14, math.max(2, math.floor(3 * (waysigns.settings.hud_scale or 2.0))))
        local right_x = math.max(corner_inset + 8, w - 8 - corner_inset)
        local bottom_y = math.max(corner_inset + 8, h - 8 - corner_inset)
        local corners_layer = table.concat({
            '[combine:', w, 'x', h,
            ':', corner_inset, ',', corner_inset, '=waysigns_corner.png',
            ':', right_x, ',', corner_inset, '=waysigns_corner.png',
            ':', corner_inset, ',', bottom_y, '=waysigns_corner.png',
            ':', right_x, ',', bottom_y, '=waysigns_corner.png'
        }, '')

        if is_light_bg then
            full_texture = '(' .. base_layer .. '^' .. corners_layer .. ')'
        else
            local vignette_layer = 'waysigns_frame_vignette.png^[resize:' .. w .. 'x' .. h
            full_texture = '(' .. base_layer .. '^' .. vignette_layer .. '^' .. corners_layer .. ')'
        end
    end

    local result = full_texture .. '^[opacity:' .. opacity_byte
    waysigns.texture_cache[cache_key] = result
    return result
end

---Initialize or retrieve active player state tracking HUD and raycast transitions
---@param player ObjectRef Connected player object reference
---@return WaySignsPlayerState state Active player HUD state table
function waysigns.get_or_create_player_state(player)
    local name = player:get_player_name()
    if not waysigns.players[name] then
        waysigns.players[name] = {
            current_sign_pos = nil,
            current_sign_data = nil,
            current_sign_normal = nil,
            sign_face_pos = nil,
            current_page = 1,
            page_timer = 0,
            hud_bg_id = nil,
            hud_line_ids = {},
            hud_page_id = nil,
            hud_display_mode = nil,
            opacity = 0,
            target_opacity = 0,
            is_visible = false,
            check_timer = 0,
            purge_timer = 0,
            last_purged_pos = nil,
        }
    end
    return waysigns.players[name]
end

---Clean up and remove all active HUD elements (text lines, page indicator, background) for a player
---@param player ObjectRef Target player to remove HUD elements from
function waysigns.remove_all_huds(player)
    local name = player:get_player_name()
    local state = waysigns.players[name]
    if not state then
        return
    end

    -- 1. Remove text lines and page indicator FIRST so text never renders
    -- on screen for even a single frame without its background plaque.
    for _, id in ipairs(state.hud_line_ids) do
        player:hud_remove(id)
    end
    state.hud_line_ids = {}

    if state.hud_page_id then
        player:hud_remove(state.hud_page_id)
        state.hud_page_id = nil
    end

    -- 2. Remove background image LAST
    if state.hud_bg_id then
        player:hud_remove(state.hud_bg_id)
        state.hud_bg_id = nil
    end

    state.is_visible = false
    state.opacity = 0
    state.target_opacity = 0
    state.current_sign_pos = nil
    state.current_sign_data = nil
    state.current_sign_normal = nil
    state.sign_face_pos = nil
    state.hud_display_mode = nil
    state.last_purged_pos = nil
    state.purge_timer = 0
    state.rendered_page = nil
    state.rendered_scale = nil
end

---Calculate the exact 3D center position on the physical face of a sign node.
---Offsets 0.02m (2cm) in front of the board surface to eliminate z-fighting.
---@param sign_pos Vector Integer coordinate of the sign node
---@param normal Vector Surface normal pointing out from the sign toward the player
---@param intersection_point Vector|nil Exact hit point from raycast
---@param is_attached_above boolean|nil Whether the sign is at pt.above rather than pt.under
---@return Vector face_pos Calculated 3D coordinates positioned on sign front face
function waysigns.get_sign_face_pos(sign_pos, normal, intersection_point, is_attached_above)
    local norm = normal or waysigns.DEFAULT_NORMAL
    local skin_offset = 0.02

    if intersection_point then
        local attach_offset = (is_attached_above and 0.0625 or 0) + skin_offset
        if math.abs(norm.x) > 0.5 then
            return {
                x = intersection_point.x + norm.x * attach_offset,
                y = sign_pos.y,
                z = sign_pos.z,
            }
        elseif math.abs(norm.y) > 0.5 then
            return {
                x = sign_pos.x,
                y = intersection_point.y + norm.y * attach_offset,
                z = sign_pos.z,
            }
        else
            return {
                x = sign_pos.x,
                y = sign_pos.y,
                z = intersection_point.z + norm.z * attach_offset,
            }
        end
    end

    -- Fallback when intersection_point is not provided:
    -- Standard wallmounted sign thickness is 0.0625m from the wall backing
    local sign_face_offset = 0.4375 - skin_offset
    return {
        x = sign_pos.x - norm.x * sign_face_offset,
        y = sign_pos.y - norm.y * sign_face_offset,
        z = sign_pos.z - norm.z * sign_face_offset,
    }
end

---Ease-out quadratic curve for silky smooth animations: f(t) = t * (2 - t)
---Provides fast, responsive initial appearance followed by soft deceleration into full opacity.
---@param t number Progress ratio from 0.0 to 1.0
---@return number eased Eased progress value from 0.0 to 1.0
function waysigns.ease_out_quad(t)
    local clamped = math.max(0.0, math.min(1.0, t))
    return clamped * (2.0 - clamped)
end

---Render or update the HUD elements on screen or in-world waypoint
---@param player ObjectRef Target player reference
---@param state WaySignsPlayerState Player HUD state tracking current sign and opacity
function waysigns.render_hud(player, state)
    local sign_data = state.current_sign_data
    if not sign_data then
        waysigns.remove_all_huds(player)
        return
    end

    if state.hud_display_mode and state.hud_display_mode ~= waysigns.settings.display_mode then
        waysigns.remove_all_huds(player)
    end
    state.hud_display_mode = waysigns.settings.display_mode

    local hud_scale = waysigns.get_effective_scale(player)
    local pages = sign_data.wrapped.pages
    local page_idx = state.current_page
    if page_idx > #pages then
        page_idx = 1
        state.current_page = 1
    end

    local lines = pages[page_idx] or { '' }
    local total_pages = #pages
    local line_height = math.floor(20 * hud_scale)
    local padding_v = math.floor(18 * hud_scale)
    local padding_h = math.floor(24 * hud_scale)
    local char_width = 8.5 * hud_scale

    local ar = sign_data.aspect_ratio or 1.40

    -- Content required space
    local text_w = math.floor(sign_data.wrapped.max_line_len * char_width)
    local content_lines = #lines + (total_pages > 1 and 1 or 0)
    local req_w = text_w + padding_h * 2
    local req_h = content_lines * line_height + padding_v * 2

    local max_screen_w = 1600
    local max_screen_h = 900
    local screen_w, screen_h = waysigns.get_player_window_size(player)
    if screen_w and screen_h then
        max_screen_w = math.max(200, math.floor(screen_w * 0.85))
        max_screen_h = math.max(100, math.floor(screen_h * 0.70))
    end

    local board_w, board_h
    if waysigns.settings.match_aspect_ratio then
        -- Minimum plaque size to give the authentic presence of a physical sign board
        local base_w = math.floor(220 * hud_scale)
        local base_h = math.floor(base_w / ar)

        local target_w = math.max(base_w, req_w)
        local target_h = math.max(base_h, req_h)

        if (target_w / target_h) < ar then
            -- Taller content: expand width to preserve sign proportions
            board_h = target_h
            board_w = math.floor(target_h * ar)
        else
            -- Wider content: expand height to preserve sign proportions
            board_w = target_w
            board_h = math.floor(target_w / ar)
        end

        -- Max size limit considering player resolution and screen boundaries
        local max_w = math.min(max_screen_w, math.floor(460 * hud_scale))
        local max_h = math.min(max_screen_h, math.floor(max_w / ar))
        if board_w > max_w then
            board_w = max_w
            board_h = math.floor(board_w / ar)
        end
        if board_h > max_h then
            board_h = max_h
            board_w = math.floor(board_h * ar)
        end
    else
        local min_w = math.floor(180 * hud_scale)
        local max_w = math.min(max_screen_w, math.floor(420 * hud_scale))
        local min_h = math.floor(55 * hud_scale)
        local max_h = math.min(max_screen_h, math.floor(220 * hud_scale))
        board_w = math.max(min_w, math.min(max_w, req_w))
        board_h = math.max(min_h, math.min(max_h, req_h))
    end

    board_w = math.max(64, math.min(max_screen_w, board_w))
    board_h = math.max(32, math.min(max_screen_h, board_h))

    local is_fading_out = (state.target_opacity == 0)
    local bg_alpha
    local text_alpha

    if is_fading_out then
        -- Keep background plaque visible and solid during fade out
        bg_alpha = math.min(1.0, state.opacity ^ 0.6)
        -- Fade text slightly ahead of background so text is never orphaned without its plaque
        text_alpha = math.max(0.0, math.min(1.0, (state.opacity - 0.08) / 0.92))
    else
        -- Smooth ease-out quadratic fade-in
        local eased_in = waysigns.ease_out_quad(state.opacity)
        bg_alpha = eased_in
        text_alpha = eased_in
    end

    -- Detect text brightness to adapt contrast dynamically
    local text_lum_sum, text_lum_count = 0, 0
    for _, line_item in ipairs(lines) do
        local line_str = line_item.text or ''
        if line_str ~= '' then
            local line_color = line_item.color or sign_data.text_color or 0xFFFFFF
            text_lum_sum = text_lum_sum + waysigns.get_luminance(line_color)
            text_lum_count = text_lum_count + 1
        end
    end
    local avg_text_lum = (text_lum_count > 0) and (text_lum_sum / text_lum_count) or 1.0
    local is_text_dark = (avg_text_lum < 0.45)

    local nodename = sign_data.nodename or (state.current_sign_node and state.current_sign_node.name)
    local is_glass = sign_data.is_glass
        or (sign_data.tile and sign_data.tile:find('glass'))
        or (nodename and nodename:find('glass'))
        or false

    local is_light_bg = sign_data.is_light_bg
    if is_glass then
        is_light_bg = is_text_dark
    elseif is_light_bg == nil then
        is_light_bg = waysigns.is_light_background(sign_data.tile, nodename)
    end

    local bg_texture = waysigns.get_background_texture(
        sign_data.tile,
        board_w,
        board_h,
        bg_alpha,
        sign_data.is_metal,
        is_light_bg,
        is_text_dark,
        is_glass
    )

    local is_waypoint = (waysigns.settings.display_mode == 'waypoint')
    local world_pos = state.sign_face_pos or state.current_sign_pos
    local overlay_y = waysigns.settings.overlay_pos_y or 0.50

    local page_changed = (state.rendered_page ~= page_idx) or (state.rendered_scale ~= hud_scale)

    -- 1. Background image (image_waypoint or screen image)
    if not state.hud_bg_id then
        if is_waypoint then
            state.hud_bg_id = player:hud_add({
                type = 'image_waypoint',
                world_pos = world_pos,
                scale = { x = 1, y = 1 },
                text = bg_texture,
                alignment = { x = 0, y = 0 },
                offset = { x = 0, y = 0 },
                z_index = -300,
            })
        else
            state.hud_bg_id = player:hud_add({
                type = 'image',
                position = { x = 0.5, y = overlay_y },
                scale = { x = 1, y = 1 },
                text = bg_texture,
                alignment = { x = 0, y = 0 },
                offset = { x = 0, y = 0 },
                z_index = 50,
            })
        end
    else
        player:hud_change(state.hud_bg_id, 'text', bg_texture)
        if page_changed then
            if is_waypoint and world_pos then
                player:hud_change(state.hud_bg_id, 'world_pos', world_pos)
            elseif not is_waypoint then
                player:hud_change(state.hud_bg_id, 'position', { x = 0.5, y = overlay_y })
            end
        end
    end

    -- 2. Line text elements
    local start_y = -math.floor((#lines - 1) * line_height / 2)
    if total_pages > 1 then
        start_y = start_y - math.floor(8 * hud_scale)
    end

    for i, line_item in ipairs(lines) do
        local line_str = line_item.text or ''
        local line_base_color = line_item.color or sign_data.text_color or 0xFFFFFF
        local contrast_color = waysigns.get_contrast_color(line_base_color, is_light_bg)

        -- Use clean 24-bit RGB value (0xRRGGBB) as specified by Luanti HUD API
        -- NEVER pack alpha into bits 24..31: signed 32-bit integer conversion in C++ (getintfield_default)
        -- overflows on ARM64 / macOS / Linux when bit 31 is set, corrupting the color and turning text black!
        local current_color = contrast_color

        -- Embed explicit Luanti EnrichedString color escape sequence (\x1b(c@#ffffff))
        -- This guarantees the engine's font renderer renders crisp white (or contrast color) across all drivers and platforms
        local hex_col = string.format('#%06x', contrast_color)
        local esc = core.get_color_escape_sequence(hex_col)

        -- If text has faded out to near-zero, use empty string to guarantee no glyphs render on screen
        local display_text = (text_alpha > 0.01) and (esc .. line_str) or ''

        local line_y = start_y + (i - 1) * line_height
        local elem_id = state.hud_line_ids[i]

        if not elem_id then
            if is_waypoint then
                elem_id = player:hud_add({
                    type = 'waypoint',
                    world_pos = world_pos,
                    name = display_text,
                    text = '',
                    precision = 0,
                    number = current_color,
                    alignment = { x = 0, y = 0 },
                    offset = { x = 0, y = line_y },
                    z_index = -290,
                })
            else
                elem_id = player:hud_add({
                    type = 'text',
                    position = { x = 0.5, y = overlay_y },
                    text = display_text,
                    number = current_color,
                    size = { x = hud_scale },
                    style = 1,
                    alignment = { x = 0, y = 0 },
                    offset = { x = 0, y = line_y },
                    z_index = 55,
                })
            end
            state.hud_line_ids[i] = elem_id
        else
            if is_waypoint then
                player:hud_change(elem_id, 'name', display_text)
                if page_changed and world_pos then
                    player:hud_change(elem_id, 'world_pos', world_pos)
                end
            else
                player:hud_change(elem_id, 'text', display_text)
            end
            if page_changed then
                player:hud_change(elem_id, 'number', current_color)
                player:hud_change(elem_id, 'offset', { x = 0, y = line_y })
                if not is_waypoint then
                    player:hud_change(elem_id, 'size', { x = hud_scale })
                    player:hud_change(elem_id, 'position', { x = 0.5, y = overlay_y })
                end
            end
        end
    end

    -- Remove extra line elements if current page has fewer lines
    if #state.hud_line_ids > #lines then
        for j = #lines + 1, #state.hud_line_ids do
            player:hud_remove(state.hud_line_ids[j])
            state.hud_line_ids[j] = nil
        end
    end

    -- 3. Page indicator for multi-page signs
    if total_pages > 1 then
        local page_y = math.floor(board_h / 2) - math.floor(16 * hud_scale)
        local page_str = S('[@1/@2]', page_idx, total_pages)
        local pr_base = is_light_bg and 60 or 220
        local pg_base = is_light_bg and 60 or 220
        local pb_base = is_light_bg and 60 or 180
        local page_color = bit.bor(bit.lshift(pr_base, 16), bit.lshift(pg_base, 8), pb_base)
        local page_hex = string.format('#%06x', page_color)
        local page_esc = core.get_color_escape_sequence(page_hex)
        local display_page = (text_alpha > 0.01) and (page_esc .. page_str) or ''

        if not state.hud_page_id then
            if is_waypoint then
                state.hud_page_id = player:hud_add({
                    type = 'waypoint',
                    world_pos = world_pos,
                    name = display_page,
                    text = '',
                    precision = 0,
                    number = page_color,
                    alignment = { x = 0, y = 0 },
                    offset = { x = 0, y = page_y },
                    z_index = -289,
                })
            else
                state.hud_page_id = player:hud_add({
                    type = 'text',
                    position = { x = 0.5, y = overlay_y },
                    text = display_page,
                    number = page_color,
                    size = { x = math.max(1.0, hud_scale * 0.75) },
                    style = 1,
                    alignment = { x = 0, y = 0 },
                    offset = { x = 0, y = page_y },
                    z_index = 56,
                })
            end
        else
            if is_waypoint then
                player:hud_change(state.hud_page_id, 'name', display_page)
                if page_changed and world_pos then
                    player:hud_change(state.hud_page_id, 'world_pos', world_pos)
                end
            else
                player:hud_change(state.hud_page_id, 'text', display_page)
            end
            if page_changed then
                player:hud_change(state.hud_page_id, 'number', page_color)
                player:hud_change(state.hud_page_id, 'offset', { x = 0, y = page_y })
                if not is_waypoint then
                    player:hud_change(state.hud_page_id, 'size', { x = math.max(1.0, hud_scale * 0.75) })
                    player:hud_change(state.hud_page_id, 'position', { x = 0.5, y = overlay_y })
                end
            end
        end
    elseif state.hud_page_id then
        player:hud_remove(state.hud_page_id)
        state.hud_page_id = nil
    end

    state.rendered_page = page_idx
    state.rendered_scale = hud_scale
    state.is_visible = true
end

---Display sign HUD to player and initiate smooth fade-in
---@param player ObjectRef Target player reference
---@param sign_pos Vector 3D integer coordinate of the sign node
---@param sign_data table Extracted sign information table
---@param normal Vector|nil Surface normal vector pointing toward player
---@param intersection_point Vector|nil Exact surface hit point from raycast
---@param is_attached_above boolean|nil Whether sign is mounted at pt.above
function waysigns.show_hud(player, sign_pos, sign_data, normal, intersection_point, is_attached_above)
    local state = waysigns.get_or_create_player_state(player)
    local pos_changed = not state.current_sign_pos or not vector.equals(state.current_sign_pos, sign_pos)
    local text_changed = not state.current_sign_data or (state.current_sign_data.raw_text ~= sign_data.raw_text)

    if not state.is_visible or pos_changed or text_changed then
        -- Clean up previous HUD elements immediately to prevent any ghosting or transition lag
        if state.is_visible and (pos_changed or text_changed) then
            waysigns.remove_all_huds(player)
        end

        state.current_sign_pos = sign_pos
        state.current_sign_data = sign_data
        state.current_sign_normal = normal or waysigns.DEFAULT_NORMAL
        state.sign_face_pos = waysigns.get_sign_face_pos(sign_pos, state.current_sign_normal, intersection_point, is_attached_above)
        state.current_page = 1
        state.page_timer = 0
        state.opacity = (waysigns.settings.fade_time <= 0) and 1.0 or 0.0
        state.target_opacity = 1.0

        waysigns.render_hud(player, state)
        return
    end

    state.target_opacity = 1.0
end

---Initiate smooth fade-out and hide sign HUD from player
---@param player ObjectRef Target player to hide HUD from
function waysigns.hide_hud(player)
    local name = player:get_player_name()
    local state = waysigns.players[name]
    if not state then
        return
    end

    if waysigns.settings.fade_time <= 0 then
        waysigns.remove_all_huds(player)
        return
    end

    state.target_opacity = 0.0
end

---Per-player step update handling throttled raycast detection and smooth opacity fade transitions
---@param player ObjectRef Player being updated
---@param dtime number Delta time in seconds since last server step
function waysigns.update_player(player, dtime)
    local state = waysigns.get_or_create_player_state(player)

    state.check_timer = state.check_timer + dtime

    -- 1. Raycast detection (throttled at check_interval for multiplayer performance)
    if state.check_timer >= waysigns.settings.check_interval then
        state.check_timer = 0

        local eye_height = (player.get_properties and player:get_properties().eye_height) or 1.625
        local player_pos = player:get_pos()
        if not player_pos then
            return
        end

        local eye_pos = {
            x = player_pos.x,
            y = player_pos.y + eye_height,
            z = player_pos.z,
        }
        local look_dir = player:get_look_dir()
        local max_dist = waysigns.settings.max_distance
        local ray_end = {
            x = eye_pos.x + look_dir.x * max_dist,
            y = eye_pos.y + look_dir.y * max_dist,
            z = eye_pos.z + look_dir.z * max_dist,
        }

        local pointed_sign_pos = nil
        local pointed_sign_normal = nil
        local pointed_sign_data = nil
        local pointed_intersection = nil
        local pointed_is_attached = false

        local ray = core.raycast(eye_pos, ray_end, false, false)
        for pt in ray do
            if pt.type == 'node' then
                local node = core.get_node_or_nil(pt.under)
                if node and node.name ~= 'air' and node.name ~= 'ignore' then
                    local data = waysigns.get_sign_data(pt.under, node)
                    if data then
                        pointed_sign_pos = pt.under
                        pointed_sign_normal = pt.intersection_normal or waysigns.DEFAULT_NORMAL
                        pointed_sign_data = data
                        pointed_intersection = pt.intersection_point
                        pointed_is_attached = false
                        break
                    end

                    -- Check if pt.above is a sign attached to this surface
                    if pt.above then
                        local above_node = core.get_node_or_nil(pt.above)
                        if above_node and above_node.name ~= 'air' and above_node.name ~= 'ignore' then
                            local above_data = waysigns.get_sign_data(pt.above, above_node)
                            if above_data then
                                pointed_sign_pos = pt.above
                                pointed_sign_normal = pt.intersection_normal or waysigns.DEFAULT_NORMAL
                                pointed_sign_data = above_data
                                pointed_intersection = pt.intersection_point
                                pointed_is_attached = true
                                break
                            end
                        end
                    end

                    -- Solid/walkable nodes block line of sight; non-walkable flora allows raycast to pass through
                    local node_def = core.registered_nodes[node.name]
                    if node_def and node_def.walkable then
                        break
                    end
                end
            end
        end

        if pointed_sign_pos and pointed_sign_data then
            if waysigns.settings.disable_sign_entities and waysigns.purge_sign_entities then
                local pos_changed = not state.last_purged_pos or not vector.equals(state.last_purged_pos, pointed_sign_pos)
                state.purge_timer = state.purge_timer + waysigns.settings.check_interval
                if pos_changed or state.purge_timer >= 2.0 then
                    waysigns.purge_sign_entities(pointed_sign_pos)
                    state.last_purged_pos = pointed_sign_pos
                    state.purge_timer = 0
                end
            end
            waysigns.show_hud(player, pointed_sign_pos, pointed_sign_data, pointed_sign_normal, pointed_intersection, pointed_is_attached)
        else
            state.purge_timer = 0
            state.last_purged_pos = nil
            waysigns.hide_hud(player)
        end
    end

    -- 2. Fade in / fade out transitions
    if waysigns.settings.fade_time <= 0 then
        if state.opacity ~= state.target_opacity then
            state.opacity = state.target_opacity
            if state.opacity <= 0 then
                waysigns.remove_all_huds(player)
            else
                waysigns.render_hud(player, state)
            end
        end
    else
        local fade_delta = dtime / math.max(0.05, waysigns.settings.fade_time)
        if state.opacity < state.target_opacity then
            state.opacity = math.min(state.target_opacity, state.opacity + fade_delta)
            waysigns.render_hud(player, state)
        elseif state.opacity > state.target_opacity then
            state.opacity = math.max(state.target_opacity, state.opacity - fade_delta)
            if state.opacity <= 0.08 then
                waysigns.remove_all_huds(player)
            else
                waysigns.render_hud(player, state)
            end
        end
    end

    -- 3. Auto-scroll / Pagination for long texts
    if state.is_visible and state.opacity >= 0.9 and waysigns.settings.auto_scroll and state.current_sign_data then
        local total_pages = #state.current_sign_data.wrapped.pages
        if total_pages > 1 then
            state.page_timer = state.page_timer + dtime
            if state.page_timer >= waysigns.settings.scroll_delay then
                state.page_timer = 0
                state.current_page = (state.current_page % total_pages) + 1
                waysigns.render_hud(player, state)
            end
        end
    end
end

---Main globalstep callback updating sign raycasting and HUD transitions for all connected players
---@param dtime number Elapsed time in seconds since last server step
function waysigns.globalstep(dtime)
    local players = core.get_connected_players()
    for _, player in ipairs(players) do
        if player and (not player.is_valid or player:is_valid()) then
            waysigns.update_player(player, dtime)
        end
    end
end

---Initialize player state tracking when a player joins the game
---@param player ObjectRef Connecting player reference
function waysigns.on_joinplayer(player)
    if player and (not player.is_valid or player:is_valid()) then
        waysigns.get_or_create_player_state(player)
    end
end

---Clean up player state and remove all active HUD elements on player disconnect
---@param player ObjectRef Disconnecting player reference
function waysigns.on_leaveplayer(player)
    waysigns.remove_all_huds(player)
    local name = player:get_player_name()
    waysigns.players[name] = nil
end

---Clean up player HUD elements when a player dies
---@param player ObjectRef Deceased player reference
function waysigns.on_dieplayer(player)
    waysigns.remove_all_huds(player)
end


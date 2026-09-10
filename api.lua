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
        scroll_delay = tonumber(core.settings:get('waysigns_scroll_delay')) or 5.0,
        show_frame = core.settings:get_bool('waysigns_show_frame', true),
        contrast_mode = core.settings:get('waysigns_contrast_mode') or 'auto',
        background_darkness = tonumber(core.settings:get('waysigns_background_darkness')) or 0.40,
        enable_node_infotext = core.settings:get_bool('waysigns_enable_node_infotext', true),
        infotext_scale = tonumber(core.settings:get('waysigns_infotext_scale')) or 2.0,
        infotext_pos_y_offset = tonumber(core.settings:get('waysigns_infotext_pos_y_offset')) or 0.35,
        infotext_overlay_pos_y = tonumber(core.settings:get('waysigns_infotext_overlay_pos_y')) or 0.38,
        enable_inventory_quickview = core.settings:get_bool('waysigns_enable_inventory_quickview', true),
        quickview_max_slots = math.max(1, math.min(32, tonumber(core.settings:get('waysigns_quickview_max_slots')) or 32)),
        quickview_show_all = core.settings:get_bool('waysigns_quickview_show_all', true),
        quickview_respect_locks = core.settings:get_bool('waysigns_quickview_respect_locks', true),
        enable_marker = core.settings:get_bool('waysigns_enable_marker', true),
        marker_uses = math.max(0, tonumber(core.settings:get('waysigns_marker_uses')) or 100),
        enable_entity_inspection = core.settings:get_bool('waysigns_enable_entity_inspection', true),
        marker_max_chars = math.max(10, math.min(1000, tonumber(core.settings:get('waysigns_marker_max_chars')) or 250)),
        marker_sense = core.settings:get_bool('waysigns_marker_sense', true),
        marker_sense_range = math.max(2.0, math.min(30.0, tonumber(core.settings:get('waysigns_marker_sense_range')) or 10.0)),
        marker_sense_max = math.max(1, math.min(20, tonumber(core.settings:get('waysigns_marker_sense_max')) or 12)),
        marker_sense_min_opacity = math.max(0, math.min(255, tonumber(core.settings:get('waysigns_marker_sense_min_opacity')) or 75)),
        marker_sense_max_opacity = math.max(10, math.min(255, tonumber(core.settings:get('waysigns_marker_sense_max_opacity')) or 255)),
    },
    registered_signs = {},
    custom_resolvers = {},
    custom_inventory_resolvers = {},
    ---@type table<string, WaySignsPlayerState>
    players = {},
    ---@type table<number|string, WaySignsCachedNode>
    node_cache = {},
    ---@type table<string, string>
    texture_cache = {},
    MAX_TEXTURE_CACHE = 500,
    MAX_NODE_CACHE = 1000,
    FALLBACK_WOOD = 'waysigns_sign_wood.png',
    FALLBACK_STEEL = 'waysigns_sign_steel.png',
    FALLBACK_SLATE = 'waysigns_sign_slate.png',
    FALLBACK_GOLD = 'waysigns_sign_gold.png',
    FALLBACK_GLASS = 'waysigns_sign_glass.png',
    PLAQUE_STYLES = {
        wood = 'waysigns_sign_wood.png',
        steel = 'waysigns_sign_steel.png',
        slate = 'waysigns_sign_slate.png',
        gold = 'waysigns_sign_gold.png',
        glass = 'waysigns_sign_glass.png',
    },
    INSCRIPTION_COLORS = {
        white = 0xFFFFFF,
        gold = 0xFFD700,
        cyan = 0x00E5FF,
        green = 0x76FF03,
        red = 0xFF5252,
        dark = 0x222222,
    },
    DEFAULT_NORMAL = { x = 0, y = 0, z = 1 },
}

local texture_cache_keys = {}
local texture_cache_count = 0
local node_cache_keys = {}
local node_cache_count = 0

---Clear texture and node caches and reset internal eviction trackers
function waysigns.clear_caches()
    waysigns.texture_cache = {}
    texture_cache_keys = {}
    texture_cache_count = 0
    waysigns.node_cache = {}
    node_cache_keys = {}
    node_cache_count = 0
end

---Store a composite texture string in the bounded texture cache
---Evicts oldest entries when exceeding MAX_TEXTURE_CACHE
---@param key string Cache key identifying texture configuration
---@param texture string Evaluated composite texture string
function waysigns.set_cached_texture(key, texture)
    if not waysigns.texture_cache[key] then
        texture_cache_count = texture_cache_count + 1
        texture_cache_keys[#texture_cache_keys + 1] = key
        local max_entries = waysigns.MAX_TEXTURE_CACHE or 500
        while texture_cache_count > max_entries and #texture_cache_keys > 0 do
            local evict_key = table.remove(texture_cache_keys, 1)
            if evict_key then
                if waysigns.texture_cache[evict_key] ~= nil then
                    waysigns.texture_cache[evict_key] = nil
                    texture_cache_count = texture_cache_count - 1
                    break
                end
            end
        end
    end
    waysigns.texture_cache[key] = texture
end

---Store a node definition in the bounded node cache
---Evicts oldest entries when exceeding MAX_NODE_CACHE
---@param key number|string Node position hash or composite key
---@param data table Extracted sign or infotext data
function waysigns.set_cached_node(key, data)
    if not waysigns.node_cache[key] then
        node_cache_count = node_cache_count + 1
        node_cache_keys[#node_cache_keys + 1] = key
        local max_entries = waysigns.MAX_NODE_CACHE or 1000
        while node_cache_count > max_entries and #node_cache_keys > 0 do
            local evict_key = table.remove(node_cache_keys, 1)
            if evict_key then
                if waysigns.node_cache[evict_key] ~= nil then
                    waysigns.node_cache[evict_key] = nil
                    node_cache_count = node_cache_count - 1
                    break
                end
            end
        end
    end
    waysigns.node_cache[key] = data
end

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
    if not player then
        return nil, nil
    end
    local name = player:get_player_name()
    local info = core.get_player_window_information(name)
    if info and info.size and info.size.x and info.size.x > 0 and info.size.y and info.size.y > 0 then
        return info.size.x, info.size.y
    end
    return nil, nil
end

---Calculate effective HUD scale factoring in user setting, node type, and player screen resolution
---@param player ObjectRef Target player to calculate HUD scaling for
---@param is_infotext boolean|nil Whether calculating for a node infotext HUD
---@param precomputed_w number|nil Optional pre-queried screen width in pixels
---@param precomputed_h number|nil Optional pre-queried screen height in pixels
---@return number scale Effective HUD scale factor adapted for screen boundaries
function waysigns.get_effective_scale(player, is_infotext, precomputed_w, precomputed_h)
    local raw_scale = is_infotext and (waysigns.settings.infotext_scale or 2.0) or (waysigns.settings.hud_scale or 2.0)
    local min_scale = is_infotext and 0.8 or 1.0
    local max_scale = is_infotext and 3.5 or 3.5
    local base_scale = math.max(min_scale, math.min(max_scale, raw_scale))
    local screen_w = precomputed_w
    local screen_h = precomputed_h
    if not screen_w or not screen_h then
        screen_w, screen_h = waysigns.get_player_window_size(player)
    end
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
    return math.max(min_scale, math.min(max_scale, effective))
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

---Register a custom inventory resolver for a specific node name (e.g. detached or player-bound containers)
---@param nodename string Node name to register resolver for
---@param resolver function Function(pos, node, meta, player): table|nil returning list of itemstacks or inventory table
function waysigns.register_inventory_resolver(nodename, resolver)
    if type(nodename) == 'string' and type(resolver) == 'function' then
        waysigns.custom_inventory_resolvers[nodename] = resolver
    end
end

---Invalidate cached sign metadata at a given position
---Called automatically when signs are punched, placed, or dug
---@param pos Vector 3D position where sign modification occurred
function waysigns.invalidate_cache(pos)
    if not pos then
        return
    end
    local hash = core.hash_node_position(pos)
    if waysigns.node_cache[hash] ~= nil then
        waysigns.node_cache[hash] = nil
        node_cache_count = math.max(0, node_cache_count - 1)
    end
end

---@type table<string, { pos: Vector, author: string, plaque: string, color: string }>
waysigns.inscribed_positions = {}

---Convert a 3D position vector into a standardized string coordinate key "X,Y,Z"
---@param pos Vector 3D position vector
---@return string|nil key Integer coordinate key string, or nil if invalid
function waysigns.pos_to_key(pos)
    if not pos then return nil end
    local r = vector.round(pos)
    return string.format('%d,%d,%d', r.x, r.y, r.z)
end

---Register an inscribed node position in the spatial registry
---@param pos Vector Node position
---@param data table Inscription metadata (author, plaque, color)
function waysigns.register_inscribed_pos(pos, data)
    local key = waysigns.pos_to_key(pos)
    if not key then return end
    local r = vector.round(pos)
    waysigns.inscribed_positions[key] = {
        pos = { x = r.x, y = r.y, z = r.z },
        author = (data and data.author) or '',
        plaque = (data and data.plaque) or 'default',
        color = (data and data.color) or 'white',
    }
    waysigns.save_inscribed_registry()
end

---Unregister an inscribed node position from the spatial registry
---@param pos Vector Node position
function waysigns.unregister_inscribed_pos(pos)
    local key = waysigns.pos_to_key(pos)
    if not key then return end
    if waysigns.inscribed_positions[key] then
        waysigns.inscribed_positions[key] = nil
        waysigns.save_inscribed_registry()
    end
end

---Get registered inscription data for a position
---@param pos Vector Node position
---@return table|nil data Registered inscription data or nil
function waysigns.get_inscribed_pos(pos)
    local key = waysigns.pos_to_key(pos)
    return key and waysigns.inscribed_positions[key]
end

---Load registered inscribed positions from mod storage
function waysigns.load_inscribed_registry()
    local storage = core.get_mod_storage and core.get_mod_storage()
    if not storage then return end
    local raw = storage:get_string('inscribed_positions')
    if raw and raw ~= '' then
        local ok, data = pcall(core.parse_json, raw)
        if ok and type(data) == 'table' then
            waysigns.inscribed_positions = data
        end
    end
end

---Save registered inscribed positions to mod storage
function waysigns.save_inscribed_registry()
    local storage = core.get_mod_storage and core.get_mod_storage()
    if not storage then return end
    local ok, json = pcall(core.write_json, waysigns.inscribed_positions)
    if ok and json then
        storage:set_string('inscribed_positions', json)
    end
end

---Handle node destruction for inscribed position unregistration and cache invalidation
---@param pos Vector 3D position where node was dug
function waysigns.on_dignode(pos)
    waysigns.invalidate_cache(pos)
    waysigns.unregister_inscribed_pos(pos)
end

---Strip all engine escape sequences (\x1b...) including colors, translations, and formatting
---Matches the Luanti unescape_enriched algorithm to guarantee zero escape codes reach HUD elements.
---@param str string|nil Input string possibly containing engine escape sequences
---@return string clean_str Sanitized string with all \x1b sequences stripped
function waysigns.strip_all_escapes(str)
    if not str or not str:find('\x1b') then
        return str or ''
    end
    local s = core.strip_escapes(str)
    if s:find('\x1b') then
        s = s:gsub('\x1b%b()', ''):gsub('\x1b%([^%)]*$', ''):gsub('\x1b.', ''):gsub('\x1b', '')
    end
    return s
end

---Check if text string is non-empty and not a generic placeholder
---@param str string|nil Raw candidate string
---@return boolean is_valid True if string has meaningful text
function waysigns.is_valid_sign_text(str)
    if not str or str == '' or not str:find('%S') then
        return false
    end
    local unescaped = waysigns.strip_all_escapes(str)
    if not unescaped:find('%S') then
        return false
    end
    -- Strip leading and trailing whitespace so surrounding spaces do not bypass placeholder checks
    local trimmed = unescaped:match('^%s*(.-)%s*$')
    local lower = trimmed and trimmed:lower() or ''
    if lower == '(empty)' or lower == 'empty' or lower == '"(empty)"' or lower == '""' then
        return false
    end
    return true
end
local is_valid_sign_text = waysigns.is_valid_sign_text

---Extract clean text from node metadata across various sign mod conventions
---Supports standard text, display_text, label, and mcl_signs text1..text4
---@param meta NodeMetaRef Node metadata reference from core.get_meta(pos)
---@return string|nil text Clean sign text string, or nil if empty or placeholder
function waysigns.extract_text(meta)
    -- 0. Dedicated WaySigns inscription marker text (takes top priority)
    local waysigns_text = meta:get_string('waysigns_text')
    if is_valid_sign_text(waysigns_text) then
        return waysigns_text
    end

    -- 1. Standard text field (Luanti Game / default, signs_lib, basic_signs, signs_rx, hiking, locks, jp_signs)
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
        local cleaned = waysigns.strip_all_escapes and waysigns.strip_all_escapes(infotext) or infotext
        local unwrapped = cleaned:match('^"(.*)"$')
        local cand = (unwrapped and unwrapped ~= '') and unwrapped or cleaned
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

    -- 1. Detect 24-bit RGB color from engine color escape if present (\27(c@#RRGGBB))
    local detected_color = nil
    local hex_col = line:match('\27%(c@#(%x+)%)')
    if hex_col then
        if #hex_col == 6 then
            detected_color = tonumber(hex_col, 16)
        elseif #hex_col == 3 then
            local r = hex_col:sub(1, 1)
            local g = hex_col:sub(2, 2)
            local b = hex_col:sub(3, 3)
            detected_color = tonumber(r .. r .. g .. g .. b .. b, 16)
        elseif #hex_col == 8 then
            detected_color = tonumber(hex_col:sub(1, 6), 16)
        end
    end

    -- 2. Strip all Luanti engine escape sequences (\x1b...) including translations and colors
    line = waysigns.strip_all_escapes(line)

    -- 3. Protect escaped signs_lib characters: ## -> \1, #^ -> \2
    line = line:gsub('##', '\1'):gsub('#%^', '\2')

    -- 4. Detect any CGA color code in this line if not already set by engine escape
    if not detected_color then
        for code in line:gmatch('#([0-9a-fA-F])') do
            local c = code:lower()
            if CGA_COLORS[c] then
                detected_color = CGA_COLORS[c]
            end
        end
    end

    -- 5. Strip signs_lib color codes #[0-9a-fA-F], including optional trailing space
    line = line:gsub('#[0-9a-fA-F]%s?', '')

    -- 6. Restore escaped characters
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

---Determine the unit normal vector pointing directly outwards from the front face of a sign node
---@param node table Node table {name = string, param2 = number}
---@return Vector|nil front_dir Normal vector pointing outward from front face, or nil if unoriented
function waysigns.get_sign_front_dir(node)
    if not node or not node.name then
        return nil
    end
    local node_def = core.registered_nodes[node.name]
    local ptype = node_def and node_def.paramtype2
    local p2 = node.param2 or 0

    if ptype == 'wallmounted' or ptype == 'colorwallmounted' then
        local back = core.wallmounted_to_dir(p2 % 8)
        if back then
            return vector.multiply(back, -1)
        end
    elseif ptype == 'facedir' or ptype == 'colorfacedir' then
        local back = core.facedir_to_dir(p2 % 32)
        if back then
            return vector.multiply(back, -1)
        end
    elseif ptype == '4dir' or ptype == 'color4dir' then
        local back = core.fourdir_to_dir(p2 % 4)
        if back then
            return vector.multiply(back, -1)
        end
    elseif ptype == 'degrotate' or ptype == 'colordegrotate' then
        local deg = (p2 % 240) * 1.5
        local yaw = math.rad(deg + 1)
        local back = core.yaw_to_dir(yaw)
        if back then
            return vector.multiply(back, -1)
        end
    end

    return nil
end

---Check if the player's raycast is pointing at the front face of the sign
---@param node table Node table {name = string, param2 = number}
---@param intersection_normal Vector|nil Normal of hit surface
---@param look_dir Vector|nil Player look direction vector
---@return boolean is_front True if pointing at front face (or orientation undetermined)
function waysigns.is_pointing_front_face(node, intersection_normal, look_dir)
    local front_dir = waysigns.get_sign_front_dir(node)
    if not front_dir then
        -- If node has no directional orientation defined, allow display
        return true
    end

    if intersection_normal then
        local norm_dot = vector.dot(intersection_normal, front_dir)
        if norm_dot < 0.65 then
            return false
        end
    end

    if look_dir then
        local look_dot = vector.dot(look_dir, front_dir)
        if look_dot >= 0 then
            return false
        end
    end

    return true
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
---@param quickview_items table|nil Optional list of items for container quickview dock
---@return string texture_spec Luanti composite texture string
function waysigns.get_background_texture(base_tile, width, height, alpha, is_metal, is_light_bg, is_text_dark, is_glass, quickview_items)
    local w = math.max(48, math.floor(tonumber(width) or 220))
    local h = math.max(24, math.floor(tonumber(height) or 100))
    local a = math.min(1.0, math.max(0.0, tonumber(alpha) or 1.0))
    local opacity_byte = math.floor(a * 255)

    local fallback = is_metal and waysigns.FALLBACK_STEEL or waysigns.FALLBACK_WOOD
    local tile = base_tile
    if not tile or tile == '' or type(tile) ~= 'string' then
        tile = fallback
    end

    -- Edge cases: inventory cube textures or unbalanced parentheses cannot be scaled
    if tile:find('%[inventorycube') then
        tile = fallback
    elseif tile:find('[()]') then
        local _, open_paren = tile:gsub('%(', '')
        local _, close_paren = tile:gsub('%)', '')
        if open_paren ~= close_paren then
            tile = fallback
        end
    end

    -- Normalize any existing verticalframe animation to crop frame 0
    if tile:find('%[verticalframe') then
        tile = tile:gsub('%[verticalframe:(%d+):%d+', '[verticalframe:%1:0')
    end

    if is_light_bg == nil then
        is_light_bg = waysigns.is_light_background(tile)
    end
    if is_text_dark == nil then
        is_text_dark = (is_light_bg == true)
    end

    local darkness = math.min(0.8, math.max(0.0, tonumber(waysigns.settings.background_darkness) or 0.40))
    local dark_byte = math.floor(darkness * 255)

    local inv_fingerprint = ''
    if quickview_items and #quickview_items > 0 then
        local parts = {}
        for _, item in ipairs(quickview_items) do
            parts[#parts + 1] = item.name .. ':' .. tostring(item.count)
        end
        inv_fingerprint = '_qv:' .. table.concat(parts, ';')
    end

    local is_glass_sign = is_glass or not not tile:find('glass')
    local cache_key = tile .. '_' .. w .. 'x' .. h .. '_' .. (is_metal and 'm' or 'w') .. '_' .. (is_glass_sign and 'g' or 'ng') .. '_' .. (is_light_bg and 'l' or 'd') .. '_' .. (is_text_dark and 'td' or 'tl') .. '_' .. dark_byte .. '_' .. opacity_byte .. inv_fingerprint
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
    -- If tile has multiple overlaid layers (contains '^' separating texture layers)
    -- and is not already enclosed in parentheses or a [combine modifier,
    -- group them with parentheses so that ^[resize and ^[colorize apply to the entire composite.
    local resizable_tile = tile
    if tile:find('%^[^%[]') and not tile:find('^%(') and not tile:find('^%[combine') then
        resizable_tile = '(' .. tile .. ')'
    end

    local base_layer
    if is_glass_sign then
        local frosted_backing = is_text_dark and ('[fill:' .. w .. 'x' .. h .. ':#f4f8fcf8')
            or ('[fill:' .. w .. 'x' .. h .. ':#080c16f8')
        local glass_sheen = '(' .. resizable_tile .. '^[opacity:40^[resize:' .. w .. 'x' .. h .. ')'
        base_layer = '(' .. frosted_backing .. '^' .. glass_sheen .. ')'
    elseif is_light_bg or dark_byte == 0 then
        base_layer = resizable_tile .. '^[resize:' .. w .. 'x' .. h
    else
        local tint_color = is_metal and ('#181818:' .. dark_byte)
            or ('#060402:' .. math.max(dark_byte, 160))
        base_layer = resizable_tile .. '^[resize:' .. w .. 'x' .. h .. '^[colorize:' .. tint_color
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

    if quickview_items and #quickview_items > 0 then
        local dock_parts = { '[combine:', w, 'x', h }
        local num_items = math.min(#quickview_items, 32)
        local cols = math.min(num_items, 8)
        local rows = math.min(4, math.ceil(num_items / cols))

        -- Scale slot size, icon size, spacing, and bottom margin proportionally with plaque width
        -- Base width is 224px (standard square infotext plaque at scale 1.4, scales to 320px at default scale 2.0)
        local scale_ratio = w / 224
        local base_slot = 22
        local slot_size = math.max(12, math.floor(base_slot * scale_ratio + 0.5))
        local icon_size = math.max(8, math.floor((base_slot - 4) * scale_ratio + 0.5))
        local slot_spacing = math.max(1, math.floor(2 * scale_ratio + 0.5))
        local bottom_margin = math.max(6, math.floor(10 * scale_ratio + 0.5))

        -- Ensure grid always fits within available width with margins
        local avail_w = math.max(32, w - 24)
        local max_fit_slot = math.max(10, math.floor((avail_w - (cols - 1) * slot_spacing) / cols))
        if slot_size > max_fit_slot then
            slot_size = max_fit_slot
            icon_size = math.max(8, slot_size - 4)
        end

        local total_grid_h = rows * slot_size + (rows - 1) * slot_spacing
        local grid_start_y = h - bottom_margin - total_grid_h

        for r = 1, rows do
            local row_y = grid_start_y + (r - 1) * (slot_size + slot_spacing)
            local row_start_idx = (r - 1) * cols + 1
            local row_end_idx = math.min(num_items, r * cols)
            local row_count = row_end_idx - row_start_idx + 1

            if row_count > 0 then
                local row_w = row_count * slot_size + (row_count - 1) * slot_spacing
                local row_start_x = math.floor((w - row_w) / 2)
                local icon_offset = math.floor((slot_size - icon_size) / 2)

                for col_idx = 1, row_count do
                    local item_idx = row_start_idx + col_idx - 1
                    local item = quickview_items[item_idx]
                    local sx = row_start_x + (col_idx - 1) * (slot_size + slot_spacing)
                    dock_parts[#dock_parts + 1] = ':' .. sx .. ',' .. row_y .. '=[fill\\:' .. slot_size .. 'x' .. slot_size .. '\\:#000000a0'
                    local raw_icon = item.icon or 'unknown_item.png'
                    local wrapped_raw = (raw_icon:find('%[') and ('(' .. raw_icon .. ')') or raw_icon)
                    local resized_icon = wrapped_raw .. '^[resize:' .. icon_size .. 'x' .. icon_size
                    local escaped_icon = resized_icon:gsub('\\', '\\\\'):gsub(':', '\\:'):gsub('%^', '\\^')
                    dock_parts[#dock_parts + 1] = ':' .. (sx + icon_offset) .. ',' .. (row_y + icon_offset) .. '=' .. escaped_icon
                end
            end
        end
        local dock_layer = table.concat(dock_parts, '')
        full_texture = '(' .. full_texture .. '^' .. dock_layer .. ')'
    end

    local result = full_texture .. '^[opacity:' .. opacity_byte
    waysigns.set_cached_texture(cache_key, result)
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
            rendered_line_texts = {},
            rendered_line_colors = {},
            rendered_page_text = nil,
            rendered_bg_texture = nil,
            opacity = 0,
            target_opacity = 0,
            is_visible = false,
            check_timer = 0,
            purge_timer = 0,
            last_purged_pos = nil,
            eye_height = (player.get_properties and player:get_properties().eye_height) or 1.625,
            scratch_eye_pos = { x = 0, y = 0, z = 0 },
            scratch_ray_end = { x = 0, y = 0, z = 0 },
            marker_waypoints = {},
            marker_sense_timer = 0,
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

    state.rendered_line_texts = {}
    state.rendered_line_colors = {}
    state.rendered_page_text = nil
    state.rendered_bg_texture = nil

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

---Check if a player is dead or undergoing a death sequence
---@param player ObjectRef Player reference
---@return boolean is_dead True if player has 0 HP or death sequence active
function waysigns.is_player_dead(player)
    if not player then
        return false
    end
    if player.get_hp and player:get_hp() <= 0 then
        return true
    end
    local meta = player.get_meta and player:get_meta()
    if meta and meta:get_string('deathstats:death_active') == '1' then
        return true
    end
    return false
end

---Calculate the exact 3D position on the physical face of a sign or node.
---Offsets 0.02m (2cm) in front of the board surface to eliminate z-fighting.
---For node infotext, positions the waypoint on the top half of the node face.
---@param sign_pos Vector Integer coordinate of the sign node
---@param normal Vector Surface normal pointing out from the sign toward the player
---@param intersection_point Vector|nil Exact hit point from raycast
---@param is_attached_above boolean|nil Whether the sign is at pt.above rather than pt.under
---@param is_infotext boolean|nil Whether target is a generic node with infotext
---@return Vector face_pos Calculated 3D coordinates positioned on node front face
function waysigns.get_sign_face_pos(sign_pos, normal, intersection_point, is_attached_above, is_infotext)
    local norm = normal or waysigns.DEFAULT_NORMAL
    local skin_offset = 0.02
    local y_offset = is_infotext and (waysigns.settings.infotext_pos_y_offset or 0.35) or 0

    if intersection_point then
        local attach_offset = (is_attached_above and 0.0625 or 0) + skin_offset
        if math.abs(norm.x) > 0.5 then
            return {
                x = intersection_point.x + norm.x * attach_offset,
                y = sign_pos.y + y_offset,
                z = sign_pos.z,
            }
        elseif math.abs(norm.y) > 0.5 then
            local vertical_adjust = (norm.y > 0) and (y_offset * 0.5) or 0
            return {
                x = sign_pos.x,
                y = intersection_point.y + norm.y * attach_offset + vertical_adjust,
                z = sign_pos.z,
            }
        else
            return {
                x = sign_pos.x,
                y = sign_pos.y + y_offset,
                z = intersection_point.z + norm.z * attach_offset,
            }
        end
    end

    -- Fallback when intersection_point is not provided:
    -- Standard wallmounted sign thickness is 0.0625m from the wall backing
    local sign_face_offset = 0.4375 - skin_offset
    return {
        x = sign_pos.x - norm.x * sign_face_offset,
        y = sign_pos.y - norm.y * sign_face_offset + y_offset,
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
    if waysigns.is_player_dead(player) then
        waysigns.remove_all_huds(player)
        return
    end

    local sign_data = state.current_sign_data
    if not sign_data then
        waysigns.remove_all_huds(player)
        return
    end

    if state.hud_display_mode and state.hud_display_mode ~= waysigns.settings.display_mode then
        waysigns.remove_all_huds(player)
    end
    state.hud_display_mode = waysigns.settings.display_mode

    local screen_w, screen_h = waysigns.get_player_window_size(player)
    local hud_scale = waysigns.get_effective_scale(player, sign_data.is_infotext, screen_w, screen_h)
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

    local qv_count = (sign_data.quickview_items and #sign_data.quickview_items) or 0
    local qv_rows = 0
    if qv_count > 0 then
        local qv_cols = math.min(qv_count, 8)
        qv_rows = math.min(4, math.ceil(qv_count / qv_cols))
    end

    -- Content required space
    local max_line_len = (sign_data.wrapped and sign_data.wrapped.max_line_len) or 12
    local text_w = math.floor(max_line_len * char_width)
    local content_lines = #lines
    local req_w = text_w + padding_h * 2
    local req_h = content_lines * line_height + padding_v * 2
    if total_pages > 1 then
        req_w = math.max(req_w, text_w + padding_h * 2 + math.floor(30 * hud_scale))
    end
    if qv_rows == 1 then
        req_h = req_h + math.floor(36 * hud_scale)
    elseif qv_rows == 2 then
        req_h = req_h + math.floor(54 * hud_scale)
    elseif qv_rows >= 3 then
        req_h = req_h + math.floor(72 * hud_scale)
    end

    local max_screen_w = 1600
    local max_screen_h = 900
    if screen_w and screen_h then
        max_screen_w = math.max(200, math.floor(screen_w * 0.85))
        max_screen_h = math.max(100, math.floor(screen_h * 0.70))
    end

    local board_w, board_h
    if sign_data.is_infotext then
        -- Option 1: Lock infotext plaques to a constant, stable square size regardless of item count
        local base_dim = math.floor(160 * hud_scale)
        board_w = math.max(64, math.min(max_screen_w, base_dim))
        board_h = math.max(64, math.min(max_screen_h, board_w))
        board_w = board_h
    elseif waysigns.settings.match_aspect_ratio then
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

    -- Quantize bg_alpha during fade transitions to prevent sending massive composite texture strings every tick
    local q_alpha = math.floor(bg_alpha * 16 + 0.5) / 16
    if bg_alpha > 0 and q_alpha == 0 then q_alpha = 1 / 16 end
    if bg_alpha < 1 and q_alpha == 1 and state.opacity < 0.99 then q_alpha = 15 / 16 end
    bg_alpha = q_alpha

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
        is_glass,
        sign_data.quickview_items
    )

    local is_waypoint = (waysigns.settings.display_mode == 'waypoint')
    local world_pos = state.sign_face_pos or state.current_sign_pos
    local overlay_y = (sign_data.is_infotext and waysigns.settings.infotext_overlay_pos_y)
        or waysigns.settings.overlay_pos_y
        or 0.50

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
        state.rendered_bg_texture = bg_texture
    else
        if state.rendered_bg_texture ~= bg_texture then
            player:hud_change(state.hud_bg_id, 'text', bg_texture)
            state.rendered_bg_texture = bg_texture
        end
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
        start_y = start_y - math.floor(4 * hud_scale)
    end
    if qv_rows == 1 then
        start_y = start_y - math.floor(14 * hud_scale)
    elseif qv_rows == 2 then
        start_y = start_y - math.floor(22 * hud_scale)
    elseif qv_rows >= 3 then
        start_y = start_y - math.floor(30 * hud_scale)
    end

    state.rendered_line_texts = state.rendered_line_texts or {}
    state.rendered_line_colors = state.rendered_line_colors or {}

    for i, line_item in ipairs(lines) do
        local line_str = line_item.text or ''
        local line_base_color = line_item.color or sign_data.text_color or 0xFFFFFF
        local contrast_color = waysigns.get_contrast_color(line_base_color, is_light_bg)

        -- Use clean 24-bit RGB value (0xRRGGBB) as specified by Luanti HUD API
        -- NEVER pack alpha into bits 24..31: signed 32-bit integer conversion in C++ (getintfield_default)
        -- overflows on ARM64 / macOS / Linux when bit 31 is set, corrupting the color and turning text black!
        local current_color = contrast_color

        -- HUD text color in Luanti is specified via the 24-bit RGB 'number' field.
        -- Omit get_color_escape_sequence (\x1b(c@#ffffff)) because the client engine's unescape_translate()
        -- parser runs on HUD text and emits 'Ignoring escape sequence c@#fff in translation' warnings.
        local display_text = (text_alpha > 0.01) and line_str or ''

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
            state.rendered_line_texts[i] = display_text
            state.rendered_line_colors[i] = current_color
        else
            if is_waypoint then
                if state.rendered_line_texts[i] ~= display_text then
                    player:hud_change(elem_id, 'name', display_text)
                    state.rendered_line_texts[i] = display_text
                end
                if state.rendered_line_colors[i] ~= current_color then
                    player:hud_change(elem_id, 'number', current_color)
                    state.rendered_line_colors[i] = current_color
                end
                if page_changed and world_pos then
                    player:hud_change(elem_id, 'world_pos', world_pos)
                end
            else
                if state.rendered_line_texts[i] ~= display_text then
                    player:hud_change(elem_id, 'text', display_text)
                    state.rendered_line_texts[i] = display_text
                end
                if state.rendered_line_colors[i] ~= current_color then
                    player:hud_change(elem_id, 'number', current_color)
                    state.rendered_line_colors[i] = current_color
                end
                if page_changed then
                    player:hud_change(elem_id, 'offset', { x = 0, y = line_y })
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
            state.rendered_line_texts[j] = nil
            state.rendered_line_colors[j] = nil
        end
    end

    -- 3. Page indicator for multi-page signs (placed in top-right header badge)
    if total_pages > 1 then
        local badge_x = math.floor(board_w / 2) - math.floor(22 * hud_scale)
        local badge_y = -math.floor(board_h / 2) + math.floor(12 * hud_scale)
        local page_str = string.format('[%d/%d]', page_idx, total_pages)
        local pr_base = is_light_bg and 60 or 220
        local pg_base = is_light_bg and 60 or 220
        local pb_base = is_light_bg and 60 or 180
        local page_color = bit.bor(bit.lshift(pr_base, 16), bit.lshift(pg_base, 8), pb_base)
        local display_page = (text_alpha > 0.01) and page_str or ''

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
                    offset = { x = badge_x, y = badge_y },
                    z_index = -289,
                })
            else
                state.hud_page_id = player:hud_add({
                    type = 'text',
                    position = { x = 0.5, y = overlay_y },
                    text = display_page,
                    number = page_color,
                    size = { x = math.max(0.8, hud_scale * 0.80) },
                    style = 1,
                    alignment = { x = 0, y = 0 },
                    offset = { x = badge_x, y = badge_y },
                    z_index = 56,
                })
            end
            state.rendered_page_text = display_page
        else
            if state.rendered_page_text ~= display_page then
                if is_waypoint then
                    player:hud_change(state.hud_page_id, 'name', display_page)
                else
                    player:hud_change(state.hud_page_id, 'text', display_page)
                end
                state.rendered_page_text = display_page
            end
            if page_changed then
                player:hud_change(state.hud_page_id, 'number', page_color)
                player:hud_change(state.hud_page_id, 'offset', { x = badge_x, y = badge_y })
                if not is_waypoint then
                    player:hud_change(state.hud_page_id, 'size', { x = math.max(0.8, hud_scale * 0.80) })
                    player:hud_change(state.hud_page_id, 'position', { x = 0.5, y = overlay_y })
                end
            end
        end
    elseif state.hud_page_id then
        player:hud_remove(state.hud_page_id)
        state.hud_page_id = nil
        state.rendered_page_text = nil
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
    if waysigns.is_player_dead(player) then
        return
    end

    local state = waysigns.get_or_create_player_state(player)
    local pos_changed = not state.current_sign_pos or not vector.equals(state.current_sign_pos, sign_pos)
    local text_changed = not state.current_sign_data or (state.current_sign_data.raw_text ~= sign_data.raw_text)

    if not state.is_visible or pos_changed then
        -- Clean up previous HUD elements immediately when switching to a different sign
        if state.is_visible then
            waysigns.remove_all_huds(player)
        end

        state.current_sign_pos = sign_pos
        state.current_sign_data = sign_data
        state.current_sign_normal = normal or waysigns.DEFAULT_NORMAL
        state.sign_face_pos = (sign_data.is_entity and (sign_data.pos or sign_pos))
            or waysigns.get_sign_face_pos(sign_pos, state.current_sign_normal, intersection_point, is_attached_above, sign_data.is_infotext)
        state.current_page = 1
        state.page_timer = 0
        state.opacity = (waysigns.settings.fade_time <= 0) and 1.0 or 0.0
        state.target_opacity = 1.0

        waysigns.render_hud(player, state)
        return
    elseif text_changed then
        -- Same node position, but text or container contents updated: update in-place without tearing down HUDs
        state.current_sign_data = sign_data
        state.current_page = 1
        state.page_timer = 0
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

---Remove all active marker-wield proximity waypoint HUD elements for a player
---@param player ObjectRef Target player
---@param state WaySignsPlayerState Player state table
function waysigns.remove_marker_waypoints(player, state)
    if not state or not state.marker_waypoints then
        return
    end
    for _, wp in pairs(state.marker_waypoints) do
        if wp.hud_id then
            player:hud_remove(wp.hud_id)
        end
    end
    state.marker_waypoints = {}
end

---Update 3D proximity HUD waypoint glyphs over nearby inscribed nodes and entities while holding the marker tool
---Filters candidates to those in the player's view direction (in sight) and applies distance-based opacity progression
---@param player ObjectRef Player holding the marker
---@param state WaySignsPlayerState Player state table
function waysigns.update_marker_waypoints(player, state)
    if not player or not state then
        return
    end

    local player_pos = player:get_pos()
    if not player_pos then
        waysigns.remove_marker_waypoints(player, state)
        return
    end

    local eye_height = state.eye_height or 1.625
    local eye_pos = { x = player_pos.x, y = player_pos.y + eye_height, z = player_pos.z }
    local sense_range = waysigns.settings.marker_sense_range or 10.0
    local max_waypoints = waysigns.settings.marker_sense_max or 12

    local look_dir = player.get_look_dir and player:get_look_dir()
    if not look_dir then
        look_dir = { x = 0, y = 0, z = 1 }
    end

    local candidates = {}

    -- 1. Check registered inscribed nodes
    for key, item in pairs(waysigns.inscribed_positions) do
        local target_pos = { x = item.pos.x, y = item.pos.y + 0.65, z = item.pos.z }
        local dx = target_pos.x - eye_pos.x
        local dy = target_pos.y - eye_pos.y
        local dz = target_pos.z - eye_pos.z
        local dist_sq = dx * dx + dy * dy + dz * dz
        if dist_sq <= (sense_range * sense_range) then
            local dist = math.sqrt(dist_sq)
            -- Check view direction: is target in front of player (in sight)?
            local dot = (dist > 0.001) and ((look_dir.x * dx + look_dir.y * dy + look_dir.z * dz) / dist) or 1.0
            if dot > 0 then
                -- If player is looking directly at this sign and full plaque HUD is visible, suppress glyph
                local is_pointed = state.is_visible and state.current_sign_pos and vector.equals(state.current_sign_pos, item.pos)
                if not is_pointed then
                    local los = true
                    if core.line_of_sight then
                        los = core.line_of_sight(eye_pos, target_pos)
                    end
                    if los then
                        table.insert(candidates, {
                            key = key,
                            pos = target_pos,
                            dist = dist,
                            is_entity = false,
                        })
                    end
                end
            end
        end
    end

    -- 2. Check nearby inscribed entities (if entity inspection enabled)
    if waysigns.settings.enable_entity_inspection and core.get_objects_inside_radius then
        local nearby_objs = core.get_objects_inside_radius(player_pos, sense_range)
        for _, obj in ipairs(nearby_objs) do
            if obj and (not obj.is_player or not obj:is_player()) then
                local ent_data = waysigns.get_entity_inscription and waysigns.get_entity_inscription(obj)
                if ent_data and ent_data.text and ent_data.text ~= '' then
                    local obj_pos = obj:get_pos()
                    if obj_pos then
                        local is_pointed = state.is_visible and state.current_sign_data and state.current_sign_data.obj == obj
                        if not is_pointed then
                            local target_pos = { x = obj_pos.x, y = obj_pos.y + 0.75, z = obj_pos.z }
                            local dx = target_pos.x - eye_pos.x
                            local dy = target_pos.y - eye_pos.y
                            local dz = target_pos.z - eye_pos.z
                            local dist_sq = dx * dx + dy * dy + dz * dz
                            if dist_sq <= (sense_range * sense_range) then
                                local dist = math.sqrt(dist_sq)
                                local dot = (dist > 0.001) and ((look_dir.x * dx + look_dir.y * dy + look_dir.z * dz) / dist) or 1.0
                                if dot > 0 then
                                    local los = true
                                    if core.line_of_sight then
                                        los = core.line_of_sight(eye_pos, target_pos)
                                    end
                                    if los then
                                        local ent_key = 'ent_' .. tostring(obj)
                                        table.insert(candidates, {
                                            key = ent_key,
                                            pos = target_pos,
                                            dist = dist,
                                            is_entity = true,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 3. Sort in-sight targets by distance ascending and keep top max_waypoints
    table.sort(candidates, function(a, b)
        return a.dist < b.dist
    end)

    local active_keys = {}
    local count = math.min(#candidates, max_waypoints)

    state.marker_waypoints = state.marker_waypoints or {}

    local min_op = waysigns.settings.marker_sense_min_opacity or 75
    local max_op = math.max(min_op, waysigns.settings.marker_sense_max_opacity or 255)

    for i = 1, count do
        local cand = candidates[i]
        active_keys[cand.key] = true

        -- Distance-based opacity progression: close markers have lower translucency (more opaque) and further away markers are progressively more translucent (lower opacity)
        local norm_dist = math.min(1.0, math.max(0.0, (cand.dist - 1.0) / math.max(1.0, sense_range - 1.0)))
        local raw_opacity = math.floor(max_op - norm_dist * (max_op - min_op))
        -- Quantize opacity into steps of 15 to prevent sending redundant network updates
        local opacity = math.min(255, math.max(0, math.floor(raw_opacity / 15) * 15))
        local marker_tex = string.format('waysigns_marker.png^[resize:24x24^[opacity:%d', opacity)

        local existing = state.marker_waypoints[cand.key]
        if existing then
            if not vector.equals(existing.pos, cand.pos) then
                player:hud_change(existing.hud_id, 'world_pos', cand.pos)
                existing.pos = cand.pos
            end
            if existing.opacity ~= opacity then
                player:hud_change(existing.hud_id, 'text', marker_tex)
                existing.opacity = opacity
            end
        else
            local hud_id = player:hud_add({
                type = 'image_waypoint',
                world_pos = cand.pos,
                scale = { x = 1, y = 1 },
                text = marker_tex,
                alignment = { x = 0, y = 0 },
                offset = { x = 0, y = 0 },
                z_index = -250,
            })
            state.marker_waypoints[cand.key] = {
                hud_id = hud_id,
                pos = cand.pos,
                opacity = opacity,
                is_entity = cand.is_entity,
            }
        end
    end

    -- 4. Remove waypoints that are no longer active (e.g. turned out of sight or exceeded cap)
    for k, wp in pairs(state.marker_waypoints) do
        if not active_keys[k] then
            if wp.hud_id then
                player:hud_remove(wp.hud_id)
            end
            state.marker_waypoints[k] = nil
        end
    end
end

---Main player update tick: raycasts signs, checks distances, and drives smooth animations
---@param player ObjectRef Connected player to update
---@param dtime number Delta time in seconds since last tick
function waysigns.update_player(player, dtime)
    -- Short-circuit update loop when player is dead: eliminate raycasting, node lookups, and HUD rendering
    if waysigns.is_player_dead(player) then
        local name = player:get_player_name()
        local state = name and waysigns.players[name]
        if state then
            if state.is_visible or state.hud_bg_id or (state.opacity and state.opacity > 0) then
                waysigns.remove_all_huds(player)
            end
            waysigns.remove_marker_waypoints(player, state)
            state.check_timer = 0
            state.page_timer = 0
            state.marker_sense_timer = 0
        end
        return
    end

    local state = waysigns.get_or_create_player_state(player)

    state.check_timer = state.check_timer + dtime

    -- 1. Raycast detection (throttled at check_interval for multiplayer performance)
    if state.check_timer >= waysigns.settings.check_interval then
        state.check_timer = 0

        local eye_height = state.eye_height or (player.get_properties and player:get_properties().eye_height) or 1.625
        local player_pos = player:get_pos()
        if not player_pos then
            return
        end

        local eye_pos = state.scratch_eye_pos or { x = 0, y = 0, z = 0 }
        state.scratch_eye_pos = eye_pos
        eye_pos.x = player_pos.x
        eye_pos.y = player_pos.y + eye_height
        eye_pos.z = player_pos.z

        local look_dir = player:get_look_dir()
        local max_dist = waysigns.settings.max_distance
        local ray_end = state.scratch_ray_end or { x = 0, y = 0, z = 0 }
        state.scratch_ray_end = ray_end
        ray_end.x = eye_pos.x + look_dir.x * max_dist
        ray_end.y = eye_pos.y + look_dir.y * max_dist
        ray_end.z = eye_pos.z + look_dir.z * max_dist

        local pointed_sign_pos = nil
        local pointed_sign_normal = nil
        local pointed_sign_data = nil
        local pointed_intersection = nil
        local pointed_is_attached = false

        local enable_objects = waysigns.settings.enable_entity_inspection
        local ray = core.raycast(eye_pos, ray_end, enable_objects, false)
        for pt in ray do
            if pt.type == 'object' then
                local obj = pt.ref
                if obj and (not obj.is_player or not obj:is_player()) then
                    local ent_data = waysigns.get_entity_inscription_data and waysigns.get_entity_inscription_data(obj)
                    if ent_data then
                        pointed_sign_pos = ent_data.pos
                        pointed_sign_normal = pt.intersection_normal or vector.direction(eye_pos, ent_data.pos)
                        pointed_sign_data = ent_data
                        pointed_intersection = pt.intersection_point or ent_data.pos
                        pointed_is_attached = false
                        break
                    end
                end
            elseif pt.type == 'node' then
                local node = core.get_node_or_nil(pt.under)
                if node and node.name ~= 'air' and node.name ~= 'ignore' then
                    local data = waysigns.get_sign_data(pt.under, node)
                    if data then
                        if waysigns.is_pointing_front_face(node, pt.intersection_normal, look_dir) then
                            pointed_sign_pos = pt.under
                            pointed_sign_normal = pt.intersection_normal or waysigns.DEFAULT_NORMAL
                            pointed_sign_data = data
                            pointed_intersection = pt.intersection_point
                            pointed_is_attached = false
                        end
                        break
                    end

                    -- Check if pt.above is a sign attached to this surface
                    if pt.above then
                        local above_node = core.get_node_or_nil(pt.above)
                        if above_node and above_node.name ~= 'air' and above_node.name ~= 'ignore' then
                            local above_data = waysigns.get_sign_data(pt.above, above_node)
                            if above_data then
                                if waysigns.is_pointing_front_face(above_node, pt.intersection_normal, look_dir) then
                                    pointed_sign_pos = pt.above
                                    pointed_sign_normal = pt.intersection_normal or waysigns.DEFAULT_NORMAL
                                    pointed_sign_data = above_data
                                    pointed_intersection = pt.intersection_point
                                    pointed_is_attached = true
                                    break
                                end
                            end
                        end
                    end

                    -- If not a sign, check if node has infotext
                    if waysigns.settings.enable_node_infotext and waysigns.get_node_infotext_data then
                        local info_data = waysigns.get_node_infotext_data(pt.under, node, player)
                        if info_data then
                            pointed_sign_pos = pt.under
                            pointed_sign_normal = pt.intersection_normal or waysigns.DEFAULT_NORMAL
                            pointed_sign_data = info_data
                            pointed_intersection = pt.intersection_point
                            pointed_is_attached = false
                            break
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
            if waysigns.settings.disable_sign_entities and waysigns.purge_sign_entities and not pointed_sign_data.is_infotext then
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

    -- 4. Marker Sense: Proximity waypoints when wielding waysigns:marker
    if waysigns.settings.marker_sense then
        state.marker_sense_timer = (state.marker_sense_timer or 0) + dtime
        local interval = math.min(0.15, waysigns.settings.check_interval or 0.10)
        if state.marker_sense_timer >= interval then
            state.marker_sense_timer = 0
            local wielded_item = player.get_wielded_item and player:get_wielded_item()
            local item_name = wielded_item and wielded_item:get_name()
            if item_name == 'waysigns:marker' then
                waysigns.update_marker_waypoints(player, state)
            elseif state.marker_waypoints and next(state.marker_waypoints) then
                waysigns.remove_marker_waypoints(player, state)
            end
        end
    elseif state.marker_waypoints and next(state.marker_waypoints) then
        waysigns.remove_marker_waypoints(player, state)
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
    local name = player:get_player_name()
    local state = name and waysigns.players[name]
    if state then
        waysigns.remove_marker_waypoints(player, state)
    end
    waysigns.remove_all_huds(player)
    waysigns.players[name] = nil
end

---Clean up player HUD elements when a player dies
---@param player ObjectRef Deceased player reference
function waysigns.on_dieplayer(player)
    waysigns.remove_all_huds(player)
    local name = player and player:get_player_name()
    local state = name and waysigns.players[name]
    if state then
        waysigns.remove_marker_waypoints(player, state)
        state.check_timer = 0
        state.page_timer = 0
        state.marker_sense_timer = 0
    end
end

---Write or update an inscription on a node's metadata
---@param pos Vector Node position
---@param text string Inscription text (empty string to clear)
---@param plaque string|nil Plaque style ('wood', 'steel', 'slate', 'gold', 'glass', 'default')
---@param color string|nil Inscription text color name ('white', 'gold', 'cyan', 'green', 'red', 'dark')
---@param player_name string|nil Name of modifying player for attribution
---@return boolean success True if inscription was written
function waysigns.set_node_inscription(pos, text, plaque, color, player_name)
    if not pos then return false end
    local meta = core.get_meta(pos)
    if not meta then return false end
    if not text or text == '' then
        meta:set_string('waysigns_text', '')
        meta:set_string('waysigns_plaque', '')
        meta:set_string('waysigns_color', '')
        meta:set_string('waysigns_author', '')
        waysigns.unregister_inscribed_pos(pos)
    else
        meta:set_string('waysigns_text', text)
        meta:set_string('waysigns_plaque', plaque or 'default')
        meta:set_string('waysigns_color', color or 'white')
        if player_name and player_name ~= '' then
            meta:set_string('waysigns_author', player_name)
        end
        waysigns.register_inscribed_pos(pos, {
            author = player_name or '',
            plaque = plaque or 'default',
            color = color or 'white',
        })
    end
    waysigns.invalidate_cache(pos)
    return true
end

---Read active inscription from a node's metadata
---@param pos Vector Node position
---@return table|nil inscription Table with text, plaque, color, author, or nil if unassigned
function waysigns.get_node_inscription(pos)
    if not pos then return nil end
    local meta = core.get_meta(pos)
    if not meta then return nil end
    local text = meta:get_string('waysigns_text')
    if not text or text == '' then return nil end
    local plaque = meta:get_string('waysigns_plaque') or 'default'
    local color = meta:get_string('waysigns_color') or 'white'
    local author = meta:get_string('waysigns_author')
    if not waysigns.get_inscribed_pos(pos) then
        waysigns.register_inscribed_pos(pos, {
            author = author or '',
            plaque = plaque,
            color = color,
        })
    end
    return {
        text = text,
        plaque = plaque,
        color = color,
        author = author,
    }
end

---Write or update an inscription on an entity
---@param object ObjectRef Entity object reference
---@param text string Inscription text (empty string to clear)
---@param plaque string|nil Plaque style ('wood', 'steel', 'slate', 'gold', 'glass', 'default')
---@param color string|nil Inscription text color name
---@param player_name string|nil Name of modifying player
---@return boolean success True if inscription was updated
function waysigns.set_entity_inscription(object, text, plaque, color, player_name)
    if not object or not object.get_pos then return false end
    local lua_ent = object.get_luaentity and object:get_luaentity()
    local has_text = (text and text ~= '')
    if lua_ent then
        lua_ent._waysigns_text = has_text and text or nil
        lua_ent._waysigns_plaque = has_text and (plaque or 'default') or nil
        lua_ent._waysigns_color = has_text and (color or 'white') or nil
        lua_ent._waysigns_author = (has_text and player_name and player_name ~= '') and player_name or nil
    end
    rawset(object, '_waysigns_text', has_text and text or nil)
    rawset(object, '_waysigns_plaque', has_text and (plaque or 'default') or nil)
    rawset(object, '_waysigns_color', has_text and (color or 'white') or nil)
    rawset(object, '_waysigns_author', (has_text and player_name and player_name ~= '') and player_name or nil)

    if object.set_properties then
        object:set_properties({
            infotext = text or '',
        })
    end
    return true
end

---Read active inscription from an entity
---@param object ObjectRef Entity object reference
---@return table|nil inscription Table with text, plaque, color, author, or nil if unassigned
function waysigns.get_entity_inscription(object)
    if not object or not object.get_pos then return nil end
    local lua_ent = object.get_luaentity and object:get_luaentity()
    local text = (lua_ent and lua_ent._waysigns_text) or object._waysigns_text
    if not text or text == '' then
        local props = object.get_properties and object:get_properties()
        text = props and props.infotext
    end
    if not text or text == '' then return nil end
    return {
        text = text,
        plaque = (lua_ent and lua_ent._waysigns_plaque) or object._waysigns_plaque or 'default',
        color = (lua_ent and lua_ent._waysigns_color) or object._waysigns_color or 'white',
        author = (lua_ent and lua_ent._waysigns_author) or object._waysigns_author,
    }
end

-- Load persistent inscribed registry on startup
waysigns.load_inscribed_registry()

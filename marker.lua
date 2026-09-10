--[[
    WaySigns: High-performance sign reading & HUD waypoints for Luanti
    Copyright (C) 2026 Juraj Vajda

    This library is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation; either version 2.1 of the License, or
    (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, see <https://www.gnu.org/licenses/>.
--]]

local S = core.get_translator and core.get_translator(core.get_current_modname()) or function(s) return s end

local PLAQUE_OPTIONS = {
    { key = 'default', label = 'Default (Node Texture / Neutral)' },
    { key = 'wood', label = 'Wood Plaque' },
    { key = 'steel', label = 'Steel Plaque' },
    { key = 'slate', label = 'Dark Slate' },
    { key = 'gold', label = 'Gold / Brass' },
    { key = 'glass', label = 'Frosted Glass' },
}

local PLAQUE_TEXTURES = {
    wood = 'waysigns_sign_wood.png',
    steel = 'waysigns_sign_steel.png',
    slate = 'waysigns_sign_slate.png',
    gold = 'waysigns_sign_gold.png',
    glass = 'waysigns_sign_glass.png',
}

local COLOR_OPTIONS = {
    { key = 'white', label = 'Classic White' },
    { key = 'gold', label = 'Warm Gold' },
    { key = 'cyan', label = 'Cyan' },
    { key = 'green', label = 'Lime Green' },
    { key = 'red', label = 'Crimson Red' },
    { key = 'dark', label = 'Dark Walnut' },
}

local COLOR_HEXES = {
    white = '#FFFFFF',
    gold = '#FFD700',
    cyan = '#00E5FF',
    green = '#76FF03',
    red = '#FF5252',
    dark = '#222222',
}

---Get plaque texture for a given plaque key
---@param key string|nil Plaque key
---@param default_tile string|nil Optional default tile to display for 'default' key
---@return string texture
local function get_plaque_texture(key, default_tile)
    if key == 'default' or not key then
        return (default_tile and default_tile ~= '') and default_tile or 'waysigns_sign_slate.png'
    end
    return PLAQUE_TEXTURES[key] or 'waysigns_sign_wood.png'
end

---Get hex color code for a given color key
---@param key string|nil Color key
---@return string hex Hex color string
local function get_color_hex(key)
    return COLOR_HEXES[key] or '#FFFFFF'
end

---Apply color escape sequence to string using core.colorize or fallback
---@param hex string Hex color string
---@param text string Target text
---@return string colored_text
local function colorize_text(hex, text)
    if core.colorize then
        return core.colorize(hex, text)
    end
    return '\x1b(c@' .. hex .. ')' .. tostring(text or '') .. '\x1b(c@#ffffff)'
end

-- Per-player active target cache for formspec session tracking
local active_targets = {}

---Resolve index of plaque key in options list
---@param key string|nil Plaque key
---@return integer index 1-based index
local function get_plaque_index(key)
    if not key then return 1 end
    for idx, opt in ipairs(PLAQUE_OPTIONS) do
        if opt.key == key then
            return idx
        end
    end
    return 1
end

---Resolve index of color key in options list
---@param key string|nil Color key
---@return integer index 1-based index
local function get_color_index(key)
    if not key then return 1 end
    for idx, opt in ipairs(COLOR_OPTIONS) do
        if opt.key == key then
            return idx
        end
    end
    return 1
end

---Build dropdown item string from option tables
---@param options table[] Array of option tables with label field
---@return string dropdown_str Comma-separated labels
local function build_dropdown_string(options)
    local items = {}
    for _, opt in ipairs(options) do
        table.insert(items, core.formspec_escape(opt.label))
    end
    return table.concat(items, ',')
end

local plaque_dropdown_items = build_dropdown_string(PLAQUE_OPTIONS)
local color_dropdown_items = build_dropdown_string(COLOR_OPTIONS)

---Build modern inscription formspec string (formspec_version[6])
---@param target table Target tracking table (pos, title, text, plaque, color, default_tile)
---@return string formspec
local function build_inscription_formspec(target)
    local plaque_idx = get_plaque_index(target.plaque)
    local color_idx = get_color_index(target.color)
    local max_chars = waysigns.settings.marker_max_chars or 250
    local header_title = target.title or S('WaySigns Inscription')

    local parts = {
        'formspec_version[6]',
        'size[10.2,9.8]',
        'no_prepend[]',
        'bgcolor[#16181f;both;#00000000]',
        'box[0,0;10.2,9.8;#16181f]',

        -- Modern styled buttons and labels
        'style_type[button,button_exit;border=false;content_offset=0;font=bold]',
        'style_type[image_button;border=false;content_offset=0]',
        'style_type[label;font=bold]',
        'style[close_btn;bgcolor=#00000000;textcolor=#8e95a5;hovered_textcolor=#ff5252;border=false;font=bold;font_size=18]',
        'style[save;bgcolor=#2e7d32;textcolor=#ffffff;hovered_bgcolor=#388e3c;border=false;font=bold]',
        'style[erase;bgcolor=#4a1c1c;textcolor=#ffcdd2;hovered_bgcolor=#6b2626;border=false]',
        'style[cancel;bgcolor=#2c303c;textcolor=#cfd8dc;hovered_bgcolor=#3d4353;border=false]',

        -- Header Bar with WaySigns Stylus Icon and Close Button
        'box[0,0;10.2,0.95;#1b1f28]',
        'box[0,0.93;10.2,0.03;#ffd700]',
        'image[0.40,0.22;0.50,0.50;waysigns_marker.png]',
        'style[header_title;font=bold;font_size=16;textcolor=#ffd700]',
        'label[1.05,0.55;', core.formspec_escape(header_title), ']',
        'button_exit[9.40,0.20;0.55,0.55;close_btn;✕]',
        'tooltip[close_btn;', core.formspec_escape(S('Close')), ']',

        -- Inscription Textarea
        'label[0.50,1.35;', core.formspec_escape(S('Inscription Text (max @1 chars):', max_chars)), ']',
        'textarea[0.50,1.65;9.20,2.00;inscription;;', core.formspec_escape(target.text or ''), ']',

        -- Plaque Material Swatches Section
        'label[0.50,3.95;', core.formspec_escape(S('Plaque Material Style:')), ']',
    }

    local current_plaque = target.plaque or 'default'
    for idx, opt in ipairs(PLAQUE_OPTIONS) do
        local swatch_x = 0.50 + (idx - 1) * 1.18
        local swatch_y = 4.30
        local tex = get_plaque_texture(opt.key, target.default_tile)

        -- Visual active halo border around the selected plaque
        if opt.key == current_plaque then
            table.insert(parts, string.format('box[%.2f,%.2f;1.10,1.10;#ffd700]', swatch_x - 0.05, swatch_y - 0.05))
        else
            table.insert(parts, string.format('box[%.2f,%.2f;1.06,1.06;#2a2e39]', swatch_x - 0.03, swatch_y - 0.03))
        end

        table.insert(parts, string.format('image_button[%.2f,%.2f;1.00,1.00;%s;plaque_sel_%s;]',
            swatch_x, swatch_y, tex, opt.key))
        table.insert(parts, string.format('tooltip[plaque_sel_%s;%s]',
            opt.key, core.formspec_escape(opt.label)))
    end

    -- Dropdown alongside swatches
    table.insert(parts, string.format('dropdown[7.65,4.40;2.05,0.80;plaque;%s;%d]',
        plaque_dropdown_items, plaque_idx))
    table.insert(parts, string.format('tooltip[plaque;%s]', core.formspec_escape(S('Select Plaque Material'))))

    -- Left: Text Color
    table.insert(parts, 'label[0.50,5.65;' .. core.formspec_escape(S('Text Color:')) .. ']')
    table.insert(parts, string.format('dropdown[0.50,6.05;3.20,0.80;color;%s;%d]',
        color_dropdown_items, color_idx))
    table.insert(parts, string.format('tooltip[color;%s]', core.formspec_escape(S('Select Text Color'))))

    -- Right: Live Waypoint Plaque Preview Card
    table.insert(parts, 'label[4.10,5.65;' .. core.formspec_escape(S('Live Plaque Preview:')) .. ']')
    table.insert(parts, 'box[4.10,6.05;5.60,2.15;#14171f]')

    local preview_tile = get_plaque_texture(target.plaque, target.default_tile)
    table.insert(parts, string.format('image[4.20,6.15;5.40,1.95;%s]', preview_tile))

    local color_hex = get_color_hex(target.color)
    local preview_raw = target.text
    if not preview_raw or preview_raw:gsub('%s+', '') == '' then
        preview_raw = 'WaySigns Inscription'
    else
        preview_raw = preview_raw:gsub('[\r\n].*$', '')
        if #preview_raw > 28 then
            preview_raw = preview_raw:sub(1, 25) .. '...'
        end
    end
    local colored_preview = colorize_text(color_hex, preview_raw)
    local subtitle = colorize_text('#8e95a5', S('(HUD Waypoint Preview)'))

    table.insert(parts, 'label[4.40,6.85;' .. core.formspec_escape(colored_preview) .. ']')
    table.insert(parts, 'label[4.40,7.40;' .. core.formspec_escape(subtitle) .. ']')

    -- Footer Separator & Action Buttons
    table.insert(parts, 'box[0,8.45;10.20,0.02;#2e3442]')
    table.insert(parts, 'button[0.50,8.70;3.00,0.80;save;' .. core.formspec_escape(S('Save Inscription')) .. ']')
    table.insert(parts, 'tooltip[save;' .. core.formspec_escape(S('Save inscription and plaque style')) .. ']')

    table.insert(parts, 'button[3.80,8.70;2.40,0.80;erase;' .. core.formspec_escape(S('Erase')) .. ']')
    table.insert(parts, 'tooltip[erase;' .. core.formspec_escape(S('Clear existing inscription')) .. ']')

    table.insert(parts, 'button_exit[7.30,8.70;2.40,0.80;cancel;' .. core.formspec_escape(S('Cancel')) .. ']')
    table.insert(parts, 'tooltip[cancel;' .. core.formspec_escape(S('Discard changes and close')) .. ']')

    return table.concat(parts)
end

---Show inscription editor formspec to player
---@param player ObjectRef Target player
---@param target table Target context table
function waysigns.show_inscription_formspec(player, target)
    local player_name = player:get_player_name()
    local formspec = build_inscription_formspec(target)
    core.show_formspec(player_name, 'waysigns:inscribe', formspec)
end

---Show node inscription editor formspec to player
---@param player ObjectRef Target player
---@param pos Vector Integer coordinate of node
function waysigns.show_node_inscription_formspec(player, pos)
    local player_name = player:get_player_name()
    local node = core.get_node(pos)
    local node_def = core.registered_nodes[node.name] or {}
    local desc = node_def.description or node.name

    -- Strip extra escape sequences or lines from node description
    desc = waysigns.strip_all_escapes(desc):gsub('[\r\n].*$', '')

    local current = waysigns.get_node_inscription(pos) or {}
    local default_tile = 'waysigns_sign_slate.png'
    if node_def.tiles then
        local t = node_def.tiles[1]
        if type(t) == 'string' then
            default_tile = t
        elseif type(t) == 'table' and t.name then
            default_tile = t.name
        end
    end

    active_targets[player_name] = {
        type = 'node',
        pos = pos,
        title = S('Inscribe Node: @1', desc),
        text = current.text or '',
        plaque = current.plaque or 'default',
        color = current.color or 'white',
        default_tile = default_tile,
    }

    waysigns.show_inscription_formspec(player, active_targets[player_name])
end

---Show entity inscription editor formspec to player
---@param player ObjectRef Target player
---@param object ObjectRef Target entity object
function waysigns.show_entity_inscription_formspec(player, object)
    local player_name = player:get_player_name()
    local lua_ent = object.get_luaentity and object:get_luaentity()
    local name = (lua_ent and lua_ent.name) or 'Entity'

    local current = waysigns.get_entity_inscription(object) or {}

    active_targets[player_name] = {
        type = 'entity',
        object = object,
        title = S('Inscribe Entity: @1', name),
        text = current.text or '',
        plaque = current.plaque or 'default',
        color = current.color or 'white',
        default_tile = 'waysigns_sign_slate.png',
    }

    waysigns.show_inscription_formspec(player, active_targets[player_name])
end

---Handle right-click or use with waysigns:marker tool
---@param itemstack ItemStack Wielded marker itemstack
---@param user ObjectRef Player using the marker
---@param pointed_thing PointedThing Target pointed node or object
---@return ItemStack itemstack Returned itemstack with wear applied
function waysigns.on_use_marker(itemstack, user, pointed_thing)
    if not user or not user.is_player or not user:is_player() then
        return itemstack
    end

    if not waysigns.settings.enable_marker then
        return itemstack
    end

    local player_name = user:get_player_name()

    if pointed_thing.type == 'node' then
        local pos = pointed_thing.under
        if not pos then
            return itemstack
        end

        if core.is_protected(pos, player_name) and not core.check_player_privs(user, 'protection_bypass') then
            core.record_protection_violation(pos, player_name)
            core.chat_send_player(player_name, S('[WaySigns] This area is protected.'))
            return itemstack
        end

        waysigns.show_node_inscription_formspec(user, pos)
        return itemstack
    elseif pointed_thing.type == 'object' then
        if not waysigns.settings.enable_entity_inspection then
            return itemstack
        end

        local obj = pointed_thing.ref
        if not obj or not obj.is_valid or not obj:is_valid() or (obj.is_player and obj:is_player()) then
            return itemstack
        end

        local pos = obj:get_pos()
        if pos and core.is_protected(pos, player_name) and not core.check_player_privs(user, 'protection_bypass') then
            core.record_protection_violation(pos, player_name)
            core.chat_send_player(player_name, S('[WaySigns] This area is protected.'))
            return itemstack
        end

        waysigns.show_entity_inscription_formspec(user, obj)
        return itemstack
    end

    return itemstack
end

---Register tool definition for waysigns:marker
core.register_tool('waysigns:marker', {
    description = S('WaySigns Inscription Marker'),
    short_description = S('WaySigns Inscription Marker'),
    inventory_image = 'waysigns_marker.png',
    wield_image = 'waysigns_marker.png',
    stack_max = 1,
    groups = { tool = 1 },
    on_place = function(itemstack, user, pointed_thing)
        return waysigns.on_use_marker(itemstack, user, pointed_thing)
    end,
    on_use = function(itemstack, user, pointed_thing)
        return waysigns.on_use_marker(itemstack, user, pointed_thing)
    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        return waysigns.on_use_marker(itemstack, user, pointed_thing)
    end,
})

---Receive and process submitted fields from inscription editor formspec
core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= 'waysigns:inscribe' or not player or not player.is_player or not player:is_player() then
        return
    end

    local player_name = player:get_player_name()
    local target = active_targets[player_name]
    if not target then
        return
    end

    -- Close on top-right 'X' button, Cancel button, or ESC/quit (when not saving or erasing)
    if fields.close_btn or fields.cancel or (fields.quit and not fields.save and not fields.erase) then
        active_targets[player_name] = nil
        core.close_formspec(player_name, 'waysigns:inscribe')
        return
    end

    -- Handle plaque swatch thumbnail click
    for _, opt in ipairs(PLAQUE_OPTIONS) do
        if fields['plaque_sel_' .. opt.key] then
            target.plaque = opt.key
            if fields.inscription then
                target.text = fields.inscription
            end
            if fields.color then
                for _, c_opt in ipairs(COLOR_OPTIONS) do
                    if c_opt.label == fields.color or c_opt.key == fields.color then
                        target.color = c_opt.key
                        break
                    end
                end
            end
            waysigns.show_inscription_formspec(player, target)
            return
        end
    end

    if target.type == 'node' then
        local pos = target.pos
        if not pos then
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end

        if core.is_protected(pos, player_name) and not core.check_player_privs(player, 'protection_bypass') then
            core.record_protection_violation(pos, player_name)
            core.chat_send_player(player_name, S('[WaySigns] This area is protected.'))
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end

        if fields.erase then
            waysigns.set_node_inscription(pos, '', 'default', 'white', player_name)
            core.chat_send_player(player_name, S('[WaySigns] Inscription erased.'))
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end

        if fields.save then
            local raw_text = fields.inscription or ''
            local clean_text = waysigns.strip_all_escapes(raw_text)
            local max_chars = waysigns.settings.marker_max_chars or 250
            if #clean_text > max_chars then
                clean_text = clean_text:sub(1, max_chars)
            end

            -- Match plaque option: prefer selected swatch in target.plaque, or check dropdown
            local plaque_key = target.plaque or 'default'
            if fields.plaque then
                for _, opt in ipairs(PLAQUE_OPTIONS) do
                    if opt.label == fields.plaque or opt.key == fields.plaque then
                        plaque_key = opt.key
                        break
                    end
                end
            end

            -- Match color option
            local color_key = target.color or 'white'
            if fields.color then
                for _, opt in ipairs(COLOR_OPTIONS) do
                    if opt.label == fields.color or opt.key == fields.color then
                        color_key = opt.key
                        break
                    end
                end
            end

            waysigns.set_node_inscription(pos, clean_text, plaque_key, color_key, player_name)

            if core.sound_play then
                core.sound_play('default_place_node', { pos = pos, gain = 0.5 }, true)
            end

            -- Consume tool durability
            local wielded = player:get_wielded_item()
            if wielded and wielded:get_name() == 'waysigns:marker' then
                local max_uses = waysigns.settings.marker_uses or 100
                if max_uses > 0 then
                    if wielded.add_wear_by_uses then
                        wielded:add_wear_by_uses(max_uses)
                    else
                        wielded:add_wear(math.floor(65535 / max_uses))
                    end
                    if wielded:get_count() == 0 then
                        if core.sound_play then
                            core.sound_play('default_tool_breaks', { pos = pos, gain = 0.8 }, true)
                        end
                        core.chat_send_player(player_name, S('[WaySigns] Your marker wore out!'))
                    end
                    player:set_wielded_item(wielded)
                end
            end

            core.chat_send_player(player_name, S('[WaySigns] Inscription saved.'))
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end
    elseif target.type == 'entity' then
        local obj = target.object
        if not obj or not obj.is_valid or not obj:is_valid() then
            core.chat_send_player(player_name, S('[WaySigns] Target entity no longer exists.'))
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end

        local pos = obj:get_pos()
        if pos and core.is_protected(pos, player_name) and not core.check_player_privs(player, 'protection_bypass') then
            core.record_protection_violation(pos, player_name)
            core.chat_send_player(player_name, S('[WaySigns] This area is protected.'))
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end

        if fields.erase then
            waysigns.set_entity_inscription(obj, '', 'default', 'white', player_name)
            core.chat_send_player(player_name, S('[WaySigns] Inscription erased.'))
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end

        if fields.save then
            local raw_text = fields.inscription or ''
            local clean_text = waysigns.strip_all_escapes(raw_text)
            local max_chars = waysigns.settings.marker_max_chars or 250
            if #clean_text > max_chars then
                clean_text = clean_text:sub(1, max_chars)
            end

            local plaque_key = target.plaque or 'default'
            if fields.plaque then
                for _, opt in ipairs(PLAQUE_OPTIONS) do
                    if opt.label == fields.plaque or opt.key == fields.plaque then
                        plaque_key = opt.key
                        break
                    end
                end
            end

            local color_key = target.color or 'white'
            if fields.color then
                for _, opt in ipairs(COLOR_OPTIONS) do
                    if opt.label == fields.color or opt.key == fields.color then
                        color_key = opt.key
                        break
                    end
                end
            end

            waysigns.set_entity_inscription(obj, clean_text, plaque_key, color_key, player_name)

            if pos and core.sound_play then
                core.sound_play('default_place_node', { pos = pos, gain = 0.5 }, true)
            end

            -- Consume tool durability
            local wielded = player:get_wielded_item()
            if wielded and wielded:get_name() == 'waysigns:marker' then
                local max_uses = waysigns.settings.marker_uses or 100
                if max_uses > 0 then
                    if wielded.add_wear_by_uses then
                        wielded:add_wear_by_uses(max_uses)
                    else
                        wielded:add_wear(math.floor(65535 / max_uses))
                    end
                    if wielded:get_count() == 0 then
                        if pos and core.sound_play then
                            core.sound_play('default_tool_breaks', { pos = pos, gain = 0.8 }, true)
                        end
                        core.chat_send_player(player_name, S('[WaySigns] Your marker wore out!'))
                    end
                    player:set_wielded_item(wielded)
                end
            end

            core.chat_send_player(player_name, S('[WaySigns] Inscription saved.'))
            active_targets[player_name] = nil
            core.close_formspec(player_name, 'waysigns:inscribe')
            return
        end
    end
end)

-- Clean up active targets on player leave
core.register_on_leaveplayer(function(player)
    if player and player.get_player_name then
        active_targets[player:get_player_name()] = nil
    end
end)

---Unique non-conflicting shapeless craft recipe: coal lump + steel ingot + stick
if core.get_modpath('default') then
    core.register_craft({
        output = 'waysigns:marker',
        type = 'shapeless',
        recipe = {
            'default:coal_lump',
            'default:steel_ingot',
            'group:stick',
        },
    })
end

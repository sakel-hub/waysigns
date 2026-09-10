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

local COLOR_OPTIONS = {
    { key = 'white', label = 'Classic White' },
    { key = 'gold', label = 'Warm Gold' },
    { key = 'cyan', label = 'Cyan' },
    { key = 'green', label = 'Lime Green' },
    { key = 'red', label = 'Crimson Red' },
    { key = 'dark', label = 'Dark Walnut' },
}

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
    local current_text = current.text or ''
    local plaque_idx = get_plaque_index(current.plaque)
    local color_idx = get_color_index(current.color)

    active_targets[player_name] = {
        type = 'node',
        pos = pos,
    }

    local formspec = table.concat({
        'formspec_version[4]',
        'size[9,8.2]',
        'no_prepend[]',
        'style_type[button;border=true]',
        'label[0.6,0.8;', core.formspec_escape(S('Inscribe Node: @1', desc)), ']',
        'textarea[0.6,1.4;7.8,3.2;inscription;', core.formspec_escape(S('Inscription Text (max @1 chars):', waysigns.settings.marker_max_chars)), ';', core.formspec_escape(current_text), ']',
        'label[0.6,5.0;', core.formspec_escape(S('Plaque Material:')), ']',
        'dropdown[0.6,5.4;3.6,0.8;plaque;', plaque_dropdown_items, ';', plaque_idx, ']',
        'label[4.8,5.0;', core.formspec_escape(S('Text Color:')), ']',
        'dropdown[4.8,5.4;3.6,0.8;color;', color_dropdown_items, ';', color_idx, ']',
        'button[0.6,6.8;2.8,0.9;save;', core.formspec_escape(S('Save Inscription')), ']',
        'button[3.6,6.8;2.4,0.9;erase;', core.formspec_escape(S('Erase')), ']',
        'button[6.2,6.8;2.2,0.9;cancel;', core.formspec_escape(S('Cancel')), ']',
    })

    core.show_formspec(player_name, 'waysigns:inscribe', formspec)
end

---Show entity inscription editor formspec to player
---@param player ObjectRef Target player
---@param object ObjectRef Target entity object
function waysigns.show_entity_inscription_formspec(player, object)
    local player_name = player:get_player_name()
    local lua_ent = object.get_luaentity and object:get_luaentity()
    local name = (lua_ent and lua_ent.name) or 'Entity'

    local current = waysigns.get_entity_inscription(object) or {}
    local current_text = current.text or ''
    local plaque_idx = get_plaque_index(current.plaque)
    local color_idx = get_color_index(current.color)

    active_targets[player_name] = {
        type = 'entity',
        object = object,
    }

    local formspec = table.concat({
        'formspec_version[4]',
        'size[9,8.2]',
        'no_prepend[]',
        'style_type[button;border=true]',
        'label[0.6,0.8;', core.formspec_escape(S('Inscribe Entity: @1', name)), ']',
        'textarea[0.6,1.4;7.8,3.2;inscription;', core.formspec_escape(S('Inscription Text (max @1 chars):', waysigns.settings.marker_max_chars)), ';', core.formspec_escape(current_text), ']',
        'label[0.6,5.0;', core.formspec_escape(S('Plaque Material:')), ']',
        'dropdown[0.6,5.4;3.6,0.8;plaque;', plaque_dropdown_items, ';', plaque_idx, ']',
        'label[4.8,5.0;', core.formspec_escape(S('Text Color:')), ']',
        'dropdown[4.8,5.4;3.6,0.8;color;', color_dropdown_items, ';', color_idx, ']',
        'button[0.6,6.8;2.8,0.9;save;', core.formspec_escape(S('Save Inscription')), ']',
        'button[3.6,6.8;2.4,0.9;erase;', core.formspec_escape(S('Erase')), ']',
        'button[6.2,6.8;2.2,0.9;cancel;', core.formspec_escape(S('Cancel')), ']',
    })

    core.show_formspec(player_name, 'waysigns:inscribe', formspec)
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

    if fields.cancel or (fields.quit and not fields.save and not fields.erase) then
        active_targets[player_name] = nil
        return
    end

    if target.type == 'node' then
        local pos = target.pos
        if not pos then
            active_targets[player_name] = nil
            return
        end

        if core.is_protected(pos, player_name) and not core.check_player_privs(player, 'protection_bypass') then
            core.record_protection_violation(pos, player_name)
            core.chat_send_player(player_name, S('[WaySigns] This area is protected.'))
            active_targets[player_name] = nil
            return
        end

        if fields.erase then
            waysigns.set_node_inscription(pos, '', 'default', 'white', player_name)
            core.chat_send_player(player_name, S('[WaySigns] Inscription erased.'))
            active_targets[player_name] = nil
            return
        end

        if fields.save then
            local raw_text = fields.inscription or ''
            local clean_text = waysigns.strip_all_escapes(raw_text)
            local max_chars = waysigns.settings.marker_max_chars or 250
            if #clean_text > max_chars then
                clean_text = clean_text:sub(1, max_chars)
            end

            -- Match plaque option
            local plaque_key = 'default'
            if fields.plaque then
                for _, opt in ipairs(PLAQUE_OPTIONS) do
                    if opt.label == fields.plaque or opt.key == fields.plaque then
                        plaque_key = opt.key
                        break
                    end
                end
            end

            -- Match color option
            local color_key = 'white'
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
            return
        end
    elseif target.type == 'entity' then
        local obj = target.object
        if not obj or not obj.is_valid or not obj:is_valid() then
            core.chat_send_player(player_name, S('[WaySigns] Target entity no longer exists.'))
            active_targets[player_name] = nil
            return
        end

        local pos = obj:get_pos()
        if pos and core.is_protected(pos, player_name) and not core.check_player_privs(player, 'protection_bypass') then
            core.record_protection_violation(pos, player_name)
            core.chat_send_player(player_name, S('[WaySigns] This area is protected.'))
            active_targets[player_name] = nil
            return
        end

        if fields.erase then
            waysigns.set_entity_inscription(obj, '', 'default', 'white', player_name)
            core.chat_send_player(player_name, S('[WaySigns] Inscription erased.'))
            active_targets[player_name] = nil
            return
        end

        if fields.save then
            local raw_text = fields.inscription or ''
            local clean_text = waysigns.strip_all_escapes(raw_text)
            local max_chars = waysigns.settings.marker_max_chars or 250
            if #clean_text > max_chars then
                clean_text = clean_text:sub(1, max_chars)
            end

            local plaque_key = 'default'
            if fields.plaque then
                for _, opt in ipairs(PLAQUE_OPTIONS) do
                    if opt.label == fields.plaque or opt.key == fields.plaque then
                        plaque_key = opt.key
                        break
                    end
                end
            end

            local color_key = 'white'
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

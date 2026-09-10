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

local modpath = core.get_modpath(core.get_current_modname())

dofile(modpath .. '/api.lua')
dofile(modpath .. '/compat.lua')
dofile(modpath .. '/marker.lua')

-- Main globalstep loop for player updates
core.register_globalstep(waysigns.globalstep)

-- Player lifecycle listeners
core.register_on_joinplayer(waysigns.on_joinplayer)
core.register_on_leaveplayer(waysigns.on_leaveplayer)
core.register_on_dieplayer(waysigns.on_dieplayer)

-- Cache invalidation hooks on sign modification or destruction
core.register_on_punchnode(waysigns.invalidate_cache)
core.register_on_dignode(waysigns.on_dignode)
core.register_on_placenode(waysigns.invalidate_cache)


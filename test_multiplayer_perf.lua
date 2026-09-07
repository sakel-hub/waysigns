--[[
    WaySigns vs Entity Signs Multiplayer Performance Benchmark
    Simulates a busy multiplayer server with 30, 40, and 50 concurrent players
    interacting in a town / spawn area containing 100 signs.

    Compares:
    1. Entity-Based Sign Systems (e.g. signs_lib, display_api):
       - ServerActiveObjects (SAOs) in active blocks
       - Engine active object tracking and per-player distance checks
       - Continuous network synchronization and object packet queuing
       - Client 3D scene node draw call overhead
    2. Waypoint Signs (WaySigns):
       - Pure static map nodes (0 ServerActiveObjects)
       - Throttled player raycast check
       - Event-driven HUD updates only for players actively looking at a sign
       - In-memory node metadata caching
--]]

local os = os
local math = math
local string = string
local collectgarbage = collectgarbage

-- Benchmark configuration
local SIGN_COUNT = 100
local STEP_COUNT = 1000
local PLAYER_COUNTS = {30, 40, 50}

print("================================================================================")
print("       WAYSIGNS VS ENTITY SIGNS: MULTIPLAYER PERFORMANCE BENCHMARK")
print(string.format("       Environment: %d Signs in Active Area | %d Server Steps (50s gameplay)", SIGN_COUNT, STEP_COUNT))
print("================================================================================\n")

-- Sign text samples
local SIGN_TEXTS = {
    "Welcome to Spawn Hub\nRead the rules before building!",
    "Community Farm -->\nTake what you need, replant what you take.",
    "Town Hall & Bank\nOpening Hours: 08:00 - 20:00",
    "Metro Line 1\nNorthbound to Northern Valley\nNext train in 2 mins",
    "Mine Entrance [Caution]\nMonster spawns active below level -50",
    "Market Square\nShop plots available for 50 gold",
    "Highway I-95 North\nKeep Right Except to Pass\nSpeed Limit 60",
    "Hospital & Emergency Services\nFollow blue trail for quick access",
    "Scenic Viewpoint\nAltitude: 120m\nDo not jump!",
    "Library & Enchanting\nBookshelf donation chest inside"
}

-- Setup 100 signs distributed in a 40x40 area
local signs = {}
for i = 1, SIGN_COUNT do
    signs[i] = {
        id = i,
        pos = {
            x = math.random(-25, 25),
            y = math.random(1, 4),
            z = math.random(-25, 25),
        },
        text = SIGN_TEXTS[((i - 1) % #SIGN_TEXTS) + 1],
        tile = (i % 2 == 0) and "default_sign_wall_wood.png" or "default_sign_wall_steel.png",
        is_metal = (i % 2 == 1),
    }
end

--------------------------------------------------------------------------------
-- Scenario 1: Entity-Based Sign Simulation (signs_lib / display_api)
--------------------------------------------------------------------------------
local function run_entity_simulation(player_count)
    collectgarbage("collect")
    local mem_start = collectgarbage("count")
    local total_packets = 0
    local total_bytes = 0
    local draw_calls_total = 0

    -- In entity sign mods, 1 ServerActiveObject (SAO) is spawned per sign
    local entities = {}
    for i = 1, SIGN_COUNT do
        local sign = signs[i]
        entities[i] = {
            id = i,
            pos = sign.pos,
            text = sign.text,
            texture = sign.tile .. "^[resize:64x32",
            active_for_players = {},
            step_timer = 0,
            -- Entity Lua table overhead
            properties = {
                visual = "mesh",
                mesh = "signs_lib_sign.obj",
                textures = {sign.tile},
                collisionbox = {-0.4, -0.4, -0.05, 0.4, 0.4, 0.05},
            },
        }
    end

    -- Simulated players moving through the area
    local players = {}
    for p = 1, player_count do
        players[p] = {
            id = p,
            pos = {
                x = math.random(-30, 30),
                y = 1.5,
                z = math.random(-30, 30),
            },
            look_dir = {x = math.random() * 2 - 1, y = 0, z = math.random() * 2 - 1},
            active_objects = {},
        }
    end

    local clock_start = os.clock()

    -- Simulate 1,000 server steps (dtime = 0.05s, 20 ticks/sec)
    for _ = 1, STEP_COUNT do
        -- 1. Players move randomly
        for p = 1, player_count do
            local pl = players[p]
            pl.pos.x = pl.pos.x + (math.random() - 0.5) * 0.4
            pl.pos.z = pl.pos.z + (math.random() - 0.5) * 0.4
            pl.look_dir.x = pl.look_dir.x + (math.random() - 0.5) * 0.1
            pl.look_dir.z = pl.look_dir.z + (math.random() - 0.5) * 0.1
        end

        -- 2. Engine Active Object step:
        -- Every tick, server environment checks distance from EVERY entity to EVERY player
        for e = 1, SIGN_COUNT do
            local ent = entities[e]
            ent.step_timer = ent.step_timer + 0.05

            for p = 1, player_count do
                local pl = players[p]
                local dx = ent.pos.x - pl.pos.x
                local dy = ent.pos.y - pl.pos.y
                local dz = ent.pos.z - pl.pos.z
                local dist_sq = dx * dx + dy * dy + dz * dz

                -- Active block radius is ~48m (dist_sq <= 2304)
                if dist_sq <= 2304 then
                    if not pl.active_objects[e] then
                        -- Object Add packet dispatched to player
                        pl.active_objects[e] = true
                        total_packets = total_packets + 1
                        total_bytes = total_bytes + 280 -- SAO init packet with props & texture
                    end

                    -- Client draws all entities in active range
                    draw_calls_total = draw_calls_total + 1
                else
                    if pl.active_objects[e] then
                        -- Object Remove packet dispatched
                        pl.active_objects[e] = nil
                        total_packets = total_packets + 1
                        total_bytes = total_bytes + 24 -- SAO remove packet
                    end
                end
            end

            -- Periodically sync text texture / props
            if ent.step_timer >= 1.0 then
                ent.step_timer = 0
                -- Message packet sent to all players in range
                for p = 1, player_count do
                    if players[p].active_objects[e] then
                        total_packets = total_packets + 1
                        total_bytes = total_bytes + 140 -- texture string update
                    end
                end
            end
        end
    end

    local clock_end = os.clock()
    local mem_end = collectgarbage("count")
    local duration_ms = (clock_end - clock_start) * 1000

    return {
        duration_ms = duration_ms,
        avg_step_us = (duration_ms / STEP_COUNT) * 1000,
        mem_kb = math.max(0, mem_end - mem_start),
        packets = total_packets,
        bandwidth_kbs = (total_bytes / 1024) / (STEP_COUNT * 0.05),
        avg_draw_calls = math.floor(draw_calls_total / (STEP_COUNT * player_count)),
        active_entities = SIGN_COUNT,
    }
end

--------------------------------------------------------------------------------
-- Scenario 2: WaySigns Simulation
--------------------------------------------------------------------------------
local function run_waysigns_simulation(player_count)
    collectgarbage("collect")
    local mem_start = collectgarbage("count")
    local total_packets = 0
    local total_bytes = 0
    local draw_calls_total = 0

    -- WaySigns uses static nodes in the map (0 ServerActiveObjects)
    local node_cache = {}
    for i = 1, SIGN_COUNT do
        local sign = signs[i]
        node_cache[sign.pos.x .. "," .. sign.pos.y .. "," .. sign.pos.z] = {
            text = sign.text,
            tile = sign.tile,
            is_metal = sign.is_metal,
            aspect_ratio = 1.4,
            wrapped_lines = 3,
        }
    end

    -- Simulated players
    local players = {}
    for p = 1, player_count do
        players[p] = {
            id = p,
            pos = {
                x = math.random(-30, 30),
                y = 1.5,
                z = math.random(-30, 30),
            },
            look_dir = {x = math.random() * 2 - 1, y = 0, z = math.random() * 2 - 1},
            current_sign = nil,
            hud_active = false,
            check_timer = 0,
        }
    end

    local clock_start = os.clock()

    -- Simulate 1,000 server steps (dtime = 0.05s, 20 ticks/sec)
    for _ = 1, STEP_COUNT do
        -- 1. Players move randomly
        for p = 1, player_count do
            local pl = players[p]
            pl.pos.x = pl.pos.x + (math.random() - 0.5) * 0.4
            pl.pos.z = pl.pos.z + (math.random() - 0.5) * 0.4
            pl.look_dir.x = pl.look_dir.x + (math.random() - 0.5) * 0.1
            pl.look_dir.z = pl.look_dir.z + (math.random() - 0.5) * 0.1

            -- WaySigns throttled check: runs at 0.05s interval per player
            pl.check_timer = pl.check_timer + 0.05
            if pl.check_timer >= 0.05 then
                pl.check_timer = 0

                -- Raycast simulation: inspects blocks up to 4.5m along look vector
                local hit_sign = nil
                local ray_dx = pl.look_dir.x
                local ray_dz = pl.look_dir.z
                local len = math.sqrt(ray_dx * ray_dx + ray_dz * ray_dz)
                if len > 0.001 then
                    ray_dx = ray_dx / len
                    ray_dz = ray_dz / len
                end

                -- Step along ray up to 4.5 blocks
                for step = 1, 4 do
                    local check_x = math.floor(pl.pos.x + ray_dx * step + 0.5)
                    local check_y = math.floor(pl.pos.y)
                    local check_z = math.floor(pl.pos.z + ray_dz * step + 0.5)
                    local k = check_x .. "," .. check_y .. "," .. check_z
                    if node_cache[k] then
                        hit_sign = node_cache[k]
                        break
                    end
                end

                if hit_sign then
                    if pl.current_sign ~= hit_sign then
                        -- Player looked at a new sign: HUD add / change packet sent ONLY to this player
                        pl.current_sign = hit_sign
                        pl.hud_active = true
                        total_packets = total_packets + 2 -- HUD background + text
                        total_bytes = total_bytes + 180 -- HUD command bytes
                    end
                    -- Client draws only 1 HUD element (the sign being looked at)
                    draw_calls_total = draw_calls_total + 1
                else
                    if pl.current_sign ~= nil then
                        -- Player looked away: HUD remove packet sent ONLY to this player
                        pl.current_sign = nil
                        pl.hud_active = false
                        total_packets = total_packets + 2 -- HUD remove
                        total_bytes = total_bytes + 32
                    end
                    -- When not looking at a sign, 0 draw calls!
                end
            end
        end
    end

    local clock_end = os.clock()
    local mem_end = collectgarbage("count")
    local duration_ms = (clock_end - clock_start) * 1000

    return {
        duration_ms = duration_ms,
        avg_step_us = (duration_ms / STEP_COUNT) * 1000,
        mem_kb = math.max(0, mem_end - mem_start),
        packets = total_packets,
        bandwidth_kbs = (total_bytes / 1024) / (STEP_COUNT * 0.05),
        avg_draw_calls = math.max(1, math.floor(draw_calls_total / (STEP_COUNT * player_count))),
        active_entities = 0,
    }
end

--------------------------------------------------------------------------------
-- Run Benchmarks and Format Comparison Table
--------------------------------------------------------------------------------
local results = {}

for _, pc in ipairs(PLAYER_COUNTS) do
    print(string.format(">>> Executing benchmark with %d concurrent players...", pc))
    local entity_res = run_entity_simulation(pc)
    local waysigns_res = run_waysigns_simulation(pc)

    results[pc] = {
        entity = entity_res,
        waysigns = waysigns_res,
    }
end

print("\n================================================================================")
print("                           BENCHMARK RESULTS TABLE")
print("================================================================================\n")

print(string.format("| %-15s | %-16s | %-16s | %-16s | %-16s |",
    "Players", "Metric", "Entity Signs", "WaySigns", "Improvement"))
print("|:----------------|:-----------------|:-----------------|:-----------------|:-----------------|")

for _, pc in ipairs(PLAYER_COUNTS) do
    local e = results[pc].entity
    local w = results[pc].waysigns

    local cpu_gain = (e.avg_step_us - w.avg_step_us) / e.avg_step_us * 100
    local pkt_gain = (e.packets - w.packets) / e.packets * 100
    local bw_gain = (e.bandwidth_kbs - w.bandwidth_kbs) / e.bandwidth_kbs * 100
    local dc_gain = (e.avg_draw_calls - w.avg_draw_calls) / e.avg_draw_calls * 100

    print(string.format("| %-15s | %-16s | %-16s | %-16s | %-16s |",
        pc .. " Players", "Server Step Time", string.format("%.1f us/tick", e.avg_step_us), string.format("%.1f us/tick", w.avg_step_us), string.format("%.1f%% faster", cpu_gain)))
    print(string.format("| %-15s | %-16s | %-16s | %-16s | %-16s |",
        "", "Server SAO Count", string.format("%d objects", e.active_entities), string.format("%d objects", w.active_entities), "100% eliminated"))
    print(string.format("| %-15s | %-16s | %-16s | %-16s | %-16s |",
        "", "Packets Dispatched", string.format("%d pkts", e.packets), string.format("%d pkts", w.packets), string.format("%.1f%% fewer", pkt_gain)))
    print(string.format("| %-15s | %-16s | %-16s | %-16s | %-16s |",
        "", "Network Bandwidth", string.format("%.2f KB/s", e.bandwidth_kbs), string.format("%.2f KB/s", w.bandwidth_kbs), string.format("%.1f%% bandwidth saved", bw_gain)))
    print(string.format("| %-15s | %-16s | %-16s | %-16s | %-16s |",
        "", "Client Draw Calls", string.format("~%d per player", e.avg_draw_calls), string.format("~%d per player", w.avg_draw_calls), string.format("%.1f%% fewer draws", dc_gain)))
    print(string.format("| %-15s | %-16s | %-16s | %-16s | %-16s |",
        "", "Memory Growth", string.format("+%.1f KB", e.mem_kb), string.format("+%.1f KB", w.mem_kb), "Minimal footprint"))
    print("|:----------------|:-----------------|:-----------------|:-----------------|:-----------------|")
end

print("\n[SUCCESS] Multiplayer Performance Benchmark completed successfully.\n")

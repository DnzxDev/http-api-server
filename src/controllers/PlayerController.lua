local CONFIG = require("config")
local Utils = require("utils")

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")

local PlayerController = {}

function PlayerController.getAllPlayers(req, res)
    if not Utils.isEndpointEnabled("players") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    local players = GetPlayers() or {}
    local playerData = {}
    local pending = #players

    Utils.log(string.format("Obtendo dados de %d jogadores online", #players))

    if pending == 0 then
        return Utils.sendResponse(res, 200, Utils.successResponse({
            count = 0,
            players = {}
        }))
    end

    local function trySend()
        if pending <= 0 then
            Utils.sendResponse(res, 200, Utils.successResponse({
                count = #playerData,
                players = playerData
            }))
        end
    end

    for _, source in ipairs(players) do
        local playerSource = tonumber(source)
        local passport = vRP.Passport(playerSource)

        if not passport then
            table.insert(playerData, {
                id = 0,
                name = { full = "Desconhecido" },
                status = { online = true, source = playerSource }
            })
            pending = pending - 1
            trySend()
        else
            exports.oxmysql:query(
                string.format("SELECT * FROM %s WHERE id = ? AND deleted = 0 LIMIT 1", CONFIG.database.characters_table),
                { passport },
                function(result)
                    local character = result and result[1]

                    if character then
                        table.insert(playerData, Utils.formatPlayerData(character, true, playerSource))
                    else
                        table.insert(playerData, {
                            id = passport,
                            name = { full = "Desconhecido" },
                            status = { online = true, source = playerSource }
                        })
                    end

                    pending = pending - 1
                    trySend()
                end
            )
        end
    end
end

function PlayerController.getActivePlayersCount(req, res)
    if not Utils.isEndpointEnabled("players_active") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    local players = GetPlayers() or {}
    local count = #players
    local maxPlayers = GetConvarInt("sv_maxclients", 32)
    
    Utils.sendResponse(res, 200, Utils.successResponse({
        active_players = count,
        max_players = maxPlayers,
        percentage = math.floor((count / maxPlayers) * 100)
    }))
end

function PlayerController.getPlayerStats(req, res)
    if not Utils.isEndpointEnabled("players_stats") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    local players = GetPlayers() or {}
    local activeCount = #players
    
    exports.oxmysql:query(string.format([[
        SELECT 
            COUNT(*) as total_registered,
            COUNT(CASE WHEN deleted = 0 THEN 1 END) as active_characters,
            COUNT(CASE WHEN deleted = 1 THEN 1 END) as deleted_characters,
            AVG(horas) as avg_hours,
            MAX(horas) as max_hours,
            SUM(horas) as total_hours,
            AVG(bank) as avg_bank,
            MAX(bank) as max_bank,
            SUM(bank) as total_economy,
            COUNT(CASE WHEN sex = 'M' THEN 1 END) as male_count,
            COUNT(CASE WHEN sex = 'F' THEN 1 END) as female_count,
            AVG(age) as avg_age
        FROM %s 
        WHERE deleted = 0
    ]], CONFIG.database.characters_table), {}, function(statsResult)
        
        exports.oxmysql:query(string.format([[
            SELECT kit, COUNT(*) as count 
            FROM %s 
            WHERE deleted = 0 AND kit IS NOT NULL 
            GROUP BY kit
        ]], CONFIG.database.characters_table), {}, function(kitResult)
            
            local stats = statsResult and statsResult[1] or {}
            local kitStats = {}
            
            if kitResult then
                for _, kit in ipairs(kitResult) do
                    kitStats[kit.kit] = kit.count
                end
            end
            
            Utils.sendResponse(res, 200, Utils.successResponse({
                server = {
                    active_players = activeCount,
                    max_players = GetConvarInt("sv_maxclients", 32),
                    uptime = GetGameTimer()
                },
                database = {
                    total_registered = stats.total_registered or 0,
                    active_characters = stats.active_characters or 0,
                    deleted_characters = stats.deleted_characters or 0
                },
                gameplay = {
                    total_hours_played = stats.total_hours or 0,
                    average_hours = math.floor((stats.avg_hours or 0) * 100) / 100,
                    max_hours = stats.max_hours or 0
                },
                economy = {
                    total_money = stats.total_economy or 0,
                    average_bank = math.floor((stats.avg_bank or 0) * 100) / 100,
                    max_bank = stats.max_bank or 0
                },
                demographics = {
                    male_players = stats.male_count or 0,
                    female_players = stats.female_count or 0,
                    average_age = math.floor((stats.avg_age or 0) * 100) / 100
                },
                kits = kitStats
            }))
        end)
    end)
end

function PlayerController.getPlayerById(req, res, playerId)
    if not Utils.isEndpointEnabled("players_by_id") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    local id = tonumber(playerId)
    if not id then
        return Utils.sendResponse(res, 400, Utils.errorResponse("ID inválido", "INVALID_ID"))
    end
    
    exports.oxmysql:query(
        string.format("SELECT * FROM %s WHERE id = ? LIMIT 1", CONFIG.database.characters_table),
        { id },
        function(result)
            if result and result[1] then
                local player = result[1]
                local isOnline = false
                local source = nil
                
                for _, playerSource in ipairs(GetPlayers()) do
                    local passport = vRP.Passport(tonumber(playerSource))
                    if passport == id then
                        isOnline = true
                        source = tonumber(playerSource)
                        break
                    end
                end
                
                Utils.sendResponse(res, 200, Utils.successResponse({
                    player = Utils.formatPlayerData(player, isOnline, source)
                }))
            else
                Utils.sendResponse(res, 404, Utils.errorResponse("Jogador não encontrado", "PLAYER_NOT_FOUND"))
            end
        end
    )
end

function PlayerController.getTopPlayers(req, res)
    if not Utils.isEndpointEnabled("players_top") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    local query = Utils.parseQuery(req.path)
    local limit = Utils.validateLimit(query.limit)
    local orderBy = query.order or "hours"
    
    if not Utils.validateOrderBy(orderBy) then
        return Utils.sendResponse(res, 400, Utils.errorResponse("Parâmetro 'order' inválido. Válidos: " .. table.concat(CONFIG.validation.valid_order_by, ", "), "INVALID_ORDER"))
    end
    
    local orderClause = Utils.getOrderClause(orderBy)
    
    exports.oxmysql:query(
        string.format("SELECT id, name, name2, horas, minutos, bank, age, sex, kit FROM %s WHERE deleted = 0 %s LIMIT ?", CONFIG.database.characters_table, orderClause),
        { limit },
        function(result)
            local topPlayers = {}
            
            if result then
                for i, player in ipairs(result) do
                    table.insert(topPlayers, {
                        rank = i,
                        id = player.id,
                        name = (player.name or "") .. " " .. (player.name2 or ""),
                        stats = {
                            horas = player.horas or 0,
                            minutos = player.minutos or 0,
                            total_minutes = (player.horas or 0) * 60 + (player.minutos or 0),
                            bank = player.bank or 0,
                            age = player.age or 0,
                            sex = player.sex,
                            kit = player.kit
                        }
                    })
                end
            end
            
            Utils.sendResponse(res, 200, Utils.successResponse({
                count = #topPlayers,
                order_by = orderBy,
                top_players = topPlayers
            }))
        end
    )
end

function PlayerController.searchPlayers(req, res)
    if not Utils.isEndpointEnabled("players_search") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    local query = Utils.parseQuery(req.path)
    local searchTerm = query.q or ""
    local limit = Utils.validateLimit(query.limit)
    
    if searchTerm == "" then
        return Utils.sendResponse(res, 400, Utils.errorResponse("Parâmetro 'q' (busca) é obrigatório", "MISSING_SEARCH_TERM"))
    end
    
    exports.oxmysql:query(string.format([[
        SELECT id, name, name2, horas, minutos, bank, age, sex, phone, kit, lastlogin 
        FROM %s 
        WHERE deleted = 0 
        AND (name LIKE ? OR name2 LIKE ? OR phone LIKE ? OR id = ?)
        ORDER BY horas DESC
        LIMIT ?
    ]], CONFIG.database.characters_table), { 
        "%" .. searchTerm .. "%", 
        "%" .. searchTerm .. "%", 
        "%" .. searchTerm .. "%", 
        tonumber(searchTerm) or 0,
        limit 
    }, function(result)
        local players = {}
        
        if result then
            for _, player in ipairs(result) do
                table.insert(players, {
                    id = player.id,
                    name = (player.name or "") .. " " .. (player.name2 or ""),
                    phone = player.phone,
                    stats = {
                        horas = player.horas or 0,
                        bank = player.bank or 0,
                        age = player.age or 0,
                        sex = player.sex,
                        kit = player.kit,
                        last_login = player.lastlogin or 0
                    }
                })
            end
        end
        
        Utils.sendResponse(res, 200, Utils.successResponse({
            search_term = searchTerm,
            count = #players,
            players = players
        }))
    end)
end

function PlayerController.getPlayersByKit(req, res, kit)
    if not Utils.isEndpointEnabled("players_kit") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    if not Utils.validateKit(kit) then
        return Utils.sendResponse(res, 400, Utils.errorResponse("Kit inválido. Válidos: " .. table.concat(CONFIG.validation.valid_kits, ", "), "INVALID_KIT"))
    end
    
    exports.oxmysql:query(
        string.format("SELECT id, name, name2, horas, bank, age, sex FROM %s WHERE kit = ? AND deleted = 0 ORDER BY horas DESC", CONFIG.database.characters_table),
        { kit },
        function(result)
            local players = {}
            
            if result then
                for _, player in ipairs(result) do
                    table.insert(players, {
                        id = player.id,
                        name = (player.name or "") .. " " .. (player.name2 or ""),
                        stats = {
                            horas = player.horas or 0,
                            bank = player.bank or 0,
                            age = player.age or 0,
                            sex = player.sex
                        }
                    })
                end
            end
            
            Utils.sendResponse(res, 200, Utils.successResponse({
                kit = kit,
                count = #players,
                players = players
            }))
        end
    )
end

return PlayerController
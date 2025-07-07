local CONFIG = require("config")
local Utils = require("utils")

local ServerController = {}

function ServerController.healthCheck(req, res)
    if not Utils.isEndpointEnabled("health") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    Utils.sendResponse(res, 200, Utils.successResponse({
        status = "online",
        uptime = GetGameTimer(),
        version = CONFIG.server.api_version
    }))
end

function ServerController.getServerInfo(req, res)
    if not Utils.isEndpointEnabled("server_info") then
        return Utils.sendResponse(res, 404, Utils.errorResponse("Endpoint desabilitado", "ENDPOINT_DISABLED"))
    end
    
    local serverInfo = Utils.getServerInfo()
    Utils.sendResponse(res, 200, Utils.successResponse({
        server = serverInfo
    }))
end

function ServerController.getDocumentation(req, res)
    local endpoints = {}

    if Utils.isEndpointEnabled("health") then
        table.insert(endpoints, "GET /health - Health check do servidor")
    end
    if Utils.isEndpointEnabled("server_info") then
        table.insert(endpoints, "GET /server/info - Informações detalhadas do servidor")
    end
    if Utils.isEndpointEnabled("players") then
        table.insert(endpoints, "GET /players - Lista todos os jogadores online")
    end
    if Utils.isEndpointEnabled("players_active") then
        table.insert(endpoints, "GET /players/active - Contador de jogadores ativos")
    end
    if Utils.isEndpointEnabled("players_stats") then
        table.insert(endpoints, "GET /players/stats - Estatísticas completas do servidor")
    end
    if Utils.isEndpointEnabled("players_top") then
        table.insert(endpoints, "GET /players/top?limit=10&order=hours|bank|age - Top jogadores")
    end
    if Utils.isEndpointEnabled("players_search") then
        table.insert(endpoints, "GET /players/search?q=termo&limit=20 - Buscar jogadores")
    end
    if Utils.isEndpointEnabled("players_kit") then
        table.insert(endpoints, "GET /players/kit/{kit} - Jogadores por kit (" .. table.concat(CONFIG.validation.valid_kits, "/") .. ")")
    end
    if Utils.isEndpointEnabled("players_by_id") then
        table.insert(endpoints, "GET /players/{id} - Informações específicas de um jogador")
    end
    
    Utils.sendResponse(res, 200, Utils.successResponse({
        api_version = CONFIG.server.api_version,
        server_info = Utils.getServerInfo(),
        configuration = {
            cors_enabled = CONFIG.server.cors_enabled,
            debug_mode = CONFIG.server.debug,
            max_limit = CONFIG.server.max_limit,
            valid_kits = CONFIG.validation.valid_kits,
            valid_order_by = CONFIG.validation.valid_order_by
        },
        documentation = {
            endpoints = endpoints,
            examples = {
                "GET /players/top?limit=20&order=bank - Top 20 mais ricos",
                "GET /players/search?q=João&limit=10 - Buscar por 'João'",
                "GET /players/kit/" .. (CONFIG.validation.valid_kits[1] or "visionario") .. " - Todos com kit " .. (CONFIG.validation.valid_kits[1] or "visionario")
            }
        }
    }))
end

return ServerController
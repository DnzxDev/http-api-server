local CONFIG = require("config")
local Utils = require("utils")
local PlayerController = require("controllers/PlayerController")
local ServerController = require("controllers/ServerController")

local Router = {}

function Router.getRoutes()
    local routes = {}
    
    table.insert(routes, {
        method = "GET",
        path = "^/$",
        handler = ServerController.getDocumentation,
        enabled = true
    })
    
    if Utils.isEndpointEnabled("health") then
        table.insert(routes, {
            method = "GET",
            path = "^/health$",
            handler = ServerController.healthCheck,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("server_info") then
        table.insert(routes, {
            method = "GET",
            path = "^/server/info$",
            handler = ServerController.getServerInfo,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("players") then
        table.insert(routes, {
            method = "GET",
            path = "^/players$",
            handler = PlayerController.getAllPlayers,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("players_active") then
        table.insert(routes, {
            method = "GET",
            path = "^/players/active$",
            handler = PlayerController.getActivePlayersCount,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("players_stats") then
        table.insert(routes, {
            method = "GET",
            path = "^/players/stats$",
            handler = PlayerController.getPlayerStats,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("players_top") then
        table.insert(routes, {
            method = "GET",
            path = "^/players/top$",
            handler = PlayerController.getTopPlayers,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("players_search") then
        table.insert(routes, {
            method = "GET",
            path = "^/players/search$",
            handler = PlayerController.searchPlayers,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("players_kit") then
        table.insert(routes, {
            method = "GET",
            path = "^/players/kit/([a-zA-Z]+)$",
            handler = PlayerController.getPlayersByKit,
            enabled = true
        })
    end
    
    if Utils.isEndpointEnabled("players_by_id") then
        table.insert(routes, {
            method = "GET",
            path = "^/players/(%d+)$",
            handler = PlayerController.getPlayerById,
            enabled = true
        })
    end
    
    return routes
end

function Router.handle(req, res)
    local path = string.match(req.path, "^[^%?]+") or req.path
    local method = req.method
    
    Utils.log(string.format("Request: %s %s", method, req.path))
    if method == "OPTIONS" then
        Utils.handleCORS(res)
        return
    end
    
    local routes = Router.getRoutes()
    
    for _, route in ipairs(routes) do
        if route.enabled and method == route.method then
            local matches = { string.match(path, route.path) }
            if #matches > 0 or path:match(route.path) then
                Utils.log(string.format("Route matched: %s %s", method, route.path), "DEBUG")
                if #matches > 0 and matches[1] then
                    route.handler(req, res, table.unpack(matches))
                else
                    route.handler(req, res)
                end
                return
            end
        end
    end

    Utils.log(string.format("Route not found: %s %s", method, path), "WARN")
    Utils.sendResponse(res, 404, Utils.errorResponse(
        "Rota não encontrada", 
        "ROUTE_NOT_FOUND"
    ))
end

function Router.validateRequest(req, res, next)
    if req.body and #req.body > 1024 * 1024 then 
        return Utils.sendResponse(res, 413, Utils.errorResponse("Requisição muito grande", "REQUEST_TOO_LARGE"))
    end
    
    if (req.method == "POST" or req.method == "PUT") then
        local contentType = req.headers["content-type"] or ""
        if not contentType:match("application/json") then
            return Utils.sendResponse(res, 415, Utils.errorResponse("Content-Type deve ser application/json", "UNSUPPORTED_MEDIA_TYPE"))
        end
    end
    
    if next then next() end
end

local requestCounts = {}
function Router.rateLimitMiddleware(req, res, next)
    local clientIP = req.headers["x-forwarded-for"] or req.address or "unknown"
    local currentTime = os.time()
    
    for ip, data in pairs(requestCounts) do
        if currentTime - data.lastReset > 60 then
            requestCounts[ip] = nil
        end
    end
    
    if not requestCounts[clientIP] then
        requestCounts[clientIP] = { count = 0, lastReset = currentTime }
    end
    
    requestCounts[clientIP].count = requestCounts[clientIP].count + 1
    
    if requestCounts[clientIP].count > 100 then
        Utils.log(string.format("Rate limit exceeded for IP: %s", clientIP), "WARN")
        return Utils.sendResponse(res, 429, Utils.errorResponse("Muitas requisições", "RATE_LIMIT_EXCEEDED"))
    end
    
    if next then next() end
end

return Router
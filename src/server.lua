local CONFIG = require("config")
local Utils = require("utils")
local Router = require("router")

local middlewares = {
    Router.rateLimitMiddleware,
    Router.validateRequest
}

local function applyMiddlewares(req, res, middlewares, index)
    if index > #middlewares then
        Router.handle(req, res)
        return
    end
    
    local middleware = middlewares[index]
    middleware(req, res, function()
        applyMiddlewares(req, res, middlewares, index + 1)
    end)
end

CreateThread(function()
    Wait(1000)
    
    Utils.log("=== HTTP API Server ===")
    Utils.log("Versão: " .. CONFIG.server.api_version)
    Utils.log("Porta: " .. CONFIG.server.port)
    Utils.log("CORS: " .. (CONFIG.server.cors_enabled and "Habilitado" or "Desabilitado"))
    Utils.log("Debug: " .. (CONFIG.server.debug and "Habilitado" or "Desabilitado"))
    Utils.log("========================")

    SetHttpHandler(function(req, res)
        local body = ""
        local startTime = GetGameTimer()

        req.setDataHandler(function(data)
            body = body .. data
        end)
        
        Citizen.SetTimeout(CONFIG.server.request_timeout, function()
            req.body = body
            req.startTime = startTime
          
            applyMiddlewares(req, res, middlewares, 1)

            local responseTime = GetGameTimer() - startTime
            Utils.log(string.format("Response time: %dms", responseTime), "DEBUG")
        end)
    end)
    
    Utils.log("Servidor HTTP iniciado com sucesso!")
    Utils.log("Acesse GET / para ver a documentação completa")
    
    local enabledEndpoints = {}
    for endpoint, enabled in pairs(CONFIG.endpoints.enabled) do
        if enabled then
            table.insert(enabledEndpoints, endpoint)
        end
    end
    
    Utils.log("Endpoints habilitados: " .. table.concat(enabledEndpoints, ", "))
end)
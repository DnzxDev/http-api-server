local CONFIG = require("config")

local Utils = {}

function Utils.log(message, level)
    if not CONFIG.logging.enabled then return end
    
    level = level or "INFO"
    if CONFIG.server.debug or level ~= "DEBUG" then
        print(string.format("%s [%s] %s", CONFIG.logging.prefix, level, message))
    end
end

function Utils.sendResponse(res, statusCode, data, customHeaders)
    local headers = {}

    for k, v in pairs(CONFIG.response.default_headers) do
        headers[k] = v
    end
    
    if CONFIG.server.cors_enabled then
        headers["Access-Control-Allow-Origin"] = CONFIG.cors.allow_origin
        headers["Access-Control-Allow-Methods"] = CONFIG.cors.allow_methods
        headers["Access-Control-Allow-Headers"] = CONFIG.cors.allow_headers
    end

    if customHeaders then
        for k, v in pairs(customHeaders) do
            headers[k] = v
        end
    end
    
    res.writeHead(statusCode, headers)
    res.send(json.encode(data))
    
    Utils.log(string.format("Response: %d - %s", statusCode, data.success and "SUCCESS" or "ERROR"))
end

function Utils.handleCORS(res)
    if CONFIG.server.cors_enabled then
        res.writeHead(204, {
            ["Access-Control-Allow-Origin"] = CONFIG.cors.allow_origin,
            ["Access-Control-Allow-Methods"] = CONFIG.cors.allow_methods,
            ["Access-Control-Allow-Headers"] = CONFIG.cors.allow_headers
        })
        res.send("")
    end
end

function Utils.parseQuery(path)
    local query = {}
    local queryString = path:match("%?(.+)")
    
    if queryString then
        for param in queryString:gmatch("([^&]+)") do
            local key, value = param:match("([^=]+)=([^=]*)")
            if key and value then
                query[key] = value
            end
        end
    end
    
    return query
end

function Utils.validateLimit(limit)
    local numLimit = tonumber(limit) or CONFIG.endpoints.limits.default_limit
    if numLimit > CONFIG.endpoints.limits.max_limit then
        numLimit = CONFIG.endpoints.limits.max_limit
    end
    return numLimit
end

function Utils.validateKit(kit)
    for _, validKit in ipairs(CONFIG.validation.valid_kits) do
        if kit == validKit then
            return true
        end
    end
    return false
end

function Utils.validateOrderBy(orderBy)
    for _, validOrder in ipairs(CONFIG.validation.valid_order_by) do
        if orderBy == validOrder then
            return true
        end
    end
    return false
end

function Utils.formatPlayerData(player, isOnline, source)
    return {
        id = player.id,
        license = player.license,
        name = {
            first = player.name or CONFIG.response.default_character_name,
            last = player.name2 or CONFIG.response.default_character_surname,
            full = (player.name or CONFIG.response.default_character_name) .. " " .. (player.name2 or CONFIG.response.default_character_surname)
        },
        phone = player.phone,
        demographics = {
            sex = player.sex == "M" and "Masculino" or "Feminino",
            age = player.age or 0,
            blood_type = player.blood or 1
        },
        economy = {
            bank = player.bank or 0
        },
        gameplay = {
            horas = player.horas or 0,
            minutos = player.minutos or 0,
            total_minutes = (player.horas or 0) * 60 + (player.minutos or 0),
            session_time = player.session_time or 0,
            kit = player.kit
        },
        status = {
            online = isOnline,
            source = source,
            deleted = player.deleted == 1,
            last_login = player.lastlogin or 0,
            last_disconnect = player.lastdisconnect or 0
        }
    }
end

function Utils.errorResponse(message, code)
    return {
        success = false,
        error = message,
        error_code = code or "GENERIC_ERROR",
        timestamp = os.time()
    }
end

function Utils.successResponse(data)
    return {
        success = true,
        timestamp = os.time(),
        data = data
    }
end

function Utils.getOrderClause(orderBy)
    if orderBy == "bank" then
        return "ORDER BY bank DESC"
    elseif orderBy == "age" then
        return "ORDER BY age DESC"
    else
        return "ORDER BY horas DESC, minutos DESC"
    end
end

function Utils.split(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

function Utils.getServerInfo()
    local players = GetPlayers() or {}
    local maxPlayers = GetConvarInt("sv_maxclients", 32)
    
    return {
        name = GetConvar("sv_hostname", "Unknown Server"),
        players = {
            online = #players,
            max = maxPlayers,
            percentage = math.floor((#players / maxPlayers) * 100)
        },
        uptime = GetGameTimer(),
        version = CONFIG.server.api_version
    }
end

function Utils.isEndpointEnabled(endpoint)
    return CONFIG.endpoints.enabled[endpoint] or false
end

return Utils
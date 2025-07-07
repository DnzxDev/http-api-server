local CONFIG = {
    server = {
        port = 30120,
        debug = true,
        cors_enabled = true,
        request_timeout = 10,
        max_limit = 100,
        api_version = "2.0.0"
    },

    database = {
        characters_table = "characters",
        query_timeout = 5000
    },

    endpoints = {
        enabled = {
            health = true,
            server_info = true,
            players = true,
            players_active = true,
            players_stats = true,
            players_top = true,
            players_search = true,
            players_kit = true,
            players_by_id = true
        },
        limits = {
            default_limit = 20,
            max_limit = 100,
            search_limit = 20
        }
    },

    validation = {
        valid_kits = {"visionario", "legal", "ilegal"},
        valid_order_by = {"hours", "bank", "age"}
    },

    cors = {
        allow_origin = "*",
        allow_methods = "GET, POST, OPTIONS, PUT, DELETE",
        allow_headers = "Content-Type, Authorization"
    },

    logging = {
        enabled = true,
        prefix = "[HTTP-API]",
        level = "INFO" -- DEBUG, INFO, WARN, ERROR
    },
    
    response = {
        default_headers = {
            ["Content-Type"] = "application/json"
        },
        default_character_name = "Individuo",
        default_character_surname = "Indigente"
    }
}

return CONFIG
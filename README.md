# HTTP API Server for FiveM

Configurable HTTP API system for FiveM servers with vRP integration.

## Features

- **Modular** – Separate controllers, utilities, and router  
- **Configurable** – All settings centralized in `config.lua`  
- **Flexible** – Endpoints can be enabled or disabled individually  
- **Secure** – Rate limiting and request validation  
- **Extensible** – Easy to add new endpoints and features  

## Configuration

### Basic Configuration (`config.lua`)

```lua
local CONFIG = {
    server = {
        port = 30120,
        debug = true,
        cors_enabled = true,
        max_limit = 100
    },
    endpoints = {
        enabled = {
            health = true,
            players = true,
            players_stats = true,
        }
    }
}
```

### Customizing Endpoints

To disable an endpoint, change its configuration:

```lua
endpoints = {
    enabled = {
        players_stats = false,  -- Disable player statistics
        players_search = false  -- Disable player search
    }
}
```

## Available Endpoints

### Server

- `GET /` – API documentation
- `GET /health` – Health check
- `GET /server/info` – Server information

### Players

- `GET /players` – List all online players
- `GET /players/active` – Count of active players
- `GET /players/stats` – Complete player statistics
- `GET /players/top` – Top players (with filters)
- `GET /players/search` – Search for players
- `GET /players/kit/{kit}` – Players by kit
- `GET /players/{id}` – Specific player information

## Query Parameters

### Top Players (`/players/top`)

- `limit` – Number of results (default: 10, max: 100)
- `order` – Sorting (hours, bank, age)

### Search Players (`/players/search`)

- `q` – Search term (required)
- `limit` – Number of results (default: 20)

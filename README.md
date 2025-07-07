# HTTP API Server para FiveM

Sistema de API HTTP configurável para servidores FiveM com integração ao vRP.

## 🚀 Características

- **Modular**: Controladores, utilitários e roteador separados
- **Configurável**: Todas as configurações centralizadas no `config.lua`
- **Flexível**: Endpoints podem ser habilitados/desabilitados individualmente
- **Seguro**: Rate limiting e validação de requisições
- **Extensível**: Fácil adição de novos endpoints e funcionalidades

## 📁 Estrutura do Projeto

```
http-api-server/
├── config.lua                    # Configurações centralizadas
├── utils.lua                     # Utilitários e funções auxiliares
├── router.lua                    # Sistema de roteamento
├── server.lua                    # Servidor principal
├── controllers/
│   ├── PlayerController.lua      # Controlador de jogadores
│   └── ServerController.lua      # Controlador do servidor
├── fxmanifest.lua                # Manifesto do FiveM
└── README.md                     # Documentação
```

## ⚙️ Configuração

### Configuração Básica (`config.lua`)

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

### Personalização de Endpoints

Para desabilitar um endpoint, altere sua configuração:

```lua
endpoints = {
    enabled = {
        players_stats = false,  -- Desabilita estatísticas
        players_search = false  -- Desabilita busca
    }
}
```

## 📊 Endpoints Disponíveis

### Servidor
- `GET /` - Documentação da API
- `GET /health` - Health check
- `GET /server/info` - Informações do servidor

### Jogadores
- `GET /players` - Lista todos os jogadores online
- `GET /players/active` - Contagem de jogadores ativos
- `GET /players/stats` - Estatísticas completas
- `GET /players/top` - Top jogadores (com filtros)
- `GET /players/search` - Buscar jogadores
- `GET /players/kit/{kit}` - Jogadores por kit
- `GET /players/{id}` - Informações de um jogador específico

### Parâmetros de Query

**Top Players (`/players/top`)**
- `limit`: Número de resultados (padrão: 10, máximo: 100)
- `order`: Ordenação (hours, bank, age)

**Buscar Players (`/players/search`)**
- `q`: Termo de busca (obrigatório)
- `limit`: Número de resultados (padrão: 20)
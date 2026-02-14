# MAXIMA RPG

Juego multijugador RPG basado en comandos de chat, con soporte visual en Pixel Art, mecanicas inspiradas en D&D, y un sistema de calabozos generados proceduralmente.

## Arquitectura

```
MAXIMA/
├── backend/                    # Servidor Node.js + Socket.IO
│   ├── server.js               # Punto de entrada principal
│   ├── src/
│   │   ├── config/
│   │   │   └── firebase.js     # Configuracion Firebase Admin SDK
│   │   ├── game/
│   │   │   ├── combat.js       # Sistema de combate D20
│   │   │   ├── commands.js     # Manejador de comandos de chat
│   │   │   ├── dungeon.js      # Generacion procedural de calabozos
│   │   │   ├── legacy.js       # Sistema de legado y /returning
│   │   │   ├── loot.js         # Sistema de loot y rareza
│   │   │   └── master.js       # Narrador Master (personalidad cinica)
│   │   ├── middleware/
│   │   │   └── rateLimit.js    # Anti-spam de comandos
│   │   ├── models/
│   │   │   ├── character.js    # Modelo de personaje
│   │   │   ├── dungeon.js      # Modelo de calabozo
│   │   │   └── player.js       # Modelo de jugador
│   │   └── multiplayer/
│   │       ├── rooms.js        # Gestion de salas
│   │       └── sync.js         # Sincronizacion en tiempo real
│   └── package.json
│
└── frontend/                   # Aplicacion Flutter
    ├── lib/
    │   ├── main.dart           # Punto de entrada
    │   ├── config/
    │   │   ├── routes.dart     # Rutas de navegacion
    │   │   └── theme.dart      # Tema visual RPG oscuro
    │   ├── data/
    │   │   └── character_data.dart  # Datos estaticos (razas, clases)
    │   ├── models/
    │   │   ├── character.dart  # Modelo de personaje
    │   │   ├── class_model.dart    # Modelo de clase/subclase
    │   │   ├── dungeon.dart    # Modelo de calabozo
    │   │   ├── player.dart     # Modelo de jugador
    │   │   ├── race_model.dart # Modelo de raza
    │   │   └── weapon_model.dart   # Modelo de arma
    │   ├── screens/
    │   │   ├── character_creation_screen.dart  # Creacion de personaje
    │   │   ├── dungeon_select_screen.dart      # Seleccion de calabozo
    │   │   ├── game_screen.dart               # Pantalla de juego
    │   │   ├── lobby_screen.dart              # Lobby principal
    │   │   ├── login_screen.dart              # Inicio de sesion
    │   │   ├── profile_screen.dart            # Perfil del jugador
    │   │   ├── register_screen.dart           # Registro
    │   │   └── settings_screen.dart           # Configuracion
    │   ├── services/
    │   │   ├── auth_service.dart       # Autenticacion Firebase
    │   │   ├── firebase_service.dart   # CRUD Firestore
    │   │   └── socket_service.dart     # Cliente Socket.IO
    │   ├── utils/
    │   │   └── stats_calculator.dart   # Calculo de stats
    │   └── widgets/
    │       ├── chat_widget.dart        # Widget de chat
    │       ├── class_card.dart         # Tarjeta de clase
    │       ├── dungeon_card.dart       # Tarjeta de calabozo
    │       ├── master_message.dart     # Mensaje del Master
    │       ├── race_card.dart          # Tarjeta de raza
    │       ├── sprite_widget.dart      # Sprite animado
    │       ├── stats_bar.dart          # Barra de stats
    │       └── weapon_display.dart     # Display de arma
    └── pubspec.yaml
```

## Stack Tecnologico

| Componente | Tecnologia |
|---|---|
| Backend | Node.js + Express |
| Tiempo Real | Socket.IO |
| Frontend | Flutter (Dart) |
| Base de Datos | Firebase Firestore |
| Autenticacion | Firebase Auth |
| Estado (Frontend) | Provider |

## Modulos del Juego

### Sistema de Combate (D20)
- Tirada de 1d20 para acciones de ataque
- Tirada >= 10: golpe exitoso (dano 5-15 + stats)
- Tirada == 20: golpe critico (dano x2)
- Tirada == 1: fallo critico (dano propio)
- Tirada < 10: fallo

### Generacion Procedural de Calabozos
Tres calabozos predefinidos con generacion procedural de salas:
- **Catacumbas del Novato** (Facil) - Nivel 1+
- **Laberinto de las Lagrimas de Obsidiana** (Media) - Nivel 5+
- **Abismo del Dragon Negro** (Dificil) - Nivel 10+

Tipos de sala: Corredor, Tesoro, Trampa, Mercader, Jefe, Puzzle, Descanso.

### Creacion de Personaje
- **5 Razas**: Humano, Elfo, Enano, Orco, No-Muerto
- **4 Clases** con 2 subclases cada una:
  - Guerrero (Espadachin / Berserker)
  - Mago (Piromante / Nigromante)
  - Ladronzuelo (Asesino / Explorador)
  - Clerigo (Sanador / Paladin)
- Stats base: Fuerza, Destreza, Constitucion, Carisma
- Cada raza y subclase modifica los stats iniciales

### Sistema de Loot
- 4 niveles de rareza: Comun (60%), Poco Comun (25%), Raro (10%), Legendario (5%)
- Categorias: Armas, Armaduras, Pociones, Pergaminos
- 40+ objetos unicos con descripciones tematicas

### Narrador Master
Personalidad cinica, descriptiva, con humor negro. Genera mensajes inmersivos para:
- Encuentros con enemigos
- Trampas
- Mercaderes
- Muerte de personajes
- Eventos aleatorios

### Multijugador
- Salas de hasta 4 jugadores
- Chat en tiempo real
- Acciones compartidas en calabozos
- Bonus cooperativo (+15% dano con aliados)
- Distribucion equitativa de loot

### Sistema de Legado
- Personajes muertos se convierten en "legado"
- Comando `/returning` para revivir con bonus (+10% XP por muerte)
- Costo: 5 Smart Coins por revival

## Comandos de Chat

| Comando | Descripcion |
|---|---|
| `/stats` | Muestra HP, XP, Coins, Smart Coins |
| `/inventory` | Lista el inventario |
| `/attack [objetivo]` | Atacar a un enemigo |
| `/hunt` | Buscar y combatir un enemigo aleatorio |
| `/move [direccion]` | Moverse (Norte/Sur/Este/Oeste) |
| `/use [objeto]` | Usar un objeto del inventario |
| `/returning` | Revivir personaje muerto con bonus |
| `/help` | Lista de comandos disponibles |

## Instalacion

### Backend

```bash
cd backend
cp .env.example .env
# Configurar variables de Firebase en .env
npm install
node server.js
```

### Frontend

```bash
cd frontend
flutter pub get
# Configurar Firebase (google-services.json / GoogleService-Info.plist)
flutter run
```

### Variables de Entorno (Backend)

```
PORT=3000
CORS_ORIGIN=*
FIREBASE_PROJECT_ID=tu-proyecto
FIREBASE_CLIENT_EMAIL=tu-email@proyecto.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=tu-clave-privada
```

## Estructura Firebase

### Coleccion `players`
```json
{
  "uid": "abc123",
  "username": "GuerreroSombrio",
  "smartCoins": 100,
  "legacyCharacters": ["char_1", "char_2"],
  "activeCharacterId": "char_1",
  "settings": { "sound": true, "notifications": true }
}
```

### Coleccion `characters`
```json
{
  "characterId": "char_abc123",
  "playerId": "uid_xyz789",
  "name": "Thalric el Implacable",
  "characterClass": "Mago",
  "race": "Elfo",
  "subclass": "Piromante",
  "level": 1,
  "hp": 70,
  "maxHp": 70,
  "stats": { "fuerza": 9, "destreza": 12, "constitucion": 10, "carisma": 12 },
  "weapon": { "name": "Baston de Fuego", "damage": "1d8" },
  "inventory": [],
  "isAlive": true
}
```

### Coleccion `rooms`
```json
{
  "roomId": "room_001",
  "dungeonId": "laberinto_obsidiana",
  "players": ["uid_1", "uid_2"],
  "currentRoom": 0,
  "status": "active"
}
```

## Plataformas

- Android (APK)
- iOS
- Web
- Desktop (Windows, macOS, Linux)

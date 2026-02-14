@echo off
chcp 65001 >nul 2>&1
title MAXIMA RPG - Instalador y Lanzador Local
color 0A

echo =====================================================
echo        MAXIMA RPG - Despliegue Local desde Cero
echo =====================================================
echo.

:: -------------------------------------------------------
:: 1. Verificar prerequisitos
:: -------------------------------------------------------

echo [1/7] Verificando prerequisitos...
echo.

:: Verificar Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] Node.js no esta instalado.
    echo         Descargalo de: https://nodejs.org/
    echo         Version recomendada: 18 LTS o superior.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('node -v') do echo   Node.js: %%v

:: Verificar npm
where npm >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] npm no esta instalado.
    echo         Reinstala Node.js desde https://nodejs.org/
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('npm -v') do echo   npm:     v%%v

:: Verificar Flutter
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    color 0E
    echo.
    echo [AVISO] Flutter no esta instalado.
    echo         El backend se iniciara, pero el frontend no podra ejecutarse.
    echo         Descarga Flutter de: https://flutter.dev/docs/get-started/install
    echo.
    set FLUTTER_AVAILABLE=0
) else (
    for /f "tokens=2 delims= " %%v in ('flutter --version 2^>^&1 ^| findstr /i "Flutter"') do echo   Flutter: %%v
    set FLUTTER_AVAILABLE=1
)

echo.
echo   Prerequisitos verificados.
echo.

:: -------------------------------------------------------
:: 2. Configurar variables de entorno del backend
:: -------------------------------------------------------

echo [2/7] Configurando variables de entorno...
echo.

cd /d "%~dp0backend"

if not exist ".env" (
    if exist ".env.example" (
        copy ".env.example" ".env" >nul
        echo   Archivo .env creado desde .env.example
        echo.
        color 0E
        echo   =====================================================
        echo   IMPORTANTE: Configura tu archivo backend\.env con
        echo   tus credenciales de Firebase antes de continuar.
        echo.
        echo   Archivo: %~dp0backend\.env
        echo.
        echo   Necesitas configurar:
        echo     - FIREBASE_PROJECT_ID
        echo     - FIREBASE_CLIENT_EMAIL
        echo     - FIREBASE_PRIVATE_KEY
        echo   O bien:
        echo     - FIREBASE_SERVICE_ACCOUNT_PATH
        echo       ^(ruta al archivo serviceAccountKey.json^)
        echo   =====================================================
        echo.
        color 0A
        choice /C SN /M "Ya configuraste Firebase? (S=Si, N=Abrir .env para editar)"
        if errorlevel 2 (
            start notepad "%~dp0backend\.env"
            echo.
            echo   Edita el archivo .env, guardalo, y presiona una tecla para continuar...
            pause >nul
        )
    ) else (
        echo   [AVISO] No se encontro .env.example - creando .env minimo...
        (
            echo PORT=3000
            echo NODE_ENV=development
            echo CORS_ORIGINS=http://localhost:5173,http://localhost:3000,http://localhost:8080
        ) > ".env"
        echo   Archivo .env basico creado.
    )
) else (
    echo   Archivo .env existente encontrado. Usando configuracion actual.
)

echo.

:: -------------------------------------------------------
:: 3. Instalar dependencias del backend
:: -------------------------------------------------------

echo [3/7] Instalando dependencias del backend...
echo.

cd /d "%~dp0backend"
call npm install
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [ERROR] Fallo la instalacion de dependencias del backend.
    echo         Verifica tu conexion a internet e intenta de nuevo.
    pause
    exit /b 1
)

echo.
echo   Dependencias del backend instaladas correctamente.
echo.

:: -------------------------------------------------------
:: 4. Ejecutar tests del backend
:: -------------------------------------------------------

echo [4/7] Ejecutando tests del backend...
echo.

cd /d "%~dp0backend"
call npx jest --verbose 2>&1
if %errorlevel% neq 0 (
    color 0E
    echo.
    echo [AVISO] Algunos tests fallaron. El servidor se iniciara de todas formas.
    echo         Revisa los errores arriba para mas detalles.
    echo.
) else (
    echo.
    echo   Todos los tests del backend pasaron correctamente.
    echo.
)

:: -------------------------------------------------------
:: 5. Instalar dependencias del frontend (si Flutter existe)
:: -------------------------------------------------------

if "%FLUTTER_AVAILABLE%"=="1" (
    echo [5/7] Instalando dependencias del frontend...
    echo.

    cd /d "%~dp0frontend"

    :: Crear directorio assets si no existe
    if not exist "assets" mkdir assets

    :: Habilitar soporte web si no existe
    if not exist "web" (
        echo   Habilitando soporte web...
        call flutter create --platforms web .
        echo.
    )

    :: Configurar Firebase Web SDK si no existe firebase_config.json
    if not exist "firebase_config.json" (
        if exist "firebase_config.json.example" (
            copy "firebase_config.json.example" "firebase_config.json" >nul
        ) else (
            (
                echo {
                echo   "FIREBASE_API_KEY": "tu-api-key-aqui",
                echo   "FIREBASE_AUTH_DOMAIN": "tu-project-id.firebaseapp.com",
                echo   "FIREBASE_PROJECT_ID": "tu-project-id",
                echo   "FIREBASE_STORAGE_BUCKET": "tu-project-id.firebasestorage.app",
                echo   "FIREBASE_MESSAGING_SENDER_ID": "tu-sender-id",
                echo   "FIREBASE_APP_ID": "tu-app-id"
                echo }
            ) > "firebase_config.json"
        )
        echo.
        color 0E
        echo   =====================================================
        echo   IMPORTANTE: Configura frontend\firebase_config.json
        echo   con tu configuracion web de Firebase.
        echo.
        echo   Archivo: %~dp0frontend\firebase_config.json
        echo.
        echo   Obten estos datos de Firebase Console:
        echo     Configuracion del proyecto ^> General ^> Tus apps
        echo     ^> Agregar app ^> Web ^(icono ^<^/^>^)
        echo.
        echo   Necesitas:
        echo     - FIREBASE_API_KEY
        echo     - FIREBASE_AUTH_DOMAIN
        echo     - FIREBASE_PROJECT_ID
        echo     - FIREBASE_STORAGE_BUCKET
        echo     - FIREBASE_MESSAGING_SENDER_ID
        echo     - FIREBASE_APP_ID
        echo   =====================================================
        echo.
        color 0A
        choice /C SN /M "Ya configuraste firebase_config.json? (S=Si, N=Abrir para editar)"
        if errorlevel 2 (
            start notepad "%~dp0frontend\firebase_config.json"
            echo.
            echo   Edita firebase_config.json, guardalo, y presiona una tecla...
            pause >nul
        )
    )

    :: Limpiar cache de compilacion y forzar resolucion fresca de dependencias
    echo   Limpiando cache de compilacion...
    call flutter clean >nul 2>&1
    if exist "pubspec.lock" del "pubspec.lock"

    call flutter pub get
    if %errorlevel% neq 0 (
        color 0E
        echo.
        echo [AVISO] Fallo la instalacion de dependencias de Flutter.
        echo         El backend se iniciara sin el frontend.
        echo.
        set FLUTTER_AVAILABLE=0
    ) else (
        echo.
        echo   Dependencias del frontend instaladas correctamente.
        echo.
    )
) else (
    echo [5/7] Saltando instalacion del frontend ^(Flutter no disponible^)...
    echo.
)

:: -------------------------------------------------------
:: 6. Iniciar el backend en una ventana separada
:: -------------------------------------------------------

echo [6/7] Iniciando servidor backend...
echo.

cd /d "%~dp0backend"
start "MAXIMA RPG - Backend (Puerto 3000)" cmd /k "title MAXIMA RPG - Backend & color 0B & echo. & echo ===================================================== & echo   MAXIMA RPG Backend - Puerto 3000 & echo ===================================================== & echo. & node server.js"

:: Esperar a que el backend arranque
echo   Esperando a que el backend inicie...
timeout /t 3 /nobreak >nul

:: Verificar que el backend responde
curl -s http://localhost:3000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo   Backend iniciado correctamente en http://localhost:3000
) else (
    echo   Backend iniciando... ^(puede tardar unos segundos^)
)
echo.

:: -------------------------------------------------------
:: 7. Iniciar el frontend en otra ventana (si Flutter existe)
:: -------------------------------------------------------

if "%FLUTTER_AVAILABLE%"=="1" (
    echo [7/7] Iniciando frontend Flutter...
    echo.

    cd /d "%~dp0frontend"

    :: Preguntar plataforma
    echo   Selecciona la plataforma para el frontend:
    echo     1. Brave ^(Web^)
    echo     2. Windows ^(Desktop^)
    echo     3. Android ^(requiere dispositivo/emulador^)
    echo.
    choice /C 123 /M "Plataforma"

    if errorlevel 3 (
        start "MAXIMA RPG - Frontend (Android)" cmd /k "title MAXIMA RPG - Frontend Android & color 0D & echo. & echo ===================================================== & echo   MAXIMA RPG Frontend - Android & echo ===================================================== & echo. & flutter run"
    ) else if errorlevel 2 (
        start "MAXIMA RPG - Frontend (Windows)" cmd /k "title MAXIMA RPG - Frontend Windows & color 0D & echo. & echo ===================================================== & echo   MAXIMA RPG Frontend - Windows Desktop & echo ===================================================== & echo. & flutter run -d windows"
    ) else (
        :: Usar web-server mode y abrir Brave manualmente
        :: (evita problemas con flutter -d chrome cuando Chrome no esta instalado)
        start "MAXIMA RPG - Frontend (Brave)" cmd /k "title MAXIMA RPG - Frontend Brave & color 0D & echo. & echo ===================================================== & echo   MAXIMA RPG Frontend - Brave Web & echo ===================================================== & echo. & flutter run -d web-server --web-port 5173 --dart-define-from-file=firebase_config.json"
        echo   Esperando a que el servidor web inicie...
        timeout /t 10 /nobreak >nul
        :: Abrir en Brave usando la ruta conocida de instalacion
        if exist "%PROGRAMFILES%\BraveSoftware\Brave-Browser\Application\brave.exe" (
            echo   Abriendo Brave...
            start "" "%PROGRAMFILES%\BraveSoftware\Brave-Browser\Application\brave.exe" "http://localhost:5173"
        ) else if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" (
            echo   Abriendo Brave...
            start "" "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" "http://localhost:5173"
        ) else (
            echo   [AVISO] No se encontro Brave. Abriendo en navegador predeterminado...
            start "" "http://localhost:5173"
        )
    )

    echo.
    echo   Frontend iniciando en ventana separada...
) else (
    echo [7/7] Frontend no disponible ^(instala Flutter para habilitarlo^).
)

echo.

:: -------------------------------------------------------
:: Resumen final
:: -------------------------------------------------------

echo =====================================================
echo              MAXIMA RPG - Listo!
echo =====================================================
echo.
echo   Backend:  http://localhost:3000
echo   Health:   http://localhost:3000/health
if "%FLUTTER_AVAILABLE%"=="1" (
    echo   Frontend: Iniciando en ventana separada
)
echo.
echo   Ventanas abiertas:
echo     - MAXIMA RPG Backend  ^(servidor Node.js^)
if "%FLUTTER_AVAILABLE%"=="1" (
    echo     - MAXIMA RPG Frontend ^(aplicacion Flutter^)
)
echo.
echo   Para detener el juego, cierra las ventanas de
echo   backend y frontend, o presiona Ctrl+C en cada una.
echo.
echo =====================================================
echo.
pause

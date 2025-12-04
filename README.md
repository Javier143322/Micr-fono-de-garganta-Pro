🎤 Throat Mic Pro + Corporate Elite v6.0.0
Sistema de comunicación profesional integrado con sistema corporativo para FiveM.
📋 CARACTERÍSTICAS
Throat Mic Pro
✅ Sistema de frecuencias públicas y privadas
✅ Frecuencias protegidas con contraseña
✅ Sistema de batería realista
✅ HUD en tiempo real
✅ Indicador de transmisión
✅ Múltiples tipos de micrófono
✅ Control total de volumen y estado
Corporate Elite
✅ Sistema de servicios corporativos
✅ Servicios legales e ilegales
✅ Sistema de acabados con costos adicionales
✅ Historial de transacciones
✅ Control de acceso por faction/grade
✅ Logging de actividades
✅ Canal de emergencia
📦 INSTALACIÓN
1. Descargar archivos
Copia todos los archivos en tu carpeta de recursos:
resources/throatmic/
├── fxmanifest.lua
├── client.lua
├── server.lua
├── html/
│   ├── throatmic.html
│   ├── style.css
│   └── script.js
2. Base de datos
Ejecuta el archivo items.sql en tu base de datos:
-- Crear items en la BD
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`, `usable`) 
VALUES ('throatmic', 'Throat Mic Pro', 1, 0, 1, 1);
3. Dependencias requeridas
Asegúrate de tener instalados:
es_extended (ESX Framework)
pma-voice (Sistema de voz)
oxmysql (Base de datos)
4. Agregar al server.cfg
ensure es_extended
ensure pma-voice
ensure oxmysql
ensure throatmic
5. Dar item a jugadores (EN JUEGO)
/give @username throatmic
🎮 COMANDOS
Cliente
Comando
Descripción
Atajo
/throatmic
Activar/Desactivar
F
/corporate
Abrir sistema corporate
G
En juego
Acción
Tecla
Hablar
Mantén V
Apagar mic
F
🔧 CONFIGURACIÓN
Cambiar teclas (client.lua)
local Config = {
    PTTKey = 0x76, -- V para hablar
    ToggleKey = 0x49, -- F para apagar
    ActivateCommand = 'throatmic'
}
Ajustar frecuencias (server.lua)
local FactionFrequencies = {
    police = {1, 2, 3},
    ambulance = {4, 5},
    -- Agregar más...
}
Servicios corporativos (server.lua)
local CorporateFactions = {
    police = {
        name = "DEPARTAMENTO DE POLICÍA",
        services = {
            {id = 1, name = "SERVICIO", price = 5000, legal = true}
        }
    }
}
🛡️ SEGURIDAD IMPLEMENTADA
Validación de datos
✅ Validación de tipos en todas las entradas
✅ Sanitización de texto para prevenir XSS
✅ Rango límites en frecuencias y precios
✅ Verificación de permisos en servidor
Protección contra explotación
✅ Sin confianza en datos del cliente
✅ Validación doble en transacciones
✅ Logging de actividades ilegales
✅ Control de grade para servicios sensibles
HTML/CSS/JS
✅ Content Security Policy
✅ Meta tags de seguridad
✅ Encapsulación IIFE
✅ Event listeners seguros
✅ Validación en formularios
📊 BASE DE DATOS
Tablas creadas automáticamente:
player_throat_mics - Datos del jugador
custom_frequencies - Frecuencias personalizadas
corporate_activity_logs - Log de actividades
corporate_transactions - Historial de transacciones
🎯 EJEMPLOS DE USO
Dar un Throat Mic
-- En consola
/give @username throatmic

-- Desde código
TriggerServerEvent('esx_giving:use', 'throatmic')
Crear frecuencia personalizada (Admin)
INSERT INTO custom_frequencies (owner_identifier, frequency, password, faction_name)
VALUES ('identifier_aqui', 100, 'password123', 'Police RP');
Ver transacciones de un jugador
SELECT * FROM corporate_transactions 
WHERE player_id = 'identifier_aqui' 
ORDER BY timestamp DESC LIMIT 10;
🐛 SOLUCIÓN DE PROBLEMAS
El HUD no aparece
Verifica que pma-voice está cargado
Comprueba la consola (F8) por errores
Asegúrate que tienes el item throatmic
No puedo usar Corporate
Verifica tu job y grade
Revisa que tu faction está en CorporateFactions
Comprueba que tienes suficiente dinero
Las frecuencias no aparecen
Verifica que las frecuencias están en la configuración
Comprueba que MySQL está funcionando
Revisa el log de servidor
📝 NOTAS IMPORTANTES
Backup de BD: Antes de usar, realiza backup de tu base de datos
Prueba en desarrollo: Prueba en server de desarrollo antes de producción
Permisos: Configura correctamente los grades para servicios ilegales
Logs: Revisa regularmente los logs de actividades
Actualizaciones: Actualiza las dependencias regularmente
🔐 MEJORAS DE SEGURIDAD IMPLEMENTADAS
Client-side
Validación de datos NUI
Sanitización de HTML
Protección contra XSS
Event listeners seguros
Sin almacenamiento inseguro
Server-side
Validación de todos los inputs
Verificación de permisos
Transacciones atómicas
Logging de actividades sospechosas
Rate limiting implícito
Database
Prepared statements (SQL injection proof)
Índices para optimización
Foreign keys donde aplica
Timestamps automáticos
📞 SOPORTE
Para problemas o sugerencias:
Revisa los logs del servidor (F8)
Verifica la consola del navegador (F12)
Confirma que todas las dependencias están cargadas
Prueba con otro jugador para descartar problemas de cuenta
📄 LICENCIA
Este recurso es de uso libre. Personalízalo según tus necesidades.
✅ CHECKLIST DE INSTALACIÓN
[ ] Archivos copiados a la carpeta correcta
[ ] Dependencias instaladas (es_extended, pma-voice, oxmysql)
[ ] SQL ejecutado en base de datos
[ ] Agregado al server.cfg
[ ] Servidor reiniciado
[ ] Probado en juego con cuenta de admin
[ ] Item creado/dado a un jugador de prueba
[ ] Frecuencias visibles en el menú
[ ] Corporate system accesible por faction
[ ] Historial de transacciones registrado
Versión: 6.0.0
Última actualización: 2024
Estado: ✅ Producción Ready


🚀 GUÍA DE INSTALACIÓN PASO A PASO - Throat Mic Pro v6.0.0
REQUISITOS PREVIOS
Antes de empezar, asegúrate de tener:
✅ FiveM server instalado
✅ Framework ESX instalado
✅ MySQL/MariaDB funcionando
✅ Acceso RCON/Admin al servidor
PASO 1: DESCARGAR ARCHIVOS
Crear estructura de carpetas
Tu_servidor/
└── resources/
    └── throatmic/
Archivos necesarios:
throatmic/
├── fxmanifest.lua
├── client.lua
├── server.lua
└── html/
    ├── throatmic.html
    ├── style.css
    └── script.js
PASO 2: COPIAR ARCHIVOS
Abre la carpeta resources/ de tu servidor
Crea una nueva carpeta llamada throatmic
Copia fxmanifest.lua, client.lua y server.lua en esta carpeta
Crea una subcarpeta html/ dentro de throatmic/
Copia throatmic.html, style.css y script.js en la carpeta html/
Estructura final:
resources/
└── throatmic/
    ├── fxmanifest.lua
    ├── client.lua
    ├── server.lua
    └── html/
        ├── throatmic.html
        ├── style.css
        └── script.js
PASO 3: CONFIGURAR BASE DE DATOS
Opción A: Usar DBeaver o similar
Abre tu gestor de base de datos (phpMyAdmin, DBeaver, etc.)
Selecciona tu base de datos del servidor
Ejecuta el siguiente SQL:
-- Crear items
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`, `usable`) 
VALUES ('throatmic', 'Throat Mic Pro', 1, 0, 1, 1)
ON DUPLICATE KEY UPDATE `label` = 'Throat Mic Pro';

-- Verificar que se insertó
SELECT * FROM `items` WHERE `name` = 'throatmic';
Opción B: Script de SQL
Las tablas se crean automáticamente cuando el servidor inicia por primera vez.
PASO 4: CONFIGURAR SERVER.CFG
Abre tu archivo server.cfg
Encuentra la sección de ensure (recursos a cargar)
Asegúrate que estas líneas existen:
# Dependencias necesarias
ensure es_extended
ensure pma-voice
ensure oxmysql

# Nuestro recurso (agrégalo después de las dependencias)
ensure throatmic
Guarda el archivo
PASO 5: CONFIGURACIÓN PERSONALIZADA (OPCIONAL)
A. Cambiar teclas (client.lua)
Abre client.lua y busca:
local Config = {
    PTTKey = 0x76, -- V
    ToggleKey = 0x49, -- F
}
Códigos de teclas comunes:
0x76 = V
0x49 = I
0x47 = G
0x4D = M
0x4B = K
B. Agregar facciones (server.lua)
Abre server.lua y busca FactionFrequencies:
local FactionFrequencies = {
    police = {1, 2, 3},
    ambulance = {4, 5},
    mechanic = {6},
    -- Aquí agregar más facciones
}
C. Agregar servicios corporativos (server.lua)
Busca CorporateFactions y personaliza los servicios:
local CorporateFactions = {
    police = {
        name = "POLICÍA",
        minGrade = 1,
        services = {
            {id = 1, name = "VIGILANCIA", price = 5000, legal = true},
            -- Agregar más servicios
        }
    }
}
PASO 6: REINICIAR SERVIDOR
En consola del servidor:
restart throatmic
O reinicia todo el servidor:
restart all
Espera a ver en la consola:
[Throat Mic] ESX cargado correctamente
[Throat Mic] Tablas de base de datos creadas/verificadas
PASO 7: PRUEBA INICIAL
Dar el item a un jugador (EN CONSOLA RCON)
# Conecta con RCON y ejecuta:
give @username throatmic

# O desde la consola F8 (si eres admin):
/give @yourname throatmic
En juego:
Abre tu inventario (I por defecto)
Busca "Throat Mic Pro"
Click derecho → Usar
Deberías ver el HUD en la esquina superior derecha
Presiona F para apagar/encender
Mantén V para hablar
PASO 8: PRUEBA DEL SISTEMA CORPORATE
Solo para facciones configuradas:
Tener el job correcto (ejemplo: police)
Tener el grade mínimo (configurable)
Presionar G en juego
Debería abrir el menú corporate
SOLUCIÓN DE PROBLEMAS
Problema: "Resource not found: throatmic"
Solución:
Verifica que la carpeta existe: resources/throatmic/
Verifica que fxmanifest.lua existe en esa carpeta
Reinicia el servidor
Problema: Error de base de datos
Solución:
Verifica que oxmysql está cargado
Revisa credenciales de BD en server.cfg
Ejecuta manualmente el SQL de items
Problema: El HUD no aparece
Solución:
Verifica que pma-voice está cargado
Verifica que tienes el item throatmic
Abre consola (F8) y busca errores
Prueba: /throatmic en consola
Problema: Corporate no funciona
Solución:
Verifica tu job actual: /job
Verifica tu grade: /myinfo
Confirma que ese job está en CorporateFactions
Verifica que tu grade es >= minGrade
Problema: "pma-voice not found"
Solución:
Asegúrate que pma-voice está en resources/
Agrega ensure pma-voice en server.cfg ANTES de throatmic
Reinicia servidor
VERIFICACIÓN FINAL
Checklist antes de decir que está instalado:
[ ] Carpeta resources/throatmic/ existe
[ ] Todos los archivos están en su lugar
[ ] El servidor inicia sin errores
[ ] El comando /give @username throatmic funciona
[ ] El item aparece en inventario
[ ] Presionar F abre el menú de frecuencias
[ ] Presionar G abre corporativo (si tienes job)
[ ] Puedes cambiar frecuencias
[ ] El HUD muestra batería y frecuencia
PRÓXIMOS PASOS
Una vez instalado y funcionando:
Personalizar configuración:
Ajusta precios de servicios
Agrega más facciones
Cambia teclas según tu gusto
Crear frecuencias personalizadas:
INSERT INTO custom_frequencies (owner_identifier, frequency, password, faction_name)
VALUES ('steam:1234567890', 100, 'secreto', 'Mafia Principal');
Monitorear logs:
Revisa corporate_activity_logs
Revisa corporate_transactions
Hacer backups:
Realiza backup regular de base de datos
Mantén respaldo de archivos
COMANDOS ÚTILES (RCON)
# Ver logs del recurso
log throatmic

# Reiniciar recurso
restart throatmic

# Detener recurso
stop throatmic

# Recargar configuración
start throatmic

# Ver jugadores conectados
players

# Dar item
give @username throatmic

# Remover item
remove @username throatmic
SOPORTE Y DEPURACIÓN
Activar modo debug (opcional)
En client.lua, agregar al inicio:
local DEBUG = true
local function DebugLog(message)
    if DEBUG then
        print("^2[DEBUG]^7 " .. message)
    end
end
Ver errores en consola (F8)
# Para ver todos los errores
/script:reset

# Para ver logs específicos
grep throatmic output.log
Contactar soporte
Si tienes problemas:
Revisa los logs del servidor (output.log)
Revisa la consola del juego (F8)
Verifica que todas las dependencias existen
Comprueba permisos de carpetas
Intenta con una base de datos nueva (test)
¡Listo! Tu sistema Throat Mic Pro está instalado y funcionando.
Para más información, consulta el README.md incluido.
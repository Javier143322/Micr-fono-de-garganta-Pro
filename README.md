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
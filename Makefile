# Makefile para gestión de PM2 con Nuxt Webnovawp

# Variables
APP_NAME = Nuxt-Webnovawp
ECOSYSTEM_FILE = ecosystem.config.cjs

# Comandos principales
.PHONY: start status logs restart stop delete startup save help

# Iniciar la aplicación
start:
	pm2 start $(ECOSYSTEM_FILE)

# Listar todas las aplicaciones PM2
status:
	pm2 ls

# Ver logs de la aplicación
logs:
	pm2 logs $(APP_NAME)

# Reiniciar la aplicación
restart:
	pm2 restart $(APP_NAME)

# Detener la aplicación
stop:
	pm2 stop $(APP_NAME)

# Eliminar la aplicación de PM2
delete:
	pm2 delete $(APP_NAME)

# Configurar PM2 para iniciar automáticamente al arrancar el sistema
startup:
	pm2 startup

# Guardar la configuración actual de PM2
save:
	pm2 save

# Mostrar ayuda
help:
	@echo "Comandos disponibles:"
	@echo "  make start     - Iniciar la aplicación con PM2"
	@echo "  make status    - Listar todas las aplicaciones PM2"
	@echo "  make logs      - Ver logs de la aplicación"
	@echo "  make restart   - Reiniciar la aplicación"
	@echo "  make stop      - Detener la aplicación"
	@echo "  make delete    - Eliminar la aplicación de PM2"
	@echo "  make startup   - Configurar PM2 para auto-inicio"
	@echo "  make save      - Guardar configuración actual de PM2"
	@echo "  make help      - Mostrar esta ayuda"

# Comando por defecto
.DEFAULT_GOAL := help

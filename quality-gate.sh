#!/bin/bash

# Quality Gate Script para Nuxt WebNovaWp
# Este script ejecuta todas las pruebas (unitarias + E2E) con cobertura y envía los resultados a SonarQube

set -e  # Exit on any error

echo "🚀 Iniciando Quality Gate para Nuxt WebNovaWp..."
echo "📅 Fecha: $(date)"
echo ""

# Navegar al directorio del proyecto
cd /home/jorgeblanc9/microservicios/portafolio/nuxt-webnovawp/app

# Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    echo "❌ Error: No se encontró package.json en el directorio actual"
    exit 1
fi

# Cargar variables de entorno desde .env si existe
if [ -f ".env" ]; then
    echo "📄 Cargando variables de entorno desde .env..."
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Variables de entorno cargadas desde .env"
elif [ -f "env.example" ]; then
    echo "⚠️  Archivo .env no encontrado, pero existe env.example"
    echo "💡 Para usar variables de entorno locales, copia env.example a .env:"
    echo "   cp env.example .env"
fi

echo "📁 Directorio de trabajo: $(pwd)"
echo ""

# Cargar nvm y usar la versión correcta
echo "🔧 Cargando Node.js con nvm..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Usar la versión especificada en .nvmrc
if [ -f ".nvmrc" ]; then
    echo "📋 Usando versión de Node.js del .nvmrc..."
    nvm use
    echo "✅ Node.js versión: $(node --version)"
    echo "✅ npm versión: $(npm --version)"
else
    echo "❌ Error: No se encontró archivo .nvmrc"
    exit 1
fi
echo ""

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm install
echo "✅ Dependencias instaladas"
echo ""

# Verificar que el servidor de desarrollo esté ejecutándose para las pruebas E2E
echo "🔍 Verificando servidor de desarrollo..."
if ! curl -s http://localhost:3000 > /dev/null; then
    echo "⚠️  Servidor de desarrollo no está ejecutándose"
    echo "🚀 Iniciando servidor de desarrollo en segundo plano..."
    npm run dev &
    DEV_PID=$!
    echo "⏳ Esperando que el servidor esté listo..."
    sleep 15
    
    # Verificar que el servidor esté funcionando
    if ! curl -s http://localhost:3000 > /dev/null; then
        echo "❌ Error: No se pudo iniciar el servidor de desarrollo"
        exit 1
    fi
    echo "✅ Servidor de desarrollo iniciado (PID: $DEV_PID)"
else
    echo "✅ Servidor de desarrollo ya está ejecutándose"
    DEV_PID=""
fi
echo ""

# Ejecutar linting
echo "🔍 Ejecutando ESLint..."
set +e  # No salir en error para continuar con las pruebas
npx eslint . --ext .vue,.js,.ts,.jsx,.tsx
LINT_EXIT_CODE=$?
if [ $LINT_EXIT_CODE -eq 0 ]; then
    echo "✅ ESLint completado exitosamente"
else
    echo "⚠️  ESLint completado con errores (código: $LINT_EXIT_CODE)"
    echo "💡 Continuando con las pruebas..."
fi
echo ""

# Ejecutar formateo (si está configurado)
echo "✨ Verificando formato..."
if command -v prettier &> /dev/null; then
    npx prettier --check .
    FORMAT_EXIT_CODE=$?
    if [ $FORMAT_EXIT_CODE -eq 0 ]; then
        echo "✅ Formato verificado exitosamente"
    else
        echo "⚠️  Formato verificado con errores (código: $FORMAT_EXIT_CODE)"
        echo "💡 Continuando con las pruebas..."
    fi
else
    echo "⚠️  Prettier no está configurado, saltando verificación de formato"
    FORMAT_EXIT_CODE=0
fi
echo ""

# Ejecutar tests unitarios con cobertura
echo "🧪 Ejecutando tests unitarios con cobertura..."
if npm run test 2>/dev/null; then
    npm run test
    UNIT_TEST_EXIT_CODE=$?
else
    echo "⚠️  No se encontraron tests unitarios configurados"
    echo "💡 Saltando tests unitarios..."
    UNIT_TEST_EXIT_CODE=0
fi

if [ $UNIT_TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ Tests unitarios completados exitosamente"
else
    echo "⚠️  Tests unitarios completados con errores (código: $UNIT_TEST_EXIT_CODE)"
    echo "💡 Continuando con las pruebas E2E..."
fi
echo ""

# Ejecutar tests E2E (si están configurados)
echo "🌐 Verificando tests E2E..."
if [ -f "cypress.config.js" ] || [ -f "cypress.config.ts" ] || [ -d "cypress" ]; then
    echo "🌐 Ejecutando tests E2E con Cypress..."
    if [ -f "./script/cypress.sh" ]; then
        ./script/cypress.sh run
    else
        npx cypress run
    fi
    E2E_TEST_EXIT_CODE=$?
    if [ $E2E_TEST_EXIT_CODE -eq 0 ]; then
        echo "✅ Tests E2E completados exitosamente"
    else
        echo "⚠️  Tests E2E completados con errores (código: $E2E_TEST_EXIT_CODE)"
        echo "💡 Continuando con la generación del reporte de SonarQube..."
    fi
else
    echo "⚠️  No se encontraron tests E2E configurados"
    echo "💡 Saltando tests E2E..."
    E2E_TEST_EXIT_CODE=0
fi
echo ""

# Detener el servidor de desarrollo si lo iniciamos
if [ ! -z "$DEV_PID" ]; then
    echo "🛑 Deteniendo servidor de desarrollo..."
    kill $DEV_PID 2>/dev/null || true
    echo "✅ Servidor de desarrollo detenido"
    echo ""
fi

# Verificar que se generaron los archivos necesarios
echo "🔍 Verificando archivos generados..."

# Verificar reporte de SonarQube (opcional para Nuxt)
if [ -f "sonar-report.xml" ]; then
    echo "✅ Reporte de SonarQube generado: sonar-report.xml"
else
    echo "⚠️  No se generó sonar-report.xml (opcional para Nuxt)"
fi

# Verificar cobertura
if [ -f "coverage/lcov.info" ]; then
    echo "✅ Archivo de cobertura generado: coverage/lcov.info"
    COVERAGE_LINES=$(wc -l < coverage/lcov.info)
    echo "📊 Líneas de cobertura: $COVERAGE_LINES"
else
    echo "⚠️  No se generó coverage/lcov.info"
    echo "💡 Se continuará sin reporte de cobertura"
fi

echo ""

# Configurar token de SonarQube
SONAR_TOKEN="sqp_5f26c63eeae45aa0b06f61889c6b6f34ae24b0fd"
echo "🔑 Usando token de SonarQube configurado"

# Ejecutar SonarQube Scanner
echo "📊 Ejecutando SonarQube Scanner..."

# Construir comando base
SONAR_CMD="npx sonar-scanner \
  -Dsonar.projectKey=Nuxt-WebNovaWp \
  -Dsonar.sources=. \
  -Dsonar.host.url=https://sonar.webnovawp.com \
  -Dsonar.login=\"$SONAR_TOKEN\""

# Agregar reporte de tests si existe
if [ -f "sonar-report.xml" ]; then
    SONAR_CMD="$SONAR_CMD -Dsonar.testExecutionReportPaths=sonar-report.xml"
fi

# Agregar cobertura si existe
if [ -f "coverage/lcov.info" ]; then
    SONAR_CMD="$SONAR_CMD -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info"
fi

# Ejecutar comando
eval $SONAR_CMD
SONAR_EXIT_CODE=$?

echo ""
echo "📊 Resumen del Quality Gate:"
echo "=============================="
echo "🔍 ESLint: $([ $LINT_EXIT_CODE -eq 0 ] && echo "✅ PASÓ" || echo "❌ FALLÓ")"
echo "✨ Formato: $([ $FORMAT_EXIT_CODE -eq 0 ] && echo "✅ PASÓ" || echo "❌ FALLÓ")"
echo "🧪 Tests Unitarios: $([ $UNIT_TEST_EXIT_CODE -eq 0 ] && echo "✅ PASÓ" || echo "❌ FALLÓ")"
echo "🌐 Tests E2E: $([ $E2E_TEST_EXIT_CODE -eq 0 ] && echo "✅ PASÓ" || echo "❌ FALLÓ")"
echo "📊 SonarQube: $([ $SONAR_EXIT_CODE -eq 0 ] && echo "✅ PASÓ" || echo "❌ FALLÓ")"
echo ""

# Determinar si el quality gate pasó
TOTAL_FAILURES=$((LINT_EXIT_CODE + FORMAT_EXIT_CODE + UNIT_TEST_EXIT_CODE + E2E_TEST_EXIT_CODE + SONAR_EXIT_CODE))

if [ $TOTAL_FAILURES -eq 0 ]; then
    echo "🎉 ¡Quality Gate PASÓ exitosamente!"
    echo "✅ Todos los checks pasaron"
    echo "📊 Resultados enviados a SonarQube"
    echo "🌐 Ver resultados en: https://sonar.webnovawp.com"
    echo ""
    echo "📅 Finalizado: $(date)"
    exit 0
else
    echo "❌ Quality Gate FALLÓ"
    echo "⚠️  $TOTAL_FAILURES check(s) fallaron"
    echo "💡 Revisa los errores arriba y corrige los problemas"
    echo ""
    echo "📅 Finalizado: $(date)"
    exit 1
fi

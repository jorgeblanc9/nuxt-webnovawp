export default {
  apps: [
    {
      name: "Nuxt-Webnovawp", // Nombre que verás en `pm2 ls`
      exec_mode: "cluster", // Recomendado: para aprovechar múltiples núcleos de CPU
      instances: "max", // Usa todos los núcleos disponibles, o puedes poner un número específico como 4
      script: "./.output/server/index.mjs", // El script de inicio de producción de Nuxt 3
      env: {
        NODE_ENV: "production",
        // Puedes añadir aquí otras variables de entorno
      },
      // Configuraciones de rendimiento y estabilidad
      max_memory_restart: "500M", // Reinicia si usa más de 500MB
      min_uptime: "10s", // Tiempo mínimo antes de considerar que la app está estable
      max_restarts: 5, // Máximo 5 reinicios en 1 minuto
      restart_delay: 4000, // Espera 4 segundos entre reinicios
      // Si quieres usar un puerto específico diferente al 3000
      port: 3999
    },
  ],
};

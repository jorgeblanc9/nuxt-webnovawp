export default {
  apps: [
    {
      name: "Nuxt-Webnovawp", // Nombre que verás en `pm2 ls`
      exec_mode: "cluster", // Recomendado: para aprovechar múltiples núcleos de CPU
      instances: "max", // Elige 'max' para usar tantos núcleos como sea posible, o un número específico
      script: "./.output/server/index.mjs", // El script de inicio de producción de Nuxt 3
      env: {
        NODE_ENV: "production",
        // Puedes añadir aquí otras variables de entorno
      },
      // Si quieres usar un puerto específico diferente al 3000
      port: 3999
    },
  ],
};

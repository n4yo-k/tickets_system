# Sistema de Tickets - Despliegue en Vercel

## Pasos para desplegar en Vercel

### 1. **Preparar el repositorio Git**
```bash
git add .
git commit -m "Preparar para Vercel"
git push origin rama-mauri
```

### 2. **Conectar a Vercel**

#### Opción A: Usando Vercel CLI
```bash
# Instalar Vercel CLI
npm i -g vercel

# Desplegar
vercel
```

#### Opción B: Desde el Dashboard de Vercel
1. Ve a https://vercel.com
2. Inicia sesión con tu cuenta (GitHub, GitLab, Bitbucket, etc.)
3. Haz clic en "New Project"
4. Selecciona tu repositorio `tickets_system`
5. Vercel detectará automáticamente que es un proyecto Flutter
6. Haz clic en "Deploy"

### 3. **Variables de Entorno (si es necesario)**
En el dashboard de Vercel, ve a **Settings → Environment Variables** y añade:
```
SUPABASE_URL=https://pbdmcbxpqdwndsntwicn.supabase.co
SUPABASE_ANON_KEY=tu_clave_publica
```

### 4. **Configuración de Dominio**
Una vez desplegado:
- Vercel te proporciona una URL automática (ej: tickets-system.vercel.app)
- Puedes conectar un dominio personalizado en **Settings → Domains**

## Estructura del Proyecto
```
tickets_system/
├── build/
│   └── web/                    # Compilación web (generada)
├── lib/
│   ├── main.dart
│   ├── screens/               # Pantallas de la app
│   ├── services/              # Servicios (API, Auth)
│   ├── models/                # Modelos de datos
│   └── utils/                 # Utilidades
├── vercel.json                # Configuración de Vercel
├── .vercelignore              # Archivos a ignorar
└── pubspec.yaml               # Dependencias de Flutter
```

## Requisitos
- Flutter SDK (instalado automáticamente por Vercel)
- Git
- Cuenta en Vercel

## URLs Importantes
- **Dashboard Vercel**: https://vercel.com/dashboard
- **Proyecto Tickets System**: (será generada después de desplegar)
- **Backend (Supabase)**: https://app.supabase.com

## Troubleshooting

### Error: "Flutter not found"
Vercel puede que no reconozca Flutter. En ese caso:
1. Ve a **Settings → Build & Development Settings**
2. Build Command: `bash build.sh`
3. Output Directory: `build/web`

### Error: "CORS"
Si tienes problemas con CORS desde Supabase:
1. Ve a Supabase Dashboard
2. Settings → API Settings
3. Añade tu dominio de Vercel a "URL allow list"

### Error: "Out of Memory"
Si Vercel se queda sin memoria durante el build:
1. Reduce el tamaño de `build/web` eliminando `build/` del repositorio
2. Usa `.gitignore` para excluir la carpeta `build/`

## Monitoreo
Una vez desplegado:
- Vercel proporciona logs en tiempo real
- Puedes ver métricas de performance
- Configurar alertas y notificaciones

## Próximos Pasos
Después del despliegue:
1. Prueba la app en la URL proporcionada por Vercel
2. Verifica que Supabase está conectando correctamente
3. Configura un dominio personalizado (opcional)
4. Configura CI/CD para deployments automáticos con cada push

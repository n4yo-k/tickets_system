# Sistema de Tickets y Soporte Técnico

Sistema de gestión de tickets construido con Flutter y Supabase.

## Configuración Inicial

### 1. Crear un proyecto en Supabase

1. Ir a [https://supabase.com](https://supabase.com)
2. Crear una nueva cuenta o iniciar sesión
3. Crear un nuevo proyecto
4. Copiar las credenciales:
   - **URL del proyecto**: `https://xxxxx.supabase.co`
   - **Anon Key**: (key pública para cliente)

### 2. Configurar variables de entorno

Crear un archivo `.env` en la raíz del proyecto con:

```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
```

### 3. Crear tablas en Supabase

En el SQL Editor de Supabase, ejecutar:

```sql
-- Tabla de usuarios (se crea automáticamente con Supabase Auth)
-- Tabla de tickets
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'abierto',
  priority TEXT DEFAULT 'media',
  assigned_to UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de comentarios
CREATE TABLE ticket_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Características Implementadas

### HU1 - Registro de Usuario ✅
- Crear cuenta con correo y contraseña
- Validación de contraseña mínima (6 caracteres)
- Verificación de correo duplicado
- Mensajes de éxito/error claros

### HU2 - Inicio de Sesión ✅
- Iniciar sesión con credenciales
- Validación de credenciales
- Indicador de cargando
- Redirección automática al Home

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   └── home_screen.dart
├── services/
│   └── auth_service.dart     # Servicio de autenticación
└── models/                   # Modelos de datos (próximamente)
```

## Cómo ejecutar

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en desarrollo
flutter run
```

## Próximas Funcionalidades

- [ ] Crear tickets
- [ ] Listar tickets del usuario
- [ ] Panel técnico
- [ ] Dashboard de admin
- [ ] Comentarios en tickets
- [ ] Notificaciones

## Tecnologías

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL + Auth)
- **Autenticación**: Supabase Auth

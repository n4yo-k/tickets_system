# Configuración de Supabase Storage

## Crear Bucket para Imágenes de Tickets

Para que funcione la funcionalidad de subir imágenes a los tickets, necesitas crear un bucket en Supabase Storage.

### Pasos:

1. **Acceder a Supabase Dashboard**
   - Ve a: https://supabase.com/dashboard
   - Selecciona tu proyecto: "sistema-tickets"

2. **Ir a Storage**
   - En el menú izquierdo, haz clic en "Storage"
   - Haz clic en "Create a new bucket"

3. **Crear Bucket**
   - **Nombre del bucket**: `ticket-images`
   - **Public bucket**: ✓ Marcado (para que las imágenes sean públicamente accesibles)
   - Haz clic en "Create bucket"

4. **Configurar Políticas de Seguridad (opcional pero recomendado)**
   - Dentro del bucket `ticket-images`, ve a "Policies"
   - Asegúrate de que los usuarios autenticados puedan:
     - **INSERT**: Para subir imágenes
     - **SELECT**: Para leer imágenes públicas

### Estructura de Carpetas

Las imágenes se suben automáticamente con la siguiente estructura:
```
ticket-images/
└── {user_id}/
    ├── {timestamp1}.jpg
    ├── {timestamp2}.jpg
    └── ...
```

### Verificación

Una vez creado el bucket, la aplicación podrá:
1. Seleccionar imágenes desde la galería
2. Subirlas automáticamente al crear un ticket
3. Mostrar las imágenes en la pantalla de detalles del ticket

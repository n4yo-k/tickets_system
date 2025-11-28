# Configuración de RLS para Supabase Storage

## Error: "new row violates row-level security policy"

Si recibiste este error al intentar subir una imagen, necesitas configurar las políticas de seguridad (RLS) en el bucket de Storage.

## Solución: Configurar Políticas RLS

### Paso 1: Acceder al Dashboard de Supabase
1. Ve a: https://supabase.com/dashboard
2. Selecciona tu proyecto: **sistema-tickets**

### Paso 2: Ir a Storage y Seleccionar el Bucket
1. En el menú izquierdo, haz clic en **Storage**
2. Haz clic en el bucket **ticket-images**

### Paso 3: Configurar Políticas

#### Opción A: Interfaz Visual (Recomendado - Simple)

1. Dentro del bucket `ticket-images`, ve a la pestaña **Policies**
2. Haz clic en **Create policy**
3. Selecciona: **For inserting (INSERT)**
4. Selecciona: **Using service role or postgres role**
5. Haz clic en **Review** y luego **Save policy**

Repite para **SELECT** (para leer imágenes):
1. **Create policy**
2. Selecciona: **For querying (SELECT)**
3. Selecciona: **Using service role or postgres role**
4. **Review** → **Save policy**

#### Opción B: SQL Personalizado (Avanzado)

Si tienes acceso al editor SQL, ejecuta estas queries:

```sql
-- Permitir INSERT para usuarios autenticados
CREATE POLICY "Allow authenticated users to upload images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'ticket-images');

-- Permitir SELECT para todos (imágenes públicas)
CREATE POLICY "Allow public read access to images"
ON storage.objects FOR SELECT
USING (bucket_id = 'ticket-images');
```

### Paso 4: Verificar que el Bucket es Público

1. En Storage → **ticket-images**
2. Haz clic en los **⋮ (three dots)** 
3. Selecciona **Edit bucket**
4. Asegúrate de que está habilitado: **Public bucket** ✓
5. Haz clic en **Save**

## Verificación

Después de configurar las políticas:
1. Vuelve a la app Flutter
2. Intenta crear un ticket con imagen
3. Debería subirse exitosamente

## Si Aún No Funciona

### Checklist:

- [ ] ¿El bucket `ticket-images` existe?
- [ ] ¿El bucket está marcado como **Public**?
- [ ] ¿Las políticas RLS están creadas?
- [ ] ¿Hiciste clic en **Refresh** en la app?
- [ ] ¿Ejecutaste `flutter pub get` nuevamente?
- [ ] ¿El usuario está autenticado?

### Debug: Prueba Manual en SQL Editor

1. Ve a **SQL Editor** en el dashboard
2. Ejecuta:

```sql
SELECT * FROM storage.buckets WHERE name = 'ticket-images';
```

Deberías ver el bucket con `public: true`

```sql
SELECT * FROM storage.objects WHERE bucket_id = 'ticket-images' LIMIT 5;
```

Si hay archivos aquí, significa que el upload está funcionando.

---

**Nota:** Las políticas RLS son esenciales para la seguridad. Sin ellas, nadie puede leer/escribir en el bucket, incluso si está marcado como público.

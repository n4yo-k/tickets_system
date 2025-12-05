-- ============================================
-- SOLUCIÓN: Arreglar Foreign Key de assigned_to
-- ============================================
-- El problema: assigned_to apunta a "users" pero debería apuntar a "technicians"
-- Ejecuta ESTO en el SQL Editor de Supabase

-- 1. Ver la restricción actual
SELECT constraint_name, table_name, column_name 
FROM information_schema.constraint_column_usage 
WHERE table_name='tickets' AND column_name='assigned_to';

-- 2. ELIMINAR la restricción anterior
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS tickets_assigned_to_fkey;

-- 3. CREAR la restricción correcta (assigned_to -> technicians.id)
ALTER TABLE tickets 
ADD CONSTRAINT tickets_assigned_to_fkey 
FOREIGN KEY (assigned_to) 
REFERENCES technicians(id) 
ON DELETE SET NULL;

-- 4. Verificación
SELECT constraint_name, table_name, column_name 
FROM information_schema.constraint_column_usage 
WHERE table_name='tickets' AND column_name='assigned_to';

-- Deberías ver: tickets_assigned_to_fkey | tickets | assigned_to

-- ============================================
-- SOLUCIÓN: Políticas RLS para tabla tickets
-- ============================================
-- Este archivo contiene las políticas correctas para que el admin pueda asignar tickets
-- Ejecuta esto en el SQL Editor de Supabase Dashboard

-- 1. PRIMERO: Ver políticas existentes
SELECT * FROM pg_policies WHERE tablename = 'tickets';

-- 2. ELIMINAR políticas que pueden estar bloqueando
DROP POLICY IF EXISTS "Users can view their own tickets" ON tickets;
DROP POLICY IF EXISTS "Users can view tickets" ON tickets;
DROP POLICY IF EXISTS "Users can insert tickets" ON tickets;
DROP POLICY IF EXISTS "Users can update their own tickets" ON tickets;
DROP POLICY IF EXISTS "Admin can view all tickets" ON tickets;
DROP POLICY IF EXISTS "Admin can update tickets" ON tickets;

-- 3. CREAR nuevas políticas correctas

-- Política 1: SELECT - Usuarios ven sus propios tickets O asignaciones
CREATE POLICY "Users can view tickets"
ON tickets FOR SELECT
USING (
  -- Usuario propietario del ticket
  auth.uid() = user_id
  OR
  -- Técnico al que está asignado el ticket
  assigned_to IN (SELECT id FROM technicians WHERE user_id = auth.uid())
  OR
  -- Admin ve todos
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Política 2: INSERT - Solo usuarios autenticados pueden crear tickets
CREATE POLICY "Users can create tickets"
ON tickets FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Política 3: UPDATE - Usuarios pueden actualizar sus propios tickets, admin puede actualizar todo
CREATE POLICY "Users and admin can update tickets"
ON tickets FOR UPDATE
USING (
  -- Usuario propietario del ticket
  auth.uid() = user_id
  OR
  -- Admin puede actualizar cualquier ticket (incluyendo assigned_to)
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
)
WITH CHECK (
  auth.uid() = user_id
  OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Política 4: DELETE - Solo admin puede eliminar
CREATE POLICY "Admin can delete tickets"
ON tickets FOR DELETE
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================
-- Verificación
-- ============================================

-- Ejecuta esto para verificar que las políticas están correctas:
SELECT * FROM pg_policies WHERE tablename = 'tickets';

-- Deberías ver 4 políticas:
-- 1. Users can view tickets
-- 2. Users can create tickets
-- 3. Users and admin can update tickets
-- 4. Admin can delete tickets

-- ============================================
-- Prueba Manual (opcional)
-- ============================================

-- Para probar que funciona:
-- 1. Ve a la app y intenta asignar un ticket como admin
-- 2. Cambiate al técnico y verifica que aparezca el ticket


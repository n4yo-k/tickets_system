-- ============================================
-- FUNCIÓN RPC: Actualizar estado del ticket
-- ============================================
-- Esta función permite que los técnicos actualicen el estado de sus tickets
-- Ejecuta ESTO en el SQL Editor de Supabase

-- 1. CREAR FUNCIÓN RPC
CREATE OR REPLACE FUNCTION update_ticket_status(
  p_ticket_id UUID,
  p_new_status TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
BEGIN
  -- Verificar que el usuario está autenticado
  IF auth.uid() IS NULL THEN
    RETURN QUERY SELECT FALSE::BOOLEAN, 'User not authenticated'::TEXT;
    RETURN;
  END IF;

  -- Verificar que el técnico está asignado a este ticket O es admin
  IF NOT EXISTS (
    SELECT 1 FROM tickets
    WHERE id = p_ticket_id AND (
      -- El técnico está asignado al ticket
      assigned_to IN (SELECT id FROM technicians WHERE user_id = auth.uid())
      OR
      -- O el usuario es admin
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    )
  ) THEN
    RETURN QUERY SELECT FALSE::BOOLEAN, 'Not authorized to update this ticket'::TEXT;
    RETURN;
  END IF;

  -- Actualizar el estado del ticket
  UPDATE tickets 
  SET status = p_new_status,
      updated_at = NOW()
  WHERE id = p_ticket_id;

  -- Verificar que se actualizó
  IF FOUND THEN
    RETURN QUERY SELECT TRUE::BOOLEAN, 'Ticket status updated successfully'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE::BOOLEAN, 'Ticket not found'::TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. GRANT permisos a usuarios autenticados
GRANT EXECUTE ON FUNCTION update_ticket_status(UUID, TEXT) TO authenticated;

-- 3. Verificación
SELECT EXISTS(
  SELECT 1 FROM pg_proc 
  WHERE proname = 'update_ticket_status'
) AS "Función creada correctamente";

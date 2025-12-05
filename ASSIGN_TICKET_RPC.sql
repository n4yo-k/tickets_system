-- ============================================
-- SOLUCIÓN: Función RPC para asignar tickets
-- ============================================
-- Esta función crea una ruta segura para que el admin asigne tickets
-- Ejecuta ESTO en el SQL Editor de Supabase

-- 1. CREAR FUNCIÓN RPC
CREATE OR REPLACE FUNCTION assign_ticket_to_technician(
  p_ticket_id UUID,
  p_technician_id UUID
)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
BEGIN
  -- Verificar que el usuario es admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN QUERY SELECT FALSE::BOOLEAN, 'Only admins can assign tickets'::TEXT;
    RETURN;
  END IF;

  -- Actualizar el ticket
  UPDATE tickets 
  SET assigned_to = p_technician_id,
      updated_at = NOW()
  WHERE id = p_ticket_id;

  -- Verificar que se actualizó
  IF FOUND THEN
    RETURN QUERY SELECT TRUE::BOOLEAN, 'Ticket assigned successfully'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE::BOOLEAN, 'Ticket not found'::TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. GRANT permisos a usuarios autenticados
GRANT EXECUTE ON FUNCTION assign_ticket_to_technician(UUID, UUID) TO authenticated;

-- 3. Verificación
SELECT EXISTS(
  SELECT 1 FROM pg_proc 
  WHERE proname = 'assign_ticket_to_technician'
) AS "Función creada correctamente";

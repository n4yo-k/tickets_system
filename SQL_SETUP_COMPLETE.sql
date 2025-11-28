-- ============================================
-- HU5 - HU6: SETUP COMPLETO
-- ============================================

-- 1. Crear tabla ticket_history
CREATE TABLE IF NOT EXISTS ticket_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ticket_history_ticket_id ON ticket_history(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_history_user_id ON ticket_history(user_id);

ALTER TABLE ticket_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view ticket history" ON ticket_history
FOR SELECT USING (true);

CREATE POLICY "System can insert history" ON ticket_history
FOR INSERT WITH CHECK (true);

-- 2. Crear tabla technicians
CREATE TABLE IF NOT EXISTS technicians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  specialization TEXT DEFAULT 'general',
  status TEXT DEFAULT 'activo',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technicians_user_id ON technicians(user_id);
CREATE INDEX IF NOT EXISTS idx_technicians_status ON technicians(status);

ALTER TABLE technicians ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Technicians can view their info" ON technicians
FOR SELECT USING (true);

-- 3. Agregar columna role a profiles si no existe
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- 4. Actualizar tabla tickets
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES technicians(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_tickets_assigned_to ON tickets(assigned_to);

-- 5. Actualizar RLS para tickets - permitir ver assigned tickets
DROP POLICY IF EXISTS "Users can view their own tickets" ON tickets;

CREATE POLICY "Users can view tickets" ON tickets
FOR SELECT USING (
  auth.uid() = user_id OR
  assigned_to IN (SELECT id FROM technicians WHERE user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Listo!

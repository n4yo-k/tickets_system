import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';
import '../../services/ticket_service.dart';
import '../../services/ticket_history_service.dart';
import '../../models/ticket.dart';
import '../../models/technician.dart';
import '../../utils/theme_utils.dart';

class AdminScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const AdminScreen({this.onLogout, super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late AdminService _adminService;
  late TicketService _ticketService;
  late TicketHistoryService _historyService;
  
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(Supabase.instance.client);
    _ticketService = TicketService(Supabase.instance.client);
    _historyService = TicketHistoryService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: ThemeUtils.primaryGradient,
          ),
        ),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: widget.onLogout,
              tooltip: 'Cerrar sesión',
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          _buildAssignmentPanel(),
          _buildTicketsPanel(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_ind),
            label: 'Asignar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tickets',
          ),
        ],
      ),
    );
  }

  // Dashboard: Estadísticas
  Widget _buildDashboard() {
    return FutureBuilder<List<Ticket>>(
      future: _ticketService.getAllTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tickets = snapshot.data ?? [];
        
        final pendingCount = tickets.where((t) => t.status == 'abierto').length;
        final inProgressCount = tickets.where((t) => t.status == 'en_progreso').length;
        final resolvedCount = tickets.where((t) => t.status == 'cerrado').length;
        final unassignedCount = tickets.where((t) => t.status == 'abierto').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen General',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // Stats Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard('Total Tickets', tickets.length.toString(), Colors.blue),
                  _buildStatCard('Abiertos', pendingCount.toString(), Colors.orange),
                  _buildStatCard('En Progreso', inProgressCount.toString(), Colors.purple),
                  _buildStatCard('Resueltos', resolvedCount.toString(), Colors.green),
                  _buildStatCard('Sin Asignar', unassignedCount.toString(), Colors.red),
                  _buildStatCard('% Resueltos', 
                    '${(resolvedCount / (tickets.isEmpty ? 1 : tickets.length) * 100).toStringAsFixed(1)}%', 
                    Colors.teal
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Actividad Reciente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // Últimos tickets
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tickets.take(5).length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(ticket.title),
                      subtitle: Text('${ticket.category} • ${ticket.priority}'),
                      trailing: Chip(
                        label: Text(ticket.status),
                        backgroundColor: _getStatusColor(ticket.status),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Panel de Asignación
  Widget _buildAssignmentPanel() {
    return FutureBuilder<List<Ticket>>(
      future: _ticketService.getUnassignedTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final unassignedTickets = snapshot.data ?? [];

        if (unassignedTickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
                const SizedBox(height: 16),
                const Text('¡Todos los tickets están asignados!'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: unassignedTickets.length,
          itemBuilder: (context, index) {
            final ticket = unassignedTickets[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(ticket.title),
                subtitle: Text(ticket.description),
                trailing: ElevatedButton(
                  onPressed: () => _showAssignDialog(ticket),
                  child: const Text('Asignar'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Todos los tickets
  Widget _buildTicketsPanel() {
    return FutureBuilder<List<Ticket>>(
      future: _ticketService.getAllTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tickets = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(ticket.title),
                subtitle: Text('${ticket.category} • ${ticket.priority}'),
                trailing: Chip(
                  label: Text(ticket.status),
                  backgroundColor: _getStatusColor(ticket.status),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Dialog de asignación
  void _showAssignDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar Ticket'),
        content: FutureBuilder<List<Technician>>(
          future: _adminService.getActiveTechnicians(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            final technicians = snapshot.data ?? [];

            if (technicians.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  const Text('No hay técnicos disponibles'),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor, crea un técnico primero',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: technicians.length,
                itemBuilder: (context, index) {
                  final tech = technicians[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(tech.fullName),
                    subtitle: Text(tech.email),
                    trailing: Text(
                      tech.specialization ?? 'General',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () async {
                      try {
                        Navigator.pop(context);
                        await _adminService.assignTicketToTechnician(
                          ticketId: ticket.id,
                          technicianId: tech.id,
                        );
                        
                        await _historyService.recordAssignment(
                          ticketId: ticket.id,
                          technicianId: tech.id,
                        );

                        setState(() {});

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ticket asignado a ${tech.fullName}',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Helper: Stat Card
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'abierto':
        return Colors.orange;
      case 'en_progreso':
        return Colors.blue;
      case 'cerrado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

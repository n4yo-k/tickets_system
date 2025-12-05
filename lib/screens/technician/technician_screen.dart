import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket.dart';
import '../../utils/theme_utils.dart';
import 'update_status_screen.dart';

class TechnicianScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const TechnicianScreen({this.onLogout, super.key});

  @override
  State<TechnicianScreen> createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen> {
  late TicketService _ticketService;
  String _selectedFilter = 'todos'; // todos, abierto, en_progreso, cerrado

  @override
  void initState() {
    super.initState();
    _ticketService = TicketService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Técnico'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: ThemeUtils.primaryGradient),
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
      body: StreamBuilder<List<Ticket>>(
        stream: _buildTechnicianTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var allTickets = snapshot.data ?? [];

          // Contar tickets por estado
          final totalAssigned = allTickets.length;
          final inProgress = allTickets
              .where((t) => t.status == 'en_progreso')
              .length;

          // Aplicar filtro
          if (_selectedFilter != 'todos') {
            allTickets = allTickets
                .where((t) => t.status == _selectedFilter)
                .toList();
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Tarjetas de estado
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          title: 'Total Asignados',
                          count: totalAssigned,
                          icon: Icons.assignment,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          title: 'En Progreso',
                          count: inProgress,
                          icon: Icons.hourglass_bottom,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'todos',
                        'Todos',
                        snapshot.data?.length ?? 0,
                      ),
                      _buildFilterChip(
                        'abierto',
                        'Abiertos',
                        snapshot.data
                                ?.where((t) => t.status == 'abierto')
                                .length ??
                            0,
                      ),
                      _buildFilterChip(
                        'en_progreso',
                        'En Progreso',
                        inProgress,
                      ),
                      _buildFilterChip(
                        'cerrado',
                        'Resueltos',
                        snapshot.data
                                ?.where((t) => t.status == 'cerrado')
                                .length ??
                            0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Lista de tickets
                if (allTickets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text('No hay tickets en esta categoría'),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = allTickets[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTicketCard(ticket),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return GestureDetector(
      onTap: () => _openTicketDetail(ticket),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cliente: ${ticket.userId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          ticket.status,
                        ).withValues(alpha: 0.1),
                        border: Border.all(
                          color: _getStatusColor(ticket.status),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(ticket.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          ticket.priority,
                        ).withValues(alpha: 0.2),
                        border: Border.all(
                          color: _getPriorityColor(ticket.priority),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.priority,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPriorityColor(ticket.priority),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        backgroundColor: isSelected ? Colors.blue.shade50 : Colors.white,
        selectedColor: Colors.blue.shade100,
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
    );
  }

  void _openTicketDetail(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            AppBar(
              title: Text(ticket.title),
              centerTitle: true,
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del cliente
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Cliente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${ticket.userId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Estado actual
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          ticket.status,
                        ).withValues(alpha: 0.1),
                        border: Border.all(
                          color: _getStatusColor(ticket.status),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estado: ${ticket.status.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(ticket.status),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UpdateStatusScreen(ticket: ticket),
                                ),
                              );
                            },
                            child: const Text('Cambiar Estado'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Detalles
                    _buildDetailRow('Categoría', ticket.category),
                    _buildDetailRow('Prioridad', ticket.priority),
                    _buildDetailRow(
                      'Creado',
                      '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Descripción',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(ticket.description),
                    ),
                    if (ticket.imageUrl != null &&
                        ticket.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Adjunto',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Mostrar imagen
                      Image.network(
                        _buildImageUrl(ticket.imageUrl!),
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _buildImageUrl(String fileName) {
    const supabaseUrl = 'https://pbdmcbxpqdwndsntwicn.supabase.co';
    const bucketName = 'ticket-images';
    return '$supabaseUrl/storage/v1/object/public/$bucketName/$fileName';
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'baja':
        return Colors.green;
      case 'media':
        return Colors.orange;
      case 'alta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Stream para obtener tickets en tiempo real
  Stream<List<Ticket>> _buildTechnicianTicketsStream() async* {
    try {
      while (true) {
        final tickets = await _ticketService.getTechnicianTickets();
        yield tickets;
        // Actualizar cada 2 segundos
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('Error en stream de tickets: $e');
      yield [];
    }
  }
}

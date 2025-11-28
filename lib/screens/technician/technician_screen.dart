import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket.dart';
import 'update_status_screen.dart';

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});

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
      ),
      body: Column(
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterChip('todos', 'Todos'),
                _buildFilterChip('abierto', 'Abiertos'),
                _buildFilterChip('en_progreso', 'En Progreso'),
                _buildFilterChip('cerrado', 'Resueltos'),
              ],
            ),
          ),
          // Lista de tickets
          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _ticketService.getTechnicianTickets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var tickets = snapshot.data ?? [];

                // Aplicar filtro
                if (_selectedFilter != 'todos') {
                  tickets = tickets
                      .where((t) => t.status == _selectedFilter)
                      .toList();
                }

                if (tickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text('No hay tickets asignados'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(ticket.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(ticket.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(ticket.category),
                                  backgroundColor: Colors.blue.shade100,
                                  labelStyle: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 4),
                                Chip(
                                  label: Text(ticket.priority),
                                  backgroundColor: _getPriorityColor(ticket.priority),
                                  labelStyle: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(ticket.status),
                          backgroundColor: _getStatusColor(ticket.status),
                        ),
                        onTap: () => _openTicketDetail(ticket),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
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
                    // Estado actual
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status).withOpacity(0.1),
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
                    if (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Adjunto',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
}

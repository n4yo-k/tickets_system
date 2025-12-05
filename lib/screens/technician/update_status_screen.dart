import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ticket_service.dart';
import '../../services/ticket_history_service.dart';
import '../../models/ticket.dart';

class UpdateStatusScreen extends StatefulWidget {
  final Ticket ticket;

  const UpdateStatusScreen({required this.ticket, super.key});

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  late TicketService _ticketService;
  late TicketHistoryService _historyService;
  late String _selectedStatus;
  bool _isLoading = false;

  final List<String> _availableStatuses = ['abierto', 'en_progreso', 'cerrado'];

  @override
  void initState() {
    super.initState();
    _ticketService = TicketService(Supabase.instance.client);
    _historyService = TicketHistoryService(Supabase.instance.client);
    _selectedStatus = widget.ticket.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Estado'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ticket.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Estado actual: ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            widget.ticket.status,
                          ).withValues(alpha: 0.1),
                          border: Border.all(
                            color: _getStatusColor(widget.ticket.status),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.ticket.status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.ticket.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Seleccionar nuevo estado
            Text(
              'Seleccionar nuevo estado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableStatuses.length,
              itemBuilder: (context, index) {
                final status = _availableStatuses[index];
                final isSelected = _selectedStatus == status;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedStatus = status);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getStatusColor(status).withValues(alpha: 0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? _getStatusColor(status)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getStatusColor(status),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? _getStatusColor(status)
                                    : Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getStatusDescription(status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateStatus,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Actualizar Estado'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.ticket.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un estado diferente')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Actualizar estado en BD
      await _ticketService.updateTicketStatus(
        widget.ticket.id,
        _selectedStatus,
      );

      // Registrar en historial
      await _historyService.recordStatusChange(
        ticketId: widget.ticket.id,
        oldStatus: widget.ticket.status,
        newStatus: _selectedStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  String _getStatusDescription(String status) {
    switch (status) {
      case 'abierto':
        return 'Ticket nuevo y sin atender';
      case 'en_progreso':
        return 'Estás trabajando en este ticket';
      case 'cerrado':
        return 'Ticket resuelto y cerrado';
      default:
        return '';
    }
  }
}

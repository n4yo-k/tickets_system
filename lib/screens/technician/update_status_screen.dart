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
                color: Colors.grey.shade100,
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
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Estado actual: '),
                      Chip(
                        label: Text(widget.ticket.status),
                        backgroundColor: _getStatusColor(widget.ticket.status),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableStatuses.length,
              itemBuilder: (context, index) {
                final status = _availableStatuses[index];
                final isSelected = _selectedStatus == status;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    // ignore: deprecated_member_use
                    leading: Radio<String>(
                      // ignore: deprecated_member_use
                      value: status,
                      // ignore: deprecated_member_use
                      groupValue: _selectedStatus,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                    title: Text(status.toUpperCase()),
                    subtitle: Text(_getStatusDescription(status)),
                    tileColor: isSelected
                        ? _getStatusColor(status).withValues(alpha: 0.1)
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Botón guardar
            SizedBox(
              width: double.infinity,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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

import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';

class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip(this.status, {super.key});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TicketStatus.baru => Colors.blue,
      TicketStatus.diproses => Colors.orange,
      TicketStatus.selesai => Colors.green,
      TicketStatus.complete => Colors.teal,
      TicketStatus.pending => Colors.deepPurple,
      TicketStatus.batal => Colors.red,
    };

    return Chip(
      label: Text(status.dbValue),
      avatar: Icon(Icons.circle, size: 10, color: color),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
    );
  }
}

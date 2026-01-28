import 'package:flutter/material.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';

class PrinterStatusWidget extends StatelessWidget {
  const PrinterStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final printingService = getIt<PrintingService>();
    
    return ValueListenableBuilder<PrinterState>(
      valueListenable: printingService.state,
      builder: (context, state, _) {
        IconData icon;
        Color color;
        String tooltip;

        switch (state.status) {
          case PrinterStatus.connected:
            icon = Icons.print;
            color = Colors.green;
            tooltip = 'Printer Terhubung: ${state.device?.name ?? ''}';
            break;
          case PrinterStatus.connecting:
            icon = Icons.watch_later_outlined;
            color = Colors.orange;
            tooltip = 'Menyambungkan ke printer...';
            break;
          case PrinterStatus.error:
            icon = Icons.print_disabled;
            color = Colors.red;
            tooltip = 'Error Printer: ${state.errorMessage ?? 'Unknown Error'}';
            break;
          case PrinterStatus.disconnected:
          default:
            icon = Icons.print_disabled_outlined;
            color = Colors.grey;
            tooltip = 'Printer Terputus';
            break;
        }

        return Tooltip(
          message: tooltip,
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: () {
              // Navigate to printer settings page
              // This can be implemented later
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navigasi ke halaman pengaturan printer...')),
              );
            },
          ),
        );
      },
    );
  }
}

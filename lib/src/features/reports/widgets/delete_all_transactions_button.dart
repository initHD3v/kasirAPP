import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/features/reports/bloc/reports_bloc.dart';

class DeleteAllTransactionsButton extends StatelessWidget {
  const DeleteAllTransactionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthenticationAuthenticated && state.user.role == UserRole.admin) {
          return FloatingActionButton.extended(
            heroTag: 'deleteAllTransactionsFab', // Add this line
            onPressed: () => _showDeleteAllTransactionsConfirmation(context),
            label: const Text('Hapus Semua Transaksi'),
            icon: const Icon(Icons.delete_forever),
            backgroundColor: Colors.redAccent,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showDeleteAllTransactionsConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Semua Transaksi?'),
          content: const Text('Anda yakin ingin menghapus SEMUA data transaksi? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ReportsBloc>().add(DeleteAllTransactions());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
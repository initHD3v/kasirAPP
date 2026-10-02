import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/features/dashboard/bloc/reports_bloc.dart';
import 'package:kasir_app/src/features/dashboard/views/overview_view.dart';
import 'package:kasir_app/src/features/dashboard/views/reports_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const OverviewView();
      case 1:
        return const ReportsView();
      default:
        return const OverviewView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReportsBloc(getIt<TransactionRepository>()),
        ),
        // Other BLoCs for the dashboard can be added here
      ],
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // HP portrait: tab atas, bukan rail samping.
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                            value: 0,
                            label: Text('Overview'),
                            icon: Icon(Icons.widgets_outlined, size: 18)),
                        ButtonSegment(
                            value: 1,
                            label: Text('Laporan'),
                            icon: Icon(Icons.show_chart_outlined, size: 18)),
                      ],
                      selected: {_selectedIndex},
                      onSelectionChanged: (s) =>
                          setState(() => _selectedIndex = s.first),
                    ),
                  ),
                  Expanded(child: _buildBody()),
                ],
              );
            }
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.widgets_outlined),
                      selectedIcon: Icon(Icons.widgets),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.show_chart_outlined),
                      selectedIcon: Icon(Icons.show_chart),
                      label: Text('Reports'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

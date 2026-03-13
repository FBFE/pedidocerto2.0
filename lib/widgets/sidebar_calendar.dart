import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Calendário compacto para sidebar, estilo Figma (fundo escuro, grid de dias).
class SidebarCalendar extends StatefulWidget {
  const SidebarCalendar({super.key});

  @override
  State<SidebarCalendar> createState() => _SidebarCalendarState();
}

class _SidebarCalendarState extends State<SidebarCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF2D2D2D);
    const dayHeader = Color(0xFF8A8A8A);
    const dayNormal = Color(0xFFB0B0B0);
    const dayDim = Color(0xFF6A6A6A);
    const dayHighlight = Color(0xFF3D3D3D);

    final first = DateTime(_currentMonth.year, _currentMonth.month);
    final last = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    // Coluna 0 = Domingo (weekday 7 em Dart)
    final startWeekday = first.weekday == 7 ? 0 : first.weekday;
    final daysInMonth = last.day;
    final prevMonthDays = startWeekday;
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysPrev = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;

    final weekLabels = ['Do', 'Se', 'Te', 'Qa', 'Qi', 'Se', 'Sá'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: dayNormal),
                onPressed: _prevMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM', 'pt_BR').format(_currentMonth),
                      style: const TextStyle(
                        color: dayNormal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down,
                        color: dayNormal, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentMonth.year}',
                      style: const TextStyle(
                        color: dayNormal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down,
                        color: dayNormal, size: 20),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: dayNormal),
                onPressed: _nextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekLabels
                .map((l) => Text(l,
                    style: const TextStyle(color: dayHeader, fontSize: 11)))
                .toList(),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              const minCellSize = 18.0;
              const maxCellSize = 28.0;
              final availableWidth = constraints.maxWidth;
              final cellSize = (availableWidth / 7).clamp(minCellSize, maxCellSize);
              final rows = <Widget>[];
              var rowDays = <Widget>[];

              for (var i = 0; i < prevMonthDays; i++) {
                final d = daysPrev - prevMonthDays + 1 + i;
                rowDays.add(SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Center(
                    child: Text('$d',
                        style: const TextStyle(color: dayDim, fontSize: 12)),
                  ),
                ));
              }

              for (var d = 1; d <= daysInMonth; d++) {
                final isThisWeek = _isCurrentWeek(first, d);
                rowDays.add(SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isThisWeek ? dayHighlight : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: const TextStyle(color: dayNormal, fontSize: 12),
                      ),
                    ),
                  ),
                ));
                if (rowDays.length == 7) {
                  rows.add(Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.from(rowDays)));
                  rowDays = [];
                }
              }

              var nextMonthDay = 1;
              while (rowDays.isNotEmpty && rowDays.length < 7) {
                rowDays.add(SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Center(
                    child: Text('$nextMonthDay',
                        style: const TextStyle(color: dayDim, fontSize: 12)),
                  ),
                ));
                nextMonthDay++;
              }
              if (rowDays.isNotEmpty) {
                rows.add(Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: rowDays));
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: rows,
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isCurrentWeek(DateTime first, int day) {
    final d = DateTime(first.year, first.month, day);
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday % 7));
    final end = start.add(const Duration(days: 6));
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

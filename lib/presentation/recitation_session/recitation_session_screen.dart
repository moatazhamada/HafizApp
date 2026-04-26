import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/domain/entities/recitation_session.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_bloc.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_event.dart';
import 'package:hafiz_app/presentation/recitation_session/bloc/recitation_session_state.dart';
import 'package:hafiz_app/injection_container.dart';

class RecitationSessionScreen extends StatelessWidget {
  const RecitationSessionScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecitationSessionBloc>()..add(LoadSessions()),
      child: const RecitationSessionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('lbl_session_history'.tr)),
      body: BlocBuilder<RecitationSessionBloc, RecitationSessionState>(
        builder: (context, state) {
          if (state is RecitationSessionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RecitationSessionError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message.tr),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context
                        .read<RecitationSessionBloc>()
                        .add(LoadSessions()),
                    child: Text('lbl_retry'.tr),
                  ),
                ],
              ),
            );
          }
          if (state is RecitationSessionLoaded && state.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'msg_no_sessions'.tr,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          if (state is RecitationSessionLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.sessions.length,
              itemBuilder: (context, index) {
                return _SessionCard(
                  session: state.sessions[index],
                  isDark: isDark == true,
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final RecitationSession session;
  final bool isDark;

  const _SessionCard({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scoreColor = session.score >= 80
        ? Colors.green
        : session.score >= 50
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.surahName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${session.score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: isDark ? Colors.green[300] : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.correctCount}/${session.totalCount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.format_list_numbered,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${'lbl_total_verses'.tr}: ${session.totalVerses}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(session.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'lbl_today'.tr;
    if (diff.inDays == 1) return 'lbl_yesterday'.tr;
    return '${date.day}/${date.month}/${date.year}';
  }
}

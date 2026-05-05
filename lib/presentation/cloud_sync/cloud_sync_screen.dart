import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart' as di;
import 'bloc/cloud_sync_bloc.dart';
import '../auth/bloc/qf_auth_bloc.dart';

class CloudSyncScreen extends StatelessWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CloudSyncBloc>(),
      child: const _CloudSyncView(),
    );
  }
}

class _CloudSyncView extends StatelessWidget {
  const _CloudSyncView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('lbl_cloud_sync'.tr)),
      body: BlocListener<CloudSyncBloc, CloudSyncState>(
        listener: (context, state) {
          if (state is QfSyncSuccess) {
            final msg = 'msg_sync_complete'
                .tr
                .replaceAll('{pushed}', '${state.pushed}')
                .replaceAll('{pulled}', '${state.pulled}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          } else if (state is QfSyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _AuthCard(),
            SizedBox(height: 24),
            _SyncSection(),
            SizedBox(height: 24),
            _LocalDataNote(),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QfAuthBloc, QfAuthState>(
      builder: (context, state) {
        final isLoading = state is QfAuthLoading || state is QfAuthInitial;
        final isAuth = state is QfAuthAuthenticated;
        final errorMsg =
            state is QfAuthError ? state.message : null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isAuth
                          ? Icons.verified_user
                          : (errorMsg != null
                              ? Icons.error_outline
                              : Icons.no_accounts),
                      color: isAuth
                          ? Colors.teal
                          : (errorMsg != null ? Colors.redAccent : Colors.grey),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAuth
                                ? 'msg_qf_logged_in'.tr
                                : 'msg_qf_not_logged_in'.tr,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isAuth && state.userId != null)
                            Text(
                              '${'lbl_user'.tr}: ${state.userId}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          if (errorMsg != null)
                            Text(
                              errorMsg.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.redAccent),
                            ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isAuth) ...[
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context
                            .read<QfAuthBloc>()
                            .add(QfAuthLogoutRequested()),
                    icon: const Icon(Icons.logout),
                    label: Text('lbl_sign_out'.tr),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('lbl_delete_my_data'.tr),
                                content: Text('msg_delete_data_confirm'.tr),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('lbl_cancel'.tr),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.read<QfAuthBloc>().add(
                                          QfAuthDeleteDataRequested());
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    child: Text('lbl_delete_data'.tr),
                                  ),
                                ],
                              ),
                            );
                          },
                    icon: Icon(Icons.delete_forever,
                        color: Theme.of(context).colorScheme.error),
                    label: Text('lbl_delete_my_data'.tr,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context
                            .read<QfAuthBloc>()
                            .add(QfAuthLoginRequested()),
                    icon: const Icon(Icons.login),
                    label: Text('msg_qf_login'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SyncSection extends StatelessWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QfAuthBloc, QfAuthState>(
      builder: (context, authState) {
        final isAuth = authState is QfAuthAuthenticated;

        return BlocBuilder<CloudSyncBloc, CloudSyncState>(
          builder: (context, syncState) {
            final isSyncing = syncState is QfSyncLoading;
            final lastSync = PrefUtils().getQfLastSyncAt();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'lbl_bookmarks'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: isAuth && !isSyncing
                      ? () => context
                          .read<CloudSyncBloc>()
                          .add(SyncWithQfEvent())
                      : null,
                  icon: isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text('lbl_bookmarks_sync'.tr),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (lastSync != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'msg_last_synced'
                        .tr
                        .replaceAll('{time}', _formatDate(lastSync)),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (!isAuth) ...[
                  const SizedBox(height: 8),
                  Text(
                    'msg_login_to_sync'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'lbl_just_now'.tr;
    if (diff.inHours < 1) {
      return 'lbl_minutes_ago'.tr.replaceAll('{count}', '${diff.inMinutes}');
    }
    if (diff.inDays < 1) {
      return 'lbl_hours_ago'.tr.replaceAll('{count}', '${diff.inHours}');
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _LocalDataNote extends StatelessWidget {
  const _LocalDataNote();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: Colors.grey),
        title: Text('msg_recitation_progress'.tr),
        subtitle: Text('msg_local_data_note'.tr),
      ),
    );
  }
}

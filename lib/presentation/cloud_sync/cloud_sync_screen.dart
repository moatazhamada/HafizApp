import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart' as di;
import 'bloc/cloud_sync_bloc.dart';
import '../auth/bloc/qf_auth_bloc.dart';
import 'package:hafiz_app/data/datasource/qf_user_api_remote_data_source.dart';

class CloudSyncScreen extends StatelessWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CloudSyncBloc>()..add(CheckAuthStatusEvent()),
      child: const _CloudSyncView(),
    );
  }
}

class _CloudSyncView extends StatefulWidget {
  const _CloudSyncView();

  @override
  State<_CloudSyncView> createState() => _CloudSyncViewState();
}

class _CloudSyncViewState extends State<_CloudSyncView> {
  bool _isAuthenticated = false;

  int _lastQfSyncCount = 0;
  int _qfCollectionsCount = 0;

  Future<void> _fetchCollectionsCount() async {
    try {
      final collections = await di
          .sl<QfUserApiRemoteDataSource>()
          .getCollections();
      if (mounted) {
        setState(() => _qfCollectionsCount = collections.length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('lbl_cloud_sync'.tr)),
      body: BlocConsumer<CloudSyncBloc, CloudSyncState>(
        listener: (context, state) {
          if (state is CloudSyncAuthenticated) {
            _isAuthenticated = state.isAuthenticated;
          } else if (state is CloudSyncSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is CloudSyncError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is QfSyncSuccess) {
            setState(() => _lastQfSyncCount = state.bookmarkCount);
            _fetchCollectionsCount();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Synced ${state.bookmarkCount} bookmarks with Quran.com',
                ),
              ),
            );
          } else if (state is QfSyncError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildQfAuthSection(context),
              const Divider(height: 32),
              Text(
                'Firebase Legacy Sync',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              _buildAuthStatus(context, state),
              const SizedBox(height: 16),
              _buildAuthActions(context, state),
              const Divider(height: 32),
              _buildSyncActions(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuthStatus(BuildContext context, CloudSyncState state) {
    final isAuth = state is CloudSyncAuthenticated
        ? state.isAuthenticated
        : _isAuthenticated;
    return Card(
      child: ListTile(
        leading: Icon(
          isAuth ? Icons.cloud_done : Icons.cloud_off,
          color: isAuth ? Colors.green : Colors.grey,
        ),
        title: Text(
          isAuth ? 'lbl_authenticated'.tr : 'lbl_not_authenticated'.tr,
        ),
        trailing: state is CloudSyncLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }

  Widget _buildAuthActions(BuildContext context, CloudSyncState state) {
    final isAuth = state is CloudSyncAuthenticated
        ? state.isAuthenticated
        : _isAuthenticated;
    final isLoading = state is CloudSyncLoading;

    if (isAuth) {
      return ElevatedButton.icon(
        onPressed: isLoading
            ? null
            : () => context.read<CloudSyncBloc>().add(SignOutEvent()),
        icon: const Icon(Icons.logout),
        label: Text('lbl_sign_out'.tr),
      );
    }
    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () => context.read<CloudSyncBloc>().add(SignInEvent()),
      icon: const Icon(Icons.login),
      label: Text('lbl_sign_in'.tr),
    );
  }

  Widget _buildSyncActions(BuildContext context, CloudSyncState state) {
    final isAuth = state is CloudSyncAuthenticated
        ? state.isAuthenticated
        : _isAuthenticated;
    final isLoading = state is CloudSyncLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'lbl_cloud_sync'.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isAuth && !isLoading
              ? () => context.read<CloudSyncBloc>().add(SyncToCloudEvent())
              : null,
          icon: const Icon(Icons.cloud_upload),
          label: Text('lbl_sync_to_cloud'.tr),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: isAuth && !isLoading
              ? () => context.read<CloudSyncBloc>().add(SyncFromCloudEvent())
              : null,
          icon: const Icon(Icons.cloud_download),
          label: Text('lbl_sync_from_cloud'.tr),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: isAuth && !isLoading
              ? () =>
                    context.read<CloudSyncBloc>().add(SyncBidirectionalEvent())
              : null,
          icon: const Icon(Icons.sync),
          label: Text('lbl_sync_bidirectional'.tr),
        ),
      ],
    );
  }

  Widget _buildQfAuthSection(BuildContext context) {
    return BlocConsumer<QfAuthBloc, QfAuthState>(
      listener: (context, state) {
        if (state is QfAuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is QfAuthLoading;
        final isAuth = state is QfAuthAuthenticated;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quran.com Authentication',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  isAuth ? Icons.verified_user : Icons.no_accounts,
                  color: isAuth ? Colors.teal : Colors.grey,
                ),
                title: Text(
                  isAuth ? 'Logged in to Quran.com' : 'Not Logged In',
                ),
                subtitle: isAuth ? Text('User ID: ${state.userId}') : null,
                trailing: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (isAuth) ...[
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => context.read<QfAuthBloc>().add(
                        QfAuthLogoutRequested(),
                      ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout from Quran.com'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final syncState = context.watch<CloudSyncBloc>().state;
                  final isSyncing = syncState is QfSyncLoading;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: isSyncing
                            ? null
                            : () => context.read<CloudSyncBloc>().add(
                                SyncWithQfEvent(),
                              ),
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
                        label: const Text('Sync Bookmarks with Quran.com'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_lastQfSyncCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Last sync: $_lastQfSyncCount bookmarks${_qfCollectionsCount > 0 ? " · $_qfCollectionsCount collections" : ""}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ] else
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => context.read<QfAuthBloc>().add(
                        QfAuthLoginRequested(),
                      ),
                icon: const Icon(Icons.login),
                label: const Text('Login with Quran.com'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }
}

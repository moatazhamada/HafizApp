import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../injection_container.dart' as di;
import 'bloc/cloud_sync_bloc.dart';

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
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
}

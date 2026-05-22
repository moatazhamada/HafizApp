import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/presentation/auth/bloc/qf_auth_bloc.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<QfAuthBloc, QfAuthState>(
      builder: (context, state) {
        final Widget avatar;
        final String title;
        final String subtitle;

        if (state is QfAuthAuthenticated) {
          final profile = state.profile;
          final initials = profile?.initials ??
              (state.userId?.isNotEmpty == true
                  ? state.userId![0].toUpperCase()
                  : '?');
          avatar = CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
          title = profile?.displayName ?? 'msg_qf_account'.tr;
          subtitle = profile?.email ?? 'msg_qf_logged_in'.tr;
        } else if (state is QfAuthLoading || state is QfAuthInitial) {
          avatar = CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          );
          title = 'lbl_not_signed_in'.tr;
          subtitle = 'lbl_tap_to_sign_in'.tr;
        } else {
          // QfAuthUnauthenticated, QfAuthError
          avatar = CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.account_circle_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
          );
          title = 'lbl_not_signed_in'.tr;
          subtitle = 'lbl_tap_to_sign_in'.tr;
        }

        return Semantics(
          button: true,
          label: 'lbl_semantics_profile_card'.tr.replaceAll('{status}', title),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, AppRoutes.cloudSyncPage),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Row(
                  children: [
                    avatar,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      rtlChevron(context),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

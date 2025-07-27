import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:spotube/collections/spotube_icons.dart';
import 'package:spotube/components/button/back_button.dart';
import 'package:spotube/components/dialogs/prompt_dialog.dart';
import 'package:spotube/components/titlebar/titlebar.dart';
import 'package:spotube/extensions/context.dart';
import 'package:spotube/provider/scrobbler/scrobbler.dart';
import 'package:auto_route/auto_route.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class LastFMLoginPage extends HookConsumerWidget {
  static const name = "lastfm_login";
  const LastFMLoginPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scrobblerNotifier = ref.read(scrobblerProvider.notifier);

    final isLoading = useState(false);

    return Scaffold(
      headers: const [
        SafeArea(
          bottom: false,
          child: TitleBar(
            leading: [BackButton()],
          ),
        ),
      ],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color.fromARGB(255, 186, 0, 0),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                SpotubeIcons.lastFm,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.lastfm_brand).h3(),
            const SizedBox(height: 8),
            Text(context.l10n.login_with_your_lastfm),
            const SizedBox(height: 16),
            Button.primary(
              onPressed: () async {
                try {
                  isLoading.value = true;
                  final url = await scrobblerNotifier.login();
                  await launchUrl(Uri.parse(url));
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.l10n.login_with_lastfm),
                        content: Text(context.l10n.lastfm_authorization_note),
                        actions: [
                          TextButton(
                            onPressed: () {
                              final token = Uri.parse(url).queryParameters['token']!;
                              scrobblerNotifier.getSession(token);
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            child: Text(context.l10n.done),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showPromptDialog(
                      context: context,
                      title: context.l10n.error("Authentication failed"),
                      message: e.toString(),
                      cancelText: null,
                    );
                  }
                } finally {
                  isLoading.value = false;
                }
              },
              child: Text(context.l10n.login_with_lastfm),
            ),
          ],
        ),
      ),
    );
  }
}

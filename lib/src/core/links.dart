import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import 'widgets/feedback.dart';

abstract final class Links {
  static const source = 'https://github.com/HBProductionOfficial/vitrine-flutter';
  static const newIssue = '$source/issues/new';
  static const dummyJson = 'https://dummyjson.com';
  static const restfulApi = 'https://restful-api.dev';
}

/// Opens [url] in the browser, or says so if nothing could open it.
Future<void> openLink(BuildContext context, String url) async {
  final message = AppLocalizations.of(context).couldNotOpenLink;
  final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) showSnack(context, message);
}

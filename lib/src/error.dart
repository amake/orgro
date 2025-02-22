import 'package:flutter/widgets.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';

typedef MessageBuilder = String Function(BuildContext);

class OrgroError implements Exception {
  factory OrgroError.from(dynamic obj) {
    switch (obj) {
      case OrgError():
        return switch (obj) {
          OrgParserError(result: final result) => OrgroError(
            'Parser error',
            localizedMessage:
                (context) => AppLocalizations.of(
                  context,
                )!.errorOrgParser(result.toString()),
          ),
          OrgExecutionError(code: final code, cause: final cause) => OrgroError(
            'Execution error',
            localizedMessage:
                (context) => AppLocalizations.of(
                  context,
                )!.errorOrgExecution(cause.toString(), code),
          ),
          OrgTimeoutError(code: final code, timeLimit: final limit) =>
            OrgroError(
              'Timeout error',
              localizedMessage:
                  (context) => AppLocalizations.of(
                    context,
                  )!.errorOrgTimeout(limit.inMilliseconds, code),
            ),
          OrgArgumentError(item: final item) => OrgroError(
            'Argument error',
            localizedMessage:
                (context) => AppLocalizations.of(
                  context,
                )!.errorOrgArgument(item.toString()),
          ),
        };
      default:
        return OrgroError(obj.toString());
    }
  }

  OrgroError(this.message, {MessageBuilder? localizedMessage})
    : localizedMessage = localizedMessage ?? ((_) => message.toString());

  final Object message;
  final MessageBuilder localizedMessage;

  @override
  String toString() => message.toString();
}

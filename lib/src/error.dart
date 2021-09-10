import 'package:flutter/widgets.dart';

typedef MessageBuilder = String Function(BuildContext);

class OrgroError implements Exception {
  OrgroError(this.message, {MessageBuilder? localizedMessage})
      : localizedMessage = localizedMessage ?? ((_) => message.toString());

  final Object message;
  final MessageBuilder localizedMessage;

  @override
  String toString() => message.toString();
}

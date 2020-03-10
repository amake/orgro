import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/navigation.dart';

const _channel = MethodChannel('org.madlonkay.orgro/openFile');

class PlatformOpenHandler extends StatefulWidget {
  const PlatformOpenHandler({@required this.child, Key key})
      : assert(child != null),
        super(key: key);

  final Widget child;

  @override
  _PlatformOpenHandlerState createState() => _PlatformOpenHandlerState();
}

class _PlatformOpenHandlerState extends State<PlatformOpenHandler> {
  @override
  void initState() {
    super.initState();
    _channel
      ..setMethodCallHandler(_handler)
      ..invokeMethod('ready');
  }

  Future<dynamic> _handler(MethodCall call) async {
    switch (call.method) {
      case 'loadString':
        return loadDocument(
          context,
          null,
          Future.value(call.arguments as String),
        );
      case 'loadUrl':
        return loadUrl(context, call.arguments as String);
    }
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

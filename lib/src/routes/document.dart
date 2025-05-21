import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/routes/routes.dart';
import 'package:orgro/src/util.dart';

class DocumentRouteArgs {
  const DocumentRouteArgs({required this.dataSource, this.target, this.mode});

  final DataSource dataSource;
  final String? target;
  final InitialMode? mode;
}

class DocumentRoute extends MaterialPageRoute<void> {
  DocumentRoute.fromSettings(RouteSettings settings)
    : super(builder: _builder, settings: settings, fullscreenDialog: true);

  DocumentRoute({
    required DataSource dataSource,
    String? target,
    InitialMode? mode,
  }) : super(
         builder: _builder,
         settings: RouteSettings(
           name: Routes.document,
           arguments: DocumentRouteArgs(
             dataSource: dataSource,
             target: target,
             mode: mode,
           ),
         ),
         fullscreenDialog: true,
       );

  static Widget _builder(BuildContext context) => const _DocumentRouteTop();
}

class _DocumentRouteTop extends StatefulWidget {
  const _DocumentRouteTop();

  @override
  State<_DocumentRouteTop> createState() => _DocumentRouteTopState();
}

class _DocumentRouteTopState extends State<_DocumentRouteTop> {
  bool _inited = false;
  late DocumentRouteArgs _args;
  late Future<ParsedOrgFileInfo?> _parsed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      setState(() {
        _inited = true;
        _args = ModalRoute.of(context)!.settings.arguments as DocumentRouteArgs;
        _parsed = ParsedOrgFileInfo.from(_args.dataSource);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParsedOrgFileInfo?>(
      future: _parsed,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DocumentProvider(
            dataSource: snapshot.data!.dataSource,
            doc: snapshot.data!.doc,
            child: _DocumentPageWrapper(
              layer: 0,
              target: _args.target,
              initialMode: _args.mode,
            ),
          );
        } else if (snapshot.hasError) {
          return ErrorPage(error: snapshot.error.toString());
        } else {
          return const ProgressPage();
        }
      },
    );
  }
}

class _DocumentPageWrapper extends StatelessWidget {
  const _DocumentPageWrapper({
    required this.layer,
    required this.target,
    this.initialMode,
  });

  final int layer;
  final String? target;
  final InitialMode? initialMode;

  @override
  Widget build(BuildContext context) {
    final docProvider = DocumentProvider.of(context);
    final dataSource = docProvider.dataSource;
    return RootRestorationScope(
      restorationId: 'org_page_root:${dataSource.id}',
      child: ViewSettings.defaults(
        context,
        // Get ViewSettings into the context
        child: Builder(
          builder: (context) {
            final viewSettings = ViewSettings.of(context);
            return OrgController(
              root: docProvider.doc,
              settings: viewSettings.readerMode
                  ? OrgSettings.hideMarkup
                  : const OrgSettings(),
              interpretEmbeddedSettings: true,
              searchQuery: viewSettings.queryString?.asRegex(),
              sparseQuery: viewSettings.filterData.asSparseQuery(),
              // errorHandler is invoked during build, so we need to schedule the
              // snack bar for after the frame
              errorHandler: (e) => WidgetsBinding.instance.addPostFrameCallback(
                (_) => showErrorSnackBar(context, OrgroError.from(e)),
              ),
              restorationId: 'org_page:${dataSource.id}',
              child: OrgLocator(
                child: DocumentPage(
                  layer: layer,
                  title: dataSource.name,
                  initialTarget: target,
                  initialMode: initialMode,
                  root: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

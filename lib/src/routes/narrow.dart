import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/routes/routes.dart';
import 'package:orgro/src/util.dart';

class NarrowRouteArgs {
  const NarrowRouteArgs({
    required this.dataSource,
    required this.section,
    required this.layer,
    required this.viewSettings,
    required this.orgController,
    required this.bucket,
    required this.onDocChanged,
  });

  final DataSource dataSource;
  final OrgTree section;
  final int layer;
  final InheritedViewSettings viewSettings;
  final OrgControllerData orgController;
  final RestorationBucket bucket;
  final ValueChanged<OrgTree> onDocChanged;
}

class NarrowRoute extends MaterialPageRoute<void> {
  NarrowRoute.fromSettings(RouteSettings settings)
    : super(builder: _builder, settings: settings);

  NarrowRoute({required NarrowRouteArgs args})
    : super(
        builder: _builder,
        settings: RouteSettings(name: Routes.narrow, arguments: args),
      );

  static Widget _builder(BuildContext context) => const _NarrowRouteTop();
}

class _NarrowRouteTop extends StatelessWidget {
  const _NarrowRouteTop();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as NarrowRouteArgs;
    final dataSource = args.dataSource;
    final layer = args.layer;
    final viewSettings = args.viewSettings;
    final orgController = args.orgController;
    return UnmanagedRestorationScope(
      bucket: args.bucket,
      child: DocumentProvider(
        doc: args.section,
        dataSource: dataSource,
        onDocChanged: args.onDocChanged,
        child: ViewSettings(
          data: viewSettings.data,
          child: Builder(
            builder: (context) {
              final viewSettings = ViewSettings.of(context);
              return OrgController.defaults(
                orgController,
                // Continue to use the true document root so that links to sections
                // outside the narrowed section can be resolved
                root: orgController.root,
                settings: viewSettings.readerMode
                    ? OrgSettings.hideMarkup
                    : const OrgSettings(),
                searchQuery: viewSettings.queryString?.asRegex(),
                sparseQuery: viewSettings.filterData.asSparseQuery(),
                restorationId: 'org_narrow_$layer:${dataSource.id}',
                child: OrgLocator(
                  child: DocumentPage(
                    layer: layer,
                    title: AppLocalizations.of(
                      context,
                    )!.pageTitleNarrow(dataSource.name),
                    initialQuery: viewSettings.queryString,
                    initialFilter: viewSettings.filterData,
                    root: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

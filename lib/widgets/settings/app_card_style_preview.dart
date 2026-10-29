import 'package:flauncher/app_image_type.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/app_card_style.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_caption.dart';
import 'package:flauncher/widgets/app_card_contour_painter.dart';
import 'package:flauncher/widgets/app_icon_face.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Typical app card size on a 1080p TV; the preview is scaled down to fit the panel.
const double _cardWidth = 196;
const double _cardHeight = _cardWidth * 9 / 16;
const double _cardGap = 18;

/// Live preview of the app card and caption settings, using the first two
/// installed apps: one drawn focused and one at rest.
class AppCardStylePreview extends StatelessWidget {
  const AppCardStylePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final captionStyle = settings.appCaptionStyle;
    final iconStyle = settings.appIconStyle;
    final accentColor = settings.accentColor;
    final apps = Provider.of<AppsService>(context, listen: false)
        .applications
        .where((app) => !app.hidden)
        .take(2)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B4A5A), Color(0xFF1B2028)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: _cardGap),
                    _PreviewCard(
                      app: i < apps.length ? apps[i] : null,
                      focused: i == 0,
                      captionStyle: captionStyle,
                      iconStyle: iconStyle,
                      accentColor: accentColor,
                      borderThickness: settings.focusBorderThickness,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatefulWidget {
  final App? app;
  final bool focused;
  final AppCaptionStyle captionStyle;
  final AppIconStyle iconStyle;
  final Color accentColor;
  final double borderThickness;

  const _PreviewCard({
    required this.app,
    required this.focused,
    required this.captionStyle,
    required this.iconStyle,
    required this.accentColor,
    required this.borderThickness,
  });

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  Future<AppCardImage>? _image;
  Object? _imageKey;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final captionStyle = widget.captionStyle;
    final iconStyle = widget.iconStyle;
    final name = app?.name ?? 'App';

    final imageKey = (app?.packageName, iconStyle.mode, iconStyle.variant);
    if (app != null && imageKey != _imageKey) {
      _imageKey = imageKey;
      _image = Provider.of<AppsService>(context, listen: false).getAppCardImage(app.packageName, iconStyle);
    }

    final captionOnCard = captionStyle.visible && captionStyle.position == AppCaptionPosition.overlay;
    final captionOpacity = captionStyle.visibility == AppCaptionVisibility.focused && !widget.focused ? 0.0 : 1.0;
    final caption = AppCaption(
      name: name,
      style: captionStyle,
      accentColor: widget.accentColor,
      onCard: captionOnCard,
    );

    return SizedBox(
      width: _cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _cardHeight,
            child: Transform.scale(
              scale: widget.focused ? 1.07 : 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (iconStyle.shadow == AppCardShadow.glow && widget.focused)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.55),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  FutureBuilder<AppCardImage>(
                    future: _image,
                    builder: (context, snapshot) {
                      final image = snapshot.data;
                      final iconFace = image?.icon != null;
                      return Material(
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        color: iconFace && iconStyle.translucentCard ? Colors.transparent : null,
                        elevation: switch (iconStyle.shadow) {
                          AppCardShadow.none => 0,
                          AppCardShadow.strong => widget.focused ? 16 : 10,
                          _ => widget.focused ? 7 : 4,
                        },
                        shadowColor: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _face(image, name, captionOnCard ? captionStyle.boxHeight + 6 : 0),
                            if (captionOnCard)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Opacity(
                                  opacity: captionOpacity,
                                  child: Padding(
                                    padding: captionStyle.background == AppCaptionBackground.bar
                                        ? EdgeInsets.zero
                                        : const EdgeInsets.fromLTRB(8, 0, 8, 6),
                                    child: caption,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (widget.focused)
                    CustomPaint(
                      foregroundPainter: AppCardContourPainter(
                        radius: 12,
                        strokeWidth: widget.borderThickness,
                        accentColor: widget.accentColor,
                        alpha: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (captionStyle.reservedHeight > 0)
            SizedBox(
              height: captionStyle.reservedHeight,
              child: Padding(
                padding: const EdgeInsets.only(top: kCaptionGap),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Opacity(opacity: captionOpacity, child: caption),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _face(AppCardImage? image, String name, double captionInset) {
    if (image == null || image.bytes.isEmpty) {
      return Center(child: Icon(Icons.tv, size: 36, color: Colors.white.withValues(alpha: 0.6)));
    }
    if (image.type == AppImageType.Banner) {
      return Image.memory(image.bytes, fit: BoxFit.cover, gaplessPlayback: true);
    }
    if (image.icon != null) {
      return AppIconFace(
        image: MemoryImage(image.bytes),
        icon: image.icon!,
        style: widget.iconStyle,
        accentColor: widget.accentColor,
        bottomInset: captionInset,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Image.memory(image.bytes, gaplessPlayback: true)),
          Flexible(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(name, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 3),
            ),
          ),
        ],
      ),
    );
  }
}

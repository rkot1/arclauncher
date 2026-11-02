/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:math';

import 'package:flauncher/actions.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/app_image_type.dart';
import 'package:flauncher/models/app_card_style.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_caption.dart';
import 'package:flauncher/widgets/app_card_contour_painter.dart';
import 'package:flauncher/widgets/app_icon_face.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';

const _validationKeys = [LogicalKeyboardKey.select, LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonA];

const kAppCardAspectRatio = 16 / 9;
const kAppCardHorizontalPadding = 12.0;
const kAppCardVerticalPadding = 9.0;
const kLauncherSectionHorizontalPadding = 24.0;

/// Row extent for a grid/dock line given the content width between section paddings.
double appCardRowExtentFromContentWidth(double contentWidth, {int columnCount = Category.ColumnsCount}) {
  final slotWidth = contentWidth / columnCount;
  return slotWidth / kAppCardAspectRatio;
}

/// Adjusted aspect ratio for grid cells that includes [labelHeight] for the app name below the card.
double appCardGridAspectRatio(double crossAxisExtent, int columnsCount, double labelHeight) {
  final cellWidth = crossAxisExtent / columnsCount;
  return cellWidth / (cellWidth / kAppCardAspectRatio + labelHeight);
}

class AppCard extends StatefulWidget {
  final App application;
  final Category category;
  final bool autofocus;
  final void Function(AxisDirection) onMove;
  final VoidCallback onMoveEnd;
  final bool handleUpNavigationToSettings;
  final double scrollAlignment;
  final bool enforceAspectRatio;
  final VoidCallback? onFocused;
  final bool ensureVisibleOnFocus;
  final bool onlyScrollWhenNearBottom;

  const AppCard({
    super.key,
    required this.application,
    required this.category,
    required this.autofocus,
    required this.onMove,
    required this.onMoveEnd,
    this.handleUpNavigationToSettings = false,
    this.scrollAlignment = 0.5,
    this.enforceAspectRatio = true,
    this.onFocused,
    this.ensureVisibleOnFocus = true,
    this.onlyScrollWhenNearBottom = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _moving = false;
  bool _clicked = false;
  bool _isFocused = false;
  bool _isTraditionalHighlightMode = false;
  bool _isHighlightAnimating = false;
  bool _animationEnabled = false;
  String? _accentColorHex;
  Color _accentColor = const Color(0xFF000000);
  DateTime? _lastMoveAt;
  DateTime? _lastEnsureVisibleAt;
  late FocusNode _focusNode;

  AppCardImage? _cardImage;
  ImageProvider? _imageProvider;
  bool _imageLoadError = false;
  // The icon settings the current image was loaded for; null forces a reload.
  Object? _imageLoadKey;
  int _imageLoadGeneration = 0;

  late final AnimationController _animation;

  late final CurvedAnimation _curvedAnimation;
  static const double _focusedScale = 1.07;
  static const Duration _focusAnimationDuration = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _curvedAnimation = CurvedAnimation(parent: _animation, curve: Curves.easeInOut);
    _focusNode = FocusNode();
    _isTraditionalHighlightMode = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    FocusManager.instance.addHighlightModeListener(_focusHighlightModeChanged);

    // Check if we need to restore focus/reorder mode after a move
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appsService = Provider.of<AppsService>(context, listen: false);
      if (appsService.pendingReorderFocusPackage == widget.application.packageName &&
          appsService.pendingReorderFocusCategoryId == widget.category.id) {
        appsService.clearPendingReorderFocusPackage();
        _focusNode.requestFocus();

        setState(() {
          _moving = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(AppCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final appsService = Provider.of<AppsService>(context, listen: false);

    if (oldWidget.application.packageName != widget.application.packageName) {
      _cardImage = null;
      _imageProvider = null;
      _imageLoadError = false;
      _imageLoadKey = null;
    } else if (appsService.consumeDirtyImage(widget.application.packageName)) {
      _imageLoadKey = null;
    }

    // Check for pending focus on update as well
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appsService = Provider.of<AppsService>(context, listen: false);
      if (appsService.pendingReorderFocusPackage == widget.application.packageName &&
          appsService.pendingReorderFocusCategoryId == widget.category.id) {
        appsService.clearPendingReorderFocusPackage();
        _focusNode.requestFocus();

        if (!_moving) {
          setState(() {
            _moving = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_focusHighlightModeChanged);
    _curvedAnimation.dispose();
    _animation.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captionStyle = context.select<SettingsService, AppCaptionStyle>((s) => s.appCaptionStyle);
    final iconStyle = context.select<SettingsService, AppIconStyle>((s) => s.appIconStyle);
    final (bool animationEnabled, String accentColorHex, bool showFocusBorders, double borderThickness) = context.select<SettingsService, (bool, String, bool, double)>(
      (s) => (s.appHighlightAnimationEnabled, s.accentColorHex, s.showFocusBorders, s.focusBorderThickness),
    );
    if (accentColorHex != _accentColorHex) {
      _accentColorHex = accentColorHex;
      _accentColor = Color(int.parse('FF$accentColorHex', radix: 16));
    }
    if (animationEnabled != _animationEnabled) {
      _animationEnabled = animationEnabled;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateHighlightAnimation();
      });
    }
    final imageLoadKey = (iconStyle.mode, iconStyle.variant);
    if (imageLoadKey != _imageLoadKey) {
      _imageLoadKey = imageLoadKey;
      _loadAppImage(Provider.of<AppsService>(context, listen: false), iconStyle);
    }

    final bool shouldHighlight = _shouldHighlight();
    final bool captionOnCard = captionStyle.visible && captionStyle.position == AppCaptionPosition.overlay;
    final double captionOpacity =
        captionStyle.visibility == AppCaptionVisibility.focused && !shouldHighlight ? 0.0 : 1.0;
    final bool iconFace = _cardImage?.icon != null;
    final appImageWidget = _appImage(iconStyle, captionOnCard ? captionStyle.boxHeight + 6 : 0);

    return _boundToCardWidth(captionStyle.reservedHeight, FocusKeyboardListener(
      onPressed: _onPressed,
      onLongPress: _onLongPress,
      child: AnimatedScale(
        scale: _clicked ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _clicked ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _wrapAspectRatio(
                  RepaintBoundary(
                    child: AnimatedScale(
                      scale: !_moving && shouldHighlight ? _focusedScale : 1.0,
                      duration: _focusAnimationDuration,
                      alignment: Alignment.center,
                      curve: Curves.easeOutCubic,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (iconStyle.shadow == AppCardShadow.glow)
                            IgnorePointer(
                              child: AnimatedOpacity(
                                duration: _focusAnimationDuration,
                                opacity: shouldHighlight ? 1.0 : 0.0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accentColor.withValues(alpha: 0.55),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Material(
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            color: iconFace && iconStyle.translucentCard ? Colors.transparent : null,
                            elevation: _cardElevation(iconStyle.shadow, shouldHighlight),
                            shadowColor: Colors.black,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                InkWell(
                                  focusNode: _focusNode,
                                  autofocus: widget.autofocus,
                                  focusColor: Colors.transparent,
                                  child: appImageWidget,
                                  onTap: () => _onPressed(LogicalKeyboardKey.enter),
                                  onLongPress: () => _onLongPress(LogicalKeyboardKey.enter),
                                  onFocusChange: (focused) {
                                    _handleFocusChange(context, focused);
                                  },
                                ),
                                if (captionOnCard)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: IgnorePointer(
                                      child: AnimatedOpacity(
                                        duration: _focusAnimationDuration,
                                        opacity: captionOpacity,
                                        child: Padding(
                                          padding: captionStyle.background == AppCaptionBackground.bar
                                              ? EdgeInsets.zero
                                              : const EdgeInsets.fromLTRB(8, 0, 8, 6),
                                          child: AppCaption(
                                            name: widget.application.name,
                                            style: captionStyle,
                                            accentColor: _accentColor,
                                            onCard: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_moving) ..._arrows(),
                                IgnorePointer(
                                  child: AnimatedOpacity(
                                    duration: _focusAnimationDuration,
                                    curve: Curves.easeInOut,
                                    opacity: shouldHighlight ? 0.0 : 1.0,
                                    child: const ColoredBox(color: Color(0x1A000000)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if ((shouldHighlight && showFocusBorders) || _moving)
                            if (animationEnabled && !_moving)
                              IgnorePointer(
                                child: RepaintBoundary(
                                  child: AnimatedBuilder(
                                    animation: _curvedAnimation,
                                    builder: (context, _) {
                                      final alpha = 0.65 + (_animation.value * 0.35);
                                      return _HighlightOutline(
                                        accentColor: _accentColor,
                                        alpha: alpha,
                                        strokeWidth: borderThickness,
                                      );
                                    },
                                  ),
                                ),
                              )
                            else
                              IgnorePointer(
                                child: RepaintBoundary(
                                  child: _HighlightOutline(
                                    accentColor: _accentColor,
                                    isMoving: _moving,
                                    strokeWidth: borderThickness,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
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
                      child: AnimatedOpacity(
                        duration: _focusAnimationDuration,
                        opacity: captionOpacity,
                        child: AppCaption(
                          name: widget.application.name,
                          style: captionStyle,
                          accentColor: _accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }

  /// In horizontal rows the card width follows from its height, so a caption
  /// below it must be bounded to that width rather than to its own text.
  Widget _boundToCardWidth(double captionHeight, Widget card) {
    if (captionHeight == 0 || !widget.enforceAspectRatio) {
      return card;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return card;
        }
        final cardHeight = constraints.maxHeight - captionHeight;
        if (cardHeight <= 0) {
          return card;
        }
        return SizedBox(width: cardHeight * kAppCardAspectRatio, child: card);
      },
    );
  }

  Future<void> _loadAppImage(AppsService service, AppIconStyle style) async {
    final generation = ++_imageLoadGeneration;
    try {
      final cardImage = await service.getAppCardImage(widget.application.packageName, style);
      if (!mounted || generation != _imageLoadGeneration) {
        return;
      }
      if (cardImage.bytes.isEmpty) {
        throw StateError('No image for ${widget.application.packageName}');
      }
      setState(() {
        _cardImage = cardImage;
        // Platform icon variants are already rendered at card size.
        _imageProvider = cardImage.icon != null
            ? MemoryImage(cardImage.bytes)
            : ResizeImage(MemoryImage(cardImage.bytes), width: 480);
        _imageLoadError = false;
      });
    } catch (_) {
      if (mounted && generation == _imageLoadGeneration) {
        setState(() {
          _cardImage = null;
          _imageProvider = null;
          _imageLoadError = true;
        });
      }
    }
  }

  double _cardElevation(AppCardShadow shadow, bool highlighted) => switch (shadow) {
        AppCardShadow.none => 0,
        AppCardShadow.strong => highlighted ? 16 : 10,
        AppCardShadow.normal || AppCardShadow.glow => highlighted ? 7 : 4,
      };

  Widget _wrapAspectRatio(Widget child) {
    if (widget.enforceAspectRatio) {
      return AspectRatio(aspectRatio: kAppCardAspectRatio, child: child);
    }
    return child;
  }

  Widget _appImage(AppIconStyle iconStyle, double captionInset) {
    App app = widget.application;

    final cardImage = _cardImage;
    final image = _imageProvider;
    if (cardImage != null && image != null) {
      if (cardImage.type == AppImageType.Banner) {
        return Ink.image(image: image, fit: BoxFit.cover);
      } else if (cardImage.icon != null) {
        return AppIconFace(
          image: image,
          icon: cardImage.icon!,
          style: iconStyle,
          accentColor: _accentColor,
          bottomInset: captionInset,
        );
      } else {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(flex: 2, child: Ink.image(image: image, height: double.maxFinite)),
              Flexible(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    app.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else if (_imageLoadError) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            app.name,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.loading),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _focusHighlightModeChanged(FocusHighlightMode mode) {
    final nextMode = mode == FocusHighlightMode.traditional;
    if (nextMode == _isTraditionalHighlightMode) {
      return;
    }
    setState(() {
      _isTraditionalHighlightMode = nextMode;
    });
    _updateHighlightAnimation();
  }

  bool _shouldHighlight() {
    return _isTraditionalHighlightMode && _isFocused;
  }

  void _handleFocusChange(BuildContext context, bool focused) {
    if (_isFocused != focused) {
      setState(() {
        _isFocused = focused;
      });
    }
    _updateHighlightAnimation();

    if (!focused) {
      return;
    }

    final now = DateTime.now();
    if (_lastEnsureVisibleAt != null && now.difference(_lastEnsureVisibleAt!).inMilliseconds < 120) {
      return;
    }
    _lastEnsureVisibleAt = now;
    if (widget.ensureVisibleOnFocus) {
      _ensureVisibleIfNeeded(
        context,
        // This specific alignment value is not only
        // to center the focused card in the row while
        // scrolling, but to prevent the topmost category
        // title to be hidden by the content above it when
        // scrolling from the app bar. How it relates to this,
        // I don't know
        alignment: widget.scrollAlignment,
        onlyWhenNearBottom: widget.onlyScrollWhenNearBottom,
      );
    }
    widget.onFocused?.call();
  }

  void _updateHighlightAnimation() {
    _setHighlightAnimation(_shouldHighlight() && _animationEnabled);
  }

  void _setHighlightAnimation(bool shouldAnimate) {
    if (_isHighlightAnimating == shouldAnimate) {
      return;
    }
    _isHighlightAnimating = shouldAnimate;
    if (shouldAnimate) {
      _animation.repeat(reverse: true);
    } else {
      _animation.stop();
    }
  }

  void _ensureVisibleIfNeeded(BuildContext context, {required double alignment, bool onlyWhenNearBottom = false}) {
    final renderObject = context.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    if (renderObject == null || scrollable == null) {
      return;
    }

    final viewport = RenderAbstractViewport.of(renderObject);

    final position = scrollable.position;
    const minDeltaToScroll = 24.0;
    if (onlyWhenNearBottom &&
        (position.axisDirection == AxisDirection.down || position.axisDirection == AxisDirection.up)) {
      const topEdgePadding = kToolbarHeight + 24.0;
      const bottomEdgePadding = 96.0;
      final topTargetOffset = (viewport.getOffsetToReveal(renderObject, 0).offset - topEdgePadding).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (position.pixels - topTargetOffset >= minDeltaToScroll) {
        position.animateTo(
          topTargetOffset,
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 220),
        );
        return;
      }

      final bottomTargetOffset = (viewport.getOffsetToReveal(renderObject, 1).offset + bottomEdgePadding).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (bottomTargetOffset - position.pixels < minDeltaToScroll) {
        return;
      }

      position.animateTo(
        bottomTargetOffset,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 220),
      );
      return;
    }

    final targetOffset = viewport.getOffsetToReveal(renderObject, alignment).offset;
    if ((targetOffset - position.pixels).abs() < minDeltaToScroll) {
      return;
    }

    Scrollable.ensureVisible(
      context,
      alignment: alignment,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 220),
    );
  }

  List<Widget> _arrows() {
    final arrows = <Widget>[
      _arrow(Alignment.centerLeft, Icons.keyboard_arrow_left, () {
        widget.onMove(AxisDirection.left);
      }),
      _arrow(Alignment.centerRight, Icons.keyboard_arrow_right, () {
        widget.onMove(AxisDirection.right);
      }),
    ];

    // Only show Up/Down arrows for grid layouts
    if (widget.category.type == CategoryType.grid) {
      arrows.add(
        _arrow(Alignment.topCenter, Icons.keyboard_arrow_up, () {
          widget.onMove(AxisDirection.up);
        }),
      );
      arrows.add(
        _arrow(Alignment.bottomCenter, Icons.keyboard_arrow_down, () {
          widget.onMove(AxisDirection.down);
        }),
      );
    }

    return arrows;
  }

  Widget _arrow(Alignment alignment, IconData icon, VoidCallback onTap) => Align(
    alignment: alignment,
    child: Ink(
      decoration: ShapeDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.8), shape: CircleBorder()),
      child: SizedBox(
        height: 36,
        width: 36,
        child: IconButton(icon: Icon(icon, size: 24), onPressed: onTap, padding: EdgeInsets.all(0)),
      ),
    ),
  );

  KeyEventResult _onPressed(LogicalKeyboardKey? key) {
    if (_moving) {
      if (_validationKeys.contains(key) || key == LogicalKeyboardKey.escape) {
        _lastMoveAt = null;
        setState(() => _moving = false);
        widget.onMoveEnd();
      } else {
        final now = DateTime.now();
        if (_lastMoveAt != null && now.difference(_lastMoveAt!).inMilliseconds < 60) {
          return KeyEventResult.handled;
        }

        if (key == LogicalKeyboardKey.arrowLeft) {
          widget.onMove(AxisDirection.left);
        } else if (key == LogicalKeyboardKey.arrowUp) {
          widget.onMove(AxisDirection.up);
        } else if (key == LogicalKeyboardKey.arrowRight) {
          widget.onMove(AxisDirection.right);
        } else if (key == LogicalKeyboardKey.arrowDown) {
          widget.onMove(AxisDirection.down);
        } else {
          return KeyEventResult.ignored;
        }

        _lastMoveAt = now;
        final nowForScroll = DateTime.now();
        if (_lastEnsureVisibleAt == null || nowForScroll.difference(_lastEnsureVisibleAt!).inMilliseconds >= 120) {
          _lastEnsureVisibleAt = nowForScroll;
          WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisibleIfNeeded(context, alignment: 0.1));
        }
      }

      return KeyEventResult.handled;
    } else if (_validationKeys.contains(key)) {
      if (!_clicked) {
        setState(() => _clicked = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          context.read<AppsService>().launchApp(widget.application);
          // Reset after a short delay so it looks normal when user returns
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _clicked = false);
            }
          });
        });
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp && widget.handleUpNavigationToSettings) {
      Actions.invoke(context, const MoveFocusToSettingsIntent());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(LogicalKeyboardKey? key) {
    if (!_moving && (key == null || longPressableKeys.contains(key))) {
      _showPanel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showPanel() async {
    final result = await showDialog<ApplicationInfoPanelResult>(
      context: context,
      builder: (context) => ApplicationInfoPanel(category: widget.category, application: widget.application),
    );
    if (result == ApplicationInfoPanelResult.reorderApp) {
      setState(() => _moving = true);
    }
  }
}

class _HighlightOutline extends StatelessWidget {
  final Color accentColor;
  final double alpha;
  final bool isMoving;
  final double strokeWidth;

  const _HighlightOutline({
    required this.accentColor,
    this.alpha = 1.0,
    this.isMoving = false,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: AppCardContourPainter(
        radius: 12.0,
        strokeWidth: isMoving ? max(2.0, strokeWidth + 0.5) : strokeWidth,
        accentColor: accentColor,
        alpha: alpha,
        isMoving: isMoving,
      ),
      child: const SizedBox.expand(),
    );
  }
}

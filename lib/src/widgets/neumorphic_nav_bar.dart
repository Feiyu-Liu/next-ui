import 'package:flutter/material.dart';
import 'package:smooth_corner/smooth_corner.dart';

/// 导航栏的数据模型
class NeumorphicNavItem {
  /// 导航栏文本
  final String label;

  /// 默认（未选中）状态下的图标
  final IconData icon;

  /// 选中状态下的图标，如果不提供，则默认使用 [icon]
  final IconData? activeIcon;

  const NeumorphicNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });
}

/// 拟物风格的底部导航栏
class NeumorphicNavBar extends StatelessWidget {
  /// 当前选中的索引
  final int selectedIndex;

  /// 点击某一项的回调
  final ValueChanged<int> onItemSelected;

  /// 导航栏的数据列表
  final List<NeumorphicNavItem> items;

  /// 整体的高度
  final double height;

  /// 外层白色边框的内边距
  final EdgeInsets padding;

  /// Uniform inset between the track and the selected thumb.
  final double thumbInset;

  /// 图标尺寸
  final double iconSize;

  /// 文字尺寸
  final double labelFontSize;

  /// 图标与文字的间距
  final double labelSpacing;

  /// 圆角平滑度，取值范围为 0 到 1
  final double smoothness;

  const NeumorphicNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.height = 92,
    this.padding = const EdgeInsets.all(10),
    this.thumbInset = 6,
    this.iconSize = 22,
    this.labelFontSize = 11,
    this.labelSpacing = 2,
    this.smoothness = 0.8,
  }) : assert(smoothness >= 0 && smoothness <= 1),
       assert(thumbInset >= 0);

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Container(
      key: const Key('neumorphic_nav_outer'),
      height: height,
      padding: padding,
      decoration: ShapeDecoration(
        color: dark ? const Color(0xFF1F1F21) : const Color(0xFFF9FAFB),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(height / 2),
          smoothness: smoothness,
          side: dark
              ? const BorderSide(color: Color(0x14FFFFFF))
              : BorderSide.none,
        ),
        // 外层弥散阴影，营造悬浮立体感
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.12 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _InnerTrack(
        selectedIndex: selectedIndex,
        onItemSelected: onItemSelected,
        items: items,
        iconSize: iconSize,
        labelFontSize: labelFontSize,
        labelSpacing: labelSpacing,
        smoothness: smoothness,
        thumbInset: thumbInset,
      ),
    );
  }
}

class _InnerTrack extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NeumorphicNavItem> items;
  final double iconSize;
  final double labelFontSize;
  final double labelSpacing;
  final double smoothness;
  final double thumbInset;

  const _InnerTrack({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    required this.iconSize,
    required this.labelFontSize,
    required this.labelSpacing,
    required this.smoothness,
    required this.thumbInset,
  });

  @override
  State<_InnerTrack> createState() => _InnerTrackState();
}

class _InnerTrackState extends State<_InnerTrack> {
  bool _isDragging = false;
  bool _isPressed = false;
  double? _dragLeft;

  @override
  void didUpdateWidget(covariant _InnerTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.selectedIndex != widget.selectedIndex) {
      _dragLeft = null;
    }
  }

  double _clampDragLeft(double left, double maxLeft) {
    return left.clamp(0.0, maxLeft).toDouble();
  }

  int _indexFromThumbLeft(double left, double itemWidth) {
    final double center = left + (itemWidth / 2);
    final int index = (center / itemWidth).floor();
    return index.clamp(0, widget.items.length - 1);
  }

  void _handleDragStart(double itemWidth, double maxLeft) {
    setState(() {
      _isDragging = true;
      _isPressed = true;
      _dragLeft = _clampDragLeft(widget.selectedIndex * itemWidth, maxLeft);
    });
  }

  void _handleDragUpdate(double delta, double maxLeft) {
    if (!_isDragging) {
      return;
    }

    setState(() {
      _dragLeft = _clampDragLeft((_dragLeft ?? 0) + delta, maxLeft);
    });
  }

  void _handleDragEnd(double itemWidth, double maxLeft) {
    final double resolvedLeft = _clampDragLeft(
      _dragLeft ?? (widget.selectedIndex * itemWidth),
      maxLeft,
    );
    final int targetIndex = _indexFromThumbLeft(resolvedLeft, itemWidth);

    setState(() {
      _isDragging = false;
      _isPressed = false;
      _dragLeft = null;
    });

    if (targetIndex != widget.selectedIndex) {
      widget.onItemSelected(targetIndex);
    }
  }

  void _handleDragCancel() {
    setState(() {
      _isDragging = false;
      _isPressed = false;
      _dragLeft = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        final double trackHeight = constraints.maxHeight;

        // 保证不越界
        if (widget.items.isEmpty || trackWidth <= 0 || trackHeight <= 0) {
          return const SizedBox.shrink();
        }

        final double itemWidth = trackWidth / widget.items.length;
        final double maxLeft = trackWidth - itemWidth;
        final double thumbLeft = _isDragging
            ? _clampDragLeft(
                _dragLeft ?? (widget.selectedIndex * itemWidth),
                maxLeft,
              )
            : widget.selectedIndex * itemWidth;
        final double thumbScale = _isPressed ? 1.10 : 1.0;
        final double thumbBlur = _isPressed ? 16 : 12;
        final double thumbOffsetY = _isPressed ? 8 : 6;

        final trackShape = SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(trackHeight / 2),
          smoothness: widget.smoothness,
          side: dark
              ? const BorderSide(color: Color(0x14FFFFFF))
              : BorderSide.none,
        );

        return Container(
          key: const Key('neumorphic_nav_track'),
          width: trackWidth,
          height: trackHeight,
          decoration: ShapeDecoration(
            color: dark ? const Color(0xFF1F1F21) : const Color(0xFFF2F3F5),
            shape: trackShape,
          ),
          child: Stack(
            children: [
              // 内阴影：通过 CustomPaint 绘制
              Positioned.fill(
                child: CustomPaint(
                  painter: _InnerShadowPainter(
                    shadowColor: Colors.black.withValues(
                      alpha: dark ? 0.25 : 0.08,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 5), // 上部的深色内阴影，由上往下投射
                    shape: trackShape,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _InnerShadowPainter(
                    shadowColor: Colors.white.withValues(
                      alpha: dark ? 0.08 : 0.9,
                    ),
                    blurRadius: 10,
                    offset: Offset(0, dark ? 5 : -5),
                    shape: trackShape,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _InnerShadowPainter(
                    shadowColor: Colors.black.withValues(
                      alpha: dark ? 0.30 : 0.12,
                    ), // 加深：0.04 -> 0.12
                    blurRadius: 8, // 稍微扩散一点
                    offset: const Offset(0, -4), // 底部明显的深色内阴影，增加底部厚度感
                    shape: trackShape,
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: _isDragging
                    ? const Duration(milliseconds: 250)
                    : const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                left: thumbLeft,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.all(widget.thumbInset),
                    child: AnimatedScale(
                      key: const Key('neumorphic_nav_thumb_visual'),
                      scale: thumbScale,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: ShapeDecoration(
                          color: dark
                              ? const Color(0xFFF2F2F3)
                              : const Color(0xFF222224),
                          shape: SmoothRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              (trackHeight / 2 - widget.thumbInset).clamp(
                                0.0,
                                double.infinity,
                              ),
                            ),
                            smoothness: widget.smoothness,
                          ),
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: dark ? 0.5 : 0.3,
                              ),
                              blurRadius: thumbBlur,
                              offset: Offset(0, thumbOffsetY),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 导航栏的图文按钮
              Row(
                children: List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  final isSelected = index == widget.selectedIndex;
                  // 根据状态获取对应的图标
                  final displayIcon = isSelected
                      ? (item.activeIcon ?? item.icon)
                      : item.icon;

                  return GestureDetector(
                    onTap: () => widget.onItemSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: itemWidth,
                      height: trackHeight,
                      child: TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        tween: ColorTween(
                          begin: dark
                              ? const Color(0xFF8D8D94)
                              : const Color(0xFF6A6A6A),
                          end: isSelected
                              ? (dark ? const Color(0xFF161618) : Colors.white)
                              : (dark
                                    ? const Color(0xFF8D8D94)
                                    : const Color(0xFF6A6A6A)),
                        ),
                        builder: (context, color, child) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // 添加这个防止高度溢出
                            children: [
                              Icon(
                                displayIcon,
                                color: color,
                                size: widget.iconSize,
                              ),
                              SizedBox(height: widget.labelSpacing),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: widget.labelFontSize,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                maxLines: 1, // 限制单行
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),

              // 只有滑块区域本身能接收拖拽，视觉层仍保持在图标文字下方。
              AnimatedPositioned(
                duration: _isDragging
                    ? const Duration(milliseconds: 250)
                    : const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                left: thumbLeft,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    if (_isPressed) {
                      return;
                    }
                    setState(() {
                      _isPressed = true;
                    });
                  },
                  onPointerUp: (_) {
                    if (!_isDragging && _isPressed) {
                      setState(() {
                        _isPressed = false;
                      });
                    }
                  },
                  onPointerCancel: (_) {
                    if (_isPressed && !_isDragging) {
                      setState(() {
                        _isPressed = false;
                      });
                    }
                  },
                  child: GestureDetector(
                    key: const Key('neumorphic_nav_thumb'),
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) =>
                        _handleDragStart(itemWidth, maxLeft),
                    onHorizontalDragUpdate: (details) =>
                        _handleDragUpdate(details.delta.dx, maxLeft),
                    onHorizontalDragEnd: (_) =>
                        _handleDragEnd(itemWidth, maxLeft),
                    onHorizontalDragCancel: _handleDragCancel,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 绘制内阴影的画笔
class _InnerShadowPainter extends CustomPainter {
  final Color shadowColor;
  final double blurRadius;
  final Offset offset;
  final SmoothRectangleBorder shape;

  _InnerShadowPainter({
    required this.shadowColor,
    required this.blurRadius,
    required this.offset,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shapePath = shape.getOuterPath(rect);

    // 裁剪掉超出组件范围的绘制
    canvas.clipPath(shapePath);

    final Paint paint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    // 构建一个足够大以至于包含了我们整个画布的路径，然后在中间挖空一个我们组件的形状
    // 这里采用 evenOdd 填充模式，使我们在画出边界外的图形时，中心是被挖空的。
    // 当带有模糊的面具偏移后，边缘模糊的效果就会侵入到组件的内部，形成内阴影。
    final Path path = Path()
      ..addRect(rect.inflate(blurRadius * 4))
      ..addPath(shapePath, Offset.zero)
      ..fillType = PathFillType.evenOdd;

    // 绘制偏移后的路径
    canvas.drawPath(path.shift(offset), paint);
  }

  @override
  bool shouldRepaint(_InnerShadowPainter oldDelegate) {
    return oldDelegate.shadowColor != shadowColor ||
        oldDelegate.blurRadius != blurRadius ||
        oldDelegate.offset != offset ||
        oldDelegate.shape != shape;
  }
}

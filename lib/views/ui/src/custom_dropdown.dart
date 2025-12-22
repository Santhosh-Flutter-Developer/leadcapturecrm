// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '/theme/theme.dart';

/// CustomSearchableDropdown supports single-select and multi-select modes.
/// - For single-select: provide `initialValue` and `onChanged: (T?)`.
/// - For multi-select: set `multiSelect: true`, provide `initialValues` and `onChangedList`.
class CustomSearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? initialValue;
  final List<T>? initialValues; // for multi-select
  final ValueChanged<T?>? onChanged; // single select callback
  final ValueChanged<List<T>>? onChangedList; // multi select callback
  final bool multiSelect;
  final String Function(T)? itemAsString;
  final String hintText;
  final double maxPanelHeight;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget? emptyWidget;
  final bool showDoneButton; // show done to confirm selections in multi-select

  const CustomSearchableDropdown({
    super.key,
    required this.items,
    this.initialValue,
    this.initialValues,
    this.onChanged,
    this.onChangedList,
    this.multiSelect = false,
    this.itemAsString,
    this.hintText = 'Select',
    this.maxPanelHeight = 280,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.emptyWidget,
    this.showDoneButton = true,
  });

  @override
  State<CustomSearchableDropdown<T>> createState() =>
      _CustomSearchableDropdownState<T>();
}

class _CustomSearchableDropdownState<T>
    extends State<CustomSearchableDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _panelFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late List<T> _filtered;
  T? _selected;
  final List<T> _selectedList = [];
  int _highlightIndex = -1;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    _filtered = List<T>.from(widget.items);

    if (widget.multiSelect && widget.initialValues != null) {
      _selectedList.addAll(widget.initialValues!);
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant CustomSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filtered = List<T>.from(widget.items);
      _overlayEntry?.markNeedsBuild();
    }
    if (widget.multiSelect && widget.initialValues != oldWidget.initialValues) {
      _selectedList
        ..clear()
        ..addAll(widget.initialValues ?? []);
      _overlayEntry?.markNeedsBuild();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _searchFocus.dispose();
    _panelFocus.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _open() {
    if (_isOpen) return;
    _filtered = List<T>.from(widget.items);
    _highlightIndex = widget.multiSelect
        ? (_selectedList.isNotEmpty
              ? widget.items.indexOf(_selectedList.first)
              : -1)
        : (_selected != null ? _filtered.indexOf(_selected as T) : -1);
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _panelFocus.requestFocus();
        _searchFocus.requestFocus();
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      }
    });
  }

  void _close({bool returnFocus = true, bool notify = true}) {
    if (!_isOpen) return;
    _removeOverlay();
    setState(() => _isOpen = false);
    if (returnFocus) {
      _focusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }

    if (widget.multiSelect && notify) {
      widget.onChangedList?.call(List<T>.from(_selectedList));
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _onItemSelectedSingle(T item) {
    widget.onChanged?.call(item);
    setState(() {
      _selected = item;
    });
    _close();
  }

  void _onItemToggledMulti(T item) {
    final already = _selectedList.indexWhere((e) => e == item) >= 0;
    setState(() {
      if (already) {
        _selectedList.removeWhere((e) => e == item);
      } else {
        _selectedList.add(item);
      }
    });

    // update overlay immediately
    _overlayEntry?.markNeedsBuild();
    // do not close on multi-select tap; user will press Done (or you can set notify immediate)
    // optionally notify live changes:
    // widget.onChangedList?.call(List<T>.from(_selectedList));
  }

  /// Called from controller listener - this filters items and calls setState so
  /// the panel updates as the user types (and also when cleared programmatically).
  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<T>.from(widget.items);
      } else {
        _filtered = widget.items.where((it) {
          final s = (widget.itemAsString?.call(it) ?? it.toString())
              .toLowerCase();
          return s.contains(q);
        }).toList();
      }
      if (_filtered.isEmpty) {
        _highlightIndex = -1;
      } else {
        _highlightIndex = (_highlightIndex >= _filtered.length)
            ? _filtered.length - 1
            : (_highlightIndex < 0 ? 0 : _highlightIndex);
      }
    });

    if (_overlayEntry != null) _overlayEntry!.markNeedsBuild();
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final globalTopLeft = renderBox.localToGlobal(Offset.zero);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final topPadding = media.padding.top;
    const verticalMargin = 8.0;

    final availableBelow =
        screenHeight - (globalTopLeft.dy + size.height) - verticalMargin;
    final availableAbove = globalTopLeft.dy - topPadding - verticalMargin;

    final preferBelow =
        availableBelow >= math.min(widget.maxPanelHeight, availableAbove);

    final double panelHeight = preferBelow
        ? math.min(widget.maxPanelHeight, availableBelow)
        : math.min(widget.maxPanelHeight, availableAbove);

    final double constrainedPanelHeight = panelHeight > 0
        ? panelHeight
        : math.min(
            widget.maxPanelHeight,
            screenHeight - topPadding - verticalMargin * 2,
          );

    final isAbove = !preferBelow;

    final targetAnchor = isAbove ? Alignment.topLeft : Alignment.bottomLeft;
    final followerAnchor = isAbove ? Alignment.bottomLeft : Alignment.topLeft;
    final double gap = 6.0;

    return OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            onTap: () => _close(returnFocus: false, notify: widget.multiSelect),
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  targetAnchor: targetAnchor,
                  followerAnchor: followerAnchor,
                  offset: isAbove ? Offset(0, -gap) : Offset(0, gap),
                  child: Material(
                    elevation: 6,
                    borderRadius: widget.borderRadius,
                    child: SizedBox(
                      width: size.width,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constrainedPanelHeight,
                          minWidth: size.width,
                        ),
                        child: RawKeyboardListener(
                          focusNode: _panelFocus,
                          onKey: (RawKeyEvent event) {
                            if (event is RawKeyDownEvent) {
                              final key = event.logicalKey;
                              if (key == LogicalKeyboardKey.escape) {
                                _close();
                              } else if (key == LogicalKeyboardKey.arrowDown) {
                                setState(() {
                                  if (_filtered.isNotEmpty) {
                                    _highlightIndex =
                                        (_highlightIndex + 1) %
                                        _filtered.length;
                                  }
                                });
                              } else if (key == LogicalKeyboardKey.arrowUp) {
                                setState(() {
                                  if (_filtered.isNotEmpty) {
                                    _highlightIndex = _highlightIndex <= 0
                                        ? _filtered.length - 1
                                        : _highlightIndex - 1;
                                  }
                                });
                              } else if (key == LogicalKeyboardKey.enter) {
                                if (_highlightIndex >= 0 &&
                                    _highlightIndex < _filtered.length) {
                                  final item = _filtered[_highlightIndex];
                                  if (widget.multiSelect) {
                                    _onItemToggledMulti(item);
                                  } else {
                                    _onItemSelectedSingle(item);
                                  }
                                }
                              }
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Search field
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Search...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              _overlayEntry?.markNeedsBuild();
                                            },
                                          ),
                                  ),
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (_) {
                                    if (_filtered.isNotEmpty) {
                                      final item = _filtered[0];
                                      if (widget.multiSelect) {
                                        _onItemToggledMulti(item);
                                      } else {
                                        _onItemSelectedSingle(item);
                                      }
                                    }
                                  },
                                ),
                              ),

                              // list / empty
                              if (_filtered.isEmpty)
                                widget.emptyWidget ??
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No items found.',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    )
                              else
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filtered.length,
                                    itemBuilder: (context, index) {
                                      final item = _filtered[index];
                                      final label =
                                          widget.itemAsString?.call(item) ??
                                          item.toString();
                                      final isHighlighted =
                                          index == _highlightIndex;
                                      final isSelectedSingle =
                                          !widget.multiSelect &&
                                          item == _selected;
                                      final isSelectedMulti =
                                          widget.multiSelect &&
                                          _selectedList.indexWhere(
                                                (e) => e == item,
                                              ) >=
                                              0;

                                      return InkWell(
                                        onTap: () {
                                          if (widget.multiSelect) {
                                            _onItemToggledMulti(item);
                                          } else {
                                            _onItemSelectedSingle(item);
                                          }
                                        },
                                        child: Container(
                                          color: isHighlighted
                                              ? theme.colorScheme.primary
                                                    .withOpacity(0.12)
                                              : null,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  label,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ),
                                              if (isSelectedSingle ||
                                                  isSelectedMulti)
                                                Icon(
                                                  Icons.check,
                                                  size: 18,
                                                  color:
                                                      theme.colorScheme.primary,
                                                )
                                              else if (widget.multiSelect)
                                                const SizedBox(width: 18),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Done / actions for multi-select
                              if (widget.multiSelect && widget.showDoneButton)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            // cancel -> close without notifying (use notify false)
                                            _close(
                                              returnFocus: true,
                                              notify: false,
                                            );
                                          },
                                          child: Text(
                                            'Cancel',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                          ),
                                          onPressed: () {
                                            // confirm selection and notify
                                            widget.onChangedList?.call(
                                              List<T>.from(_selectedList),
                                            );
                                            _close(
                                              returnFocus: true,
                                              notify: false,
                                            );
                                          },
                                          child: Text(
                                            // 'Done (${_selectedList.length})',
                                            'Done',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.white,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
        _toggle();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowDown) {
        if (!_isOpen) {
          _open();
        } else {
          _panelFocus.requestFocus();
          _searchFocus.requestFocus();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildActivatorContent(String? displayText) {
    if (widget.multiSelect) {
      if (_selectedList.isEmpty) {
        return Text(
          displayText ?? widget.hintText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: displayText == null
                ? Theme.of(context).hintColor
                : AppColors.black,
          ),
          overflow: TextOverflow.ellipsis,
        );
      }

      // show small chips, or a compact summary if too many
      const maxChipsToShow = 3;
      final chips = _selectedList.take(maxChipsToShow).map((it) {
        final label = widget.itemAsString?.call(it) ?? it.toString();
        return Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList();

      final remaining = _selectedList.length - chips.length;
      return Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ),
          if (remaining > 0)
            Text(
              '+$remaining',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.black54),
            ),
        ],
      );
    } else {
      return Text(
        displayText ?? widget.hintText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: displayText == null
              ? Theme.of(context).hintColor
              : AppColors.black,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _selected != null
        ? (widget.itemAsString?.call(_selected as T) ?? _selected.toString())
        : null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        onFocusChange: (hasFocus) {
          if (mounted) setState(() {});
          if (!hasFocus && _isOpen) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted &&
                  !_searchFocus.hasFocus &&
                  !_panelFocus.hasFocus &&
                  !_focusNode.hasFocus) {
                _close(returnFocus: false, notify: widget.multiSelect);
              }
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _focusNode.requestFocus();
            _toggle();
          },
          child: Container(
            padding: widget.padding,
            height: 33,
            decoration: BoxDecoration(
              border: Border.all(
                color: _focusNode.hasFocus
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.grey500,
                width: _focusNode.hasFocus ? 2 : 1,
              ),
              borderRadius: widget.borderRadius,
            ),
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(child: _buildActivatorContent(displayText)),
                const SizedBox(width: 6),
                Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

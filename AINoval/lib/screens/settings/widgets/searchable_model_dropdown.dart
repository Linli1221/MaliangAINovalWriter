import 'package:flutter/material.dart';

/// 可搜索的模型下拉框
/// 允许用户搜索和选择模型
class SearchableModelDropdown extends StatefulWidget {
  const SearchableModelDropdown({
    super.key,
    required this.models,
    required this.onModelSelected,
    this.hintText = '搜索模型',
    this.onMultipleModelsSelected,
    this.selectedModels,
  });

  final List<String> models;
  final ValueChanged<String> onModelSelected;
  final String hintText;
  final ValueChanged<List<String>>? onMultipleModelsSelected;
  final List<String>? selectedModels;

  @override
  State<SearchableModelDropdown> createState() => _SearchableModelDropdownState();
}

class _SearchableModelDropdownState extends State<SearchableModelDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  String _searchText = '';
  bool _isDropdownOpen = false;
  late Set<String> _selectedModels;
  
  @override
  void initState() {
    super.initState();
    _selectedModels = Set<String>.from(widget.selectedModels ?? []);
  }
  
  @override
  void didUpdateWidget(covariant SearchableModelDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedModels != oldWidget.selectedModels) {
      setState(() {
        _selectedModels = Set<String>.from(widget.selectedModels ?? []);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
      if (_isDropdownOpen) {
        _updateOverlay();
      } else if (_searchText.isNotEmpty) {
        _showOverlay();
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    _isDropdownOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isDropdownOpen = false;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 250,
                  minWidth: size.width,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: _buildDropdownList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownList() {
    final filteredModels = widget.models
        .where((model) => model.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    if (filteredModels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(
          child: Text(
            '没有找到匹配的模型',
            style: TextStyle(fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      itemCount: filteredModels.length,
      itemBuilder: (context, index) {
        final model = filteredModels[index];
        final isSelected = _selectedModels.contains(model);
        
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          // 在多选模式下显示复选框
          leading: widget.onMultipleModelsSelected != null
            ? Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  _toggleModelSelection(model);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )
            : null,
          title: Text(
            model,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: widget.onMultipleModelsSelected != null
            ? () => _toggleModelSelection(model)
            : () {
                widget.onModelSelected(model);
                _searchController.clear();
                _removeOverlay();
                _focusNode.unfocus();
              },
        );
      },
    );
  }
  
  void _toggleModelSelection(String model) {
    setState(() {
      if (_selectedModels.contains(model)) {
        _selectedModels.remove(model);
      } else {
        _selectedModels.add(model);
      }
    });
    
    // 通知父组件选择了多个模型
    widget.onMultipleModelsSelected?.call(_selectedModels.toList());
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            color: Theme.of(context).hintColor.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
              : Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          isDense: true,
        ),
      ),
    );
  }
}

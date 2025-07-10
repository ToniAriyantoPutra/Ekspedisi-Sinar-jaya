import 'package:app_projekskripsi/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const AnimatedSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  _AnimatedSearchBarState createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _isExpanded ? MediaQuery.of(context).size.width - 32 : 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 16),
              child: _isExpanded
                  ? TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
              )
                  : null,
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    _isExpanded ? Icons.close : Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (!_isExpanded) {
                      widget.controller.clear();
                      widget.onChanged('');
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


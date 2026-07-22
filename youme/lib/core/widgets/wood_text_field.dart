import 'package:flutter/material.dart';
import '../theme/colors.dart';

class WoodTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const WoodTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<WoodTextField> createState() => _WoodTextFieldState();
}

class _WoodTextFieldState extends State<WoodTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusBorderAnim;
  bool _obscure = true;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusBorderAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowGold.withValues(alpha: _focusBorderAnim.value * 0.4),
                blurRadius: 16,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText && _obscure,
            keyboardType: widget.keyboardType,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            validator: widget.validator,
            style: const TextStyle(
              color: AppColors.woodDark,
              fontFamily: 'Lato',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              filled: true,
              fillColor: Color.lerp(
                AppColors.creamBase,
                AppColors.creamLight,
                _focusBorderAnim.value,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.woodHighlight, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.woodSatin, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Color.lerp(AppColors.woodHighlight, AppColors.goldPrimary, _focusBorderAnim.value)!,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              labelStyle: const TextStyle(color: AppColors.woodMedium, fontFamily: 'Lato'),
              hintStyle: TextStyle(color: AppColors.woodMedium.withValues(alpha: 0.5)),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.woodMedium, size: 20)
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.woodMedium),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : widget.suffix,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fully Customizable & Reusable Text Field
/// Matches your app theme with extensive customization options
class CustomTextField extends StatefulWidget {
  // Controllers & Focus
  final TextEditingController? controller;
  final FocusNode? focusNode;

  // Labels & Hints
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final String? counterText;

  // Icons & Widgets
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onSuffixIconTap;
  final VoidCallback? onPrefixIconTap;

  // Input Configuration
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final int? maxLines; // Changed to nullable
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final bool expands;

  // Validation & Formatting
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  // Callbacks
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;

  // Styling
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? cursorColor;
  final double? cursorHeight;
  final double? cursorWidth;
  final Radius? cursorRadius;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final double focusedBorderWidth;

  // Features
  final bool showBorder;
  final bool filled;
  final bool isDense;
  final bool showCounter;
  final bool required;
  final bool showClearButton;
  final bool showPasswordToggle;

  const CustomTextField({
    super.key,
    // Controllers & Focus
    this.controller,
    this.focusNode,

    // Labels & Hints
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.counterText,

    // Icons & Widgets
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onSuffixIconTap,
    this.onPrefixIconTap,

    // Input Configuration
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.expands = false,

    // Validation & Formatting
    this.inputFormatters,
    this.validator,
    this.autovalidateMode,

    // Callbacks
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,

    // Styling
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.helperStyle,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.cursorColor,
    this.cursorHeight,
    this.cursorWidth,
    this.cursorRadius,
    this.contentPadding,
    this.borderRadius,
    this.borderWidth = 1.0,
    this.focusedBorderWidth = 2.0,

    // Features
    this.showBorder = true,
    this.filled = true,
    this.isDense = false,
    this.showCounter = false,
    this.required = false,
    this.showClearButton = false,
    this.showPasswordToggle = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();

  // ============================================
  // STATIC FACTORY METHODS (Pre-configured variants)
  // ============================================

  /// Email TextField
  static CustomTextField email({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Email',
      hint: hint ?? 'you@example.com',
      errorText: errorText,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      validator: validator,
      required: required,
      showClearButton: true,
    );
  }

  /// Password TextField
  static CustomTextField password({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Password',
      hint: hint ?? 'Enter your password',
      errorText: errorText,
      prefixIcon: Icons.lock_outline,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      required: required,
      showPasswordToggle: true,
    );
  }

  /// Search TextField
  static CustomTextField search({
    TextEditingController? controller,
    String? hint,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return CustomTextField(
      controller: controller,
      hint: hint ?? 'Search...',
      prefixIcon: Icons.search,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      showClearButton: true,
      borderRadius: BorderRadius.circular(24),
    );
  }

  /// Multiline TextField (Text Area)
  static CustomTextField multiline({
    TextEditingController? controller,
    String? label,
    String? hint,
    IconData? prefixIcon,
    String? errorText,
    int? maxLines = 5,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: maxLines,
      minLines: 2,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      required: required,
      showCounter: maxLength != null,
    );
  }

  /// Singleline TextField
  static CustomTextField singleline({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
    IconData? prefixIcon,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      maxLines: 1,
      minLines: 1,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      required: required,
      showCounter: maxLength > 0,
    );
  }

  /// Number TextField
  static CustomTextField number({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool required = false,
    bool allowDecimal = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      prefixIcon: Icons.numbers,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: onChanged,
      validator: validator,
      required: required,
    );
  }

  /// URL TextField
  static CustomTextField url({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'URL',
      hint: hint ?? 'https://example.com',
      errorText: errorText,
      prefixIcon: Icons.link,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      validator: validator,
      required: required,
      showClearButton: true,
    );
  }
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  bool _isFocused = false;

  VoidCallback? _controllerListener;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;

    _focusNode.addListener(_onFocusChange);

    // Store listener so we can remove it later
    _controllerListener = () {
      if (!mounted) return;
      setState(() {});
    };

    _controller.addListener(_controllerListener!);
  }

  @override
  void dispose() {
    // Remove listener to avoid setState after dispose
    if (_controllerListener != null) {
      _controller.removeListener(_controllerListener!);
    }

    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();

    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,

      // Input Configuration
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textDirection: widget.textDirection ?? TextDirection.ltr,
      textAlign: widget.textAlign,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: _obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      expands: widget.expands,

      // Validation & Formatting
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,

      // Callbacks
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onEditingComplete: widget.onEditingComplete,

      // Styling
      style:
          widget.style ??
          theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      cursorColor: widget.cursorColor ?? colorScheme.primary,
      cursorHeight: widget.cursorHeight,
      cursorWidth: widget.cursorWidth ?? 2.0,
      cursorRadius: widget.cursorRadius ?? const Radius.circular(2),

      decoration: InputDecoration(
        // Labels
        labelText: widget.required && widget.label != null
            ? '${widget.label} *'
            : widget.label,
        labelStyle:
            widget.labelStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: _isFocused
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
        floatingLabelStyle:
            widget.labelStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),

        // Hints & Helper Text
        hintText: widget.hint,
        hintStyle:
            widget.hintStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontWeight: FontWeight.w400,
            ),
        helperText: widget.helperText,
        helperStyle:
            widget.helperStyle ??
            theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
        helperMaxLines: 2,

        // Error Text
        errorText: widget.errorText,
        errorStyle:
            widget.errorStyle ??
            theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
        errorMaxLines: 2,

        // Counter
        counterText: widget.showCounter ? widget.counterText : '',
        counterStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),

        // Prefix
        prefixText: widget.prefixText,
        prefixStyle: theme.textTheme.bodyLarge,
        prefix: widget.prefix,
        prefixIcon: widget.prefixIcon != null
            ? GestureDetector(
                onTap: widget.onPrefixIconTap,
                child: Icon(
                  widget.prefixIcon,
                  color: _isFocused
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),

        // Suffix
        suffixText: widget.suffixText,
        suffixStyle: theme.textTheme.bodyLarge,
        suffix: widget.suffix,
        suffixIcon: _buildSuffixIcon(colorScheme),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),

        // Fill
        filled: widget.filled,
        fillColor:
            widget.fillColor ??
            (widget.enabled
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHighest.withOpacity(0.5)),

        // Padding
        contentPadding:
            widget.contentPadding ??
            EdgeInsets.symmetric(
              horizontal: 16,
              vertical: (widget.maxLines == null || widget.maxLines! > 1)
                  ? 16
                  : 14,
            ),
        isDense: widget.isDense,

        // Borders
        border: _buildBorder(colorScheme.outline, widget.borderWidth),
        enabledBorder: _buildBorder(
          widget.borderColor ?? colorScheme.outline,
          widget.borderWidth,
        ),
        focusedBorder: _buildBorder(
          widget.focusedBorderColor ?? colorScheme.primary,
          widget.focusedBorderWidth,
        ),
        errorBorder: _buildBorder(
          widget.errorBorderColor ?? colorScheme.error,
          widget.borderWidth,
        ),
        focusedErrorBorder: _buildBorder(
          widget.errorBorderColor ?? colorScheme.error,
          widget.focusedBorderWidth,
        ),
        disabledBorder: _buildBorder(
          colorScheme.outline.withOpacity(0.5),
          widget.borderWidth,
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme) {
    final List<Widget> suffixWidgets = [];

    // Password Toggle (takes priority)
    if (widget.showPasswordToggle && widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: _isFocused
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        onPressed: _togglePasswordVisibility,
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      );
    }

    // Clear Button
    if (widget.showClearButton && _controller.text.isNotEmpty) {
      suffixWidgets.add(
        IconButton(
          icon: Icon(
            Icons.clear,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: _clearText,
          tooltip: 'Clear',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }

    // Custom Suffix Icon
    if (widget.suffixIcon != null) {
      suffixWidgets.add(
        GestureDetector(
          onTap: widget.onSuffixIconTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              widget.suffixIcon,
              color: _isFocused
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Return combined message_bubbles or null
    if (suffixWidgets.isEmpty) return null;
    if (suffixWidgets.length == 1) return suffixWidgets.first;

    return Row(mainAxisSize: MainAxisSize.min, children: suffixWidgets);
  }

  InputBorder _buildBorder(Color color, double width) {
    if (!widget.showBorder) {
      return InputBorder.none;
    }

    return OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

InputDecoration appInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? helperText,
  String? suffixText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  EdgeInsetsGeometry? contentPadding,
  bool? filled,
  Color? fillColor,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    suffixText: suffixText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: filled,
    fillColor: fillColor,
    contentPadding: contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
    border: OutlineInputBorder(
      borderRadius: AppRadius.buttonRadius,
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.buttonRadius,
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.buttonRadius,
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.buttonRadius,
      borderSide: BorderSide(
        color: theme.colorScheme.error,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.buttonRadius,
      borderSide: BorderSide(
        color: theme.colorScheme.error,
        width: 1.5,
      ),
    ),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.contentPadding,
    this.filled,
    this.fillColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      decoration: appInputDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding,
        filled: filled,
        fillColor: fillColor,
      ),
    );
  }
}

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.autovalidateMode,
    this.contentPadding,
    this.filled,
    this.fillColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final FormFieldValidator<String>? validator;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? contentPadding;
  final bool? filled;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      validator: validator,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode,
      decoration: appInputDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding,
        filled: filled,
        fillColor: fillColor,
      ),
    );
  }
}

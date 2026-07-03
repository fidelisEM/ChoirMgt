import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/validation_service.dart';

// Validated text form field
class ValidatedTextFormField extends StatefulWidget {

  const ValidatedTextFormField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.required = false,
    this.enabled = true,
    this.controller,
  });
  final String label;
  final String? hint;
  final String? initialValue;
  final Function(String value)? onChanged;
  final Function(String value)? onSaved;
  final ValidationResult Function(String? value)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool required;
  final bool enabled;
  final TextEditingController? controller;

  @override
  State<ValidatedTextFormField> createState() => _ValidatedTextFormFieldState();
}

class _ValidatedTextFormFieldState extends State<ValidatedTextFormField> {
  late final TextEditingController _controller;
  ValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final value = _controller.text;
    widget.onChanged?.call(value);
    
    if (widget.validator != null) {
      setState(() {
        _validationResult = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            text: widget.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
            children: widget.required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        
        // Text field
        TextFormField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.grey[50] : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (widget.validator != null) {
              final result = widget.validator!(value);
              return result.isValid ? null : result.error;
            }
            return null;
          },
          onSaved: (value) => widget.onSaved?.call(value ?? ''),
        ),
        
        // Validation message
        if (_validationResult != null && !_validationResult!.isValid) ...[
          const SizedBox(height: 4),
          Text(
            _validationResult!.error!,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// Email input field
class EmailFormField extends StatelessWidget {

  const EmailFormField({
    super.key,
    this.label = 'Email Address',
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.required = true,
    this.controller,
  });
  final String label;
  final String? initialValue;
  final Function(String value)? onChanged;
  final Function(String value)? onSaved;
  final bool required;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return ValidatedTextFormField(
      label: label,
      hint: 'Enter email address',
      initialValue: initialValue,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: TextInputType.emailAddress,
      validator: (value) => ValidationService().validateEmail(value),
      prefixIcon: const Icon(Icons.email_outlined),
      required: required,
      controller: controller,
    );
  }
}

// Phone number input field
class PhoneFormField extends StatelessWidget {

  const PhoneFormField({
    super.key,
    this.label = 'Phone Number',
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.required = true,
    this.controller,
  });
  final String label;
  final String? initialValue;
  final Function(String value)? onChanged;
  final Function(String value)? onSaved;
  final bool required;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return ValidatedTextFormField(
      label: label,
      hint: 'Enter phone number',
      initialValue: initialValue,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: TextInputType.phone,
      validator: (value) => ValidationService().validatePhoneNumber(value),
      prefixIcon: const Icon(Icons.phone_outlined),
      required: required,
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-\(\)\+]')),
      ],
    );
  }
}

// Name input field
class NameFormField extends StatelessWidget {

  const NameFormField({
    super.key,
    this.label = 'Full Name',
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.required = true,
    this.controller,
  });
  final String label;
  final String? initialValue;
  final Function(String value)? onChanged;
  final Function(String value)? onSaved;
  final bool required;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return ValidatedTextFormField(
      label: label,
      hint: 'Enter full name',
      initialValue: initialValue,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: TextInputType.name,
      validator: (value) => ValidationService().validateName(value, fieldName: label),
      prefixIcon: const Icon(Icons.person_outline),
      required: required,
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-'\.']")),
      ],
    );
  }
}

// Password input field
class PasswordFormField extends StatefulWidget {

  const PasswordFormField({
    super.key,
    this.label = 'Password',
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.required = true,
    this.controller,
  });
  final String label;
  final String? initialValue;
  final Function(String value)? onChanged;
  final Function(String value)? onSaved;
  final bool required;
  final TextEditingController? controller;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return ValidatedTextFormField(
      label: widget.label,
      hint: 'Enter password',
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      obscureText: _obscureText,
      validator: (value) => ValidationService().validatePassword(value),
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
      required: widget.required,
      controller: widget.controller,
    );
  }
}

// Amount/Money input field
class AmountFormField extends StatelessWidget {

  const AmountFormField({
    super.key,
    this.label = 'Amount',
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.required = true,
    this.controller,
    this.currency = '\$',
  });
  final String label;
  final String? initialValue;
  final Function(String value)? onChanged;
  final Function(String value)? onSaved;
  final bool required;
  final TextEditingController? controller;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return ValidatedTextFormField(
      label: label,
      hint: 'Enter amount',
      initialValue: initialValue,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) => ValidationService().validateAmount(value, fieldName: label),
      prefixIcon: Container(
        width: 48,
        alignment: Alignment.center,
        child: Text(
          currency,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      required: required,
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          // Allow only one decimal point
          if (newValue.text.split('.').length > 2) {
            return oldValue;
          }
          return newValue;
        }),
      ],
    );
  }
}

// Registration number field
class RegistrationNumberFormField extends StatelessWidget {

  const RegistrationNumberFormField({
    super.key,
    this.label = 'Registration Number',
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.required = true,
    this.controller,
  });
  final String label;
  final String? initialValue;
  final Function(String value)? onChanged;
  final Function(String value)? onSaved;
  final bool required;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return ValidatedTextFormField(
      label: label,
      hint: 'Enter registration number',
      initialValue: initialValue,
      onChanged: onChanged,
      onSaved: onSaved,
      validator: (value) => ValidationService().validateRegistrationNumber(value),
      prefixIcon: const Icon(Icons.confirmation_number_outlined),
      required: required,
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]')),
      ],
    );
  }
}

// Form section header
class FormSection extends StatelessWidget {

  const FormSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

// Form container with proper spacing
class FormContainer extends StatelessWidget {

  const FormContainer({
    super.key,
    required this.child,
    this.padding,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
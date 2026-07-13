import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'ya_input.dart';
import 'ya_textarea.dart';

class ReactiveYaInput<T> extends ReactiveFormField<T, String> {
  ReactiveYaInput({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    String? label,
    String? placeholder,
    String? hint,
    IconData? icon,
    YaInputSize size = YaInputSize.md,
    bool obscureText = false,
    TextInputType? keyboardType,
    ReactiveFormFieldCallback<T>? onChanged,
    ReactiveFormFieldCallback<T>? onSubmitted,
  }) : super(
          builder: (field) {
            final state = field as _ReactiveYaInputState<T>;
            return YaInput(
              controller: state._textController,
              label: label,
              placeholder: placeholder,
              hint: hint,
              errorText: field.errorText,
              icon: icon,
              size: size,
              obscureText: obscureText,
              keyboardType: keyboardType,
              enabled: field.control.enabled,
              onChanged: (value) {
                field.didChange(value);
                onChanged?.call(field.control);
              },
              onSubmitted: (_) => onSubmitted?.call(field.control),
            );
          },
        );

  @override
  ReactiveFormFieldState<T, String> createState() => _ReactiveYaInputState<T>();
}

class _ReactiveYaInputState<T> extends ReactiveFormFieldState<T, String> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: value ?? '');
  }

  @override
  void onControlValueChanged(dynamic value) {
    final text = value?.toString() ?? '';
    if (_textController.text != text) {
      _textController.value = _textController.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
        composing: TextRange.empty,
      );
    }
    super.onControlValueChanged(value);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ReactiveYaTextarea<T> extends ReactiveFormField<T, String> {
  ReactiveYaTextarea({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    String? placeholder,
    int minLines = 4,
    int maxLines = 8,
    ReactiveFormFieldCallback<T>? onChanged,
  }) : super(
          builder: (field) {
            final state = field as _ReactiveYaTextareaState<T>;
            return YaTextarea(
              controller: state._textController,
              placeholder: placeholder,
              errorText: field.errorText,
              minLines: minLines,
              maxLines: maxLines,
              enabled: field.control.enabled,
              onChanged: (value) {
                field.didChange(value);
                onChanged?.call(field.control);
              },
            );
          },
        );

  @override
  ReactiveFormFieldState<T, String> createState() =>
      _ReactiveYaTextareaState<T>();
}

class _ReactiveYaTextareaState<T> extends ReactiveFormFieldState<T, String> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: value ?? '');
  }

  @override
  void onControlValueChanged(dynamic value) {
    final text = value?.toString() ?? '';
    if (_textController.text != text) {
      _textController.value = _textController.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
        composing: TextRange.empty,
      );
    }
    super.onControlValueChanged(value);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

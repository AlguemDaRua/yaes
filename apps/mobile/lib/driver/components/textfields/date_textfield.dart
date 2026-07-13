import 'package:date_picker_textfield/date_picker_textfield.dart';
import 'package:flutter/material.dart';

class DateInputField extends StatefulWidget {
  const DateInputField({super.key});

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DatePicker(
      type: MyDatePickerFieldTypes.all,
      controller: _controller,
      context: context,
      label: 'Data de nascimento',
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
  }
}

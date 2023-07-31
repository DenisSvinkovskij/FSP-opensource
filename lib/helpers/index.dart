import 'package:flutter/cupertino.dart';

customUpdateInputTextField(TextEditingController controller, String newValue) {
  controller.text = newValue;
  controller.selection =
      TextSelection.fromPosition(TextPosition(offset: controller.text.length));
}

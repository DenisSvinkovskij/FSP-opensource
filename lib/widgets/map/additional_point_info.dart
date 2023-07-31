import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/widgets/map/info_row_with_icon.dart';
import 'package:flutter/material.dart';

class AdditionalPointInfo extends StatelessWidget {
  const AdditionalPointInfo({super.key, required this.info});

  final Map<String, dynamic>? info;

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      return Container();
    }
    log(info.toString());
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          '${tr('additional_info')}:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        InfoRowWithIcon(
          icon: Icons.apartment,
          text: '${tr('category')}: ${info!['sector'] ?? ''}',
        ),
        const SizedBox(height: 5),
        InfoRowWithIcon(
          icon: Icons.ads_click,
          text: '${tr('title_of')}: ${info?['Name'] ?? ''}',
        ),
        const SizedBox(height: 5),
        InfoRowWithIcon(
          icon: Icons.schedule,
          text:
              '${tr('schedule')}: ${info?["grafic"].trim().isNotEmpty ? info!['grafic'] : tr('not_known')}',
        ),
        const SizedBox(height: 5),
        InfoRowWithIcon(
          icon: Icons.bolt_outlined,
          text:
              '${tr('generator')}: ${info!['generator'] ?? false ? tr('have') : tr('not_have')}',
        ),
        const SizedBox(height: 5),
        InfoRowWithIcon(
          icon: Icons.info,
          text: '${tr('remark')}: ${info!['primitka'] ?? ''}',
        ),
      ],
    );
  }
}

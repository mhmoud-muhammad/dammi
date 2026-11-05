import 'package:flutter/material.dart';

import '../core/theme.dart';

/// مربع أحمر يعرض الفصيلة بخط كبير (بطاقات الطلبات).
class BloodTypeBadge extends StatelessWidget {
  final String type;
  final double size;

  const BloodTypeBadge({super.key, required this.type, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Text(
        type,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: type.length > 2 ? size * 0.32 : size * 0.36,
        ),
      ),
    );
  }
}

/// شارة صغيرة للفصيلة (مثل O+ بجانب اسم المتبرع).
class BloodTypeChip extends StatelessWidget {
  final String type;

  const BloodTypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/blood_types.dart';
import '../core/theme.dart';
import '../models/blood_request.dart';
import '../utils/formatters.dart';
import 'blood_type_badge.dart';

/// بطاقة طلب دم في الشاشة الرئيسية.
class RequestCard extends StatelessWidget {
  final BloodRequest request;
  final VoidCallback onTap;

  const RequestCard({super.key, required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final compatible = request.scope == SearchScope.compatible;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BloodTypeBadge(type: request.bloodType),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.patientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          request.isActive ? timeAgo(request.createdAt) : request.status.label,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.hospitalName,
                      style: const TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${unitsLabel(request.units)} · بقي ${arabicDigits(request.remaining)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: compatible ? AppColors.infoSoft : AppColors.subtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.scope.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: compatible ? AppColors.info : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: request.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.subtle,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

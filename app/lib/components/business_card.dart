import 'package:flutter/material.dart';
import '../models/business.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback? onTap;

  const BusinessCard({
    super.key,
    required this.business,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  image: business.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(business.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: business.logoUrl == null
                    ? Icon(Icons.business, color: theme.colorScheme.primary, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (business.address != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        business.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    // if (business.description != null) ...[
                    //   const SizedBox(height: 6),
                    //   Text(
                    //     business.description!,
                    //     style: theme.textTheme.bodyMedium,
                    //     maxLines: 2,
                    //     overflow: TextOverflow.ellipsis,
                    //   ),
                    // ],
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

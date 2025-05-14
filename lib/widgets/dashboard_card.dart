import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final String buttonText;
  final String buttonVariant;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.buttonText,
    this.buttonVariant = 'default',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        icon,
                        size: 20,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Value
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(), // Pushes button to bottom safely

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: buttonVariant == 'outline'
                        ? OutlinedButton(
                            onPressed: onTap,
                            child: Text(buttonText),
                          )
                        : ElevatedButton(
                            onPressed: onTap,
                            child: Text(buttonText),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

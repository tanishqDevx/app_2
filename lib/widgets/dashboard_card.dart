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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
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
          ),
        ),
      ),
    );
  }
}

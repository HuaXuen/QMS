import 'package:flutter/material.dart';

class CustomListView extends StatelessWidget {
  final IconData icon;
  final String name;
  final int heightRequirement;
  final int queueTime;
  final String status;
  final String category;

  const CustomListView(
      {Key? key,
      required this.icon,
      required this.name,
      required this.heightRequirement,
      required this.queueTime,
      required this.status,
      required this.category})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(name),
        subtitle: Text('Paid on: $category'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${heightRequirement.toStringAsFixed(2)}'),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'Paid' ? Colors.purple : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        onTap: () {
          // Handle invoice item tap
        },
      ),
    );
  }
}

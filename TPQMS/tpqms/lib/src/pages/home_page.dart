import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Welcome!'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Rides Available'),
              Tab(text: 'Rides Closed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RidesAvailableTab(),
            RidesClosedTab(),
          ],
        ),
      ),
    );
  }
}

class RidesAvailableTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        RideItem(
          icon: Icons.attractions,
          name: 'SkyWhirl Coaster',
          heightRequirement: '130 cm',
          color: Colors.blue,
        ),
        RideItem(
          icon: Icons.forest,
          name: 'Forest Canyon Run',
          heightRequirement: '125 cm',
          color: Colors.pink,
        ),
        InvoiceItem(
          icon: Icons.account_tree,
          name: 'FlutterFlow',
          amount: 500.00,
          date: 'May, 4th 2023',
          status: 'Overdue',
        ),
        InvoiceItem(
          icon: Icons.screen_rotation,
          name: 'ScreenStudio App',
          amount: 24.99,
          date: 'May, 4th 2023',
          status: 'Paid',
        ),
        InvoiceItem(
          icon: Icons.block,
          name: 'Slack Ltd',
          amount: 24.99,
          date: 'May, 4th 2023',
          status: 'Paid',
        ),
      ],
    );
  }
}

class RidesClosedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        InvoiceItem(
          icon: Icons.sports_basketball,
          name: 'Dribble LTD.',
          amount: 500.00,
          date: 'May, 4th 2023',
          status: 'Paid',
        ),
        InvoiceItem(
          icon: Icons.account_tree,
          name: 'FlutterFlow',
          amount: 500.00,
          date: 'May, 4th 2023',
          status: 'Paid',
        ),
      ],
    );
  }
}

class RideItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String heightRequirement;
  final Color color;

  const RideItem({
    Key? key,
    required this.icon,
    required this.name,
    required this.heightRequirement,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        subtitle: Text('Height Requirement: $heightRequirement'),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Handle ride item tap
        },
      ),
    );
  }
}

class InvoiceItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final double amount;
  final String date;
  final String status;

  const InvoiceItem({
    Key? key,
    required this.icon,
    required this.name,
    required this.amount,
    required this.date,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(name),
        subtitle: Text('Paid on: $date'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${amount.toStringAsFixed(2)}'),
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
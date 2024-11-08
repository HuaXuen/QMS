import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_listview.dart';
import 'package:tpqms/common/resuable_widgets/reusable_navbar.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/pages/users/ride_details/ride_details.dart';
import 'package:tpqms/src/providers/ride_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> Category = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Constants.homeBackground,
        appBar: AppBar(
          backgroundColor: Constants.primaryBackground,
          title: Center(
            child: Text(
              'Let the fun begin!',
              style: TextStyle(color: Constants.white),
            ),
          ),
          bottom: TabBar(
            labelColor: Constants.white,
            unselectedLabelColor: Constants.white.withOpacity(0.6),
            indicatorColor: Constants.purple,
            tabs: const [
              Tab(text: 'Rides Available'),
              Tab(text: 'Rides Closed'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                RidesAvailableTab(),
                RidesClosedTab(),
              ],
            ),
            CustomNavigationBar(
              items: [
                NavBarItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                ),
                NavBarItem(
                  icon: Icons.timer_outlined,
                  label: 'Queue',
                ),
                NavBarItem(
                  icon: Icons.map_outlined,
                  label: 'Map',
                ),
                NavBarItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RidesAvailableTab extends StatelessWidget {
  const RidesAvailableTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RideModel>>(
      stream: context.read<RideProvider>().getAvailableRidesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No rides available'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final ride = snapshot.data![index];
            return RideItem(
              icon: Icons.attractions,
              name: ride.name,
              heightRequirement: ride.heightRequirement,
              queueTime: ride.queueTime,
              category: ride.category,
              color: Constants.purple,
              rideData: ride,
            );
          },
        );
      },
    );
  }
}

class RidesClosedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RideModel>>(
      stream: context.read<RideProvider>().getClosedRidesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No rides are currently closed'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (BuildContext context, int index) {
            final ride = snapshot.data![index]; // Get the ride at current index
            return RideItem(
              icon: Icons.attractions,
              name: ride.name,
              heightRequirement: ride.heightRequirement,
              queueTime: ride.queueTime,
              category: ride.category,
              color: Constants.purple,
              rideData: ride,
            );
          },
        );
      },
    );
  }
}

class RideItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final int heightRequirement;
  final int queueTime;
  final String category;
  final Color color;
  final RideModel rideData; // Pass the RideModel object as a parameter

  const RideItem({
    Key? key,
    required this.icon,
    required this.name,
    required this.heightRequirement,
    required this.queueTime,
    required this.category,
    required this.color,
    required this.rideData, // Assign the rideData parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        subtitle: Text('Height Requirement: $heightRequirement'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsPage(rideData: rideData),
            ),
          );
        },
      ),
    );
  }
}

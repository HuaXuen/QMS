import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_appbar.dart';
import 'package:tpqms/common/resuable_widgets/reusable_bottompopup.dart';
import 'package:tpqms/common/resuable_widgets/reusable_listview.dart';
import 'package:tpqms/common/resuable_widgets/reusable_navbar.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/pages/users/ride_details/ride_details.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/common_providers/navigation.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> Category = [];
  final Navigation navigation = Navigation(); // Instantiate Navigation

  @override
  void initState() {
    super.initState();
    //Fetch the username once the widget is created
    _fetchUsernameData();
  }

  Future<void> _fetchUsernameData() async {
    // Use Provider.of with listen: false in initState
    final userProvider = Provider.of<UserInfoProvider>(context, listen: false);
    await userProvider.fetchUsername();
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserInfoProvider>(context).name;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: CustomAppBar(
          title: 'Welcome $userName, \nLet the fun begin!',
          backgroundColor: Constants.purple,
          tabBar: const TabBar(
            labelColor: Constants.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            dividerColor: Constants.transparent,
            unselectedLabelColor: Colors.white60,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.5, color: Constants.white),
              insets: EdgeInsets.symmetric(horizontal: 16.0),
            ),
            tabs: [
              Tab(text: 'Rides Available'),
              Tab(text: 'Rides Closed'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                RidesAvailableTab(navigation: navigation),
                RidesClosedTab(navigation: navigation),
              ],
            ),
            CustomNavigationBar(
              items: [
                NavBarItem(icon: Icons.home_outlined, label: 'Home'),
                NavBarItem(icon: Icons.timer_outlined, label: 'Queue'),
                NavBarItem(icon: Icons.qr_code_scanner, label: 'Scan Ticket'),
                NavBarItem(icon: Icons.map_outlined, label: 'Map'),
                NavBarItem(icon: Icons.person_outline, label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RidesAvailableTab extends StatelessWidget {
  final Navigation navigation;
  const RidesAvailableTab({Key? key, required this.navigation})
      : super(key: key);

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

        List<RideModel> rides = snapshot.data ?? [];

        return ReusableListView<RideModel>(
          items: rides,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (ride) => RideItem(
            icon: Icons.attractions,
            name: ride.name,
            heightRequirement: ride.heightRequirement,
            queueTime: ride.queueTime,
            category: ride.category,
            color: Constants.purple,
            rideData: ride,
            navigation: Navigation(),
          ),
          emptyMessage: 'No rides available',
        );
      },
    );
  }
}

class RidesClosedTab extends StatelessWidget {
  final Navigation navigation;
  const RidesClosedTab({Key? key, required this.navigation}) : super(key: key);
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

        List<RideModel> rides = snapshot.data ?? [];

        return ReusableListView<RideModel>(
          items: rides,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (ride) => RideItem(
            icon: Icons.attractions,
            name: ride.name,
            heightRequirement: ride.heightRequirement,
            queueTime: ride.queueTime,
            category: ride.category,
            color: Constants.purple,
            rideData: ride,
            navigation: Navigation(),
          ),
          emptyMessage: 'No rides are currently closed',
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
  final Navigation navigation; // Instantiate Navigation

  const RideItem({
    Key? key,
    required this.icon,
    required this.name,
    required this.heightRequirement,
    required this.queueTime,
    required this.category,
    required this.color,
    required this.rideData, // Assign the rideData parameter
    required this.navigation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String folderPath = "ride_details/";
    final String imagePath = "${rideData.name}.jpg";
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        subtitle: Text('Height Requirement: $heightRequirement'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RideDetailsBottomSheet(
              rideData: rideData,
              folderPath: "ride_details/",
              imagePath:
                  imagePath, // Adjust the path format according to your image naming convention
              onQueuePressed: () {
                navigation.navigateToRideDetails(
                    context: context,
                    rideModel: rideData,
                    folderPath: folderPath,
                    imagePath: imagePath); //redirect
              },
            ),
          );
        },
      ),
    );
  }
}





//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         backgroundColor: Constants.white,
//         appBar: PreferredSize(
//           preferredSize: Size.fromHeight(160.0),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Constants.purple,
//               borderRadius: BorderRadius.vertical(
//                 bottom: Radius.circular(30.0),
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(top: 0, bottom: 8.0),
//                     child: Consumer<UserInfoProvider>(
//                       builder: (context, userInfoProvider, child) {
//                         return Text(
//                           'Welcome ${userInfoProvider.name}! \n Let the fun begin!',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w700,
//                             fontSize: 24,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   TabBar(
//                     labelColor: Colors.white,
//                     labelStyle:
//                         TextStyle(fontWeight: Constants.bold, fontSize: 16),
//                     unselectedLabelColor: Colors.white.withOpacity(0.6),
//                     dividerColor: Constants.transparent,
//                     indicator: UnderlineTabIndicator(
//                       borderSide: BorderSide(width: 3.0, color: Colors.grey),
//                       insets: EdgeInsets.symmetric(horizontal: 16.0),
//                     ),
//                     tabs: const [
//                       Tab(text: 'Rides Available'),
//                       Tab(text: 'Rides Closed'),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         body: Stack(
//           children: [
//             TabBarView(
//               children: [
//                 RidesAvailableTab(),
//                 RidesClosedTab(),
//               ],
//             ),
//             CustomNavigationBar(
//               items: [
//                 NavBarItem(
//                   icon: Icons.home_outlined,
//                   label: 'Home',
//                 ),
//                 NavBarItem(
//                   icon: Icons.timer_outlined,
//                   label: 'Queue',
//                 ),
//                 NavBarItem(icon: Icons.qr_code_scanner, label: 'Scan Ticket'),
//                 NavBarItem(
//                   icon: Icons.map_outlined,
//                   label: 'Map',
//                 ),
//                 NavBarItem(
//                   icon: Icons.person_outline,
//                   label: 'Profile',
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

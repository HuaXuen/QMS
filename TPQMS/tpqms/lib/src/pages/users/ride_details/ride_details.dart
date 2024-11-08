import 'package:flutter/material.dart';
import 'package:tpqms/src/model/ride_model.dart';

class RideDetailsPage extends StatelessWidget {
  final RideModel rideData;

  const RideDetailsPage({Key? key, required this.rideData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(rideData.name),
      ),
      body: StreamBuilder<RideModel>(
        stream: Stream.value(rideData),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final ride = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Height Requirement: ${ride.heightRequirement}'),
                Text('Queue Time: ${ride.queueTime}'),
                Text('Category: ${ride.category}'),
                // Add more details as needed
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

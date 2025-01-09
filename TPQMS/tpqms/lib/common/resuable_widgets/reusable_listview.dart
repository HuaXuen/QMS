import 'package:flutter/material.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/pages/users/home_page/home_page.dart';

class ReusableListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;
  final bool showDividers;
  final ScrollPhysics? physics;
  final String? emptyMessage;

  const ReusableListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.emptyWidget,
    this.padding,
    this.showDividers = false,
    this.physics,
    this.emptyMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ??
          Center(
            child: Text(
              emptyMessage!,
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          );
    }

    return ListView.separated(
        padding: padding,
        physics: physics,
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            showDividers ? const Divider() : const SizedBox.shrink(),
        itemBuilder: (context, index) => itemBuilder(items[index]));
  }
}



// import 'package:flutter/material.dart';

// class CustomListView extends StatelessWidget {
//   final IconData icon;
//   final String name;
//   final int heightRequirement;
//   final int queueTime;
//   final String status;
//   final String category;

//   const CustomListView(
//       {Key? key,
//       required this.icon,
//       required this.name,
//       required this.heightRequirement,
//       required this.queueTime,
//       required this.status,
//       required this.category})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.blue),
//         title: Text(name),
//         subtitle: Text('Paid on: $category'),
//         trailing: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text('\$${heightRequirement.toStringAsFixed(2)}'),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: status == 'Paid' ? Colors.purple : Colors.orange,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 status,
//                 style: TextStyle(color: Colors.white, fontSize: 12),
//               ),
//             ),
//           ],
//         ),
//         onTap: () {
//           // Handle invoice item tap
//         },
//       ),
//     );
//   }
// }

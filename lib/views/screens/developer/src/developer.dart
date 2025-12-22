import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '/utils/utils.dart';
import '/views/views.dart';

class Developer extends StatefulWidget {
  final bool showAppbar;
  const Developer({super.key, this.showAppbar = true});

  @override
  State<Developer> createState() => _DeveloperState();
}

class _DeveloperState extends State<Developer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppbar
          ? AppBar(leading: Back(), title: Text("Developer Area"))
          : null,
      body: ListView(
        padding: EdgeInsets.all(10),
        children: [
          ListTile(
            leading: CircleAvatar(child: Icon(Iconsax.notification)),
            title: Text("Notification Test"),
            trailing: Icon(Iconsax.arrow_right_3),
            onTap: () => Navigate.route(context, NotificationTestPage()),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(child: Icon(Iconsax.data)),
            title: Text("Shared Preferences Data"),
            trailing: Icon(Iconsax.arrow_right_3),
            onTap: () => Navigate.route(context, SharedprefsData()),
          ),
          // SizedBox(height: 20),
          // ListTile(
          //   leading: CircleAvatar(child: Icon(Iconsax.link)),
          //   title: Text("Hive Data"),
          //   trailing: Icon(Iconsax.arrow_right_3),
          //   onTap: () => Navigate.route(context, HiveData()),
          // ),
          SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(child: Icon(Iconsax.close_circle)),
            title: Text("Errors"),
            trailing: Icon(Iconsax.arrow_right_3),
            onTap: () => Navigate.route(context, AppErrors()),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(child: Icon(Iconsax.cloud)),
            title: Text("Backups"),
            trailing: Icon(Iconsax.arrow_right_3),
            onTap: () => Navigate.route(context, BackupListing()),
          ),
        ],
      ),
    );
  }
}

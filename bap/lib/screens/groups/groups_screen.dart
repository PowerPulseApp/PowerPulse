import 'package:bap/screens/groups/other_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bap/screens/groups/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Groups',
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            _buildNavigationButton(
              context,
              'Create New Group',
              CreateGroupScreen(),
            ),
            SizedBox(
              height: 20,
            ),
            _buildNavigationButton(
              context,
              'Join Group',
              JoinGroupScreen(),
            ),
            SizedBox(
              height: 20,
            ),
            Divider(
              color: Colors.grey[600],
              thickness: 1,
              height: 30,
            ),
            SizedBox(
              height: 20,
            ),
            _buildUserGroups(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context,
    String label,
    Widget destination,
  ) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SafeArea(
              child: destination,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(label),
      ),
    );
  }

  Widget _buildUserGroups(BuildContext context) {
    String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserUid != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('groups')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Widget> groupTiles = [];
            snapshot.data!.docs.forEach((doc) {
              String groupName = doc['name'];
              groupTiles.add(ElevatedButton(
                onPressed: () {
                  // Open a new screen to display group details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailsScreen(groupName),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(groupName),
              ));
            });
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: groupTiles,
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return CircularProgressIndicator();
          }
        },
      );
    } else {
      return Text('User not authenticated');
    }
  }
}

class CreateGroupScreen extends StatelessWidget {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create New Group',
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: groupKeyController,
              decoration: InputDecoration(
                labelText: 'Group Key',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _createGroup(context);
              },
              child: Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    String groupName = groupNameController.text.trim();
    String groupKey = groupKeyController.text.trim();

    if (groupName.isEmpty || groupKey.isEmpty) {
      // Show error message if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    try {
      // Check if group name already exists
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupName)
          .get();

      if (groupSnapshot.exists) {
        // Show error message if group name already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Group name already exists. Please choose a different name.'),
          ),
        );
        return;
      }

      // Get current user's UID
      String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) {
        throw FirebaseAuthException(
          code: 'user-not-logged-in',
          message: 'User not logged in.',
        );
      }

      // Create the new group
      await FirebaseFirestore.instance.collection('groups').doc(groupName).set({
        'key': groupKey,
        'name': groupName,
        'creatorUid': currentUserUid,
        'members': [currentUserUid],
      });

      // Add group to user's groups collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('groups')
          .doc(groupName)
          .set({
        'key': groupKey,
        'name': groupName,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group created successfully.'),
        ),
      );

      // Navigate to the newly created group
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupDetailsScreen(groupName),
        ),
      );
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $error'),
        ),
      );
    }
  }
}

class JoinGroupScreen extends StatelessWidget {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Join Group',
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: groupKeyController,
              decoration: InputDecoration(
                labelText: 'Group Key',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Get the current user's UID
                String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

                if (currentUserUid != null) {
                  String groupName = groupNameController.text.trim();
                  String groupKey = groupKeyController.text.trim();

                  if (groupName.isEmpty || groupKey.isEmpty) {
                    // Show error message if any field is empty
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please fill in all fields.'),
                      ),
                    );
                    return;
                  }

                  // Check if the group exists in Firestore
                  FirebaseFirestore.instance
                      .collection('groups')
                      .where('name', isEqualTo: groupName)
                      .where('key', isEqualTo: groupKey)
                      .get()
                      .then((QuerySnapshot querySnapshot) {
                    if (querySnapshot.docs.isNotEmpty) {
                      // Group with given name and key exists, add user to members
                      String groupId = querySnapshot.docs.first.id;
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(groupId)
                          .update({
                        'members': FieldValue.arrayUnion([currentUserUid]),
                      }).then((_) {
                        // Add the group to the user's groups
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserUid)
                            .collection('groups')
                            .doc(groupId)
                            .set({
                          'name': querySnapshot.docs.first['name'],
                          'key': groupKey,
                        });

                        // Success, navigate back to groups screen
                        Navigator.pop(context);
                      }).catchError((error) {
                        // Handle error
                        print("Failed to join group: $error");
                        // Optionally, show an error message to the user
                      });
                    } else {
                      // Group with given name and key does not exist, show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Group not found.'),
                        ),
                      );
                    }
                  }).catchError((error) {
                    // Handle error
                    print("Failed to join group: $error");
                    // Optionally, show an error message to the user
                  });
                }
              },
              child: Text('Join Group'),
            ),
          ],
        ),
      ),
    );
  }
}

/*
this comment is to make the code more readable and separate the groupsdetailsscreen from the rest of the code
.
.
.
*/

class GroupDetailsScreen extends StatefulWidget {
  final String groupName;

  GroupDetailsScreen(this.groupName);

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _groupKeyController = TextEditingController();
  String groupName = "";
  String _groupKey = '';
  

  @override
  void initState() {
    super.initState();
    _groupNameController.text = widget.groupName;
    groupName = widget.groupName;
    _loadGroupKey();
  }
  Future<void> _loadGroupKey() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupName)
        .get();
    if (groupDoc.exists) {
      final groupData = groupDoc.data() as Map<String, dynamic>;
      setState(() {
        _groupKey = groupData['key'];
      });
    }
  }
bool _showKey = false;
  @override
  Widget build(BuildContext context,) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
    children: [
            Text(
              groupName,
              style: GoogleFonts.bebasNeue(fontSize: 26),
            ),
            SizedBox(width: 8), // add some space between the name and key
            Opacity(
              opacity: _showKey ? 1.0 : 0.0, // blur the text if _showKey is false
              child: Text(
                '($_groupKey)',
                style: GoogleFonts.bebasNeue(fontSize: 16, color: const Color.fromARGB(255, 109, 109, 109)),
              ),
            ),
            IconButton(
              icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showKey = !_showKey;
                });
              },
            ),
          ],
          
        ),
        actions: [
          /*
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {},
          ),
          */
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              // Navigate to group members screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupMembersScreen(groupName),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(widget.groupName),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _leaveGroup(groupName);
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Leaderboards',
            style: GoogleFonts.bebasNeue(fontSize: 24),
          ),
          SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupName)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  var groupData = snapshot.data!.data() as Map<String, dynamic>;
                  List<dynamic> members = groupData['members'];
                  return _buildLeaderboard(members);
                } else {
                  return Center(child: Text('No data found'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog() async {
    
  }

  Future<void> _updateGroup() async {
    // Implement group update logic
  }

  Future<void> _leaveGroup(String groupName) async {
  User? user = FirebaseAuth.instance.currentUser;  
  DocumentReference groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupName);

      // Remove the user from the members array
      await groupRef.update({
        'members': FieldValue.arrayRemove([user?.uid])
      });

      DocumentReference userGroupRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('groups')
        .doc(groupName);

    // Delete the group document from the user's groups collection
    await userGroupRef.delete();

    Navigator.of(context).pop();

  }

  Widget _buildLeaderboard(List<dynamic> members) {
    return FutureBuilder<List<_LeaderboardEntry>>(
      future: _loadLeaderboardData(members),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final entry = snapshot.data![index];
              return ListTile(
                title: Text(
                  '${index + 1}. ${entry.username}',
                  style: GoogleFonts.bebasNeue(fontSize: 20),
                ),
                trailing: Text(
                  '${entry.totalWeight.toStringAsFixed(2)} tons',
                  style: GoogleFonts.bebasNeue(fontSize: 18),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<List<_LeaderboardEntry>> _loadLeaderboardData(
      List<dynamic> members) async {
    List<_LeaderboardEntry> leaderboardEntries = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    for (var memberId in members) {
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('workouts')
          .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      double totalWeight = 0;
      for (var workoutDoc in workoutSnapshot.docs) {
        final workoutData = workoutDoc.data() as Map<String, dynamic>;
        totalWeight += workoutData['totalWeight'] / 1000 ?? 0;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>;
      final username = userData['username'];

      leaderboardEntries.add(_LeaderboardEntry(username, totalWeight));
    }

    leaderboardEntries.sort((a, b) => b.totalWeight.compareTo(a.totalWeight));

    return leaderboardEntries;
  }
}

class _LeaderboardEntry {
  final String username;
  final double totalWeight;

  _LeaderboardEntry(this.username, this.totalWeight);
}

/*
this comment is to make the code more readable and separate the groupsdetailsscreen from the rest of the code
.
.
.
*/

class GroupMembersScreen extends StatefulWidget {
  final String groupName;

  GroupMembersScreen(this.groupName);

  @override
  _GroupMembersScreenState createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  late BuildContext _scaffoldContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Members',
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupName)
            .snapshots(),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.hasData) {
            List<String> memberIds = [];
            final groupData =
                groupSnapshot.data!.data() as Map<String, dynamic>;
            if (groupData.containsKey('members')) {
              memberIds = List<String>.from(groupData['members']);
            }
            return FutureBuilder<List<String>>(
              future: _getUsernames(memberIds),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (userSnapshot.hasError) {
                  return Center(
                    child: Text('Error: ${userSnapshot.error}'),
                  );
                } else {
                  List<String> memberUsernames = userSnapshot.data!;
                  return ListView.builder(
                    itemCount: memberUsernames.length,
                    itemBuilder: (context, index) {
                      String memberId = memberIds[index];
                      String memberUsername = memberUsernames[index];
                      return ListTile(
                        title: Text(
                          memberUsername,
                          style: GoogleFonts.bebasNeue(fontSize: 20),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OtherProfileScreen(userId: memberId),
                            ),
                          );
                        },
                        trailing:
                            (memberId != FirebaseAuth.instance.currentUser!.uid)
                                ? IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      _removeMember(memberId);
                                    },
                                  )
                                : null,
                      );
                    },
                  );
                }
              },
            );
          } else if (groupSnapshot.hasError) {
            return Center(
              child: Text('Error: ${groupSnapshot.error}'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scaffoldContext = context;
  }

  Future<List<String>> _getUsernames(List<String> userIds) async {
    List<String> usernames = [];
    for (String userId in userIds) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userSnapshot.exists) {
        // Check if the user document exists
        usernames.add(userSnapshot['username']);
      } else {
        usernames.add('Unknown User');
      }
    }
    return usernames;
  }

  void _removeMember(String memberId) async {
    String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserUid != null) {
      try {
        // Remove user from group members
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupName)
            .update({
          'members': FieldValue.arrayRemove([memberId]),
        });

        // Remove group from user's groups
        await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .collection('groups')
            .doc(widget.groupName)
            .delete();

        // Show success message
        ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Removed member successfully.'),
          ),
        );
      } catch (error) {
        // Show error message
        ScaffoldMessenger.of(_scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $error'),
          ),
        );
      }
    }
  }
}

/*
.
Leaderboards stuff 
.
*/

Future<List<Widget>> _loadLeaderboardData(List<dynamic> members) async {
  List<_LeaderboardEntry> leaderboardEntries = [];
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(Duration(days: 30));

  for (var memberId in members) {
    final workoutSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .collection('workouts')
        .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .get();

    double totalWeight = 0;
    for (var workoutDoc in workoutSnapshot.docs) {
      final workoutData = workoutDoc.data() as Map<String, dynamic>;
      totalWeight += workoutData['totalWeight'] / 1000 ?? 0;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .get();

    final userData = userDoc.data() as Map<String, dynamic>;
    final username = userData['username'];

    leaderboardEntries.add(_LeaderboardEntry(username, totalWeight));
  }

  leaderboardEntries.sort((a, b) => b.totalWeight.compareTo(a.totalWeight));

  List<Widget> leaderboardTiles = [];
  for (int i = 0; i < leaderboardEntries.length; i++) {
    leaderboardTiles.add(ListTile(
      title: Text('${i + 1}. ${leaderboardEntries[i].username}',
          style: TextStyle(fontSize: 15)),
      trailing: Text(
        '${leaderboardEntries[i].totalWeight.toStringAsFixed(2)} tons',
        style: TextStyle(fontSize: 15),
      ),
    ));
  }

  return leaderboardTiles;
}

void main() {
  runApp(MaterialApp(
    home: GroupsScreen(),
  ));
}

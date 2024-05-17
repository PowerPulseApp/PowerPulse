import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groups'),
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
        title: Text('Create New Group'),
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
                  // Save the group details to Firestore
                  String groupName = groupNameController.text
                      .trim(); // Trim any leading or trailing whitespace
                  FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupName)
                      .set({
                    'name': groupName,
                    'key': groupKeyController.text,
                    'creatorUid': currentUserUid,
                    'members': [currentUserUid], // Start with creator as member
                  }).then((_) {
                    // Add the group to the user's groups
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserUid)
                        .collection('groups')
                        .doc(groupName)
                        .set({
                      'name': groupName,
                      'key': groupKeyController.text,
                    });

                    // Success, navigate back to groups screen
                    Navigator.pop(context);
                  }).catchError((error) {
                    // Handle error
                    print("Failed to create group: $error");
                    // Optionally, show an error message to the user
                  });
                }
              },
              child: Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinGroupScreen extends StatelessWidget {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Group'),
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

class GroupDetailsScreen extends StatelessWidget {
  final String groupName;

  GroupDetailsScreen(this.groupName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$groupName'),
        actions: [
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
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _leaveGroup(context, groupName);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardScreen(groupName),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Text(
              'Group Details',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup(BuildContext context, String groupName) async {
    String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserUid != null) {
      try {
        // Remove user from group members
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupName)
            .update({
          'members': FieldValue.arrayRemove([currentUserUid]),
        });

        // Remove group from user's groups
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('groups')
            .doc(groupName)
            .delete();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left group successfully.'),
          ),
        );
      } catch (error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave group: $error'),
          ),
        );
      }
    }
  }
}

/*
this comment is to make the code more readable and separate the groupsdetailsscreen from the rest of the code
.
.
.
*/

class GroupMembersScreen extends StatelessWidget {
  final String groupName;

  GroupMembersScreen(this.groupName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Members'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupName)
            .snapshots(),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.hasData) {
            List<String> memberIds = [];
            List<String> memberUsernames = [];
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
                  memberUsernames = userSnapshot.data!;
                  return ListView.builder(
                    itemCount: memberUsernames.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(memberUsernames[index]),
                        ),
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
}

/*
.
Leaderboards stuff 
.
*/

class LeaderboardScreen extends StatelessWidget {
  final String groupName;

  LeaderboardScreen(this.groupName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: _buildLeaderboard(groupName),
    );
  }

  Widget _buildLeaderboard(String groupName) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('groups').doc(groupName).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          var groupData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> members = groupData['members'];

          return FutureBuilder(
            future: _loadLeaderboardData(members),
            builder:
                (context, AsyncSnapshot<List<Widget>> leaderboardSnapshot) {
              if (leaderboardSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (leaderboardSnapshot.hasError) {
                return Center(
                    child: Text('Error: ${leaderboardSnapshot.error}'));
              } else {
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Total weight lifted over last 30 days',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ...leaderboardSnapshot.data!,
                  ],
                );
              }
            },
          );
        } else {
          return Center(child: Text('No data found'));
        }
      },
    );
  }

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
        totalWeight += workoutData['totalWeight'] ?? 0;
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
        title: Text('${i + 1}. ${leaderboardEntries[i].username}'),
        trailing: Text('${leaderboardEntries[i].totalWeight} kg'),
      ));
    }

    return leaderboardTiles;
  }
}

class _LeaderboardEntry {
  final String username;
  final double totalWeight;

  _LeaderboardEntry(this.username, this.totalWeight);
}

void main() {
  runApp(MaterialApp(
    home: GroupsScreen(),
  ));
}

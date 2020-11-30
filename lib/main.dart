import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:ui';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)
              )
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => UserRepository.instance(),
        child: MaterialApp(
          title: 'Startup Name Generator',
          theme: ThemeData(
            primaryColor: Colors.red,
          ),
          home: RandomWords(),
        )
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final _saved = Set<WordPair>();
  final _firstwords = new List<String>();
  final _secondwords = new List<String>();
  final TextStyle _biggerFont = const TextStyle(fontSize: 18);
  final GlobalKey<ScaffoldState> _scaffoldkeySaved = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldkeyLogin = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldkeybuild = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldkeyWorkAround = new GlobalKey<ScaffoldState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordValidatorController = TextEditingController();
  SnappingSheetController snappingSheetController = SnappingSheetController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var _snapPositions = [
      SnapPosition(
          snappingCurve: Curves.elasticOut,
          snappingDuration: Duration(milliseconds: 750),
          positionPixel: 0.0
      ),
      SnapPosition(
          positionPixel: MediaQuery.of(context).size.height * 0.14,
          snappingCurve: Curves.elasticOut,
          snappingDuration: Duration(milliseconds: 750)
      )
    ];
    return Material(
      child: Consumer<UserRepository>(
          builder: (context, userRep, _) {
            var _lst = Scaffold(
              key: _scaffoldkeybuild,
              appBar: AppBar(
                title: Text('Startup Name Generator'),
                actions: [
                  Builder(builder: (context) =>
                      Consumer<UserRepository>(builder: (context, userRep, _) =>
                          IconButton(
                              icon: Icon(Icons.favorite), onPressed: _pushSaved)
                      )
                  ),
                  Builder(builder: (context) =>
                      Consumer<UserRepository>(builder: (context, userRep, _) =>
                          IconButton(icon: Icon(userRep.status ==
                              Status.Authenticated
                              ? Icons.exit_to_app
                              : Icons.login),
                              onPressed: userRep.status == Status.Authenticated
                                  ? () {
                                userRep.signOut(
                                    _saved, _firstwords, _secondwords);
                                setState(() {
                                  //nothing to be done here
                                });
                                Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Logged out successfully")
                                    )
                                );
                              }
                                  : _pushLogin)
                      )
                  )
                ],
              ),
              body: _buildSuggestions(),
            );
            return userRep.status != Status.Authenticated ? _lst :
            Scaffold(
              key: _scaffoldkeyWorkAround,
              body: SnappingSheet(
                snappingSheetController: snappingSheetController,
                sheetBelow: SnappingSheetContent(
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(2),
                    alignment: Alignment.topCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: null == userRep.avatarURL ? null : NetworkImage(userRep.avatarURL),
                          child: null == userRep.avatarURL
                              ? Icon(Icons.camera)
                              : null,
                          radius: MediaQuery.of(context).size.height * 0.05,
                        ),
                        SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                flex: 0,
                                child: Text(
                                  "${userRep.user.email}",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18.0
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 0,
                                child: ButtonTheme(
                                  minWidth: 200.0,
                                  child: FlatButton(
                                      color: Colors.cyan,
                                      onPressed: () async {
                                        PickedFile avatar = await ImagePicker().getImage(source: ImageSource.gallery);
                                        if(null == avatar) {
                                          _scaffoldkeyWorkAround.currentState
                                              .showSnackBar(
                                              SnackBar(content: Text(
                                                  "No image selected"),
                                                behavior: SnackBarBehavior.floating,
                                              )
                                          );
                                        } else {
                                          userRep.setAvatar(avatar.path);
                                        }
                                      },
                                      child: Center(
                                        child: Text(
                                          "Change avatar",
                                          style: TextStyle(
                                              color: Colors.white
                                          ),
                                        ),
                                      )
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  draggable: true,
                  heightBehavior: SnappingSheetHeight.fit(),
                ),
                grabbing: InkWell(
                  onTap: () {
                    snappingSheetController.snapToPosition(
                        0.0 == snappingSheetController.currentSnapPosition
                            .positionPixel
                            ? _snapPositions[1]
                            : _snapPositions[0]
                    );
                  }, //onTap
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "Welcome back, ${userRep.user.email}!",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_up,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    color: Colors.grey,
                    padding: EdgeInsets.all(10.0),
                  ),
                ),
                grabbingHeight: MediaQuery.of(context).size.height * 0.075,
                child: _lst,
                snapPositions: _snapPositions,
                initSnapPosition: SnapPosition(
                    positionPixel: 0.0,
                    snappingCurve: Curves.elasticOut,
                    snappingDuration: Duration(milliseconds: 750)
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return Builder(builder: (context) =>
        Consumer<UserRepository>(builder: (context, userRep, _) =>
            ListTile(
              title: Text(
                pair.asPascalCase,
                style: _biggerFont,
              ),
              trailing: Icon(
                alreadySaved ? Icons.favorite : Icons.favorite_border,
                color: alreadySaved ? Colors.red : null,
              ),
              onTap: () {
                setState(() {
                  if (Status.Authenticated == userRep.status) {
                    if (alreadySaved) {
                      userRep.deleteWordPair(
                          _saved, pair, _firstwords, _secondwords);
                    } else {
                      _firstwords.add(pair.first);
                      _secondwords.add(pair.second);
                      userRep.addWordPair(
                          _saved, pair, _firstwords, _secondwords);
                    }
                  } else {
                    if (alreadySaved) {
                      _saved.remove(pair);
                      userRep.deleteWordPairFromFirstsSeconds(
                          _firstwords, _secondwords, pair);
                    } else {
                      _saved.add(pair);
                      _firstwords.add(pair.first);
                      _secondwords.add(pair.second);
                    }
                  }
                  userRep.externalNotify();
                  setState(() {
                    //nothing to be done here
                  });
                });
              },
            ),
        )
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            Provider.of<UserRepository>(context);
            final tiles = _saved.map(
                  (WordPair pair) {
                    return Builder(builder: (context) =>
                        Consumer<UserRepository>(
                            builder: (context, userRep, _) =>
                                ListTile(
                                    title: Text(
                                      pair.asPascalCase,
                                      style: _biggerFont,
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (userRep.status ==
                                              Status.Authenticated) {
                                            userRep.deleteWordPair(
                                                _saved, pair, _firstwords,
                                                _secondwords);
                                          } else {
                                            _saved.remove(pair);
                                            userRep.externalNotify();
                                          }
                                          setState(() {
                                            //Nothing to do here, just sets the screen fot the UI
                                          });
                                        });
                                      },
                                    )
                                )
                        )
                    );
                  },
            );
            final divided = ListTile.divideTiles(
              context: context,
              tiles: tiles,
            ).toList();
            return Scaffold(
              key: _scaffoldkeySaved,
              appBar: AppBar(
                title: Text('Saved Suggestions'),
              ),
              body: ListView(children: divided),
            );
          }, //builder
        )
    );
  }

  ///validating that passwords are the same on the sign up page
  bool validatePassword(String p1, String p2) {
    if(p1.isEmpty || p2.isEmpty || p1.compareTo(p2) != 0) {
      setState(() {
        //nothing to do here
      });
      return false;
    }
    setState(() {
      //nothing to do here
    });
    return true;
  }

  void _pushLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          Provider.of<UserRepository>(context);
          final _email = TextFormField(
            controller: emailController,
            decoration: InputDecoration(
                icon: Icon(Icons.email_outlined),
                labelText: 'Email',
            ),
          );
          final _password = TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
                labelText: 'Password',
                icon: Icon(Icons.vpn_key_outlined)
            ),
            obscureText: true,
          );
          final loginButton = Builder(builder: (context) =>
              Consumer<UserRepository>(builder: (context, userRep, _) =>
                  FlatButton(
                    onPressed: userRep.status == Status.Authenticating ||
                        userRep.status == Status.Authenticated
                        ? null
                        : () async {
                      try {
                        await userRep.signIn(emailController.text, passwordController.text);
                        await userRep.backup(_saved, _firstwords, _secondwords);
                        Navigator.pop(context);
                        setState(() {
                          //nothing
                        });
                      } on FirebaseAuthException catch (_) {
                        Scaffold.of(context).showSnackBar(
                            SnackBar(
                                content: Text("There was an error logging into the app")
                            )
                        );
                      }
                    },
                    child: Text(
                      "Log in",
                    ),
                    color: Colors.red,
                    textColor: Colors.white,
                  )
              )
          );
          final signUpButton = Builder(builder: (context) =>
              Consumer<UserRepository>(builder: (context, userRep, _) =>
                  FlatButton(
                    onPressed: userRep.status == Status.Authenticated ||
                        userRep.status == Status.Authenticating
                        ? null
                        : () async {
                      setState(() {
                      });
                      if (emailController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: MediaQuery
                                    .of(context)
                                    .viewInsets,
                                child: Container(
                                  height: 200,
                                  color: Colors.white,
                                  child: Center(
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            'Please confirm your password below:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          TextFormField(
                                            controller: passwordValidatorController,
                                            validator: (value) {
                                              return validatePassword(value,
                                                  passwordController.text)
                                                  ? null:
                                                  "Passwords must match";
                                            },
                                            decoration: InputDecoration(
                                              icon: Icon(
                                                  Icons.vpn_key_outlined),
                                              labelText: "Password",
                                            ),
                                            obscureText: true,
                                          ),
                                          ElevatedButton(
                                              onPressed: () async {
                                                if (_formKey.currentState.validate()) {
                                                  await userRep.signUp(emailController.text, passwordController.text);
                                                  await userRep.backupOnSignUp(_saved, _firstwords, _secondwords);
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    //nothing to do here
                                                  });
                                                } else {
                                                  userRep.externalNotify();
                                                  setState(() {
                                                    //nothing to do here
                                                  });
                                                }
                                              },
                                              child: const Text('Confirm')
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                        ); // showModalBottomSheet
                        setState(() {
                          //nothing to do here
                        });
                      }
                    },
                    child: Text("New user? Click to sign up"),
                    color: Colors.cyan,
                    textColor: Colors.white,
                  )
              )
          );
          return StatefulBuilder(builder: (context, setState) =>
              Consumer<UserRepository>(builder: (context, userRep, _) =>
                  Scaffold(
                      resizeToAvoidBottomInset: true,
                      key: _scaffoldkeyLogin,
                      appBar: AppBar(
                        title: Text('Login'),
                      ),
                      body: Column(
                          children: <Widget>[
                          Text('\nWelcome to Startup Names Generator, please log in\nbelow\n',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          _email, _password, loginButton, signUpButton
                          ]
                      )
                  )
              )
          );
        },
      ),
    );
  }
}

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User _user;
  Status _status = Status.Uninitialized;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseStorage _storage = FirebaseStorage.instance;
  String _avatarURL;

  UserRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Status get status => _status;
  User get user => _user;
  FirebaseFirestore get db => _db;
  FirebaseStorage get storage => _storage;
  String get avatarURL => _avatarURL;

  Future<void> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _avatarURL = await _storage.ref().child("images/" + _auth.currentUser.uid + "_avatar").getDownloadURL();
    } on FirebaseAuthException catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      throw e;
    } catch(_) {
      //nothing
    }
    finally {
      notifyListeners();
    }
  }

  Future<void> backupOnSignUp(Set<WordPair> saved, List<String> firsts, List<String> seconds) async {
    await _db.collection("users").doc(_auth.currentUser.uid).set({
      'data': saved.map((e) => e.first + e.second).toList(),
      'first': firsts,
      'second': seconds
    });
  }
  Future<void> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (_) {
      _status = Status.Unauthenticated;
      notifyListeners();
      // throw e;
    } finally {
      notifyListeners();
    }
  }

  Future signOut(Set<WordPair> saved, List<String> firsts, List<String> seconds) async {
    saved.clear();
    firsts.clear();
    seconds.clear();
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  void deleteWordPairFromFirstsSeconds(List<String> firsts, List<String> seconds, WordPair wordPair){
    for(int i = 0; i < firsts.length; i++){
      if(firsts[i].compareTo(wordPair.first) == 0 && seconds[i].compareTo(wordPair.second) == 0){
        firsts.removeAt(i);
        seconds.removeAt(i);
        return;
      }
    }
  }

  Future<void> deleteWordPair(Set<WordPair> saved, WordPair wordPair, List<String> firsts, List<String> seconds) async {
    deleteWordPairFromFirstsSeconds(firsts, seconds, wordPair);
    saved.remove(wordPair);
    var list = saved.map((e) => e.first + e.second).toList();
    await _db.collection("users").doc(_auth.currentUser.uid).set(
        {'data': list, 'first': firsts, 'second': seconds});
    notifyListeners();
  }

  Future<void> addWordPair(Set<WordPair> saved, WordPair wordPair, List<String> firsts, List<String> seconds) async {
    saved.add(wordPair);
    var list = saved.map((e) => e.first + e.second).toList();
    try {
      await _db.collection("users").doc(_auth.currentUser.uid).set(
          {'data': list, 'first': firsts, 'second': seconds});
    } catch (_) {
      //nothing
    }
    notifyListeners();
  }

  Future<void> backup(Set<WordPair> saved, List<String> firsts, List<String> seconds) async {
    try {
      var retrieve = await _db.collection("users").doc(_auth.currentUser.uid).get();
      var retrievedData = retrieve.data();
      Map<int, dynamic> m1 = retrievedData['first'].asMap(),
          m2 = retrievedData['second'].asMap();
      for (int j = 0; j < m1.length; j++) {
        if (!firsts.contains(m1[j]) && !seconds.contains(m2[j])) {
          firsts.add(m1[j]);
          seconds.add(m2[j]);
        }
      }
      var i = 0;
      for (String s1 in firsts) {
        saved.add(WordPair(s1, seconds[i]));
        i += 1;
      }
      await _db.collection("users").doc(_auth.currentUser.uid).set({
        'data': saved.map((e) => e.first + e.second).toList(),
        'first': firsts,
        'second': seconds
      });
    } catch (_) {
      //nothing
    }
  }

  void externalNotify(){
    notifyListeners();
  }

  /// sets avatar for a user
  Future<void> setAvatar(String avatar) async {
    try {
      await _storage.ref().child("images/" + _auth.currentUser.uid + "_avatar").putFile(File(avatar));
      _avatarURL = await _storage.ref().child("images/" + _auth.currentUser.uid + "_avatar").getDownloadURL();
    } catch(_) {
      //nothing
    } finally {
      notifyListeners();
    }
  }
}

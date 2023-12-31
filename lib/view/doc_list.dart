import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:interrupt/resources/UI_constraints.dart';
import 'package:interrupt/resources/colors.dart';
import 'package:interrupt/view/share.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/date_formatter.dart';
import '../view_model/expire_provider.dart';
import '../view_model/user_provider.dart';
import '../resources/components/custom_text_field.dart';
import '../resources/components/primary_button.dart';
import '../resources/components/primary_icon_button.dart';
import 'individual_doc.dart';
import 'package:http/http.dart' as http;

class DocListScreen extends StatefulWidget {
  const DocListScreen({super.key});

  @override
  State<DocListScreen> createState() => _DocListScreenState();
}

class _DocListScreenState extends State<DocListScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isSelectAll = false;
  bool isSelectAllUSG = false;
  bool isSelectNonStressThings = false;
  bool isSelectContractionStressThings = false;
  bool isSelectDopplerUltrasoundReport = false;
  bool isSelectOthers = false;
  List<Widget> docCategoriesTabs = const [
    Tab(child: Text('All')),
    Tab(child: Text('USG Reports')),
    Tab(child: Text('Non-Stress Test')),
    Tab(child: Text('Contraction Stress Test')),
    Tab(child: Text('Doppler Ultrasound Report')),
    Tab(child: Text('Others'))
  ];
  List docCategories = [
    'All',
    'USG Report',
    'Non-Stress Test',
    'Contraction Stress Test',
    'Doppler Ultrasound Report',
    'Others'
  ];

  List selectedItems = [];
  final expireTimeController = TextEditingController();
  bool shareProfile = true;
  final user = FirebaseAuth.instance.currentUser!;
  List<String> allDocId = [];
  List allExpireLinks = [];
  final success = const SnackBar(
    content: Text('Copied to clipboard'),
  );

  fetchExpire() async {
    ExpireProvider userProvider = Provider.of(context, listen: false);
    await userProvider.fetchExpiryDetails();
  }

  Future sendDetails(List selectedDoc) async {
    for (var docID in selectedDoc) {
      allDocId.add(docID);
    }
    var url = Uri.parse("https://expiry-system-s6e4vwvwlq-el.a.run.app");
    Map data = {
      "uid": user.uid, // user id
      "isprofile": shareProfile, // shares profile
      "ttl": int.parse(expireTimeController.text) * 3600, //in seconds
      "shared_docs": allDocId,
    };
    var body = json.encode(data);
    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: body,
    );
    await fetExpireDetails();
    return response.body;
  }

  Future fetExpireDetails() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      CollectionReference docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('shared_links');
      QuerySnapshot querySnapshot = await docRef.get();
      final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
      allExpireLinks = allData;
    } catch (e) {
      return;
    }
  }

  @override
  initState() {
    super.initState();
    fetExpireDetails();
  }

  @override
  Widget build(BuildContext context) {
    List allUserDocs = Provider.of<UserProvider>(context).getUserDocs;

    BuildContext modalContext = context;

    List usgDocs = allUserDocs.where((element) {
      if (element['doc_type'] == 'USG Report') {
        return true;
      } else {
        return false;
      }
    }).toList();

    List nonStressTestDocs = allUserDocs.where((element) {
      if (element['doc_type'] == 'Non-Stress Test') {
        return true;
      } else {
        return false;
      }
    }).toList();

    List contractionStressTestDocs = allUserDocs.where((element) {
      if (element['doc_type'] == 'Contraction Stress Test') {
        return true;
      } else {
        return false;
      }
    }).toList();

    List dopplerUltraSoundReportDocs = allUserDocs.where((element) {
      if (element['doc_type'] == 'Doppler Ultrasound Report') {
        return true;
      } else {
        return false;
      }
    }).toList();

    List otherDocs = allUserDocs.where((element) {
      if (element['doc_type'] == 'Others') {
        return true;
      } else {
        return false;
      }
    }).toList();

    print(selectedItems);

    return DefaultTabController(
      length: docCategoriesTabs.length,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
          backgroundColor: AppColors.bodyTextColorLight,
          bottom: TabBar(
            indicatorColor: AppColors.primaryPurple,
            labelStyle: TextStyle(
              fontSize: 24.0.sp,
              fontWeight: FontWeight.bold,
              fontFamily:
                  GoogleFonts.poppins(fontWeight: FontWeight.bold).fontFamily,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.0.sp,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
            labelColor: Colors.black,
            isScrollable: true,
            tabs: docCategoriesTabs,
          ),
          toolbarTextStyle:
              GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
                  .bodyMedium,
          titleTextStyle:
              GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
                  .titleLarge,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    children: [
                      allUserDocs.isNotEmpty
                          ? SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: defaultPadding,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    allUserDocs.isNotEmpty
                                        ? Row(
                                            children: [
                                              Checkbox(
                                                checkColor: Colors.white,
                                                activeColor:
                                                    AppColors.primaryPurple,
                                                value: isSelectAll,
                                                shape: const CircleBorder(),
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isSelectAll = value!;

                                                    if (value == true) {
                                                      selectedItems.clear();
                                                      setState(() {
                                                        for (var item
                                                            in allUserDocs) {
                                                          selectedItems.add(
                                                              item["doc_id"]);
                                                        }
                                                      });
                                                    } else {
                                                      selectedItems = [];
                                                    }
                                                  });
                                                },
                                              ),
                                              const Text(
                                                'Select All',
                                                style: TextStyle(
                                                    color: AppColors
                                                        .primaryPurple),
                                              )
                                            ],
                                          )
                                        : Container(),
                                    for (var doc in allUserDocs)
                                      Column(
                                        children: [
                                          SizedBox(height: 10.h),
                                          GestureDetector(
                                              child: IndividualDoc(
                                            docData: doc,
                                            documentID: doc['doc_id'],
                                            callback: (val, isSelectAllfr) {
                                              selectedItems = val;
                                              isSelectAll = isSelectAllfr;
                                              setState(() {});
                                            },
                                            selectedDocuments: selectedItems,
                                            isSelectedDoc: isSelectAll,
                                            documentTitle: doc['doc_title'],
                                            time:
                                                convertFirebaseTimestampToFormattedString(
                                                    doc['timeline_time']),
                                          )),
                                        ],
                                      )
                                  ],
                                ),
                              ),
                            )
                          : Lottie.network(
                              'https://assets3.lottiefiles.com/packages/lf20_aBYmBC.json'),
                      usgDocs.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: defaultPadding),
                              child: Column(
                                children: [
                                  usgDocs.isNotEmpty
                                      ? Row(
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.white,
                                              activeColor:
                                                  AppColors.primaryPurple,
                                              value: isSelectAllUSG,
                                              shape: const CircleBorder(),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isSelectAllUSG = value!;
                                                  if (value == true) {
                                                    setState(() {
                                                      for (var item
                                                          in usgDocs) {
                                                        selectedItems.add(
                                                            item["doc_id"]);
                                                      }
                                                    });
                                                  } else {
                                                    for (var item in usgDocs) {
                                                      selectedItems.remove(
                                                          item['doc_id']);
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Select All',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryPurple),
                                            )
                                          ],
                                        )
                                      : Container(),
                                  for (var doc in usgDocs)
                                    Column(
                                      children: [
                                        SizedBox(height: 10.h),
                                        GestureDetector(
                                            child: IndividualDoc(
                                          docData: doc,
                                          documentID: doc['doc_id'],
                                          callback: (val, isSelectAll) {
                                            selectedItems = val;
                                            isSelectAllUSG = isSelectAll;
                                            setState(() {});
                                          },
                                          selectedDocuments: selectedItems,
                                          isSelectedDoc: isSelectAllUSG,
                                          documentTitle: doc['doc_title'],
                                          time: doc['timeline_time'].toString(),
                                        )),
                                      ],
                                    )
                                ],
                              ),
                            )
                          : Lottie.network(
                              'https://assets3.lottiefiles.com/packages/lf20_aBYmBC.json'),
                      nonStressTestDocs.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: defaultPadding),
                              child: Column(
                                children: [
                                  nonStressTestDocs.isNotEmpty
                                      ? Row(
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.white,
                                              activeColor:
                                                  AppColors.primaryPurple,
                                              value: isSelectNonStressThings,
                                              shape: const CircleBorder(),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isSelectNonStressThings =
                                                      value!;

                                                  if (value == true) {
                                                    setState(() {
                                                      for (var item
                                                          in nonStressTestDocs) {
                                                        selectedItems.add(
                                                            item["doc_id"]);
                                                      }
                                                    });
                                                  } else {
                                                    for (var item
                                                        in nonStressTestDocs) {
                                                      selectedItems.remove(
                                                          item['doc_id']);
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Select All',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryPurple),
                                            )
                                          ],
                                        )
                                      : Container(),
                                  for (var doc in nonStressTestDocs)
                                    Column(
                                      children: [
                                        SizedBox(height: 10.h),
                                        GestureDetector(
                                            child: IndividualDoc(
                                          docData: doc,
                                          documentID: doc['doc_id'],
                                          callback: (val, isSelectAll) {
                                            selectedItems = val;
                                            isSelectNonStressThings =
                                                isSelectAll;
                                            setState(() {});
                                          },
                                          selectedDocuments: selectedItems,
                                          isSelectedDoc:
                                              isSelectNonStressThings,
                                          documentTitle: doc['doc_title'],
                                          time: doc['timeline_time'],
                                        )),
                                      ],
                                    )
                                ],
                              ),
                            )
                          : Lottie.network(
                              'https://assets3.lottiefiles.com/packages/lf20_aBYmBC.json'),
                      contractionStressTestDocs.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: defaultPadding),
                              child: Column(
                                children: [
                                  contractionStressTestDocs.isNotEmpty
                                      ? Row(
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.white,
                                              activeColor:
                                                  AppColors.primaryPurple,
                                              value:
                                                  isSelectContractionStressThings,
                                              shape: const CircleBorder(),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isSelectContractionStressThings =
                                                      value!;

                                                  if (value == true) {
                                                    setState(() {
                                                      for (var item
                                                          in contractionStressTestDocs) {
                                                        selectedItems.add(
                                                            item["doc_id"]);
                                                      }
                                                    });
                                                  } else {
                                                    for (var item
                                                        in contractionStressTestDocs) {
                                                      selectedItems.remove(
                                                          item['doc_id']);
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Select All',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryPurple),
                                            )
                                          ],
                                        )
                                      : Container(),
                                  for (var doc in contractionStressTestDocs)
                                    Column(
                                      children: [
                                        SizedBox(height: 10.h),
                                        GestureDetector(
                                            child: IndividualDoc(
                                          docData: doc,
                                          documentID: doc['doc_id'],
                                          callback: (val, isSelectAll) {
                                            selectedItems = val;
                                            isSelectContractionStressThings =
                                                isSelectAll;
                                            setState(() {});
                                          },
                                          selectedDocuments: selectedItems,
                                          isSelectedDoc:
                                              isSelectContractionStressThings,
                                          documentTitle: doc['doc_title'],
                                          time: doc['timeline_time'],
                                        )),
                                      ],
                                    )
                                ],
                              ),
                            )
                          : Lottie.network(
                              'https://assets3.lottiefiles.com/packages/lf20_aBYmBC.json'),
                      dopplerUltraSoundReportDocs.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: defaultPadding),
                              child: Column(
                                children: [
                                  dopplerUltraSoundReportDocs.isNotEmpty
                                      ? Row(
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.white,
                                              activeColor:
                                                  AppColors.primaryPurple,
                                              value:
                                                  isSelectDopplerUltrasoundReport,
                                              shape: const CircleBorder(),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isSelectDopplerUltrasoundReport =
                                                      value!;

                                                  if (value == true) {
                                                    setState(() {
                                                      for (var item
                                                          in dopplerUltraSoundReportDocs) {
                                                        selectedItems.add(
                                                            item["doc_id"]);
                                                      }
                                                    });
                                                  } else {
                                                    for (var item
                                                        in dopplerUltraSoundReportDocs) {
                                                      selectedItems.remove(
                                                          item['doc_id']);
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Select All',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryPurple),
                                            )
                                          ],
                                        )
                                      : Container(),
                                  for (var doc in dopplerUltraSoundReportDocs)
                                    Column(
                                      children: [
                                        SizedBox(height: 10.h),
                                        GestureDetector(
                                            child: IndividualDoc(
                                          docData: doc,
                                          documentID: doc['doc_id'],
                                          callback: (val, isSelectAll) {
                                            selectedItems = val;
                                            isSelectDopplerUltrasoundReport =
                                                isSelectAll;

                                            setState(() {});
                                          },
                                          selectedDocuments: selectedItems,
                                          isSelectedDoc:
                                              isSelectDopplerUltrasoundReport,
                                          documentTitle: doc['doc_title'],
                                          time: doc['timeline_time'],
                                        )),
                                      ],
                                    )
                                ],
                              ),
                            )
                          : Lottie.network(
                              'https://assets3.lottiefiles.com/packages/lf20_aBYmBC.json'),
                      otherDocs.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: defaultPadding),
                              child: Column(
                                children: [
                                  otherDocs.isNotEmpty
                                      ? Row(
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.white,
                                              activeColor:
                                                  AppColors.primaryPurple,
                                              value: isSelectOthers,
                                              shape: const CircleBorder(),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isSelectOthers = value!;

                                                  if (value == true) {
                                                    setState(() {
                                                      for (var item
                                                          in otherDocs) {
                                                        selectedItems.add(
                                                            item["doc_id"]);
                                                      }
                                                    });
                                                  } else {
                                                    for (var item
                                                        in otherDocs) {
                                                      selectedItems.remove(
                                                          item['doc_id']);
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Select All',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.primaryPurple),
                                            )
                                          ],
                                        )
                                      : Container(),
                                  for (var doc in otherDocs)
                                    Column(
                                      children: [
                                        SizedBox(height: 10.h),
                                        GestureDetector(
                                          child: IndividualDoc(
                                            docData: doc,
                                            documentID: doc['doc_id'],
                                            callback: (val, isSelectAll) {
                                              selectedItems = val;
                                              isSelectOthers = isSelectAll;
                                              setState(() {});
                                            },
                                            selectedDocuments: selectedItems,
                                            isSelectedDoc: isSelectOthers,
                                            documentTitle: doc['doc_title'],
                                            time: doc['timeline_time'],
                                          ),
                                        ),
                                      ],
                                    )
                                ],
                              ),
                            )
                          : Lottie.network(
                              'https://assets3.lottiefiles.com/packages/lf20_aBYmBC.json'),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              color: const Color.fromARGB(255, 245, 246, 254),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder:
                                (BuildContext context, StateSetter myState) {
                              return BottomSheet(
                                onClosing: () {},
                                builder: (BuildContext context) {
                                  return SizedBox(
                                    height: 350.h,
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: defaultPadding,
                                          right: defaultPadding,
                                          bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 30.h,
                                            ),
                                            Text(
                                              'Expiry Time',
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontFamily: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.bold)
                                                    .fontFamily,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 20.h,
                                            ),
                                            Form(
                                              key: _formKey,
                                              child: CustomTextField(
                                                isNumber: true,
                                                hintText:
                                                    "Enter Expiry time in hrs",
                                                controller:
                                                    expireTimeController,
                                                validator: (value) {
                                                  if (value
                                                      .toString()
                                                      .isEmpty) {
                                                    return 'Time Required';
                                                  } else if (int.parse(value) >
                                                      30) {
                                                    return 'Maximum Limit 30 days';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              height: 20.h,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Share Profile",
                                                  style: TextStyle(
                                                    fontSize: 20.sp,
                                                    fontFamily:
                                                        GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500)
                                                            .fontFamily,
                                                  ),
                                                ),
                                                StatefulBuilder(builder:
                                                    (BuildContext context,
                                                        StateSetter
                                                            stateSetter) {
                                                  return Switch(
                                                    value: shareProfile,
                                                    activeColor:
                                                        AppColors.primaryPurple,
                                                    onChanged: (val) {
                                                      stateSetter(() =>
                                                          shareProfile = val);
                                                    },
                                                  );
                                                }),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 50.h,
                                            ),
                                            PrimaryIconButton(
                                              buttonTitle: "Next",
                                              buttonIcon: FaIcon(
                                                FontAwesomeIcons.link,
                                                size: 18.w,
                                              ),
                                              onPressed: () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  Navigator.pop(context);
                                                  var res = await sendDetails(
                                                      selectedItems);
                                                  final Map parsed =
                                                      json.decode(res);

                                                  fetchExpire();
                                                  setState(() {});
                                                  if (mounted) {
                                                    showModalBottomSheet(
                                                        context: modalContext,
                                                        builder: (BuildContext
                                                            context) {
                                                          return SizedBox(
                                                            height: 500.h,
                                                            child: Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          defaultPadding),
                                                              child: Column(
                                                                  children: [
                                                                    SizedBox(
                                                                      height:
                                                                          40.h,
                                                                    ),
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              8),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(10),
                                                                        border:
                                                                            Border.all(
                                                                          color: const Color.fromARGB(
                                                                              255,
                                                                              224,
                                                                              223,
                                                                              223),
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          QrImageView(
                                                                        data: parsed[
                                                                            'share_doc_link'],
                                                                        size: 200
                                                                            .h,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            30.h),
                                                                    Container(
                                                                        padding:
                                                                            const EdgeInsets.all(
                                                                                8),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          borderRadius:
                                                                              BorderRadius.circular(10),
                                                                          border:
                                                                              Border.all(
                                                                            color: const Color.fromARGB(
                                                                                255,
                                                                                224,
                                                                                223,
                                                                                223),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            SizedBox(
                                                                              width: 300.w,
                                                                              child: Text(parsed['share_doc_link']),
                                                                            ),
                                                                            InkWell(
                                                                              child: const Icon(Icons.copy),
                                                                              onTap: () {
                                                                                FlutterClipboard.copy(parsed['share_doc_link']).then(
                                                                                  (value) => ScaffoldMessenger.of(context).showSnackBar(success),
                                                                                );
                                                                                Navigator.pop(context);
                                                                              },
                                                                            )
                                                                          ],
                                                                        )),
                                                                    SizedBox(
                                                                      height:
                                                                          20.h,
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              153.w,
                                                                          height:
                                                                              60.h,
                                                                          child:
                                                                              ElevatedButton.icon(
                                                                            onPressed:
                                                                                null,
                                                                            icon:
                                                                                const Icon(Icons.send, color: AppColors.primaryPurple),
                                                                            label:
                                                                                const Padding(
                                                                              padding: EdgeInsets.symmetric(horizontal: 8),
                                                                              child: Text(
                                                                                'Send Via Email',
                                                                                style: TextStyle(color: AppColors.primaryPurple),
                                                                                textAlign: TextAlign.center,
                                                                              ),
                                                                            ),
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12.0),
                                                                              ),
                                                                              backgroundColor: AppColors.bodyTextColorLight,
                                                                              textStyle: TextStyle(
                                                                                fontFamily: GoogleFonts.poppins().fontFamily,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontSize: 16.sp,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                            width:
                                                                                20.w),
                                                                        SizedBox(
                                                                          width:
                                                                              153.w,
                                                                          child: PrimaryButton(
                                                                              buttonTitle: 'View Shared Links',
                                                                              onPressed: () {
                                                                                Navigator.push(context, CupertinoPageRoute(builder: (_) => const Share()));
                                                                              }),
                                                                        )
                                                                      ],
                                                                    )
                                                                  ]),
                                                            ),
                                                          );
                                                        });
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share,
                          color: AppColors.primaryPurple,
                        ),
                        Text('Share')
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download,
                          color: AppColors.primaryPurple,
                        ),
                        Text('Download')
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      Text('Delete')
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

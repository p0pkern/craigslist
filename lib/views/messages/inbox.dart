import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// dart async library for setting up real time updates
import 'dart:async';
// amplify packages
import 'package:amplify_datastore/amplify_datastore.dart';
// amplify configuration and models
import '../../models/ModelProvider.dart';
import '../../models/Messages.dart';

class InboxPage extends StatefulWidget {
  final AmplifyDataStore dataStore;

  const InboxPage({Key? key, required this.dataStore}) : super(key: key);

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  // Change later
  final String userName = 'sender';
  // Change later

  late StreamSubscription<QuerySnapshot<Messages>> messageStream;

  List<Messages> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    getMessageStream();
    super.initState();
  }

  Future<void> getMessageStream() async {
    messageStream = widget.dataStore
        .observeQuery(Messages.classType)
        .listen((QuerySnapshot<Messages> snapshot) {
      setState(() {
        if (_isLoading) _isLoading = false;
        _messages = snapshot.items;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return (Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Inbox'),
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isNotEmpty
                ? Column(
                    children: [
                      Expanded(
                        flex: 7,
                        child: InboxList(
                            messages: _messages,
                            formattedMessages:
                                filterRecentMessagesByGroup(_messages),
                            dataStore: widget.dataStore),
                      ),
                      Expanded(
                          flex: 1,
                          child: Container(
                            color: Theme.of(context).primaryColor,
                          ))
                    ],
                  )
                : const Center(child: Text('No messages'))));
  }
}

class InboxList extends StatelessWidget {
  List<Messages> formattedMessages = [];
  List<Messages> messages = [];
  final AmplifyDataStore dataStore;

  InboxList(
      {Key? key,
      required this.formattedMessages,
      required this.messages,
      required this.dataStore})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (messages.isNotEmpty
        ? ListView.builder(
            itemCount: formattedMessages.length,
            itemBuilder: (_, index) => InboxItem(
                messages: messages,
                message: formattedMessages[index],
                dataStore: dataStore))
        : const Center(child: Text('No Messages')));
  }
}

class InboxItem extends StatelessWidget {
  final List<Messages> messages;
  final Messages message;
  final AmplifyDataStore dataStore;

  const InboxItem(
      {Key? key,
      required this.messages,
      required this.message,
      required this.dataStore})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Material(
        elevation: 3.0,
        shadowColor: Colors.black,
        shape:RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                borderRadius: BorderRadius.circular(10)),
        child: (
          ListTile(
            leading: leadingContent(message.customer, message.text),
            trailing: trailingContent(message.date),
            onTap: () => {
                  Navigator.pushNamed(context, '/msgDetail',
                      arguments: DetailData(
                          dataStore,
                          groupByConversation(messages, message.host,
                              message.customer, message.sale)))
                })),
      ),
    );
  }
}

Widget leadingContent(String? customer, String? message){
  return (
    Column(children: [
      Text(customer!.length > 8 ? customer.substring(0, 8) : customer,
      style: const TextStyle(fontSize: 20)),
      Text(message!.length > 25 ? message.substring(0, 25) : message),
    ],)
  );
}

Widget trailingContent(TemporalDateTime? date){
  
  DateTime parsedDate = DateTime.parse(date.toString());
  String formattedDate;

  if(withinCurrentDay(date!)) {
    formattedDate = DateFormat.jm().format(parsedDate);
  } else {
    formattedDate = DateFormat.Md().format(parsedDate);
  }

  return Text(formattedDate.length > 25
          ? formattedDate.substring(0, 25)
          : formattedDate);
}

List<Messages> filterRecentMessagesByGroup(List<Messages> messages) {
  List<Messages> formattedMessages = [];
  List<String> visited = [];
  bool flag = true;

  for (int i = 0; i < messages.length; i++) {
    String combined = '${messages[i].sale}${messages[i].customer}';
    for (int j = 0; j < visited.length; j++) {
      if (combined == visited[j]) {
        for (int k = 0; k < formattedMessages.length; k++) {
          if (identical(formattedMessages[k].sale, messages[i].sale)) {
            TemporalDateTime oldDate =
                messages[i].date ?? TemporalDateTime.now();
            formattedMessages[k] =
                formattedMessages[k].date!.compareTo(oldDate) >= 1
                    ? formattedMessages[k]
                    : messages[i];
          }
        }
        flag = false;
      }
    }
    if (flag) {
      formattedMessages.add(messages[i]);
      visited.add(combined);
      flag = true;
    }
    flag = true;
  }

  return formattedMessages;
}

List<Messages> groupByConversation(
    List<Messages> messages, String? host, String? customer, String? sale) {
  List<Messages> formattedMessages = [];

  for (int i = 0; i < messages.length; i++) {
    if (messages[i].host == host &&
        messages[i].customer == customer &&
        messages[i].sale == sale) {
      formattedMessages.add(messages[i]);
    }
  }

  return formattedMessages;
}

bool withinCurrentDay(TemporalDateTime messageDate) {
  DateTime currDate = DateTime.now();
  DateTime parseMessageDate = DateTime.parse(messageDate.toString());

  if(currDate.day < parseMessageDate.day) {
    return false;
  }
  return true;
}

class DetailData {
  final AmplifyDataStore ds;
  final List<Messages> m;

  DetailData(this.ds, this.m);

  AmplifyDataStore get dataStore {
    return ds;
  }

  List<Messages> get messages {
    return m;
  }
}

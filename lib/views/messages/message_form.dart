import 'package:flutter/material.dart';
// dart async library for setting up real time updates
import 'dart:async';
// amplify packages
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
// amplify configuration and models
import '../../models/ModelProvider.dart';
import '../../models/Messages.dart';

class MessageForm extends StatefulWidget {
  
  final Messages messageData;
  final String userName;
  final AmplifyDataStore dataStore;

  const MessageForm({Key? key, 
    required this.messageData,
    required this.dataStore,
    required this.userName
    }) : super(key: key);

  @override
  State<MessageForm> createState() => _MessageFormState();
}

class _MessageFormState extends State<MessageForm> {

  @override
  Widget build(BuildContext context) {
    
    final formKey = GlobalKey<FormState>();
    String newMessage = '';
    String userName = widget.userName;

    return (
      Form(
        key: formKey,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: paddingSides(context),
                  vertical: paddingTopAndBottom(context)),
              child: SizedBox(
                width: 300,
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'New Message', border: OutlineInputBorder()),
                  maxLines: 2,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.text,
                  onSaved: (value) {
                    newMessage = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || value == '') {
                      return 'Please enter a message';
                    } else {
                      return null;
                    }
                  }
                ),
              ),
            ),
            ElevatedButton(
            style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)))),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                await saveNewMessage(widget.messageData, newMessage, userName);
                formKey.currentState?.reset();
              }
            },
            child: const Icon(Icons.send),
          )])
        ));
    }
}


Future<void> saveNewMessage(Messages messageData, String newMessage, String userName) async {
  TemporalDateTime currDate = TemporalDateTime.now();

  Messages outMessage = Messages(
    sale: messageData.sale,
    host: messageData.host,
    customer: messageData.customer,
    sender: userName == messageData.host ? messageData.host : messageData.customer,
    receiver: userName == messageData.host ?  messageData.customer : messageData.host,
    senderSeen: true,
    receiverSeen: false,
    text: newMessage,
    date: currDate
  );

  try{
    await Amplify.DataStore.save(outMessage);
    print('Message sent successfully');
  } catch (e) {
    print("An error occurred saving new message: $e");
  }
}

double paddingSides(BuildContext context) {
  return MediaQuery.of(context).size.width * 0.03;
}

double paddingTopAndBottom(BuildContext context) {
  return MediaQuery.of(context).size.height * 0.01;
}

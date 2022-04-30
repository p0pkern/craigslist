// dart async library we will refer to when setting up real time updates
import 'dart:async';
import 'dart:core';
import 'dart:io';
// flutter and ui libraries
import 'package:flutter/material.dart';
// amplify packages we will need to use
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:image_picker/image_picker.dart';
// amplify configuration and models that should have been generated for you
import '../../models/ModelProvider.dart';
import 'sale_detail.dart';

class EditSaleForm extends StatefulWidget {
  const EditSaleForm({Key? key, required this.sale, required this.saleImages})
      : super(key: key);
  final Sale sale;
  final List<SaleImage> saleImages;

  @override
  _EditSaleFormState createState() => _EditSaleFormState();
}

class _EditSaleFormState extends State<EditSaleForm> {
  String? imageURL;
  final picker = ImagePicker();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _conditionController;
  late TextEditingController _zipcodeController;
  late TextEditingController _priceController;

  @override
  void initState() {
    _titleController = TextEditingController(text: widget.sale.title);
    _descriptionController =
        TextEditingController(text: widget.sale.description);
    _conditionController = TextEditingController(text: widget.sale.condition);
    _zipcodeController = TextEditingController(text: widget.sale.zipcode);
    _priceController = TextEditingController(text: widget.sale.price);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Sale'),
        actions: <Widget>[
          ElevatedButton(onPressed: _saveSale, child: Text('Save')),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: _titleController,
                  decoration:
                      InputDecoration(filled: true, labelText: 'Title')),
              TextFormField(
                  controller: _descriptionController,
                  decoration:
                      InputDecoration(filled: true, labelText: 'Description')),
              TextFormField(
                  controller: _conditionController,
                  decoration:
                      InputDecoration(filled: true, labelText: 'Condition')),
              TextFormField(
                  controller: _zipcodeController,
                  decoration:
                      InputDecoration(filled: true, labelText: 'Zipcode')),
              TextFormField(
                  controller: _priceController,
                  decoration:
                      InputDecoration(filled: true, labelText: 'Price')),
              ElevatedButton(
                  onPressed: uploadImage, child: Text('Upload Image')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSale() async {
    // get the current text field contents
    String title = _titleController.text;
    String condition = _conditionController.text;
    String description = _descriptionController.text;
    String zipcode = _zipcodeController.text;
    String price = _priceController.text;

    try {
      // fetch the sale that is going to be updated
      Sale originalSale = (await Amplify.DataStore.query(Sale.classType,
          where: Sale.ID.eq(widget.sale.id)))[0];

      // Create a new sale object from original sale's id and form fields
      Sale updatedSale = originalSale.copyWith(
        id: originalSale.id,
        title: title.isNotEmpty ? title : null,
        description: description.isNotEmpty ? description : null,
        condition: condition.isNotEmpty ? condition : null,
        zipcode: zipcode.isNotEmpty ? zipcode : null,
        price: price.isNotEmpty ? price : null,
      );

      // Save the updated sale in DataStore
      await Amplify.DataStore.save(updatedSale);

      // await Amplify.DataStore.save(SaleImage(
      //   imageURL: imageURL,
      //   saleID: newSale.getId(),
      // ));
      // Close the form
      // Navigator.of(context).pop();
      Navigator.popUntil(context, ModalRoute.withName('/mySales'));
    } catch (e) {
      debugPrint('An error occurred while saving Sale: $e');
    }
  }

  Future<String?> getDownloadUrl(key) async {
    try {
      final GetUrlResult result = await Amplify.Storage.getUrl(key: key);
      // NOTE: This code is only for demonstration
      // Your debug console may truncate the debugPrinted url string
      debugPrint('Got URL: ${result.url}');
      setState(() {
        imageURL = result.url;
      });
      return result.url;
    } on StorageException catch (e) {
      debugPrint('Error getting download URL: $e');
      return null;
    }
  }

  Future<void> uploadImage() async {
    final options = S3UploadFileOptions(
      accessLevel: StorageAccessLevel.guest,
    );

    // Select image from user's gallery
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      debugPrint('No image selected');
      return;
    }
    // Upload image with the current time as the key
    final key = DateTime.now().toString();
    final file = File(pickedFile.path);
    try {
      final UploadFileResult result = await Amplify.Storage.uploadFile(
          options: options,
          local: file,
          key: key,
          onProgress: (progress) {
            debugPrint("Fraction completed: " +
                progress.getFractionCompleted().toString());
          });
      debugPrint('Successfully uploaded image: ${result.key}');
      getDownloadUrl(key);
    } on StorageException catch (e) {
      debugPrint('Error uploading image: $e');
    }
  }
}

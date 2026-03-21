import 'package:flutter/material.dart';

class SettingsSection extends StatefulWidget {
  @override
  _SettingsSectionState createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController appNameController = TextEditingController(
    text: "EasyConnect",
  );
  TextEditingController supportEmailController = TextEditingController(
    text: "support@easyconnect.com",
  );
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: appNameController,
            decoration: InputDecoration(labelText: "Nom de l'application"),
            validator: (v) => v!.isEmpty ? "Champ requis" : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: supportEmailController,
            decoration: InputDecoration(labelText: "Email support"),
            validator: (v) => !v!.contains('@') ? "Email invalide" : null,
          ),
          SizedBox(height: 16),
          SwitchListTile(
            title: Text("Mode sombre"),
            value: darkMode,
            onChanged: (v) => setState(() => darkMode = v),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres sauvegardés')),
                );
              }
            },
            child: Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }
}

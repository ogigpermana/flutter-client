import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_form.dart';
import 'package:invoiceninja_flutter/ui/settings/product_settings_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/settings_scaffold.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class ProductSettings extends StatefulWidget {
  const ProductSettings({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final ProductSettingsVM viewModel;

  @override
  _ProductSettingsState createState() => _ProductSettingsState();
}

class _ProductSettingsState extends State<ProductSettings> {
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final company = viewModel.company;

    return SettingsScaffold(
      title: localization.productSettings,
      onSavePressed: viewModel.onSavePressed,
      body: AppForm(
        formKey: _formKey,
        children: <Widget>[
          FormCard(
            children: <Widget>[
              SwitchListTile(
                activeColor: Theme.of(context).accentColor,
                title: Text(localization.fillProducts),
                value: company.fillProducts ?? false,
                subtitle: Text(localization.fillProductsHelp),
                onChanged: (value) => viewModel.onCompanyChanged(
                    company.rebuild((b) => b..fillProducts = value)),
              ),
              SwitchListTile(
                activeColor: Theme.of(context).accentColor,
                title: Text(localization.updateProducts),
                value: company.updateProducts ?? true,
                subtitle: Text(localization.updateProductsHelp),
                onChanged: (value) => viewModel.onCompanyChanged(
                    company.rebuild((b) => b..updateProducts = value)),
              ),
              SwitchListTile(
                activeColor: Theme.of(context).accentColor,
                title: Text(localization.convertProducts),
                value: company.convertProductExchangeRate ?? false,
                subtitle: Text(localization.convertProductsHelp),
                onChanged: (value) => viewModel.onCompanyChanged(company
                    .rebuild((b) => b..convertProductExchangeRate = value)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
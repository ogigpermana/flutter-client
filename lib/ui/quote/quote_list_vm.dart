import 'dart:async';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/redux/client/client_actions.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_actions.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_list.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_list_vm.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/pdf.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';

class QuoteListBuilder extends StatelessWidget {
  static const String route = '/quote/edit';

  const QuoteListBuilder({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, QuoteListVM>(
      converter: QuoteListVM.fromStore,
      builder: (context, vm) {
        return InvoiceList(
          viewModel: vm,
        );
      },
    );
  }
}

class QuoteListVM extends EntityListVM {

  QuoteListVM({
    UserEntity user,
    ListUIState listState,
    List<int> invoiceList,
    BuiltMap<int, InvoiceEntity> invoiceMap,
    BuiltMap<int, ClientEntity> clientMap,
    String filter,
    bool isLoading,
    bool isLoaded,
    Function(BuildContext, InvoiceEntity) onInvoiceTap,
    Function(BuildContext, InvoiceEntity, DismissDirection) onDismissed,
    Function(BuildContext) onRefreshed,
    Function onClearClientFilterPressed,
    Function(BuildContext) onViewClientFilterPressed,
    Function(BuildContext, InvoiceEntity, EntityAction) onEntityAction,
  }) : super(
    user: user,
    listState: listState,
    invoiceList: invoiceList,
    invoiceMap: invoiceMap,
    clientMap: clientMap,
    filter: filter,
    isLoading: isLoading,
    isLoaded: isLoaded,
    onInvoiceTap: onInvoiceTap,
    onDismissed: onDismissed,
    onRefreshed: onRefreshed,
    onClearClientFilterPressed: onClearClientFilterPressed,
    onViewClientFilterPressed: onViewClientFilterPressed,
    onEntityAction: onEntityAction,
  );

  static QuoteListVM fromStore(Store<AppState> store) {
    Future<Null> _handleRefresh(BuildContext context) {
      if (store.state.isLoading) {
        return Future<Null>(null);
      }
      final completer = snackBarCompleter(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(LoadQuotes(completer: completer, force: true));
      return completer.future;
    }

    final state = store.state;

    return QuoteListVM(
        user: state.user,
        listState: state.quoteListState,
        invoiceList: memoizedFilteredQuoteList(
            state.quoteState.map,
            state.quoteState.list,
            state.clientState.map,
            state.quoteListState),
        invoiceMap: state.quoteState.map,
        clientMap: state.clientState.map,
        isLoading: state.isLoading,
        isLoaded: state.quoteState.isLoaded && state.clientState.isLoaded,
        filter: state.quoteListState.filter,
        onInvoiceTap: (context, quote) {
          store.dispatch(ViewQuote(quoteId: quote.id, context: context));
        },
        onRefreshed: (context) => _handleRefresh(context),
        onClearClientFilterPressed: () =>
            store.dispatch(FilterQuotesByClient()),
        onViewClientFilterPressed: (BuildContext context) => store.dispatch(
            ViewClient(
                clientId: state.quoteListState.filterClientId,
                context: context)),
        onEntityAction: (context, quote, action) {
          final localization = AppLocalization.of(context);
          switch (action) {
            case EntityAction.pdf:
              Navigator.of(context).pop();
              viewPdf(quote, context);
              break;
            case EntityAction.markSent:
              store.dispatch(MarkSentQuoteRequest(
                  popCompleter(
                      context, localization.markedQuoteAsSent),
                  quote.id));
              break;
            case EntityAction.email:
              store.dispatch(ShowEmailQuote(
                  completer: popCompleter(
                      context, localization.emailedQuote),
                  quote: quote,
                  context: context));
              break;
            case EntityAction.clone:
              Navigator.of(context).pop();
              store.dispatch(
                  EditQuote(context: context, quote: quote.clone));
              break;
            case EntityAction.restore:
              store.dispatch(RestoreQuoteRequest(
                  popCompleter(
                      context, localization.restoredQuote),
                  quote.id));
              break;
            case EntityAction.archive:
              store.dispatch(ArchiveQuoteRequest(
                  popCompleter(
                      context, localization.archivedQuote),
                  quote.id));
              break;
            case EntityAction.delete:
              store.dispatch(DeleteQuoteRequest(
                  popCompleter(
                      context, localization.deletedQuote),
                  quote.id));
              break;
          }
        },
        onDismissed: (BuildContext context, InvoiceEntity quote,
            DismissDirection direction) {
          final localization = AppLocalization.of(context);
          if (direction == DismissDirection.endToStart) {
            if (quote.isDeleted || quote.isArchived) {
              store.dispatch(RestoreQuoteRequest(
                  snackBarCompleter(
                      context, localization.restoredQuote),
                  quote.id));
            } else {
              store.dispatch(ArchiveQuoteRequest(
                  snackBarCompleter(
                      context, localization.archivedQuote),
                  quote.id));
            }
          } else if (direction == DismissDirection.startToEnd) {
            if (quote.isDeleted) {
              store.dispatch(RestoreQuoteRequest(
                  snackBarCompleter(
                      context, localization.restoredQuote),
                  quote.id));
            } else {
              store.dispatch(DeleteQuoteRequest(
                  snackBarCompleter(
                      context, localization.deletedQuote),
                  quote.id));
            }
          }
        });
  }
}

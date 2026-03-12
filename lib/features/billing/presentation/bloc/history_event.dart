part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {}

class SearchHistoryEvent extends HistoryEvent {
  final String query;
  const SearchHistoryEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class DeleteSaleEvent extends HistoryEvent {
  final String saleId;
  const DeleteSaleEvent(this.saleId);

  @override
  List<Object?> get props => [saleId];
}

class AddSaleToHistoryEvent extends HistoryEvent {
  final Sale sale;
  const AddSaleToHistoryEvent(this.sale);

  @override
  List<Object?> get props => [sale];
}

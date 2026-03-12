import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/sale.dart';
import '../../data/models/sale_model.dart';
import '../../../../core/data/hive_database.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(const HistoryState()) {
    on<LoadHistoryEvent>(_onLoadHistory);
    on<SearchHistoryEvent>(_onSearchHistory);
    on<DeleteSaleEvent>(_onDeleteSale);
    on<AddSaleToHistoryEvent>(_onAddSale);
  }

  void _onLoadHistory(LoadHistoryEvent event, Emitter<HistoryState> emit) {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      final sales = HiveDatabase.saleBox.values.toList();
      // Sort by date descending (newest first)
      sales.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      emit(state.copyWith(
        status: HistoryStatus.success,
        allSales: sales,
        filteredSales: sales,
      ));
    } catch (e) {
      emit(state.copyWith(status: HistoryStatus.error, error: e.toString()));
    }
  }

  void _onSearchHistory(SearchHistoryEvent event, Emitter<HistoryState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredSales: state.allSales));
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = state.allSales.where((sale) {
      // Search in product names
      final hasProduct = sale.items.any((item) => item.productName.toLowerCase().contains(query));
      // Search in ID
      final hasId = sale.id.toLowerCase().contains(query);
      return hasProduct || hasId;
    }).toList();

    emit(state.copyWith(filteredSales: filtered));
  }

  Future<void> _onDeleteSale(DeleteSaleEvent event, Emitter<HistoryState> emit) async {
    try {
      final index = HiveDatabase.saleBox.values.toList().indexWhere((s) => s.id == event.saleId);
      if (index >= 0) {
        await HiveDatabase.saleBox.deleteAt(index);
        add(LoadHistoryEvent());
      }
    } catch (e) {
      emit(state.copyWith(status: HistoryStatus.error, error: e.toString()));
    }
  }

  Future<void> _onAddSale(AddSaleToHistoryEvent event, Emitter<HistoryState> emit) async {
    try {
      final model = SaleModel.fromEntity(event.sale);
      await HiveDatabase.saleBox.add(model);
      add(LoadHistoryEvent());
    } catch (e) {
      emit(state.copyWith(status: HistoryStatus.error, error: e.toString()));
    }
  }
}

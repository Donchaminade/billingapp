part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, success, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<Sale> allSales;
  final List<Sale> filteredSales;
  final String? error;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.allSales = const [],
    this.filteredSales = const [],
    this.error,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<Sale>? allSales,
    List<Sale>? filteredSales,
    String? error,
  }) {
    return HistoryState(
      status: status ?? this.status,
      allSales: allSales ?? this.allSales,
      filteredSales: filteredSales ?? this.filteredSales,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, allSales, filteredSales, error];
}

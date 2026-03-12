import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class AddProductsUseCase implements UseCase<void, List<Product>> {
  final ProductRepository repository;

  AddProductsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(List<Product> params) async {
    return await repository.addProducts(params);
  }
}

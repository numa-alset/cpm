import '../dao/product_dao.dart';
import '../models/product.dart';

class ProductRepository {
  final ProductDAO _productDAO;

  ProductRepository(this._productDAO);

  Future<int> create(Product product) => _productDAO.insert(product);

  Future<int> update(Product product) => _productDAO.update(product);

  Future<int> delete(String unified) => _productDAO.softDelete(unified);

  Future<Product?> get(String unified) => _productDAO.getByUnified(unified);

  Future<List<Product>> getAll() => _productDAO.getAll();

  Future<List<Product>> search(String keyword) => _productDAO.search(keyword);

  Future<bool> exists(String unified) => _productDAO.exists(unified);

  Future<int> count() => _productDAO.count();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  CategoryNotifier() : super(const AsyncValue.loading()) {
    fetchCategories();
  }

  final _service = CategoryService();

  Future<void> fetchCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _service.fetchCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(Category category) async {
    await _service.insertCategory(category);
    await fetchCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _service.updateCategory(category);
    await fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _service.deleteCategory(id);
    await fetchCategories();
  }
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>(
      (ref) => CategoryNotifier(),
    );

import '../models/savings_entry.dart';
import 'database_service.dart';

class SavingsEntryService {
  static final SavingsEntryService _instance = SavingsEntryService._internal();
  factory SavingsEntryService() => _instance;
  SavingsEntryService._internal();

  Future<int> insertEntry(SavingsEntry entry) async {
    final db = await DatabaseService().db;
    return await db.insert('savings_entries', entry.toMap());
  }

  Future<List<SavingsEntry>> fetchEntries(int goalId) async {
    final db = await DatabaseService().db;
    final maps = await db.query(
      'savings_entries',
      where: 'goalId = ?',
      whereArgs: [goalId],
      orderBy: 'date ASC',
    );
    return maps.map((e) => SavingsEntry.fromMap(e)).toList();
  }

  Future<int> updateEntry(SavingsEntry entry) async {
    final db = await DatabaseService().db;
    return await db.update(
      'savings_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await DatabaseService().db;
    return await db.delete('savings_entries', where: 'id = ?', whereArgs: [id]);
  }
}

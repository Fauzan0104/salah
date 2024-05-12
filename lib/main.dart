import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import package for line chart
import 'package:intl/intl.dart'; // Import package for currency formatting
import 'package:pengeluaran_harian/login/login_screen.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengeluaran harian',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Set home to LoginScreen
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;

  Expense({required this.id, required this.title, required this.amount});
}

class ExpenseListScreen extends StatefulWidget {
  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late Database _database; // Definisikan variabel _database di sini
  List<Expense> _expenses = []; // Definisikan _expenses di sini

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      'expenses.db',
      version: 1,
      onCreate: (db, version) async {
        // Buat tabel baru jika belum ada
        await db.execute('''
          CREATE TABLE expenses(
            id TEXT PRIMARY KEY,
            title TEXT,
            amount REAL
          )
        ''');
      },
    );
    await _loadExpenses(); // Muat pengeluaran setelah database siap
  }

  Future<void> _loadExpenses() async {
    final List<Map<String, dynamic>> expenseMaps =
        await _database.query('expenses');
    setState(() {
      _expenses = expenseMaps
          .map((expenseMap) => Expense(
                id: expenseMap['id'],
                title: expenseMap['title'],
                amount: expenseMap['amount'],
              ))
          .toList();
    });
  }

  Future<void> _addExpense(String title, double amount) async {
    final newExpense = Expense(
      id: DateTime.now().toString(),
      title: title,
      amount: amount,
    );
    setState(() {
      _expenses.add(newExpense);
    });
    await _saveExpense(newExpense); // Simpan pengeluaran baru ke dalam database
  }

  Future<void> _saveExpense(Expense expense) async {
    await _database.insert(
      'expenses',
      {
        'id': expense.id,
        'title': expense.title,
        'amount': expense.amount,
      },
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Ganti data jika sudah ada data dengan id yang sama
    );
  }

  Future<void> _removeExpense(String id) async {
    setState(() {
      _expenses.removeWhere((expense) => expense.id == id);
    });
    await _database.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _editExpense(
      String id, String newTitle, double newAmount) async {
    setState(() {
      // Cari pengeluaran yang sesuai dengan id
      final expenseIndex = _expenses.indexWhere((expense) => expense.id == id);
      if (expenseIndex != -1) {
        // Ubah data pengeluaran dengan data baru
        _expenses[expenseIndex] = Expense(
          id: id,
          title: newTitle,
          amount: newAmount,
        );
      }
    });
    await _saveExpenses(); // Simpan pengeluaran setelah diedit
  }

  Future<void> _showEditExpenseDialog(
      BuildContext context, Expense expense) async {
    TextEditingController titleController =
        TextEditingController(text: expense.title);
    TextEditingController amountController =
        TextEditingController(text: expense.amount.toString());

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = titleController.text;
              final newAmount = double.parse(amountController.text);
              _editExpense(expense.id, newTitle, newAmount);
              Navigator.of(ctx).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpenses() async {
    // Buka atau buat database SQLite
    Database db = await openDatabase('expenses.db');

    // Mulai transaksi untuk menyimpan data pengeluaran
    await db.transaction((txn) async {
      // Hapus semua data yang ada sebelum menyimpan yang baru
      await txn.delete('expenses');

      // Simpan setiap pengeluaran ke dalam tabel 'expenses'
      for (var expense in _expenses) {
        await txn.insert('expenses', {
          'id': expense.id,
          'title': expense.title,
          'amount': expense.amount,
        });
      }
    });

    // Tutup database setelah selesai
    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengeluaran harian'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text('Login'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: Text('Register'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (ctx, index) {
                final expense = _expenses[index];
                return ListTile(
                  title: Text(expense.title),
                  subtitle: Text(
                      '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp').format(expense.amount)}'), // Format menjadi mata uang Rupiah
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () =>
                            _showEditExpenseDialog(context, expense),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeExpense(expense.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildTotalExpense(),
          _buildLineChart(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExpenseDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalExpense() {
    double totalExpense =
        _expenses.fold(0, (prev, expense) => prev + expense.amount);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Total Pengeluaran: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp').format(totalExpense)}',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLineChart() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: _expenses
                    .asMap()
                    .entries
                    .map((entry) =>
                        FlSpot(entry.key.toDouble(), entry.value.amount))
                    .toList(),
                isCurved: true,
                colors: [Colors.blue],
                barWidth: 2,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
              ),
            ],
            minX: 0,
            maxX: _expenses.length.toDouble() - 1,
            minY: 0,
            maxY: _calculateMaxAmount(),
          ),
        ),
      ),
    );
  }

  double _calculateMaxAmount() {
    if (_expenses.isEmpty) return 0;
    return _expenses
        .map((expense) => expense.amount)
        .reduce((a, b) => a > b ? a : b);
  }

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text;
              final amount = double.parse(amountController.text);
              _addExpense(title, amount);
              Navigator.of(ctx).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

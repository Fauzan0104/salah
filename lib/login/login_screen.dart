import 'package:flutter/material.dart';
import 'package:pengeluaran_harian/login/register_screen.dart';
import 'package:pengeluaran_harian/main.dart';
import 'package:sqflite/sqflite.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    Future<bool> login(String email, String password) async {
      // Buka atau buat database SQLite
      Database db = await openDatabase('users.db');

      // Query database untuk memeriksa apakah pengguna terdaftar
      List<Map> result = await db.rawQuery('''
        SELECT * FROM users WHERE email = ? AND password = ?
      ''', [email, password]);

      // Tutup database setelah selesai
      await db.close();

      // Return true jika pengguna ditemukan, false jika tidak ditemukan
      return result.isNotEmpty;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mbuh Pusing Aku!!',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            TextField(
              controller:
                  emailController, // Tambahkan controller untuk TextField email
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Masukkan Email Anda',
              ),
            ),
            SizedBox(height: 10.0),
            TextField(
              controller:
                  passwordController, // Tambahkan controller untuk TextField password
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan Password Anda',
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;
                String password = passwordController.text;
                bool loggedIn = await login(email,
                    password); // Panggil fungsi login dengan email dan password yang dimasukkan
                if (loggedIn) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MyApp()),
                  );
                } else {
                  // Show dialog if account does not exist
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Akun belum terdaftar!'),
                        content: Text('Gae Akun anyar ta?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Gak wes'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to registration screen if user chooses to create account
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegisterScreen()),
                              );
                            },
                            child: Text('Create Account'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Handle forgot password button pressed
              },
              child: Text('Forgot Password?'),
            ),
            SizedBox(height: 10.0),
            TextButton(
              onPressed: () {
                // Navigate to registration screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

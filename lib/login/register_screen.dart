import 'package:flutter/material.dart';
import 'package:pengeluaran_harian/login/login_screen.dart';
import 'package:sqflite/sqflite.dart';

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    void registerAccount(String email, String password) async {
      // Buka atau buat database SQLite
      Database db = await openDatabase('users.db');

      // Insert informasi akun pengguna ke dalam tabel 'users'
      await db.transaction((txn) async {
        await txn.rawInsert('''
          INSERT INTO users(email, password) VALUES(?, ?)
        ''', [email, password]);
      });

      // Tutup database setelah selesai
      await db.close();
    }

    void showAlertDialog(BuildContext context, String message) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Registration Result'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  // Navigate to login screen after account creation
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create an Account',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Masukkan Email Anda',
              ),
            ),
            SizedBox(height: 10.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan Password Anda',
              ),
            ),
            SizedBox(height: 10.0),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                hintText: 'Konfirmasi Password Anda',
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                String email = emailController.text;
                String password = passwordController.text;
                String confirmPassword = confirmPasswordController.text;

                if (password == confirmPassword) {
                  // Jika password dan konfirmasi password sama, lakukan pendaftaran
                  registerAccount(email, password);
                  showAlertDialog(context,
                      'Akun Anda telah berhasil dibuat! silahkan login.');
                } else {
                  // Jika password dan konfirmasi password tidak sama, tampilkan pesan kesalahan
                  showAlertDialog(
                      context, 'Password and confirm password do not match.');
                }
              },
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

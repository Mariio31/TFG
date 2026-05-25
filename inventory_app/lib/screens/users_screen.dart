import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> users = [];
  bool loading = true;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);
    final id = await ApiService.getUserId();
    final data = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        currentUserId = id;
        users = data;
        loading = false;
      });
    }
  }

  String roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Manager';
      case 'employee':
        return 'Empleado';
      default:
        return role;
    }
  }

  Color roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.deepPurple;
      case 'manager':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> handleDelete(int id, String name) async {
    if (id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminar tu propia cuenta')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await ApiService.deleteUser(id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      await loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado')),
        );
      }
    }
  }

  Future<void> openCreateUserForm() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'employee';
    List<String> passwordErrors = [];

    String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'La contraseña es obligatoria';
      }
      if (value.length < 8 || !value.contains(RegExp(r'[A-Z]'))) {
        return 'Contraseña inválida';
      }
      return null;
    }

    void validatePasswordErrors(String value, void Function(void Function()) setModalState) {
      final errors = <String>[];
      if (value.isNotEmpty) {
        if (value.length < 8) {
          errors.add('Mínimo 8 caracteres');
        }
        if (!value.contains(RegExp(r'[A-Z]'))) {
          errors.add('Al menos una mayúscula');
        }
      }
      setModalState(() => passwordErrors = errors);
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nuevo usuario',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || !v.contains('@') ? 'Email inválido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: validatePassword,
                        onChanged: (value) =>
                            validatePasswordErrors(value, setModalState),
                      ),
                      if (passwordErrors.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: passwordErrors.map((msg) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  '• $msg',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Manager'),
                          ),
                          DropdownMenuItem(
                            value: 'employee',
                            child: Text('Empleado'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedRole = v);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final ok = await ApiService.createUser({
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                            'password': passwordController.text,
                            'role': selectedRole,
                          });
                          if (context.mounted) {
                            if (ok) {
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se pudo crear el usuario (¿email duplicado?)',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Crear usuario',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      await loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Gestión de usuarios'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateUserForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadUsers,
              child: users.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No hay usuarios registrados')),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final id = user['id'] as int;
                        final name = user['name']?.toString() ?? '';
                        final email = user['email']?.toString() ?? '';
                        final role = user['role']?.toString() ?? 'employee';
                        final isSelf = id == currentUserId;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: roleColor(role).withOpacity(0.15),
                              child: Icon(Icons.person, color: roleColor(role)),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    roleLabel(role),
                                    style: TextStyle(
                                      color: roleColor(role),
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: roleColor(role).withOpacity(0.1),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            trailing: isSelf
                                ? const Tooltip(
                                    message: 'Tu cuenta',
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => handleDelete(id, name),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'NavBar.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? category;
  final String role;
  final String? tutor;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.category,
    required this.role,
    this.tutor,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? category,
    String? role,
    String? tutor,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      category: category ?? this.category,
      role: role ?? this.role,
      tutor: tutor ?? this.tutor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.title});
  final String title;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late List<UserProfile> users = [
    UserProfile(
      id: '1',
      name: 'Ana Silva',
      email: 'ana.silva@meninasdigitais.com',
      category: null,
      role: 'Tutoranda',
      tutor: 'Prof. Marina Costa',
      createdAt: DateTime.now(),
    ),
    UserProfile(
      id: '2',
      name: 'Bárbara Souza',
      email: 'barbara.souza@meninasdigitais.com',
      category: 'Programação',
      role: 'Tutor',
      tutor: null,
      createdAt: DateTime.now(),
    ),
    UserProfile(
      id: '3',
      name: 'Carla Lima',
      email: 'carla.lima@meninasdigitais.com',
      category: null,
      role: 'Tutoranda',
      tutor: 'Prof. Juliana Ramos',
      createdAt: DateTime.now(),
    ),
  ];

  String searchQuery = '';
  late TextEditingController searchController;
  String selectedClassFilter = 'Todos';
  final List<String> classFilters = ['Todos', 'Tutor', 'Tutoranda'];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<UserProfile> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();
    return users.where((user) {
      final matchesClass =
          selectedClassFilter == 'Todos' || user.role == selectedClassFilter;
      final matchesName = user.name.toLowerCase().contains(query);
      final matchesCategory =
          user.category?.toLowerCase().contains(query) ?? false;
      final matchesQuery = query.isEmpty || matchesName || matchesCategory;
      return matchesClass && matchesQuery;
    }).toList();
  }

  void _addUser() {
    showDialog<UserProfile>(
      context: context,
      builder: (context) => _AddEditUserDialog(
        title: 'Adicionar Pessoa',
        onSubmit: (newUser) {
          setState(() {
            users.insert(0, newUser);
          });
        },
      ),
    );
  }

  void _showUserDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(
        user: users[index],
        onUpdate: (updatedUser) {
          setState(() {
            users[index] = updatedUser;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: NavBar.buildDrawer(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por nome ou categoria',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                                searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedClassFilter,
                        decoration: InputDecoration(
                          labelText: 'Classe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: classFilters
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedClassFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      users.isEmpty
                          ? 'Nenhum usuário cadastrado.'
                          : 'Nenhum usuário encontrado.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(user.email),
                              const SizedBox(height: 4),
                              Text(
                                user.category != null
                                    ? '${user.role} • ${user.category}'
                                    : user.role,
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(31),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.role,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _showUserDetails(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        tooltip: 'Adicionar pessoa',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _UserDetailsDialog extends StatelessWidget {
  final UserProfile user;
  final ValueChanged<UserProfile> onUpdate;

  const _UserDetailsDialog({required this.user, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhes da Pessoa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Nome', user.name),
          _infoRow('Email', user.email),
          if (user.category != null) _infoRow('Categoria', user.category!),
          _infoRow('Papel', user.role),
          _infoRow('Tutor', user.tutor ?? 'Não informado'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showDialog<UserProfile>(
              context: context,
              builder: (context) => _AddEditUserDialog(
                title: 'Editar Pessoa',
                user: user,
                onSubmit: (updatedUser) {
                  onUpdate(updatedUser);
                },
              ),
            );
          },
          child: const Text('Editar'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AddEditUserDialog extends StatefulWidget {
  final String title;
  final UserProfile? user;
  final ValueChanged<UserProfile> onSubmit;

  const _AddEditUserDialog({
    required this.title,
    this.user,
    required this.onSubmit,
  });

  @override
  State<_AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<_AddEditUserDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController categoryController;
  late TextEditingController tutorController;
  late String selectedRole;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user?.name ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    categoryController = TextEditingController(
      text: widget.user?.category ?? '',
    );
    tutorController = TextEditingController(text: widget.user?.tutor ?? '');
    selectedRole = widget.user?.role ?? 'Tutoranda';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    categoryController.dispose();
    tutorController.dispose();
    super.dispose();
  }

  void _submit() {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      return;
    }

    if (selectedRole == 'Tutor' && categoryController.text.trim().isEmpty) {
      return;
    }

    final updatedUser = UserProfile(
      id: widget.user?.id ?? DateTime.now().toString(),
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      category: selectedRole == 'Tutor' ? categoryController.text.trim() : null,
      role: selectedRole,
      tutor: tutorController.text.trim().isEmpty
          ? null
          : tutorController.text.trim(),
      createdAt: widget.user?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(updatedUser);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            if (selectedRole == 'Tutor')
              Column(
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Papel',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Tutor', child: Text('Tutor')),
                DropdownMenuItem(value: 'Tutoranda', child: Text('Tutoranda')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tutorController,
              decoration: InputDecoration(
                labelText: selectedRole == 'Tutoranda'
                    ? 'Orientador (opcional)'
                    : 'Orientador',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}

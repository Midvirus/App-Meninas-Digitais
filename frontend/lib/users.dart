import 'package:flutter/material.dart';
import 'NavBar.dart';
import 'api_client.dart';
import 'global_state.dart';

class UserProfile {
  final dynamic id;
  final String name;
  final String email;
  final String? category;
  final String role;
  final String? tutor;
  final String? observacoes;
  final DateTime createdAt;

  // Mock stats
  int get mockPosts => 12;
  int get mockDesafiosCriados => 5;
  int get mockTutorandas => 3;
  double get mockConclusao => 0.75;
  int get mockDesafiosFeitos => 15;
  int get mockAcertos => 12;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.category,
    required this.role,
    this.tutor,
    this.observacoes,
    required this.createdAt,
  });

  UserProfile copyWith({
    dynamic id,
    String? name,
    String? email,
    String? category,
    String? role,
    String? tutor,
    String? observacoes,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      category: category ?? this.category,
      role: role ?? this.role,
      tutor: tutor ?? this.tutor,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Parse from backend Usuario JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Map backend role enum to frontend display string
    final backendRole = json['role'] as String? ?? 'TUTORANDA';
    final role = ApiClient.mapRoleFromBackend(backendRole);

    // Extract tutor name from nested tutora object
    String? tutorName;
    final tutora = json['tutora'];
    if (tutora != null && tutora is Map<String, dynamic>) {
      tutorName = tutora['nome'] as String?;
    }

    return UserProfile(
      id: json['id'],
      name: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      category: json['escolaInstituicao'] as String?,
      role: role,
      tutor: tutorName,
      observacoes: null, // Backend doesn't have this field directly
      createdAt: json['criadoEm'] != null
          ? DateTime.parse(json['criadoEm'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to backend CadastroUsuarioRequest JSON format
  Map<String, dynamic> toBackendJson() {
    return {
      'nome': name,
      'email': email,
      'senha': 'Senha@123', // Default password for new users
      'escolaInstituicao': category,
      'role': ApiClient.mapRoleToBackend(role),
    };
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.title});
  final String title;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<UserProfile> users = [];
  bool _isLoadingUsers = true;
  String? _userError;
  String searchQuery = '';
  late TextEditingController searchController;
  String selectedClassFilter = 'Todos';
  final List<String> classFilters = ['Todos', 'Tutor', 'Tutoranda'];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    if (GlobalState.userRole == 'Tutoranda') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return;
    }
    _loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _userError = null;
    });

    try {
      final rawUsers = await ApiClient.listUsers();
      if (!mounted) return;

      List<UserProfile> allUsers = rawUsers
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .toList();

      // If user is Tutor, filter to show only their tutorandas
      if (GlobalState.userRole == 'Tutor') {
        allUsers = allUsers.where((u) => u.tutor == GlobalState.userName).toList();
      }

      // Sort by created date descending
      allUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        users = allUsers;
        _isLoadingUsers = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _userError = error.message;
        _isLoadingUsers = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _userError = error.toString();
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _saveUser(UserProfile user) async {
    try {
      await ApiClient.createUser(user.toBackendJson());
      await _loadUsers();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar usuário: ${error.message}')),
      );
    }
  }

  Future<void> _deleteUser(dynamic id) async {
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Usuário'),
        content: const Text('Tem certeza que deseja excluir este usuário?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiClient.deleteUser(id);
      await _loadUsers();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir usuário: ${error.message}')),
      );
    }
  }

  Future<void> _updateUser(UserProfile user) async {
    try {
      // For role changes, use the specific role endpoint
      final backendRole = ApiClient.mapRoleToBackend(user.role);
      await ApiClient.changeUserRole(user.id, backendRole);

      // If tutoranda, bind to tutor
      if (user.role == 'Tutoranda' && user.tutor != null) {
        // Find tutor ID from users list
        final tutorUser = users.where((u) => u.name == user.tutor && u.role == 'Tutor').firstOrNull;
        if (tutorUser != null) {
          await ApiClient.bindTutoranda(user.id, tutorUser.id);
        }
      }

      await _loadUsers();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar usuário: ${error.message}')),
      );
    }
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
    final tutorsList = users.where((u) => u.role == 'Tutor').toList();
    showDialog<UserProfile>(
      context: context,
      builder: (context) => _AddEditUserDialog(
        title: 'Adicionar Pessoa',
        tutors: tutorsList,
        onSubmit: (newUser) async {
          await _saveUser(newUser);
        },
      ),
    );
  }

  void _showUserDetails(int index) {
    final tutorsList = users.where((u) => u.role == 'Tutor').toList();
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(
        user: users[index],
        tutors: tutorsList,
        onUpdate: (updatedUser) async {
          await _updateUser(updatedUser);
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
                        value: selectedClassFilter,
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
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _userError != null
                    ? Center(
                        child: Text(
                          'Erro ao carregar usuários: $_userError',
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              users.isEmpty
                                  ? 'Nenhum usuário cadastrado.'
                                  : 'Nenhum usuário encontrado.',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showUserDetails(index),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(user.email),
                                                  if (user.role == 'Tutor' && (GlobalState.userRole?.toLowerCase() == 'admin' || GlobalState.userRole == 'Admin'))
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('Posts: ${user.mockPosts}', style: const TextStyle(fontSize: 12)),
                                                          Text('Desafios: ${user.mockDesafiosCriados}', style: const TextStyle(fontSize: 12)),
                                                          Text('Tutorandas: ${user.mockTutorandas}', style: const TextStyle(fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                  if (user.role == 'Tutoranda')
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('Tutor: ${user.tutor ?? 'Não atribuído'}', style: const TextStyle(fontSize: 12)),
                                                          Text('Concluído: ${(user.mockConclusao * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withAlpha(31),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                user.role,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (GlobalState.userRole?.toLowerCase() == 'admin' || GlobalState.userRole == 'Admin')
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _deleteUser(user.id),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: GlobalState.userRole == 'admin'
          ? FloatingActionButton(
              onPressed: _addUser,
              tooltip: 'Adicionar pessoa',
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}

class _UserDetailsDialog extends StatefulWidget {
  final UserProfile user;
  final List<UserProfile> tutors;
  final ValueChanged<UserProfile> onUpdate;

  const _UserDetailsDialog({required this.user, required this.tutors, required this.onUpdate});

  @override
  State<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<_UserDetailsDialog> {
  late TextEditingController obsController;

  @override
  void initState() {
    super.initState();
    obsController = TextEditingController(text: widget.user.observacoes ?? '');
  }

  @override
  void dispose() {
    obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTutor = GlobalState.userRole == 'Tutor';
    final isAdmin = GlobalState.userRole?.toLowerCase() == 'admin' || GlobalState.userRole == 'Admin';
    final user = widget.user;

    return AlertDialog(
      title: const Text('Detalhes da Pessoa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Nome', user.name),
            _infoRow('Email', user.email),
            _infoRow('Papel', user.role),
            if (user.role == 'Tutoranda') ...[
              const SizedBox(height: 8),
              _infoRow('Tutor', user.tutor ?? 'Não atribuído'),
              _infoRow('Desafios Feitos', '${user.mockDesafiosFeitos}'),
              _infoRow('Desafios Publicados', '${user.mockDesafiosCriados}'),
              _infoRow('Respostas Corretas', '${user.mockAcertos}'),
              const SizedBox(height: 16),
              const Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: obsController,
                maxLines: 4,
                readOnly: !isTutor,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Nenhuma observação',
                  fillColor: !isTutor ? Colors.grey[100] : null,
                  filled: !isTutor,
                ),
              ),
            ] else if (user.role == 'Tutor' && isAdmin) ...[
              const SizedBox(height: 8),
              _infoRow('Posts Feitos', '${user.mockPosts}'),
              _infoRow('Desafios Criados', '${user.mockDesafiosCriados}'),
              _infoRow('Tutorandas', '${user.mockTutorandas}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        if (isTutor && user.role == 'Tutoranda')
          TextButton(
            onPressed: () {
              final updated = widget.user.copyWith(observacoes: obsController.text.trim());
              Navigator.pop(context);
              widget.onUpdate(updated);
            },
            child: const Text('Salvar Observações'),
          ),
        if (isAdmin)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog<UserProfile>(
                context: context,
                builder: (context) => _AddEditUserDialog(
                  title: 'Editar Pessoa',
                  user: user,
                  tutors: widget.tutors,
                  onSubmit: (updatedUser) {
                    widget.onUpdate(updatedUser);
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
      padding: const EdgeInsets.only(bottom: 8),
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
  final List<UserProfile> tutors;
  final ValueChanged<UserProfile> onSubmit;

  const _AddEditUserDialog({
    required this.title,
    this.user,
    required this.tutors,
    required this.onSubmit,
  });

  @override
  State<_AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<_AddEditUserDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late String selectedRole;
  String? selectedTutor;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user?.name ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    selectedRole = widget.user?.role ?? 'Tutoranda';
    
    if (widget.user?.tutor != null && widget.user!.tutor!.isNotEmpty) {
      if (widget.tutors.any((t) => t.name == widget.user!.tutor)) {
        selectedTutor = widget.user!.tutor;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      return;
    }

    if (selectedRole == 'Tutoranda' && selectedTutor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um orientador.')),
      );
      return;
    }

    final updatedUser = UserProfile(
      id: widget.user?.id,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      category: null,
      role: selectedRole,
      tutor: selectedRole == 'Tutoranda' ? selectedTutor : null,
      observacoes: widget.user?.observacoes,
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
            DropdownButtonFormField<String>(
              value: selectedRole,
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
                    if (selectedRole == 'Tutor') {
                      selectedTutor = null;
                    }
                  });
                }
              },
            ),
            if (selectedRole == 'Tutoranda') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTutor,
                decoration: const InputDecoration(
                  labelText: 'Orientador (Tutor)',
                  border: OutlineInputBorder(),
                ),
                items: widget.tutors.map((tutor) {
                  return DropdownMenuItem(value: tutor.name, child: Text(tutor.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTutor = value;
                  });
                },
              ),
            ],
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

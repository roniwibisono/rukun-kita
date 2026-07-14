import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/warga_induk.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';

class DataWargaPage extends ConsumerStatefulWidget {
  const DataWargaPage({super.key});

  @override
  ConsumerState<DataWargaPage> createState() => _DataWargaPageState();
}

class _DataWargaPageState extends ConsumerState<DataWargaPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _nomorKkController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _alamatController = TextEditingController();
  final _agamaController = TextEditingController();
  final _pendidikanController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  final _loginController = TextEditingController();
  final _kodeAksesController = TextEditingController();

  DateTime? _tanggalLahir;
  String? _jenisKelamin;
  String? _hubunganKeluarga;
  String? _statusPernikahan;
  bool _isActive = true;
  bool _setupLogin = false;
  bool _isSaving = false;

  static const _hubunganOptions = [
    'Kepala Keluarga',
    'Istri',
    'Suami',
    'Anak',
    'Orang Tua',
    'Famili Lain',
  ];

  static const _statusOptions = [
    'Belum Kawin',
    'Kawin',
    'Cerai Hidup',
    'Cerai Mati',
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _nomorKkController.dispose();
    _tempatLahirController.dispose();
    _alamatController.dispose();
    _agamaController.dispose();
    _pendidikanController.dispose();
    _pekerjaanController.dispose();
    _loginController.dispose();
    _kodeAksesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedAsync = ref.watch(groupedWargaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data Warga')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _openWargaForm(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Tambah Warga'),
      ),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Data warga belum bisa dimuat',
          message: '$error',
        ),
        data: (grouped) {
          if (grouped.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Belum ada data warga',
              message: 'Data buku induk penduduk akan tampil per nomor KK.',
            );
          }

          final entries = grouped.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupedWargaProvider);
              ref.invalidate(wargaListProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final members = [...entry.value]..sort(_compareFamilyMember);
                final head = members.first;

                return Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.family_restroom_outlined),
                    title: Text(head.namaLengkap),
                    subtitle: Text(
                      'KK ${entry.key} • ${members.length} anggota',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => _openWargaForm(
                              context,
                              nomorKk: entry.key,
                              alamat: head.alamatLengkap,
                            ),
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Tambah Anggota KK'),
                          ),
                        ),
                      ),
                      for (final warga in members)
                        ListTile(
                          title: Text(warga.namaLengkap),
                          subtitle: Text(
                            [
                              'NIK ${warga.nik}',
                              if (warga.hubunganKeluarga != null)
                                warga.hubunganKeluarga!,
                              AppFormatters.date(warga.tanggalLahir),
                              warga.isActive ? 'Aktif' : 'Nonaktif',
                            ].join(' • '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showDetail(context, warga),
                        ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: entries.length,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openWargaForm(
    BuildContext context, {
    String? nomorKk,
    String? alamat,
  }) async {
    _resetForm(nomorKk: nomorKk, alamat: alamat);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        nomorKk == null
                            ? 'Tambah Data Warga'
                            : 'Tambah Anggota KK',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _namaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nikController,
                              keyboardType: TextInputType.number,
                              maxLength: 16,
                              decoration: const InputDecoration(
                                labelText: 'NIK',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              validator: _nikKkValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nomorKkController,
                              keyboardType: TextInputType.number,
                              maxLength: 16,
                              decoration: const InputDecoration(
                                labelText: 'Nomor KK',
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              validator: _nikKkValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _jenisKelamin,
                              decoration: const InputDecoration(
                                labelText: 'Jenis kelamin',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'L', child: Text('Laki-laki')),
                                DropdownMenuItem(
                                    value: 'P', child: Text('Perempuan')),
                              ],
                              onChanged: (value) {
                                setModalState(() => _jenisKelamin = value);
                              },
                              validator: (value) =>
                                  value == null ? 'Pilih jenis kelamin' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _hubunganKeluarga,
                              decoration: const InputDecoration(
                                labelText: 'Hubungan',
                                border: OutlineInputBorder(),
                              ),
                              items: _hubunganOptions
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setModalState(() => _hubunganKeluarga = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tempatLahirController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Tempat lahir',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _tanggalLahir ??
                                      DateTime(DateTime.now().year - 25),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (selected == null) return;
                                setModalState(() => _tanggalLahir = selected);
                              },
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                _tanggalLahir == null
                                    ? 'Tanggal lahir'
                                    : AppFormatters.date(_tanggalLahir!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _statusPernikahan,
                        decoration: const InputDecoration(
                          labelText: 'Status pernikahan',
                          border: OutlineInputBorder(),
                        ),
                        items: _statusOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setModalState(() => _statusPernikahan = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _alamatController,
                        minLines: 2,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Alamat lengkap',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _agamaController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Agama',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _pendidikanController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Pendidikan',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pekerjaanController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Pekerjaan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Warga aktif'),
                        value: _isActive,
                        onChanged: (value) {
                          setModalState(() => _isActive = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Buat / tautkan akun login'),
                        subtitle: const Text(
                          'Admin bisa menautkan warga ke akun yang sudah ada atau membuat akun baru.',
                        ),
                        value: _setupLogin,
                        onChanged: (value) {
                          setModalState(() {
                            _setupLogin = value;
                            if (value && _loginController.text.isEmpty) {
                              _loginController.text =
                                  _suggestLogin(_namaController.text);
                            }
                          });
                        },
                      ),
                      if (_setupLogin) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _loginController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username / email login',
                            hintText: 'Contoh: warga atau warga@email.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_circle_outlined),
                          ),
                          validator: (value) {
                            if (!_setupLogin) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Username/email wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _kodeAksesController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Kode akses awal / baru',
                            hintText:
                                'Wajib jika akun belum ada. Isi untuk reset password.',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveWarga(sheetContext, setModalState),
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Simpan Data Warga'),
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
  }

  void _resetForm({String? nomorKk, String? alamat}) {
    _formKey.currentState?.reset();
    _namaController.clear();
    _nikController.clear();
    _nomorKkController.text = nomorKk ?? '';
    _tempatLahirController.clear();
    _alamatController.text = alamat ?? '';
    _agamaController.clear();
    _pendidikanController.clear();
    _pekerjaanController.clear();
    _loginController.clear();
    _kodeAksesController.clear();
    _tanggalLahir = null;
    _jenisKelamin = null;
    _hubunganKeluarga = nomorKk == null ? 'Kepala Keluarga' : 'Anak';
    _statusPernikahan = null;
    _isActive = true;
    _setupLogin = false;
  }

  Future<void> _saveWarga(
    BuildContext sheetContext,
    void Function(void Function()) setModalState,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal lahir wajib dipilih.')),
      );
      return;
    }

    setModalState(() => _isSaving = true);
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final warga = WargaInduk(
        id: '',
        namaLengkap: _namaController.text.trim(),
        nomorKk: _nomorKkController.text.trim(),
        nik: _nikController.text.trim(),
        jenisKelamin: _jenisKelamin,
        tempatLahir: _optionalText(_tempatLahirController),
        tanggalLahir: _tanggalLahir!,
        agama: _optionalText(_agamaController),
        pendidikan: _optionalText(_pendidikanController),
        pekerjaan: _optionalText(_pekerjaanController),
        statusPernikahan: _statusPernikahan,
        hubunganKeluarga: _hubunganKeluarga,
        alamatLengkap: _alamatController.text.trim(),
        isActive: _isActive,
        createdAt: now,
      );

      final createdWarga =
          await ref.read(wargaRepositoryProvider).create(warga);
      var message = 'Data warga berhasil disimpan.';

      if (_setupLogin) {
        try {
          final account =
              await ref.read(wargaAccountRepositoryProvider).upsertForWarga(
                    wargaId: createdWarga.id,
                    login: _loginController.text.trim(),
                    kodeAkses: _optionalText(_kodeAksesController),
                  );
          message = account.createdAuthUser
              ? 'Data warga dan akun login berhasil dibuat.'
              : 'Data warga berhasil ditautkan ke akun login.';
        } catch (loginError) {
          message =
              'Data warga berhasil disimpan, tapi akun login gagal dibuat/ditautkan: $loginError';
        }
      }

      ref.invalidate(groupedWargaProvider);
      ref.invalidate(wargaListProvider);

      if (!mounted || !sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data warga: $e')),
      );
    } finally {
      if (mounted) {
        setModalState(() => _isSaving = false);
        setState(() => _isSaving = false);
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  String? _nikKkValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Wajib diisi';
    if (!RegExp(r'^\d{16}$').hasMatch(text)) return 'Harus 16 digit';
    return null;
  }

  String? _optionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  static int _compareFamilyMember(WargaInduk a, WargaInduk b) {
    final aScore = _familyScore(a.hubunganKeluarga);
    final bScore = _familyScore(b.hubunganKeluarga);
    if (aScore != bScore) return aScore.compareTo(bScore);
    return a.namaLengkap.compareTo(b.namaLengkap);
  }

  static int _familyScore(String? relation) {
    final normalized = relation?.toLowerCase() ?? '';
    if (normalized.contains('kepala')) return 0;
    if (normalized.contains('istri') || normalized.contains('suami')) return 1;
    if (normalized.contains('anak')) return 2;
    return 3;
  }

  String _suggestLogin(String name) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    return normalized.isEmpty ? 'warga' : normalized;
  }

  void _showDetail(BuildContext rootContext, WargaInduk warga) {
    showModalBottomSheet<void>(
      context: rootContext,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          Text(
            warga.namaLengkap,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _Info(label: 'NIK', value: warga.nik),
          _Info(label: 'Nomor KK', value: warga.nomorKk),
          _Info(label: 'Alamat', value: warga.alamatLengkap),
          _Info(label: 'Lahir', value: AppFormatters.date(warga.tanggalLahir)),
          if (warga.tempatLahir != null)
            _Info(label: 'Tempat lahir', value: warga.tempatLahir!),
          if (warga.pekerjaan != null)
            _Info(label: 'Pekerjaan', value: warga.pekerjaan!),
          if (warga.statusPernikahan != null)
            _Info(label: 'Status', value: warga.statusPernikahan!),
          _Info(
            label: 'Akun login',
            value: warga.profileId == null ? 'Belum tertaut' : 'Tertaut',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openLoginAccountSheet(rootContext, warga);
            },
            icon: const Icon(Icons.manage_accounts_outlined),
            label: Text(
              warga.profileId == null
                  ? 'Buat / Tautkan Akun Login'
                  : 'Edit Akun Login Warga',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLoginAccountSheet(
    BuildContext rootContext,
    WargaInduk warga,
  ) async {
    final loginController = TextEditingController(
      text: _suggestLogin(warga.namaLengkap),
    );
    final kodeController = TextEditingController();
    var isSaving = false;
    var isLoading = warga.profileId != null;
    String? profileId;

    await showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoading) {
              isLoading = false;
              ref
                  .read(wargaAccountRepositoryProvider)
                  .getForWarga(warga.id)
                  .then((account) {
                if (!context.mounted) return;
                setModalState(() {
                  profileId = account.profileId;
                  loginController.text =
                      account.email ?? account.username ?? loginController.text;
                });
              }).catchError((error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal memuat akun login: $error')),
                );
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      warga.profileId == null
                          ? 'Buat / Tautkan Akun Login'
                          : 'Edit Akun Login',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(warga.namaLengkap),
                    Text(
                      warga.profileId == null
                          ? 'Belum ada akun tertaut.'
                          : 'Profile ID: ${profileId ?? warga.profileId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: loginController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Username / email login',
                        hintText: 'Contoh: warga atau warga@email.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: kodeController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kode akses baru',
                        hintText:
                            'Kosongkan jika hanya menautkan akun yang sudah ada.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final login = loginController.text.trim();
                              if (login.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Username/email login wajib diisi.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSaving = true);
                              try {
                                final account = await ref
                                    .read(wargaAccountRepositoryProvider)
                                    .upsertForWarga(
                                      wargaId: warga.id,
                                      login: login,
                                      kodeAkses: _optionalText(kodeController),
                                    );
                                ref.invalidate(groupedWargaProvider);
                                ref.invalidate(wargaListProvider);
                                if (!context.mounted || !sheetContext.mounted) {
                                  return;
                                }
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      account.createdAuthUser
                                          ? 'Akun login warga berhasil dibuat.'
                                          : 'Akun login warga berhasil diperbarui.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Gagal menyimpan akun login: $e'),
                                  ),
                                );
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Simpan Akun Login'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    loginController.dispose();
    kodeController.dispose();
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }
}

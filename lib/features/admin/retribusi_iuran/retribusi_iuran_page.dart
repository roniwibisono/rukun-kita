import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/iuran_ipl.dart';
import '../../../data/models/iuran_ipl_edit_request.dart';
import '../../../data/models/kas_umum.dart';
import '../../../data/models/warga_induk.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';

class RetribusiIuranPage extends ConsumerStatefulWidget {
  const RetribusiIuranPage({super.key});

  @override
  ConsumerState<RetribusiIuranPage> createState() => _RetribusiIuranPageState();
}

class _RetribusiIuranPageState extends ConsumerState<RetribusiIuranPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomorRumahController = TextEditingController();
  final _nominalBulananController = TextEditingController();
  final _keteranganController = TextEditingController();

  int _tahun = DateTime.now().year;
  bool? _isActive = true;
  int _formTahun = DateTime.now().year;
  String? _selectedKepalaKeluargaId;
  final Set<int> _selectedBulan = {};
  bool _isSaving = false;
  late Future<List<IuranIpl>> _iuranFuture;

  @override
  void initState() {
    super.initState();
    _iuranFuture = _loadIuran();
  }

  @override
  void dispose() {
    _nomorRumahController.dispose();
    _nominalBulananController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentProfileProvider).valueOrNull;
    final canEditHistory = currentProfile?.role == UserRole.superAdmin;
    final canRequestEdit = currentProfile?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Retribusi / IPL')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _openIuranForm,
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Catat IPL'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton.outlined(
                  onPressed: () => _setTahun(_tahun - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Tahun $_tahun',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => _setTahun(_tahun + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment(value: true, label: Text('Aktif')),
              ButtonSegment(value: false, label: Text('Nonaktif')),
              ButtonSegment(value: null, label: Text('Semua')),
            ],
            selected: {_isActive},
            onSelectionChanged: (value) => _setStatusFilter(value.first),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading: Icon(
                  canEditHistory
                      ? Icons.admin_panel_settings_outlined
                      : Icons.lock_outline,
                ),
                title: Text(
                  canEditHistory
                      ? 'Mode Super Admin'
                      : 'Riwayat pembayaran terkunci',
                ),
                subtitle: Text(
                  canEditHistory
                      ? 'Akun ini bisa mengubah riwayat pembayaran IPL.'
                      : 'Admin biasa hanya bisa mencatat pembayaran baru. Perubahan riwayat hanya untuk SUPER_ADMIN.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (canEditHistory)
            _PendingEditRequestsPanel(onChanged: _refreshIuran)
          else if (canRequestEdit && currentProfile != null)
            _MyEditRequestsPanel(profileId: currentProfile.id),
          if (canEditHistory || canRequestEdit) const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<IuranIpl>>(
              key: ValueKey('$_tahun-$_isActive'),
              future: _iuranFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Data iuran belum bisa dimuat',
                    message: '${snapshot.error}',
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'Belum ada data IPL',
                    message:
                        'Data iuran tahunan dari Supabase akan tampil di sini.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) => _IuranCard(
                    iuran: rows[index],
                    canEditHistory: canEditHistory,
                    canRequestEdit: canRequestEdit,
                    onChanged: _refreshIuran,
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: rows.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<IuranIpl>> _loadIuran() {
    final repo = ref.read(iuranRepositoryProvider);
    final isActive = _isActive;
    if (isActive == null) return repo.getByTahun(_tahun);
    return repo.getByTahunDenganStatusWarga(tahun: _tahun, isActive: isActive);
  }

  void _refreshIuran() {
    setState(() => _iuranFuture = _loadIuran());
  }

  void _setTahun(int tahun) {
    setState(() {
      _tahun = tahun;
      _iuranFuture = _loadIuran();
    });
  }

  void _setStatusFilter(bool? value) {
    setState(() {
      _isActive = value;
      _iuranFuture = _loadIuran();
    });
  }

  Future<void> _openIuranForm() async {
    final grouped = await ref.read(groupedWargaProvider.future);
    if (!mounted) return;

    final families = grouped.entries.map((entry) {
      final members = [...entry.value]..sort(_compareFamilyMember);
      return _FamilyOption(nomorKk: entry.key, kepala: members.first);
    }).toList()
      ..sort((a, b) => a.kepala.namaLengkap.compareTo(b.kepala.namaLengkap));

    if (families.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Data warga belum ada. Isi Data Warga terlebih dahulu.'),
        ),
      );
      return;
    }

    _resetForm(families.first);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totalBayar = _selectedBulan.length * _nominalBulanan;

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
                        'Catat Pembayaran IPL',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedKepalaKeluargaId,
                        decoration: const InputDecoration(
                          labelText: 'Kepala keluarga',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                        ),
                        items: families
                            .map(
                              (family) => DropdownMenuItem(
                                value: family.kepala.id,
                                child: Text(
                                  '${family.kepala.namaLengkap} • KK ${family.nomorKk}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(
                              () => _selectedKepalaKeluargaId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Pilih kepala keluarga' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nomorRumahController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Nomor rumah',
                                hintText: 'Contoh: A-01',
                                border: OutlineInputBorder(),
                              ),
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: '$_formTahun',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tahun',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final year = int.tryParse(value ?? '');
                                if (year == null) return 'Tahun tidak valid';
                                if (year < 2000 || year > 2100) {
                                  return 'Tahun 2000-2100';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _formTahun = int.tryParse(value) ?? _formTahun;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nominalBulananController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal per bulan',
                          hintText: 'Contoh: 100000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (value) {
                          final amount = _parseAmount(value ?? '');
                          if (amount <= 0) return 'Nominal wajib lebih dari 0';
                          return null;
                        },
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bulan dibayar',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var month = 1; month <= 12; month++)
                            FilterChip(
                              label: Text(_monthLabel(month)),
                              selected: _selectedBulan.contains(month),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    _selectedBulan.add(month);
                                  } else {
                                    _selectedBulan.remove(month);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calculate_outlined),
                        title: const Text('Total bayar'),
                        subtitle: Text(
                          '${_selectedBulan.length} bulan x ${AppFormatters.rupiah(_nominalBulanan)}',
                        ),
                        trailing: Text(
                          AppFormatters.rupiah(totalBayar),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextFormField(
                        controller: _keteranganController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveIuran(sheetContext, setModalState),
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Simpan Catatan IPL'),
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

  void _resetForm(_FamilyOption initialFamily) {
    _formKey.currentState?.reset();
    _selectedKepalaKeluargaId = initialFamily.kepala.id;
    _nomorRumahController.clear();
    _nominalBulananController.clear();
    _keteranganController.clear();
    _selectedBulan.clear();
    _formTahun = _tahun;
  }

  Future<void> _saveIuran(
    BuildContext sheetContext,
    void Function(void Function()) setModalState,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBulan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu bulan pembayaran.')),
      );
      return;
    }

    final nominalBulanan = _nominalBulanan;
    final totalBayar = nominalBulanan * _selectedBulan.length;

    setModalState(() => _isSaving = true);
    setState(() => _isSaving = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      final collector = profile?.username ?? 'admin';
      final collectorRole = profile?.role.dbValue ?? 'ADMIN';
      final keterangan = _buildKeteranganAudit(
        collector: collector,
        collectorRole: collectorRole,
      );

      await ref.read(iuranRepositoryProvider).create(
            IuranIpl(
              id: '',
              kepalaKeluargaId: _selectedKepalaKeluargaId!,
              nomorRumah: _nomorRumahController.text.trim(),
              tahun: _formTahun,
              bulanBayar: _selectedBulan.toList()..sort(),
              totalBayar: totalBayar,
              keterangan: keterangan,
            ),
          );

      final kasCreated = await _createKasUmumEntry(
        totalBayar: totalBayar,
        collector: collector,
      );

      setState(() {
        _tahun = _formTahun;
        _iuranFuture = _loadIuran();
      });
      if (!mounted || !sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kasCreated
                ? 'Catatan IPL dan kas umum berhasil disimpan.'
                : 'Catatan IPL berhasil disimpan, tapi kas umum belum tercatat.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan catatan IPL: $e')),
      );
    } finally {
      if (mounted) {
        setModalState(() => _isSaving = false);
        setState(() => _isSaving = false);
      }
    }
  }

  double get _nominalBulanan =>
      _parseAmount(_nominalBulananController.text).toDouble();

  int _parseAmount(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  String? _optionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String _buildKeteranganAudit({
    required String collector,
    required String collectorRole,
  }) {
    final manualNote = _optionalText(_keteranganController);
    final audit =
        'Dicatat oleh: $collector ($collectorRole) pada ${AppFormatters.dateTime(DateTime.now())}.';
    if (manualNote == null) return audit;
    return '$manualNote\n$audit';
  }

  Future<bool> _createKasUmumEntry({
    required double totalBayar,
    required String collector,
  }) async {
    try {
      final kasRepo = ref.read(kasUmumRepositoryProvider);
      final kasRows = await kasRepo.getAll();
      final saldoSebelumnya = kasRows.isEmpty ? 0 : kasRows.last.saldoAkhir;
      final months = _selectedBulan.toList()..sort();
      final uraian =
          'Penerimaan IPL rumah ${_nomorRumahController.text.trim()} tahun $_formTahun bulan ${months.map(_monthLabel).join(', ')}. Dicatat oleh $collector.';

      await kasRepo.create(
        KasUmum(
          id: '',
          tanggalTransaksi: DateTime.now(),
          uraian: uraian,
          nomorBukti: 'IPL-${DateTime.now().millisecondsSinceEpoch}',
          debet: totalBayar,
          kredit: 0,
          saldoAkhir: saldoSebelumnya + totalBayar,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return labels[month - 1];
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
}

class _FamilyOption {
  const _FamilyOption({required this.nomorKk, required this.kepala});

  final String nomorKk;
  final WargaInduk kepala;
}

class _PendingEditRequestsPanel extends ConsumerWidget {
  const _PendingEditRequestsPanel({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<IuranIplEditRequest>>(
      future: ref.read(iuranEditRequestRepositoryProvider).getPending(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <IuranIplEditRequest>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          );
        }
        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: const Color(0xFF4A2500),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(
                Icons.pending_actions_outlined,
                color: Color(0xFFFFB000),
              ),
              title: Text(
                '${requests.length} request edit menunggu review',
                style: const TextStyle(
                  color: Color(0xFFFFB000),
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [
                for (final request in requests)
                  _PendingEditRequestTile(
                    request: request,
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingEditRequestTile extends ConsumerWidget {
  const _PendingEditRequestTile({
    required this.request,
    required this.onChanged,
  });

  final IuranIplEditRequest request;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(request.requestNote ?? 'Request edit IPL'),
          const SizedBox(height: 8),
          _DiffLine(
            label: 'Bulan bayar',
            before: request.originalBulanBayar.join(', '),
            after: request.proposedBulanBayar.join(', '),
          ),
          _DiffLine(
            label: 'Total bayar',
            before: AppFormatters.rupiah(request.originalTotalBayar),
            after: AppFormatters.rupiah(request.proposedTotalBayar),
          ),
          _DiffLine(
            label: 'Keterangan',
            before: request.originalKeterangan ?? '-',
            after: request.proposedKeterangan ?? '-',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _review(context, ref, approve: true),
                icon: const Icon(Icons.check_outlined),
                label: const Text('Setujui'),
              ),
              OutlinedButton.icon(
                onPressed: () => _review(context, ref, approve: false),
                icon: const Icon(Icons.close_outlined),
                label: const Text('Tolak'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    try {
      final profile = await ref.read(currentProfileProvider.future);
      final reviewer = profile?.username ?? 'superadmin';
      await ref.read(iuranEditRequestRepositoryProvider).review(
            requestId: request.id,
            approve: approve,
            reviewNote:
                '${approve ? 'Disetujui' : 'Ditolak'} oleh $reviewer pada ${AppFormatters.dateTime(DateTime.now())}.',
          );
      onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Request edit disetujui.' : 'Request edit ditolak.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request sudah diproses super admin lain atau gagal diproses: $e',
          ),
        ),
      );
    }
  }
}

class _MyEditRequestsPanel extends ConsumerWidget {
  const _MyEditRequestsPanel({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<IuranIplEditRequest>>(
      future: ref.read(iuranEditRequestRepositoryProvider).getMine(profileId),
      builder: (context, snapshot) {
        final requests = (snapshot.data ?? const <IuranIplEditRequest>[])
            .where((request) => request.isPending || request.reviewNote != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (requests.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: ExpansionTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text('${requests.length} status request edit'),
              children: [
                for (final request in requests.take(5))
                  ListTile(
                    title: Text('Request ${request.status}'),
                    subtitle: Text(
                      request.reviewNote ??
                          request.requestNote ??
                          'Menunggu review SUPER_ADMIN.',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: before,
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
            TextSpan(text: '  ->  $after'),
          ],
        ),
      ),
    );
  }
}

class _IuranCard extends ConsumerStatefulWidget {
  const _IuranCard({
    required this.iuran,
    required this.canEditHistory,
    required this.canRequestEdit,
    required this.onChanged,
  });

  final IuranIpl iuran;
  final bool canEditHistory;
  final bool canRequestEdit;
  final VoidCallback onChanged;

  @override
  ConsumerState<_IuranCard> createState() => _IuranCardState();
}

class _IuranCardState extends ConsumerState<_IuranCard> {
  bool _requestMode = false;
  late Set<int> _draftMonths;
  late double _draftTotalBayar;
  late String? _draftKeterangan;

  @override
  void initState() {
    super.initState();
    _resetDraft();
  }

  @override
  void didUpdateWidget(covariant _IuranCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iuran.id != widget.iuran.id) {
      _resetDraft();
    }
  }

  void _resetDraft() {
    _draftMonths = {...widget.iuran.bulanBayar};
    _draftTotalBayar = widget.iuran.totalBayar;
    _draftKeterangan = widget.iuran.keterangan;
  }

  @override
  Widget build(BuildContext context) {
    final shownMonths =
        _requestMode ? _draftMonths : widget.iuran.bulanBayar.toSet();
    final shownTotal =
        _requestMode ? _draftTotalBayar : widget.iuran.totalBayar;
    final shownKeterangan =
        _requestMode ? _draftKeterangan : widget.iuran.keterangan;
    final chipsEditable = widget.canEditHistory || _requestMode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. ${widget.iuran.nomorRumah}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Retribusi ${widget.iuran.tahun}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total bayar',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      AppFormatters.rupiah(shownTotal),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            if (_requestMode) ...[
              const SizedBox(height: 8),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_calendar_outlined),
                title: Text('Mode request edit'),
                subtitle: Text(
                  'Perubahan belum menyentuh riwayat asli sampai SUPER_ADMIN menyetujui.',
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var month = 1; month <= 12; month++)
                  Tooltip(
                    message: widget.canEditHistory
                        ? 'Ubah riwayat pembayaran'
                        : _requestMode
                            ? 'Ubah draft request'
                            : 'Riwayat hanya bisa diubah SUPER_ADMIN',
                    child: FilterChip(
                      label: Text(_iplMonthLabel(month)),
                      selected: shownMonths.contains(month),
                      onSelected: chipsEditable
                          ? (_) => _toggleMonth(context, month)
                          : null,
                    ),
                  ),
              ],
            ),
            if (shownKeterangan != null && shownKeterangan.isNotEmpty) ...[
              const SizedBox(height: 12),
              _KeteranganHistoryView(keterangan: shownKeterangan),
            ],
            if (widget.canEditHistory) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _editKeterangan(context),
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Edit Keterangan'),
              ),
            ] else if (widget.canRequestEdit && !_requestMode) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _resetDraft();
                    _requestMode = true;
                  });
                },
                icon: const Icon(Icons.request_page_outlined),
                label: const Text('Request edit'),
              ),
            ],
            if (_requestMode) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _editKeterangan(context),
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Edit Keterangan Draft'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _resetDraft();
                          _requestMode = false;
                        });
                      },
                      icon: const Icon(Icons.undo_outlined),
                      label: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _submitEditRequest(context),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Request'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMonth(BuildContext context, int month) async {
    final months =
        _requestMode ? {..._draftMonths} : {...widget.iuran.bulanBayar};
    if (months.contains(month)) {
      months.remove(month);
    } else {
      months.add(month);
    }

    final totalController = TextEditingController(
      text: (_requestMode ? _draftTotalBayar : widget.iuran.totalBayar)
          .toStringAsFixed(0),
    );
    final total = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Total bayar'),
        content: TextField(
          controller: totalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total bayar setelah perubahan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(totalController.text.replaceAll('.', '')) ?? 0,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    totalController.dispose();
    if (total == null) return;

    if (_requestMode) {
      setState(() {
        _draftMonths = months;
        _draftTotalBayar = total;
      });
      return;
    }

    try {
      await ref.read(iuranRepositoryProvider).tandaiBulanDibayar(
            iuranId: widget.iuran.id,
            bulanBayar: months.toList()..sort(),
            totalBayar: total,
          );
      widget.onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Iuran diperbarui.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui iuran: $e')));
    }
  }

  Future<void> _editKeterangan(BuildContext context) async {
    final history = _KeteranganHistory.parse(
      _requestMode ? _draftKeterangan : widget.iuran.keterangan,
    );
    final controller = TextEditingController(text: history.latestNote);

    final newNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit keterangan IPL'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Keterangan baru',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newNote == null || newNote.isEmpty) return;

    try {
      final profile = await ref.read(currentProfileProvider.future);
      final editor =
          profile?.username ?? (_requestMode ? 'admin' : 'superadmin');
      final editorRole = profile?.role.dbValue ?? 'ADMIN';
      final updated = history.appendEdit(
        newNote: newNote,
        editor: editor,
        editorRole: editorRole,
      );

      if (_requestMode) {
        setState(() => _draftKeterangan = updated);
        return;
      }

      await ref.read(iuranRepositoryProvider).updateKeterangan(
            iuranId: widget.iuran.id,
            keterangan: updated,
          );
      widget.onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan IPL diperbarui.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengedit keterangan: $e')),
      );
    }
  }

  Future<void> _submitEditRequest(BuildContext context) async {
    try {
      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null) {
        throw StateError('Profile admin belum tersedia.');
      }

      await ref.read(iuranEditRequestRepositoryProvider).create(
            IuranIplEditRequest(
              id: '',
              iuranId: widget.iuran.id,
              requestedBy: profile.id,
              status: 'PENDING',
              originalBulanBayar: widget.iuran.bulanBayar,
              originalTotalBayar: widget.iuran.totalBayar,
              originalKeterangan: widget.iuran.keterangan,
              proposedBulanBayar: _draftMonths.toList()..sort(),
              proposedTotalBayar: _draftTotalBayar,
              proposedKeterangan: _draftKeterangan,
              requestNote:
                  'Diminta oleh: ${profile.username} (${profile.role.dbValue}) pada ${AppFormatters.dateTime(DateTime.now())}.',
              createdAt: DateTime.now(),
            ),
          );

      setState(() {
        _resetDraft();
        _requestMode = false;
      });
      widget.onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request edit dikirim ke SUPER_ADMIN.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim request edit: $e')),
      );
    }
  }
}

String _iplMonthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return labels[month - 1];
}

class _KeteranganHistoryView extends StatelessWidget {
  const _KeteranganHistoryView({required this.keterangan});

  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final history = _KeteranganHistory.parse(keterangan);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.entries.isNotEmpty) ...[
          Text('Keterangan', style: textTheme.labelLarge),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                for (var index = 0;
                    index < history.entries.length;
                    index++) ...[
                  if (index > 0) const TextSpan(text: '\n'),
                  if (history.entries[index].label != null)
                    TextSpan(
                      text: '${history.entries[index].label} ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  TextSpan(
                    text: history.entries[index].text,
                    style: TextStyle(
                      decoration: index == history.entries.length - 1
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (history.createdByLine != null)
          Text(history.createdByLine!, style: textTheme.bodySmall),
        for (final editedBy in history.editedByLines)
          Text(editedBy, style: textTheme.bodySmall),
      ],
    );
  }
}

class _KeteranganHistory {
  const _KeteranganHistory({
    required this.entries,
    required this.createdByLine,
    required this.editedByLines,
  });

  final List<_KeteranganEntry> entries;
  final String? createdByLine;
  final List<String> editedByLines;

  String get latestNote => entries.isEmpty ? '' : entries.last.text;

  static final _markerPattern =
      RegExp(r'^\[(original|edited(?: \d+)?)\]\s*(.*)$');

  static _KeteranganHistory parse(String? rawValue) {
    final raw = rawValue?.trim() ?? '';
    if (raw.isEmpty) {
      return const _KeteranganHistory(
        entries: [],
        createdByLine: null,
        editedByLines: [],
      );
    }

    final lines = raw.split('\n');
    final bodyLines = <String>[];
    String? createdByLine;
    final editedByLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('Dicatat oleh:')) {
        createdByLine = trimmed;
      } else if (trimmed.startsWith('Diedit oleh:')) {
        editedByLines.add(trimmed);
      } else {
        bodyLines.add(line);
      }
    }

    final entries = _parseEntries(bodyLines.join('\n').trim());
    return _KeteranganHistory(
      entries: entries,
      createdByLine: createdByLine,
      editedByLines: editedByLines,
    );
  }

  static List<_KeteranganEntry> _parseEntries(String body) {
    if (body.isEmpty) return const [];

    final entries = <_KeteranganEntry>[];
    final buffer = StringBuffer();
    String? currentLabel;

    void flush() {
      final text = buffer.toString().trim();
      if (text.isEmpty) return;
      entries.add(_KeteranganEntry(label: currentLabel, text: text));
      buffer.clear();
    }

    for (final line in body.split('\n')) {
      final marker = _markerPattern.firstMatch(line.trim());
      if (marker != null) {
        flush();
        final markerText = marker.group(1)!;
        currentLabel = markerText == 'original' ? null : '[$markerText]';
        buffer.write(marker.group(2) ?? '');
      } else {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(line);
      }
    }
    flush();

    if (entries.isEmpty) {
      return [_KeteranganEntry(label: null, text: body)];
    }
    return entries;
  }

  String appendEdit({
    required String newNote,
    required String editor,
    required String editorRole,
  }) {
    final nextEditNumber =
        entries.where((entry) => entry.label != null).length + 1;
    final nextLabel =
        nextEditNumber == 1 ? '[edited]' : '[edited $nextEditNumber]';
    final body = <String>[];

    if (entries.isEmpty) {
      body.add('$nextLabel $newNote');
    } else {
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        final marker = entry.label == null ? '[original]' : entry.label!;
        body.add('$marker ${entry.text}');
      }
      body.add('$nextLabel $newNote');
    }

    final metadata = <String>[
      if (createdByLine != null) createdByLine!,
      ...editedByLines,
      'Diedit oleh: $editor ($editorRole) pada ${AppFormatters.dateTime(DateTime.now())}.',
    ];

    return [...body, ...metadata].join('\n');
  }
}

class _KeteranganEntry {
  const _KeteranganEntry({required this.label, required this.text});

  final String? label;
  final String text;
}

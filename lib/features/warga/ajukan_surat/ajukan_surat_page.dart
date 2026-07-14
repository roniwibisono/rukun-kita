import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/warga_induk.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_data_providers.dart';
import '../../shared/widgets/empty_state.dart';

class AjukanSuratPage extends ConsumerStatefulWidget {
  const AjukanSuratPage({super.key});

  @override
  ConsumerState<AjukanSuratPage> createState() => _AjukanSuratPageState();
}

class _AjukanSuratPageState extends ConsumerState<AjukanSuratPage> {
  final _formKey = GlobalKey<FormState>();
  final _catatanController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};

  String? _selectedWargaId;
  JenisKeperluanSurat _selectedJenis = JenisKeperluanSurat.ktpBaruHilang;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _catatanController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(WargaInduk selectedWarga) async {
    if (!_formKey.currentState!.validate() || _selectedWargaId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(ticketRepositoryProvider).create(
            wargaId: _selectedWargaId!,
            jenisKeperluan: _selectedJenis.label,
            detailKeterangan: _buildDetailKeterangan(selectedWarga),
          );
      ref.invalidate(wargaTicketStreamProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan surat berhasil dikirim.')),
      );
      context.go(AppRoutes.wargaRiwayatPermintaan);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim pengajuan: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  TextEditingController _controllerFor(String key) {
    return _fieldControllers.putIfAbsent(key, TextEditingController.new);
  }

  String _buildDetailKeterangan(WargaInduk warga) {
    final lines = <String>[
      'Arsip Surat Pengantar Warga',
      'Nama Warga: ${warga.namaLengkap}',
      'NIK: ${warga.nik}',
      'Nomor KK: ${warga.nomorKk}',
      'Alamat: ${warga.alamatLengkap}',
      'Keperluan: ${_selectedJenis.label}',
    ];

    for (final field in _fieldsFor(_selectedJenis)) {
      final value = _controllerFor(field.key).text.trim();
      if (value.isNotEmpty) lines.add('${field.label}: $value');
    }

    final catatan = _catatanController.text.trim();
    if (catatan.isNotEmpty) lines.add('Catatan tambahan: $catatan');

    lines.add('Tanggal ambil berkas: dipilih warga setelah berkas selesai.');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final wargaAsync = ref.watch(wargaListProvider);
    final currentWarga = ref.watch(currentWargaProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Surat')),
      body: wargaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Data warga belum bisa dimuat',
          message: '$error',
        ),
        data: (wargaList) {
          if (wargaList.isEmpty) {
            return const EmptyState(
              icon: Icons.person_search_outlined,
              title: 'Data keluarga belum tertaut',
              message:
                  'Hubungi pengurus RT agar akun ini ditautkan ke data warga.',
            );
          }

          _selectedWargaId ??= currentWarga?.id ?? wargaList.first.id;
          final selectedWarga = wargaList.firstWhere(
            (warga) => warga.id == _selectedWargaId,
            orElse: () => wargaList.first,
          );

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DropdownButtonFormField<JenisKeperluanSurat>(
                        initialValue: _selectedJenis,
                        decoration: const InputDecoration(
                          labelText: 'Jenis surat',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        items: JenisKeperluanSurat.values
                            .map(
                              (jenis) => DropdownMenuItem(
                                value: jenis,
                                child: Text(jenis.label),
                              ),
                            )
                            .toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (value) => setState(() {
                                  if (value != null) _selectedJenis = value;
                                }),
                      ),
                      const SizedBox(height: 12),
                      _SuratInfoCard(jenis: _selectedJenis),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedWargaId),
                        initialValue: _selectedWargaId,
                        decoration: const InputDecoration(
                          labelText: 'Pemohon',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: wargaList
                            .map(
                              (warga) => DropdownMenuItem(
                                value: warga.id,
                                child: Text(warga.namaLengkap),
                              ),
                            )
                            .toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (value) =>
                                setState(() => _selectedWargaId = value),
                        validator: (value) =>
                            value == null ? 'Pilih pemohon' : null,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedWarga.namaLengkap,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text('NIK ${selectedWarga.nik}'),
                              Text('KK ${selectedWarga.nomorKk}'),
                              Text('Alamat ${selectedWarga.alamatLengkap}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final field in _fieldsFor(_selectedJenis)) ...[
                        TextFormField(
                          controller: _controllerFor(field.key),
                          maxLines: field.maxLines,
                          minLines: field.maxLines > 1 ? 2 : 1,
                          decoration: InputDecoration(
                            labelText: field.required
                                ? field.label
                                : '${field.label} (opsional)',
                            hintText: field.hint,
                            alignLabelWithHint: field.maxLines > 1,
                          ),
                          validator: (value) {
                            if (!field.required) return null;
                            if (value == null || value.trim().isEmpty) {
                              return '${field.label} wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 4,
                        minLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan tambahan (opsional)',
                          hintText:
                              'Contoh: dokumen pendukung, kondisi khusus, atau pesan untuk pengurus RT.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Data pemohon otomatis dari buku induk: nama, NIK, KK, dan alamat. Tanggal ambil berkas dipilih setelah status berkas selesai.',
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed:
                        _isSubmitting ? null : () => _submit(selectedWarga),
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Kirim permintaan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

List<_SuratField> _fieldsFor(JenisKeperluanSurat jenis) {
  return switch (jenis) {
    JenisKeperluanSurat.ktpBaruHilang => const [
        _SuratField(
          key: 'kondisi_dokumen',
          label: 'Kondisi dokumen',
          hint: 'Contoh: KTP baru, hilang, rusak, atau perubahan data',
        ),
        _SuratField(
          key: 'tujuan_pengurusan',
          label: 'Tujuan pengurusan',
          hint: 'Contoh: Kelurahan/Dukcapil/Kecamatan',
          required: false,
        ),
      ],
    JenisKeperluanSurat.kartuKeluarga => const [
        _SuratField(
          key: 'alasan_pengurusan',
          label: 'Alasan pengurusan KK',
          hint: 'Contoh: KK baru, pecah KK, perubahan anggota, KK hilang',
        ),
        _SuratField(
          key: 'anggota_terdampak',
          label: 'Nama anggota yang terkait',
          hint: 'Isi nama anggota keluarga jika ada',
          required: false,
          maxLines: 2,
        ),
      ],
    JenisKeperluanSurat.aktaLahir => const [
        _SuratField(
          key: 'nama_anak',
          label: 'Nama anak/bayi',
          hint: 'Nama yang akan dibuatkan akta kelahiran',
        ),
        _SuratField(
          key: 'tanggal_lahir_anak',
          label: 'Tanggal lahir anak',
          hint: 'Contoh: 14 Juli 2026',
        ),
        _SuratField(
          key: 'nama_orang_tua',
          label: 'Nama orang tua',
          hint: 'Nama ayah dan ibu',
          maxLines: 2,
        ),
      ],
    JenisKeperluanSurat.aktaKematian => const [
        _SuratField(
          key: 'nama_almarhum',
          label: 'Nama almarhum/almarhumah',
        ),
        _SuratField(
          key: 'tanggal_wafat',
          label: 'Tanggal wafat',
          hint: 'Contoh: 14 Juli 2026',
        ),
        _SuratField(
          key: 'hubungan_pemohon',
          label: 'Hubungan dengan pemohon',
          hint: 'Contoh: orang tua, pasangan, anak',
        ),
      ],
    JenisKeperluanSurat.numpangNikah => const [
        _SuratField(
          key: 'nama_calon_pasangan',
          label: 'Nama calon pasangan',
        ),
        _SuratField(
          key: 'kua_tujuan',
          label: 'KUA/Kelurahan tujuan',
          hint: 'Lokasi pendaftaran nikah',
        ),
        _SuratField(
          key: 'tanggal_rencana_nikah',
          label: 'Tanggal rencana nikah',
          hint: 'Isi jika sudah ada',
          required: false,
        ),
      ],
    JenisKeperluanSurat.sktm => const [
        _SuratField(
          key: 'tujuan_bantuan',
          label: 'Tujuan SKTM/bantuan',
          hint: 'Contoh: KJP, BPJS, bantuan kesehatan, bantuan pendidikan',
        ),
        _SuratField(
          key: 'instansi_tujuan',
          label: 'Instansi tujuan',
          hint: 'Contoh: sekolah, rumah sakit, kelurahan',
          required: false,
        ),
      ],
    JenisKeperluanSurat.domisili => const [
        _SuratField(
          key: 'alamat_domisili',
          label: 'Alamat domisili',
          hint: 'Alamat tempat tinggal saat ini',
          maxLines: 2,
        ),
        _SuratField(
          key: 'sejak_tanggal',
          label: 'Menetap sejak',
          hint: 'Contoh: Januari 2024',
          required: false,
        ),
        _SuratField(
          key: 'tujuan_domisili',
          label: 'Tujuan surat domisili',
          hint: 'Contoh: administrasi sekolah, bank, pekerjaan',
        ),
      ],
    JenisKeperluanSurat.pindah => const [
        _SuratField(
          key: 'alamat_tujuan',
          label: 'Alamat tujuan pindah',
          maxLines: 2,
        ),
        _SuratField(
          key: 'alasan_pindah',
          label: 'Alasan pindah',
          hint: 'Contoh: pekerjaan, keluarga, kontrak habis',
        ),
        _SuratField(
          key: 'jumlah_anggota_pindah',
          label: 'Jumlah anggota yang pindah',
          hint: 'Isi angka atau nama anggota yang ikut pindah',
          required: false,
        ),
      ],
  };
}

String _suratDescription(JenisKeperluanSurat jenis) {
  return switch (jenis) {
    JenisKeperluanSurat.ktpBaruHilang =>
      'Pengantar awal untuk pembuatan, kehilangan, kerusakan, atau perubahan data KTP.',
    JenisKeperluanSurat.kartuKeluarga =>
      'Pengantar untuk pembuatan/perbaikan KK, perubahan anggota keluarga, atau KK hilang.',
    JenisKeperluanSurat.aktaLahir =>
      'Pengantar untuk pengurusan akta kelahiran di kelurahan/dukcapil.',
    JenisKeperluanSurat.aktaKematian =>
      'Pengantar untuk pengurusan akta kematian dan administrasi terkait.',
    JenisKeperluanSurat.numpangNikah =>
      'Pengantar numpang nikah atau kelengkapan pendaftaran nikah ke KUA.',
    JenisKeperluanSurat.sktm =>
      'Pengantar SKTM untuk KJP, BPJS, bantuan kesehatan, pendidikan, atau bantuan sosial.',
    JenisKeperluanSurat.domisili =>
      'Surat keterangan domisili untuk kebutuhan administrasi warga.',
    JenisKeperluanSurat.pindah =>
      'Surat keterangan pindah antar wilayah atau pindah keluar/masuk lingkungan.',
  };
}

class _SuratInfoCard extends StatelessWidget {
  const _SuratInfoCard({required this.jenis});

  final JenisKeperluanSurat jenis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(_suratDescription(jenis))),
          ],
        ),
      ),
    );
  }
}

class _SuratField {
  const _SuratField({
    required this.key,
    required this.label,
    this.hint,
    this.required = true,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
}

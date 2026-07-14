/// Nama tabel persis seperti di schema `public` — dipakai di semua repository
/// agar tidak ada typo string literal tersebar di banyak file.
class TableNames {
  TableNames._();

  static const profiles = 'profiles';
  static const tenants = 'tenants';
  static const tenantMemberships = 'tenant_memberships';

  static const wargaInduk = 'warga_induk';
  static const wargaMutasi = 'warga_mutasi';
  static const wargaSementara = 'warga_sementara';

  static const ticketRequests = 'ticket_requests';
  static const appNotifications = 'app_notifications';

  static const suratMasuk = 'surat_masuk';
  static const suratKeluar = 'surat_keluar';
  static const bukuEkspedisi = 'buku_ekspedisi';

  static const kasUmum = 'kas_umum';
  static const iuranIpl = 'iuran_ipl';
  static const iuranIplEditRequests = 'iuran_ipl_edit_requests';

  static const bukuTamu = 'buku_tamu';
  static const inventarisRt = 'inventaris_rt';

  static const notulenRapat = 'notulen_rapat';
  static const presensiRapat = 'presensi_rapat';

  static const pengurusRt = 'pengurus_rt';
}

/// Nama RPC function yang sudah ada di DB.
class RpcNames {
  RpcNames._();

  static const linkWargaProfile = 'link_warga_profile';
  static const reviewIuranIplEditRequest = 'review_iuran_ipl_edit_request';
}

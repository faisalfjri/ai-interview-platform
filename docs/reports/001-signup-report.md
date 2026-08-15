# Laporan Implementasi Fitur

## Tautan Pull Request

GitHub Pull Request: [Link PR di GitHub](https://github.com/rakamindev/ai-interview-platform/pull/XX)

## Ringkasan Implementasi

Implementasi ini berfokus pada **penambahan fitur signup dan perbaikan sistem autentikasi** pada platform AI Interview.

Pekerjaan bersifat **backend-heavy**, dengan fokus utama pada Rails API, validasi model, JWT authentication, dan test coverage. Perubahan pada frontend bersifat minor, terutama untuk menyesuaikan tipe role dan memperbaiki mekanisme Axios interceptor.

Secara keseluruhan, implementasi mencakup:

* Penambahan endpoint `POST /api/v1/signup`
* Penambahan role `assessor` pada model `User`
* Validasi email dan password
* Validasi role saat registrasi
* Penerbitan JWT setelah signup
* Perbaikan login agar dapat digunakan oleh seluruh role
* Perbaikan Axios interceptor untuk mencegah redirect loop
* Penambahan **19 test case** yang mencakup signup dan login

---

# 1. Fitur Signup & Perbaikan Autentikasi

**Status: ✅ Selesai**

## Mengapa Fitur Ini Penting?

### Dari Sisi Bisnis

Sebelumnya, platform belum menyediakan mekanisme signup mandiri. Akibatnya, assessor baru harus dibuatkan akun secara manual oleh admin.

Hal ini menjadi bottleneck ketika jumlah pengguna bertambah. Dengan adanya signup, proses onboarding dapat dilakukan secara mandiri sehingga:

* mengurangi ketergantungan terhadap admin atau tim IT,
* mempercepat onboarding assessor,
* mendukung pertumbuhan jumlah pengguna,
* dan mengurangi proses administratif yang tidak perlu.

Dalam konteks platform assessment yang ditujukan untuk penggunaan dalam skala besar, self-service onboarding juga menjadi fondasi penting untuk pengembangan fitur seperti invitation, organization management, dan automated onboarding di tahap berikutnya.

### Dari Sisi Pengguna

**Assessor** membutuhkan akses yang cepat agar dapat membuat dan menjalankan assessment tanpa menunggu pembuatan akun secara manual.

**Recruiter** dapat lebih mudah menambahkan atau mengarahkan assessor baru ke platform tanpa bergantung pada proses administratif internal.

**Hiring Manager** juga mendapatkan manfaat secara tidak langsung karena proses onboarding assessor yang lebih cepat dapat mengurangi hambatan dalam assessment dan mempercepat recruitment workflow.

### Dari Sisi Kandidat dan Auditability

Sistem autentikasi yang lebih konsisten memberikan identitas yang jelas terhadap pengguna yang melakukan aktivitas assessment.

Hal ini penting untuk kebutuhan:

* audit trail,
* accountability,
* pengelolaan akses,
* dan penerapan prinsip perlindungan data sesuai konteks UU PDP.

Dengan setiap aktivitas terasosiasi dengan user yang terautentikasi, sistem memiliki dasar yang lebih baik untuk melakukan tracking terhadap siapa yang mengakses atau menjalankan proses assessment.

> Catatan: fitur autentikasi saja belum berarti platform sepenuhnya compliant terhadap UU PDP. Compliance tetap membutuhkan kontrol tambahan seperti consent, data retention, access control, audit logging, dan mekanisme pengelolaan data pribadi.

---

## Masalah yang Ditemukan

Implementasi dilakukan untuk menyelesaikan beberapa masalah berikut:

| Priority | Masalah                                                      |
| -------- | ------------------------------------------------------------ |
| P0       | Endpoint signup belum tersedia di backend                    |
| P0       | Role pada proses signup tidak konsisten dengan authorization |
| P1       | Login sebelumnya terbatas pada role tertentu                 |
| P1       | Axios interceptor berpotensi menyebabkan redirect loop       |

Masalah tersebut berdampak langsung terhadap kemampuan pengguna baru untuk masuk ke platform dan menjalankan workflow assessment.

---

## Solusi yang Diimplementasikan

Untuk mengatasi masalah tersebut, dilakukan beberapa perubahan:

1. Menambahkan endpoint `POST /api/v1/signup`
2. Menambahkan role `assessor` pada model `User`
3. Menambahkan validasi email, password, dan role
4. Menghasilkan JWT token setelah signup berhasil
5. Memperbaiki login agar dapat digunakan oleh seluruh role yang valid
6. Memperbaiki Axios interceptor agar response `401` tidak menyebabkan redirect loop
7. Menyesuaikan tipe role pada frontend dengan role yang tersedia di backend

---

## File yang Diubah

| File                                                      | Perubahan                                         |
| --------------------------------------------------------- | ------------------------------------------------- |
| `api/config/routes.rb`                                    | Menambahkan route signup                          |
| `api/app/controllers/api/v1/authentication_controller.rb` | Menambahkan action signup dan proses autentikasi  |
| `api/app/models/user.rb`                                  | Menambahkan role `assessor` dan validasi user     |
| `web/src/services/auth.ts`                                | Menyesuaikan TypeScript type untuk role           |
| `web/src/pages/auth/SignupPage.tsx`                       | Menetapkan `assessor` sebagai default role signup |
| `web/src/services/api.ts`                                 | Memperbaiki Axios interceptor dan handling `401`  |

---

# 2. Validasi dan Test Coverage

Implementasi backend dilengkapi dengan **19 test case**, terdiri dari:

* **11 test case untuk signup**
* **8 test case untuk login**

Test mencakup happy path maupun beberapa kondisi invalid untuk memastikan behavior API konsisten.

### Validasi yang Dicakup

* Email wajib diisi
* Format email harus valid
* Email harus unik
* Uniqueness email bersifat case-insensitive
* Password wajib diisi
* Password minimal 6 karakter
* Role harus merupakan role yang valid
* Signup berhasil menghasilkan JWT token
* Login berhasil menggunakan credential yang valid
* Login gagal ketika credential tidak valid
* JWT yang expired menghasilkan response `401 Unauthorized`

---

# 3. Kriteria Penerimaan

| # | Kriteria                                                                    | Status |
| - | --------------------------------------------------------------------------- | ------ |
| 1 | Endpoint `POST /api/v1/signup` tersedia dan dapat digunakan                 | ✅      |
| 2 | Email memiliki validasi format dan uniqueness case-insensitive              | ✅      |
| 3 | Password memiliki minimum 6 karakter                                        | ✅      |
| 4 | Role hanya menerima `admin`, `assessor`, atau `user`                        | ✅      |
| 5 | Signup berhasil mengembalikan JWT token                                     | ✅      |
| 6 | User dapat login setelah signup                                             | ✅      |
| 7 | User dengan role yang valid dapat mengakses assessment sesuai authorization | ✅      |

---

# 4. Edge Cases

Beberapa kondisi yang secara eksplisit ditangani:

### Email Duplikat

Registrasi dengan email yang sudah terdaftar akan ditolak melalui validasi uniqueness.

Validasi juga mempertimbangkan perbedaan huruf besar dan kecil, sehingga email seperti:

```text
User@example.com
user@example.com
```

tidak dianggap sebagai dua akun berbeda.

### Password Tidak Valid

Signup ditolak apabila:

* password kosong,
* password kurang dari 6 karakter,
* atau tidak memenuhi validasi model yang telah ditentukan.

### Role Tidak Valid

Request dengan role di luar role yang diperbolehkan akan ditolak oleh backend.

### JWT Expired

Request menggunakan JWT yang sudah kadaluwarsa akan menghasilkan:

```text
401 Unauthorized
```

Frontend kemudian menangani kondisi tersebut melalui interceptor tanpa menyebabkan redirect loop.

---

# 5. Trade-off Implementasi

Terdapat beberapa opsi desain untuk fitur signup:

| Opsi                        | Kelebihan                                       | Kekurangan                                    | Keputusan |
| --------------------------- | ----------------------------------------------- | --------------------------------------------- | --------- |
| Signup sederhana            | Implementasi cepat, sederhana, mudah dipelihara | Belum melakukan verifikasi email              | ✅ Dipilih |
| Signup + email verification | Keamanan dan validitas email lebih baik         | Membutuhkan email service dan flow tambahan   | Belum     |
| Signup + OAuth              | UX lebih baik dan mengurangi friction           | Memerlukan dependency dan integrasi eksternal | Belum     |

Untuk scope implementasi saat ini, **signup sederhana dipilih** karena memberikan value utama dengan kompleksitas yang relatif rendah.

Email verification dan OAuth dapat ditambahkan sebagai enhancement pada tahap berikutnya.

---

# 6. Verifikasi dan Koreksi Implementasi

Selama proses implementasi, terdapat satu temuan dari AI-generated implementation yang perlu dikoreksi.

AI menghasilkan **response envelope** yang tidak sesuai dengan ekspektasi frontend.

Masalah tersebut ditemukan setelah melakukan pengecekan terhadap kode frontend dan alur konsumsi API. Response kemudian disesuaikan agar contract antara backend dan frontend konsisten.

Hal ini menunjukkan bahwa implementasi tidak hanya bergantung pada output AI, tetapi tetap melalui proses:

1. membaca existing code,
2. memeriksa API contract,
3. mencocokkan response dengan consumer di frontend,
4. menjalankan test,
5. dan melakukan koreksi terhadap hasil yang tidak sesuai.

---

# 7. Constraint dan Risiko Teknis

Implementasi berjalan dalam arsitektur yang memiliki beberapa constraint penting.

### Multi-Tenant Architecture

Platform menggunakan PostgreSQL dengan pemisahan schema:

* `public` untuk data organization
* `ai_interview` untuk data aplikasi

Karena itu, proses authentication tidak hanya bergantung pada validasi JWT. Request juga harus dapat menentukan tenant atau organization context yang benar.

### Dependency terhadap `rakamin-api`

Platform memiliki ketergantungan terhadap `rakamin-api`, termasuk penggunaan:

* shared database,
* dan JWT secret yang sama.

Perubahan pada authentication perlu mempertimbangkan compatibility dengan sistem yang sudah menggunakan JWT tersebut.

### Tenant Resolution

Tenant resolution merupakan bagian penting dari request lifecycle.

Jika tenant tidak dapat di-resolve dengan benar, request dapat ditolak dengan:

```text
403 Forbidden
```

Artinya, kegagalan request tidak selalu menunjukkan bahwa JWT tidak valid. Masalah juga dapat berasal dari kegagalan menentukan organization/tenant context.

---

# 8. Catatan untuk Production

Fitur sudah memenuhi kebutuhan scope saat ini, tetapi masih terdapat beberapa enhancement yang disarankan sebelum digunakan pada skala production yang lebih besar:

* **Email verification** untuk memastikan email benar-benar dimiliki oleh user
* **Rate limiting** khusus pada endpoint signup dan login untuk mengurangi risiko abuse/brute-force
* **Organization assignment** agar user baru dapat langsung dikaitkan dengan organization yang sesuai
* **Audit logging** untuk aktivitas authentication dan authorization
* **Stronger password policy** apabila kebutuhan security meningkat
* **Monitoring dan alerting** untuk mendeteksi pola signup/login yang tidak normal

Item tersebut tidak menjadi blocker untuk scope implementasi saat ini, tetapi penting sebagai bagian dari hardening production.

---

# 9. Kesimpulan

Implementasi berhasil menyelesaikan gap utama pada authentication flow, khususnya ketiadaan signup endpoint dan ketidakkonsistenan role antara backend dan frontend.

Dengan penambahan signup, role `assessor`, JWT setelah registrasi, validasi input, serta perbaikan login dan Axios interceptor, authentication flow sekarang lebih siap digunakan untuk proses onboarding secara mandiri.

Dari sisi kualitas, implementasi didukung oleh **19 test case** yang mencakup signup dan login, serta telah mempertimbangkan beberapa edge case penting seperti email duplikat, password tidak valid, role tidak valid, dan JWT expired.

Untuk tahap selanjutnya, prioritas yang paling relevan adalah **email verification, rate limiting, organization assignment, dan audit logging** sebagai bagian dari production hardening.

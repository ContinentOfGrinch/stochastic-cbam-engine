# Resmî Kaynak Belgeler

Bu klasördeki belgeler **AB'nin resmî yayınlarıdır ve değiştirilmemiştir.**
`data/` altındaki işlenmiş veri tamamen buradan türetilir.

Avrupa Komisyonu belgeleri, Komisyon'un yeniden kullanım kararı kapsamında
kaynak belirtilerek serbestçe kullanılabilir. Bu klasördeki belgelerin telif
durumu, projenin AGPLv3 kod lisansından **ayrıdır** — kod AGPLv3, belgeler
AB yeniden kullanım koşullarına tabidir.

> **Çelişki halinde resmî metin geçerlidir.** `data/` altındaki değerler bu
> belgelerden elle aktarılmıştır. Bir uyuşmazlık görürsen resmî metni esas al
> ve lütfen hata bildir.

---

## İndirilecek belgeler

Her belge indirildikten sonra aşağıdaki tabloyu doldur. SHA256 almak için:

```bash
# PowerShell
Get-FileHash -Algorithm SHA256 data-raw/mevzuat/<dosya>

# Linux / macOS
sha256sum data-raw/mevzuat/<dosya>
```

Belgeler **EUR-Lex**'ten indirilir: <https://eur-lex.europa.eu>

CELEX numarasıyla doğrudan erişim:
`https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:<CELEX>`

> **Her zaman KONSOLİDE (consolidated) sürümü indir.** Orijinal Resmî Gazete
> metni sonraki tadilleri içermez; CBAM Tüzüğü 2025 sadeleştirme paketiyle
> değiştirildi. EUR-Lex'te belge sayfasında sol menüden *"All consolidated
> versions"* seçilir. Konsolide CELEX `0` ile başlar: `02023R0956-YYYYMMDD`.
>
> Aşağıdaki CELEX numaraları başlangıç noktasıdır; indirmeden önce EUR-Lex'te
> arayıp **yürürlükteki en güncel sürüm olduğunu teyit et.**

| # | Belge kimliği | CELEX (başlangıç) | Ne için gerekli | Dosya | Tarih | SHA256 | Durum |
|---|---|---|---|---|---|---|---|
| 1 | `REG-2023-956` | `32023R0956` → konsolide `02023R0956` | **CBAM Tüzüğü.** Ek I (kapsamdaki ürünler + CN kodları + dolaylı emisyon kapsamı), phase-in takvimi, sertifika hesabı, menşede ödenen karbon, de minimis | — | — | — | ⬜ |
| 2 | `CIR-BENCHMARK` | AB ETS ücretsiz tahsisat benchmark değerleri — **2026–2030 dönemi** | Ürün bazında benchmark (D7) | — | — | — | ⬜ |
| 3 | `CIR-2023-1773` | `32023R1773` | Geçiş dönemi raporlama tüzüğü + ekleri; Komisyon'un varsayılan emisyon değerleri | — | — | — | ⬜ |
| 4 | `DIR-2003-87` | `02003L0087` (konsolide) | AB ETS Direktifi — benchmark tanımı ve ücretsiz tahsisatın kademeli kaldırılması | — | — | — | ⬜ |
| 5 | `IR-KESIN-DONEM` | 2025–2026 uygulama tüzükleri | Kesin dönem (2026+) hesap kuralları ve varsayılan değerler | — | — | — | ⬜ |

**2 ve 5 numara için CELEX veremiyorum** — benchmark tüzükleri dönem dönem
yenileniyor ve kesin dönem uygulama tüzükleri bu projenin bilgi kesitinden
sonra yayımlanmış olabilir. EUR-Lex'te arayarak yürürlüktekini bul.

### Öncelik sırası

**1 numara her şeyden önce gelir** — tek başına D1, D2, D3, D4, D5, D6, D8
maddelerinin çoğunu kapatır.

İçindeki en kritik bilgi: *hangi ürünlerde dolaylı (elektrik) emisyonlar CBAM
yükümlülüğüne giriyor?* (bkz. `MEVZUAT_DOGRULAMA.md` → **D6**)

Bunun pratik karşılığı, 15.000 tonluk bir alüminyum ihracatçısı için 2034'te
**136 EUR/ton ile 608 EUR/ton arasındaki fark** — yılda yaklaşık 7 milyon EUR.
`data/urunler.csv` içindeki `dolayli_kapsamda` sütunu şu an doğrulanmamış bir
varsayım taşıyor ve bu belge gelene kadar öyle kalacak.

### Dil

EUR-Lex belgeleri tüm AB dillerinde yayımlanır; Türkçe AB resmî dili olmadığı
için Türkçe sürüm yoktur. **İngilizce (EN) sürümü esas al** — CN kodları ve
teknik terimler için en az yoruma açık olan odur.

---

## Belge nasıl eklenir

1. Belgeyi bu klasöre indir, **dosya adını değiştirme, içeriğine dokunma**
2. SHA256'sını al, yukarıdaki tabloya işle
3. `data/` altındaki ilgili CSV'ye değerleri aktar — `kaynak_belge` sütununa
   belge kimliğini, `kaynak_yeri` sütununa madde/ek/satır referansını yaz
4. O satırın `durum` sütununu `dogrulandi` yap
5. `Rscript tests/test_engine.R` çalıştır — veri bütünlüğü testleri geçmeli

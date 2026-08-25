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

## İndirilmiş belgeler ✅

| Belge kimliği | Dosya | Tarih | SHA256 |
|---|---|---|---|
| `GUIDANCE-3` | `Guidance-3-CBAM-methods-calculation-embedded-emissions.pdf` | 2026-08-23 | `162ED275717671F05B88355A9B161726E7A1396F6CE1FC8F72A2F287D204A0D6` |
| `GUIDANCE-4` | `Guidance-4-CBAM-free-allocation-adjustment.pdf` | 2026-08-23 | `6854641617E77C18F7C752283E56871B180CB8790806CFDE9CBD6EF6F62F8698` |
| `CBAM-BENCHMARKS-2026-02-06` | `CBAM-Benchmarks-20260206.xlsx` | 2026-08-23 | `B79108B025E697822F0F59DE477FA68066C1C05C228FAE2270CD230AF84E8A7B` |
| `CBAM-DEFAULT-VALUES-2026-08-06` | `CBAM-Default-Values-20260806.xlsx` | 2026-08-25 | `900583811C7E1194799EB9BDBAD2D6D7E1100F5A7D80A664C1584A8FCE6F9F35` |

Doğrulamak için:

```powershell
Get-FileHash -Algorithm SHA256 data-raw/mevzuat/<dosya>
```

Avrupa Komisyonu, DG TAXUD, **14 Ağustos 2026** — kesin dönem için ilk yayın.
Kaynak: <https://taxation-customs.ec.europa.eu/carbon-border-adjustment-mechanism/cbam-legislation-and-guidance_en>

> Bu rehberler **hukuken bağlayıcı değildir**; açıklayıcı niteliktedir. Resmî
> metin çelişki halinde üstündür. Yine de D1, D2, D5, D6 maddelerini
> kapatmaya yetti — her biri altındaki yasal işleme atıf vererek.

## İndirilecek belgeler ⬜

| # | Belge kimliği | Erişim | Ne için gerekli | Durum |
|---|---|---|---|---|
| 1 | `REG-2023-956` | `data.europa.eu/eli/reg/2023/956/2025-10-20` (konsolide) | Ek I (CN kodları, D8), Ek II (dolaylı kapsam listesi), Md. 9 (menşede ödenen, D3), de minimis (D4) | ⬜ |
| 2 | `CIR-2025-2620` | `data.europa.eu/eli/reg_impl/2025/2620/oj` | **Free Allocation Adjustment Act.** Ek nokta 5 Column A = benchmark değerleri (D7) | ⬜ |
| 4 | `CIR-2025-2547` | `data.europa.eu/eli/reg_impl/2025/2547/oj` | **Methodology Act.** Md. 3(2) dolaylı emisyon kuralı, fonksiyonel birimler | ⬜ |
> **EUR-Lex erişim notu (2026-08-25):** EUR-Lex kısmen kapalı; hem HTML hem PDF
> uçları günlük Resmî Gazete indeksine yönlendiriyor. Yukarıdaki üç belge
> **Komisyon'un kendi sitesinden** (`taxation-customs.ec.europa.eu`) indirildi
> ve o kaynak çalışıyor. Kalan yasal işlemler için EUR-Lex'in düzelmesi
> beklenebilir ya da Komisyon sitesindeki sektörel rehberler kullanılabilir.

**Yeni öncelik: 3 numara.** Komisyon benchmark tablosunu hazır XLSX olarak
yayımlamış — D7'yi kapatmanın en kısa yolu bu. İndirip `data/benchmarks.csv`'ye
aktarılacak. Ardından 1 numara (D3, D4, D8 için).

## Kesin dönem yasal işlemleri (tam liste)

Rehber No. 4 s.5'ten:

| Kısa ad | İşlem | Dayanak |
|---|---|---|
| CBAM Regulation | (EU) 2023/956 + (EU) 2025/2083 tadili | — |
| Methodology Act | CIR (EU) 2025/2547 | Md. 7(7) |
| Default Values Act | CIR (EU) 2025/2621 | Md. 7(7) |
| Verification Principles Act | CIR (EU) 2025/2546 | Md. 8(3) |
| Accreditation & Verification | CDR (EU) 2025/2551 | Md. 18(3) |
| **Free Allocation Adjustment Act** | **CIR (EU) 2025/2620** | **Md. 31(2)** |

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

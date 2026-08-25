# Değişiklik Günlüğü

Bu projede [semantik sürümleme](https://semver.org/lang/tr/) kullanılır.

---

## [1.0.0] — 2026-08-25

İlk kararlı sürüm. Çekirdek hesap resmî Avrupa Komisyonu kaynaklarından
doğrulandı ve her referans değer kaynağını taşıyor.

### Doğrulanan mevzuat iddiaları

Kaynak: Avrupa Komisyonu Rehber No. 3 ve No. 4 (14 Ağustos 2026),
CBAM Benchmarks tablosu (6 Şubat 2026). Belgeler `data-raw/mevzuat/` altında,
SHA256'larıyla birlikte.

| # | İddia | Sonuç |
|---|---|---|
| D1 | Phase-in takvimi | ✅ **Hata bulundu ve düzeltildi** — 2031/2032/2033 yanlıştı |
| D2 | Sertifika hesabı formülü | ✅ Doğrulandı; eksik CSCF terimi eklendi |
| D5 | 2026 öncesi mali yükümlülük yok | ✅ |
| D6 | Dolaylı emisyon kapsamı | ✅ Yalnızca çimento, gübre, sinter |
| D7 | Benchmark değerleri | ✅ 570 CN kodu, resmî tablodan |
| D8 | CN kodları | ✅ |
| D3 | Menşede ödenen karbonun birimi | ✅ **Hata bulundu ve düzeltildi** |
| D4 | De minimis eşiği | ✅ **Hata bulundu ve düzeltildi** |

**Sekiz iddianın sekizi de doğrulandı; dördünde hata bulundu ve düzeltildi.**

| Madde | Hata | Düzeltme |
|---|---|---|
| D1 | 2031/2032/2033 phase-in faktörleri yanlıştı | Resmî tablodan türetiliyor |
| D2 | CSCF terimi eksikti | Formüle eklendi |
| **D3** | Menşede ödenen karbon **tCO2e** olarak düşülüyordu | **Bir fiyattır** (EUR/ton mal); sertifika referans fiyatına bölünür |
| **D4** | De minimis **50 tCO2e emisyon** sanılıyordu | **50 ton net kütle**; elektrik ve hidrojene uygulanmaz |

Ayrıntı: `data-raw/mevzuat/MEVZUAT_DOGRULAMA.md`

### Referans veri — tamamı resmî

| Tablo | Kayıt | Kaynak |
|---|---|---|
| `data/benchmarks.csv` | 570 CN kodu | CBAM Benchmarks tablosu (06.02.2026) |
| `data/varsayilan_yogunluk.csv` | 283 CN kodu, Türkiye | Default Values Act, CIR (EU) 2025/2621 (06.08.2026) |

`--cn` ve `--miktar` vermeniz yeterli: benchmark ve varsayılan emisyon
yoğunluğu resmî tablolardan otomatik gelir ve çıktıda kaynağıyla gösterilir.
**Hiçbir varsayılan değer projenin kendi tahmini değildir.**

> Varsayılan yoğunluklar mevzuatın öngördüğü değerlerdir ve bilerek yüksek
> seçilmişlerdir. Kendi ölçtüğünüz değeri `--yogunluk` ile verirseniz
> maliyetiniz büyük ihtimalle düşer.

### Özellikler

- **Hesap makinesi ve CLI** (`hesapla.R`) — CN kodunuzla hesap; benchmark resmî
  tablodan otomatik gelir
- **Şeffaf aritmetik** — her ara adım görünür, sonuç kâğıt üzerinde doğrulanabilir
- **Column A / B ayrımı** — tek üretim süreci vs tüm üretim zinciri
- **Belirsizlik dağılımı** — karbon fiyatı, döviz kuru ve tesis verimliliği
  birlikte oynatılır; tek tahmin yerine yüzdelikler ve VaR
- **Paylaşılabilir HTML rapor** (`--rapor`) — tek dosya, dışarıdan hiçbir kaynak
  yüklemez, künye gömülü
- **Değer başına provenans** — her sayının kaynağı çıktıda gösterilir
- **Doğrulama uyarısı** — doğrulanmamış değerler açıkça işaretlenir
- **Fonksiyonel birim uyarısı** — çimento ve gübrede birim ton ürün değildir
- **Reel/nominal ayrımı** — kur sürüklemesi enflasyon farkından türetilir,
  TRY üç ayrı sütunda raporlanır

### Kalite

- 161 test, 4 ortamda geçiyor (Linux, Windows, macOS, R 4.2)
- Sürekli entegrasyon: GitHub Actions
- **Sıfır çalışma zamanı bağımlılığı** — yalnızca R `base` ve `stats`; bu bir
  iddia değil, test edilen bir kural
- Canlı veri çekilmez, kullanıcı verisi hiçbir yere gönderilmez

### ⚠️ Bilinen sınırlar

- **Öncüller (precursors) modellenmiyor.** Araç ürünü tek üretim süreci sayar.
  Girdi satın alıyorsanız satın aldığınız malın gömülü emisyonu hesaba girmez.
  Cevherden kendi üreten entegre tesisler için geçerlidir.
- **`--mensede-odenen` kullanılmamalıdır** — D3 doğrulanmadı.
- **Elektrik kapsam dışı** — ayrı hesap yolu gerektirir.
- **Emisyon yoğunlukları sektör tahminidir** — kendi ölçtüğünüz değeri verin.
- **Uzak yıl belirsizlik kuyruğu güvenilmez** — karbon fiyatında ortalamaya
  dönüş modellenmiyor.
- **Bu bir beyan aracı değildir.** Çelişki halinde resmî mevzuat metni geçerlidir.

### Yol haritası

1. Default Values Act (CIR 2025/2621) → resmî emisyon yoğunlukları
2. EUA vadeli fiyat eğrisi çapası
3. **Öncül zinciri** (2.0.0 hedefi)
4. Ortalamaya dönen karbon fiyatı süreci
5. D3 — Türkiye ETS düşümü

### Lisans

AGPL-3.0-or-later, AGPL §7(b) atıf ek şartıyla. Bkz. `LICENSE`,
`LICENSE-ADDITIONAL-TERMS.md`, `NOTICE`.

# Mevzuat Doğrulama Kontrol Listesi

Kod şu an **8 iddiada** bulunuyor. Her biri resmî metinden doğrulanmalı.
Bir iddia doğrulandığında kutuyu işaretle, kaynak referansını yaz ve
ilgili kod dosyasına yorum olarak ekle.

> Bu liste projenin "mevzuata uygunluk" güvencesidir. Doğrulanmamış bir
> iddia, doğrulanmış gibi görünen bir iddiadan daha az tehlikelidir —
> o yüzden hiçbirini varsayılan olarak işaretli bırakma.

---

## D1 — Phase-in (CBAM faktörü) takvimi ⬜

**Kod:** [`R/cbam.R`](../../R/cbam.R) → `cbam_phase_in_factor()`

Kodun iddia ettiği takvim:

| Yıl | Faktör | Yıl | Faktör |
|---|---|---|---|
| 2026 | %2,5 | 2031 | %61,5 |
| 2027 | %5,0 | 2032 | %74,5 |
| 2028 | %10,0 | 2033 | %86,5 |
| 2029 | %22,5 | 2034 | %100 |
| 2030 | %48,5 | | |

**Doğrula:** Bu değerler ücretsiz tahsisatın kademeli kaldırılma takvimidir.
Kaynak muhtemelen CBAM Tüzüğü'nün ilgili maddesi ve/veya AB ETS Direktifi'nin
ücretsiz tahsisat maddesi. Omnibus tadili takvimi değiştirdi mi?

**Kaynak:** _________________

---

## D2 — Sertifika hesabı formülü ⬜ ⚠️ EN KRİTİK

**Kod:** [`R/cbam.R`](../../R/cbam.R) → `certificates_due()`

Kodun iddia ettiği formül:

```
sertifika = gömülü_emisyon − benchmark × miktar × (1 − cbam_faktörü) − menşede_ödenen
```

**Neden kritik:** Projenin en çarpıcı bulgusu buna dayanıyor — "2026'da CBAM
faktörü %2,5 olsa da benchmark üstü firma emisyonunun %36'sı üzerinden öder."
Formül yanlışsa bütün mesaj çöker.

**Doğrula:**
- Ücretsiz tahsisat düşümü gerçekten **benchmark üzerinden** mi yapılıyor,
  yoksa gömülü emisyon üzerinden mi?
- `(1 − faktör)` çarpanı doğru yerde mi?
- Sonuç negatif olamaz kuralı mevzuatta var mı?

**Kaynak:** _________________

---

## D3 — Menşede ödenen karbon düşümü ⬜

**Kod:** [`R/cbam.R`](../../R/cbam.R) → `certificates_due(carbon_paid_origin=)`

Kod şu an menşede ödenen karbonu **tCO2e cinsinden** düşüyor.

**Doğrula:** Mevzuat *fiilen ödenen karbon fiyatı* üzerinden mi düşüm
öngörüyor? Öyleyse mevcut parametre yanlış birimde ve yeniden tasarlanmalı.
Türkiye ETS devreye girdiğinde bu, aracın en değerli özelliği olacak —
şimdiden doğru kurmak gerek.

**Kaynak:** _________________

---

## D4 — De minimis eşiği ⬜

**Kod:** [`R/cbam.R`](../../R/cbam.R) → `is_de_minimis()`, varsayılan 50 tCO2e

Kodun iddiası: ithalatçı başına yıllık 50 tCO2e altındaki gömülü emisyon muaf.

**Doğrula:** Eşik 50 **tCO2e** mi yoksa 50 **ton mal** mı? Omnibus'ta hangi
biçimde geçiyor? İthalatçı başına mı, sevkiyat başına mı, yıllık mı?

**Kaynak:** _________________

---

## D5 — 2026 öncesi mali yükümlülük yok ⬜

**Kod:** [`R/cbam.R`](../../R/cbam.R) → `cbam_phase_in_factor()`, `year < 2026 → 0`

Kodun iddiası: geçiş döneminde yalnızca raporlama var, sertifika alınmıyor.

**Kaynak:** _________________

---

## D6 — Dolaylı (elektrik) emisyonların kapsamı ⬜ ⚠️ EN YÜKSEK BEDELLİ

**Kod:** [`data/urunler.csv`](../../data/urunler.csv) → `dolayli_kapsamda` sütunu

Şu an tüm satırlarda `hayir` yazıyor — **bu doğrulanmamış bir varsayım.**

**Doğrula:** Hangi ürünlerde dolaylı emisyonlar CBAM yükümlülüğüne giriyor?
CBAM Tüzüğü'nde ürün bazında bunu belirleyen bir ek/sütun var; bul ve
her ürün için `evet`/`hayir` değerini oradan gir.

**Beklenen ayrım:** Çimento ve gübrede dolaylı emisyonların dahil olduğu,
demir-çelik ve alüminyumda olmadığı yönünde bir ayrım olması muhtemel —
ama bunu metinden teyit et, varsayma.

**Pratik bedeli:** 15.000 tonluk alüminyum ihracatçısı için 2034'te
136 EUR/ton (yalnız doğrudan) ile 608 EUR/ton (dolaylı dahil) arasındaki
fark — yılda yaklaşık **7 milyon EUR**.

**Kaynak:** _________________

---

## D7 — Benchmark değerleri ⬜

**Kod:** [`data/benchmarks.csv`](../../data/benchmarks.csv)

**Doğrula — iki katmanlı soru:**

1. Değerlerin kendisi doğru mu?
2. **Hangi tahsisat dönemi geçerli?** Ücretsiz tahsisat benchmark'ları dönem
   dönem güncelleniyor (2021–2025, 2026–2030, ...). CBAM 2026'da ücretlendirmeye
   başlıyor, yani **2026–2030 dönemi benchmark'ları** geçerli olmalı; 2021–2025
   değerlerini kullanmak sessiz bir hata olur.

Her satırın `gecerli_baslangic` / `gecerli_bitis` sütunları bu yüzden var.

**Kaynak:** _________________

---

## D8 — Kapsamdaki ürünler ve CN kodları ⬜

**Kod:** [`data/urunler.csv`](../../data/urunler.csv) → `cn_kodlari` sütunu

Şu an boş. CBAM Tüzüğü Ek I'deki CN kodlarını her ürün satırına gir.

**Doğrula:** Kullanıcının ihraç ettiği ürünün CN kodu gerçekten kapsamda mı?
Alüminyumda ham metal ile yarı mamul arasında fark var; çelikte de bazı
alt kalemler kapsam dışı olabilir.

**Kaynak:** _________________

---

## Yapısal Not — Elektrik farklı bir hesap istiyor ⚠️

Motorun mevcut modeli şunu varsayıyor:

```
gömülü emisyon = miktar (ton) × emisyon yoğunluğu (tCO2e/ton)
ücretsiz tahsisat = ürün benchmark'ı × miktar × (1 − faktör)
```

**Elektrik bu kalıba oturmuyor:** birim MWh, "ürün benchmark'ı" aynı anlamda
yok, varsayılan değerler menşe ülke şebeke karbon yoğunluğuna göre
belirleniyor ve özel kurallar var.

**Karar:** Elektrik `data/urunler.csv`'ye satır olarak eklenmeyecek. Kendi
hesap yolunu gerektiriyor (`R/electricity.R`), ayrı bir iş kalemi.
Hidrojenin standart kalıba oturup oturmadığı da mevzuattan kontrol edilmeli.

Bunu şimdi ayırmak, yanlış modele zorlamaktan iyidir.

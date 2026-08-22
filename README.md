# Stochastic CBAM Engine

> Open-source stochastic MRIO framework for Carbon Border Adjustment Mechanism (CBAM) exposure analysis.

Bu proje, AB Sınırda Karbon Düzenleme Mekanizması'nın (SKDM) ihracatçılar üzerindeki etkisini sektörel ortalamalara sıkışmadan, stokastik belirsizlikler ve mikro düzey firma verileriyle hesaplayan açık kaynaklı bir ekonometrik laboratuvardır.

## Proje Vizyonu ve Kapsamı

Piyasadaki kapalı kutu (black-box) danışmanlık araçlarının aksine, bu altyapı **açık bilim (open-science)** ve **tekrarlanabilirlik (reproducibility)** ilkeleriyle inşa edilmiştir.

* **Odak Ülke:** Türkiye
* **Odak Sektör:** Demir ve Çelik (Modüler yapı ile genişletilebilir)
* **Veritabanı:** EXIOBASE / WIOD

## Hızlı Başlangıç

Gereksinim: **R ≥ 4.0**. Harici paket bağımlılığı yoktur — yalnızca `base` ve `stats` kullanılır.

### Hesap makinesi

Kendi rakamlarınızı girin, yıllık CBAM maliyetinizi hesaplayın:

```bash
Rscript hesapla.R --rota bof --miktar 250000 --yil 2030 --kur 48
```

```
HESAP
  Gomulu emisyon        250.000 x 1,950          =       487.500 tCO2e
  Ucretsiz tahsisat     1,288 x 250.000 x 0,515  =      -165.830 tCO2e
                        (0,515 = 1 - CBAM faktoru 0,485)
  --------------------------------------------------------------------
  SERTIFIKA YUKUMLULUGU                          =       321.670 tCO2e
                                                   (emisyonun %66,0'i)

  CBAM MALIYETI         321.670 x 80,00 EUR      =    25.733.600 EUR
                        x 48,00 TRY/EUR          = 1.235.212.800 TRY
  Ton basina yuk                                 =        102,93 EUR/ton

BELIRSIZLIK  (50.000 simulasyon, 4 yillik ufuk)
    %5  (iyimser)     :       6.850.369 EUR
    Medyan            :      24.248.507 EUR
    %95 (VaR)         :      85.530.001 EUR
```

Her ara adım görünür — sonucu kâğıt üzerinde doğrulayabilirsiniz. Kapalı kutu
araçlardan ayrışan nokta budur.

Kendi tesis verinizle:

```bash
Rscript hesapla.R --miktar 120000 --yogunluk 1.72 --benchmark 1.288 \
                  --yil 2030 --karbon-fiyati 85 --kur 48

Rscript hesapla.R --yardim        # tüm seçenekler
```

`--rota` değerleri (`eaf`, `bof`) gösterim amaçlı sektör ortalamalarıdır, resmî
değer değildir. Gerçek analiz için kendi tesis verinizi kullanın.

### R içinden

```r
# Proje kökünden
source("load_all.R")

hesap <- cbam_estimate(
  quantity     = 250000,   # ton/yıl AB'ye ihracat
  ei_direct    = 1.95,     # tCO2e/ton (doğrudan emisyon)
  benchmark    = 1.288,    # AB ETS sıcak metal benchmark'ı
  year         = 2030,
  carbon_price = 80,       # EUR/tCO2e
  fx_rate      = 48        # TRY/EUR
)
print(hesap)
```

Simülasyon motoruna doğrudan erişim:

```r
sim <- run_cbam_mc(
  n_sims         = 50000,
  quantity       = 250000,   # ton/yıl AB'ye ihracat
  ei_sector      = 1.95,     # tCO2e/ton (doğrudan emisyon)
  theta_sdlog    = 0.20,     # firma teknoloji heterojenliği
  benchmark      = 1.288,    # AB ETS sıcak metal benchmark'ı
  year           = 2030,
  carbon_price_0 = 80,       # EUR/tCO2e
  fx_0           = 48,       # TRY/EUR
  seed           = 2026
)

print(sim)
risk_summary(sim)
cbam_var(sim, level = 0.95)
```

Test ve demo:

```bash
Rscript tests/test_engine.R                   # 77 test
Rscript analysis/01_demo_turkiye_celik.R      # EAF vs BF-BOF senaryo demosu
```

## Metodolojik Çerçeve

Proje, yasal olarak vergilendirilen emisyonlar ($E_{CBAM}$) ile tedarik zincirindeki toplam emisyonları ($E_{MRIO}$) birbirinden ayırır. Sektörel makro Girdi-Çıktı matrisleri, firma düzeyindeki heterojen teknoloji katsayıları ile esnetilir:

$$ EI_f = EI_s \times \theta_f $$

*(Burada $EI_f$ firmanın spesifik emisyon yoğunluğunu, $EI_s$ sektör ortalamasını ve $\theta_f$ teknoloji ayarlama katsayısını temsil eder.)*

`theta_f` firma düzeyi veri yokluğunda lognormal dağılımdan örneklenir — emisyon yoğunluğu pozitif tanımlı ve sağa çarpıktır (az sayıda çok kirli tesis, çok sayıda ortalamaya yakın tesis).

### Yükümlülük hesabı

İthalatçı, AB üreticisinin hâlâ aldığı ücretsiz tahsisat kadar muaftır; bu muafiyet CBAM faktörü arttıkça erir:

```
sertifika = gömülü_emisyon − benchmark × miktar × (1 − cbam_factor) − menşede_ödenen
```

CBAM faktörü Regulation (EU) 2023/956 takvimini izler: 2026'da %2,5 → 2034'te %100.

> **Metodolojik not.** Ücretsiz tahsisat *benchmark üzerinden* düşüldüğü için, benchmark'ın belirgin şekilde üstünde emisyon yoğunluğuna sahip bir firma 2026'da bile ciddi yükümlülük altına girer. "2026'da yalnızca %2,5 ödenir" ifadesi yalnızca benchmark'taki ortalama üretici için geçerlidir. Bu, modelin en politika-ilgili çıktılarından biridir.

### Belirsizlik ve Risk Modellemesi

Sistem deterministik tek bir sonuç vermek yerine, Monte Carlo simülasyonları kullanarak;

* EU ETS karbon fiyatı volatilitesini,
* Döviz kuru dalgalanmalarını

Geometrik Brown Hareketi ile modeller. İki süreç Cholesky ayrışımıyla korele edilir (`rho`) — enerji fiyatı şokları her ikisini de aynı yönde etkileyebilir. Çıktı, **%90 güven aralığında** risk olasılık dağılımı ve VaR'dır.

## Proje Yapısı

```
R/
  emissions.R     EI_f = EI_s × theta_f, gömülü emisyon, theta örnekleme
  cbam.R          Phase-in takvimi, sertifika yükümlülüğü, maliyet, de minimis
  stochastic.R    GBM, korele şoklar, piyasa simülasyonu
  mrio.R          Teknik katsayılar, Leontief tersi, E_CBAM/E_MRIO kapsam farkı
  monte_carlo.R   Simülasyon motoru, risk özeti, VaR
  calculator.R    Kullanıcı girdisi → okunabilir tek cevap (hesap makinesi)
  utils.R         Sayı/aralık formatlama
hesapla.R         Komut satırı hesap makinesi (--yardim)
tests/
  test_engine.R   77 test (base R, harici test paketi gerektirmez)
analysis/
  01_demo_turkiye_celik.R   EAF vs BF-BOF, 2026/2030/2034 senaryoları
data-raw/         Ham EXIOBASE/WIOD ve firma verisi (versiyonlanmaz)
load_all.R        Bağımlılıksız modül yükleyici
```

Katmanlar ayrıdır: `R/` altındaki motor saf hesap yapar ve hiçbir yere yazmaz;
`calculator.R` ve `hesapla.R` yalnızca sunum katmanıdır.

## Yol Haritası

- [x] Çekirdek emisyon ve CBAM yükümlülük motoru
- [x] Monte Carlo belirsizlik katmanı (karbon fiyatı + kur, korele)
- [x] MRIO temel fonksiyonları (Leontief tersi, toplam yoğunluk)
- [x] Test altyapısı ve çalıştırılabilir demo
- [x] Hesap makinesi ve komut satırı arayüzü (`hesapla.R`)
- [ ] HTML/PDF rapor çıktısı
- [ ] Duyarlılık ayrıştırması ve başabaş analizi
- [ ] Dekarbonizasyon yatırım kararı modülü (kümülatif maliyet vs. NPV)
- [ ] EXIOBASE/WIOD veri alım katmanı (`data-raw/`)
- [ ] Gerçek AB ETS benchmark tablosunun paketlenmesi
- [ ] Çoklu sektör desteği (çimento, alüminyum, gübre, elektrik, hidrojen)
- [ ] Duyarlılık analizi (Sobol indeksleri)
- [ ] Görselleştirme katmanı ve raporlama şablonu

## Lisanslama ve Fikri Mülkiyet

Bu altyapı **AGPLv3 (GNU Affero General Public License v3.0)** ile lisanslanmıştır. Akademik araştırmalarda serbestçe kullanılabilir ve atıf yapılarak geliştirilebilir. Ticari kullanım ve kapalı sistem entegrasyonları için "Çifte Lisanslama" (Dual Licensing) modeli uygulanmaktadır.

## Uyarı

`analysis/` altındaki parametreler gösterim amaçlı varsayımlardır, gerçek firma verisi değildir. Üretim analizi için kendi verinizi `data-raw/` altına yerleştirin.

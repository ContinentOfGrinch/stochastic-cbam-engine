# Stochastic CBAM Engine

[![testler](https://github.com/ContinentOfGrinch/stochastic-cbam-engine/actions/workflows/test.yml/badge.svg)](https://github.com/ContinentOfGrinch/stochastic-cbam-engine/actions/workflows/test.yml)
[![lisans: AGPL v3](https://img.shields.io/badge/lisans-AGPL--3.0--or--later-blue.svg)](LICENSE)

> Türk ihracatçılar için açık kaynaklı CBAM maliyet hesaplayıcısı.
> Her sayı kaynağını gösterir; tek tahmin yerine olasılık dağılımı verir.

**Proje iki parçadan oluşur:**

| Parça | Kimin için | Ne gerektirir |
|---|---|---|
| **Hesap makinesi** (`hesapla.R`, `R/`) | İhracatçı, üretici | Çarpma ve çıkarma |
| **Araştırma eki** (`research/`) | Akademisyen | Girdi-çıktı iktisadı |

Araştırma eki **isteğe bağlıdır** — hesap makinesi ona hiç dokunmaz, silinse
aynen çalışır. Çoğu kullanıcının ihtiyacı yalnızca ilk satırdır.

Araç, AB Sınırda Karbon Düzenleme Mekanizması'nın (SKDM) bir ihracatçıya
maliyetini hesaplar. Sektörel ortalamaya sıkışmak yerine firmanın kendi
emisyon yoğunluğuyla çalışır ve tek bir tahmin yerine karbon fiyatı ile kur
belirsizliğini de içeren bir dağılım verir.

## Proje Vizyonu ve Kapsamı

Piyasadaki kapalı kutu (black-box) danışmanlık araçlarının aksine, bu altyapı **açık bilim (open-science)** ve **tekrarlanabilirlik (reproducibility)** ilkeleriyle inşa edilmiştir.

* **Odak Ülke:** Türkiye
* **Kapsam:** CBAM'in yürürlükteki tüm sektörleri — demir-çelik, alüminyum,
  çimento, gübre, hidrojen (570 CN kodu). Elektrik ayrı hesap yolu gerektirdiği
  için henüz kapsam dışı.
* **Referans veri:** Avrupa Komisyonu resmî tabloları — benchmark (Şubat 2026)
  ve varsayılan emisyon değerleri (Ağustos 2026)

## Hızlı Başlangıç

Gereksinim: **R ≥ 4.0**. Harici paket bağımlılığı yoktur — yalnızca `base` ve `stats` kullanılır.

### Hesap makinesi

Kendi rakamlarınızı girin, yıllık CBAM maliyetinizi hesaplayın:

CN kodunuz gümrük beyanınızda yazar; benchmark resmî AB tablosundan gelir:

```bash
Rscript hesapla.R --cn 72081000 --miktar 250000 \
                  --yil 2030 --karbon-fiyati 80 --kur 48
```

```
CN 72081000 | Flat-rolled products of iron or non-alloy steel...
Benchmark Column B = 1,370 tCO2e/ton | Kaynak: CBAM-BENCHMARKS-2026-02-06
Varsayilan yogunluk = 2,428 tCO2e/ton (Turkiye, dogrudan)
  Kaynak: CBAM-DEFAULT-VALUES-2026-08-06, Turkiye sayfasi | CN 7208
  !! Bu mevzuatin VARSAYILAN degeridir, tesisinizin degeri degildir.

HESAP
  Gomulu emisyon        250.000 x 2,428          =       607.000 tCO2e
  Ucretsiz tahsisat     1,370 x 250.000 x 0,515  =      -176.388 tCO2e
                        (0,515 = 1 - CBAM faktoru 0,485)
  --------------------------------------------------------------------
  SERTIFIKA YUKUMLULUGU                          =       430.613 tCO2e
                                                   (emisyonun %70,9'i)

  CBAM MALIYETI         430.613 x 80,00 EUR      =    34.449.000 EUR
                        x 48,00 TRY/EUR          = 1.653.552.000 TRY
  Ton basina yuk                                 =        137,80 EUR/ton
```

**Hiçbir sayı bizim tahminimiz değil.** Benchmark Komisyon'un benchmark
tablosundan, emisyon yoğunluğu Default Values Act'ten, phase-in faktörü
Rehber No. 4'ten geliyor — hepsi çıktıda kaynağıyla gösteriliyor.

`--sutun` benchmark sütununu seçer ve **fark büyüktür**:

| Sütun | Kime | CN 72081000 örneği |
|---|---|---|
| **B** (varsayılan) | Cevherden üreten entegre tesis | 1,370 tCO2e/ton |
| **A** | Yalnızca son işlemi yapan tesis | 0,044 tCO2e/ton |

Her ara adım görünür — sonucu kâğıt üzerinde doğrulayabilirsiniz. Kapalı kutu
araçlardan ayrışan nokta budur.

Kendi tesis verinizle:

```bash
Rscript hesapla.R --cn 72081000 --yogunluk 1.72 --miktar 120000 \
                  --yil 2030 --karbon-fiyati 85 --kur 48

Rscript hesapla.R --urunler       # hazır ürün tanımları ve CN kodları
Rscript hesapla.R --yardim        # tüm seçenekler
```

### Paylaşılabilir rapor

```bash
Rscript hesapla.R --cn 72081000 --yogunluk 1.95 --miktar 250000 --yil 2030 \
                  --firma "Örnek Çelik A.Ş." --rapor cikti/rapor.html
```

Tek bir HTML dosyası üretir (~10 KB): yönetici özeti, şeffaf hesap tablosu,
dağılım grafiği, yüzdelikler ve tam provenans bloğu. Tarayıcıda açılır,
PDF olarak yazdırılır, e-postayla gönderilir.

**Dışarıdan hiçbir şey yüklemez** — internet olmadan açılır, hiçbir sunucuya
istek gitmez. Bu test altındadır: alıcının verisi hiçbir yere ulaşmaz.

`--urun` ile referans değerler otomatik gelir; üstüne `--yogunluk` verirseniz
kendi tesis veriniz referans değerin yerine geçer.

## Bilinen Sınırlar

Bu araç neyi bilmediğini söyler. Bir sonuca güvenmeden önce şunlara bakın:

| Sınır | Etkisi |
|---|---|
| **Öncüller (precursors) modellenmiyor** | Araç ürünü **tek üretim süreci** sayar. Girdi (slab, kütük, öncül) satın alıyorsanız, satın aldığınız malın gömülü emisyonu hesaba **girmez** ve sonuç eksik çıkar. Cevherden kendi üreten entegre tesisler için geçerlidir. |

| **De minimis kümülatif eşiktir** | 50 ton net kütle, ithalatçı başına ve **tüm CN kodları toplamında** yıllık. Araç tek bir miktar görür; yıllık toplamınızı siz takip etmelisiniz. |
| **Elektrik kapsam dışı** | Ücretsiz tahsisatı sıfır, birimi MWh; ayrı bir hesap yolu gerektirir. |
| **Varsayılan yoğunluklar tesisinize ait değildir** | Default Values Act'ten gelen resmî değerlerdir ve bilerek **yüksek** seçilmişlerdir. **Kendi ölçtüğünüz değeri `--yogunluk` ile verin** — maliyetiniz büyük ihtimalle düşer. |
| **Uzak yıl belirsizlik kuyruğu** | Karbon fiyatı Geometrik Brown Hareketi ile modellenir; ortalamaya dönüş ve AB Piyasa İstikrar Rezervi yoktur. Uzak yıllarda %95 üst sınırı gerçekçi olmayan fiyatlara uzanır. Bütçe için medyanı ve yakın yılları kullanın. |
| **Çimento ve gübrede birim farklı** | Ton ürün değil: çimento *ton klinker*, gübre *kg azot*. Araç uyarı basar ama dönüşümü sizin yapmanız gerekir. |

**Bu bir beyan aracı değildir.** CBAM raporu/beyanı üretmez; maruziyet hesabı ve
karar desteği için tasarlanmıştır. Çelişki halinde resmî mevzuat metni geçerlidir.

Doğrulama durumunun tamamı: [`data-raw/mevzuat/MEVZUAT_DOGRULAMA.md`](data-raw/mevzuat/MEVZUAT_DOGRULAMA.md)

## Kaynak Şeffaflığı

Hesabın kullandığı her referans değer **kaynağını taşır** ve çıktıda gösterilir:

```
CN 72081000 | Flat-rolled products of iron or non-alloy steel...
Benchmark Column B = 1,370 tCO2e/ton
Kaynak: CBAM-BENCHMARKS-2026-02-06, CN 72081000, Column B
```

İki referans tablosu da resmî ve doğrulanmış durumda:

| Tablo | Kayıt | Kaynak |
|---|---|---|
| `data/benchmarks.csv` | 570 CN kodu | CBAM Benchmarks tablosu (06.02.2026) |
| `data/varsayilan_yogunluk.csv` | 283 CN kodu, Türkiye | Default Values Act — **CIR (EU) 2026/1740** (Sürüm 2, 06.08.2026) |

> **Sürüm önemlidir.** Varsayılan emisyon değerleri CIR (EU) 2025/2621 ile
> yayımlandı, **CIR (EU) 2026/1740** ile revize edildi. Araç Sürüm 2'yi
> kullanır ve her çıktıda hangi belgeden geldiğini yazar. Kaynak dosya
> SHA256'sıyla birlikte `data-raw/mevzuat/` altındadır.

Resmî AB belgeleri `data-raw/mevzuat/` altında **değiştirilmemiş halde** depoda
durur, SHA256'larıyla birlikte. `data/` altındaki CSV tabloları bunlardan
aktarılmıştır ve her satır `kaynak_belge` + `kaynak_yeri` sütunlarıyla belgeye
geri bağlanır.

Bir değerin kaynağı yoksa araç bunu **çıktıda açıkça söyler** ve hesabı
sessizce sürdürmez:

```
!! DIKKAT: Bu hesapta DOGRULANMAMIS deger kullanildi.
```

> Bu kural test altındadır: `durum=dogrulandi` diyen her satırın
> `kaynak_belge` alanı dolu olmak **zorundadır**.

> Referans veri paketi sürümlenir (`data/VERSION`) ve her çıktıda basılır.
> Araç canlı veri çekmez — bu bir kısıt değil, tekrarlanabilirlik koşuludur:
> canlı API'den beslenen bir analiz tekrarlanamaz.

Belgelerin telif durumu koddan ayrıdır: kod AGPLv3, AB belgeleri Komisyon'un
yeniden kullanım koşullarına tabidir. Ayrıntı: `data-raw/mevzuat/KAYNAKLAR.md`.

### R içinden

```r
# Proje kökünden
source("load_all.R")

hesap <- cbam_estimate(
  quantity     = 250000,   # ton/yıl AB'ye ihracat
  ei_direct    = 1.95,     # tCO2e/ton (doğrudan emisyon)
  benchmark    = 1.370,    # CN 72081000, Column B (resmî tablodan)
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
  benchmark      = 1.370,    # CN 72081000, Column B (resmî tablodan)
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
Rscript tests/test_engine.R                   # 172 test
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
sertifika = gömülü_emisyon − benchmark × miktar × CBAM_faktörü × CSCF − menşede_ödenen
```

Kaynak: Free Allocation Adjustment Act (CIR (EU) 2025/2620), Ek nokta 2 ve 5;
Rehber No. 4, Denklem (1)–(2).

> **İsim karışıklığına dikkat.** Mevzuatın *"CBAM factor"* dediği değer,
> ücretsiz tahsisatın **hâlâ geçerli olan payıdır** — 2026'da %97,5, 2034'te %0.
> Kodda `cbam_phase_in_factor()` bunun tümleyenini, yani **yükümlülük payını**
> döndürür (2026'da %2,5, 2034'te %100). Tek doğruluk kaynağı
> `cbam_factor_official()`; diğeri ondan türetilir.
>
> `CSCF` (cross-sectoral correction factor, AB ETS Md. 10a(5)) 2026–2030 için
> 1,0'dır; formülde yer alması, değer değiştiğinde motorun sessizce yanlış
> hesap yapmaması içindir.

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
  monte_carlo.R   Simülasyon motoru, risk özeti, VaR
  reference.R     Referans veri okuyucu, kaynak izleme, doğrulama uyarısı
  calculator.R    Kullanıcı girdisi → okunabilir tek cevap (hesap makinesi)
  report.R        Paylaşılabilir HTML rapor (bağımlılıksız, tek dosya)
  utils.R         Sayı/aralık formatlama
hesapla.R         Komut satırı hesap makinesi (--yardim, --urunler, --rapor)
research/         ARAŞTIRMA EKİ — hesap makinesi buraya hiç dokunmaz
  mrio.R          Leontief tersi, E_CBAM/E_MRIO kapsam farkı
data/             İşlenmiş referans veri (CSV, her satır kaynağıyla)
  urunler.csv     Ürün kataloğu → CN kodu eşlemesi
  varsayilan_yogunluk.csv  Default Values Act, Türkiye (283 CN kodu)
  benchmarks.csv  AB ETS ürün benchmark'ları
  VERSION         Veri paketi sürümü
data-raw/
  mevzuat/        Resmî AB belgeleri — değiştirilmemiş, versiyonlanır
  exiobase/       Büyük MRIO matrisleri (versiyonlanmaz)
  firma/          Firma düzeyi veri (versiyonlanmaz)
tests/
  test_engine.R   172 test (base R, harici test paketi gerektirmez)
LICENSE                        AGPL-3.0 tam metni
LICENSE-ADDITIONAL-TERMS.md    Atıf ek şartı (AGPL §7(b)) + marka notu
NOTICE                         Telif, atıf ve veri kaynağı bildirimleri
CONTRIBUTING.md                Katkı rehberi + DCO
CITATION.cff                   Akademik atıf künyesi
analysis/
  01_demo_turkiye_celik.R   EAF vs BF-BOF, 2026/2030/2034 senaryoları
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
- [x] Referans veri katmanı, kaynak izleme ve doğrulama uyarısı
- [x] Paylaşılabilir HTML rapor (`--rapor`)

**v1.0 için kalan:**

- [ ] Resmî AB belgelerinden değerlerin doğrulanması (`data-raw/mevzuat/`)
- [x] Sürekli entegrasyon (GitHub Actions) — 3 işletim sistemi, R 4.2 ve güncel
- [x] Reel/nominal ayrımı — kur sürüklemesi enflasyon farkından türetiliyor

**v1.0 sonrası:**

- [ ] Duyarlılık ayrıştırması ve başabaş analizi
- [ ] Dekarbonizasyon yatırım kararı modülü (kümülatif maliyet vs. NPV)
- [ ] Çimento, gübre, hidrojen için doğrulanmış değerler
- [ ] Elektrik modülü (ayrı hesap yolu gerektiriyor)
- [ ] MRIO entegrasyonu ve EXIOBASE veri alım katmanı
- [ ] Gerçek AB ETS benchmark tablosunun paketlenmesi
- [ ] Çoklu sektör desteği (çimento, alüminyum, gübre, elektrik, hidrojen)
- [ ] Duyarlılık analizi (Sobol indeksleri)
- [ ] Görselleştirme katmanı ve raporlama şablonu

## Bu Proje Nasıl Üretildi

Fikir, kapsam ve yönlendirme **Selahattin İlhan**'a aittir: problem tanımı,
hangi sektörlerin kapsama gireceği, ürün ile araştırma katmanının ayrılması,
lisans ve atıf stratejisi, kapsamın dar tutulması ve her aşamadaki kabul/ret
kararları.

Kod, bir yapay zekâ asistanı (Anthropic Claude) ile eşli çalışılarak yazıldı.
Mevzuat doğrulaması da aynı yöntemle yürütüldü: resmî Avrupa Komisyonu
belgeleri indirildi, kodun her iddiası metinle karşılaştırıldı, bulgular
kaynak referanslarıyla [`MEVZUAT_DOGRULAMA.md`](data-raw/mevzuat/MEVZUAT_DOGRULAMA.md)
içinde kayda geçirildi. Bu denetim **sekiz iddiadan beşinde hata buldu.**

> Bu not projenin kendi ilkesinin gereğidir: her sayının kaynağını göstermeyi
> şart koşan bir araç, kendi üretim biçimini de gizlememelidir. Akademik
> kullanımda bu bilginin beyan edilmesi ayrıca gerekir.

Doğrulanabilirliğin dayanağı kimin yazdığı değil, **kaynağın gösterilmiş
olmasıdır**: her değer belgeye kadar izlenebilir, kaynak belgeler SHA256'larıyla
depoda, 177 test dört ortamda koşuyor. Bunların hiçbiri okuyucunun bize
güvenmesini gerektirmez.

## Lisans ve Katkı

**AGPL-3.0-or-later** ([`LICENSE`](LICENSE)) + atıf ek şartı
([`LICENSE-ADDITIONAL-TERMS.md`](LICENSE-ADDITIONAL-TERMS.md)).

Copyright © 2026 Selahattin İlhan · ORCID
[0009-0007-4824-752X](https://orcid.org/0009-0007-4824-752X)

| | |
|---|---|
| Yerel kullanım (kendi bilgisayarında) | Serbest, hiçbir yükümlülük yok |
| Akademik araştırma | Serbest — [`CITATION.cff`](CITATION.cff) ile atıf verin |
| Değiştirip dağıtma | Değişiklikleriniz de AGPL ile açık olmalı |
| Web sitesinde/serviste sunma | Kullanıcılarınıza kaynak kodu sunmalısınız (AGPL §13) |

**Atıf ek şartı (AGPL §7(b)):** Yeniden dağıtırsanız kaynak dosyalardaki telif
başlıklarını, [`NOTICE`](NOTICE) dosyasını ve **araç çıktısındaki künyeyi**
korumak zorundasınız. Kendi adınızı ekleyebilirsiniz; mevcut olanı
kaldıramazsınız. Lisans projenin **adını** kullanma hakkı vermez.

**Katkı:** [`CONTRIBUTING.md`](CONTRIBUTING.md). CLA yok — sadece
`git commit -s` ile DCO imzası. Telif hakkınız sizde kalır.

**Ticari lisans:** AGPL koşulları senaryonuza uymuyorsa farklı koşullarla
lisanslama için iletişime geçebilirsiniz.

## Uyarı

`analysis/` altındaki parametreler gösterim amaçlı varsayımlardır, gerçek firma verisi değildir. Üretim analizi için kendi verinizi `data-raw/` altına yerleştirin.

#!/usr/bin/env Rscript
#
#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md
#
#  CBAM HESAP MAKINESI - komut satiri arayuzu
#
#  Kullanim:
#    Rscript hesapla.R --miktar 250000 --yogunluk 1.95 --benchmark 1.288 \
#                      --yil 2030 --karbon-fiyati 80 --kur 48
#
#    Rscript hesapla.R --rota bof --miktar 250000 --yil 2030 --kur 48
#    Rscript hesapla.R --yardim
#
#  Bu dosya yalnizca girdi ayristirma ve yardim metni icerir; hesabin
#  tamami R/calculator.R icindedir.

suppressWarnings(suppressMessages(source("load_all.R")))

# Urun tanimlari data/urunler.csv ve data/benchmarks.csv icinden gelir;
# bu dosyada gomulu deger yoktur. Kaynak belgeler data-raw/mevzuat/ altinda.

yardim <- function() {
  cat("
CBAM HESAP MAKINESI
===================

Kendi rakamlarinizi girin, yillik CBAM maliyetinizi hesaplayin.

KULLANIM
  Rscript hesapla.R [secenekler]

ZORUNLU
  --miktar <ton>          AB'ye yillik ihracat miktari

  ve benchmark icin asagidakilerden biri:
  --cn <kod>              CN kodunuz (gumruk beyaninizda yazar). Benchmark
                          resmi AB tablosundan otomatik gelir. ONERILEN.
  --urun <kod>            Hazir urun tanimi. Kodlar icin: --urunler
  --benchmark <tCO2e/ton> Benchmark'i elle verin

  --yogunluk <tCO2e/ton>  Kendi olctugunuz dogrudan emisyon yogunlugunuz.
                          Vermezseniz mevzuatin VARSAYILAN degeri kullanilir
                          (Default Values Act). Varsayilanlar bilerek yuksek
                          secilir - kendi degerinizi vermek genelde lehinizedir.
  --ulke <ad>             Varsayilan deger tablosundaki ulke (varsayilan: Turkiye)

  --sutun <A|B>           Benchmark sutunu (varsayilan: B)
                            B = tum uretim zinciri (cevherden urune kendi
                                ureten entegre tesis)
                            A = tek uretim sureci (yalnizca son islemi
                                yapan tesis, ornek sadece haddeleme)
                          Yanlis sutun 30 kata varan hata demektir.

ISTEGE BAGLI
  --yil <yil>             Yukumluluk yili           (varsayilan: 2026)
  --karbon-fiyati <EUR>   EU ETS fiyati             (varsayilan: 80)
  --kur <TRY/EUR>         Doviz kuru                (varsayilan: 1, yalniz EUR)
  --odenen-karbon-fiyati <EUR>
                          Mensede fiilen odenmis karbon FIYATI, MAL TONU
                          basina EUR (SECPP). Miktar degil FIYAT. Iade ve
                          tazminatlar dusulmus olmali. CBAM Tuzugu Md. 9.
  --sertifika-referans-fiyati <EUR>
                          CBAM sertifikasi referans fiyati (EUR/tCO2e).
                          Odenen karbon verildiyse ZORUNLU - odenen fiyat
                          buna bolunerek tCO2e'ye cevrilir.
  --dolayli <tCO2e/ton>   Elektrik kaynakli dolayli emisyon
  --dolayli-dahil         Dolayli emisyonu hesaba kat
  --sacilim <sd>          Tesis verimliligi sacilimi (varsayilan: 0.20)
  --baz-yil <yil>         Fiyatlarin gozlendigi yil (varsayilan: 2026)
  --simulasyon <n>        Simulasyon sayisi         (varsayilan: 50000)
  --tohum <n>             Rastgele sayi tohumu      (varsayilan: 2026)
  --kesin                 Belirsizlik hesaplamadan yalniz deterministik sonuc
  --rapor <dosya.html>    Paylasilabilir HTML rapor uret
  --firma <ad>            Raporun ustunde gorunecek firma adi
  --urunler               Referans tablosundaki urunleri listele
  --yardim                Bu metni goster

ORNEKLER
  # CN kodunuz ve kendi tesis yogunlugunuzla (ONERILEN yol)
  Rscript hesapla.R --cn 72081000 --yogunluk 1.95 --miktar 250000 \\
                    --yil 2030 --karbon-fiyati 80 --kur 48

  # Yalnizca son islemi yapiyorsaniz (ornek: sadece haddeleme)
  Rscript hesapla.R --cn 72081000 --yogunluk 0.08 --sutun A \\
                    --miktar 250000 --yil 2030

  # Ham aluminyum, hazir urun tanimiyla
  Rscript hesapla.R --urun alu-ham --miktar 15000 --yil 2030 --kur 48

  # Paylasilabilir HTML rapor
  Rscript hesapla.R --cn 72081000 --yogunluk 1.95 --miktar 250000 \\
                    --yil 2030 --kur 48 --firma \'Ornek Celik A.S.\' \\
                    --rapor cikti/rapor.html

  # Turkiye'de karbon odemesi yapilmis ise (fiyat, miktar degil)
  Rscript hesapla.R --cn 72081000 --miktar 250000 --yil 2030 \\
                    --odenen-karbon-fiyati 12.5 --sertifika-referans-fiyati 80

NOT
  Referans degerlerin her biri kaynagini tasir ve ciktida gosterilir.
  Kaynak belgeler data-raw/mevzuat/ altindadir.
  Henuz dogrulanmamis degerler ciktida acikca isaretlenir.
  Cikan sayilar yatirim veya beyan karari icin tek basina yeterli degildir.

")
}

# --- Argüman ayristirma -----------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0 || "--yardim" %in% args || "--help" %in% args) {
  yardim()
  quit(status = 0)
}

if ("--urunler" %in% args) {
  u <- cbam_products()
  b <- cbam_benchmarks()
  cat(sprintf("\nReferans veri paketi: %s\n", cbam_data_version()))
  cat(sprintf("Benchmark tablosu   : %d CN kodu (resmi, dogrulandi)\n\n",
              nrow(b)))
  bicim <- function(v) if (is.na(v)) "-" else sprintf("%.3f", v)
  cat(sprintf("  %-16s %-30s %-10s %8s %8s %8s\n",
              "KOD", "URUN", "CN", "YOGUNL.", "BM(A)", "BM(B)"))
  cat("  ", strrep("-", 86), "\n", sep = "")
  sektor_onceki <- ""
  for (k in seq_len(nrow(u))) {
    if (u$sektor[k] != sektor_onceki) {
      cat(sprintf("  [%s]\n", toupper(u$sektor[k])))
      sektor_onceki <- u$sektor[k]
    }
    j <- match(u$cn_kodu[k], b$cn_kodu)
    cat(sprintf("  %-16s %-30s %-10s %8s %8s %8s\n",
                u$urun_kodu[k], u$urun_adi[k], u$cn_kodu[k],
                bicim(u$varsayilan_yogunluk[k]),
                if (is.na(j)) "-" else bicim(b$bm_column_a[j]),
                if (is.na(j)) "-" else bicim(b$bm_column_b[j])))
  }
  hazir <- sum(!is.na(u$varsayilan_yogunluk))
  cat("\n  Benchmark'lar : CBAM Benchmarks tablosu (resmi)\n")
  cat(sprintf("  Yogunluklar   : Default Values Act, Turkiye (%d/%d urunde var)\n",
              hazir, nrow(u)))
  cat("\n  Varsayilan yogunluklar mevzuatin ongordugu degerlerdir ve bilerek\n")
  cat("  yuksek secilir. Kendi olctugunuz degeri --yogunluk ile verirseniz\n")
  cat("  maliyetiniz buyuk ihtimalle duser.\n")
  cat("\n  Urununuz listede yoksa CN kodunuzla dogrudan hesaplayin:\n")
  cat("    Rscript hesapla.R --cn <kod> --miktar <ton>\n\n")
  quit(status = 0)
}

bayraklar <- c("--dolayli-dahil", "--kesin")
opt <- list()
i <- 1
while (i <= length(args)) {
  a <- args[i]
  if (!startsWith(a, "--")) {
    cat(sprintf("HATA: beklenmeyen girdi '%s'. --yardim ile secenekleri gorun.\n", a))
    quit(status = 1)
  }
  anahtar <- substring(a, 3)
  if (a %in% bayraklar) {
    opt[[anahtar]] <- TRUE
    i <- i + 1
  } else {
    if (i + 1 > length(args)) {
      cat(sprintf("HATA: '%s' bir deger bekliyor.\n", a))
      quit(status = 1)
    }
    opt[[anahtar]] <- args[i + 1]
    i <- i + 2
  }
}

sayi_metin <- function(anahtar, varsayilan = NULL) {
  if (is.null(opt[[anahtar]])) return(varsayilan)
  trimws(opt[[anahtar]])
}

sayi <- function(anahtar, varsayilan = NULL) {
  if (is.null(opt[[anahtar]])) return(varsayilan)
  v <- suppressWarnings(as.numeric(opt[[anahtar]]))
  if (is.na(v)) {
    cat(sprintf("HATA: --%s sayisal olmali, '%s' verildi.\n",
                anahtar, opt[[anahtar]]))
    quit(status = 1)
  }
  v
}

# --- Girdi dogrulama --------------------------------------------------------
miktar <- sayi("miktar")
if (is.null(miktar)) {
  cat("HATA: --miktar zorunlu. --yardim ile ornekleri gorun.\n")
  quit(status = 1)
}

yogunluk  <- sayi("yogunluk")
benchmark <- sayi("benchmark")
sacilim   <- sayi("sacilim")
referans  <- NULL

sutun <- if (is.null(opt[["sutun"]])) "B" else toupper(trimws(opt[["sutun"]]))
if (!sutun %in% c("A", "B")) {
  cat("HATA: --sutun 'A' ya da 'B' olmali. --yardim ile aciklamayi gorun.\n")
  quit(status = 1)
}

hata_ver <- function(e) {
  cat(sprintf("HATA: %s\n", conditionMessage(e)))
  quit(status = 1)
}

birim <- NULL
yogunluk_etiketi <- "dogrudan"

if (!is.null(opt[["cn"]])) {
  # CN kodu yolu: benchmark resmi tablodan gelir, yogunlugu kullanici verir.
  bm <- tryCatch(cbam_benchmark_by_cn(opt[["cn"]], sutun), error = hata_ver)
  if (is.null(benchmark)) benchmark <- bm$benchmark
  birim <- bm$birim

  cat(sprintf("\nCN %s | %s\n", bm$cn_kodu, bm$aciklama))
  cat(sprintf("Benchmark Column %s = %s tCO2e/ton | Kaynak: %s\n",
              bm$sutun, fmt_num(bm$benchmark, 3), bm$kaynak))

  # Yogunluk verilmediyse mevzuatin varsayilan degerini kullan. Bu bir
  # tahmin degil, Default Values Act'in ongordugu degerdir - ve bilerek
  # muhafazakar secilmistir, cunku olcmemeyi odullendirmemek icin oyledir.
  if (is.null(yogunluk)) {
    dv <- cbam_default_intensity(opt[["cn"]], sayi_metin("ulke", "Turkiye"))
    if (is.null(dv)) {
      cat("\nHATA: bu CN kodu icin varsayilan yogunluk tablosunda kayit yok.\n")
      cat("      --yogunluk ile kendi tesis verinizi verin.\n")
      quit(status = 1)
    }
    # Dolayli emisyon yalnizca Ek I'de olup Ek II'de olmayan mallarda
    # sayilir (cimento, gubre, sinter - bkz. D6). Bunu ayri bir listeden
    # degil verinin kendisinden okuyoruz: Komisyon, dolayli emisyonun
    # sayilmadigi bir mal icin dolayli varsayilan deger yayimlamaz.
    dolayli_var <- !is.na(dv$dolayli)
    yogunluk <- if (dolayli_var) dv$toplam else dv$dogrudan
    yogunluk_etiketi <- if (dolayli_var) "dogrudan + dolayli" else "dogrudan"

    if (dolayli_var) {
      cat(sprintf("Varsayilan yogunluk = %s tCO2e/ton (%s, TOPLAM)\n",
                  fmt_num(dv$toplam, 3), dv$ulke))
      cat(sprintf("  dogrudan %s + dolayli %s\n",
                  fmt_num(dv$dogrudan, 3), fmt_num(dv$dolayli, 3)))
      cat("  Bu sektorde dolayli (elektrik) emisyon CBAM kapsamindadir.\n")
    } else {
      cat(sprintf("Varsayilan yogunluk = %s tCO2e/ton (%s, dogrudan)\n",
                  fmt_num(dv$dogrudan, 3), dv$ulke))
      cat("  Bu sektorde dolayli emisyon CBAM kapsami disindadir (Ek II).\n")
    }
    cat(sprintf("  Kaynak: %s | CN %s (%s eslesme)\n",
                dv$kaynak, dv$cn_kodu, dv$eslesme))
    cat("  !! Bu mevzuatin VARSAYILAN degeridir, tesisinizin degeri degildir.\n")
    cat("     Varsayilanlar bilerek yuksek secilir. Kendi olctugunuz degeri\n")
    cat("     --yogunluk ile verirseniz maliyetiniz buyuk ihtimalle duser.\n")
  }
} else if (!is.null(opt[["urun"]])) {
  referans <- tryCatch(
    cbam_product(tolower(trimws(opt[["urun"]])), sutun),
    error = function(e) {
      cat(sprintf("HATA: %s\n", conditionMessage(e)))
      cat("      --urunler ile mevcut kodlari listeleyin.\n")
      quit(status = 1)
    }
  )
  # Kullanicinin verdigi deger her zaman referans degerin onune gecer:
  # tesis verisi sektor ortalamasindan iyidir.
  if (is.null(yogunluk))  yogunluk  <- referans$varsayilan_yogunluk
  if (is.null(benchmark)) benchmark <- referans$benchmark
  if (is.null(sacilim))   sacilim   <- referans$varsayilan_sacilim
  birim <- tryCatch(cbam_benchmark_by_cn(referans$cn_kodu, sutun)$birim,
                    error = function(e) NULL)
}

if (is.null(yogunluk) || is.null(benchmark)) {
  cat("HATA: benchmark icin --cn, --urun ya da --benchmark verin;\n")
  cat("      emisyon yogunlugu icin --yogunluk verin.\n")
  cat("      --urunler ile hazir tanimlari, --yardim ile ornekleri gorun.\n")
  quit(status = 1)
}
if (is.null(sacilim)) sacilim <- 0.20

# --- Hesap ------------------------------------------------------------------
# Motor katmani hatalari kullaniciya R yigin izi olarak degil, tek satirlik
# anlasilir mesaj olarak gosterilir.
sonuc <- tryCatch(
  cbam_estimate(
    quantity           = miktar,
    ei_direct          = yogunluk,
    benchmark          = benchmark,
    year               = sayi("yil", 2026),
    carbon_price       = sayi("karbon-fiyati", 80),
    fx_rate            = sayi("kur", 1),
    carbon_price_paid    = sayi("odenen-karbon-fiyati", 0),
    cbam_reference_price = sayi("sertifika-referans-fiyati", NULL),
    ei_indirect        = sayi("dolayli", 0),
    include_indirect   = isTRUE(opt[["dolayli-dahil"]]),
    uncertainty        = !isTRUE(opt[["kesin"]]),
    theta_sdlog        = sacilim,
    base_year          = sayi("baz-yil", 2026),
    n_sims             = sayi("simulasyon", 50000),
    seed               = sayi("tohum", 2026),
    reference          = referans,
    functional_unit    = birim,
    ei_label           = yogunluk_etiketi
  ),
  error = function(e) {
    cat(sprintf("HATA: %s\n", conditionMessage(e)))
    cat("      --yardim ile secenekleri ve ornekleri gorun.\n")
    quit(status = 1)
  }
)

print(sonuc)

if (!is.null(opt[["rapor"]])) {
  yol <- tryCatch(
    cbam_rapor(sonuc, opt[["rapor"]], firma = opt[["firma"]]),
    error = function(e) {
      cat(sprintf("HATA: rapor uretilemedi - %s\n", conditionMessage(e)))
      quit(status = 1)
    }
  )
  cat(sprintf("Rapor yazildi: %s\n", normalizePath(yol, winslash = "/")))
  cat("Tarayicida acip PDF olarak yazdirabilirsiniz.\n\n")
}

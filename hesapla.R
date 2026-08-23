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

  ve asagidakilerden biri:
  --urun <kod>            Referans tablosundan urun (yogunluk + benchmark
                          otomatik gelir). Kodlar icin: --urunler
  --yogunluk <tCO2e/ton>  Kendi dogrudan emisyon yogunlugunuz
  --benchmark <tCO2e/ton>   ile birlikte AB ETS urun benchmark'i

  --urun verip ustune --yogunluk yazarsaniz, kendi degeriniz referans
  degerin yerine gecer. Tesis verisi her zaman sektor ortalamasini yener.

ISTEGE BAGLI
  --yil <yil>             Yukumluluk yili           (varsayilan: 2026)
  --karbon-fiyati <EUR>   EU ETS fiyati             (varsayilan: 80)
  --kur <TRY/EUR>         Doviz kuru                (varsayilan: 1, yalniz EUR)
  --mensede-odenen <t>    Turkiye'de odenmis karbon (varsayilan: 0)
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
  # Entegre celik tesisi, 250 bin ton, 2030 yili
  Rscript hesapla.R --urun celik-bof --miktar 250000 --yil 2030 --kur 48

  # Birincil aluminyum
  Rscript hesapla.R --urun alu-birincil --miktar 15000 --yil 2030 --kur 48

  # Kendi tesis verinizle
  Rscript hesapla.R --miktar 120000 --yogunluk 1.72 --benchmark 1.288 \\
                    --yil 2030 --karbon-fiyati 85 --kur 48

  # Paylasilabilir HTML rapor
  Rscript hesapla.R --urun celik-bof --miktar 250000 --yil 2030 --kur 48 \\
                    --firma \'Ornek Celik A.S.\' --rapor cikti/rapor.html

  # Turkiye'de karbon odemesi yapilmis ise
  Rscript hesapla.R --urun celik-bof --miktar 250000 --yil 2030 \\
                    --mensede-odenen 40000

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
  cat(sprintf("\nReferans veri paketi: %s\n\n", cbam_data_version()))
  bicim <- function(v) if (is.na(v)) "-" else sprintf("%.3f", v)
  cat(sprintf("  %-18s %-32s %9s %9s  %s\n",
              "KOD", "URUN", "YOGUNLUK", "BENCHMARK", "DURUM"))
  cat("  ", strrep("-", 84), "\n", sep = "")
  sektor_onceki <- ""
  for (k in seq_len(nrow(u))) {
    if (u$sektor[k] != sektor_onceki) {
      cat(sprintf("  [%s]\n", toupper(u$sektor[k])))
      sektor_onceki <- u$sektor[k]
    }
    j <- match(u$urun_kodu[k], b$urun_kodu)
    cat(sprintf("  %-18s %-32s %9s %9s  %s\n",
                u$urun_kodu[k], u$urun_adi[k],
                bicim(u$varsayilan_yogunluk[k]),
                if (is.na(j)) "-" else bicim(b$benchmark_tco2e_ton[j]),
                u$durum[k]))
  }
  hazir <- sum(!is.na(u$varsayilan_yogunluk))
  cat(sprintf("\n  %d urunden %d tanesinin degeri girilmis, %d tanesi iskelet.\n",
              nrow(u), hazir, nrow(u) - hazir))
  cat("  Iskelet urunler icin --yogunluk ve --benchmark elle verilmeli.\n")
  cat("  Girilmis degerler sektor tahminidir; kendi tesis verinizi\n")
  cat("  --yogunluk ile verirseniz o kullanilir.\n\n")
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

if (!is.null(opt[["urun"]])) {
  referans <- tryCatch(
    cbam_product(tolower(trimws(opt[["urun"]]))),
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
}

if (is.null(yogunluk) || is.null(benchmark)) {
  cat("HATA: --urun verin ya da --yogunluk ile --benchmark degerlerini\n")
  cat("      birlikte girin. --urunler ile mevcut kodlari gorebilirsiniz.\n")
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
    carbon_paid_origin = sayi("mensede-odenen", 0),
    ei_indirect        = sayi("dolayli", 0),
    include_indirect   = isTRUE(opt[["dolayli-dahil"]]),
    uncertainty        = !isTRUE(opt[["kesin"]]),
    theta_sdlog        = sacilim,
    base_year          = sayi("baz-yil", 2026),
    n_sims             = sayi("simulasyon", 50000),
    seed               = sayi("tohum", 2026),
    reference          = referans
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

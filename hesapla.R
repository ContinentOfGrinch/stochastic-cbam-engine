#!/usr/bin/env Rscript
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

# --- Onceden tanimli uretim rotalari ----------------------------------------
# DIKKAT: Bu degerler gosterim amacli sektor ortalamalaridir, resmi deger
# degildir. Kendi tesis verinizi --yogunluk ve --benchmark ile verin.
ROTALAR <- list(
  eaf = list(
    ad        = "Elektrik Ark Ocagi (EAF)",
    yogunluk  = 0.25,
    benchmark = 0.215,
    sacilim   = 0.30
  ),
  bof = list(
    ad        = "Entegre Tesis (BF-BOF)",
    yogunluk  = 1.95,
    benchmark = 1.288,
    sacilim   = 0.20
  )
)

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
  --rota <eaf|bof>        Hazir uretim rotasi (yogunluk + benchmark otomatik)
  --yogunluk <tCO2e/ton>  Kendi dogrudan emisyon yogunlugunuz
  --benchmark <tCO2e/ton>   ile birlikte AB ETS urun benchmark'i

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
  --yardim                Bu metni goster

ORNEKLER
  # Entegre tesis, 250 bin ton, 2030 yili
  Rscript hesapla.R --rota bof --miktar 250000 --yil 2030 --kur 48

  # Kendi tesis verinizle
  Rscript hesapla.R --miktar 120000 --yogunluk 1.72 --benchmark 1.288 \\
                    --yil 2030 --karbon-fiyati 85 --kur 48

  # Turkiye'de karbon odemesi yapilmis ise
  Rscript hesapla.R --rota bof --miktar 250000 --yil 2030 \\
                    --mensede-odenen 40000

NOT
  Hazir rota degerleri sektor ortalamasidir, resmi deger degildir.
  Gercek analiz icin kendi tesis verinizi kullanin.
  Cikan sayilar yatirim veya beyan karari icin tek basina yeterli degildir.

")
}

# --- Argüman ayristirma -----------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0 || "--yardim" %in% args || "--help" %in% args) {
  yardim()
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
rota_ad   <- NULL

if (!is.null(opt[["rota"]])) {
  r <- tolower(opt[["rota"]])
  if (is.null(ROTALAR[[r]])) {
    cat(sprintf("HATA: bilinmeyen rota '%s'. Secenekler: %s\n",
                opt[["rota"]], paste(names(ROTALAR), collapse = ", ")))
    quit(status = 1)
  }
  rota      <- ROTALAR[[r]]
  rota_ad   <- rota$ad
  if (is.null(yogunluk))  yogunluk  <- rota$yogunluk
  if (is.null(benchmark)) benchmark <- rota$benchmark
  if (is.null(sacilim))   sacilim   <- rota$sacilim
}

if (is.null(yogunluk) || is.null(benchmark)) {
  cat("HATA: --rota verin ya da --yogunluk ile --benchmark degerlerini birlikte girin.\n")
  cat("      --yardim ile ornekleri gorun.\n")
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
    seed               = sayi("tohum", 2026)
  ),
  error = function(e) {
    cat(sprintf("HATA: %s\n", conditionMessage(e)))
    cat("      --yardim ile secenekleri ve ornekleri gorun.\n")
    quit(status = 1)
  }
)

if (!is.null(rota_ad)) {
  cat(sprintf("\nRota: %s  (hazir degerler - resmi deger degildir)\n", rota_ad))
}
print(sonuc)

#  Referans Veri Katmani (Katman 0)
#
#  data/ altindaki islenmis referans tablolarini okur. Tablolarin tamami
#  data-raw/mevzuat/ icindeki resmi belgelerden elle aktarilmistir ve her
#  satir kendi kaynagini tasir (kaynak_belge + kaynak_yeri).
#
#  Tasarim kurallari:
#    - CSV kullanilir, .rda degil: git'te diff'lenir, GitHub'da okunur,
#      R olmadan da dogrulanabilir. Seffaflik misyonunun geregi.
#    - Yalnizca base R. Calisma zamaninda hicbir harici pakete bagli degil.
#    - Dogrulanmamis her deger yuksek sesle isaretlenir. Sessizce resmi
#      gorunen bir yer tutucu, bu projenin yapabilecegi en kotu hata olur.

CBAM_DATA_DIR <- "data"

#' Referans veri dizinini bul
#'
#' Betikler proje kokunden calistirilir; yine de bir ust dizine bakarak
#' analysis/ icinden calistirmayi da tolere eder.
#'
#' @return Veri dizininin yolu.
cbam_data_path <- function() {
  aday <- c(CBAM_DATA_DIR, file.path("..", CBAM_DATA_DIR))
  for (p in aday) {
    if (dir.exists(p) && file.exists(file.path(p, "urunler.csv"))) {
      return(p)
    }
  }
  stop("Referans veri bulunamadi. Proje kokunden calistirdiginizdan emin olun.")
}

#' Kullanilan referans veri paketinin surumu
#'
#' @return Surum etiketi (ornek: "params-2026.08").
cbam_data_version <- function() {
  f <- file.path(cbam_data_path(), "VERSION")
  if (!file.exists(f)) return("bilinmiyor")
  trimws(readLines(f, warn = FALSE)[1])
}

#' Referans tablosunu oku
#'
#' @param ad Dosya adi (uzantisiz).
#' @return data.frame.
cbam_read_table <- function(ad) {
  f <- file.path(cbam_data_path(), paste0(ad, ".csv"))
  if (!file.exists(f)) {
    stop(sprintf("Referans tablosu bulunamadi: %s", f))
  }
  utils::read.csv(f, stringsAsFactors = FALSE, colClasses = "character")
}

#' Urun katalogu
#'
#' @return Urun kodu, adi, sektoru, varsayilan yogunlugu ve kaynak bilgisini
#'   iceren data.frame.
cbam_products <- function() {
  d <- cbam_read_table("urunler")
  d$varsayilan_yogunluk <- as.numeric(d$varsayilan_yogunluk)
  d$varsayilan_sacilim  <- as.numeric(d$varsayilan_sacilim)
  d
}

#' Benchmark tablosu
#'
#' @return Urun kodu bazinda AB ETS benchmark degerleri ve kaynaklari.
cbam_benchmarks <- function() {
  d <- cbam_read_table("benchmarks")
  d$benchmark_tco2e_ton <- as.numeric(d$benchmark_tco2e_ton)
  d
}

#' Tek bir urunun tum referans bilgisi
#'
#' Urun katalogunu ve benchmark tablosunu birlestirir.
#'
#' @param urun_kodu Urun kodu (ornek: "alu-birincil").
#' @return Tek satirlik liste: yogunluk, benchmark, kapsam ve kaynaklar.
cbam_product <- function(urun_kodu) {
  urunler <- cbam_products()
  i <- match(urun_kodu, urunler$urun_kodu)
  if (is.na(i)) {
    stop(sprintf("Bilinmeyen urun kodu '%s'. Mevcut kodlar: %s",
                 urun_kodu, paste(urunler$urun_kodu, collapse = ", ")))
  }
  u <- urunler[i, ]

  bm <- cbam_benchmarks()
  j <- match(urun_kodu, bm$urun_kodu)
  if (is.na(j)) {
    stop(sprintf("'%s' icin benchmark tanimli degil (data/benchmarks.csv).",
                 urun_kodu))
  }
  b <- bm[j, ]

  # Iskelet satirlar (henuz deger girilmemis urunler) sessizce NA ile
  # hesaba girmemeli. Kullanici ya degeri girmeli ya da kendi verisini vermeli.
  eksik <- c(
    if (is.na(u$varsayilan_yogunluk)) "varsayilan yogunluk",
    if (is.na(b$benchmark_tco2e_ton)) "benchmark"
  )
  if (length(eksik) > 0) {
    stop(sprintf(paste0(
      "'%s' icin %s henuz girilmemis.\n",
      "  Bu urun referans tablosunda yer tutucu olarak duruyor; degerleri\n",
      "  resmi belgeden girin (bkz. data-raw/mevzuat/MEVZUAT_DOGRULAMA.md)\n",
      "  ya da --yogunluk ve --benchmark ile kendi verinizi verin."),
      urun_kodu, paste(eksik, collapse = " ve ")))
  }

  list(
    urun_kodu           = u$urun_kodu,
    urun_adi            = u$urun_adi,
    sektor              = u$sektor,
    cn_kodlari          = u$cn_kodlari,
    dolayli_kapsamda    = tolower(trimws(u$dolayli_kapsamda)) %in%
                            c("evet", "yes", "true"),
    varsayilan_yogunluk = u$varsayilan_yogunluk,
    varsayilan_sacilim  = u$varsayilan_sacilim,
    benchmark           = b$benchmark_tco2e_ton,
    yogunluk_kaynak     = cbam_kaynak_metni(u$kaynak_belge, u$kaynak_yeri),
    benchmark_kaynak    = cbam_kaynak_metni(b$kaynak_belge, b$kaynak_yeri),
    benchmark_gecerlilik = cbam_gecerlilik_metni(b$gecerli_baslangic,
                                                 b$gecerli_bitis),
    dogrulandi          = identical(trimws(u$durum), "dogrulandi") &&
                            identical(trimws(b$durum), "dogrulandi"),
    urun_durum          = trimws(u$durum),
    benchmark_durum     = trimws(b$durum),
    not                 = u$not,
    veri_surumu         = cbam_data_version()
  )
}

#' Kaynak referansini tek satirlik metne cevir
#'
#' @param belge Kaynak belge kimligi.
#' @param yer Belge icindeki yer (madde, ek, satir).
#' @return Okunabilir kaynak metni; kaynak yoksa acik uyari.
cbam_kaynak_metni <- function(belge, yer) {
  belge <- trimws(as.character(belge))
  yer   <- trimws(as.character(yer))
  if (is.na(belge) || belge == "") {
    return("KAYNAK GIRILMEDI")
  }
  if (is.na(yer) || yer == "") {
    return(belge)
  }
  paste0(belge, ", ", yer)
}

#' Gecerlilik araligini metne cevir
#'
#' @param baslangic Baslangic tarihi.
#' @param bitis Bitis tarihi.
#' @return Okunabilir aralik metni ya da bos karakter.
cbam_gecerlilik_metni <- function(baslangic, bitis) {
  baslangic <- trimws(as.character(baslangic))
  bitis     <- trimws(as.character(bitis))
  if (is.na(baslangic) || baslangic == "") return("")
  if (is.na(bitis) || bitis == "") return(baslangic)
  paste(baslangic, "-", bitis)
}

#' Dogrulanmamis veri uyarisi
#'
#' Yer tutucu degerlerin resmi deger sanilmasini onler.
#'
#' @param p \code{cbam_product()} ciktisi.
#' @return Yazdirilacak uyari satirlari; veri dogrulanmissa NULL.
cbam_dogrulama_uyarisi <- function(p) {
  if (isTRUE(p$dogrulandi)) return(NULL)
  c(
    "!! DIKKAT: Bu hesapta DOGRULANMAMIS referans degerleri kullanildi.",
    sprintf("   Urun kaydi     : %s", p$urun_durum),
    sprintf("   Benchmark kaydi: %s", p$benchmark_durum),
    "   Degerler sektor tahminidir, resmi AB degeri DEGILDIR.",
    "   Resmi degerler icin bkz. data-raw/mevzuat/KAYNAKLAR.md",
    "   Bu ciktiyi beyan veya yatirim karari icin kullanmayin."
  )
}

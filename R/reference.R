#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

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
  d$varsayilan_sacilim <- as.numeric(d$varsayilan_sacilim)
  # Emisyon yogunlugu bu tabloda tutulmaz; mevzuatin varsayilan deger
  # tablosundan CN kodu uzerinden gelir. Bkz. cbam_default_intensity().
  d$varsayilan_yogunluk <- vapply(d$cn_kodu, function(cn) {
    dv <- cbam_default_intensity(cn)
    if (is.null(dv)) NA_real_ else dv$dogrudan
  }, numeric(1), USE.NAMES = FALSE)
  d
}

#' CBAM benchmark tablosu (CN kodu bazinda)
#'
#' Kaynak: Free Allocation Adjustment Act (CIR (EU) 2025/2620), Ek nokta 5;
#' Komisyon'un yayimladigi "CBAM Benchmarks" tablosu (6 Subat 2026).
#'
#' Iki sutun vardir ve secim hesabi ciddi sekilde degistirir:
#'   Column A : TEK bir uretim sureci icin benchmark. Yalnizca son islemi
#'              yapan tesis (ornek: sadece haddeleme) icin gecerlidir.
#'   Column B : TUM uretim zinciri icin benchmark. Cevherden urune kadar
#'              kendi ureten entegre tesis icin gecerlidir.
#'
#' Ornek (CN 72081000, sicak haddelenmis rulo): Column A = 0,044;
#' Column B = 1,370. Yanlis sutun 30 kat hata demektir.
#'
#' @return CN kodu bazinda benchmark degerleri ve kaynaklari.
cbam_benchmarks <- function() {
  d <- cbam_read_table("benchmarks")
  d$bm_column_a <- as.numeric(d$bm_column_a)
  d$bm_column_b <- as.numeric(d$bm_column_b)
  d
}

#' CN koduna gore benchmark degeri
#'
#' @param cn_kodu CN kodu (metin ya da sayi; bosluklar temizlenir).
#' @param sutun \code{"B"} (tum uretim zinciri, varsayilan) ya da
#'   \code{"A"} (tek uretim sureci).
#' @return Tek satirlik liste: deger, aciklama, sektor, rota gostergesi, kaynak.
cbam_benchmark_by_cn <- function(cn_kodu, sutun = "B") {
  sutun <- toupper(trimws(sutun))
  if (!sutun %in% c("A", "B")) {
    stop("sutun 'A' (tek uretim sureci) ya da 'B' (tum zincir) olmali.")
  }
  cn <- gsub("[^0-9]", "", as.character(cn_kodu))
  if (!nzchar(cn)) {
    stop("cn_kodu bos olamaz.")
  }
  bm <- cbam_benchmarks()
  i <- match(cn, bm$cn_kodu)
  if (is.na(i)) {
    stop(sprintf(paste0(
      "CN kodu '%s' CBAM benchmark tablosunda yok.\n",
      "  Urununuz CBAM kapsaminda olmayabilir, ya da kodu kontrol edin.\n",
      "  Tabloda %d CN kodu tanimli (kaynak: %s)."),
      cn, nrow(bm), bm$kaynak_belge[1]))
  }
  b <- bm[i, ]
  list(
    cn_kodu   = b$cn_kodu,
    aciklama  = b$aciklama,
    sektor    = b$sektor,
    birim     = cbam_fonksiyonel_birim(b$sektor),
    sutun     = sutun,
    benchmark = if (sutun == "A") b$bm_column_a else b$bm_column_b,
    rota      = if (sutun == "A") b$rota_a else b$rota_b,
    kaynak    = cbam_kaynak_metni(b$kaynak_belge, b$kaynak_yeri),
    durum     = trimws(b$durum)
  )
}

#' Varsayilan emisyon yogunlugu tablosu
#'
#' Kaynak: Default Values Act, CIR (EU) 2025/2621 - Komisyon'un yayimladigi
#' ulke bazli varsayilan deger tablosu (6 Agustos 2026 guncellemesi).
#'
#' Bu degerler mevzuatin ongordugu varsayilanlardir. Kendi olctugunuz tesis
#' degeri her zaman bunlarin onune gecmelidir; varsayilanlar bilerek muhafazakar
#' (yuksek) secilir, cunku olcmemeyi odullendirmemek icin oyle tasarlanmislardir.
#'
#' @return CN kodu bazinda dogrudan/dolayli/toplam varsayilan degerler.
cbam_default_intensities <- function() {
  d <- cbam_read_table("varsayilan_yogunluk")
  # Tabloda deger girilmemis hucreler var (Komisyon o ürün icin varsayilan
  # yayimlamamis). Bos hucre NA olmali; as.numeric'in uyari uretmesi
  # kullaniciya gosterilecek bir sey degil, beklenen durum.
  sayiya <- function(x) {
    x <- trimws(as.character(x))
    x[!nzchar(x)] <- NA_character_
    suppressWarnings(as.numeric(x))
  }
  d$dogrudan <- sayiya(d$dogrudan)
  d$dolayli  <- sayiya(d$dolayli)
  d$toplam   <- sayiya(d$toplam)
  d
}

#' CN koduna gore varsayilan emisyon yogunlugu
#'
#' Varsayilan deger tablosu bazen 4 haneli, bazen 8 veya 10 haneli CN kodu
#' kullanir. Bu yuzden en uzun onek eslesmesi aranir: 72081000 sorulursa
#' once tam kod, yoksa 720810, yoksa 7208 denenir.
#'
#' @param cn_kodu CN kodu.
#' @param ulke Ulke sayfasi (varsayilan "Turkiye").
#' @return Bulunursa liste, bulunamazsa \code{NULL}.
cbam_default_intensity <- function(cn_kodu, ulke = "Turkiye") {
  cn <- gsub("[^0-9]", "", as.character(cn_kodu))
  if (!nzchar(cn)) return(NULL)

  dv <- cbam_default_intensities()
  dv <- dv[dv$ulke == ulke & !is.na(dv$dogrudan), ]
  if (nrow(dv) == 0) return(NULL)

  # En uzun onekten en kisaya dogru ara.
  for (n in seq(nchar(cn), 2)) {
    aday <- substr(cn, 1, n)
    i <- match(aday, dv$cn_kodu)
    if (!is.na(i)) {
      r <- dv[i, ]
      return(list(
        cn_kodu   = r$cn_kodu,
        eslesme   = if (identical(r$cn_kodu, cn)) "tam" else "onek",
        ulke      = r$ulke,
        sektor    = r$sektor,
        aciklama  = r$aciklama,
        dogrudan  = r$dogrudan,
        dolayli   = r$dolayli,
        toplam    = r$toplam,
        rota      = r$rota,
        kaynak    = cbam_kaynak_metni(r$kaynak_belge, r$kaynak_yeri),
        durum     = trimws(r$durum)
      ))
    }
  }
  NULL
}

#' Sektorun fonksiyonel birimi
#'
#' Cimento ve gubrede operatorun emisyonu IZLEYIP RAPORLADIGI birim ton urun
#' degildir: cimentoda ton klinker, gubrede kg azot (Rehber No. 3, s.20).
#'
#' ANCAK yukumluluk hesabi ton urun uzerinden yapilir. Rehber No. 1, s.15:
#'   "SEE values must be expressed per tonne ... while the value per
#'    functional unit (where different from tonnes of good) is to be
#'    transformed in value per tonne of good applying the formulas for
#'    specific compositions in Annex III of the Methodology Act."
#'
#' Nitekim hem benchmark tablosu hem varsayilan deger tablosu ton basina
#' degerler tasir. Dolayisiyla bu araca miktar TON URUN olarak girilir;
#' fonksiyonel birim, kendi emisyon verisi fonksiyonel birim cinsinden olan
#' kullaniciyi donusturme yukumlulugu konusunda uyarmak icin tutulur.
#'
#' @param sektor Benchmark tablosundaki sektor adi.
#' @return Liste: \code{birim} (izleme birimi) ve \code{standart} (mantiksal;
#'   izleme birimi ton urun ise TRUE).
cbam_fonksiyonel_birim <- function(sektor) {
  s <- tolower(trimws(as.character(sektor)))
  if (identical(s, "cement")) {
    return(list(birim = "ton klinker", standart = FALSE))
  }
  if (identical(s, "fertilisers")) {
    return(list(birim = "kg azot", standart = FALSE))
  }
  list(birim = "ton urun", standart = TRUE)
}

#' Tek bir urunun tum referans bilgisi
#'
#' Urun katalogunu ve benchmark tablosunu birlestirir.
#'
#' @param urun_kodu Urun kodu (ornek: "alu-ham").
#' @param sutun Benchmark sutunu: \code{"B"} tum uretim zinciri (varsayilan),
#'   \code{"A"} tek uretim sureci.
#' @return Tek satirlik liste: yogunluk, benchmark, kapsam ve kaynaklar.
cbam_product <- function(urun_kodu, sutun = "B") {
  urunler <- cbam_products()
  i <- match(urun_kodu, urunler$urun_kodu)
  if (is.na(i)) {
    stop(sprintf("Bilinmeyen urun kodu '%s'. Mevcut kodlar: %s",
                 urun_kodu, paste(urunler$urun_kodu, collapse = ", ")))
  }
  u <- urunler[i, ]
  b <- cbam_benchmark_by_cn(u$cn_kodu, sutun)

  # Yogunluk artik urun tablosunda tutulmuyor; mevzuatin varsayilan deger
  # tablosundan gelir. Kendi tahminimizi tasimak, resmi bir deger varken
  # savunulamazdi.
  dv <- cbam_default_intensity(u$cn_kodu)
  if (is.null(dv)) {
    stop(sprintf(paste0(
      "'%s' (CN %s) icin varsayilan yogunluk tablosunda kayit yok.\n",
      "  Benchmark resmi tablodan geliyor (%s), ama yogunluk yok.\n",
      "  --yogunluk ile kendi tesis verinizi verin."),
      urun_kodu, u$cn_kodu, fmt_num(b$benchmark, 3)))
  }

  list(
    urun_kodu           = u$urun_kodu,
    urun_adi            = u$urun_adi,
    sektor              = u$sektor,
    cn_kodu             = b$cn_kodu,
    cn_aciklama         = b$aciklama,
    benchmark_sutun     = b$sutun,
    dolayli_kapsamda    = tolower(trimws(u$dolayli_kapsamda)) %in%
                            c("evet", "yes", "true"),
    varsayilan_yogunluk = dv$dogrudan,
    varsayilan_sacilim  = u$varsayilan_sacilim,
    benchmark           = b$benchmark,
    yogunluk_kaynak     = sprintf("%s, CN %s", dv$kaynak, dv$cn_kodu),
    benchmark_kaynak    = sprintf("%s, CN %s, Column %s",
                                  b$kaynak, b$cn_kodu, b$sutun),
    benchmark_gecerlilik = "",
    # Benchmark artik resmi ve dogrulanmis; yogunluk hala sektor tahmini.
    # Bu yuzden satir bazinda degil, alan bazinda durum tutuluyor.
    benchmark_dogrulandi = identical(b$durum, "dogrulandi"),
    yogunluk_dogrulandi  = identical(dv$durum, "dogrulandi"),
    dogrulandi          = identical(dv$durum, "dogrulandi") &&
                            identical(b$durum, "dogrulandi"),
    urun_durum          = trimws(u$durum),
    benchmark_durum     = b$durum,
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
  satir <- "!! DIKKAT: Bu hesapta DOGRULANMAMIS deger kullanildi."
  if (isTRUE(p$benchmark_dogrulandi) && !isTRUE(p$yogunluk_dogrulandi)) {
    # En sik durum: benchmark resmi, yogunluk hala sektor tahmini.
    return(c(
      satir,
      "   Benchmark  : resmi AB tablosundan, DOGRULANDI.",
      "   Yogunluk   : sektor tahmini, DOGRULANMADI.",
      "   Kendi tesis verinizi --yogunluk ile verin; sonuc o zaman",
      "   tamamen resmi kaynaklara dayanir."
    ))
  }
  c(
    satir,
    sprintf("   Urun kaydi     : %s", p$urun_durum),
    sprintf("   Benchmark kaydi: %s", p$benchmark_durum),
    "   Degerler sektor tahminidir, resmi AB degeri DEGILDIR.",
    "   Resmi degerler icin bkz. data-raw/mevzuat/KAYNAKLAR.md",
    "   Bu ciktiyi beyan veya yatirim karari icin kullanmayin."
  )
}

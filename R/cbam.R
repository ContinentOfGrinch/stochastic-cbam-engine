#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

#  CBAM Yukumluluk Modulu
#
#  Yasal cerceve: Regulation (EU) 2023/956 (CBAM Tuzugu) ve tadilleri.
#  Bu modul E_CBAM (yasal olarak vergilendirilen emisyon) hesabini yapar;
#  tedarik zinciri genelindeki E_MRIO icin bkz. R/mrio.R.

#' CBAM kademeli gecis (phase-in) faktoru
#'
#' AB ETS ucretsiz tahsisatinin kademeli kaldirilmasini yansitir. 2026'da
#' yukumlulugun yalnizca %2,5'i dogar, 2034'te tamami dogar.
#'
#' @param year Takvim yili (tam sayi). Vektor verilebilir.
#' @return 0 ile 1 arasinda CBAM faktoru.
cbam_phase_in_factor <- function(year) {
  # Girdi dogrulamasi: tam sayi olmayan bir yil sessizce NA uretirse hata
  # tum hesaba yayilir ve fark edilmez. Erken ve acik sekilde reddedilir.
  if (!is.numeric(year) || length(year) == 0) {
    stop("year bos olmayan sayisal bir vektor olmali.")
  }
  if (anyNA(year)) {
    stop("year NA icermemeli.")
  }
  if (any(year != trunc(year))) {
    stop("year tam sayi olmali (ornek: 2030).")
  }

  schedule <- c(
    "2026" = 0.025, "2027" = 0.050, "2028" = 0.100,
    "2029" = 0.225, "2030" = 0.485, "2031" = 0.615,
    "2032" = 0.745, "2033" = 0.865, "2034" = 1.000
  )

  out <- numeric(length(year))       # year < 2026 -> 0 (yalnizca raporlama)
  out[year >= 2034] <- 1
  mid <- year >= 2026 & year < 2034
  out[mid] <- unname(schedule[as.character(year[mid])])
  out
}

#' Odenmesi gereken CBAM sertifikasi (tCO2e)
#'
#' Ithalatci, AB ureticisinin hala aldigi ucretsiz tahsisat kadar muaftir.
#' Bu muafiyet CBAM faktoru arttikca erir:
#'
#'     sertifika = gomulu_emisyon - benchmark * miktar * (1 - cbam_factor)
#'                 - mensede_odenen_karbon
#'
#' @param embedded Gomulu emisyon (tCO2e).
#' @param quantity Ihracat miktari (ton).
#' @param benchmark AB ETS urun benchmark'i (tCO2e / ton). Demir-celik sicak
#'   metal icin yaklasik 1,288 tCO2e/ton.
#' @param cbam_factor Kademeli gecis faktoru, bkz. \code{cbam_phase_in_factor()}.
#' @param carbon_paid_origin Mense ulkede fiilen odenmis karbon yukumlulugu (tCO2e).
#' @return Satin alinmasi gereken sertifika miktari (tCO2e), negatif olamaz.
certificates_due <- function(embedded,
                             quantity,
                             benchmark,
                             cbam_factor,
                             carbon_paid_origin = 0) {
  stopifnot(is.numeric(embedded), is.numeric(quantity), is.numeric(benchmark))
  if (any(cbam_factor < 0 | cbam_factor > 1, na.rm = TRUE)) {
    stop("cbam_factor 0 ile 1 arasinda olmali.")
  }
  free_allocation <- benchmark * quantity * (1 - cbam_factor)
  pmax(embedded - free_allocation - carbon_paid_origin, 0)
}

#' CBAM maliyeti (EUR ve yerel para)
#'
#' @param certificates Sertifika miktari (tCO2e).
#' @param carbon_price EU ETS sertifika fiyati (EUR / tCO2e).
#' @param fx_rate Doviz kuru (yerel para / EUR). Varsayilan 1 -> yalniz EUR.
#' @return \code{cost_eur} ve \code{cost_local} iceren liste.
cbam_cost <- function(certificates, carbon_price, fx_rate = 1) {
  stopifnot(is.numeric(certificates), is.numeric(carbon_price))
  if (any(carbon_price < 0, na.rm = TRUE)) {
    stop("carbon_price negatif olamaz.")
  }
  cost_eur <- certificates * carbon_price
  list(cost_eur = cost_eur, cost_local = cost_eur * fx_rate)
}

#' De minimis muafiyeti
#'
#' 2025 Omnibus duzenlemesi ile ithalatci basina yillik 50 tCO2e altindaki
#' gomulu emisyonlar CBAM yukumlulugunden muaftir.
#'
#' @param embedded Gomulu emisyon (tCO2e).
#' @param threshold Esik deger (tCO2e). Varsayilan 50.
#' @return Mantiksal vektor: TRUE ise muaf.
is_de_minimis <- function(embedded, threshold = 50) {
  embedded < threshold
}

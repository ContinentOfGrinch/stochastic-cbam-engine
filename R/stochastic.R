#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

#  Stokastik Surecler Modulu
#
#  CBAM maruziyetinin iki ana belirsizlik kaynagini modeller:
#    (1) EU ETS karbon fiyati volatilitesi
#    (2) Doviz kuru dalgalanmasi (TRY/EUR)
#
#  Her ikisi de Geometrik Brown Hareketi (GBM) ile modellenir. GBM secimi,
#  her iki serinin de pozitif tanimli olmasi ve log-getirilerinin yaklasik
#  normal davranmasi nedeniyledir.

#' Geometrik Brown Hareketi ile yol simulasyonu
#'
#' Kapali cozum kullanir:
#'     S_t = S_0 * exp((mu - sigma^2 / 2) * t + sigma * W_t)
#'
#' @param n_sims Simulasyon sayisi.
#' @param s0 Baslangic degeri.
#' @param mu Yillik surukleme (drift) orani.
#' @param sigma Yillik volatilite.
#' @param horizon Zaman ufku (yil). 0 verilirse belirsizlik yoktur ve s0
#'   aynen dondurulur; yukumluluk yili ile baz yilin ayni oldugu durum budur.
#' @return Uzunlugu n_sims olan, ufuk sonundaki deger vektoru.
simulate_gbm <- function(n_sims, s0, mu, sigma, horizon = 1) {
  stopifnot(n_sims > 0, s0 > 0, sigma >= 0, horizon >= 0)
  drift <- (mu - 0.5 * sigma^2) * horizon
  shock <- sigma * sqrt(horizon) * stats::rnorm(n_sims)
  s0 * exp(drift + shock)
}

#' Korele iki degiskenli sok uretimi
#'
#' Karbon fiyati ve doviz kuru bagimsiz degildir; enerji fiyati soklari her
#' ikisini de ayni yonde etkileyebilir. Cholesky ayrisimi ile korelasyon
#' yapisi korunur.
#'
#' @param n_sims Simulasyon sayisi.
#' @param rho Korelasyon katsayisi (-1, 1).
#' @return n_sims x 2 boyutlu, standart normal korele sok matrisi.
correlated_shocks <- function(n_sims, rho = 0) {
  if (rho <= -1 || rho >= 1) {
    stop("rho -1 ile 1 arasinda (haric) olmali.")
  }
  z1 <- stats::rnorm(n_sims)
  z2 <- stats::rnorm(n_sims)
  cbind(z1, rho * z1 + sqrt(1 - rho^2) * z2)
}

#' Korele karbon fiyati ve doviz kuru simulasyonu
#'
#' @param n_sims Simulasyon sayisi.
#' @param carbon_price_0 Baslangic EU ETS fiyati (EUR/tCO2e).
#' @param carbon_mu Karbon fiyati yillik suruklemesi.
#' @param carbon_sigma Karbon fiyati yillik volatilitesi.
#' @param fx_0 Baslangic kuru (TRY/EUR).
#' @param fx_mu Kur yillik suruklemesi.
#' @param fx_sigma Kur yillik volatilitesi.
#' @param rho Karbon fiyati ile kur arasindaki korelasyon.
#' @param inflation_tr Turkiye yillik enflasyon varsayimi.
#' @param inflation_eu Avro Alani yillik enflasyon varsayimi.
#' @param horizon Zaman ufku (yil). 0 -> belirsizlik yok, baslangic degerleri
#'   aynen dondurulur.
#' @return \code{carbon_price} ve \code{fx_rate} sutunlarini iceren data.frame.
simulate_market <- function(n_sims,
                            carbon_price_0,
                            carbon_mu = 0.02,
                            carbon_sigma = 0.35,
                            fx_0 = 1,
                            fx_mu = NULL,
                            fx_sigma = 0.18,
                            rho = 0.20,
                            inflation_tr = 0.25,
                            inflation_eu = 0.02,
                            horizon = 1) {
  stopifnot(horizon >= 0)

  # Kur suruklemesi elle verilen bir sayi degil, enflasyon farkindan
  # turetilir (goreli satin alma gucu paritesi):
  #
  #     beklenen nominal kur degisimi ~ TR enflasyonu - AB enflasyonu
  #
  # Onceki hali sabit %20 idi ve kaynaksizdi: sekiz yil bileşiklenince
  # 2034 icin ~238 TRY/EUR ima ediyordu. O bir tahmin degil, mekanik bir
  # ekstrapolasyon artefaktiydi. Simdi varsayim gorunur ve degistirilebilir.
  if (is.null(fx_mu)) {
    fx_mu <- log((1 + inflation_tr) / (1 + inflation_eu))
  }

  z <- correlated_shocks(n_sims, rho)

  carbon <- carbon_price_0 * exp(
    (carbon_mu - 0.5 * carbon_sigma^2) * horizon +
      carbon_sigma * sqrt(horizon) * z[, 1]
  )
  fx <- fx_0 * exp(
    (fx_mu - 0.5 * fx_sigma^2) * horizon +
      fx_sigma * sqrt(horizon) * z[, 2]
  )

  # Nominal TRY tutarlari, bugunun parasiyla karsilastirilabilir olsun diye
  # bu deflator ile bolunur. Sabit reel kur varsayiminda sonuc, bugunku
  # kurla hesaplanan tutara yakinsar - okunabilir olan da odur.
  data.frame(
    carbon_price = carbon,
    fx_rate      = fx,
    deflator_tr  = (1 + inflation_tr)^horizon
  )
}

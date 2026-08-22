#  Emisyon Yogunlugu Modulu
#
#  Sektorel makro emisyon yogunlugunu firma duzeyindeki heterojen teknoloji
#  katsayisi ile esneterek mikro duzey emisyon yogunlugu uretir:
#
#      EI_f = EI_s * theta_f
#
#  theta_f < 1  -> firma sektor ortalamasindan temiz (BAT'a yakin)
#  theta_f = 1  -> firma sektor ortalamasi teknolojide
#  theta_f > 1  -> firma sektor ortalamasindan kirli

#' Firma duzeyi emisyon yogunlugu
#'
#' @param ei_sector Sektor ortalama emisyon yogunlugu (tCO2e / ton urun).
#' @param theta_firm Teknoloji ayarlama katsayisi (boyutsuz, > 0).
#' @return Firmaya ozgu emisyon yogunlugu (tCO2e / ton urun).
firm_emission_intensity <- function(ei_sector, theta_firm) {
  stopifnot(is.numeric(ei_sector), is.numeric(theta_firm))
  if (any(ei_sector < 0, na.rm = TRUE)) {
    stop("ei_sector negatif olamaz.")
  }
  if (any(theta_firm <= 0, na.rm = TRUE)) {
    stop("theta_firm pozitif olmali.")
  }
  ei_sector * theta_firm
}

#' Gomulu emisyonlar (embedded emissions)
#'
#' CBAM kapsaminda beyan edilen gomulu emisyon: dogrudan (Scope 1) emisyonlar
#' artik elektrik kaynakli dolayli (Scope 2) emisyonlar. Tedarik zincirinin
#' tamamini kapsayan E_MRIO'dan farklidir - bkz. \code{total_emission_intensity()}.
#'
#' @param quantity Ihracat miktari (ton).
#' @param ei_direct Dogrudan emisyon yogunlugu (tCO2e / ton).
#' @param ei_indirect Dolayli (elektrik) emisyon yogunlugu (tCO2e / ton).
#' @param include_indirect Dolayli emisyonlar dahil edilsin mi? CBAM'de demir-celik
#'   icin gecis doneminde dolayli emisyonlar raporlanir ancak vergilendirilmez.
#' @return Toplam gomulu emisyon (tCO2e).
embedded_emissions <- function(quantity,
                               ei_direct,
                               ei_indirect = 0,
                               include_indirect = FALSE) {
  stopifnot(is.numeric(quantity), is.numeric(ei_direct))
  if (any(quantity < 0, na.rm = TRUE)) {
    stop("quantity negatif olamaz.")
  }
  ei <- if (isTRUE(include_indirect)) ei_direct + ei_indirect else ei_direct
  quantity * ei
}

#' Teknoloji katsayisi dagilimindan orneklem
#'
#' Firma duzeyi veri bulunmadiginda theta_f'nin sektor ici heterojenligini
#' lognormal dagilimla temsil eder. Lognormal secimi, emisyon yogunlugunun
#' pozitif ve saga carpik olmasi nedeniyledir (birkac cok kirli tesis, cok
#' sayida ortalamaya yakin tesis).
#'
#' @param n Orneklem buyuklugu.
#' @param meanlog Log-olcekte ortalama. Varsayilan 0 -> medyan theta = 1.
#' @param sdlog Log-olcekte standart sapma (sektor ici heterojenlik).
#' @return Uzunlugu n olan theta_f vektoru.
sample_theta <- function(n, meanlog = 0, sdlog = 0.25) {
  stopifnot(n > 0, sdlog >= 0)
  stats::rlnorm(n, meanlog = meanlog, sdlog = sdlog)
}

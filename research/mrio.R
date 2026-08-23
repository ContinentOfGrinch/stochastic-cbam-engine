#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

#  ARASTIRMA EKI - Cok Bolgeli Girdi-Cikti (MRIO) Modulu
#
#  ---------------------------------------------------------------------------
#  BU MODUL HESAP MAKINESININ PARCASI DEGILDIR.
#
#  CBAM faturasi hesabi (hesapla.R -> R/calculator.R -> R/cbam.R) bu dosyadaki
#  hicbir fonksiyonu cagirmaz. Buradaki fonksiyonlar isteğe bagli bir arastirma
#  eklentisidir; silinse hesap makinesi aynen calismaya devam eder.
#
#  Neden ayri bir klasorde: bu modulu anlamak icin girdi-cikti iktisadi bilmek
#  gerekir (teknik katsayi matrisi, Leontief tersi). Hesap makinesini anlamak
#  icinse carpma ve cikarma yeterlidir. Ikisini ayni rafta tutmak, araci
#  gereginden karmasik gosteriyordu.
#  ---------------------------------------------------------------------------
#
#  NE ISE YARAR
#
#  CBAM'in yasal tabani ile urunun gercek karbon ayak izi ayni sey degildir:
#    E_CBAM : yalnizca tesis duzeyinde dogrudan + elektrik emisyonlari
#             (mevzuatin vergilendirdigi taban)
#    E_MRIO : tedarik zincirinin tamamina yayilan ayak izi
#             (ekonomik olarak gercek taban)
#
#  Aradaki fark, kapsam genislemelerine karsi "gizli maruziyeti" olcer.
#  Bugun vergilendirilmeyen ama yarin vergilendirilebilecek emisyon budur.
#
#  DURUM: Fonksiyonlar yazildi ve test edildi, ancak gercek EXIOBASE/WIOD
#  matrisleri henuz baglanmadi. Kapsam farkini uretmek icin data-raw/exiobase/
#  altina matris yerlestirilmesi gerekir.

#' Teknik katsayi matrisi (A)
#'
#' A = Z %*% diag(1 / x); ara girdi akimlarini toplam ciktiya boler.
#'
#' @param Z Ara girdi akim matrisi (n x n).
#' @param x Toplam cikti vektoru (uzunluk n).
#' @return Teknik katsayi matrisi A (n x n).
technical_coefficients <- function(Z, x) {
  Z <- as.matrix(Z)
  if (nrow(Z) != ncol(Z)) {
    stop("Z kare matris olmali.")
  }
  if (length(x) != ncol(Z)) {
    stop("x uzunlugu Z sutun sayisina esit olmali.")
  }
  x_safe <- ifelse(x == 0, 1, x)   # Sifir ciktili sektorlerde bolme hatasini onler.
  A <- sweep(Z, 2, x_safe, "/")
  A[, x == 0] <- 0
  A
}

#' Leontief ters matrisi
#'
#' L = (I - A)^-1; nihai talebin toplam cikti gereksinimine donusumu.
#'
#' @param A Teknik katsayi matrisi.
#' @return Leontief ters matrisi L.
leontief_inverse <- function(A) {
  A <- as.matrix(A)
  n <- nrow(A)
  if (n != ncol(A)) {
    stop("A kare matris olmali.")
  }
  L <- try(solve(diag(n) - A), silent = TRUE)
  if (inherits(L, "try-error")) {
    stop("(I - A) tekil; MRIO matrisi cozulemiyor. Cikti vektorunu kontrol edin.")
  }
  L
}

#' Toplam (dogrudan + dolayli) emisyon yogunlugu
#'
#' e_total = f %*% L, burada f dogrudan emisyon katsayi vektorudur.
#' Sonuc, nihai talep birimi basina tedarik zinciri genelindeki emisyondur -
#' yani E_MRIO tabani.
#'
#' @param f Dogrudan emisyon katsayilari (tCO2e / parasal birim cikti).
#' @param L Leontief ters matrisi.
#' @return Sektor bazinda toplam emisyon yogunlugu vektoru.
total_emission_intensity <- function(f, L) {
  L <- as.matrix(L)
  if (length(f) != nrow(L)) {
    stop("f uzunlugu L satir sayisina esit olmali.")
  }
  as.vector(f %*% L)
}

#' E_CBAM ile E_MRIO arasindaki kapsam farki
#'
#' Yasal yukumlulugun gercek karbon ayak izini ne kadar eksik yansittigini
#' olcer. Bu fark, gelecekteki kapsam genislemelerine karsi "gizli maruziyeti"
#' temsil eder.
#'
#' @param e_cbam Yasal kapsamdaki emisyon (tCO2e).
#' @param e_mrio Tedarik zinciri genelindeki emisyon (tCO2e).
#' @return \code{gap} (mutlak fark) ve \code{coverage_ratio} iceren liste.
scope_gap <- function(e_cbam, e_mrio) {
  if (any(e_mrio <= 0, na.rm = TRUE)) {
    stop("e_mrio pozitif olmali.")
  }
  list(
    gap = e_mrio - e_cbam,
    coverage_ratio = e_cbam / e_mrio
  )
}

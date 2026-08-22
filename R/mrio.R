#  Cok Bolgeli Girdi-Cikti (MRIO) Modulu
#
#  E_CBAM ile E_MRIO ayrimi bu projenin metodolojik omurgasidir:
#    E_CBAM : yalnizca tesis duzeyinde dogrudan + elektrik emisyonlari (yasal taban)
#    E_MRIO : tedarik zincirinin tamamina yayilan ayak izi (ekonomik gercek taban)
#
#  EXIOBASE / WIOD matrisleri bu moduldeki fonksiyonlara beslenir.

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

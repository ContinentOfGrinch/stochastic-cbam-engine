#  Yardimci Fonksiyonlar

#' Turkce bicimde sayi formatlama
#'
#' \code{formatC(format = "d")} 2^31'i asan degerlerde tamsayi tasmasi
#' nedeniyle NA uretir; CBAM maliyetleri TRY cinsinden bu esigi kolayca
#' asar. Bu fonksiyon kayan noktali bicim kullanarak tasmayi onler ve
#' binlik/ondalik ayraci cakismasindan dogan uyariyi engeller.
#'
#' @param x Sayisal vektor.
#' @param digits Ondalik basamak sayisi.
#' @return Karakter vektor (binlik ayraci ".", ondalik ayraci ",").
fmt_num <- function(x, digits = 0) {
  formatC(x, format = "f", digits = digits,
          big.mark = ".", decimal.mark = ",")
}

#' Guven araligini tek satirda bicimle
#'
#' @param x Sayisal vektor.
#' @param level Guven duzeyi (varsayilan 0.90 -> %5 ve %95 yuzdelikleri).
#' @return "alt - ust" biciminde karakter.
fmt_ci <- function(x, level = 0.90) {
  a <- (1 - level) / 2
  q <- stats::quantile(x, c(a, 1 - a))
  paste(fmt_num(q[1]), "-", fmt_num(q[2]))
}

#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

#  Uretilmis bir HTML raporun sozlerini tutup tutmadigini dogrular.
#
#  Calistirma:  Rscript tests/check_report.R <rapor.html>
#
#  Neden ayri bir dosya: bu kontrol once CI icinde satir ici "Rscript -e"
#  olarak yazilmisti ve Windows'ta kirildi - bash'ten Rscript.exe'ye cok
#  satirli tirnakli argüman gecirmek platformlar arasi guvenilir degil.
#  Dosyaya alinca hem tasinabilir hem de yerelde tek basina calistirilabilir.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  cat("Kullanim: Rscript tests/check_report.R <rapor.html>\n")
  quit(status = 2)
}
dosya <- args[1]

if (!file.exists(dosya)) {
  cat(sprintf("HATA: rapor bulunamadi: %s\n", dosya))
  quit(status = 1)
}

h <- paste(readLines(dosya, warn = FALSE), collapse = "\n")
hata <- character(0)

# 1) Tek dosya sarti: rapor internetsiz acilmali, alicinin verisi hicbir
#    yere gitmemeli. Disaridan kaynak yukleyen bir rapor bu sozu bozar.
if (grepl("src=|href=\"http|@import|fetch\\(", h)) {
  hata <- c(hata, "Rapor disaridan kaynak yukluyor (src=/href=http/@import/fetch).")
}

# 2) AGPL 7(b) atif sarti: kunye rapor govdesinde olmali.
if (!grepl("0009-0007-4824-752X", h, fixed = TRUE)) {
  hata <- c(hata, "Rapor ORCID kunyesini tasimiyor.")
}
if (!grepl("AGPL", h, fixed = TRUE)) {
  hata <- c(hata, "Rapor lisans bildirimini tasimiyor.")
}

# 3) Hesabin her ara adimi gorunur olmali - urunun ana vaadi bu.
for (adim in c("Gomulu emisyon", "Ucretsiz tahsisat", "Sertifika yukumlulugu")) {
  if (!grepl(adim, h, fixed = TRUE)) {
    hata <- c(hata, sprintf("Rapor '%s' satirini icermiyor.", adim))
  }
}

# 4) Provenans: hangi tohum ve hangi veri paketi kullanildi.
if (!grepl("Rastgele tohum", h, fixed = TRUE)) {
  hata <- c(hata, "Rapor provenans blogunu icermiyor.")
}

# 5) Gecerli HTML iskeleti.
if (!grepl("^<!doctype html>", h) || !grepl("</html>$", trimws(h))) {
  hata <- c(hata, "Rapor gecerli bir HTML belgesi degil.")
}

if (length(hata) > 0) {
  cat("RAPOR KONTROLU BASARISIZ\n")
  for (m in hata) cat("  - ", m, "\n", sep = "")
  quit(status = 1)
}

cat(sprintf("Rapor kontrolu gecti: %s (%.1f KB)\n",
            dosya, file.size(dosya) / 1024))

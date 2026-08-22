#  Motoru bagimliliksiz yukle
#
#  Kullanim:  source("load_all.R")
#
#  R/ altindaki tum modulleri global ortama yukler. devtools veya paket
#  kurulumu gerektirmez; yalnizca base R + stats kullanilir.

local({
  files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
  if (length(files) == 0) {
    stop("R/ dizininde kaynak dosya bulunamadi. Proje kokunde misiniz?")
  }
  invisible(lapply(files, source, encoding = "UTF-8"))
  message(sprintf("stochastic-cbam-engine yuklendi (%d modul).", length(files)))
})

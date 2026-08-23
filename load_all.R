#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

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

  # Arastirma eklentileri motorun parcasi degildir; yoksa da hesap makinesi
  # calisir. Bu yuzden ayri yuklenir ve ayri raporlanir.
  ek <- list.files("research", pattern = "\\.R$", full.names = TRUE)
  if (length(ek) > 0) {
    invisible(lapply(ek, source, encoding = "UTF-8"))
  }

  message(sprintf("stochastic-cbam-engine yuklendi (%d modul%s).",
                  length(files),
                  if (length(ek) > 0) sprintf(" + %d arastirma eki", length(ek))
                  else ""))
})

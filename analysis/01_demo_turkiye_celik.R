#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

#  DEMO: Turkiye Demir-Celik Sektoru CBAM Maruziyeti
#
#  Calistirma:  Rscript analysis/01_demo_turkiye_celik.R   (proje kokunden)
#
#  DIKKAT: Asagidaki parametreler gosterim amacli varsayimlardir, gercek firma
#  verisi degildir. Uretim analizi icin data-raw/ altina kendi verinizi koyun.

source("load_all.R")

# ---------------------------------------------------------------------------
# Varsayimlar
# ---------------------------------------------------------------------------
CARBON_PRICE_0 <- 80     # EU ETS spot (EUR / tCO2e)
FX_0           <- 48     # TRY / EUR
N_SIMS         <- 50000
SEED           <- 2026

# Baslangic fiyatlarinin gozlendigi yil. Zaman ufku her senaryoda
# (yukumluluk yili - BASE_YEAR) olarak otomatik turetilir; 2034 senaryosu
# sekiz yillik belirsizlikle kosar, 2026 senaryosu ufuksuz kosar.
BASE_YEAR      <- 2026

# Uretim rotasina gore parametreler.
# Turkiye celik uretiminin yaklasik ucte ikisi elektrik ark ocagi (EAF) rotasi
# ile yapilir; bu rota entegre (BF-BOF) rotaya gore belirgin sekilde dusuk
# emisyon yogunluguna sahiptir. Benchmark degerleri de rotaya gore farklidir.
#
# ONEMLI: ei_sector burada DOGRUDAN (Scope 1) emisyonu ifade eder; AB ETS
# benchmark'lari da dogrudan emisyon tabanlidir. EAF icin elektrik kaynakli
# dolayli emisyon dahil edilirse yogunluk yaklasik iki katina cikar, ancak
# benchmark ile karsilastirmasi gecersiz olur. Dolayli emisyonu modele katmak
# icin embedded_emissions(include_indirect = TRUE) kullanin.
routes <- list(
  EAF = list(
    label      = "Elektrik Ark Ocagi (EAF)",
    ei_sector  = 0.25,   # tCO2e / ton ham celik (dogrudan)
    benchmark  = 0.215,  # AB ETS EAF karbon celigi benchmark'i
    theta_sd   = 0.30    # Hurda kalitesi ve ocak verimliligi kaynakli sacilim
  ),
  BF_BOF = list(
    label      = "Entegre Tesis (BF-BOF)",
    ei_sector  = 1.95,
    benchmark  = 1.288,  # AB ETS sicak metal benchmark'i
    theta_sd   = 0.20
  )
)

QUANTITY <- 250000       # Yillik AB'ye ihracat (ton)
YEARS    <- c(2026, 2030, 2034)

# ---------------------------------------------------------------------------
# Simulasyon
# ---------------------------------------------------------------------------
cat("\n############################################################\n")
cat("#  STOKASTIK CBAM MARUZIYET ANALIZI - TURKIYE DEMIR-CELIK  #\n")
cat("############################################################\n")
cat(sprintf("\nIhracat hacmi     : %s ton/yil\n", fmt_num(QUANTITY)))
cat(sprintf("EU ETS baslangic  : %.0f EUR/tCO2e\n", CARBON_PRICE_0))
cat(sprintf("Kur baslangic     : %.0f TRY/EUR\n", FX_0))
cat(sprintf("Simulasyon sayisi : %s\n", fmt_num(N_SIMS)))

results <- list()

for (route_name in names(routes)) {
  r <- routes[[route_name]]
  cat("\n\n============================================================\n")
  cat(sprintf("ROTA: %s\n", r$label))
  cat(sprintf("Sektor emisyon yogunlugu: %.3f tCO2e/ton | Benchmark: %.3f\n",
              r$ei_sector, r$benchmark))
  cat("============================================================\n")

  for (yr in YEARS) {
    sim <- run_cbam_mc(
      n_sims         = N_SIMS,
      quantity       = QUANTITY,
      ei_sector      = r$ei_sector,
      theta_sdlog    = r$theta_sd,
      benchmark      = r$benchmark,
      year           = yr,
      base_year      = BASE_YEAR,
      carbon_price_0 = CARBON_PRICE_0,
      fx_0           = FX_0,
      carbon_sigma   = 0.35,
      fx_sigma       = 0.18,
      rho            = 0.20,
      seed           = SEED
    )

    cat(sprintf("\n--- %d (CBAM faktoru: %.1f%%, ufuk: %g yil) ---\n",
                yr, 100 * sim$inputs$cbam_factor, sim$inputs$horizon))
    cat(sprintf("  Medyan sertifika yukumlulugu : %14s tCO2e\n",
                fmt_num(median(sim$draws$certificates))))
    cat(sprintf("  Maliyet EUR  [%%90 GA]        : %s\n",
                fmt_ci(sim$draws$cost_eur)))
    cat(sprintf("    medyan                     : %14s EUR\n",
                fmt_num(median(sim$draws$cost_eur))))
    # Bugunku kurla: varsayim icermez. Nominal kur suruklemesiyle hesaplanan
    # tutar da mevcut (cost_local) ama planlamada kullanilacak olan bu degil.
    cat(sprintf("  Maliyet TRY (bugunku kur)    : %14s TRY (medyan)\n",
                fmt_num(median(sim$draws$cost_local_today))))
    cat(sprintf("  VaR (%%95)                    : %14s EUR\n",
                fmt_num(cbam_var(sim, 0.95))))
    cat(sprintf("  Ton basina yuk               : %14s EUR/ton\n",
                fmt_num(median(sim$draws$cost_eur) / QUANTITY, digits = 2)))

    results[[paste(route_name, yr, sep = "_")]] <- sim
  }
}

# ---------------------------------------------------------------------------
# Rota karsilastirmasi: temiz teknolojinin rekabet avantaji
# ---------------------------------------------------------------------------
cat("\n\n============================================================\n")
cat("ROTA KARSILASTIRMASI - 2034 (tam yukumluluk)\n")
cat("============================================================\n")

eaf_2034 <- median(results$EAF_2034$draws$cost_eur)
bof_2034 <- median(results$BF_BOF_2034$draws$cost_eur)

cat(sprintf("  EAF medyan maliyet    : %15s EUR\n", fmt_num(eaf_2034)))
cat(sprintf("  BF-BOF medyan maliyet : %15s EUR\n", fmt_num(bof_2034)))
cat(sprintf("  EAF avantaji          : %15s EUR/yil\n",
            fmt_num(bof_2034 - eaf_2034)))

# ---------------------------------------------------------------------------
# Yasal taban (E_CBAM)
# ---------------------------------------------------------------------------
cat("\n============================================================\n")
cat("YASAL EMISYON TABANI\n")
cat("============================================================\n")

e_cbam_bof <- QUANTITY * routes$BF_BOF$ei_sector
cat(sprintf("  E_CBAM (BF-BOF)       : %12s tCO2e\n", fmt_num(e_cbam_bof)))

cat("\nBu, mevzuatin vergilendirdigi tabandir: tesis ici dogrudan emisyonlar.\n")
cat("Tedarik zincirinin tamamina yayilan gercek ayak izi (E_MRIO) bundan\n")
cat("buyuktur ve aradaki fark, kapsam genislemelerine karsi gizli maruziyeti\n")
cat("olcer. Bu hesap research/mrio.R altindaki arastirma ekinde yapilir ve\n")
cat("gercek EXIOBASE/WIOD matrisi gerektirir; uydurma bir carpanla tahmin\n")
cat("edilmesi yaniltici olurdu.\n\n")

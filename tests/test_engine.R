#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

#  Motor Testleri (base R - harici test paketi gerektirmez)
#
#  Calistirma:  Rscript tests/test_engine.R   (proje kokunden)

if (!file.exists("load_all.R")) {
  stop("Testler proje kokunden calistirilmali: Rscript tests/test_engine.R")
}
source("load_all.R")

passed <- 0L
failed <- 0L

expect <- function(label, condition) {
  ok <- isTRUE(tryCatch(condition, error = function(e) FALSE))
  if (ok) {
    passed <<- passed + 1L
    cat(sprintf("  [GECTI] %s\n", label))
  } else {
    failed <<- failed + 1L
    cat(sprintf("  [KALDI] %s\n", label))
  }
}

expect_error <- function(label, expr) {
  threw <- inherits(try(force(expr), silent = TRUE), "try-error")
  expect(label, threw)
}

cat("\n== emissions.R ==\n")
expect("theta = 1 sektor ortalamasini korur",
       firm_emission_intensity(2.0, 1.0) == 2.0)
expect("theta olceklemesi dogrusal",
       firm_emission_intensity(2.0, 1.5) == 3.0)
expect_error("negatif ei_sector reddedilir",
             firm_emission_intensity(-1, 1))
expect_error("sifir theta reddedilir",
             firm_emission_intensity(1, 0))
expect("gomulu emisyon = miktar * yogunluk",
       embedded_emissions(1000, 1.9) == 1900)
expect("dolayli emisyon varsayilan olarak haric",
       embedded_emissions(1000, 1.9, ei_indirect = 0.5) == 1900)
expect("dolayli emisyon istege bagli dahil",
       embedded_emissions(1000, 1.9, 0.5, include_indirect = TRUE) == 2400)
expect("sample_theta pozitif ve dogru uzunlukta",
       { s <- sample_theta(500); length(s) == 500 && all(s > 0) })

cat("\n== cbam.R ==\n")
expect("2025 oncesi mali yukumluluk yok",
       cbam_phase_in_factor(2025) == 0)
expect("2026 faktoru %2,5",
       abs(cbam_phase_in_factor(2026) - 0.025) < 1e-12)
expect("2030 faktoru %48,5",
       cbam_phase_in_factor(2030) == 0.485)
expect("2034 ve sonrasi tam yukumluluk",
       cbam_phase_in_factor(2034) == 1 && cbam_phase_in_factor(2040) == 1)

# --- D1: resmi CBAM faktoru tablosu -----------------------------------------
# Kaynak: Free Allocation Adjustment Act (CIR (EU) 2025/2620),
#         Guidance No. 4 Tablo 2-1.
# Mevzuatin "CBAM factor" dedigi deger UCRETSIZ TAHSISAT payidir; bizim
# yukumluluk payimiz onun tumleyenidir. 2031-2033 degerleri onceden yanlisti.
expect("resmi CBAM faktoru tablosu mevzuatla ayni",
       all(abs(cbam_factor_official(2026:2034) -
                 c(0.975, 0.950, 0.900, 0.775, 0.515,
                   0.390, 0.265, 0.140, 0.000)) < 1e-12))
expect("yukumluluk payi resmi faktorun tumleyeni",
       all(abs(cbam_phase_in_factor(2026:2034) +
                 cbam_factor_official(2026:2034) - 1) < 1e-12))
expect("2031-2033 duzeltilmis degerler",
       all(abs(cbam_phase_in_factor(2031:2033) -
                 c(0.610, 0.735, 0.860)) < 1e-12))
expect("2026 oncesi tahsisat tam, yukumluluk sifir",
       cbam_factor_official(2025) == 1 && cbam_phase_in_factor(2025) == 0)
expect_error("resmi faktor gecersiz yili reddeder",
             cbam_factor_official(2030.5))

# --- CSCF ---
expect("cscf su an tum yillarda 1",
       all(cbam_cscf(2026:2034) == 1))
expect("cscf ucretsiz tahsisati olcekler",
       { tam <- certificates_due(1900, 1000, 1.288, 0.025, cscf = 1)
         yari <- certificates_due(1900, 1000, 1.288, 0.025, cscf = 0.5)
         yari > tam })
expect_error("negatif cscf reddedilir",
             certificates_due(1900, 1000, 1.288, 0.5, cscf = -1))
expect("faktor vektorlestirilmis",
       length(cbam_phase_in_factor(c(2026, 2030, 2034))) == 3)
expect("vektor sonuclari tek tek cagriyla ayni",
       all(abs(cbam_phase_in_factor(c(2025, 2028, 2031, 2040)) -
                 c(0, 0.100, 0.610, 1)) < 1e-12))
# K3: gecersiz yil sessizce NA uretiyordu; hata tum hesaba yayiliyordu.
expect_error("tam sayi olmayan yil reddedilir", cbam_phase_in_factor(2026.5))
expect_error("NA yil reddedilir", cbam_phase_in_factor(NA_real_))
expect_error("metin yil reddedilir", cbam_phase_in_factor("2030"))
expect_error("bos yil reddedilir", cbam_phase_in_factor(numeric(0)))

expect("tam faktorde ucretsiz tahsisat kalmaz",
       certificates_due(1900, 1000, 1.288, 1.0) == 1900)
expect("dusuk faktorde muafiyet buyuk",
       certificates_due(1900, 1000, 1.288, 0.025) < 700)
expect("sertifika negatif olamaz",
       certificates_due(100, 1000, 1.288, 0.025) == 0)
expect("mensede odenen karbon dusulur",
       certificates_due(1900, 1000, 1.288, 1.0, carbon_paid_origin = 400) == 1500)
expect_error("gecersiz cbam_factor reddedilir",
             certificates_due(1900, 1000, 1.288, 1.5))

expect("maliyet = sertifika * fiyat",
       cbam_cost(100, 80)$cost_eur == 8000)
expect("kur cevrimi uygulanir",
       cbam_cost(100, 80, fx_rate = 40)$cost_local == 320000)
expect("de minimis esigi 50 tCO2e",
       is_de_minimis(49) && !is_de_minimis(51))

cat("\n== stochastic.R ==\n")
set.seed(42)
expect("GBM pozitif degerler uretir",
       all(simulate_gbm(1000, 75, 0.05, 0.35) > 0))
expect("sifir volatilitede GBM deterministik",
       { v <- simulate_gbm(10, 100, 0.0, 0.0); all(abs(v - 100) < 1e-9) })
expect("korelasyon hedefe yakin",
       { z <- correlated_shocks(200000, 0.6); abs(cor(z[, 1], z[, 2]) - 0.6) < 0.02 })
expect_error("gecersiz rho reddedilir",
             correlated_shocks(100, 1.0))
expect("simulate_market dogru boyutta",
       { m <- simulate_market(1000, 75, fx_0 = 40)
         nrow(m) == 1000 && all(m$carbon_price > 0) && all(m$fx_rate > 0) })
expect("sifir ufukta belirsizlik yok",
       { m <- simulate_market(500, 80, fx_0 = 48, horizon = 0)
         all(abs(m$carbon_price - 80) < 1e-9) && all(abs(m$fx_rate - 48) < 1e-9) })
# --- K6: reel / nominal ayrimi ---------------------------------------------
# Onceki hali sabit fx_mu = 0.20 idi ve kaynaksizdi; sekiz yil bileşiklenince
# 2034 icin ~238 TRY/EUR ima ediyordu. Simdi enflasyon farkindan turetiliyor.
expect("kur suruklemesi enflasyon farkindan turetilir",
       { m <- simulate_market(200000, 80, fx_0 = 48, fx_sigma = 0,
                              inflation_tr = 0.25, inflation_eu = 0.02,
                              horizon = 1)
         beklenen <- 48 * (1.25 / 1.02)
         abs(median(m$fx_rate) - beklenen) / beklenen < 0.01 })
expect("enflasyon esitse kur sabit kalir",
       { m <- simulate_market(1000, 80, fx_0 = 48, fx_sigma = 0,
                              inflation_tr = 0.10, inflation_eu = 0.10,
                              horizon = 5)
         all(abs(m$fx_rate - 48) < 1e-6) })
expect("fx_mu elle verilirse enflasyonun onune gecer",
       { m <- simulate_market(1000, 80, fx_0 = 48, fx_mu = 0, fx_sigma = 0,
                              inflation_tr = 0.25, horizon = 3)
         all(abs(m$fx_rate - 48) < 1e-6) })
expect("deflator enflasyon ve ufuktan hesaplanir",
       { m <- simulate_market(10, 80, inflation_tr = 0.25, horizon = 4)
         abs(m$deflator_tr[1] - 1.25^4) < 1e-9 })

expect("ufuk buyudukce dagilim genisler",
       { set.seed(4)
         s1 <- sd(simulate_market(50000, 80, horizon = 1)$carbon_price)
         s8 <- sd(simulate_market(50000, 80, horizon = 8)$carbon_price)
         s8 > s1 })

cat("\n== mrio.R ==\n")
Z <- matrix(c(20, 30, 10, 40), nrow = 2)
x <- c(100, 200)
A <- technical_coefficients(Z, x)
expect("A = Z / cikti (sutun bazinda)",
       abs(A[1, 1] - 0.20) < 1e-12 && abs(A[1, 2] - 0.05) < 1e-12)
expect("sifir ciktili sektor sifir sutun verir",
       { A0 <- technical_coefficients(Z, c(100, 0)); all(A0[, 2] == 0) })
L <- leontief_inverse(A)
expect("L = (I - A)^-1 dogrulanir",
       max(abs((diag(2) - A) %*% L - diag(2))) < 1e-10)
expect("L kosegen elemanlari >= 1",
       all(diag(L) >= 1))
expect_error("tekil matris hata verir",
             leontief_inverse(matrix(c(1, 0, 0, 1), nrow = 2)))
expect("toplam yogunluk dogrudandan buyuk",
       { f <- c(0.5, 0.3); tot <- total_emission_intensity(f, L)
         all(tot >= f) })
expect("kapsam orani 0-1 arasinda",
       { g <- scope_gap(1900, 2500)
         abs(g$gap - 600) < 1e-9 && g$coverage_ratio > 0 && g$coverage_ratio < 1 })

cat("\n== monte_carlo.R ==\n")
sim <- run_cbam_mc(n_sims = 5000, quantity = 50000, ei_sector = 1.9,
                   benchmark = 1.288, year = 2030, carbon_price_0 = 75,
                   fx_0 = 40, seed = 123)
expect("cikti cbam_mc sinifinda", inherits(sim, "cbam_mc"))
expect("draws dogru satir sayisinda", nrow(sim$draws) == 5000)
expect("tum maliyetler negatif degil", all(sim$draws$cost_eur >= 0))
expect("yerel maliyet = EUR * kur",
       max(abs(sim$draws$cost_local -
               sim$draws$cost_eur * sim$draws$fx_rate)) < 1e-6)
expect("bugunku kur sutunu varsayim icermez",
       max(abs(sim$draws$cost_local_today -
               sim$draws$cost_eur * sim$inputs$fx_0)) < 1e-6)
expect("reel tutar nominalden kucuk (pozitif enflasyonda)",
       { s <- run_cbam_mc(2000, 50000, 1.9, benchmark = 1.288, year = 2034,
                          base_year = 2026, fx_0 = 48, seed = 9)
         median(s$draws$cost_local_real) < median(s$draws$cost_local) })
expect("risk_summary ucunu de raporlar",
       { rs <- risk_summary(sim)
         all(c("cost_local_today", "cost_local_real", "cost_local")
             %in% rownames(rs)) })
expect("ayni tohum ayni sonucu verir",
       { s2 <- run_cbam_mc(n_sims = 5000, quantity = 50000, ei_sector = 1.9,
                           benchmark = 1.288, year = 2030,
                           carbon_price_0 = 75, fx_0 = 40, seed = 123)
         identical(sim$draws$cost_eur, s2$draws$cost_eur) })
expect("sifir heterojenlikte theta sabit",
       { s3 <- run_cbam_mc(n_sims = 100, quantity = 1000, ei_sector = 1.9,
                           theta_sdlog = 0, benchmark = 1.288, seed = 1)
         length(unique(s3$draws$theta)) == 1 })
expect("2034 maliyeti 2026'dan yuksek",
       { a <- run_cbam_mc(2000, 50000, 1.9, benchmark = 1.288,
                          year = 2026, seed = 7)
         b <- run_cbam_mc(2000, 50000, 1.9, benchmark = 1.288,
                          year = 2034, seed = 7)
         median(b$draws$cost_eur) > median(a$draws$cost_eur) })
expect("risk_summary tum metrikleri dondurur",
       { rs <- risk_summary(sim); nrow(rs) == 6 && "5%" %in% colnames(rs) })
expect("VaR medyandan buyuk",
       cbam_var(sim, 0.95) > median(sim$draws$cost_eur))
expect_error("risk_summary yanlis girdiyi reddeder",
             risk_summary(data.frame(a = 1)))

# --- K1: horizon, yukumluluk yilindan turetilmeli --------------------------
# Onceki davranis: year = 2034 verildiginde bile horizon = 1 kaliyordu ve
# dokuz yillik belirsizlik tek yil gibi modellenerek risk eksik gosteriliyordu.
expect("horizon year - base_year olarak turetilir",
       { s <- run_cbam_mc(500, 50000, 1.9, benchmark = 1.288,
                          year = 2034, base_year = 2026, seed = 11)
         s$inputs$horizon == 8 })
expect("uzak yil daha genis fiyat dagilimi uretir",
       { near <- run_cbam_mc(20000, 50000, 1.9, benchmark = 1.288,
                             year = 2027, base_year = 2026,
                             carbon_price_0 = 80, seed = 11)
         far <- run_cbam_mc(20000, 50000, 1.9, benchmark = 1.288,
                            year = 2034, base_year = 2026,
                            carbon_price_0 = 80, seed = 11)
         sd(far$draws$carbon_price) > 3 * sd(near$draws$carbon_price) })
expect("year = base_year -> ufuk sifir, fiyat sabit",
       { s <- run_cbam_mc(500, 50000, 1.9, benchmark = 1.288,
                          year = 2026, base_year = 2026,
                          carbon_price_0 = 80, fx_0 = 48, seed = 3)
         s$inputs$horizon == 0 &&
           all(abs(s$draws$carbon_price - 80) < 1e-9) &&
           all(abs(s$draws$fx_rate - 48) < 1e-9) })
expect("horizon elle gecersiz kilinabilir",
       { s <- run_cbam_mc(500, 50000, 1.9, benchmark = 1.288,
                          year = 2034, horizon = 2, seed = 11)
         s$inputs$horizon == 2 })
expect_error("birden fazla yil reddedilir",
             run_cbam_mc(100, 1000, 1.9, benchmark = 1.288, year = c(2026, 2030)))

# --- K2: seed cagiranin RNG durumunu kirletmemeli --------------------------
expect("seed global RNG durumunu kirletmez",
       { set.seed(999)
         before <- runif(1)
         set.seed(999)
         invisible(run_cbam_mc(100, 1000, 1.9, benchmark = 1.288, seed = 5))
         identical(before, runif(1)) })
expect("provenans alanlari inputs icinde kayitli",
       { s <- run_cbam_mc(100, 1000, 1.9, benchmark = 1.288, seed = 5)
         all(c("seed", "horizon", "base_year", "theta_sdlog") %in%
               names(s$inputs)) })

cat("\n== bagimlilik disiplini ==\n")
# "Sifir bagimlilik" bir iddia degil, korunmasi gereken bir kural olmali.
# Motor ve sunum katmani yalnizca R'in temel paketlerini kullanabilir.
kaynak_dosyalar <- c(list.files("R", pattern = "\\.R$", full.names = TRUE),
                     "hesapla.R", "load_all.R")
kaynak_metin <- unlist(lapply(kaynak_dosyalar, readLines, warn = FALSE))
kod_satirlari <- kaynak_metin[!grepl("^\\s*#", kaynak_metin)]

expect("motor library()/require() cagirmiyor",
       !any(grepl("\\b(library|require|requireNamespace)\\s*\\(", kod_satirlari)))
expect("yalnizca temel paket ad alanlari kullaniliyor",
       { ns <- regmatches(kod_satirlari,
                          gregexpr("[A-Za-z][A-Za-z0-9.]*(?=::)", kod_satirlari,
                                   perl = TRUE))
         ns <- unique(unlist(ns))
         length(ns) == 0 || all(ns %in% c("stats", "utils", "graphics",
                                          "grDevices", "methods", "base",
                                          "tools"))
       })
expect("motor katmani ag erisimi yapmiyor",
       !any(grepl("url\\(|download\\.file|curl|httr|readLines\\s*\\(\\s*\"http",
                  kod_satirlari)))

cat("\n== reference.R (Katman 0 veri butunlugu) ==\n")
urunler <- cbam_products()
benchmarks <- cbam_benchmarks()

expect("urun katalogu bos degil", nrow(urunler) > 0)
expect("veri surumu tanimli", nchar(cbam_data_version()) > 0)
expect("urun kodlari benzersiz",
       !any(duplicated(urunler$urun_kodu)))
expect("CN kodlari benzersiz",
       !any(duplicated(benchmarks$cn_kodu)))
expect("her urunun CN kodu benchmark tablosunda var",
       all(urunler$cn_kodu %in% benchmarks$cn_kodu))
expect("benchmark tablosu resmi buyuklukte (500+ CN kodu)",
       nrow(benchmarks) > 500)
expect("benchmark tablosunun tamami dogrulandi",
       all(trimws(benchmarks$durum) == "dogrulandi"))
expect("her benchmark satirinin kaynagi var",
       all(nzchar(trimws(benchmarks$kaynak_belge))))
expect("girilmis yogunluk degerleri pozitif",
       { v <- urunler$varsayilan_yogunluk
         all(v[!is.na(v)] > 0) })
expect("benchmark degerleri negatif degil",
       { all(benchmarks$bm_column_a[!is.na(benchmarks$bm_column_a)] >= 0) &&
           all(benchmarks$bm_column_b[!is.na(benchmarks$bm_column_b)] >= 0) })
# Column B tum uretim zinciri, Column A tek surec: B >= A olmali.
expect("Column B her zaman Column A'dan kucuk degil",
       { a <- benchmarks$bm_column_a
         b <- benchmarks$bm_column_b
         ok <- !is.na(a) & !is.na(b)
         all(b[ok] >= a[ok] - 1e-9) })
expect("girilmis sacilim degerleri makul araliktan",
       { v <- urunler$varsayilan_sacilim
         all(v[!is.na(v)] >= 0 & v[!is.na(v)] < 2) })
expect("benchmark tablosu tum CBAM sektorlerini kapsiyor",
       all(c("Cement", "Fertilisers", "Iron & Steel", "Aluminium", "Hydrogen")
           %in% unique(benchmarks$sektor)))

# --- D7/D8: CN kodu ile benchmark cozumleme -------------------------------
expect("CN kodu ile benchmark bulunur",
       { b <- cbam_benchmark_by_cn("72081000")
         abs(b$benchmark - 1.370) < 1e-9 && b$sutun == "B" })
expect("Column A tek uretim sureci degerini verir",
       { b <- cbam_benchmark_by_cn("72081000", "A")
         abs(b$benchmark - 0.044) < 1e-9 })
expect("birincil aluminyum resmi degeri 1,423",
       abs(cbam_benchmark_by_cn("76011090")$benchmark - 1.423) < 1e-9)
expect("hidrojen resmi degeri 5,089",
       abs(cbam_benchmark_by_cn("28041000")$benchmark - 5.089) < 1e-9)
expect("CN kodundaki bosluk ve nokta temizlenir",
       { abs(cbam_benchmark_by_cn(" 7208 10 00 ")$benchmark - 1.370) < 1e-9 })
expect("benchmark kaynagi ciktida tasinir",
       nzchar(cbam_benchmark_by_cn("72081000")$kaynak))
expect_error("kapsam disi CN kodu net hata verir",
             cbam_benchmark_by_cn("99999999"))
expect_error("bos CN kodu reddedilir", cbam_benchmark_by_cn(""))
expect_error("gecersiz sutun reddedilir",
             cbam_benchmark_by_cn("72081000", "C"))

# --- Fonksiyonel birim: sessizce yanlis sonucu onleyen kontrol ------------
# Rehber No. 3 s.20: cimentoda ton klinker, gubrede kg azot.
expect("celikte birim ton urun",
       isTRUE(cbam_benchmark_by_cn("72081000")$birim$standart))
expect("cimentoda birim ton klinker",
       { b <- cbam_benchmark_by_cn("25231000")$birim
         !b$standart && b$birim == "ton klinker" })
expect("aluminyumda birim ton urun",
       isTRUE(cbam_benchmark_by_cn("76011090")$birim$standart))
expect("gubre sektorunde birim kg azot",
       { g <- benchmarks$cn_kodu[benchmarks$sektor == "Fertilisers"][1]
         b <- cbam_benchmark_by_cn(g)$birim
         !b$standart && b$birim == "kg azot" })
expect("standart disi birim hesapta uyari uretir",
       { e <- cbam_estimate(100000, 0.9, 0.666, year = 2030,
                            uncertainty = FALSE,
                            functional_unit = cbam_fonksiyonel_birim("Cement"))
         cikti <- capture.output(print(e))
         any(grepl("BIRIM UYARISI", cikti, fixed = TRUE)) })
expect("standart birimde uyari cikmaz",
       { e <- cbam_estimate(250000, 1.95, 1.37, year = 2030,
                            uncertainty = FALSE)
         cikti <- capture.output(print(e))
         !any(grepl("BIRIM UYARISI", cikti, fixed = TRUE)) })
expect("durum degerleri gecerli",
       all(trimws(c(urunler$durum, benchmarks$durum)) %in%
             c("dogrulandi", "dogrulanmadi", "kismen")))

# Kritik kural: bir satir "dogrulandi" diyorsa kaynagini gostermek ZORUNDA.
# Bu test olmadan biri kaynaksiz bir degeri resmi gibi isaretleyebilir.
expect("dogrulanmis urun satirlarinin kaynagi var",
       { d <- urunler[urunler$durum == "dogrulandi", ]
         nrow(d) == 0 || all(nzchar(trimws(d$kaynak_belge))) })
expect("dogrulanmis benchmark satirlarinin kaynagi var",
       { d <- benchmarks[benchmarks$durum == "dogrulandi", ]
         nrow(d) == 0 || all(nzchar(trimws(d$kaynak_belge))) })

expect("degeri girilmis urunler icin cbam_product calisir",
       { hazir <- urunler$urun_kodu[!is.na(urunler$varsayilan_yogunluk)]
         length(hazir) > 0 &&
           all(vapply(hazir, function(k) {
             p <- cbam_product(k)
             is.numeric(p$benchmark) && p$benchmark > 0 &&
               is.numeric(p$varsayilan_yogunluk) &&
               isTRUE(p$benchmark_dogrulandi)
           }, logical(1))) })
expect("urun benchmark'i CN kodu uzerinden resmi tablodan gelir",
       { p <- cbam_product("celik-hrc")
         b <- cbam_benchmark_by_cn(p$cn_kodu)
         abs(p$benchmark - b$benchmark) < 1e-12 })
expect("sutun secimi urun cozumlemesine de gecer",
       { pa <- cbam_product("celik-hrc", "A")
         pb <- cbam_product("celik-hrc", "B")
         pb$benchmark > pa$benchmark })
# Iskelet satirlar sessizce NA ile hesaba girmemeli.
expect("degeri girilmemis urun net hata verir",
       { bos <- urunler$urun_kodu[is.na(urunler$varsayilan_yogunluk)]
         length(bos) == 0 ||
           all(vapply(bos, function(k) {
             inherits(try(cbam_product(k), silent = TRUE), "try-error")
           }, logical(1))) })
expect("dogrulanmamis urun uyari uretir",
       { p <- cbam_product(urunler$urun_kodu[1])
         if (p$dogrulandi) is.null(cbam_dogrulama_uyarisi(p))
         else length(cbam_dogrulama_uyarisi(p)) > 0 })
expect("kaynaksiz deger acikca isaretlenir",
       cbam_kaynak_metni("", "") == "KAYNAK GIRILMEDI")
expect("kaynak metni belge ve yeri birlestirir",
       cbam_kaynak_metni("REG-2023-956", "Ek II") == "REG-2023-956, Ek II")
expect_error("bilinmeyen urun kodu reddedilir", cbam_product("yok-boyle-urun"))

cat("\n== calculator.R ==\n")
est <- cbam_estimate(quantity = 1000, ei_direct = 1.9, benchmark = 1.288,
                     year = 2034, carbon_price = 80, fx_rate = 48,
                     uncertainty = FALSE)
expect("cikti cbam_estimate sinifinda", inherits(est, "cbam_estimate"))
expect("2034'te ucretsiz tahsisat sifir",
       est$deterministic$free_allocation == 0)
expect("2034'te tum gomulu emisyon vergilenir",
       est$deterministic$certificates == 1900)
expect("maliyet = sertifika * fiyat",
       est$deterministic$cost_eur == 1900 * 80)
expect("yerel maliyet kur ile cevrilir",
       est$deterministic$cost_local == 1900 * 80 * 48)
expect("ton basina yuk dogru",
       abs(est$deterministic$cost_per_tonne - 152) < 1e-9)
expect("vergilenen oran 2034'te %100",
       abs(est$deterministic$taxed_share - 1) < 1e-12)
expect("uncertainty = FALSE simulasyon uretmez",
       is.null(est$simulation))

est26 <- cbam_estimate(1000, 1.9, 1.288, year = 2026, carbon_price = 80,
                       uncertainty = FALSE)
expect("2026 ucretsiz tahsisati benchmark uzerinden",
       abs(est26$deterministic$free_allocation - 1.288 * 1000 * 0.975) < 1e-9)
expect("2026'da benchmark ustu firma yine de oder",
       abs(est26$deterministic$certificates - (1900 - 1255.8)) < 1e-9)
expect("2026'da emisyonun ucte birinden fazlasi vergilenir",
       est26$deterministic$taxed_share > 0.33)

expect("mensede odenen karbon dusulur",
       { e <- cbam_estimate(1000, 1.9, 1.288, year = 2034,
                            carbon_paid_origin = 400, uncertainty = FALSE)
         e$deterministic$certificates == 1500 })
expect("de minimis esigi altinda yukumluluk yok",
       { e <- cbam_estimate(20, 1.9, 1.288, year = 2034, uncertainty = FALSE)
         e$deterministic$de_minimis &&
           e$deterministic$certificates == 0 &&
           e$deterministic$cost_eur == 0 })
expect("dolayli emisyon istege bagli dahil",
       { e <- cbam_estimate(1000, 1.9, 1.288, year = 2034, ei_indirect = 0.5,
                            include_indirect = TRUE, uncertainty = FALSE)
         e$deterministic$embedded == 2400 })
expect("belirsizlik istendiginde simulasyon uretilir",
       { e <- cbam_estimate(1000, 1.9, 1.288, year = 2030, n_sims = 2000,
                            seed = 1)
         inherits(e$simulation, "cbam_mc") && nrow(e$simulation$draws) == 2000 })
expect("deterministik sonuc simulasyon medyanina yakin duruyor",
       { e <- cbam_estimate(1000, 1.9, 1.288, year = 2026, carbon_price = 80,
                            n_sims = 20000, seed = 1)
         d <- e$deterministic$cost_eur
         m <- median(e$simulation$draws$cost_eur)
         abs(m - d) / d < 0.25 })
expect_error("negatif miktar reddedilir",
             cbam_estimate(-5, 1.9, 1.288, uncertainty = FALSE))
expect_error("negatif karbon fiyati reddedilir",
             cbam_estimate(1000, 1.9, 1.288, carbon_price = -1,
                           uncertainty = FALSE))
expect_error("sifir kur reddedilir",
             cbam_estimate(1000, 1.9, 1.288, fx_rate = 0, uncertainty = FALSE))
expect_error("vektor girdi reddedilir",
             cbam_estimate(c(1000, 2000), 1.9, 1.288, uncertainty = FALSE))

cat("\n== report.R ==\n")
expect("html_kacis ozel karakterleri kacirir",
       html_kacis("<a href=\"x\">A&B</a>") ==
         "&lt;a href=&quot;x&quot;&gt;A&amp;B&lt;/a&gt;")

rapor_dosya <- file.path(tempdir(), "cbam_test_rapor.html")
if (file.exists(rapor_dosya)) file.remove(rapor_dosya)
est_rapor <- cbam_estimate(250000, 1.95, 1.288, year = 2030,
                           carbon_price = 80, fx_rate = 48,
                           n_sims = 3000, seed = 2026,
                           reference = cbam_product("celik-hrc"))
cbam_rapor(est_rapor, rapor_dosya, firma = "Test A.S.")
rapor_html <- paste(readLines(rapor_dosya, warn = FALSE), collapse = "\n")

expect("rapor dosyasi olusturuldu", file.exists(rapor_dosya))
# Rapor tek dosya olmali: internet olmadan acilmali, e-postayla gonderilmeli.
expect("rapor disaridan hicbir sey yuklemiyor",
       !grepl("src=|href=\"http|@import|fetch\\(", rapor_html))
expect("rapor gecerli HTML iskeletiyle basliyor",
       grepl("^<!doctype html>", rapor_html) &&
         grepl("</html>$", trimws(rapor_html)))
expect("rapor firma adini tasiyor", grepl("Test A.S.", rapor_html, fixed = TRUE))
expect("rapor hesap adimlarini gosteriyor",
       grepl("Gomulu emisyon", rapor_html, fixed = TRUE) &&
         grepl("Ucretsiz tahsisat", rapor_html, fixed = TRUE))
expect("rapor dagilim grafigi iceriyor",
       grepl("<svg", rapor_html, fixed = TRUE) &&
         length(gregexpr("<rect", rapor_html)[[1]]) > 5)
expect("rapor provenans bloku iceriyor",
       grepl("Rastgele tohum", rapor_html, fixed = TRUE) &&
         grepl("2026", rapor_html, fixed = TRUE))
# AGPL 7(b) atif sarti: kunye her raporda gomulu gelmeli.
expect("rapor kunyeyi tasiyor",
       grepl("0009-0007-4824-752X", rapor_html, fixed = TRUE) &&
         grepl("AGPL", rapor_html, fixed = TRUE))
expect("dogrulanmamis veri raporda uyari uretiyor",
       grepl("DOGRULANMAMIS", rapor_html, fixed = TRUE))
expect("referanssiz raporda dogrulama uyarisi cikmaz",
       { f3 <- file.path(tempdir(), "cbam_test_rapor3.html")
         e3 <- cbam_estimate(1000, 1.9, 1.288, year = 2030,
                             uncertainty = FALSE)
         cbam_rapor(e3, f3)
         h3 <- paste(readLines(f3, warn = FALSE), collapse = "\n")
         !grepl("DOGRULANMAMIS", h3, fixed = TRUE) &&
           grepl("kullanici girdisi", h3, fixed = TRUE) })
expect("kesin modda rapor belirsizlik bolumu icermez",
       { f2 <- file.path(tempdir(), "cbam_test_rapor2.html")
         e2 <- cbam_estimate(1000, 1.9, 1.288, year = 2030, uncertainty = FALSE)
         cbam_rapor(e2, f2)
         h2 <- paste(readLines(f2, warn = FALSE), collapse = "\n")
         !grepl("Belirsizlik", h2, fixed = TRUE) })
expect_error("rapor yanlis girdi tipini reddeder",
             cbam_rapor(data.frame(a = 1), file.path(tempdir(), "x.html")))

cat(sprintf("\n=====================================\n"))
cat(sprintf("Toplam: %d gecti, %d kaldi\n", passed, failed))
cat(sprintf("=====================================\n"))
if (failed > 0) quit(status = 1)

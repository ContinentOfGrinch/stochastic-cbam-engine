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
       cbam_phase_in_factor(2026) == 0.025)
expect("2030 faktoru %48,5",
       cbam_phase_in_factor(2030) == 0.485)
expect("2034 ve sonrasi tam yukumluluk",
       cbam_phase_in_factor(2034) == 1 && cbam_phase_in_factor(2040) == 1)
expect("faktor vektorlestirilmis",
       length(cbam_phase_in_factor(c(2026, 2030, 2034))) == 3)
expect("vektor sonuclari tek tek cagriyla ayni",
       all(cbam_phase_in_factor(c(2025, 2028, 2031, 2040)) ==
             c(0, 0.100, 0.615, 1)))
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
       { rs <- risk_summary(sim); nrow(rs) == 4 && "5%" %in% colnames(rs) })
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

cat(sprintf("\n=====================================\n"))
cat(sprintf("Toplam: %d gecti, %d kaldi\n", passed, failed))
cat(sprintf("=====================================\n"))
if (failed > 0) quit(status = 1)

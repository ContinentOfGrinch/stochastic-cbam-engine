#  stochastic-cbam-engine — Copyright (C) 2026 Selahattin İlhan
#  SPDX-License-Identifier: AGPL-3.0-or-later
#
#  Bu dosya GNU Affero General Public License v3 (ya da sonraki bir surum)
#  kosullariyla dagitilir; HICBIR GARANTI VERILMEZ. Ayrintilar: LICENSE
#  EK SART (AGPL 7(b)): yazar atiflari ve telif bildirimleri korunmalidir.
#  Bkz. NOTICE ve LICENSE-ADDITIONAL-TERMS.md

#  Rapor Katmani
#
#  cbam_estimate() ciktisini paylasilabilir tek bir HTML dosyasina cevirir.
#  Ihracatcinin yonetim kuruluna, denetcisine ya da musterisine goturebilecegi
#  belge budur.
#
#  Tasarim kurallari:
#    - Tek dosya, disaridan hicbir sey yuklemez. Internet olmadan acilir,
#      e-postayla gonderilir, tarayicidan PDF'e basilir.
#    - Sifir bagimlilik: HTML metin olarak uretilir, grafik satir ici SVG'dir.
#    - Hesabin her ara adimi raporda gorunur. Rapor bir sonuc degil, bir
#      muhakeme zinciridir; denetlenebilirlik urunun kendisidir.
#    - Kunye her rapora gomulu gelir (AGPL 7(b) atif sarti).

#' HTML'de guvenli metin
#'
#' @param x Karakter vektor.
#' @return Ozel karakterleri kacisli karakter vektor.
html_kacis <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

#' Dagilim histogramini satir ici SVG olarak ciz
#'
#' Harici grafik paketi kullanilmaz; cubuklar dogrudan SVG dikdortgeni olarak
#' uretilir. Boylece rapor tek dosya olarak kendi kendine yeter.
#'
#' @param v Sayisal vektor (maliyet cekilisleri).
#' @param genislik SVG genisligi (piksel).
#' @param yukseklik SVG yuksekligi (piksel).
#' @return SVG karakter dizisi.
svg_histogram <- function(v, genislik = 720, yukseklik = 220) {
  v <- v[is.finite(v)]
  if (length(v) < 2 || diff(range(v)) == 0) {
    return("<p class=\"not\">Dagilim cizilemedi: deger sacilimi yok.</p>")
  }
  # Ust %2'lik kuyruk grafigi okunamaz hale getiriyor; cizimden kirpilir.
  ust <- stats::quantile(v, 0.98)
  vg <- v[v <= ust]
  h <- graphics::hist(vg, breaks = 40, plot = FALSE)
  if (max(h$counts) == 0) return("")

  sol <- 8; sag <- 8; alt <- 26
  ic_g <- genislik - sol - sag
  ic_y <- yukseklik - alt
  n <- length(h$counts)
  bar_g <- ic_g / n
  olcek <- ic_y / max(h$counts)

  cubuklar <- vapply(seq_len(n), function(i) {
    yuk <- h$counts[i] * olcek
    sprintf('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" class="cubuk"/>',
            sol + (i - 1) * bar_g, ic_y - yuk, max(bar_g - 1, 0.5), yuk)
  }, character(1))

  # Medyan ve %95 cizgileri
  q <- stats::quantile(v, c(0.50, 0.95))
  konum <- function(x) {
    sol + (x - min(h$breaks)) / (max(h$breaks) - min(h$breaks)) * ic_g
  }
  cizgiler <- character(0)
  for (k in seq_along(q)) {
    if (q[k] >= min(h$breaks) && q[k] <= max(h$breaks)) {
      x <- konum(q[k])
      etiket <- if (k == 1) "medyan" else "%95"
      cizgiler <- c(cizgiler, sprintf(
        paste0('<line x1="%.1f" y1="0" x2="%.1f" y2="%.1f" class="isaret"/>',
               '<text x="%.1f" y="%.1f" class="isaret-etiket">%s</text>'),
        x, x, ic_y, x + 4, 12, etiket))
    }
  }

  paste0(
    sprintf('<svg viewBox="0 0 %d %d" class="grafik" role="img" ',
            genislik, yukseklik),
    'aria-label="CBAM maliyeti olasilik dagilimi">',
    paste(cubuklar, collapse = ""),
    paste(cizgiler, collapse = ""),
    sprintf('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" class="eksen"/>',
            sol, ic_y, genislik - sag, ic_y),
    sprintf('<text x="%d" y="%d" class="eksen-etiket">%s</text>',
            sol, yukseklik - 6, html_kacis(fmt_num(min(h$breaks)))),
    sprintf('<text x="%d" y="%d" class="eksen-etiket" text-anchor="end">%s</text>',
            genislik - sag, yukseklik - 6, html_kacis(fmt_num(max(h$breaks)))),
    '</svg>'
  )
}

#' Hesap tablosu satiri
#'
#' @param etiket Satir etiketi.
#' @param formul Acik formul metni.
#' @param deger Bicimlenmis sonuc.
#' @param birim Birim.
#' @param sinif Ek CSS sinifi.
#' @return HTML satiri.
rapor_satir <- function(etiket, formul, deger, birim, sinif = "") {
  sprintf(paste0('<tr class="%s"><td class="etiket">%s</td>',
                 '<td class="formul">%s</td>',
                 '<td class="deger">%s</td><td class="birim">%s</td></tr>'),
          sinif, html_kacis(etiket), html_kacis(formul),
          html_kacis(deger), html_kacis(birim))
}

#' CBAM hesabindan HTML rapor uret
#'
#' @param x \code{cbam_estimate()} ciktisi.
#' @param dosya Yazilacak HTML dosyasinin yolu.
#' @param baslik Rapor basligi.
#' @param firma Firma adi (istege bagli, raporun ustunde gorunur).
#' @return Yazilan dosyanin yolu (gorunmez).
cbam_rapor <- function(x, dosya, baslik = "CBAM Maliyet Raporu", firma = NULL) {
  if (!inherits(x, "cbam_estimate")) {
    stop("x, cbam_estimate() ciktisi olmali.")
  }
  i <- x$inputs
  d <- x$deterministic
  r <- x$reference
  tarih <- format(Sys.Date(), "%d.%m.%Y")

  kalan <- 1 - i$cbam_factor
  uyari <- if (!is.null(r)) cbam_dogrulama_uyarisi(r) else NULL

  # --- Ozet kartlari ---
  kartlar <- c(
    sprintf('<div class="kart"><div class="kart-deger">%s</div>
             <div class="kart-etiket">EUR / yil</div></div>',
            fmt_num(d$cost_eur)),
    sprintf('<div class="kart"><div class="kart-deger">%s</div>
             <div class="kart-etiket">EUR / ton</div></div>',
            fmt_num(d$cost_per_tonne, 2)),
    sprintf('<div class="kart"><div class="kart-deger">%s</div>
             <div class="kart-etiket">tCO2e sertifika</div></div>',
            fmt_num(d$certificates)),
    sprintf('<div class="kart"><div class="kart-deger">%%%s</div>
             <div class="kart-etiket">emisyonun vergilenen orani</div></div>',
            fmt_num(100 * d$taxed_share, 1))
  )

  # --- Hesap tablosu ---
  satirlar <- c(
    rapor_satir("Gomulu emisyon",
                sprintf("%s ton x %s", fmt_num(i$quantity),
                        fmt_num(i$ei_total, 3)),
                fmt_num(d$embedded), "tCO2e"),
    rapor_satir("Ucretsiz tahsisat",
                sprintf("%s x %s x %s", fmt_num(i$benchmark, 3),
                        fmt_num(i$quantity), fmt_num(kalan, 3)),
                paste0("−", fmt_num(d$free_allocation)), "tCO2e")
  )
  if (i$carbon_price_paid > 0) {
    satirlar <- c(satirlar,
      rapor_satir("Mensede odenen karbon", "",
                  paste0("−", fmt_num(i$quantity * i$carbon_price_paid /
                                        i$cbam_reference_price)), "tCO2e"))
  }
  satirlar <- c(satirlar,
    rapor_satir("Sertifika yukumlulugu", "", fmt_num(d$certificates),
                "tCO2e", "toplam"),
    rapor_satir("CBAM maliyeti",
                sprintf("%s x %s EUR", fmt_num(d$certificates),
                        fmt_num(i$carbon_price, 2)),
                fmt_num(d$cost_eur), "EUR", "toplam"))
  if (i$fx_rate != 1) {
    satirlar <- c(satirlar,
      rapor_satir("", sprintf("x %s TRY/EUR (bugunku kur)",
                              fmt_num(i$fx_rate, 2)),
                  fmt_num(d$cost_local), "TRY"))
  }

  # --- Belirsizlik bolumu ---
  belirsizlik <- ""
  if (!is.null(x$simulation)) {
    v <- x$simulation$draws$cost_eur
    q <- stats::quantile(v, c(0.05, 0.25, 0.50, 0.75, 0.95))
    yuzdelik <- paste(vapply(seq_along(q), function(k) {
      sprintf('<tr><td>%s</td><td class="deger">%s</td></tr>',
              c("%5 (iyimser)", "%25", "Medyan", "%75",
                "%95 (VaR)")[k], fmt_num(q[k]))
    }, character(1)), collapse = "")

    ufuk_notu <- if (i$horizon == 0) {
      "Yukumluluk yili baz yil ile ayni; fiyat ve kur belirsizligi yok.
       Asagidaki aralik yalnizca tesis verimliligi sacilimindan gelir."
    } else {
      sprintf("Karbon fiyati ve doviz kuru %g yillik ufukta Geometrik Brown
               Hareketi ile, tesis verimliligi lognormal dagilimla oynatildi.
               %s bagimsiz senaryo kosuldu.", i$horizon, fmt_num(i$n_sims))
    }

    belirsizlik <- sprintf('
<section>
  <h2>Belirsizlik</h2>
  <p>%s</p>
  %s
  <div class="iki-sutun">
    <table class="yuzdelik">
      <thead><tr><th>Senaryo</th><th class="deger">EUR / yil</th></tr></thead>
      <tbody>%s</tbody>
    </table>
    <div class="yorum">
      <p><strong>Butcelenmesi gereken rakam %%95 senaryosudur.</strong>
      Medyan zamanin yarisinda asilir; tek bir sayiya gore butce yapan
      taraf, ihtimallerin yarisinda yanilir.</p>
      <p class="not">Grafikte ust %%2&#39;lik kuyruk okunabilirlik icin
      kirpilmistir; yuzdelik tablosu tam dagilimdan hesaplanmistir.</p>
    </div>
  </div>
</section>', ufuk_notu, svg_histogram(v), yuzdelik)
  }

  # --- Uyari bloku ---
  uyari_html <- if (!is.null(uyari)) {
    sprintf('<div class="uyari"><strong>%s</strong><ul>%s</ul></div>',
            html_kacis(uyari[1]),
            paste(sprintf("<li>%s</li>", html_kacis(trimws(uyari[-1]))),
                  collapse = ""))
  } else ""

  # --- Provenans ---
  prov <- c(
    sprintf("<tr><td>Ihracat miktari</td><td>%s ton/yil</td><td></td></tr>",
            fmt_num(i$quantity)),
    sprintf("<tr><td>Emisyon yogunlugu</td><td>%s tCO2e/ton</td><td>%s</td></tr>",
            fmt_num(i$ei_direct, 3),
            html_kacis(if (!is.null(r)) r$yogunluk_kaynak else "kullanici girdisi")),
    sprintf("<tr><td>AB ETS benchmark</td><td>%s tCO2e/ton</td><td>%s</td></tr>",
            fmt_num(i$benchmark, 3),
            html_kacis(if (!is.null(r)) r$benchmark_kaynak else "kullanici girdisi")),
    sprintf("<tr><td>CBAM faktoru (%d)</td><td>%%%s</td><td>Reg. (EU) 2023/956</td></tr>",
            i$year, fmt_num(100 * i$cbam_factor, 1)),
    sprintf("<tr><td>Karbon fiyati</td><td>%s EUR/tCO2e</td><td>kullanici girdisi</td></tr>",
            fmt_num(i$carbon_price, 2)),
    sprintf("<tr><td>Doviz kuru</td><td>%s TRY/EUR</td><td>kullanici girdisi</td></tr>",
            fmt_num(i$fx_rate, 2)),
    sprintf("<tr><td>Zaman ufku</td><td>%g yil</td><td>baz yil %d</td></tr>",
            i$horizon, i$base_year),
    sprintf("<tr><td>Rastgele tohum</td><td>%s</td><td>tekrarlanabilirlik</td></tr>",
            html_kacis(as.character(i$seed))),
    sprintf("<tr><td>Referans veri paketi</td><td>%s</td><td>%s</td></tr>",
            html_kacis(if (!is.null(r)) r$veri_surumu else "-"),
            if (!is.null(r) && isTRUE(r$dogrulandi)) "dogrulandi"
            else "<strong>DOGRULANMADI</strong>")
  )

  html <- sprintf('<!doctype html>
<html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%s</title>
<style>
  :root { --ink:#1a1a1a; --soft:#666; --line:#ddd; --bg:#fff;
          --vurgu:#1f4e5f; --uyari-bg:#fff4e5; --uyari-ink:#8a4b00; }
  * { box-sizing:border-box; }
  body { margin:0; padding:2rem 1.25rem; background:var(--bg); color:var(--ink);
         font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; }
  .sayfa { max-width:820px; margin:0 auto; }
  header { border-bottom:3px solid var(--vurgu); padding-bottom:1rem;
           margin-bottom:1.5rem; }
  h1 { margin:0 0 .25rem; font-size:1.6rem; }
  .altbilgi { color:var(--soft); font-size:.9rem; }
  h2 { font-size:1.15rem; margin:2rem 0 .75rem; color:var(--vurgu);
       border-bottom:1px solid var(--line); padding-bottom:.35rem; }
  .kartlar { display:flex; flex-wrap:wrap; gap:.75rem; margin:1.5rem 0; }
  .kart { flex:1 1 160px; border:1px solid var(--line); border-radius:6px;
          padding:.9rem 1rem; }
  .kart-deger { font-size:1.5rem; font-weight:600; letter-spacing:-.02em; }
  .kart-etiket { color:var(--soft); font-size:.8rem; margin-top:.2rem; }
  table { width:100%%; border-collapse:collapse; font-size:.95rem; }
  th,td { padding:.5rem .6rem; border-bottom:1px solid var(--line);
          text-align:left; vertical-align:top; }
  th { font-size:.8rem; text-transform:uppercase; letter-spacing:.04em;
       color:var(--soft); }
  .deger { text-align:right; font-variant-numeric:tabular-nums;
           white-space:nowrap; }
  .formul { color:var(--soft); font-size:.85rem;
            font-family:ui-monospace,SFMono-Regular,Consolas,monospace; }
  .birim { color:var(--soft); font-size:.85rem; white-space:nowrap; }
  tr.toplam td { font-weight:600; border-top:2px solid var(--ink);
                 border-bottom:none; }
  .uyari { background:var(--uyari-bg); color:var(--uyari-ink);
           border-left:4px solid currentColor; padding:.9rem 1rem;
           border-radius:0 4px 4px 0; margin:1.25rem 0; font-size:.92rem; }
  .uyari ul { margin:.5rem 0 0; padding-left:1.1rem; }
  .grafik { width:100%%; height:auto; margin:1rem 0 .5rem; }
  .cubuk { fill:var(--vurgu); opacity:.75; }
  .isaret { stroke:#c0392b; stroke-width:1.5; stroke-dasharray:4 3; }
  .isaret-etiket { fill:#c0392b; font-size:11px; }
  .eksen { stroke:var(--ink); stroke-width:1; }
  .eksen-etiket { fill:var(--soft); font-size:11px; }
  .iki-sutun { display:flex; flex-wrap:wrap; gap:1.5rem; align-items:flex-start; }
  .iki-sutun > * { flex:1 1 280px; }
  .yorum p { margin:0 0 .75rem; }
  .not { color:var(--soft); font-size:.85rem; }
  footer { margin-top:2.5rem; padding-top:1rem; border-top:1px solid var(--line);
           color:var(--soft); font-size:.82rem; }
  @media print {
    body { padding:0; font-size:11pt; }
    h2 { page-break-after:avoid; }
    section { page-break-inside:avoid; }
  }
</style></head><body><div class="sayfa">

<header>
  <h1>%s</h1>
  <div class="altbilgi">%s%s &middot; %s</div>
</header>

%s

<div class="kartlar">%s</div>

<section>
  <h2>Hesap</h2>
  <table>
    <thead><tr><th>Kalem</th><th>Formul</th>
    <th class="deger">Deger</th><th></th></tr></thead>
    <tbody>%s</tbody>
  </table>
  <p class="not">Her ara adim gorunurdur; sonuc kagit uzerinde
  dogrulanabilir. 2034&#39;te CBAM faktoru %%100 oldugunda ucretsiz tahsisat
  sifirlanir ve benchmark hesaptan tamamen duser.</p>
</section>

%s

<section>
  <h2>Girdiler ve Kaynaklar</h2>
  <table>
    <thead><tr><th>Parametre</th><th>Deger</th><th>Kaynak</th></tr></thead>
    <tbody>%s</tbody>
  </table>
</section>

<footer>
  <p><strong>stochastic-cbam-engine</strong> &middot; Selahattin
  &#304;lhan &middot; ORCID 0009-0007-4824-752X<br>
  A&#199;IK KAYNAK &middot; AGPL-3.0-or-later &middot;
  github.com/ContinentOfGrinch/stochastic-cbam-engine</p>
  <p>Bu rapor a&#231;&#305;k kaynakl&#305; bir hesap motoruyla
  &#252;retilmi&#351;tir; y&#246;ntemin tamam&#305; denetlenebilir.
  Beyan, yat&#305;r&#305;m veya fiyatlama karar&#305; i&#231;in tek
  ba&#351;&#305;na yeterli de&#287;ildir. &#199;eli&#351;ki halinde resm&#238;
  mevzuat metni ge&#231;erlidir.</p>
</footer>

</div></body></html>',
    html_kacis(baslik),
    html_kacis(baslik),
    if (!is.null(firma)) paste0(html_kacis(firma), " &middot; ") else "",
    if (!is.null(r)) html_kacis(r$urun_adi) else "Kullanici tanimli urun",
    sprintf("%s tarihinde uretildi", tarih),
    uyari_html,
    paste(kartlar, collapse = ""),
    paste(satirlar, collapse = ""),
    belirsizlik,
    paste(prov, collapse = "")
  )

  dizin <- dirname(dosya)
  if (!dir.exists(dizin)) dir.create(dizin, recursive = TRUE)
  writeLines(html, dosya, useBytes = TRUE)
  invisible(dosya)
}

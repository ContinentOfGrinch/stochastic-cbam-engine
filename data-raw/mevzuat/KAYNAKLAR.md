# Resmî Kaynak Belgeler

Bu klasördeki belgeler **AB'nin resmî yayınlarıdır ve değiştirilmemiştir.**
`data/` altındaki işlenmiş veri tamamen buradan türetilir.

Avrupa Komisyonu belgeleri, Komisyon'un yeniden kullanım kararı kapsamında
kaynak belirtilerek serbestçe kullanılabilir. Bu klasördeki belgelerin telif
durumu, projenin AGPLv3 kod lisansından **ayrıdır** — kod AGPLv3, belgeler
AB yeniden kullanım koşullarına tabidir.

> **Çelişki halinde resmî metin geçerlidir.** `data/` altındaki değerler bu
> belgelerden elle aktarılmıştır. Bir uyuşmazlık görürsen resmî metni esas al
> ve lütfen hata bildir.

---

## İndirilecek belgeler

Her belge indirildikten sonra aşağıdaki tabloyu doldur. SHA256 almak için:

```bash
# PowerShell
Get-FileHash -Algorithm SHA256 data-raw/mevzuat/<dosya>

# Linux / macOS
sha256sum data-raw/mevzuat/<dosya>
```

| # | Belge kimliği | Ne için gerekli | Dosya | İndirme tarihi | SHA256 | Durum |
|---|---|---|---|---|---|---|
| 1 | `REG-2023-956` | CBAM Tüzüğü. Phase-in takvimi, **Ek I** (kapsamdaki ürünler + CN kodları), **Ek II** (yalnız doğrudan emisyon sayılan ürünler), Ek IV (hesap yöntemi) | — | — | — | ⬜ |
| 2 | `CIR-BENCHMARK` | AB ETS ürün benchmark değerleri (uygulama tüzüğü) | — | — | — | ⬜ |
| 3 | `CIR-2023-1773` | Geçiş dönemi raporlama tüzüğü + ekleri; Komisyon'un varsayılan değerleri | — | — | — | ⬜ |
| 4 | `OMNIBUS-2025` | De minimis eşiği ve sadeleştirme tadilleri | — | — | — | ⬜ |

### Öncelik sırası

**1 numara her şeyden önce gelir.** İçindeki **Ek II** şu soruyu kesin olarak
cevaplıyor: *alüminyum ve demir-çelik için dolaylı (elektrik) emisyonlar CBAM
yükümlülüğüne giriyor mu?*

Bu tek maddenin pratik karşılığı, 15.000 tonluk bir alüminyum ihracatçısı için
2034'te **136 EUR/ton ile 608 EUR/ton arasındaki fark** — yani yılda yaklaşık
7 milyon EUR. `data/urunler.csv` içindeki `dolayli_kapsamda` sütunu şu an
doğrulanmamış bir varsayım taşıyor ve bu belge gelene kadar öyle kalacak.

---

## Belge nasıl eklenir

1. Belgeyi bu klasöre indir, **dosya adını değiştirme, içeriğine dokunma**
2. SHA256'sını al, yukarıdaki tabloya işle
3. `data/` altındaki ilgili CSV'ye değerleri aktar — `kaynak_belge` sütununa
   belge kimliğini, `kaynak_yeri` sütununa madde/ek/satır referansını yaz
4. O satırın `durum` sütununu `dogrulandi` yap
5. `Rscript tests/test_engine.R` çalıştır — veri bütünlüğü testleri geçmeli

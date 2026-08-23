# Katkı Rehberi

Katkıya açığız. Bu dosya iki şeyi anlatır: katkının nasıl kaydedildiği ve
projenin hangi disiplinlere sadık kaldığı.

---

## 1. Katkı Sertifikası (DCO) — zorunlu

Bu proje **Developer Certificate of Origin (DCO) 1.1** kullanır. CLA yoktur,
imzalanacak evrak yoktur, avukat gerekmez. Tek gereken commit'lerine bir
satır eklemek:

```bash
git commit -s -m "Mesajınız"
```

`-s` bayrağı commit mesajına şunu ekler:

```
Signed-off-by: Ad Soyad <eposta@ornek.com>
```

Bu satırı ekleyerek aşağıdaki beyanda bulunmuş olursun. Beyanın tam metni:

> **Developer Certificate of Origin 1.1**
>
> Bu katkıya bir "Signed-off-by" satırı ekleyerek şunları beyan ederim:
>
> **(a)** Katkı tamamen ya da kısmen benim tarafımdan oluşturuldu ve onu bu
> dosyada belirtilen açık kaynak lisansı altında sunma hakkına sahibim; ya da
>
> **(b)** Katkı, bildiğim kadarıyla uygun bir açık kaynak lisansı kapsamındaki
> önceki bir çalışmaya dayanıyor ve bu çalışmanın lisansı altında değişiklik
> yapma ve sunma hakkına sahibim — ki bu katkıyı, kaynağını ve varsa lisans
> bilgisini koruyarak aynı lisansla sunuyorum; ya da
>
> **(c)** Katkı, (a), (b) veya (c) maddelerini beyan etmiş bir başkası
> tarafından bana doğrudan sağlandı ve ben onu değiştirmedim.
>
> **(d)** Bu projenin ve katkının açık olduğunu, gönderdiğim katkının
> (Signed-off-by satırındaki kişisel bilgiler dahil) kalıcı olarak kayıtlı
> kalacağını ve bu projeyle veya ilgili açık kaynak lisanslarıyla tutarlı
> şekilde süresiz olarak yeniden dağıtılabileceğini anlıyorum ve kabul ediyorum.

DCO'nun resmî İngilizce metni: <https://developercertificate.org/>

**Neden CLA değil de DCO?** CLA yalnızca katkıcıların kodunu farklı bir
lisansla yeniden lisanslayabilmek için gerekir. Bu projenin amacı kullanıcıdan
gelir elde etmek değil, yaygın kullanım ve atıf. Dolayısıyla CLA'nın getireceği
bürokrasi katkıcıyı caydırmaktan başka bir işe yaramaz.

Katkın, kendi telif hakkın sende kalarak, projenin AGPL-3.0-or-later lisansı
ve [`LICENSE-ADDITIONAL-TERMS.md`](LICENSE-ADDITIONAL-TERMS.md) ek şartları
altında dağıtılır.

---

## 2. Katkı Göndermeden Önce

```bash
Rscript tests/test_engine.R     # hepsi geçmeli
```

Yeni davranış eklediysen **testini de yaz.** Bir hatayı düzelttiysen, o hatayı
yakalayan bir gerileme testi ekle — düzeltmenin geri gelmemesi için.

---

## 3. Projenin Değişmez Kuralları

Bu kurallar tartışmaya kapalı değil ama değiştirmek istiyorsan önce bir issue
açıp gerekçeni yaz. Hepsinin bir sebebi var.

### Çalışma zamanında sıfır bağımlılık

Motor yalnızca R'ın `base` ve `stats` paketlerini kullanır. Kullanıcı hiçbir
paket kurmaz. Sebep: tekrarlanabilirlik — beş yıl sonra da `Rscript` ile
çalışsın, paket sürüm cehennemi olmasın.

Veri hazırlama betikleri (build zamanı) bağımlılık kullanabilir; bunlar
kullanıcıya ulaşmaz.

### Canlı veri çekilmez

Araç hiçbir sunucuya istek göndermez ve hiçbir kullanıcı verisini dışarı
çıkarmaz. Rapor dosyaları da dahil — üretilen HTML internet olmadan açılır.
Bu bir kısıt değil, projenin varlık sebebi.

### Değer uydurulmaz

Kaynağı gösterilemeyen hiçbir sayı `dogrulandi` olarak işaretlenemez. Bir
satır `durum=dogrulandi` diyorsa `kaynak_belge` sütunu dolu olmak **zorundadır**
— bu kural test altındadır. Doğrulanmamış değerler çıktıda açıkça işaretlenir.

### Motor katmanı I/O yapmaz

`R/` altındaki hesap fonksiyonları saf olmalıdır: dosya okumaz, konsola
yazmaz, ağa çıkmaz. Tüm sunum `R/calculator.R`, `R/report.R` ve `hesapla.R`
içindedir. Bu ayrım, motorun test edilebilir ve yeniden kullanılabilir
kalmasını sağlar.

### Kapsam dar tutulur

Yeni bir özellik önerirken **"bu neyin yerine geçiyor?"** sorusunu cevapla.
Proje bir *CBAM karar destek aracıdır* — uyum/beyan yazılımı değildir.
`research/` altındaki araştırma eklentileri hesap makinesine bağlanmaz.

---

## 4. Kod Biçimi

- Satırlar 80 karakteri geçmesin
- Fonksiyon ve parametre adları İngilizce ve `snake_case`
- Kullanıcıya görünen metin Türkçe
- Yorumlar mevcut dosyaların üslubunu izlesin
- Yorumlar **neden** olduğunu anlatsın, **ne** yaptığını değil — kod zaten
  ne yaptığını söylüyor

---

## 5. Hata Bildirimi

Özellikle değerli olan bildirimler:

- **Mevzuata aykırılık.** Kodun bir iddiası resmî metinle çelişiyorsa,
  belgeyi ve madde numarasını da yaz. Kodun bulunduğu iddiaların listesi
  `data-raw/mevzuat/MEVZUAT_DOGRULAMA.md` içindedir.
- **Yanlış referans değeri.** Kaynağını göster.
- **Sessizce yanlış sonuç.** Hata vermeden yanlış sayı üreten her durum
  en yüksek öncelikli hatadır.

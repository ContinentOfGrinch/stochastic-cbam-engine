# stochastic-cbam-engine
Open-source stochastic MRIO framework for Carbon Border Adjustment Mechanism (CBAM) exposure analysis.
# Stochastic CBAM Engine 
> Open-source stochastic MRIO framework for Carbon Border Adjustment Mechanism (CBAM) exposure analysis.

Bu proje, AB Sınırda Karbon Düzenleme Mekanizması'nın (SKDM) ihracatçılar üzerindeki etkisini sektörel ortalamalara sıkışmadan, stokastik belirsizlikler ve mikro düzey firma verileriyle hesaplayan açık kaynaklı bir ekonometrik laboratuvardır.

##  Proje Vizyonu ve Kapsamı
Piyasadaki kapalı kutu (black-box) danışmanlık araçlarının aksine, bu altyapı **açık bilim (open-science)** ve **tekrarlanabilirlik (reproducibility)** ilkeleriyle inşa edilmiştir.

* **Odak Ülke:** Türkiye
* **Odak Sektör:** Demir ve Çelik (Modüler yapı ile genişletilebilir)
* **Veritabanı:** EXIOBASE / WIOD 

##  Metodolojik Çerçeve
Proje, yasal olarak vergilendirilen emisyonlar ($E_{CBAM}$) ile tedarik zincirindeki toplam emisyonları ($E_{MRIO}$) birbirinden ayırır. Sektörel makro Girdi-Çıktı matrisleri, firma düzeyindeki heterojen teknoloji katsayıları ile esnetilir:

$$ EI_f = EI_s \times \theta_f $$

*(Burada $EI_f$ firmanın spesifik emisyon yoğunluğunu, $EI_s$ sektör ortalamasını ve $\theta_f$ teknoloji ayarlama katsayısını temsil eder.)*

## 🎲 Belirsizlik ve Risk Modellemesi
Sistem deterministik tek bir sonuç vermek yerine, Monte Carlo simülasyonları kullanarak;
* EU ETS Karbon fiyatı volatilitesini,
* Döviz kuru dalgalanmalarını hesaba katar ve kullanıcılara **%90 Güven Aralığında** risk olasılık dağılımları sunar.

##  Lisanslama ve Fikri Mülkiyet
Bu altyapı **AGPLv3 (GNU Affero General Public License v3.0)** ile lisanslanmıştır. Akademik araştırmalarda serbestçe kullanılabilir ve atıf yapılarak geliştirilebilir. Ticari kullanım ve kapalı sistem entegrasyonları için "Çifte Lisanslama" (Dual Licensing) modeli uygulanmaktadır.

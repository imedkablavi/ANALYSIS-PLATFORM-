# Proje Önerisi — Türkçe

## Proje Adı

**Ağ Tabanlı Şüpheli Davranış Örüntülerinin Analizi ve Multimedya Destekli Görselleştirilmesi**

## Proje Tanımı

Bu projede, bilgisayar ağı trafiği kullanılarak ağdaki host'ların (IP adresleri / bilgisayarlar) gözlemlenebilir davranış örüntülerinin analiz edilmesi amaçlanmaktadır. Birincil veri seti, etiketli botnet trafiği içeren **CTU-13**'tür; **CIC-IDS2017**, **UNSW-NB15** ve **LANL** veri setleri de desteklenmektedir. Bu veri setlerindeki yayımlanmış etiketler (botnet / saldırı / red team) yalnızca tespit başarısını ölçmek için, puanlamadan sonra kullanılır; IP adresleri içe aktarma sırasında takma adlara dönüştürülür. Sistem, zaman, etkileşim, ağ yapısı ve olay sırası gibi farklı davranış boyutlarını birlikte değerlendirerek normal davranıştan sapmaları belirleyecektir.

Projenin temel farkı, yalnızca bir ağ grafiği veya basit bir makine öğrenmesi modeli geliştirmek yerine veri işleme, davranış profili oluşturma, zamansal analiz, graph/network analizi, sequence analizi, anomaly detection, pattern mining ve explainable analysis aşamalarını tek bir sistem içinde birleştirmesidir.

Tespit sonucu doğrudan “host'un ele geçirildiği” veya “kişinin suçlu olduğu” şeklinde yorumlanmayacaktır. Sistem, yalnızca gözlemlenebilir veriler üzerinden normal davranış modelinden sapma gösteren örüntüleri analitik sinyal olarak gösterecektir.

## Sistem Akışı

Ağ Trafiği Verisi (CTU-13, CIC-IDS2017, UNSW-NB15, LANL) → Veri Doğrulama → Ön İşleme → Özellik Çıkarma → Davranış Profili → Zaman Analizi → Network/Graph Analizi → Sequence Analizi → Anomaly Detection → Pattern Mining → Açıklanabilir Sonuç → Etkileşimli Multimedya Arayüzü

## Multimedya Bölümü

Sistem MATLAB App Designer kullanılarak geliştirilecektir. Kullanıcı; network graph, timeline, heatmap, grafikler, davranış profili, anomaly sonuçları ve event replay üzerinden veriyi etkileşimli olarak inceleyebilecektir.

## Kullanılacak Teknolojiler

- MATLAB — ana geliştirme dili
- MATLAB App Designer — uygulama ve kullanıcı arayüzü
- Statistics and Machine Learning Toolbox — anomaly detection ve istatistiksel analiz
- Computer Vision / Image Processing / Signal Processing / Audio Toolbox — yalnızca veri yapısı gerektiriyorsa
- Python — yalnızca yardımcı veri dönüşümü veya özel bir kütüphane gerektiğinde

## Beklenen Sonuç

Proje sonunda gerçek veriler üzerinde çalışan, davranış örüntülerini analiz edebilen, anomalileri ölçebilen, sonuçların nedenlerini açıklayabilen ve bütün bu bilgileri etkileşimli multimedya araçlarıyla kullanıcıya sunabilen bir MATLAB uygulaması ortaya çıkarılması hedeflenmektedir.

## Değerlendirme

Ağ veri setlerinde etiketler bulunduğundan, sistemin şüpheli host'ları ne kadar iyi sıraladığı ROC-AUC, ortalama kesinlik (şans düzeyiyle karşılaştırmalı) ve ilk k'deki kesinlik ile ölçülecektir. Ayrıca hangi davranış özelliği grubunun (trafik, ağ yapısı, zaman, dizi) tespite katkı sağladığı ablasyon deneyiyle incelenecektir.

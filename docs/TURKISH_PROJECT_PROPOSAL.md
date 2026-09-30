# Proje Önerisi — Türkçe

## Proje Adı

**Ağ Tabanlı Şüpheli Davranış Örüntülerinin Analizi ve Multimedya Destekli Görselleştirilmesi**

## Proje Tanımı

Bu projede, gerçek ve anonimleştirilmiş ağ/etkileşim verileri kullanılarak bireylerin veya ağ içindeki varlıkların gözlemlenebilir davranış örüntülerinin analiz edilmesi amaçlanmaktadır. Sistem, zaman, etkileşim, ağ yapısı ve olay sırası gibi farklı davranış boyutlarını birlikte değerlendirerek normal davranıştan sapmaları belirleyecektir.

Projenin temel farkı, yalnızca bir ağ grafiği veya basit bir makine öğrenmesi modeli geliştirmek yerine veri işleme, davranış profili oluşturma, zamansal analiz, graph/network analizi, sequence analizi, anomaly detection, pattern mining ve explainable analysis aşamalarını tek bir sistem içinde birleştirmesidir.

Tespit sonucu doğrudan “kişinin suçlu olduğu” şeklinde yorumlanmayacaktır. Sistem, yalnızca gözlemlenebilir veriler üzerinden normal davranış modelinden sapma gösteren örüntüleri analitik sinyal olarak gösterecektir.

## Sistem Akışı

Gerçek Veri → Veri Doğrulama → Ön İşleme → Özellik Çıkarma → Davranış Profili → Zaman Analizi → Network/Graph Analizi → Sequence Analizi → Anomaly Detection → Pattern Mining → Açıklanabilir Sonuç → Etkileşimli Multimedya Arayüzü

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

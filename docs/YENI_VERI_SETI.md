# Yeni bir veri seti açma

Uygulama, CTU-13 dosyası dışında aynı tür bağlantı kayıtlarını da içe aktarır.
Desteklenen metin dosyaları CSV, TSV, TXT ve binetflow biçimleridir. Kaynak ve
hedef bir IP adresi veya cihaz kimliği olabilir; zaman alanı zorunludur.

## Uygulamadan

1. **Veri seti aç** düğmesiyle dosyayı seçin.
2. Tanınan veri düzenini kontrol edin. CTU-13, CIC-IDS2017, UNSW-NB15 ve LANL
   düzenleri kendi alan ve birim kurallarını kullanır.
3. Dosyanız farklıysa özel bağlantı sütunlarını seçin. Kaynak, hedef ve zamanı
   eşleştirin. Süre, bayt, paket, port ve protokol alanları isteğe bağlıdır.
4. Sayısal zaman için doğru birimi seçin: Unix saniye/milisaniye, Excel,
   MATLAB seri tarih veya YYYYMMDD. Metin tarihleri belirsizse biçimini belirtin.
   Otomatik seçim, tanınan profilin zaman kuralını korur.
5. Büyük bağlantı dosyalarında ilk kaydı ve en fazla okunacak kayıt sayısını
   belirleyin. Sıfır üst sınır tüm kayıtlar demektir. Bu seçim, olay/kenar
   tabloları için kullanılmaz; bu tablolar tam okunur.
6. Analizi başlatın. Yeni sonuç ayrı bir veri seti kimliğiyle kaydedilir;
   başka bir dosyanın zaman aralığı veya hesaplanmış puanları devralınmaz.

Kaynak/hedef/zaman alanları yanlış tahmin edildiyse sütun eşleştirmesini
düzeltebilirsiniz. Yalnızca `source`, `target`, `time` içeren genel bağlantı
listesi otomatik olarak zamanlı kenar listesi kabul edilir; trafik alanlarını
kullanmak için özel ağ akışları düzenini açıkça seçin.

## Komutla

Aşağıdaki sütun adlarını kendi dosyanızdaki adlarla değiştirin:

```matlab
addpath scripts
setupProject()
opts = struct('format', "network_flow", 'profile', "generic_network_flow", ...
    'mapping', struct('src', "client", 'dst', "server", 'time', "started_at", ...
                     'bytes', "total_bytes", 'proto', "protocol"), ...
    'time_unit', "posix_ms");
b = analyzeDataset("data/external/my_connections.csv", opts);
app = NetworkBehaviorExplorer(b);
```

Metin tarih biçimi gerektiğinde `opts.time_formats = "dd.MM.yyyy HH:mm:ss"`
kullanın. Genel akışlarda süre saniye, veri miktarı bayt, paketler adet olarak
okunur. Mikrosaniye süreyi saniyeymiş gibi eşleştirmeyin; bilinen profilin birim
kuralını kullanın veya dönüşümü kaynak hazırlama adımında açıkça belgeleyin.

## Etiketler ve eksik alanlar

Özel bağlantı dosyasındaki bir `label` sütunu kendiliğinden saldırı etiketi
kabul edilmez. Etiket anlamı doğrulanmadıysa kayıtlar bilinmeyen olarak kalır.
Model yine davranış sapmalarını sıralayabilir; doğruluk/tespit başarısı ölçümü
uydurulmaz. Eksik trafik ölçümleri sıfırla doldurulmuş gözlem gibi gösterilmez.

Dosya bir Excel çalışma kitabı, sıkıştırılmış arşiv, PCAP veya Parquet ise
önce desteklenen metin düzenine dönüştürün. Sütun seçmek bu dosya türlerini
okunabilir hâle getirmez. Bu içe aktarıcı genel amaçlı JSON okuyucusu değildir;
yalnızca belgelenmiş eski NetworkX şeması desteklenir.

## Doğrulama

İki bağımsız resmi dosya yerel kaynak denetiminden geçirilmiştir: CTU-13
senaryo 7 ve 11. Yeni özel eşleştirmeler, tarih birimleri ve ardışık bağımsız
analizler için MATLAB regresyon testleri eklenmiştir. Mevcut ortamda MATLAB
olmadığından bu testlerin çalıştırıldığı veya arayüzün açıldığı iddia edilmez.

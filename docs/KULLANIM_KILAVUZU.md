# Ağ Davranışı Analizi

Uygulama, bağlantı kayıtlarından cihazların iletişim alışkanlıklarını çıkarır.
Bir cihazı seçerek model puanlarını, bu puanlarla birlikte sunulan ölçümleri
ve ilgili bağlantı kayıtlarını inceleyebilirsiniz.

## Veri seti açma

**Veri seti aç** düğmesinden dosyanızı seçin. CTU-13 için `.binetflow`, diğer
desteklenen düzenler için CSV, TSV veya TXT dosyası kullanın. Genel bir olay
tablosunda varlık ve zaman; bağlantı tablosunda kaynak, hedef ve zaman alanları
gerekir. Uygulama bu alanları tanıyamazsa karşılık gelen sütunları seçmenizi ister.

Dosya incelendikten sonra analiz başlar. Kaynak dosya değiştirilmez. Analiz
kaydedilir ve veri seti listesinden yeniden açılabilir. Büyük bir dosyanın yalnızca
bir bölümünü kullanırsanız kayıt aralığını analiz bilgileriyle birlikte saklayın.

## Bir cihazı inceleme

Listeden bir cihaz seçin. Ağ görünümü komşularını, zaman çizelgesi etkinliğini
gösterir. Ayrıntı bölümünde model puanları ve referans gruptan en çok ayrılan
ölçümler yer alır. Bağlantı tablosunda zaman, yön, protokol, port, süre ve trafik
miktarı bulunur; gösterilen kayıt sayısı sınırlıysa toplam sayı ayrıca belirtilir.

Puanın yüksek olması cihazın diğer cihazlardan farklılaştığını gösterir.
Bu puan bir saldırı olasılığı değildir. Veri setinin yayımlanmış etiketleri
varsa model karşılaştırmasında ayrıca gösterilir; modelin girdisi olarak kullanılmaz.
Yeterli geçmişi olmayan cihazlar puanlanmış cihazlarla aynı şekilde yorumlanmaz.

## Zaman aralığı

Kaydırıcıyı ve pencere uzunluğunu kullanarak bağlantıları farklı aralıklarda
inceleyin. Oynat, adım ve sıfırla düğmeleri zaman çizelgesinde ilerlemenizi sağlar.
Kayıtlı model puanları analizin tamamına aittir; zaman aralığını değiştirmek
modeli yeniden eğitmez.

## Kaynak ve dışa aktarma

Kaynak bilgileri sekmesinde dosyanın parmak izini, kullanılan kayıt aralığını,
yazılım sürümünü ve puanlanan cihaz sayısını kontrol edin. **Dışa aktar** ile
görünümleri ve seçili cihazın inceleme dosyalarını kaydedin. CSV dosyaları
ölçümleri ve bağlantıları, JSON dosyası puanların kapsamını ve seçili zaman
aralığını içerir. Bu dosyalardaki cihaz adları analiz içindeki yerel kimliklerdir.

## Dil

Üst bölümdeki **Türkçe / English** seçeneğiyle dili değiştirin. Dil değişimi
veriyi veya hesaplanan sonuçları değiştirmez. Oynatma durur; incelemeye seçili
cihaz ve zaman aralığından devam edebilirsiniz.

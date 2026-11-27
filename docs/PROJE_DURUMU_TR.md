# Ağ davranışı analizi: inceleme notu

Tarih: 4 Kasım 2026

Bu proje, ağ bağlantı kayıtlarında cihazların olağan davranışlarından ayrılan
ölçümleri incelemek için geliştirilen bir MATLAB uygulamasıdır. Amaç bir
cihazı kesin olarak saldırgan ilan etmek değil, incelenecek cihazları sıralayıp
bu sıralamanın yanında ölçümleri ve bağlantı kayıtlarını gösterebilmektir.

## Projede bulunan bölümler

- Dosya inceleme, sütun eşleme, zaman biçimi seçimi ve kayıt doğrulama.
- CTU-13, CIC-IDS2017, UNSW-NB15 ve LANL düzenlerini tanıyan içe aktarma kodu;
  ayrıca kaynak, hedef ve zaman sütunları eşlenebilen bağlantı tabloları.
- Trafik, ağ, zaman ve sıralı davranış özellikleri; istatistiksel temel yöntem
  ve Isolation Forest ile puanlama.
- Cihaz sıralaması, komşuluk ağı, etkinlik çizelgesi ve ölçüm açıklamaları.
- Türkçe/İngilizce arayüz, zaman aralığı oynatma ve CSV/JSON/görsel dışa aktarma.
- Kaynak dosya parmak izi, ayarlar, testler ve deney kayıtlarını saklayan betikler.

Bu liste kodda bulunan işlevleri gösterir. Bütün veri düzenlerinin ve arayüz
işlemlerinin son sürümde çalıştırıldığı anlamına gelmez.

## Eklenen veri

Pakete CTU-13'ün yayımlanmış 7. ve 11. senaryo bağlantı dosyaları eklenmiştir.
İki dosyanın da SHA-256
parmak izi kontrol edilir. Kaynak adresleri ve yöntem `REAL_CAPTURE_EVIDENCE.md`
dosyasındadır. Testlerdeki küçük yapay veriler uygulamanın veri kaynağı değildir.

Senaryo 7'de 114.077 bağlantı ve 38.204 cihaz bulunur. Puanlamaya uygun
cihazların yalnızca yedisinin etiketi bilinir: biri kötü amaçlı, altısı normal.
Diğer uygun cihazların etiketleri bilinmez. Bu küçük etiketli grup, tek bir
senaryodan genel başarı iddiası çıkarmayı sınırlar. Bu sayılar bağımsız veri
sayımıdır; yeni MATLAB çalıştırmasının model sonuçları henüz yoktur.

## Son inceleme ve açık işler

4 Kasım incelemesinde üç hata grubu için düzeltme ve regresyon testleri hazırlandı:

1. Kısa sayısal cihaz kimliği, metin dışa aktarılırken ölçümlerin içindeki
   rakamları da değiştirebiliyordu.
2. Isolation Forest kapalıyken bazı deneylerde kayıtlı IF sonuçları kullanılabiliyor
   ve karşılaştırma yapılamadığı halde uyum değeri sıfır yazılabiliyordu.
3. İleri/geri trafik sütunlarından biri yoksa kalan sütun toplam trafik
   olarak yorumlanabiliyordu.

Bu değişikliklerin MATLAB üzerinde regresyon çalıştırması bekleniyor. Statik
kontrol ve Python testleri MATLAB testlerinin yerine geçmez. Önceki GitHub CI
çalıştırmasında MATLAB test işi atlanmıştır. CHANGELOG'daki 114/114 sonucu
27 Ekim tarihli eski sürüme aittir.

Son sürümde yapılacaklar:

- MATLAB testlerini ve iki veri setiyle analiz akışını çalıştırmak.
- Arayüzde veri değiştirme, cihaz seçimi, TR/EN, oynatma ve dışa aktarmayı denemek.
- Oluşan model/deney sonuçlarını rapora eklemek ve sınırlarını yorumlamak.
- Sunum ve yedek gösterim kaydını hazırlamak; kullanılacaksa gerçek katılımcılarla
  kullanılabilirlik çalışmasını tamamlamak.

Bu kontroller bitmediği için `main` dalına birleştirme yapılmaması gerekir.
Güncel geliştirme incelemesi [PR #13](https://github.com/imedkablavi/ANALYSIS-PLATFORM-/pull/13)
üzerindedir. Arşivdeki `TRANSFER_STATE.json`, pakete giren dosyaları ve Git
durumunu kaydeder.

## Çalıştırma

MATLAB R2021b veya üzeri ve Statistics and Machine Learning Toolbox gerekir.
ZIP'i açın; MATLAB'da `NetworkBehaviourExplorer` klasörünü Current Folder yapın:

```matlab
addpath('scripts');
setupProject();
assert(~isempty(which('iforest')), 'Statistics and Machine Learning Toolbox gerekli.');
run('scripts/run_tests.m');
run('scripts/run_network_demo.m');
```

İlk komutlar testleri, son komut senaryo 7 analizini ve arayüzü açar. İkinci
dosyayı arayüzden `data/external/ctu13-scenario11.binetflow` yoluyla seçebilirsiniz.
Tam test ve deney kaydı için ayrıca:

```matlab
evidence = verify_delivery(fullfile('data','external','ctu13-scenario7.binetflow'));
```

Kayıtlar `outputs/verification/` altındadır. `PARTIAL`, `FAILED` ve atlanan
testler ayrıca incelenmelidir. Arayüz denemesi elle yapılır.

Kodun bölümleri `CODE_GUIDE_AR.md`, kullanıcı işlemleri `KULLANIM_KILAVUZU.md`,
yeni dosya koşulları `YENI_VERI_SETI.md`, teknik yöntem `report/TECHNICAL_REPORT.md`
dosyalarında açıklanmıştır.

# دليل التشغيل على كمبيوتر الجامعة (Windows + MATLAB)

الهدف: أول تشغيل حقيقي للمشروع، وجمع المخرجات كاملة لإصلاح أي خطأ. الوقت المتوقع: 30–60 دقيقة.

## 0. ما تحتاجه معك
- فلاشة USB، أو بريدك الجامعي لإرسال الملفات.
- حساب GitHub (المستودع خاص، تحتاج تسجيل الدخول).

## 1. تأكد من MATLAB
1. افتح MATLAB من قائمة Start.
2. في نافذة الأوامر (Command Window) اكتب:
   ```matlab
   version
   ver stats
   ```
3. المطلوب:
   - `version`: الإصدار R2021b أو أحدث.
   - `ver stats`: يظهر سطر **Statistics and Machine Learning Toolbox**.

   إن لم يظهر الـ Toolbox: تابع العمل، فالتحليل يعمل بدونه، لكن بدون Isolation Forest. سجّل ذلك.

## 2. تنزيل المشروع
1. في المتصفح افتح `https://github.com/imedkablavi/ANALYSIS-PLATFORM-` وسجّل الدخول.
2. اختر الفرع من زر الفروع (أعلى اليسار): `cybrextech/serene-gates-03tlpx`.
3. اضغط **Code ← Download ZIP**.
4. فكّ الضغط في `C:\Users\<اسمك>\Documents\ANALYSIS-PLATFORM`.
   - يجب أن ترى مباشرة داخل المجلد: `src`, `scripts`, `tests`, `app`, `configs`.
   - إن كان هناك مجلد داخل مجلد، انقل المحتوى للأعلى.
   - تجنّب المسارات التي فيها أحرف عربية أو تركية.

## 3. الدخول إلى المجلد وبدء سجل المخرجات
في MATLAB:
```matlab
cd('C:\Users\<اسمك>\Documents\ANALYSIS-PLATFORM')
diary('run_log.txt')
diary on
```
`diary` يحفظ كل ما يظهر في الشاشة في الملف `run_log.txt`. **لا تغلقه حتى النهاية.**

## 4. تنزيل البيانات
```matlab
run scripts/download_dataset.m
```
المتوقع: `Dataset matches the verified artifact.`

إذا فشل التنزيل (الإنترنت محجوب في المختبر):
1. نزّل الملف من المتصفح:
   `https://raw.githubusercontent.com/erichoang/criminal-network-visualization/main/datasets/preprocessed/israel_lea_inp_burglary_offender_id_network.json`
2. ضعه في `data\raw\` داخل مجلد المشروع.
3. أعد تشغيل الأمر.

## 5. الاختبارات
```matlab
run scripts/run_tests.m
```
- النهاية تكون سطرًا مثل: `Passed X / Y, failed Z, ...`
- إذا ظهر خطأ أحمر في المنتصف **لا تتوقف**، تابع الخطوات التالية. الهدف جمع أكبر قدر من المعلومات.

## 6. التحليل الكامل
```matlab
run scripts/run_pipeline.m
```
قد يأخذ عدة دقائق.

## 7. التجارب والصور (إن نجحت الخطوة 6)
```matlab
run scripts/run_experiments.m
run scripts/generate_report_figures.m
```

## 7ب. بيانات الشبكات (مهم: موضوع المشروع)
الكمبيوتر في الجامعة يستطيع غالبًا الوصول لمواقع التنزيل:
1. من `https://stratosphereips.org/datasets-ctu13` نزّل ملف `.binetflow` لسيناريو واحد (مثلًا السيناريو 1 أو 9).
2. ضعه في `data\external\` داخل مجلد المشروع.
3. شغّل:
   ```matlab
   b = analyzeDataset("data/external/<اسم الملف>.binetflow")
   ```
4. إن نجح: سترى في `outputs\datasets\...\tables\ground_truth_evaluation.csv` مدى دقة الكشف مقارنة بالتصنيف المنشور.
5. إن كان الملف كبيرًا جدًا أو بطيئًا: أضف `struct('max_rows', 500000)` كوسيط ثانٍ.
6. التجارب على نفس البيانات: افتح `scripts/run_experiments.m` وغيّر السطر `DATASET = "";` إلى `DATASET = "latest";`، ثم شغّل:
   ```matlab
   run scripts/run_experiments.m
   ```
   الناتج في `outputs\datasets\<id>\experiments\`، وأهم ملفين فيه هما `experiments_summary.md` و `E11_ground_truth_by_feature_set.csv`.
7. انسخ مجلد `outputs\datasets\` كاملًا إلى الفلاشة.

## 8. التطبيق
```matlab
run scripts/launch_app.m
```
جرّب:
1. اضغط على أول صف في الجدول على اليسار.
2. اضغط **Play**.
3. افتح التبويبات في الأسفل.
4. **Open dataset…**: لا تجربه الآن إلا إذا بقي وقت.

خذ لقطات شاشة (Win + Shift + S) للنافذة، وصوّر أي رسالة خطأ.

## 9. إنهاء السجل وجمع الملفات
```matlab
diary off
```
انسخ إلى الفلاشة:
- `run_log.txt` ← **الأهم**
- مجلد `outputs\` كاملًا (إن وُجد)
- لقطات الشاشة

## 10. أرسل لي
- محتوى `run_log.txt`: الصقه في المحادثة، أو ارفعه.
- لقطات الشاشة.
- رقم إصدار MATLAB، وهل الـ Toolbox موجود.

## مشاكل شائعة

| المشكلة | الحل |
|---|---|
| `Undefined function or variable 'setupProject'` | لست داخل مجلد المشروع: أعد أمر `cd` في الخطوة 3 |
| `websave` فشل / timeout | الحل اليدوي في الخطوة 4 |
| `iforest` غير معروف | الـ Toolbox غير مثبت: تابع وسجّل ذلك |
| لا صلاحية كتابة في المجلد | ضع المشروع في Documents أو Desktop وليس في C:\ مباشرة |
| MATLAB يتجمد في التطبيق | انتظر دقيقة، ثم أغلق النافذة وتابع؛ السجل محفوظ |

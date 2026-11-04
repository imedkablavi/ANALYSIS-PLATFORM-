# نقل النسخة الحالية إلى Windows وتشغيلها في MATLAB

## ما الذي تنقله؟

الحزمة مبنية من محتويات worktree الحالية، بما فيها التعديلات غير المحفوظة
والملفات الجديدة. ليست تنزيلًا لفرع `main`. تحتوي الشيفرة والاختبارات والتوثيق
وملفّي CTU-13 الرسميين للسيناريوهين 7 و11. بيانات الاختبار الصغيرة تبقى ضمن
`tests/` ولا يستخدمها التطبيق كبيانات عرض. لا توجد نتائج كاشف مجهزة مسبقًا.

`TRANSFER_STATE.json` داخل الحزمة يسجل الفرع والـcommit الأساسي والتعديلات
وبصمة SHA-256 لكل ملف منقول. `TRANSFER_GIT_DIFF.patch` يحفظ فرق الملفات المتتبعة؛
الملفات الجديدة موجودة كاملة في الحزمة. لم يُنقل ملف `.git` لأنه في worktree
يشير إلى مسار على جهاز Linux. الحزمة نسخة تشغيل مستقلة وليست نسخة بتاريخ Git كامل.

حالة الفروع الأساسية قبل تجميع مراجعة 2026-11-04:

- `main`: `ceb359b285b794a85752b9c9a35c072a7eff97a6`.
- الفرع المحلي: `fix/pr13-analysis-correctness`، أساسه `cc105ca0f1ecdf3566a484cde9bc19a411ede8b7`.
- الفرع الأساسي يتقدم على `main` بـ52 commit، وفوقه تعديلات المراجعة.
- [PR #13](https://github.com/imedkablavi/ANALYSIS-PLATFORM-/pull/13) مفتوح كمسودة،
  وفرعه `cybrextech/serene-gates-03tlpx`. عند بدء المراجعة كان عند `cc105ca`.
  المرجع الدقيق للنسخة المجمّعة وحالة تعديلاتها محفوظان داخل `TRANSFER_STATE.json`.

## المتطلبات

MATLAB R2021b أو أحدث وStatistics and Machine Learning Toolbox. استُخدمت
R2023b في إعداد CI، لكن تشغيل النسخة الحالية على جهاز التسليم ما زال مطلوبًا.
لا تحتاج Python أو Git لتشغيل الحزمة؛ Python مطلوب فقط لفحوص المرجع المستقلة
وإعادة إنشاء ZIP. تثبيت MATLAB والـToolbox يتم عبر مثبّت MathWorks بترخيصك؛
الأوامر التالية تعمل **داخل MATLAB Command Window بعد تثبيته**.

## فك الحزمة من داخل MATLAB

انسخ ZIP إلى Windows ثم نفذ التالي. نافذة اختيار الملف تتجنب كتابة اسم المستخدم
أو مسار التنزيل يدويًا. سيُنشأ مجلد جديد بجانب ملف ZIP لتجنب خلطه بنسخة قديمة.

```matlab
[zipName, zipFolder] = uigetfile('*.zip', 'Select the project transfer ZIP');
assert(~isequal(zipName, 0), 'No archive selected.');
destination = fullfile(zipFolder, ['NBE_' datestr(now, 'yyyymmdd_HHMMSS')]);
assert(~isfolder(destination), 'Destination already exists. Choose a new folder.');
unzip(fullfile(zipFolder, zipName), destination);
cd(fullfile(destination, 'NetworkBehaviourExplorer'));
addpath('scripts');
setupProject();
ver
assert(~isempty(which('iforest')), 'Install Statistics and Machine Learning Toolbox.');
```

الحزمة تتضمن بيانات التحليل أصلًا؛ لا يلزم تنزيلها. افحص المصدر ثم شغّل الاختبارات:

```matlab
[sourceOK, actualSHA] = verifyGitBlobSha(fullfile('data','external','ctu13-scenario7.binetflow'), ...
    '33065bb8bc1df911fae818e3475ee0cf96d0e0a9');
assert(sourceOK, 'Capture fingerprint mismatch: %s', actualSHA);
run('scripts/run_tests.m');
```

ثم حلل السيناريو 7 وافتح الواجهة التركية مع إمكانية التبديل إلى الإنكليزية:

```matlab
run('scripts/run_network_demo.m');
```

قد يستغرق التحليل وقتًا؛ لا توجد نتائج مصطنعة تُعرض بدل التنفيذ. عند العودة
لاحقًا إلى **نفس مجلد المشروع**، يمكن فتح آخر تحليل محفوظ:

```matlab
run('scripts/launch_app.m');
```

إذا لم يوجد تحليل محفوظ صالح، تفتح واجهة فارغة تتيح اختيار ملف.

## تنزيل البيانات مباشرة عبر MATLAB عند الحاجة

هذه أوامر إعادة الحصول على المصدر الرسمي، وليست ضرورية للحزمة المرفقة.
تتجنب استبدال الملف الموجود وتتحقق من بصمته قبل الاستخدام:

```matlab
addpath('scripts'); setupProject();
capture = fullfile('data','external','ctu13-scenario7.binetflow');
if ~isfile(capture)
    url = ['https://mcfp.felk.cvut.cz/publicDatasets/CTU-Malware-Capture-Botnet-48/' ...
        'detailed-bidirectional-flow-labels/capture20110816-2.binetflow'];
    pending = [tempname(fullfile(pwd,'data','external')) '.binetflow'];
    websave(pending, url, weboptions('Timeout', 120));
    [ok, sha] = verifyGitBlobSha(pending, '33065bb8bc1df911fae818e3475ee0cf96d0e0a9');
    assert(ok, 'Downloaded source differs; preserve it for inspection: %s', pending);
    [moved, message] = movefile(pending, capture);
    assert(moved, '%s', message);
end
[ok, sha] = verifyGitBlobSha(capture, '33065bb8bc1df911fae818e3475ee0cf96d0e0a9');
assert(ok, 'Existing capture differs: %s', sha);
```

لا يوجد رابط منشور للحزمة المحلية الحالية؛ تنزيل ZIP من GitHub سيحضر النسخة
المنشورة هناك فقط، لذلك استخدم الحزمة المنقولة للحصول على كل عمل هذه الجلسة.

## تجربة ملف آخر وحفظ أدلة التسليم

بعد انتهاء تحليل السيناريو 7، لتجربة المصدر الثاني المرفق:

```matlab
b11 = analyzeDataset(fullfile('data','external','ctu13-scenario11.binetflow'), ...
    struct('name', 'CTU-13 scenario 11', 'use_iforest', true));
app11 = NetworkBehaviorExplorer(b11);
```

للبيانات الجديدة استخدم Open dataset داخل الواجهة؛ راجع `docs/YENI_VERI_SETI.md`
لصيغ الشبكات وتعيين الأعمدة والتوقيت. ليست كل صيغ الملفات مدعومة تلقائيًا.

للتوثيق الكامل، نفذ الأمر التالي منفصلًا بعد نجاح التشغيل الأول. يعيد تشغيل
الاختبارات والتحليل والتجارب؛ قد يستغرق وقتًا أطول من العرض:

```matlab
evidence = verify_delivery(fullfile('data','external','ctu13-scenario7.binetflow'));
```

النتائج والسجل تحفظ في `outputs/verification/`. افحص `verification.json`
والاختبارات غير المكتملة، وجرّب الواجهة يدويًا: اختيار مضيف، TR/EN، إعادة العرض،
فتح ملف آخر والتصدير. نجاح الأمر لا يعوّض فحص الواجهة.

## حدود التحقق قبل النقل

فحوص Python والفحص الساكن وتدقيق ZIP لا تثبت نجاح تنفيذ MATLAB. نتيجة
114/114 المذكورة في سجل المشروع تخص تشغيلًا أقدم بتاريخ 2026-10-27.
النسخة المعدلة الحالية تحتاج تشغيلًا جديدًا. نتائج التجارب الحالية، الصور النهائية،
شرائح العرض والتسجيل الاحتياطي ودراسة الاستخدام إن كانت مطلوبة لم تكتمل بعد.
التفاصيل في `docs/TASKS.md` و`TASKS_FOR_ADMIN.md`.

المراجع: [unzip](https://www.mathworks.com/help/matlab/ref/unzip.html)،
[websave](https://www.mathworks.com/help/matlab/ref/websave.html)،
[iforest ومتطلبات الإصدار](https://www.mathworks.com/help/stats/iforest.html).

## إعادة إنشاء الحزمة على جهاز التطوير

```sh
python3 scripts/package_windows.py --output ../deliveries
```

يُفحص SHA-256 للمصدرين قبل التجميع، ثم CRC ومحتوى كل ملف داخل ZIP. ملف
`.zip.sha256` بجانب الحزمة يسمح بفحص الملف بعد نسخه. من PowerShell في Windows:

```powershell
Get-FileHash -Algorithm SHA256 "C:\path\to\your-project.zip"
```

قارن الناتج بالقيمة الموجودة في ملف `.zip.sha256`؛ عدّل مسار ZIP حسب مكانه.

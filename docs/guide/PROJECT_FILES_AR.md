# ملفات المستودع والاختبارات والوثائق

هذا الفهرس يشرح وظيفة كل ملف خارج طبقات التحليل والعرض المفصلة في الأدلة الأخرى.
ملفات الاختبار ليست بيانات عرض، والملفات ذات اللاحقة `.gitkeep` تحفظ مجلداً فارغاً فقط.

## التشغيل والإعدادات وإدارة المستودع

| الملف | وظيفته |
|---|---|
| [scripts/data/acquire_ctu13_capture.py](../../scripts/data/acquire_ctu13_capture.py) | استحواذ موحد للسيناريوهين الرسميين 7 و11 مع تحقق البصمة وعدم استبدال مصدر مختلف. |
| [configs/projectConfig.m](../../configs/projectConfig.m) | الإعدادات المركزية: البذرة، الخصائص، النوافذ، حدود كلفة الرسم، النماذج ومسارات الحفظ. |
| [scripts/setupProject.m](../../scripts/setupProject.m) | يضيف مجلدات الكود والإعدادات والواجهة إلى مسار MATLAB. |
| [scripts/run_network_demo.m](../../scripts/run_network_demo.m) | يتحقق من بصمة CTU-13 الرسمي ثم يحلله ويفتح نفس الحزمة في التطبيق. |
| [scripts/launch_app.m](../../scripts/launch_app.m) | يفتح تحليل شبكة محفوظاً أو واجهة فارغة؛ لا ينشئ درجات أو سجلات بديلة. |
| [scripts/analyze_dataset.m](../../scripts/analyze_dataset.m) | مدخل سكربت لتحليل ملف خارجي مع خيارات الاستيراد. |
| [scripts/run_pipeline.m](../../scripts/run_pipeline.m) | يشغّل دراسة السطو الثانوية؛ ليس مدخل عرض الشبكات الأساسي. |
| [scripts/run_experiments.m](../../scripts/run_experiments.m) | يحمّل حزمة محفوظة ويشغّل التقييم والمقارنة على إعداداتها. |
| [scripts/verify_delivery.m](../../scripts/verify_delivery.m) | يجمع نتائج الاختبارات والتجارب والبصمات ويسجل الفشل أو النقص صراحة. |
| [scripts/generate_report_figures.m](../../scripts/generate_report_figures.m) | يولّد رسوم التقرير من الحزمة المختارة باستخدام وظائف رسم التطبيق. |
| [scripts/run_tests.m](../../scripts/run_tests.m) | يشغّل اختبارات MATLAB ويعرض عدد الناجح والفاشل والمتجاوز. |
| [scripts/scan_capture.m](../../scripts/scan_capture.m) | يفحص توزيعات التسميات في كتل الملف الكبير لاختيار نطاق معلن. |
| [scripts/check_dataset_presence.m](../../scripts/check_dataset_presence.m) | يتحقق من وجود ملف الدراسة الثانوية في مساره. |
| [scripts/download_dataset.m](../../scripts/download_dataset.m) | ينزّل ملف الدراسة الثانوية ويتحقق من بصمته. |
| [scripts/inspect_primary_dataset.m](../../scripts/inspect_primary_dataset.m) | يفحص مخطط ملف الدراسة الثانوية ويعرض ملخصه والرسم الأولي. |
| [scripts/data/acquire_ctu13_scenario7.py](../../scripts/data/acquire_ctu13_scenario7.py) | ينزّل ملف CTU-13 الرسمي ويتحقق من SHA256 ويرفض استبدال ملف مختلف. |
| [scripts/reference/audit_dataset_reference.py](../../scripts/reference/audit_dataset_reference.py) | مرجع مستقل لحقائق ملف السطو وبنيته الشبكية؛ ليس نموذج كشف. |
| [scripts/reference/audit_network_capture.py](../../scripts/reference/audit_network_capture.py) | تدقيق متدفق لملف الشبكة ينتج بصمات وأعداداً وتغطية التسميات دون عناوين خام. |
| [scripts/reference/network_flow_reference.py](../../scripts/reference/network_flow_reference.py) | حساب مرجعي مستقل لخصائص تدفقات CTU وتسميات الأجهزة؛ لا يستبدل MATLAB. |
| [.github/workflows/ci.yml](../../.github/workflows/ci.yml) | فحوص GitHub: تحليل ساكن ومرجع بيانات واختبارات Python وMATLAB حسب الترخيص. |
| [.claude/settings.json](../../.claude/settings.json) | إعداد مساعد التطوير؛ ليس جزءاً من واجهة التطبيق أو تحليل المستخدم. |
| [.claude/hooks/session-start.sh](../../.claude/hooks/session-start.sh) | إعداد أدوات فحص للمطور عند بدء جلسة المساعد؛ لا يولّد نتائج تحليل. |
| [.gitignore](../../.gitignore) | استبعاد البيانات الخام والمخرجات المحلية وخرائط المعرفات والملفات المولدة من Git. |
| [AGENTS.md](../../AGENTS.md) | قواعد العمل على المستودع ومنع اختلاق البيانات والنتائج وحماية الخصوصية. |
| [PROJECT_CONTEXT.md](../../PROJECT_CONTEXT.md) | النطاق الحالي والمصدر الأساسي وأوامر التشغيل وحدود حالة التنفيذ. |
| [README.md](../../README.md) | التعريف بالتطبيق والتشغيل والاستيراد والوصول إلى الأدلة والدليل. |
| [CHANGELOG.md](../../CHANGELOG.md) | سجل التغييرات؛ السجلات التاريخية لا تثبت تشغيل النسخة الأحدث. |
| [TASKS_FOR_ADMIN.md](../../TASKS_FOR_ADMIN.md) | المدخلات البشرية المطلوبة مثل تكليف الدكتور وبيئة تشغيل MATLAB. |
| [LICENSE.txt](../../LICENSE.txt) | ترخيص كود المشروع؛ تراخيص مصادر البيانات تُراجع مستقلة عنه. |

## الاختبارات

كل الاختبارات التالية تتحقق من سلوك محدد. وجود الملف لا يعني أن اختبار MATLAB قد نُفّذ.

| الملف | ما يفحصه |
|---|---|
| [tests/fixtures/makeSyntheticNetworkJson.m](../../tests/fixtures/makeSyntheticNetworkJson.m) | مولّد بيانات صغيرة معروفة البنية لاختبارات الوحدات فقط؛ لا تستدعيه واجهة العرض. |
| [tests/reference/test_audit_network_capture.py](../../tests/reference/test_audit_network_capture.py) | اختبارات Python لتدقيق البصمات والتواريخ والحقول والأطراف والتسميات. |
| [tests/test_anomaly_and_metrics.m](../../tests/test_anomaly_and_metrics.m) | تجهيز الخصائص والنموذجين وميزانية المراجعة والمقاييس. |
| [tests/test_behavior_features.m](../../tests/test_behavior_features.m) | قيم الخصائص السلوكية على مدخلات محسوبة يدوياً. |
| [tests/test_bundle_provenance.m](../../tests/test_bundle_provenance.m) | عرض مصدر البيانات والتغطية وحجب المعرفات والمسارات الخاصة. |
| [tests/test_dataset_import.m](../../tests/test_dataset_import.m) | كشف صيغ البيانات وربط الأعمدة وتكوين الجداول القياسية. |
| [tests/test_dataset_reuse_pipeline.m](../../tests/test_dataset_reuse_pipeline.m) | استقلال نتائج ملفين جديدين وتكرار الاستيراد وتكييف الوقت والسجلات وإغلاق الأخطاء. |
| [tests/test_delivery_evidence.m](../../tests/test_delivery_evidence.m) | تسلسل حفظ أدلة التحقق وتحويل إعدادات التواريخ إلى JSON والبصمات. |
| [tests/test_display_counts.m](../../tests/test_display_counts.m) | تنسيق أعداد المصدر بالتركية والإنجليزية دون اختصار أو تحويل المفقود إلى صفر. |
| [tests/test_domain_wording.m](../../tests/test_domain_wording.m) | ملاءمة لغة الأحداث والكيانات والنافذة القابلة للإعداد. |
| [tests/test_entity_summary_language.m](../../tests/test_entity_summary_language.m) | عرض القياسات نفسها في شرح تركي وإنجليزي دون تعديل النتائج. |
| [tests/test_evidence_display.m](../../tests/test_evidence_display.m) | اختيار أقوى القياسات المقاسة فعلاً وعدم عرض القيم المعوضة كقياسات. |
| [tests/test_external_network_import.m](../../tests/test_external_network_import.m) | الملفات الشبكية العامة وربط أعمدتها ووحدات الوقت والتسميات غير المعروفة والتحقق من القياسات. |
| [tests/test_graph_work_budget.m](../../tests/test_graph_work_budget.m) | تجاوز حساب betweenness المكلف عند حد العمل مع الحفاظ على الحساب المسموح. |
| [tests/test_host_flow_evidence.m](../../tests/test_host_flow_evidence.m) | توقيت التدفقات واتجاهها والمعرفات البديلة وحد العرض. |
| [tests/test_import_correctness.m](../../tests/test_import_correctness.m) | البصمات وهوية الشرائح والتواريخ التالفة والأطراف الناقصة. |
| [tests/test_import_dialog_options.m](../../tests/test_import_dialog_options.m) | تحويل اختيارات حوار الاستيراد إلى خيارات صحيحة وربط أعمدة موجودة وحدود صفوف واضحة. |
| [tests/test_import_ui_contract.m](../../tests/test_import_ui_contract.m) | نصوص الاستيراد والامتدادات وقيم رسائل التشخيص. |
| [tests/test_investigation_export.m](../../tests/test_investigation_export.m) | بنية JSON وCSV ونطاق الوقت والخصوصية وعدم اختلاق الأدلة. |
| [tests/test_language_copy.m](../../tests/test_language_copy.m) | اختيار اللغة والتنسيق والنصوص البديلة وعناوين الجداول. |
| [tests/test_loader_and_events.m](../../tests/test_loader_and_events.m) | قراءة JSON وتحويل تفاصيل الأحداث إلى صفوف صحيحة. |
| [tests/test_metric_correctness.m](../../tests/test_metric_correctness.m) | تعادل AP ومقاييس النسب والبيانات قليلة الخصائص. |
| [tests/test_network_datasets.m](../../tests/test_network_datasets.m) | ملفات تعريف CTU/CIC/UNSW/LANL والخصائص والتسميات المرتبطة بالأطراف. |
| [tests/test_pipeline_fixture.m](../../tests/test_pipeline_fixture.m) | ترابط طبقات المسار وحزمة النتائج ووظائف دعم الواجهة على بيانات اختبار. |
| [tests/test_playback_correctness.m](../../tests/test_playback_correctness.m) | حدود نوافذ الدقيقة والساعة والشهر في إعادة العرض. |
| [tests/test_presentation_bundle.m](../../tests/test_presentation_bundle.m) | اختيار تحليل شبكة محفوظ وعدم استبدال غياب البيانات ببيانات مصطنعة. |
| [tests/test_real_dataset.m](../../tests/test_real_dataset.m) | مقارنة فحص الملف الحقيقي الثانوي بقيم المرجع المستقل عند توفره. |
| [tests/test_relations_and_graph.m](../../tests/test_relations_and_graph.m) | اشتقاق العلاقات ودرجات الرسم والمكونات والتجمع والنواة. |
| [tests/test_sequence.m](../../tests/test_sequence.m) | ترميز الأحداث ونموذج الانتقال وندرة التسلسلات والأنماط. |
| [tests/test_table_display.m](../../tests/test_table_display.m) | ترجمة نسخة العرض مع المحافظة على الأرقام والقيم المفقودة والحقول الأصلية. |
| [tests/test_temporal_spatial_patterns.m](../../tests/test_temporal_spatial_patterns.m) | السلاسل الزمنية والمراجع والمواقع النسبية والأنماط المتكررة. |
| [tests/test_usability_scoring.m](../../tests/test_usability_scoring.m) | حساب SUS وملخص مهام الاستخدام من إجابات فعلية أو مدخلات اختبار معروفة. |
| [tests/test_validation.m](../../tests/test_validation.m) | حالات فشل التحقق والتحذيرات واتساق العقد الداخلية. |
| [tests/test_visualization_theme.m](../../tests/test_visualization_theme.m) | الألوان والتباين وتنسيق الجداول والرسوم ووظائف العرض المستقلة. |

## الوثائق

| الملف | الغرض |
|---|---|
| [app/README.md](../../app/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |
| [data/BURGLARY_DATASET_CARD.md](../../data/BURGLARY_DATASET_CARD.md) | بطاقة مستقلة لبيانات دراسة السطو الثانوية. |
| [data/DATASET_CARD.md](../../data/DATASET_CARD.md) | بطاقة CTU-13: المصدر والبصمات والحقول والتغطية والتفسير. |
| [data/README.md](../../data/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |
| [data/external/README.md](../../data/external/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |
| [docs/30_DAY_ROADMAP.md](../../docs/30_DAY_ROADMAP.md) | ترتيب إنجاز العمل والتحقق من مراحله؛ ليس دليلاً على اكتمال التنفيذ. |
| [docs/AGENT_EXECUTION_PROMPT.md](../../docs/AGENT_EXECUTION_PROMPT.md) | تعليمات العمل الآلي ضمن نطاق المشروع. |
| [docs/ANOMALY_DETECTION.md](../../docs/ANOMALY_DETECTION.md) | اختيار النموذجين والتطبيع وسياسة ميزانية المراجعة وحدود تفسير الدرجة. |
| [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md) | طبقات النظام وعقد حزمة التحليل والمفاتيح المشتركة بينها. |
| [docs/ASSIGNMENT_SOURCE.md](../../docs/ASSIGNMENT_SOURCE.md) | حالة النص الأصلي لتكليف الدكتور؛ لا يختلق نصاً غير متاح. |
| [docs/AUDIT_2026-09-30.md](../../docs/AUDIT_2026-09-30.md) | سجل تاريخي لفحص النسخة الأقدم؛ لا يصف وحده حالة الكود الحالي. |
| [docs/BEHAVIOR_MODEL.md](../../docs/BEHAVIOR_MODEL.md) | تعريف المرجع السلوكي والفرق بين الوصف الحالي والتنبؤ المستقبلي. |
| [docs/CODE_GUIDE_AR.md](../../docs/CODE_GUIDE_AR.md) | نقطة بدء شرح الكود ومسار البيانات وروابط الفهارس التفصيلية. |
| [docs/DATASETS.md](../../docs/DATASETS.md) | اختيار بيانات الشبكة الأساسية ودراسة السطو الثانوية. |
| [docs/DATASET_ACQUISITION.md](../../docs/DATASET_ACQUISITION.md) | مصادر الحصول على البيانات وضوابط حفظها. |
| [docs/DATASET_IMPORT.md](../../docs/DATASET_IMPORT.md) | الصيغ المقبولة وربط الأعمدة وقيود استيراد بيانات خارجية. |
| [docs/DATASET_SCHEMA_INSPECTION.md](../../docs/DATASET_SCHEMA_INSPECTION.md) | نتائج فحص مخطط ملف السطو الثانوي وحقوله. |
| [docs/DATA_DICTIONARY.md](../../docs/DATA_DICTIONARY.md) | معاني الأعمدة والمفاتيح والوحدات في الجداول الداخلية. |
| [docs/DEFINITION_OF_DONE.md](../../docs/DEFINITION_OF_DONE.md) | شروط اكتمال الخاصية والتجربة والتسليم بناء على أدلة تشغيل. |
| [docs/DEMO_SCENARIO.md](../../docs/DEMO_SCENARIO.md) | ترتيب العرض العملي على البيانات الحقيقية وما يُفحص في كل شاشة. |
| [docs/ETHICS_AND_LIMITATIONS.md](../../docs/ETHICS_AND_LIMITATIONS.md) | حدود البيانات والتعميم والخصوصية وتفسير درجات الشذوذ. |
| [docs/EVALUATION.md](../../docs/EVALUATION.md) | بروتوكول التقييم والتسميات ومقاييسه ودراسة الاستخدام. |
| [docs/EXPERIMENTS.md](../../docs/EXPERIMENTS.md) | تجارب المقارنة وحذف مجموعات الخصائص والحساسية وإنتاج النتائج. |
| [docs/EXPLAINABILITY.md](../../docs/EXPLAINABILITY.md) | كيفية ربط القياسات والمرجع والأدلة بدرجات النماذج. |
| [docs/FEATURE_ENGINEERING.md](../../docs/FEATURE_ENGINEERING.md) | تعريف عائلات الخصائص وطريقة حسابها ومشكلات التوقيت والقيم المفقودة. |
| [docs/GITHUB_WORKFLOW.md](../../docs/GITHUB_WORKFLOW.md) | مسار الفروع والمراجعة والتحقق ضمن GitHub. |
| [docs/GRAPH_ANALYSIS.md](../../docs/GRAPH_ANALYSIS.md) | تفسير العلاقات والمقاييس الشبكية والتغير بين النوافذ. |
| [docs/ISSUE_TEMPLATE.md](../../docs/ISSUE_TEMPLATE.md) | صيغة تسجيل مهمة أو مشكلة ومتطلبات قبولها. |
| [docs/KULLANIM_KILAVUZU.md](../../docs/KULLANIM_KILAVUZU.md) | دليل الاستخدام باللغة التركية. |
| [docs/LAB_RUN_GUIDE_AR.md](../../docs/LAB_RUN_GUIDE_AR.md) | خطوات الإعداد والتشغيل العملي للمختبر باللغة العربية. |
| [docs/MATLAB_STACK.md](../../docs/MATLAB_STACK.md) | أدوات MATLAB وصناديق الأدوات التي يعتمد عليها المشروع. |
| [docs/METHODOLOGY.md](../../docs/METHODOLOGY.md) | القرارات المنهجية خلف الإعدادات والخصائص والتقييم. |
| [docs/MILESTONES.md](../../docs/MILESTONES.md) | حالة المراحل مع فصل التنفيذ عن التحقق الفعلي. |
| [docs/MULTIMEDIA_DESIGN.md](../../docs/MULTIMEDIA_DESIGN.md) | بنية الواجهة وألوان القياسات والتفاعل وإجراءات فحصها. |
| [docs/NETWORK_DATASETS.md](../../docs/NETWORK_DATASETS.md) | ملفات تعريف مجموعات الشبكات والأعمدة والوحدات والتسميات. |
| [docs/PATTERN_MINING.md](../../docs/PATTERN_MINING.md) | معنى الأنماط المتكررة وحدود تفسيرها. |
| [docs/PROJECT_BRIEF.md](../../docs/PROJECT_BRIEF.md) | ملخص الهدف والنطاق والتسليم. |
| [docs/PYTHON_POLICY.md](../../docs/PYTHON_POLICY.md) | قصر Python على أدوات الاستحواذ والتحقق المرجعي؛ التحليل الأساسي MATLAB. |
| [docs/REAL_CAPTURE_EVIDENCE.md](../../docs/REAL_CAPTURE_EVIDENCE.md) | مصدر CTU-13 وبصماته وأعداد المصدر المدققة وأمر إعادة التحقق. |
| [docs/RELATED_SYSTEMS_AND_DELIVERY.md](../../docs/RELATED_SYSTEMS_AND_DELIVERY.md) | مقارنة مع أنظمة تحليل حقيقية ومعايير عرض الأدلة. |
| [docs/REPRODUCIBILITY.md](../../docs/REPRODUCIBILITY.md) | إعادة التشغيل والإعدادات والملفات المطلوبة لتوثيق النتائج. |
| [docs/REQUIREMENTS.md](../../docs/REQUIREMENTS.md) | المتطلبات الوظيفية وغير الوظيفية وربطها بالتنفيذ. |
| [docs/RESEARCH_LOG.md](../../docs/RESEARCH_LOG.md) | سجل القرارات والفحوص التاريخية ومبرراتها. |
| [docs/RISKS.md](../../docs/RISKS.md) | المخاطر الفنية والمنهجية وحدود أدلة التشغيل. |
| [docs/SEQUENCE_ANALYSIS.md](../../docs/SEQUENCE_ANALYSIS.md) | تعريف رموز الأحداث وانتقالاتها ومقاييس ندرتها. |
| [docs/SOURCE_INDEX.md](../../docs/SOURCE_INDEX.md) | مراجع البحث والوثائق المستخدمة في القرارات المنهجية. |
| [docs/SPATIAL_ANALYSIS.md](../../docs/SPATIAL_ANALYSIS.md) | تحليل المواقع النسبية عند توفر إحداثيات؛ لا ينشئ خريطة لملف بلا إحداثيات. |
| [docs/TASKS.md](../../docs/TASKS.md) | قائمة المهام بحالات مبنية على التنفيذ والأدلة. |
| [docs/TEMPORAL_ANALYSIS.md](../../docs/TEMPORAL_ANALYSIS.md) | تجميع النشاط والمرجع الزمني وكشف الارتفاعات والانخفاضات. |
| [docs/TURKISH_PROJECT_PROPOSAL.md](../../docs/TURKISH_PROJECT_PROPOSAL.md) | المقترح الأكاديمي التركي للمشروع. |
| [docs/UI_ACCEPTANCE_TR_EN.md](../../docs/UI_ACCEPTANCE_TR_EN.md) | إجراءات التحقق اليدوي من الواجهة واللغتين؛ ليست نتائج تشغيل. |
| [docs/UI_COPY_GUIDE.md](../../docs/UI_COPY_GUIDE.md) | قواعد كتابة نصوص الواجهة والترجمة دون تغيير معنى القياسات. |
| [docs/USABILITY_STUDY.md](../../docs/USABILITY_STUDY.md) | بروتوكول دراسة الاستخدام بمشاركين حقيقيين. |
| [docs/USER_GUIDE_EN.md](../../docs/USER_GUIDE_EN.md) | دليل الاستخدام باللغة الإنجليزية. |
| [docs/YENI_VERI_SETI.md](../../docs/YENI_VERI_SETI.md) | دليل تركي لفتح ملف جديد وربط أعمدته ووحدات التوقيت وحدود الصيغ المدعومة. |
| [docs/guide/DATA_FILES_AR.md](../../docs/guide/DATA_FILES_AR.md) | شرح عربي تفصيلي للملفات الواردة في هذا القسم. |
| [docs/guide/EVALUATION_FILES_AR.md](../../docs/guide/EVALUATION_FILES_AR.md) | شرح عربي تفصيلي للملفات الواردة في هذا القسم. |
| [docs/guide/PROJECT_FILES_AR.md](../../docs/guide/PROJECT_FILES_AR.md) | شرح عربي تفصيلي للملفات الواردة في هذا القسم. |
| [docs/guide/UI_FILES_AR.md](../../docs/guide/UI_FILES_AR.md) | شرح عربي تفصيلي للملفات الواردة في هذا القسم. |
| [docs/report/README.md](../../docs/report/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |
| [docs/report/TECHNICAL_REPORT.md](../../docs/report/TECHNICAL_REPORT.md) | التقرير التقني الحالي بالبيانات المثبتة ومنهج التقييم وحدوده. |
| [docs/report/TECHNICAL_REPORT_DRAFT.md](../../docs/report/TECHNICAL_REPORT_DRAFT.md) | رابط توافق إلى التقرير الحالي؛ لا يحتوي نتائج أو حقولاً مصطنعة. |
| [docs/usability/consent_form.md](../../docs/usability/consent_form.md) | نموذج الموافقة على جلسة الاستخدام. |
| [docs/usability/sus_questionnaire.md](../../docs/usability/sus_questionnaire.md) | أسئلة مقياس قابلية الاستخدام؛ لا يحتوي إجابات مشاركين جاهزة. |
| [docs/usability/task_sheet.md](../../docs/usability/task_sheet.md) | مهام جلسة دراسة الاستخدام. |
| [models/README.md](../../models/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |
| [outputs/README.md](../../outputs/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |
| [scripts/README.md](../../scripts/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |
| [src/README.md](../../src/README.md) | مدخل يوضح محتوى هذا المجلد وطريقة استخدامه. |

## الملفات المحلية والمجلدات الفارغة

- `data/external/ctu13-scenario7.binetflow`: ملف المصدر الرسمي، محلي ومستبعد من Git.
- `outputs/reference/ctu13-scenario7.json`: تدقيق المصدر المستقل، وليس مخرجات كاشف MATLAB.
- `outputs/datasets/`: حزم التحليل وCSV وإعدادات كل استيراد عند تشغيله.
- `outputs/verification/`: ملفات نتائج الاختبارات والتجارب والبصمات عند التحقق الفعلي.
- `outputs/reports/` و`outputs/figures/`: التقارير والرسوم المولدة عند التشغيل.
- `.gitkeep`: ملف فارغ يحفظ بنية المجلد؛ لا يحتوي سجلات أو قيماً تجريبية.

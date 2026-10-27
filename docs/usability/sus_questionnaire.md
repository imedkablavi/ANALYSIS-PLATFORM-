# Sistem Kullanılabilirlik Ölçeği (SUS) / System Usability Scale (SUS)

Katılımcı kodu / Participant ID: **P____**

> Çeviri notu / Translation note: The English items are the original SUS wording (Brooke 1996).
> The Turkish items are a **project translation** made for this study; they are **not** a
> published, validated Turkish SUS version. We searched for a validated Turkish SUS adaptation
> and did not find one we could verify, so results are reported with this caveat
> (docs/USABILITY_STUDY.md §8, §11). Türkçe maddeler bu çalışma için yapılmış bir proje
> çevirisidir; geçerlik-güvenirlik çalışması yapılmış resmi bir Türkçe SUS sürümü değildir.

---

## Türkçe

Uygulamayı kullanma deneyiminizi düşünerek her ifade için **bir** sayıyı işaretleyin. Uzun
düşünmeyin; emin değilseniz orta değeri (3) işaretleyin. Lütfen her maddeyi cevaplayın.

1 = Kesinlikle katılmıyorum · 2 = Katılmıyorum · 3 = Kararsızım · 4 = Katılıyorum ·
5 = Kesinlikle katılıyorum

| # | İfade | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| 1 | Bu sistemi sık sık kullanmak isteyeceğimi düşünüyorum. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 2 | Sistemi gereksiz yere karmaşık buldum. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 3 | Sistemin kullanımının kolay olduğunu düşündüm. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 4 | Bu sistemi kullanabilmek için teknik bir kişinin desteğine ihtiyaç duyacağımı düşünüyorum. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 5 | Bu sistemdeki çeşitli işlevlerin iyi bütünleştirildiğini düşündüm. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 6 | Bu sistemde çok fazla tutarsızlık olduğunu düşündüm. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 7 | Çoğu insanın bu sistemi kullanmayı çok çabuk öğreneceğini tahmin ediyorum. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 8 | Sistemi kullanmayı çok zahmetli buldum. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 9 | Sistemi kullanırken kendimden çok emin hissettim. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 10 | Bu sistemi kullanmaya başlamadan önce birçok şey öğrenmem gerekti. | ☐ | ☐ | ☐ | ☐ | ☐ |

**Açık soru:** Bu uygulamada ilk olarak neyi değiştirirdiniz, neden?

______________________________________________________________________________

______________________________________________________________________________

---

## English

Thinking about your experience with the application, tick **one** number for each statement.
Do not think too long; if you are unsure, tick the middle value (3). Please answer every item.

1 = Strongly disagree · 2 = Disagree · 3 = Neutral · 4 = Agree · 5 = Strongly agree

| # | Statement | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| 1 | I think that I would like to use this system frequently. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 2 | I found the system unnecessarily complex. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 3 | I thought the system was easy to use. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 4 | I think that I would need the support of a technical person to be able to use this system. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 5 | I found the various functions in this system were well integrated. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 6 | I thought there was too much inconsistency in this system. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 7 | I would imagine that most people would learn to use this system very quickly. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 8 | I found the system very cumbersome to use. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 9 | I felt very confident using the system. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 10 | I needed to learn a lot of things before I could get going with this system. | ☐ | ☐ | ☐ | ☐ | ☐ |

**Open question:** What would you change first in this application, and why?

______________________________________________________________________________

______________________________________________________________________________

---

*Facilitator only — scoring (Brooke 1996), see `src/evaluation/scoreSUS.m`:* odd items
(1, 3, 5, 7, 9) → response − 1; even items (2, 4, 6, 8, 10) → 5 − response; SUS = 2.5 × sum
(0–100). Any blank item → SUS not computed for this participant.

Reference: Brooke, J. (1996). SUS: A "quick and dirty" usability scale. In P. W. Jordan,
B. Thomas, B. A. Weerdmeester & I. L. McClelland (Eds.), *Usability Evaluation in Industry*
(pp. 189–194). Taylor & Francis.

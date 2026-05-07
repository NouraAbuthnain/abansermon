import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';

class LegalContentDialog extends StatelessWidget {
  final String title;
  final String content;

  const LegalContentDialog({
    super.key,
    required this.title,
    required this.content,
  });

  static void show(BuildContext context, {required String title, required String content}) {
    AppBottomSheet.show(
      context,
      title: title,
      child: LegalContentDialog(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              content,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: isDark ? AppColors.doveGray : AppColors.slate,
              ),
            ),
          ),
        ),
        
        // Bottom Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: AppButton(
            label: 'common.cancel'.tr() == 'common.cancel' ? 'Close' : 'common.cancel'.tr(),
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}

class LegalTexts {
  static const String termsEn = '''TERMS OF SERVICE – ABAN

Effective Date: 20 April 2026

1. About Aban
Aban (أبان) provides real-time translation of Friday Khutbahs using AI technologies and allows authorized volunteers to capture and optionally store sermon audio.

By using Aban, you agree to these Terms.

2. Use of the App

General Users
- Can access live and archived translated Khutbahs.

Volunteers
- Must log in using phone number and OTP.
- Are responsible for recording the Khutbah audio.

Volunteers agree to:
- Record only authorized Khutbahs
- Avoid capturing inappropriate or private content
- Use the app in a respectful and lawful manner

Aban may suspend access if misuse is detected.

3. Audio and Content
- Khutbahs may be recorded live and optionally stored.
- Stored recordings may remain available inside the app.

4. Acceptable Use
You agree not to:
- Use the app unlawfully
- Record inappropriate content
- Interfere with the app’s functionality

5. Contact
Email: aban.sermon@gmail.com''';

  static const String privacyEn = '''PRIVACY POLICY – ABAN

Effective Date: 20 April 2026

1. Data We Collect

Volunteers
- Phone number
- User ID
- Location
  - Used by volunteers to select mosques on the map
- Live Khutbah recordings
  - May be stored if the volunteer chooses

We collect ID information to:
- Verify volunteer identity
- Protect accounts
- Comply with applicable legal and operational requirements

2. How We Use Data
We use data to:
- Provide real-time translation
- Associate recordings with mosques
- Improve performance and accuracy
- Maintain platform safety

3. Security
We take reasonable steps to protect data, but no system is completely secure.

4. Contact
Email: aban.sermon@gmail.com''';

  static const String termsAr = '''شروط الخدمة – أبان

تاريخ السريان: 20 أبريل 2026

1. عن أبان
يوفر أبان (Aban) ترجمة فورية لخطب الجمعة باستخدام تقنيات الذكاء الاصطناعي ويسمح للمتطوعين المصرح لهم بالتقاط وتخزين صوت الخطبة اختيارياً.

باستخدام أبان، فإنك توافق على هذه الشروط.

2. استخدام التطبيق

المستخدمون العامون
- يمكنهم الوصول إلى خطب الجمعة المترجمة المباشرة والمؤرشفة.

المتطوعون
- يجب تسجيل الدخول باستخدام رقم الهاتف ورمز التحقق (OTP).
- مسؤولون عن تسجيل صوت الخطبة.

يوافق المتطوعون على:
- تسجيل الخطب المصرح بها فقط
- تجنب التقاط محتوى غير لائق أو خاص
- استخدام التطبيق بطريقة محترمة وقانونية

قد يقوم أبان بتعليق الوصول إذا تم اكتشاف سوء استخدام.

3. الصوت والمحتوى
- قد يتم تسجيل الخطب مباشرة وتخزينها اختيارياً.
- قد تظل التسجيلات المخزنة متاحة داخل التطبيق.

4. الاستخدام المقبول
توافق على عدم:
- استخدام التطبيق بشكل غير قانوني
- تسجيل محتوى غير لائق
- التدخل في وظائف التطبيق

5. الاتصال
البريد الإلكتروني: aban.sermon@gmail.com''';

  static const String privacyAr = '''سياسة الخصوصية – أبان

تاريخ السريان: 20 أبريل 2026

1. البيانات التي نجمعها

المتطوعون
- رقم الهاتف
- معرف المستخدم
- الموقع
  - يستخدمه المتطوعون لاختيار المساجد على الخریطة
- تسجيلات الخطبة المباشرة
  - قد يتم تخزينها إذا اختار المتطوع ذلك

نحن نجمع معلومات الهوية من أجل:
- التحقق من هوية المتطوع
- حماية الحسابات
- الامتثال للمتطلبات القانونية والتشغيلية المعمول بها

2. كيف نستخدم البيانات
نستخدم البيانات من أجل:
- توفير ترجمة فورية
- ربط التسجيلات بالمساجد
- تحسين الأداء والدقة
- الحفاظ على سلامة المنصة

3. الأمن
نتخذ خطوات معقولة لحماية البيانات، ولكن لا يوجد نظام آمن تماماً.

4. الاتصال
البريد الإلكتروني: aban.sermon@gmail.com''';

  static const String termsUr = termsEn;
  static const String privacyUr = '''رازداری کی پالیسی – ABAN

Effective Date: 20 April 2026

1. Data We Collect

Volunteers
- Phone number
- User ID
- Location
  - Used by volunteers to select mosques on the map
- Live Khutbah recordings
  - May be stored if the volunteer chooses

ہم شناختی معلومات جمع کرتے ہیں تاکہ:
- رضاکار کی شناخت کی تصدیق کی جا سکے
- اکاؤنٹس کی حفاظت کی جا سکے
- قانونی اور آپریشنل تقاضوں کی تعمیل کی جا سکے

2. How We Use Data
We use data to:
- Provide real-time translation
- Associate recordings with mosques
- Improve performance and accuracy
- Maintain platform safety

3. Security
We take reasonable steps to protect data, but no system is completely secure.

4. Contact
Email: aban.sermon@gmail.com''';

  static const String termsBn = termsEn;
  static const String privacyBn = '''গোপনীয়তা নীতি – ABAN

Effective Date: 20 April 2026

1. Data We Collect

Volunteers
- Phone number
- User ID
- Location
  - Used by volunteers to select mosques on the map
- Live Khutbah recordings
  - May be stored if the volunteer chooses

আমরা আইডি তথ্য সংগ্রহ করি:
- ভলান্টিয়ারের পরিচয় যাচাই করতে
- অ্যাকাউন্ট সুরক্ষিত রাখতে
- প্রযোজ্য আইনি ও অপারেশনাল প্রয়োজনীয়তা মেনে চলতে

2. How We Use Data
We use data to:
- Provide real-time translation
- Associate recordings with mosques
- Improve performance and accuracy
- Maintain platform safety

3. Security
We take reasonable steps to protect data, but no system is completely secure.

4. Contact
Email: aban.sermon@gmail.com''';
}

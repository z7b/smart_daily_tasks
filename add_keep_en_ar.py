import os

file_path = 'lib/app/core/translations/messages.dart'

en_trans = """
      // ─── Keep Bulletin Board ─────────────────────
      'keep': 'Keep',
      'keep_board_title': 'My Board',
      'keep_board_subtitle': 'Stick your ideas and capture anything',
      'keep_notes': 'notes',
      'keep_new_note': 'New Note',
      'keep_untitled': 'Untitled',
      'keep_empty_title': 'Your board is empty!',
      'keep_empty_sub': 'Tap the + button to stick\\nyour first note.',
      'keep_add_first': 'Add First Note',
      'keep_text': 'Text',
      'keep_list': 'List',
      'keep_image': 'Image',
      'keep_draw': 'Drawing',
      'keep_voice': 'Voice',
      'keep_text_hint': 'Write something...',
      'keep_add_item': 'Add item...',
      'keep_tap_add_image': 'Tap to attach image',
      'keep_tap_draw': 'Tap to start drawing',
      'keep_tap_record': 'Tap to start recording',
      'keep_recording': 'Recording...',
      'keep_tap_play': 'Tap to play',
      'keep_playing': 'Playing...',
      'keep_required': 'Cannot be empty',
      'keep_required_msg': 'Please enter a title or content.',
      'confirm_delete': 'Confirm Deletion',
      'keep_delete_confirm': 'Are you sure you want to delete the selected notes?',
      'keep_empty_delete_msg': 'This note is empty. Do you want to delete it?',
      'keep_image_coming': 'Image capture coming soon.',
      'keep_draw_coming': 'Drawing canvas coming soon.',
      'keep_voice_coming': 'Voice recording coming soon.',
      'keep_change_image': 'Change Image',
      'keep_change_audio': 'Change Audio File',
      'keep_draw_hint': 'Draw here with your finger...',
      'keep_empty_note': 'Empty Note',
      'keep_format': 'Text Formatting',
      'keep_blur': 'Background Blur',
"""

ar_trans = """
      // ─── Keep Bulletin Board ─────────────────────
      'keep': 'الملاحظات',
      'keep_board_title': 'الصبورة',
      'keep_board_subtitle': 'ألصق أفكارك وسجل أي شيء',
      'keep_notes': 'ملاحظات',
      'keep_new_note': 'ملاحظة جديدة',
      'keep_untitled': 'بدون عنوان',
      'keep_empty_title': 'صبورتك فارغة!',
      'keep_empty_sub': 'اضغط على زر + لإلصاق\\nملاحظتك الأولى.',
      'keep_add_first': 'إضافة ملاحظة أولى',
      'keep_text': 'نص',
      'keep_list': 'قائمة',
      'keep_image': 'صورة',
      'keep_draw': 'رسم',
      'keep_voice': 'صوت',
      'keep_text_hint': 'اكتب شيئاً...',
      'keep_add_item': 'إضافة عنصر...',
      'keep_tap_add_image': 'اضغط لإرفاق صورة',
      'keep_tap_draw': 'اضغط لبدء الرسم',
      'keep_tap_record': 'اضغط لبدء التسجيل',
      'keep_recording': 'جاري التسجيل...',
      'keep_tap_play': 'اضغط للتشغيل',
      'keep_playing': 'جاري التشغيل...',
      'keep_required': 'لا يمكن أن يكون فارغاً',
      'keep_required_msg': 'الرجاء إدخال عنوان أو محتوى.',
      'confirm_delete': 'تأكيد الحذف',
      'keep_delete_confirm': 'هل أنت متأكد أنك تريد حذف الملاحظات المحددة؟',
      'keep_empty_delete_msg': 'هذه الملاحظة فارغة. هل تريد حذفها؟',
      'keep_image_coming': 'التقاط الصور قريباً.',
      'keep_draw_coming': 'لوحة الرسم قريباً.',
      'keep_voice_coming': 'تسجيل الصوت قريباً.',
      'keep_change_image': 'تغيير الصورة',
      'keep_change_audio': 'تغيير الملف الصوتي',
      'keep_draw_hint': 'ارسم هنا بإصبعك...',
      'keep_empty_note': 'ملاحظة فارغة',
      'keep_format': 'تنسيق النص',
      'keep_blur': 'ضبابية (Blur)',
"""

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Insert before 'ar': { for en
idx_ar = content.find("    'ar': {")
if idx_ar != -1:
    idx_end_en = content.rfind('    },', 0, idx_ar)
    if idx_end_en != -1:
        content = content[:idx_end_en] + en_trans + content[idx_end_en:]

# Insert before }, at the end of ar block
idx_end_ar = content.find("    },", idx_ar)
if idx_end_ar != -1:
    content = content[:idx_end_ar] + ar_trans + content[idx_end_ar:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Added Keep translations to messages.dart")

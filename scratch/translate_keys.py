import os

files_to_update = {
    "c:/Users/sief/Downloads/smart_daily_tasks-main/lib/app/core/translations/messages.dart": ["en", "ar"],
    "c:/Users/sief/Downloads/smart_daily_tasks-main/lib/app/core/translations/zh_cn.dart": ["zh_CN"],
    "c:/Users/sief/Downloads/smart_daily_tasks-main/lib/app/core/translations/zh_tw.dart": ["zh_TW"],
    "c:/Users/sief/Downloads/smart_daily_tasks-main/lib/app/core/translations/hi_in.dart": ["hi_IN"],
    "c:/Users/sief/Downloads/smart_daily_tasks-main/lib/app/core/translations/fr_fr.dart": ["fr_FR"],
    "c:/Users/sief/Downloads/smart_daily_tasks-main/lib/app/core/translations/es_es.dart": ["es_ES"],
    "c:/Users/sief/Downloads/smart_daily_tasks-main/lib/app/core/translations/ru_ru.dart": ["ru_RU"]
}

translations = {
    "en": {
        "keep_edited": "Edited",
        "keep_drawing_tools": "Drawing Tools",
        "keep_undo": "Undo",
        "keep_redo": "Redo",
        "keep_clear": "Clear",
        "keep_stroke_width": "Stroke Width"
    },
    "ar": {
        "keep_edited": "آخر تعديل",
        "keep_drawing_tools": "أدوات الرسم",
        "keep_undo": "تراجع",
        "keep_redo": "إعادة",
        "keep_clear": "مسح",
        "keep_stroke_width": "حجم الخط"
    },
    "zh_CN": {
        "keep_edited": "已编辑",
        "keep_drawing_tools": "绘图工具",
        "keep_undo": "撤销",
        "keep_redo": "重做",
        "keep_clear": "清除",
        "keep_stroke_width": "笔画宽度"
    },
    "zh_TW": {
        "keep_edited": "已編輯",
        "keep_drawing_tools": "繪圖工具",
        "keep_undo": "撤銷",
        "keep_redo": "重做",
        "keep_clear": "清除",
        "keep_stroke_width": "筆畫寬度"
    },
    "hi_IN": {
        "keep_edited": "संपादित",
        "keep_drawing_tools": "ड्राइंग टूल",
        "keep_undo": "पूर्ववत करें",
        "keep_redo": "फिर से करें",
        "keep_clear": "साफ़ करें",
        "keep_stroke_width": "स्ट्रोक की चौड़ाई"
    },
    "fr_FR": {
        "keep_edited": "Modifié",
        "keep_drawing_tools": "Outils de dessin",
        "keep_undo": "Annuler",
        "keep_redo": "Rétablir",
        "keep_clear": "Effacer",
        "keep_stroke_width": "Épaisseur du trait"
    },
    "es_ES": {
        "keep_edited": "Editado",
        "keep_drawing_tools": "Herramientas de dibujo",
        "keep_undo": "Deshacer",
        "keep_redo": "Rehacer",
        "keep_clear": "Borrar",
        "keep_stroke_width": "Grosor del trazo"
    },
    "ru_RU": {
        "keep_edited": "Изменено",
        "keep_drawing_tools": "Инструменты для рисования",
        "keep_undo": "Отменить",
        "keep_redo": "Повторить",
        "keep_clear": "Очистить",
        "keep_stroke_width": "Толщина линии"
    }
}

for file_path, langs in files_to_update.items():
    if not os.path.exists(file_path):
        continue
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    for lang in langs:
        lang_keys = translations[lang]
        dart_entries = "\n" + "\n".join([f"      '{k}': '{v.replace(chr(39), chr(92)+chr(39))}'," for k, v in lang_keys.items()])
        
        if file_path.endswith("messages.dart"):
            if lang == "en":
                # Find first 'remind_custom'
                idx = content.find("'remind_custom':")
                end_idx = content.find('\n', idx)
                content = content[:end_idx] + dart_entries + content[end_idx:]
            elif lang == "ar":
                # Find last 'remind_custom'
                idx = content.rfind("'remind_custom':")
                end_idx = content.find('\n', idx)
                content = content[:end_idx] + dart_entries + content[end_idx:]
        else:
            # find `final Map<String, String> lang_code = { ... };`
            # we can just insert before `};` at the end
            idx = content.rfind("};")
            if idx != -1:
                content = content[:idx] + dart_entries + "\n" + content[idx:]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        print(f"Updated {file_path}")

# Smart Daily Tasks (Life OS)

A professional, high-performance Flutter application designed with the **Life OS** philosophy. It integrates tasks, health tracking, journaling, and professional work management into a unified dashboard.

## 🚀 Architecture
The application follows a refined **Clean Architecture** pattern combined with **GetX** for state management:
- **Presentation Layer**: GetX Controllers, Obx-powered Views, and Cupertino-style premium UI.
- **Domain/Data Layer**: Isar Database for high-performance peripheral storage with encrypted schemas.
- **Core Services**: Centralized services for Security, App Lock, Notifications, and Theme.

## 🔑 Key Features
- **Unified Progress**: A doctoral-logic dashboard that weights tasks, health, and work attendance.
- **Biometric Security**: Built-in App Lock (PIN + Biometrics) and Screenshot Protection.
- **Health Integration**: Steps tracking and Medication adherence with smart reminders.
- **Professional Tools**: Work profile management with salary countdowns and attendance logging.
- **Deep Localization**: Full Arabic and English support with RTL/LTR handling.

## 🛠️ Technical Excellence
- **Robust DateTime Handling**: Using native DateTime objects and Timezone support for global reliability.
- **Performance**: Debounced listeners, lazy-loading services, and parallel future execution.
- **Real-time Sync**: Stream-based UI updates from the Isar database.
- **Log System**: Comprehensive error tracking using Talker.

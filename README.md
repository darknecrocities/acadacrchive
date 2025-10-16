# 📚 AcadArchive

AcadArchive is a **mobile application** designed to help students **store, organize, and manage their academic documents and projects** securely in one centralized digital platform.  
It provides an easy-to-use interface for uploading, viewing, downloading, and managing files — ensuring accessibility anytime, anywhere.

---

## 🚀 Features

✅ **User Authentication** — Secure login and registration powered by Supabase.  
✅ **Cloud Storage** — Upload and access academic files anytime.  
✅ **File Management** — View, download, and delete documents easily.  
✅ **Dark & Light Mode** — Adaptive theme for comfortable viewing.  
✅ **Text Extraction (OCR)** — Extract text from images or PDFs using Google ML Kit.  
✅ **Data Visualization** — View analytics and summaries using beautiful charts.

---

## 🧩 Tech Stack

| Technology | Purpose |
|-------------|----------|
| **Flutter** | App development framework |
| **Supabase** | Backend-as-a-Service (authentication + storage) |
| **Google ML Kit** | Text recognition and OCR |
| **Syncfusion Flutter PDF** | PDF rendering and management |
| **File Picker & Image Picker** | File and image selection |
| **Flutter TTS** | Text-to-speech for accessibility |
| **FL Chart** | Data visualization and analytics |
| **Flutter Native Splash** | Custom splash screen |
| **Flutter Launcher Icons** | Custom app icon generation |

---

## ⚙️ Installation

### 1️⃣ Clone the repository
```bash
git clone https://github.com/your-username/acad_archive.git
cd acad_archive
```

### 2️⃣ Install dependencies
```bash
flutter pub get
```

### 3️⃣ Configure Environment
Create a `.env` file in the project root and add your **Supabase credentials**:
```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 4️⃣ Run the app
```bash
flutter run
```

---

## 🧠 Project Structure

```
acad_archive/
│
├── assets/
│   ├── images/
│   │   └── acadarchive_brand.png     # app icon & splash
│   └── fonts/
│       └── Inter-Regular.ttf
│
├── lib/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── main_screen.dart
│   └── supabase_options.dart
│
├── .env
├── pubspec.yaml
└── README.md
```

---

## 🎨 Custom Branding

AcadArchive uses:
- **App Icon** → `assets/images/acadarchive_brand.png`
- **Splash Screen** → Configured via `flutter_native_splash`

To regenerate icons and splash:
```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

---

## 📱 Screenshots (Optional)
_Add screenshots of your app UI here once available._

---

## 👨‍💻 Author
**Josh Danielle Miranda**  
📧 [joshdaniellemiranda@gmail.com](mailto:joshdaniellemiranda@gmail.com)

---

## 🪪 License
This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
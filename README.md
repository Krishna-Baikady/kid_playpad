# Kid PlayPad ⌨️👶

> **Let your child bash the keyboard safely — zero ruined documents, zero blasted volume, zero screen-time tantrums.**

[![macOS 13.0+](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Safety: In-Memory](https://img.shields.io/badge/Safety-100%25%20In--Memory-brightgreen.svg)]()

---

Every parent working on a Mac knows the feeling: your toddler sees you typing, climbs onto your lap, and desperately wants to press the keys too. 

If you let them, they might accidentally delete your spreadsheets, trigger Siri, send half-finished Slack messages, or blast the volume to 100%. Most existing "baby lock" apps either alter permanent system files (leaving your Mac stuck if they crash) or use hyper-stimulating neon animations and loud sound effects that foster screen addiction.

**Kid PlayPad** is a lightweight, calm, and hyper-secure macOS app that transforms your Mac into a safe, kid-friendly typing playground.

---

## ✨ Why Parents Love Kid PlayPad

* 🛡️ **Total and Safe Hardware Lockdown**: Safely intercepts and drops all keystrokes, trackpad clicks, and mouse movement. Prevents app-switching (`Cmd + Tab`), force quit (`Option + Cmd + Esc`), and dock access.
* 🔇 **Hardware Media Key Protection**: Unlike other utilities, Kid PlayPad blocks hardware Volume Up/Down, Mute, and Play/Pause keys so your toddler can't blast the speakers.
* 🔤 **Educational & Responsive**: Pressing any letter key displays that **exact typed letter** in a soft, rounded tile. Any other key displays a peaceful geometric shape.
* 🌿 **Non-Stimulating, Kid-Friendly Colors**: Strictly designed with soothing earth tones and dull pastels (muted sage, slate, dusty clay, taupe). No loud bleeps, no flashing neon lights, and no sensory overstimulation.
* 👋 **Built-In Gentle Wind-Down**: Screen time ends smoothly. In the final minute, shapes fade away and a friendly animated waving hand mascot (`👋`) appears to help your child prepare to say goodbye without tantrums.
* 🔒 **100% In-Memory & Kernel Safe**: Never touches your macOS system preference files or plist configs. If closed or force-quit, the macOS kernel automatically and instantly restores full keyboard and mouse control.

---

## ⏱️ How It Works (The 3-Minute Session)

Kid PlayPad runs in structured, predictable sessions designed to make ending screen time natural and drama-free:

| Time | Top Badge | What Your Child Sees | What Parents Can Do |
| :--- | :---: | :--- | :--- |
| **Minutes 1 & 2** | `3`, `2` | **Play & Learn Phase**: Pressing letters shows the exact letter typed (A–Z); other keys show soft shapes. | Relax knowing your Mac is 100% locked. |
| **Minute 3** | `1` | **Goodbye Phase**: Key spawning stops. A friendly waving hand mascot (`👋`) appears in the center to signal that play time is ending. | Prepare to transition to the next activity. |
| **Final 30 Seconds** | `1` | **Warning Modal**: A live 30-second countdown appears over the waving mascot. | **Mouse unlocks automatically** so you can click **"Add Time"** (+3 mins) or **"Unlock Mac"**. |

### 🔑 Regain Control Anytime (Parent Unlock Shortcut)
You never have to wait for the timer to finish. If you need your Mac back midway through a session (for an urgent email, call, or diaper change), simply press:

$$\mathbf{Command + Option + Control + U}$$

This instantly closes the app and restores 100% of your keyboard and mouse control immediately.

---

## 📥 Download & Quick Start

> **Compatibility**: Tested on **macOS Sequoia** and **macOS Sonoma** (Apple Silicon M1–M4 & Intel). Requires macOS 13.0 (Ventura) or later.

### Option 1: Direct Download (Easiest)
1. Download the latest **`Kid-PlayPad-macOS.zip`** from the **[Releases](https://github.com/Krishna-Baikady/kid_playpad/releases)** tab on GitHub.
2. Double-click the downloaded zip to extract **`Kid PlayPad.app`**, and drag it into your **Applications** folder.
3. **First-Time Open**: Right-click (or Control-click) **Kid PlayPad.app** → click **Open** → click **Open** in the dialog.  
   *(This one-time step is required for independent open-source apps not distributed through the Mac App Store).*
4. Follow the clear on-screen guide to turn ON Accessibility permissions, then click **Check permission and START**!

### Option 2: Build from Source (For Developers)
```bash
# Clone the repository
git clone https://github.com/Krishna-Baikady/kid_playpad.git
cd kid_playpad

# Build and package the standalone app
swift build -c release
mkdir -p "Kid PlayPad.app/Contents/MacOS" "Kid PlayPad.app/Contents/Resources"
cp .build/release/KidPlayPad "Kid PlayPad.app/Contents/MacOS/"
cp Info.plist "Kid PlayPad.app/Contents/"
codesign --force --deep --sign - "Kid PlayPad.app"

# Launch
open "Kid PlayPad.app"
```

---

## 💡 Pro-Tips for Parents

### ⚡ Quick Launch via Spotlight
When your toddler climbs onto your lap, the fastest zero-setup way to launch:
1. Press **`Cmd + Space`** to open Spotlight.
2. Type **`Kid`** and hit **`Return`**.

*(Optional power-user tip: You can also assign a dedicated global hotkey like `Option + Shift + K` using the macOS Shortcuts app).*

---

## 🛡️ Safety & Disclaimer

* **Parental Supervision Required**: Kid PlayPad is a software utility designed to prevent accidental keystrokes and app switching. It is not a substitute for active adult supervision. The authors are not responsible for physical hardware damage, spilled liquids, dropped laptops, or toddler antics.

---

## 📜 License

Licensed under the terms of the **[MIT License](LICENSE)**. Open source and free for parents and educators everywhere.

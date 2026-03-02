# Auto Patch FaceUnlock for OPlus ROM with Workflow
Automated workflow to patch services.jar - implements Motorola Face Unlock into OPlus-based ROMs (ColorOS 16, realmeUI 7, OxygenOS 16) and disables secure screenshots. All required files are included, simply run the workflow and download the result.

<div align="center">

![Android](https://img.shields.io/badge/Android-000000?style=flat-square&logo=android&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-000000?style=flat-square&logo=gnubash&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-000000?style=flat-square&logo=githubactions&logoColor=white)

</div>

---

## ✨ Features

- 🔓 **Face Unlock** - Fix Face Unlock on OPlus ROM with Implements motorola Face Unlock into ColorOS 16, realmeUI 7, OxygenOS 16
- 📸 **Disable Secure Screenshot** — Removes screenshot restrictions on secure windows, you can enable this feature option while patching
- ⚙️ **Automated** - Just provide a mirror link of services.jar file link on Pixeldrain, GitHub Actions does the rest
- 📦 **Ready to Use** - Output includes patched `services.jar` + required system files

---

## 📦 Output
```
Patched_FaceUnlock_Build/
├── services.jar       ← Patched services.jar
└── system/
    ├── lib64/         ← Required native libraries
    └── etc/           ← Required config files
```
---

## 📋 Requirements
- OPlus-based ROMs: **ColorOS 16 / realmeUI 7 / OxygenOS 16**
- Direct download link for `services.jar` from your ROM
- GitHub account (to fork and run workflow)

## 📂 User manual

### Step 1
1. **Fork** this repository to your GitHub account
2. Go to the **Actions** tab
3. Select **Auto Patch FaceUnlock** from the left sidebar
4. Click **Run workflow**
5. Paste the **direct download link** to your `services.jar`
6. Click **Run workflow** and wait
7. Download the artifact **Patched_FaceUnlock_Build** when done

---

### Step 2
1. Once the workflow is complete, download the results.
2. Then, replace the previous services.jar file and copy all the HALs from your system.
3. That's it. Good luck!

---

## 🙏 Credits

| Name | Contribution |
|------|-------------|
| [@ryanistr](https://github.com/ryanistr) | Original Face Unlock Guide and HALs |
| [@XTENSEI](https://github.com/XTENSEI) | Workflow improvements & fixes |
| [@zerophyx-4](https://github.com/zerophyx-4) | Workflow & patch scripts |
---

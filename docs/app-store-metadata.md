# App Store Metadata — LeiLeMe (累了么)

## Basic Information

- **App Name:** LeiLeMe (累了么)
- **Subtitle (EN):** Daily Recovery Assessment
- **Subtitle (zh-Hans):** 每日恢复评估
- **Category (Primary):** Health & Fitness
- **Category (Secondary):** Medical (optional — omit if it triggers extra review)
- **Age Rating:** 4+ (no objectionable content, no medical diagnosis)
- **Pricing:** TODO — pricing model TBD (free / one-time purchase / subscription)

---

## App Store Description

### English

**Promotional Text** (170 chars, updatable without review):
Track your daily recovery with 9 science-based measures. No wearable required — just your iPhone and 90 seconds a day.

**Description:**
LeiLeMe helps you understand how recovered your body is each day through 9 simple measures spanning physical, cognitive, and subjective dimensions.

**What you get:**
• A daily recovery score based on 9 measures: reaction time, tap speed, grip strength, balance, heart rate variability, resting heart rate, sleep, perceived energy, and mood
• A personalized baseline that learns your body's patterns over 7 days
• Weekly recovery insights showing trends and changes
• Streak tracking to build a consistent check-in habit
• Push notification reminders so you never miss a day
• Full data export (CSV/JSON) — your data is always yours

**How it works:**
1. Complete quick daily assessments — most take under 10 seconds
2. LeiLeMe builds a personal baseline from your first 7 days
3. Each day, your recovery score shows how today compares to your normal
4. Weekly insights reveal trends you can act on

**Privacy first:**
All data stays on your device. No accounts, no cloud sync, no tracking. HealthKit data (heart rate, HRV, sleep) is read locally and never leaves your phone.

**Apple Watch integration:**
If you wear an Apple Watch, LeiLeMe automatically reads resting heart rate, HRV, and sleep data from Apple Health. No Watch? No problem — 6 of 9 measures work with just your iPhone.

### 简体中文 (zh-Hans)

**Promotional Text:**
通过9项科学指标追踪每日恢复状态。无需可穿戴设备——只需iPhone和每天90秒。

**Description:**
累了么帮助你通过9项简单指标了解身体每天的恢复状况，涵盖身体、认知和主观三个维度。

**你将获得：**
• 基于9项指标的每日恢复评分：反应时间、点击速度、握力、平衡、心率变异性、静息心率、睡眠、体感精力和情绪
• 个性化基线——在7天内学习你的身体模式
• 每周恢复洞察，展示趋势和变化
• 连续打卡追踪，帮助养成稳定的检查习惯
• 推送通知提醒，确保每天不遗漏
• 完整数据导出（CSV/JSON）——你的数据始终属于你

**使用方法：**
1. 完成快速的每日评估——大多数不到10秒
2. 累了么在前7天建立个人基线
3. 每天的恢复评分显示今天与你的正常水平相比如何
4. 每周洞察揭示你可以采取行动的趋势

**隐私至上：**
所有数据保留在你的设备上。无需注册账号，无云同步，无追踪。HealthKit数据（心率、HRV、睡眠）在本地读取，绝不离开你的手机。

**Apple Watch集成：**
如果你佩戴Apple Watch，累了么会自动从Apple Health读取静息心率、HRV和睡眠数据。没有Watch？没问题——9项指标中有6项只需iPhone即可使用。

---

## Keywords (100 characters max each)

### English
recovery,fatigue,health,wellness,HRV,sleep,heart rate,daily check,baseline,body score

### 简体中文
恢复,疲劳,健康,养生,HRV,睡眠,心率,每日检查,基线,身体评分

---

## Age Rating Questionnaire

| Category | Answer |
|----------|--------|
| Violence | None |
| Sexual Content | None |
| Profanity | None |
| Drug/Alcohol/Tobacco Use | None |
| Gambling | None |
| Horror/Fear | None |
| Medical/Treatment Information | No (recovery assessment, not medical diagnosis) |
| Unrestricted Web Access | No |
| Contests | None |

**Result: 4+ rating**

---

## Privacy Nutrition Labels

### Data Types Collected

| Data Type | Category | Purpose | Linked to Identity | Tracking |
|-----------|----------|---------|-------------------|----------|
| Heart Rate (read) | Health & Fitness | App Functionality | No | No |
| Heart Rate Variability (read) | Health & Fitness | App Functionality | No | No |
| Sleep Analysis (read) | Health & Fitness | App Functionality | No | No |

### Data Practices

- **Data Used to Track You:** None
- **Data Linked to You:** None
- **Data Not Linked to You:** Health & Fitness (HealthKit reads)
- **Data Collection:** Optional (HealthKit authorization is requested but not required)
- **Third-Party Sharing:** None
- **Data Storage:** Device-only (SwiftData local store)
- **Account Required:** No
- **Data Retention:** Until user deletes app or exports/deletes data manually

### HealthKit Specifics (for Apple review)

- **Read types:** `HKQuantityType.heartRateVariabilitySDNN`, `HKQuantityType.restingHeartRate`, `HKCategoryType.sleepAnalysis`
- **Write types:** None (NSHealthUpdateUsageDescription is present but no write operations are implemented)
- **Clinical records:** Not accessed
- **Background delivery:** Not used
- **Purpose:** Recovery assessment — comparing daily biometrics against personal baseline

> **Note:** NSHealthUpdateUsageDescription exists in Info.plist but the app does NOT write to HealthKit. Consider removing it before submission to avoid reviewer questions, or keep it for future use. If removed, also remove it from InfoPlist.strings in both locales.

---

## Support & Legal

- **Support URL:** TODO — set up a simple support page (GitHub Pages recommended)
- **Privacy Policy URL:** See `docs/privacy-policy.md` — host as a web page
- **License Agreement:** Standard Apple EULA (default)
- **Copyright:** © 2026 [Developer Name]

---

## Screenshots

Required sizes:
- 6.7" (iPhone 15 Pro Max / 16 Pro Max): 1290 x 2796 px
- 6.1" (iPhone 15 / 16): 1179 x 2556 px
- Optional: 5.5" (iPhone 8 Plus): 1242 x 2208 px

Recommended screenshot sequence:
1. Home page with recovery score
2. Measure detail with history
3. Tap test / reaction time in action
4. Weekly insights card
5. Streak display
6. Settings / data export

> Screenshots to be captured during T0041 device compatibility testing.

---

## Flags & TODOs

- [ ] **TODO: Pricing model** — free / one-time purchase / freemium / subscription — decision needed before submission
- [ ] **TODO: Support URL** — create and host support page
- [ ] **TODO: Developer name / copyright** — confirm legal entity
- [ ] **TODO: Screenshots** — capture during T0041
- [ ] **TODO: App icon** — verify meets App Store requirements (1024x1024 no alpha)
- [ ] Consider removing NSHealthUpdateUsageDescription if no HealthKit writes are planned for v1

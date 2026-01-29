<div align="center">

<img src="https://github.com/user-attachments/assets/049e8816-3a03-46db-b1d6-df19cb113db6" alt="미러링부스 썸네일" width="100%" />

### 내 손 안의 포토부스

**가장 선명하게, 우리다운 순간을 기록하다.**

포토부스를 찾아갈 필요 없이, Apple 기기만 있으면 어디서나 시작되는 나만의 포토부스

<br>

📥 **앱 다운로드**

**[TestFlight로 설치 (권장)](https://testflight.apple.com/join/enKrknEr)** | [AppBox로 설치](https://appbox.me/xepf4oo8)

TestFlight가 처음이라면 → [설치 가이드](https://drive.google.com/file/d/1Dmga2k9LP1twziCmxFiiYCYUD5FdKfp4/view?usp=share_link)

</div>

---

## 목차

- [📌 프로젝트 개요](#프로젝트-개요)
- [✨ 주요 기능](#주요-기능)
- [📱 지원 기기](#지원-기기)
- [🛠️ 기술 스택](#기술-스택)
- [💡 핵심 경험](#핵심-경험)
- [🏠 시스템 아키텍처](#시스템-아키텍처)
- [📁 프로젝트 구조](#프로젝트-구조)
- [📚 관련 문서](#관련-문서)
- [👥 팀원 소개](#팀-소개)

---

## 📌 프로젝트 개요

> 📷 최신 스마트폰의 후면 카메라는 성능이 정말 좋지만, 셀카를 찍을 때 **내 모습이 보이지 않아** 결국 화질이 낮은 전면 카메라를 쓰게 됩니다.

- 남이 찍어줄 때도 내가 어떻게 나오는지 실시간으로 볼 수 없어 **"찍고 확인하고 다시 찍는"** 번거로운 과정이 반복됩니다.
- 기존 Apple Watch 리모컨 기능은 화면이 너무 작아 표정이나 구도를 잡기 불편하고, 셔터를 누를 때 **시선이 분산**되는 한계가 있었습니다.

<br>

**미러링부스**는 이미 보유한 iPhone, iPad, Mac 등 Apple 기기들을 하나로 연결해 **언제 어디서든 나만의 포토부스**를 만드는 것을 목표로 합니다.

단순히 사진 앱을 만드는 것을 넘어, 기기 간 화면 공유를 통해 사용자가 직접 **스튜디오급 결과물**을 만들 수 있는 촬영 환경을 구축합니다.

- 📍 **어디서나 나만의 스튜디오** : 집, 카페, 여행지 등 Apple 기기만 있으면 나만의 포토부스
- 📷 **후면 카메라 화질 유지** : 고화질로 촬영하면서 실시간 모니터링 가능
- 🍎 **Apple 생태계 활용** : 보유한 기기들이 연동되어 동작하는 재미

---

## ✨ 주요 기능

<div align="center">

### 💻 다양한 기기 연결

<img width="5760" height="3240" alt="iOS03 스크린샷 1 - 다양한 기기 연결@3x" src="https://github.com/user-attachments/assets/031187b7-131a-4aeb-a49c-bab6b39b57e4" />

<br>

<b>가지고 있는 기기를 자유롭게 연결하세요.</b>

<br>

---

### 📷 촬영 방식 선택

<img width="5760" height="3240" alt="iOS03 스크린샷 2 - 촬영 방식 선택@3x" src="https://github.com/user-attachments/assets/ae355ad9-842d-43c7-9cd6-63c39a66447c" />

<br>

<b>원하는 촬영 방식을 선택하세요.</b>  
<br>
<b>**타이머 촬영**: 8초 카운트다운 후 8초 간격으로 10장 자동 촬영</b>  
<b>**리모트 촬영**: 연결된 기기에서 직접 촬영 버튼을 눌러 원하는 순간 촬영</b>

<br>

---

### 🤳 촬영 및 포즈

<img width="5760" height="3240" alt="iOS03 스크린샷 3 - 촬영 및 포즈 추천@3x" src="https://github.com/user-attachments/assets/e35eba87-4f2e-4bb2-a1d0-b48713b917c8" />

<br>

<b>iPhone 카메라 화면을 iPad, Mac 등에서 실시간으로 확인하세요.</b>  
<br>
<b>포즈 가이드로 다양한 포즈를 추천 받아보세요.</b>

<br>

---

### 🎨 프레임과 레이아웃 선택

<img width="5760" height="3240" alt="iOS03 스크린샷 4 - 편집@3x" src="https://github.com/user-attachments/assets/52b8c48b-770f-438d-b57d-d15933222b74" />

<br>

<b>촬영한 사진 중 원하는 사진을 선택하고, 다양한 스타일의 프레임에 합성하세요.</b>

<br>

---

### 🎑 결과 저장 및 공유

<img width="5760" height="3240" alt="iOS03 스크린샷 5 - 결과 및 공유@3x" src="https://github.com/user-attachments/assets/9d6275a8-f08b-4a17-b215-c3e32862ed9f" />

<br>

<b>완성된 사진을 저장하거나 공유하세요.</b>

<br>

</div>

---

## 📱 지원 기기

보유한 Apple 기기를 자유롭게 조합하여 사용하세요!

| 역할 | 기기 | 최소 버전 |
|:---:|---|---|
| **촬영** (카메라) | iPhone | <img src="https://img.shields.io/badge/iOS_17.0+-000000?style=flat-square&logo=apple&logoColor=white"> |
| **미러링** (실시간 확인) | iPhone, iPad, Mac | <img src="https://img.shields.io/badge/iOS_17.0+-000000?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/iPadOS_17.0+-000000?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/macOS_14.0+-000000?style=flat-square&logo=apple&logoColor=white"> |
| **리모트** (촬영 버튼) | iPhone, iPad, Mac, Apple Watch | <img src="https://img.shields.io/badge/iOS_17.0+-000000?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/iPadOS_17.0+-000000?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/macOS_14.0+-000000?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/watchOS_10.0+-000000?style=flat-square&logo=apple&logoColor=white"> |

**조합 예시**
- iPhone(카메라) + iPhone(미러링)
- iPhone(카메라) + iPad(미러링)
- iPhone(카메라) + Mac(미러링) + Watch(리모트)

> 원활한 동작을 위해 **Bluetooth**와 **Wi-Fi**가 반드시 켜져 있어야 합니다.

---

## 🛠 기술 스택

| 구분 | 스택 |
|---|---|
| **Language** | <img src="https://img.shields.io/badge/Swift_5.0-F05138?style=flat-square&logo=swift&logoColor=white"> |
| **UI** | <img src="https://img.shields.io/badge/SwiftUI-0D96F6?style=flat-square&logo=swift&logoColor=white"> <img src="https://img.shields.io/badge/@Observable-8E44AD?style=flat-square&logo=swift&logoColor=white"> |
| **Connectivity** | <img src="https://img.shields.io/badge/MultipeerConnectivity-34C759?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/WatchConnectivity-FF9500?style=flat-square&logo=apple&logoColor=white"> |
| **Media** | <img src="https://img.shields.io/badge/AVFoundation-FF2D55?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/VideoToolbox_(H.264)-5856D6?style=flat-square&logo=apple&logoColor=white"> |
| **Async** | <img src="https://img.shields.io/badge/Combine-007AFF?style=flat-square&logo=apple&logoColor=white"> <img src="https://img.shields.io/badge/async/await-1ABC9C?style=flat-square&logo=swift&logoColor=white"> |
| **Tools** | <img src="https://img.shields.io/badge/Xcode-147EFB?style=flat-square&logo=xcode&logoColor=white"> <img src="https://img.shields.io/badge/SwiftLint-E74C3C?style=flat-square&logo=swift&logoColor=white"> |
| **CI/CD** | <img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white"> <img src="https://img.shields.io/badge/Fastlane-00F200?style=flat-square&logo=fastlane&logoColor=white"> <img src="https://img.shields.io/badge/n8n-EA4B71?style=flat-square&logo=n8n&logoColor=white"> |

---

## 💡 핵심 경험

| 경험 | 설명 | 링크 |
|---|---|---|
| **멀티 디바이스 통신** | MultipeerConnectivity로 Apple 기기 간 실시간 스트리밍을 구현한 경험을 소개합니다. | [![Wiki](https://img.shields.io/badge/↗_Wiki-2D9CDB?style=flat-square)](https://github.com/boostcampwm2025/iOS03-dolAwang/wiki/%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC-%ED%86%B5%EC%8B%A0-%EA%B3%BC%EC%A0%95) |
| **재연결 로직** | 디바이스 별 연결이 끊어졌을 때 어떻게 대응하는지 설명합니다. | [![Wiki](https://img.shields.io/badge/↗_Wiki-9B59B6?style=flat-square)](https://github.com/boostcampwm2025/iOS03-dolAwang/wiki/%F0%9F%94%AA-%EC%97%B0%EA%B2%B0-%EB%81%8A%EA%B9%80-%EB%8C%80%EC%9D%91) |
| **CI/CD 자동화** | GitHub Actions로 빌드 자동화, 에셋 자동 병합 시스템 구축을 진행했습니다. | [![Wiki](https://img.shields.io/badge/↗_Wiki-E74C3C?style=flat-square)](https://github.com/boostcampwm2025/iOS03-dolAwang/pull/68) |
| **AI PR 자동 리뷰** | n8n을 활용한 AI PR 자동 리뷰 파이프라인 구축을 진행한 경험을 소개합니다. | [![Wiki](https://img.shields.io/badge/↗_Wiki-27AE60?style=flat-square)](https://daegom.notion.site/n8n-PR-2eb1833ac003807ba1f7ec97515ea243) |
| **사용자 테스트** | 실사용자 피드백 기반 UX 개선 (공유 시트, 토스트 컴포넌트 등)을 진행한 기록입니다. | [![Wiki](https://img.shields.io/badge/↗_Wiki-FF9500?style=flat-square)](#) |

---

## 🏛 시스템 아키텍처

<img width="1456" height="859" alt="image" src="https://github.com/user-attachments/assets/48031810-8f8c-4082-84ec-a3eee0cd8e13" />

**주요 컴포넌트**
- **Camera Device**: iPhone 후면 카메라로 촬영, H.264 인코딩 후 스트리밍
- **Mirroring Device**: 스트림 수신 및 디코딩하여 실시간 미러링 화면 표시
- **Remote Device**: 원격 촬영 명령 전송

**통신 방식**
- **MultipeerConnectivity**: iPhone ↔ iPad ↔ Mac 간 P2P 통신 (영상 스트리밍 + 촬영 명령)
- **WatchConnectivity**: iPhone ↔ Apple Watch 간 1:1 통신 (촬영 명령 전용)

> Apple Watch는 MultipeerConnectivity를 지원하지 않아 WatchConnectivity로 iPhone과 직접 연결됩니다.

---

## 📂 프로젝트 구조

```
mirroringBooth/
├── App/                          # 앱 진입점 및 루트 구성
│   ├── mirroringBoothApp.swift   # @main 앱 엔트리
│   ├── AppDelegate.swift         # 앱 생명주기 관리
│   ├── RootView.swift            # 루트 뷰
│   └── RootStore.swift           # 루트 상태 관리
│
├── Core/                         # 공통 인프라
│   ├── StoreProtocol.swift       # MVI 아키텍처 프로토콜
│   ├── Router.swift              # 화면 전환 라우팅
│   ├── AppLogger.swift           # 로깅 유틸리티
│   └── PlistRepository.swift     # Plist 데이터 관리
│
├── Device/                       # 기기별 기능 모듈
│   ├── Camera/                   # 촬영 기기
│   ├── Mirroring/                # 미러링 기기
│   ├── Remote/                   # 리모트 기기
│   └── Common/                   # 공통 컴포넌트
│
└── Resources/                    # 리소스 파일
```

---

## 📚 관련 문서

더 자세한 정보는 프로젝트 위키에서 확인할 수 있습니다.

| 문서 | 링크 |
|---|---|
| 그라운드 룰 | [![Wiki](https://img.shields.io/badge/↗_그라운드룰-2D9CDB?style=flat-square)](https://github.com/boostcampwm2025/iOS03-dolAwang/wiki/%E2%9A%94%EF%B8%8F%C2%A0%EA%B7%B8%EB%9D%BC%EC%9A%B4%EB%93%9C-%EB%A3%B0) |
| 기획서 | [![Wiki](https://img.shields.io/badge/↗_프로젝트_기획서-9B59B6?style=flat-square)](https://github.com/boostcampwm2025/iOS03-dolAwang/wiki/%EA%B8%B0%ED%9A%8D%EC%84%9C) |
| 설계서 | [![Wiki](https://img.shields.io/badge/↗_프로젝트_설계서-E74C3C?style=flat-square)](https://www.figma.com/design/7JOGxTFogHn71WU3q8VOSZ/%EB%AF%B8%EB%9F%AC%EB%A7%81%EB%B6%80%EC%8A%A4-%ED%99%94%EB%A9%B4-%EC%84%A4%EA%B3%84%EC%95%88?node-id=0-1&t=GsglDcx1sHtk6ooq-1) |
| 프로덕트 백로그 | [![Wiki](https://img.shields.io/badge/↗_프로덕트_백로그-27AE60?style=flat-square)](https://github.com/orgs/boostcampwm2025/projects/239/views/5) |

---

## 👥 팀원 소개

<div align="center">

<table>
<thead>
<tr>
<th align="center">S022 윤대현</th>
<th align="center">S024 이상유</th>
<th align="center">S029 전귀로</th>
<th align="center">S038 최윤진</th>
</tr>
</thead>
<tbody>
<tr>
<td align="center">
<img width="170" alt="S022" src="https://github.com/user-attachments/assets/674f6f68-c659-49cc-b9ed-966345e6baf4" />
</td>
<td align="center">
<img width="146" alt="S024" src="https://github.com/user-attachments/assets/c25cf5ee-b660-4910-a085-8fadbf6187ac" />
</td>
<td align="center">
<img width="172" height="226" alt="S029" src="https://github.com/user-attachments/assets/8c70aeed-9469-4bf1-a87c-00349a9d2957" />
</td>
<td align="center">
<img width="170" height="218" alt="S038" src="https://github.com/user-attachments/assets/f9ef5669-ab71-469e-9f6c-b59ca3f9c934" />
</td>
</tr>
<tr>
<td align="center">위키 리더</td>
<td align="center">UI/UX 리더</td>
<td align="center">팀 리더</td>
<td align="center">테크 리더</td>
</tr>
</tbody>
</table>

</div>

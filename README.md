<div align="center">

<img src="https://github.com/user-attachments/assets/049e8816-3a03-46db-b1d6-df19cb113db6" alt="미러링부스 썸네일" width="100%" />

### 내 손 안의 포토부스

**가장 선명하게, 우리다운 순간을 기록하다.**

포토부스를 찾아갈 필요 없이, Apple 기기만 있으면 어디서나 시작되는 인생N컷

<br>

📥 **앱 다운로드**

**[TestFlight로 설치 (권장)](https://testflight.apple.com/join/enKrknEr)** | [AppBox로 설치](https://appbox.me/xepf4oo8)

TestFlight가 처음이라면 → [설치 가이드](https://drive.google.com/file/d/1VK9TpWCFxb7PFmxqdfirVWv-yiq-dWDM/view?usp=share_link)

</div>

---

## 목차

- [프로젝트 개요](#프로젝트-개요)
- [주요 기능](#주요-기능)
- [지원 기기](#지원-기기)
- [기술 스택](#기술-스택)
- [핵심 경험](#핵심-경험)
- [시스템 아키텍처](#시스템-아키텍처)
- [프로젝트 구조](#프로젝트-구조)
- [관련 문서](#관련-문서)
- [팀원 소개](#팀-소개)

---

## 📌 프로젝트 개요

> 📷 스마트폰 후면 카메라는 화질이 좋지만, 셀카를 찍을 때 **내 모습을 볼 수 없습니다.**  
> 결국 화질이 낮은 전면 카메라를 쓰거나, "찍고 확인하고 다시 찍는" 과정을 반복하게 됩니다.

**미러링부스**는 이 문제를 해결합니다.

iPhone 후면 카메라를 **렌즈**로, iPad나 Mac의 넓은 화면을 **거울(뷰파인더)** 처럼 활용해서 촬영하면서 **실시간으로 내 모습을 확인**할 수 있습니다. 

포즈와 구도를 잡은 뒤 원격으로 촬영하면 끝!

- 📍 **어디서나 나만의 스튜디오** : 집, 카페, 여행지 등 Apple 기기만 있으면 나만의 포토부스
- 📷 **후면 카메라 화질 유지** : 고화질로 촬영하면서 실시간 모니터링 가능
- 🍎 **Apple 생태계 활용** : 보유한 기기들이 연동되어 동작하는 재미

---

## ✨ 주요 기능

| 기능 | 설명 |
|:---:|---|
| **실시간 미러링** | iPhone 카메라 화면을 다른 Apple 기기에 실시간으로 고화질 스트리밍 |
| **원격 촬영** | iPad, Mac, Apple Watch 등 모든 기기에서 촬영 버튼 조작 가능 |
| **타이머 촬영** | 8초 카운트다운 후 8초 간격으로 10장 자동 촬영 |
| **포토 프레임 합성** | 촬영한 사진을 인생네컷 스타일의 예쁜 프레임에 자동 합성 |
| **Apple Watch 지원** | 손목에서 바로 촬영 버튼을 눌러 가장 편리하게 촬영 |


실제 동작 gif 추가 예정...

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

> 원활한 동작을 위해 **Bluetooth** 또는 **Wi-Fi**가 켜져 있어야 합니다.

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

### 아키텍처 (MVI)

프로젝트는 **MVI (Model-View-Intent)** 패턴을 사용합니다.

```mermaid
flowchart LR
    subgraph View
        V[SwiftUI View]
    end
    
    subgraph Store
        S[Store]
        ST[State]
    end
    
    V -->|"send(Intent)"| S
    S -->|"action(Intent)"| R[Results]
    R -->|"reduce(Result)"| ST
    ST -->|"@Observable"| V
```

| 구성 요소 | 역할 |
|:---:|---|
| **State** | View가 표시할 현재 상태 |
| **Intent** | 사용자 액션을 나타내는 이벤트 |
| **Result** | Intent 처리 결과, State를 변경 |
| **Store** | Intent를 받아 Result를 생성하고 State를 업데이트 |

---

## 💡 핵심 경험

| 경험 | 설명 |
|---|---|
| **멀티 디바이스 통신** | MultipeerConnectivity로 iPhone↔iPad↔Mac↔Watch 간 실시간 스트리밍 구현 |
| **재연결 로직** | 연결 끊김 시 자동 재연결 및 상태 복구 처리 |
| **CI/CD 자동화** | Fastlane + GitHub Actions로 빌드 자동화, 에셋 자동 병합 시스템 구축 |
| **AI PR 자동 리뷰** | n8n을 활용한 AI PR 자동 리뷰 파이프라인 구축 |
| **사용자 테스트** | 실사용자 피드백 기반 UX 개선 (공유 시트, 토스트 컴포넌트 등) |

[![Wiki](https://img.shields.io/badge/➜_더_자세한_기술_문서_보러가기-4F47E6?style=flat-square)](#)

---

## 🏛 시스템 아키텍처

```mermaid
flowchart TB
    subgraph Camera["Camera Device (iPhone)"]
        CAM[Camera Capture]
        ENC[H.264 Encoder]
        SEND[Stream Sender]
        CAM --> ENC --> SEND
    end
    
    subgraph MPC["MultipeerConnectivity"]
        CONN[P2P Connection]
    end
    
    subgraph Mirroring["Mirroring Device (iPhone/iPad/Mac)"]
        RECV[Stream Receiver]
        DEC[H.264 Decoder]
        DISP[Display View]
        RECV --> DEC --> DISP
    end
    
    subgraph Remote["Remote Device"]
        WATCH[Apple Watch]
        OTHER[iPhone/iPad/Mac]
    end
    
    SEND <-->|"Video Stream"| CONN
    CONN <-->|"Video Stream"| RECV
    Remote <-->|"Capture Command"| CONN
    CONN <-->|"Capture Command"| Camera
```

**주요 컴포넌트**
- **Camera Device**: iPhone 후면 카메라로 촬영, H.264 인코딩 후 스트리밍
- **Mirroring Device**: 스트림 수신 및 디코딩하여 실시간 미러링 화면 표시
- **Remote Device**: 원격 촬영 명령 전송 (Apple Watch 포함)
- **MultipeerConnectivity**: 모든 기기 간 P2P 통신 담당

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
│   ├── Camera/                   # 촬영 기기 모드
│   ├── Mirroring/                # 미러링 기기 모드
│   ├── Remote/                   # 리모트 기기 모드
│   └── Common/                   # 공통 컴포넌트
│
└── Resources/                    # 리소스 파일
```

---

## 📚 관련 문서

더 자세한 정보는 프로젝트 위키에서 확인할 수 있습니다.

| 문서 | 링크 |
|---|---|
| 그라운드 룰 | [![Wiki](https://img.shields.io/badge/↗_그라운드룰-2D9CDB?style=flat-square)](#) |
| 기획서 | [![Wiki](https://img.shields.io/badge/↗_프로젝트_기획서-9B59B6?style=flat-square)](#) |
| 설계서 | [![Wiki](https://img.shields.io/badge/↗_프로젝트_설계서-E74C3C?style=flat-square)](#) |
| 프로덕트 백로그 | [![Wiki](https://img.shields.io/badge/↗_프로덕트_백로그-27AE60?style=flat-square)](#) |

---

## 👥 팀원 소개

<div align="center">

### 왔다감

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

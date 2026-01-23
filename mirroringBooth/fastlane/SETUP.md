# Fastlane 설정 가이드

> [!NOTE]  
> 아래 설정은 `배포 담당자` 1명이 진행하면 됩니다.  

## 📋 최초 1회 세팅

### 1. 의존성 설치

```bash
cd mirroringBooth

bundle install
```

### 2. 환경 변수 파일 생성

프로젝트 Root 폴더가 아닌 `.xcodeproj` 폴더가 위치하고 있는 Root 하위 폴더에 `.env` 파일을 생성해야합니다!

`.env`의 경우 슬랙에 공유드린 파일을 사용해주세요!

### 3-1. AppBox CLI 설치 및 Dropbox 연동 (내부 테스터 배포용)

```bash
# Appbox.app 설치
curl -s https://getappbox.com/install.sh | bash
```

Appbox 설치 후 실행하신 뒤 최초 1회 `Dropbox` 연동을 진행해야합니다!  

그 후 AppBox를 실행하신 뒤 상단 메뉴 탭에서 `install CLI` 버튼을 클릭하셔서 `CLI`을 설치해주세요!

### 3-2. TestFlight 배포용 설정 (공식 배포)

TestFlight 배포는 **App Store Connect 접근 권한**이 있는 계정이 필요합니다!

`.env` 파일에 아래 정보가 설정되어 있어야 합니다. 이 또한 슬랙에 공유드린 파일을 사용해주세요!

```env
# TestFlight 배포용 (권한 있는 계정 정보)
APPLE_ID=권한있는이메일@codesquad.kr
TEAM_ID=에벱베베벱
```

> [!TIP]  
> `APPLE_ID`는 App Store Connect에서 권한이 있는 이메일이어야 하고,  
> `TEAM_ID`는 Xcode > Build Settings에서 `DEVELOPMENT_TEAM` 검색하면 나오는 10자리 영숫자입니다!

## 🚀 사용법

### IPA 빌드 및 배포

```bash
cd mirroringBooth
bundle exec fastlane dev_ipa
```

이 명령어는 다음 작업을 수행합니다:
1. Development IPA 빌드 (`build/mirroringBooth.ipa` 생성)
2. AppBox에 업로드
3. `.env` 파일에 설정된 이메일로 배포 링크 전송

### TestFlight 배포 (공식 배포용)
```bash
cd mirroringBooth
bundle exec fastlane dev_testflight
```

이 명령어는 다음 작업을 수행합니다:
1. App Store 배포용 IPA 빌드 (`build/mirroringBooth_appstore.ipa` 생성)
2. TestFlight에 자동 업로드
3. App Store Connect에서 빌드 처리 시작 (보통 5~10분 소요)

업로드 완료 후 [App Store Connect](https://appstoreconnect.apple.com)에서 테스터 그룹에 배포하시면 됩니다!

> 추후 시간이 남는다면 테스터 그룹 자동 추가 파이프라인도 구축해보겠습니다!

`TestFlight` 배포 시 변경사항을 함께 기록하고 싶으시다면 아래 명령어를 사용해주세요!

```bash
cd mirroringBooth
bundle exec fastlane dev_testflight changelog:"로그인 버그 수정 및 UI 개선"
```

## 📚 참고 자료

- [⭐️ 학습 자료: Fastlane으로 자동 배포 구현기](https://daegom.notion.site/Fastlane-2e61833ac00380389770f50c68e976b2?source=copy_link)
- [Fastlane 공식 문서](https://docs.fastlane.tools)
- [Fastlane 설치 가이드](https://docs.fastlane.tools/#installing-fastlane)
- [AppBox 플러그인](https://github.com/getappbox/fastlane-plugin-appbox)

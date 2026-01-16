# Fastlane 설정 가이드

> [!NOTE]  
> 아래 설정은 `배포 담당자` 1명이 진행하면 됩니다.  
> 직접 배포 후 AppBox 링크 추출을 진행하고 싶으실 때 아래 세팅을 진행하시면 됩니다.

## 📋 최초 1회 세팅

### 1. 의존성 설치

```bash
cd mirroringBooth

bundle install
```

### 2. 환경 변수 파일 생성

프로젝트 Root 폴더가 아닌 `.xcodeproj` 폴더가 위치하고 있는 Root 하위 폴더에 `.env` 파일을 생성해야합니다!

`.env`의 경우 슬랙에 공유드린 파일을 사용해주세요!

### 3. AppBox CLI 설치 및 Dropbox 연동

```bash
# Appbox.app 설치
curl -s https://getappbox.com/install.sh | bash
```

Appbox 설치 후 실행하신 뒤 최초 1회 `Dropbox` 연동을 진행해야합니다!  

그 후 AppBox를 실행하신 뒤 상단 메뉴 탭에서 `install CLI` 버튼을 클릭하셔서 `CLI`을 설치해주세요!

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

## 📚 참고 자료

- [⭐️ 학습 자료: Fastlane으로 자동 배포 구현기](https://daegom.notion.site/Fastlane-2e61833ac00380389770f50c68e976b2?source=copy_link)
- [Fastlane 공식 문서](https://docs.fastlane.tools)
- [Fastlane 설치 가이드](https://docs.fastlane.tools/#installing-fastlane)
- [AppBox 플러그인](https://github.com/getappbox/fastlane-plugin-appbox)

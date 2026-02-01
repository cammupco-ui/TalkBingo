# 배포 가이드 (Deployment Guide)

이 문서는 프로젝트를 GitHub에 업로드하고 GitHub Pages에 배포하는 방법을 설명합니다.

## 전제 조건
- Flutter SDK가 설치되어 있어야 합니다.
- Git이 설치되어 있어야 합니다.

## 1. 소스 코드 Github 업로드 (Source Code Upload)

현재 작업 내용을 저장하고 원격 저장소(GitHub)의 `main` 브랜치에 업로드합니다.

```bash
# 프로젝트 루트 경로에서 실행
git add .
git commit -m "작업 내용 업데이트 및 배포 준비"
git push origin main
```

## 2. 웹 빌드 (Web Build)

Flutter 앱을 웹용으로 빌드합니다. `app` 폴더 내에서 실행해야 합니다.

```bash
cd app
flutter clean
flutter pub get
flutter build web --release
```

빌드가 완료되면 `app/build/web` 폴더에 정적 파일들이 생성됩니다.

## 3. GitHub Pages 배포 (Deploy using gh-pages branch)

빌드된 파일(`app/build/web`)만 `gh-pages` 브랜치에 강제로 푸시하여 배포합니다.

```bash
# app/build/web 폴더로 이동
cd build/web

# 새로운 git 저장소 초기화 (빌드 결과물만 관리하기 위함)
git init
git add .
git commit -m "Deploy to GitHub Pages"

# 강제로 gh-pages 브랜치에 푸시
git branch -M gh-pages
git remote add origin https://github.com/cammupco-ui/TalkBingo.git
git push -u -f origin gh-pages

# 원래 폴더로 복귀
cd ../../..
```

## 4. 트러블슈팅 (Troubleshooting)

- **오류: "Updates were rejected because the tip of your current branch is behind..."**
    - 원인: 원격 저장소에 로컬에 없는 변경사항이 있을 때 발생합니다.
    - 해결: `git pull origin main --rebase` 로 변경사항을 가져온 후 다시 푸시하세요.

- **배포 후 페이지가 404가 뜨는 경우**
    - GitHub 저장소의 `Settings` -> `Pages` 메뉴에서 `Source`가 `Deploy from a branch`로 되어있고, `gh-pages` 브랜치와 `/(root)` 폴더가 선택되어 있는지 확인하세요.

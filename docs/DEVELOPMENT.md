# 다른 Windows PC에서 Android 앱 실행하기

이 버전에 사용한 도구는 Flutter 3.47.9(Dart 3.13.7), JDK 21, Android SDK Platform 36과 Build Tools 36.0.0이다. 새 PC에 도구를 설치한 뒤 저장소를 `C:\dev\DTR`처럼 영문 경로에 복제한다. Flutter SDK의 `bin`을 PATH에 추가하거나 `FLUTTER_ROOT`를 SDK 폴더로 지정한다. Android SDK를 기본 위치 밖에 설치했다면 `ANDROID_HOME`을 해당 폴더로 지정한다.

복제한 폴더에서 PowerShell을 열고 다음을 실행한다.

```powershell
.\flutter.ps1 doctor -v
.\flutter.ps1 pub get
.\flutter.ps1 test --concurrency=1
.\flutter.ps1 build apk --debug
```

`doctor`가 Android 라이선스 동의를 요청하면 해당 PC에서 `.\flutter.ps1 doctor --android-licenses`로 내용을 확인하고 진행한다. 첫 빌드에서는 Flutter 패키지, Gradle 및 필요한 Android 구성 요소를 내려받는다. 생성된 APK는 `build\app\outputs\flutter-apk\app-debug.apk`에 있다. Android 휴대폰 또는 가상 기기를 연결했다면 `.\flutter.ps1 devices`로 확인한 다음 `.\flutter.ps1 run`으로 실행한다.

기존 개발 PC에서는 스크립트가 상위 폴더의 돈토리 작업공간 표시와 설치된 도구를 확인한 뒤 `Q:` 경로 및 기존 임시·캐시 폴더를 재사용한다. 이 작업공간 안에서는 저장소 폴더 이름과 위치를 바꿔도 실행할 수 있다. 일반 PC에서는 현재 복제한 위치와 설치된 Flutter를 직접 사용한다.

Android의 `local.properties`와 Gradle 실행용 스크립트·JAR는 첫 Flutter 빌드에서 준비된다. 빌드 재현에 쓰이는 패키지 버전은 `pubspec.lock`, Gradle 버전은 `android/gradle/wrapper/gradle-wrapper.properties`에서 확인할 수 있다.

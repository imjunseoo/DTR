# 베타 사용 분석 — 구현 및 운영

2026-11-18: Cloudflare Worker + SQLite Durable Object에 배포했다. APK beta.3부터 선택 동의 후 수집한다. 이전 사용 내역은 소급 수집하지 않는다.

## 확인 방법

관리자 화면: https://dontori-chat-beta.promotion-report-worker.workers.dev/admin

관리자 접근 키는 로컬 산출물 DTR-analytics-admin.txt에 저장했다. APK와 Git에 포함하지 않으며 테스터에게 공유하지 않는다. 로그인은 Secure/HttpOnly/SameSite=Strict 쿠키로 24시간 유지한다.

테스터: 새 APK 설치 → 홈 하단 ‘베타 테스트 참여 · 사용 데이터 설정’ → 초대 코드 입력 → 선택 동의 → ‘동의하고 베타 참여’. 동의 전에는 설치 ID 생성과 이벤트 저장·전송을 하지 않는다. AI용 초대 코드와 동일하며 코드는 분석 설정 파일에 저장하지 않는다. 참여 거절은 앱 기능을 제한하지 않는다.

## 지표

| 지표 | 정의 |
|---|---|
| D0 | 동의 후 처음 예산이 준비된 한국 날짜. 기존 예산 사용자는 참여 당일 |
| D1 / D7 | D0+1 / D0+7일 활동 설치 ÷ 해당 날짜가 완전히 지난 설치. 미경과는 관측 대기 |
| 주간 기록일 | 월~일 신규 지출 저장 날짜 수. 하루 여러 번 저장도 1일. 그 주 종료일까지 활성화된 모든 참여 설치를 분모로 평균, 0일도 포함 |
| 위젯 진입률 | 위젯 캐릭터·간편 지출 버튼 클릭이 있었던 세션 ÷ 전체 세션. 같은 세션 여러 클릭은 1회 |

최근 28일 코호트·일별 사용과 최근 4주 기록일을 표시한다. 이번 주는 진행 중이다. 세션은 프로세스 시작, 30분 이상 백그라운드 후 복귀, 한국 날짜 변경 시 시작한다. 사람 수가 아닌 설치 기준이며 재설치는 별도 집계다. QA 모드는 제외한다. 위젯을 보기만 한 사실이나 충동구매 방지 성공 여부는 측정하지 않는다.

## 데이터와 삭제

허용 이벤트: app_active, session_start, widget_open, expense_saved, budget_ready. 무작위 설치 ID, 이벤트 ID, 날짜, 세션 ID, 진입 경로, 앱 버전만 저장한다. 금액·분류·메모·대화문·광고 ID·연락처는 보내지 않고 서버도 추가 속성을 거절한다. 설치별 인증 비밀은 서버에 해시로 보관한다.

오프라인 큐는 최대 1,000개다. 오래된 미전송 이벤트는 제외하고 연결 후 재전송하며 이벤트 ID로 중복 제거한다. 이벤트 보존은 90일, 비활성 설치 ID는 마지막 활동 후 최대 90일이다. 장기 미접속으로 인증이 만료되면 설정에서 수집 중지 후 다시 참여한다.

‘수집 중지하고 서버 데이터 삭제’는 즉시 수집·대기열을 중지하고 서버 이벤트를 삭제한다. 오프라인이면 삭제 요청만 남겨 재시도한다. 재전송 차단용 폐기 식별자는 최대 90일 유지하되 집계에서 제외한다. 삭제로 과거 집계가 바뀔 수 있다. 서버 요청 로그 수집은 비활성화했다.

## 운영

루트 .env의 ANALYTICS_ADMIN_TOKEN은 충분히 긴 무작위 키, BETA_TOKENS는 초대 코드 목록이다. server/cloudflare에서 node upload-secrets.mjs 후 node node_modules/wrangler/bin/wrangler.js deploy를 실행한다. 기존 바인딩과 migration을 유지해야 데이터가 보존된다.

APK는 DTR_CHAT_URL=/chat HTTPS 주소, DTR_ANALYTICS_URL=서버 HTTPS 기본 주소, DTR_APP_VERSION=1.0.0-beta.3+3 dart-define을 지정한다. 주소가 없는 빌드는 분석을 비활성화한다.

서버 테스트: node --test server/cloudflare/analytics.test.mjs
실제 배포 확인: cloudflare 폴더에서 node analytics-smoke.mjs. 가상 설치를 만들고 집계·중복 제거·로그인·삭제 검증 후 가상 데이터를 제거한다.

Figma 명세: https://www.figma.com/design/SMigmzPpEFzOww1QPpbudr?node-id=72-34 (Primary 계정 저장).

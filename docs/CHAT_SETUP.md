# 돈토리 대화: 구현 및 연결

## 현재 동작

- 하단 대화 탭. 위젯 돈토리 터치 → 대화, 기존 간편 지출 입력 → 지출 화면.
- 기본 대화·최근 7일 합계·구매 전 금액 계산은 기기에서 실행. 구매 예상은 일반 지출 시뮬레이션이며 DB나 성장 포인트를 바꾸지 않는다.
- 금액 계산은 기존 calculateBudget 사용. 저축과 미결제 고정지출을 보호하며 내일 배정액은 추가 지출이 없다는 가정이다.
- Claude 대화는 HTTPS 서버 주소, 서버 측 API 키/모델, 베타 초대 코드, 사용자 전송 동의가 모두 있어야 실행된다.
- 기본 빌드는 AI 미연결. 앱 종료 시 대화와 초대 코드가 사라진다. 최근 40개 말풍선만 메모리에 보관하며 AI에는 동의 후 AI 대화 최대 10개와 예산 요약만 전송한다.
- 전송 요약: 날짜, 오늘 남은 금액, HP, 남은 일수, 기간 만료 여부. 지출 메모·전체 내역은 자동 전송하지 않는다. 사용자가 직접 채팅에 쓴 정보는 전송된다.
- AI에는 계산·데이터 변경 도구가 없다. 정확한 계산은 화면의 구매 전 확인으로 안내한다. AI 자연어 응답의 정확성을 보증하지 않는다.

## Claude 서버 설정 (배포 전 필요)

1. Claude Console에서 API 키와 사용 가능한 모델 ID를 준비한다. 키는 채팅에 공유하지 않는다.
2. Node.js 22 이상 서버에서 `server/.env.example`을 `.env`로 복사하고 키, 모델 ID, 베타 초대 코드를 설정한다. `.env`는 Git 제외 대상이다.
3. 초대 코드는 테스터마다 별개로 생성한다: `node -e "console.log(require('node:crypto').randomBytes(24).toString('base64url'))"`. `BETA_TOKENS`에 쉼표로 구분해서 설정한다. 이 코드는 Claude API 키가 아니다.
4. 저장소 루트에서 `node --env-file=.env server/chat-server.mjs` 실행. `/health` 상태 확인. 단일 프로세스 전용이며 HTTPS 역방향 프록시 뒤에서 운영한다. 기본은 로컬 주소만 수신한다.
5. `server/data`는 영구 볼륨으로 보관한다. 재시작 시에도 한국 날짜 기준 사용자별 10회/전체 1,000회 한도가 유지된다. 실패 호출도 비용 발생 가능성을 고려해 한도에 포함한다. 여러 인스턴스로 확장하기 전 공유 DB 기반 원자적 한도로 교체해야 한다.
6. 공개 HTTPS 서버 준비 후 `flutter build apk --debug --dart-define=DTR_CHAT_URL=https://YOUR_HOST/chat`로 빌드한다. APK에는 서버 주소만 포함한다. Claude API 키나 공용 초대 코드를 dart-define에 넣지 않는다.
7. 테스터가 대화 탭에서 AI 대화 켜기 → 전송 동의 → 개인 초대 코드 입력. 해당 코드는 앱 실행 세션 동안만 유지된다.

서버는 대화/금액/키를 로그나 파일에 저장하지 않는다. 한도 파일에는 초대 코드의 SHA-256 해시와 일별 횟수만 저장한다. 실제 호스팅 로그·보존 정책과 Anthropic 데이터 처리 고지는 배포 시 확인한다. 일일 한도는 비용 상한 자체가 아니므로 Claude Console의 지출 제한도 함께 설정한다.

## 검증

`flutter test` / `flutter analyze` / `node --test server/chat-server.test.mjs`.
실제 API 키와 공개 서버가 없으면 Claude 실응답·실제 과금 검증은 수행할 수 없다.
Android 홈 런처에서 앱 종료/실행 중 돈토리 클릭, 간편 지출 입력, 작은 위젯, 키보드, 오프라인과 한도 초과를 최종 확인한다.

API 기준: https://platform.claude.com/docs/en/api/messages/create

## Cloudflare HTTPS 배포

`server/cloudflare`는 Workers용 실행 파일이다. 기존 Node 서버와 메시지 검증·프롬프트를 공유한다. 일일 한도는 단일 이름의 SQLite Durable Object에서 트랜잭션으로 집계하며, 여러 서버 인스턴스와 재배포 사이에도 유지된다. 저장 항목은 현재 한국 날짜, 초대 코드 해시, 호출 횟수와 마지막 요청 시각이다.

1. `server/cloudflare`에서 `npm ci` 후 `node node_modules/wrangler/bin/wrangler.js login` 실행. 계정 소유자가 브라우저에서 승인한다.
2. `node node_modules/wrangler/bin/wrangler.js deploy` 실행. 새 API는 비밀값이 없으면 요청을 거부한다.
3. `node upload-secrets.mjs` 실행. 로컬 `.env`의 Claude 키와 초대 코드만 stdin으로 서버 비밀값 저장소에 전달하며 화면에 출력하지 않는다.
4. 배포 도구가 반환한 HTTPS 주소의 `/health`가 `ok: true`인지, 무인증 `/chat`이 401인지, 초대 코드로 가상 질문이 성공하는지 확인한다.
5. 저장소 루트에서 `./flutter.ps1 build apk --debug --dart-define=DTR_CHAT_URL=<배포된 HTTPS 주소>/chat`로 빌드한다.

Cloudflare 무료 플랜 범위로 준비한 설정이다. Claude 사용료는 별도이며 유료 호스팅 플랜으로 자동 변경하지 않는다. 로그 수집은 비활성화한다. 코드/한도 변경 시 동일한 Worker 이름과 Durable Object 바인딩을 유지한다.

Figma 대화 보드: https://www.figma.com/design/SMigmzPpEFzOww1QPpbudr?node-id=70-29 (Primary 계정 저장 완료).

## 현재 배포 (2026-11-18)

- Cloudflare 계정: 사용자 로그인으로 확인한 imjunse040205@gmail.com 계정.
- HTTPS API: `https://dontori-chat-beta.promotion-report-worker.workers.dev/chat`
- 상태 확인: `https://dontori-chat-beta.promotion-report-worker.workers.dev/health`
- 모델: `claude-haiku-5-5`. API 키와 초대 코드는 Cloudflare secret으로 등록했다.
- 공개 HTTPS 검사: health 200/ok, 무인증 chat 401, 초대 코드 및 가상 예산을 사용한 Claude 응답 200 확인.
- 앱 빌드: `./flutter.ps1 build apk --debug --build-number=2 --build-name=1.0.0-beta.2 --dart-define=DTR_CHAT_URL=https://dontori-chat-beta.promotion-report-worker.workers.dev/chat`
- 현재 초대 코드는 소유자 폰 테스트용 1개다. 베타테스터에게 배포할 때는 테스터별 코드를 추가하고 `upload-secrets.mjs`로 갱신한다. 같은 코드를 공유하면 1일 10회 한도도 공유된다.
- 선택 동의 기반 사용 분석과 관리자 대시보드를 구현했다. 설정은 [BETA_MEASUREMENT.md](BETA_MEASUREMENT.md)를 참조한다. AI 호출 한도와 사용 분석 저장소는 분리되어 있다.


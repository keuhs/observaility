# 🚨 게임 서비스 인시던트 대응 플레이북

## 개요
이 플레이북은 모바일 게임 서비스에서 발생하는 모든 인시던트에 대한 표준화된 대응 절차를 정의합니다.

## 🚨 인시던트 발생 시 즉시 행동

### 1단계: 인시던트 선언 (0-5분)

#### 인시던트 감지
- [ ] **자동 감지**: Prometheus 알람, SLO 위반 감지
- [ ] **수동 감지**: 사용자 리포트, 팀원 발견, 고객 지원팀 연락
- [ ] **상황 파악**: 영향 범위, 사용자 수, 비즈니스 영향 평가

#### 인시던트 선언
```bash
# 인시던트 채널에 즉시 선언
/invite @game-sre-oncall @game-ops-lead @game-dev-lead

🚨 INCIDENT DECLARED 🚨
서비스: {{서비스명}}
심각도: {{Sev0/1/2/3}}
영향: {{영향 범위}}
발견자: {{@사용자명}}
```

#### 초기 대응팀 구성
- [ ] **Incident Commander (IC)** 선임
- [ ] **Operations Lead** 선임
- [ ] **Communications Lead** 선임
- [ ] **Scribe** 선임
- [ ] **필요시 Liaison** 선임

### 2단계: 초기 상황 파악 (5-15분)

#### 기술적 상황 파악
```bash
# 게임 서비스 상태 확인
kubectl get pods -n game-production
kubectl get svc -n game-production
kubectl get ingress -n game-production

# 메트릭 확인
curl -s "http://prometheus:9090/api/v1/query?query=up{service=~\"game-server|matchmaking|game-persistence\"}"
curl -s "http://prometheus:9090/api/v1/query?query=game_requests_total{service=\"game-server\"}"

# 로그 확인
kubectl logs -n game-production -l app=game-server --tail=100
kubectl logs -n game-production -l app=matchmaking --tail=100
```

#### 비즈니스 영향 평가
- [ ] **영향 받는 사용자 수** 추정
- [ ] **수익 영향** 추정
- [ ] **브랜드 평판 영향** 평가
- [ ] **규제 준수 영향** 확인

#### 스테이크홀더 통지
```bash
# 내부 팀 통지
/invite @cto @product-lead @marketing-lead

# 고객 지원팀 통지
/invite @customer-support-lead @customer-success-lead
```

### 3단계: 인시던트 분류 및 우선순위 결정 (15-30분)

#### 심각도 재평가
| 심각도 | 기준 | 대응 시간 | 에스컬레이션 |
|--------|------|-----------|--------------|
| **Sev0** | 전면 중단 | 즉시 | CTO 즉시 |
| **Sev1** | 핵심 기능 장애 | 5분 내 | 팀 리드 5분 내 |
| **Sev2** | 부분 기능 장애 | 15분 내 | 팀 리드 30분 내 |
| **Sev3** | 성능 저하 | 30분 내 | 팀 리드 1시간 내 |

#### 인시던트 분류
- [ ] **카테고리**: Infrastructure, Application, Deployment, Security, Performance
- [ ] **태그**: game-server, matchmaking, data-persistence, payment 등
- [ ] **영향 범위**: 사용자 수, 지역, 기능별 영향

#### 우선순위 결정
```bash
# 우선순위 매트릭스
우선순위 = (심각도 × 비즈니스 영향 × 사용자 영향) / 기술적 복잡도

# 예시
Sev0 + 전체 사용자 영향 + 결제 시스템 = 최우선
Sev1 + 부분 사용자 영향 + 게임 매칭 = 고우선
Sev2 + 일부 사용자 영향 + 리더보드 = 중우선
```

## 🔧 인시던트 대응 실행

### Operations Lead 실행 계획

#### 1. 문제 진단 (30분-1시간)
```bash
# 시스템 상태 점검
kubectl describe pods -n game-production
kubectl get events -n game-production --sort-by='.lastTimestamp'
kubectl top pods -n game-production

# 네트워크 연결 확인
kubectl exec -it <pod-name> -- nslookup game-server
kubectl exec -it <pod-name> -- curl -v http://game-server:8080/health

# 데이터베이스 연결 확인
kubectl exec -it <pod-name> -- pg_isready -h game-db
kubectl exec -it <pod-name> -- redis-cli -h game-redis ping
```

#### 2. 복구 작업 실행 (1-2시간)
```bash
# 서비스 재시작
kubectl rollout restart deployment/game-server -n game-production
kubectl rollout status deployment/game-server -n game-production

# 스케일링 조정
kubectl scale deployment/game-server -n game-production --replicas=5

# 설정 업데이트
kubectl patch configmap/game-server-config -n game-production -p '{"data":{"max_connections":"10000"}}'

# 롤백 (필요시)
kubectl rollout undo deployment/game-server -n game-production
```

#### 3. 복구 검증 (2-3시간)
```bash
# 헬스체크 확인
curl -s "http://game-server:8080/health"
curl -s "http://matchmaking:8080/health"

# 메트릭 확인
curl -s "http://prometheus:9090/api/v1/query?query=up{service=\"game-server\"}"
curl -s "http://prometheus:9090/api/v1/query?query=rate(game_requests_total{service=\"game-server\"}[5m])"

# 사용자 경험 테스트
# - 게임 로그인 테스트
# - 게임 매칭 테스트
# - 게임 데이터 저장 테스트
```

### Communications Lead 실행 계획

#### 1. 내부 커뮤니케이션
```bash
# 상태 업데이트 (15분마다)
🔄 [UPDATE] {{서비스명}} 인시던트 진행상황

**현재 상황**: {{상황 설명}}
**영향 범위**: {{영향 받는 사용자/기능}}
**진행상황**: {{진행된 작업}}
**예상 해결시간**: {{ETA}}
**다음 업데이트**: {{시간}}

#팀업데이트 #인시던트
```

#### 2. 외부 커뮤니케이션
```bash
# 상태페이지 업데이트
https://status.game-service.com/incidents/{{incident-id}}

# 고객 지원팀 통지
📧 고객 지원팀 통지

**인시던트**: {{서비스명}} {{심각도}}
**상황**: {{상황 설명}}
**영향**: {{영향 범위}}
**예상 해결시간**: {{ETA}}
**고객 문의 대응 가이드**: {{링크}}

#고객지원 #인시던트
```

#### 3. 매체/소셜미디어 대응
```bash
# 공식 발표문 (필요시)
📢 공식 발표문

**제목**: {{서비스명}} 일시적 서비스 장애 발생
**내용**: {{상황 설명 및 사과}}
**영향**: {{영향 범위}}
**해결 조치**: {{진행 중인 조치}}
**문의**: {{연락처}}

#공식발표 #서비스장애
```

### Scribe 실행 계획

#### 1. 타임라인 기록
```markdown
# 인시던트 타임라인

## 인시던트 정보
- **ID**: INC-2024-001
- **서비스**: Game Server
- **심각도**: Sev1
- **발생 시간**: 2024-01-15 14:30 KST
- **해결 시간**: 2024-01-15 15:45 KST
- **지속 시간**: 1시간 15분

## 타임라인
| 시간 | 활동 | 담당자 | 세부사항 |
|------|------|--------|----------|
| 14:30 | 인시던트 감지 | @user1 | Prometheus 알람 발생 |
| 14:31 | 인시던트 선언 | @ic | Slack 채널에 선언 |
| 14:32 | 대응팀 구성 | @ic | IC, Ops, Comms, Scribe 선임 |
| 14:35 | 초기 상황 파악 | @ops | 시스템 상태 점검 |
| 14:40 | 문제 진단 | @ops | 로그 분석 및 원인 파악 |
| 14:50 | 복구 작업 시작 | @ops | 서비스 재시작 |
| 15:00 | 복구 검증 | @ops | 헬스체크 및 테스트 |
| 15:15 | 서비스 복구 | @ops | 정상 동작 확인 |
| 15:30 | 사용자 테스트 | @ops | 실제 사용자 시나리오 테스트 |
| 15:45 | 인시던트 해결 | @ic | 팀 해산 및 정리 |
```

#### 2. 증거 수집
- [ ] **로그 파일**: 게임 서버, 매칭, 데이터베이스 로그
- [ ] **메트릭 데이터**: Prometheus 쿼리 결과, Grafana 스크린샷
- [ ] **설정 파일**: 배포 시점의 설정, 환경 변수
- [ ] **변경 이력**: 최근 배포, 설정 변경, 인프라 변경
- [ ] **사용자 리포트**: 고객 지원팀 티켓, 사용자 피드백

#### 3. 결정사항 기록
```markdown
# 주요 결정사항

## 기술적 결정
- **문제 원인**: {{원인 설명}}
- **해결 방법**: {{해결 방법}}
- **대안 검토**: {{검토한 대안들}}
- **선택 이유**: {{선택한 이유}}

## 운영적 결정
- **에스컬레이션**: {{에스컬레이션 여부 및 이유}}
- **고객 통지**: {{통지 내용 및 시점}}
- **서비스 중단**: {{중단 여부 및 기간}}
- **롤백 결정**: {{롤백 여부 및 이유}}
```

## 🚨 에스컬레이션 절차

### 자동 에스컬레이션
```bash
# Sev0: 즉시 CTO 통지
/invite @cto @all-team-leads
🚨 CRITICAL ESCALATION 🚨
Sev0 인시던트 발생 - 즉시 대응 필요

# Sev1: 15분 미해결 시 팀 리드 통지
/invite @game-sre-lead @game-dev-lead @game-ops-lead
⚠️ ESCALATION REQUIRED ⚠️
Sev1 인시던트 15분 미해결 - 팀 리드 개입 필요
```

### 수동 에스컬레이션
```bash
# 기술적 한계 도달
/invite @external-vendor @cloud-support
🔧 EXTERNAL SUPPORT REQUIRED 🔧
기술적 한계 도달 - 외부 지원 요청

# 비즈니스 영향 확대
/invite @cto @product-lead @marketing-lead
💼 BUSINESS ESCALATION 💼
비즈니스 영향 확대 - 경영진 의사결정 필요
```

## ✅ 인시던트 해결 및 정리

### 해결 조건 확인
- [ ] **기술적 해결**: 서비스 정상 동작 확인
- [ ] **사용자 경험**: 실제 사용자 시나리오 테스트 완료
- [ ] **모니터링**: 모든 메트릭 정상 범위 내
- [ ] **알람 해제**: 관련 알람 모두 해제
- [ ] **스테이크홀더 통지**: 해결 완료 통지

### 인시던트 해산
```bash
✅ INCIDENT RESOLVED ✅

**서비스**: {{서비스명}}
**해결 시간**: {{해결 시간}}
**지속 시간**: {{지속 시간}}
**해결 방법**: {{해결 방법}}
**영향 범위**: {{영향 받은 사용자/기능}}

팀 해산 및 포스트모템 준비 시작
#인시던트해결 #포스트모템
```

### 사후 조치 계획
- [ ] **포스트모템**: 48시간 내 진행
- [ ] **액션 아이템**: 개선사항 및 재발 방지 계획
- [ ] **문서화**: 인시던트 보고서 작성
- [ ] **훈련**: 교훈 반영 훈련 계획
- [ ] **모니터링**: 추가 모니터링 및 알람 설정

## 📊 인시던트 메트릭 추적

### 주요 KPI
```bash
# MTTD (Mean Time To Detection)
MTTD = (인시던트 발생 시간 - 인시던트 감지 시간) / 인시던트 수

# MTTR (Mean Time To Resolution)
MTTR = (인시던트 감지 시간 - 인시던트 해결 시간) / 인시던트 수

# MTBF (Mean Time Between Failures)
MTBF = (마지막 인시던트 해결 시간 - 이전 인시던트 해결 시간) / (인시던트 수 - 1)
```

### 목표 및 현황
| 메트릭 | 목표 | 현재 | 개선 계획 |
|--------|------|------|-----------|
| MTTD | Sev0: 1분, Sev1: 5분 | {{현재값}} | {{계획}} |
| MTTR | Sev0: 15분, Sev1: 30분 | {{현재값}} | {{계획}} |
| MTBF | 월 1회 미만 | {{현재값}} | {{계획}} |
| 재발률 | 10% 미만 | {{현재값}} | {{계획}} |

## 🔄 지속적 개선

### 주간 리뷰
- [ ] **인시던트 통계**: 빈도, 지속시간, 유형별 분석
- [ ] **대응 과정**: 절차 준수도, 개선점 식별
- [ ] **도구 및 자동화**: 효율성 개선 방안 검토
- [ ] **팀 역량**: 교육 필요사항 및 훈련 계획

### 월간 리뷰
- [ ] **트렌드 분석**: 인시던트 패턴 및 원인 분석
- [ ] **정책 검토**: 인시던트 관리 정책 개정 필요사항
- [ ] **예산 및 리소스**: 인시던트 대응 비용 및 리소스 할당
- [ ] **벤치마킹**: 업계 모범사례 및 개선 방안

### 분기별 훈련
- [ ] **테이블톱 연습**: 시나리오 기반 인시던트 대응 훈련
- [ ] **실제 시스템 시뮬레이션**: 실제 환경에서의 대응 훈련
- [ ] **역할극**: 다양한 역할별 대응 훈련
- [ ] **성과 평가**: 훈련 결과 및 개선점 평가

## 📞 연락처 및 참고 자료

### 핵심 연락처
- **SRE 온콜**: @game-sre-oncall
- **팀 리드**: @game-sre-lead
- **CTO**: @cto
- **고객 지원**: @customer-support-lead

### 유용한 링크
- **게임 서비스 대시보드**: https://grafana.game-sre.com
- **상태페이지**: https://status.game-service.com
- **인시던트 관리 시스템**: https://incidents.game-sre.com
- **런북**: https://runbooks.game-sre.com

### 참고 문서
- **인시던트 관리 정책**: `incident-management-policy.yaml`
- **게임 서버 런북**: `runbooks/game-server-availability.md`
- **SLO 정의**: `sli-slo/game-service-slo.yaml`
- **모니터링 설정**: `monitoring/prometheus-values.yaml`

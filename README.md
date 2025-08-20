# Observaility - 모바일 게임 서비스 SRE 체계

모바일 게임 서비스의 신뢰성, 가용성, 성능을 체계적으로 향상시키는 SRE(Site Reliability Engineering) 프로젝트입니다.

## 🎯 핵심 목표

- **SLI/SLO 기반 운영**: 사용자 경험을 대표하는 지표 정의 및 목표 관리
- **관찰 가능성**: 메트릭, 로그, 트레이스 통합 스택으로 시스템 가시성 확보
- **인시던트 대응**: 빠른 감지, 신속 복구, 학습을 통한 지속적 개선
- **안전한 배포**: SLO 기반 가드레일과 자동 롤백으로 변경 위험 최소화
- **회복탄력성**: 카오스 엔지니어링을 통한 장애 대응 능력 향상
- **자동화**: CI/CD 파이프라인과 운영 자동화로 인적 오류 최소화

## 🏗️ 프로젝트 구조

```
├── sli-slo/                    # SLI/SLO 정의 및 정책
├── monitoring/                  # 모니터링 스택 구성
├── dashboards/                  # Grafana 대시보드
├── alerting/                   # 알람 규칙 및 정책
├── runbooks/                   # 운영 절차서
├── chaos-engineering/          # 카오스 엔지니어링 및 회복탄력성
├── deployment/                 # 안전한 배포 파이프라인
├── incident-response/          # 인시던트 대응 체계
├── docs/                       # 문서 및 가이드
└── scripts/                    # 자동화 스크립트
```

## 🚀 빠른 시작

### 1. 전체 SRE 체계 설치
```bash
# 전체 SRE 체계 자동 설치
./scripts/install-all.sh

# 또는 단계별 설치
./scripts/install-monitoring.sh
./scripts/install-chaos-engineering.sh
./scripts/install-deployment-pipeline.sh
```

### 2. 개별 구성 요소 설치
```bash
# SLI/SLO 설정
kubectl apply -f sli-slo/game-service-slo.yaml

# 모니터링 스택
helm install game-monitoring ./monitoring \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/values.yaml

# 카오스 엔지니어링
kubectl apply -f chaos-engineering/k8s/litmus-chaos-install.yaml

# 배포 파이프라인
kubectl apply -f deployment/k8s/production/rollout.yaml
```

## 📊 핵심 SLI

- **가용성**: 게임 서버 응답 성공률 (99.9%)
- **지연시간**: 게임 액션 응답 속도 (p95 < 500ms)
- **오류율**: 게임 플레이 중 오류 발생률 (< 0.1%)
- **동시 접속자**: 동시 게임 세션 수 (최대 100,000)
- **매칭 성공률**: 게임 매칭 시스템 성공률 (95%)
- **데이터 저장 성공률**: 게임 데이터 저장 성공률 (99.99%)

## 🖥️ 모니터링 대시보드

### 1. 게임 서비스 개요 대시보드 (`dashboards/game-service-overview.json`)
- 🎮 게임 서비스 전체 상태 모니터링
- 📊 요청율, 응답시간, 오류율 실시간 추적
- 👥 동시 접속자 수 및 게임 세션 현황
- 🎯 매칭 성공률 및 데이터 저장 성공률
- 🔥 SLO 에러 버짓 소진률 추적
- 🚨 활성 알람 현황

### 2. 게임 서버 SLO 대시보드 (`dashboards/game-server-slo.json`)
- 🎯 게임 서버 가용성 SLO 실시간 모니터링
- 🔥 에러 버짓 소진률 및 남은 버짓 추적
- 📊 월간 SLO 진행률 및 24시간 트렌드
- ❌ 오류 유형별 발생률 분석
- ⚡ 응답시간 분포 히트맵
- 🔄 상태코드별 요청율 분석
- 👥 인스턴스별 활성 세션 수

### 3. 매칭 서비스 SLO 대시보드 (`dashboards/matchmaking-slo.json`)
- 🎯 매칭 성공률 SLO 실시간 모니터링
- 🔥 에러 버짓 소진률 추적
- ⏱️ 평균 매칭 시간 및 분포
- 👥 활성 매칭 큐 크기
- 📈 성공률 트렌드 및 오류 버짓 소진 트렌드
- 🎮 매칭 유형별 요청율
- 🏆 플레이어 스킬 레벨별 성공률
- 📊 매칭 유형별 큐 크기

### 4. 인프라 모니터링 대시보드 (`dashboards/game-infrastructure.json`)
- 🖥️ 노드 리소스 사용률 (CPU, 메모리)
- 📊 파드별 CPU/메모리 사용량
- 🌐 네트워크 I/O 및 디스크 I/O
- 📦 파드 상태 및 서비스 엔드포인트
- 📊 리소스 쿼터 현황
- 🚨 인프라 관련 알람 현황

## 🔧 모니터링 스택 구성

### Prometheus 설정 (`monitoring/prometheus-values.yaml`)
- 게임 서비스 특화 스크랩 설정
- 게임 피크 시간대 고려한 리소스 할당
- 게임 서비스별 메트릭 수집 간격 최적화
- 한국 시간대 설정 (Asia/Seoul)

### 알람 규칙 (`monitoring/prometheus-rules.yaml`)
- **SLO 규칙**: 에러 버짓 소진률 계산
- **메트릭 규칙**: 응답시간 분위수, 요청율, 오류율
- **알람 규칙**: 고부하, 응답시간 지연, 큐 크기 증가
- **인프라 규칙**: 노드 리소스, 파드 상태, 서비스 엔드포인트

### Grafana 설정 (`monitoring/grafana-dashboard-provider.yaml`)
- 게임 서비스 전용 대시보드 프로바이더
- 자동 대시보드 로딩 및 폴더 구성
- 한국 시간대 및 다크 테마 기본 설정

## 🧪 카오스 엔지니어링 및 회복탄력성

### 카오스 엔지니어링 정책 (`chaos-engineering/chaos-engineering-policy.yaml`)
- **목표**: 시스템 회복탄력성 검증 및 장애 대응 능력 향상
- **원칙**: 안전성 우선, 점진적 접근, 학습 중심, 자동화 우선
- **시나리오**: 인프라, 애플리케이션, 외부 의존성 장애 시뮬레이션

### 회복탄력성 프레임워크 (`chaos-engineering/resilience-framework.md`)
- **Circuit Breaker**: 장애 전파 방지 및 자동 복구
- **Retry Pattern**: 일시적 장애에 대한 재시도 메커니즘
- **Fallback Strategy**: 장애 시 대체 서비스 제공
- **Timeout Management**: 응답 지연 시 자동 중단
- **Rate Limiting**: 과부하 방지 및 안정성 보장

### 카오스 실험 (`chaos-engineering/chaos-experiments/`)
- **Pod 장애**: Pod 삭제, CPU/메모리 고갈
- **네트워크 장애**: 지연, 손실, 분할
- **리소스 고갈**: CPU, 메모리, 디스크 공간 부족
- **데이터베이스 장애**: 연결 실패, 쿼리 지연

## 🚀 안전한 배포 파이프라인

### 배포 정책 (`deployment/deployment-pipeline-policy.yaml`)
- **SLO 기반 가드레일**: 모든 배포는 SLO 지표로 검증
- **자동 롤백**: 문제 발생 시 즉시 이전 버전으로 복구
- **배포 전략**: Blue-Green, Canary, Rolling Update
- **승인 워크플로우**: 기술적, 보안, 비즈니스 검토

### CI/CD 파이프라인 (`deployment/.github/workflows/game-service-deploy.yml`)
- **코드 품질**: Linting, 보안 스캔, 테스트 자동화
- **단계별 배포**: Development → Staging → Production
- **자동 검증**: SLO 확인, 성능 테스트, 사용자 경험 테스트
- **롤백 준비**: 배포 상태 저장 및 복구 계획

### ArgoCD 배포 (`deployment/k8s/production/rollout.yaml`)
- **Blue-Green 배포**: 게임 서버 무중단 배포
- **Canary 배포**: 매칭 서비스 점진적 배포
- **SLO 기반 승인**: Prometheus 메트릭 기반 자동 승인
- **자동 롤백**: SLO 위반 시 즉시 롤백

## 🚨 인시던트 대응 체계

### 인시던트 관리 정책 (`incident-response/incident-management-policy.yaml`)
- **심각도 체계**: Sev0(전면 중단) ~ Sev3(성능 저하)
- **대응 역할**: IC, Operations Lead, Communications Lead, Scribe
- **에스컬레이션**: 자동/수동 에스컬레이션 정책

### 온콜 및 에스컬레이션 (`incident-response/oncall-escalation-policy.yaml`)
- **4단계 온콜**: Primary → Secondary → Tertiary → Executive
- **자동 에스컬레이션**: 시간 기반 및 조건 기반 에스컬레이션
- **24/7 운영**: 주간 로테이션 및 백업 체계

### 인시던트 대응 플레이북 (`incident-response/incident-response-playbook.md`)
- **즉시 행동**: 인시던트 선언 및 팀 구성
- **상황 파악**: 기술적 영향 및 비즈니스 영향 평가
- **실행 계획**: 역할별 상세 실행 절차
- **에스컬레이션**: 단계별 에스컬레이션 절차

### 포스트모템 템플릿 (`incident-response/postmortem-template.md`)
- **근본 원인 분석**: 5 Why 분석 및 시스템적 원인 파악
- **학습 및 개선**: 개선 계획 및 재발 방지 대책
- **지속적 개선**: 정기적인 리뷰 및 정책 업데이트

## 📈 SLO 기반 운영

### 에러 버짓 정책
- **빠른 소진 (1시간)**: 14.4x 버닝 레이트로 즉시 대응
- **느린 소진 (6시간)**: 6x 버닝 레이트로 경고 알림
- **배포 일시중지**: 에러 버짓 50% 소진 시
- **자동 롤백**: 에러 버짓 80% 소진 시

### 게임 특화 운영 정책
- **피크 시간대**: 저녁 18:00-22:00 SLO 강화 (1.2x)
- **이벤트 기간**: 공휴일/이벤트 기간 자동 스케일링
- **정기 점검**: 화요일 새벽 02:00-06:00 SLO 면제

## 🚨 알림 및 에스컬레이션

### 알림 채널
- **Slack**: 게임 SRE 온콜, 게임 서버, 매칭 서비스별 채널
- **PagerDuty**: Critical 알람 에스컬레이션
- **상태페이지**: 고객 공지 및 서비스 상태 업데이트

### 에스컬레이션 정책
- **Critical**: 즉시 PagerDuty + Slack 동시 알림
- **Warning**: Slack 채널별 알림
- **에스컬레이션**: 30분 미해결 시 팀 리드, 1시간 미해결 시 CTO

## 📚 운영 문서

### 런북 (`runbooks/game-server-availability.md`)
- 게임 서버 가용성 문제 대응 절차
- 단계별 문제 진단 및 해결 방법
- 에스컬레이션 및 사후 조치 가이드

### 배포 가이드 (`docs/deployment-guide.md`)
- 단계별 모니터링 스택 배포 방법
- 설정 검증 및 문제 해결 가이드
- 운영 체크리스트 및 백업/복구 방법

## 🚀 배포 방법

### 1. 전체 SRE 체계 자동 설치
```bash
# 전체 SRE 체계 자동 설치
./scripts/install-all.sh
```

### 2. 개별 구성 요소 설치
```bash
# 모니터링 스택
helm install game-monitoring ./monitoring \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/values.yaml

# 카오스 엔지니어링
kubectl apply -f chaos-engineering/k8s/litmus-chaos-install.yaml

# 배포 파이프라인
kubectl apply -f deployment/k8s/production/rollout.yaml
```

### 3. 접속 정보
- **Grafana**: http://localhost:3000 (admin / game-sre-admin-2024!)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **ArgoCD**: http://localhost:8080 (admin / admin)

## 🔍 모니터링 체크리스트

### 일일 체크
- [ ] 게임 서비스 가용성 확인
- [ ] 에러 버짓 소진률 확인
- [ ] 알람 발생 현황 확인
- [ ] 대시보드 데이터 정상성 확인
- [ ] 카오스 실험 상태 확인
- [ ] 배포 파이프라인 상태 확인

### 주간 체크
- [ ] SLO 달성률 분석
- [ ] 에러 버짓 소모 패턴 분석
- [ ] 알람 임계치 조정 검토
- [ ] 대시보드 개선사항 검토
- [ ] 카오스 실험 결과 분석
- [ ] 배포 성공률 및 롤백 빈도 분석

### 월간 체크
- [ ] SLO 목표 재검토
- [ ] 에러 버짓 정책 조정
- [ ] 모니터링 스택 업그레이드
- [ ] 팀 교육 및 문서 업데이트
- [ ] 회복탄력성 개선 계획 수립
- [ ] 배포 파이프라인 최적화

## 🤝 기여 방법

1. 이슈 생성: 모니터링 개선사항이나 버그 리포트
2. PR 제출: 대시보드 개선, 알람 규칙 추가, 문서 업데이트
3. 코드 리뷰: 팀원 간 코드 품질 검토 및 피드백

## 📞 연락처

- **SRE 팀**: game-sre@company.com
- **온콜**: game-sre-oncall@company.com
- **에스컬레이션**: game-sre-lead@company.com

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
# 🎮 Game Server Availability Runbook

## 개요
게임 서버 가용성 SLO 위반 시 대응 절차서입니다.

## 사전 조건
- [ ] SRE 온콜 권한 확인
- [ ] 게임 서비스 대시보드 접근 권한
- [ ] 게임 서버 로그 접근 권한
- [ ] 게임 서비스 배포 권한

## 체크리스트

### 1. 초기 상황 파악
- [ ] SLO 대시보드에서 현재 가용성 확인
- [ ] 에러 버짓 소진률 확인
- [ ] 영향 받는 서비스/인스턴스 식별
- [ ] 사용자 영향 범위 파악

### 2. 최근 변경사항 확인
- [ ] 최근 배포 이력 확인
- [ ] 설정 변경 이력 확인
- [ ] 인프라 변경 이력 확인
- [ ] 피처 플래그 상태 확인

### 3. 시스템 상태 점검
- [ ] 게임 서버 헬스체크 상태
- [ ] 데이터베이스 연결 상태
- [ ] 네트워크 연결 상태
- [ ] 리소스 사용률 (CPU, 메모리, 디스크)

## 완화 절차

### 단계 1: 즉시 대응 (5분 이내)
```bash
# 게임 서버 상태 확인
kubectl get pods -n game-production -l app=game-server
kubectl describe pods -n game-production -l app=game-server

# 게임 서버 로그 확인
kubectl logs -n game-production -l app=game-server --tail=100

# 게임 서버 메트릭 확인
curl -s "http://prometheus:9090/api/v1/query?query=up{service=\"game-server\"}"
```

### 단계 2: 문제 진단 (15분 이내)
```bash
# 게임 서버 상세 상태 확인
kubectl exec -n game-production -it $(kubectl get pod -n game-production -l app=game-server -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

# 게임 서버 내부 상태 확인
curl -s "http://localhost:8080/health"
curl -s "http://localhost:8080/metrics" | grep -E "(game_requests_total|game_errors_total)"

# 네트워크 연결 확인
netstat -tulpn | grep :8080
ss -tulpn | grep :8080
```

### 단계 3: 문제 해결 (30분 이내)

#### 3.1 게임 서버 재시작
```bash
# 게임 서버 재시작
kubectl rollout restart deployment/game-server -n game-production

# 롤아웃 상태 확인
kubectl rollout status deployment/game-server -n game-production

# 새 파드 상태 확인
kubectl get pods -n game-production -l app=game-server
```

#### 3.2 스케일링 조정
```bash
# 게임 서버 레플리카 수 증가
kubectl scale deployment/game-server -n game-production --replicas=5

# 스케일링 상태 확인
kubectl get deployment/game-server -n game-production
```

#### 3.3 설정 업데이트
```bash
# 게임 서버 설정 확인
kubectl get configmap/game-server-config -n game-production -o yaml

# 설정 업데이트 (필요시)
kubectl patch configmap/game-server-config -n game-production -p '{"data":{"max_connections":"10000"}}'
```

### 단계 4: 복구 확인 (45분 이내)
```bash
# 게임 서버 가용성 확인
curl -s "http://prometheus:9090/api/v1/query?query=sum(rate(game_requests_total{service=\"game-server\", status_code!~\"5..|4..\"}[5m])) / sum(rate(game_requests_total{service=\"game-server\"}[5m]))"

# 에러율 확인
curl -s "http://prometheus:9090/api/v1/query?query=sum(rate(game_errors_total{service=\"game-server\"}[5m])) / sum(rate(game_requests_total{service=\"game-server\"}[5m]))"

# 응답 시간 확인
curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95, sum(rate(game_action_duration_seconds_bucket{service=\"game-server\"}[5m])) by (le))"
```

## 검증

### 복구 확인 지표
- [ ] 게임 서버 가용성 > 99.9%
- [ ] 에러율 < 0.1%
- [ ] p95 응답 시간 < 500ms
- [ ] 에러 버짓 소진률 < 1.0

### 사용자 경험 확인
- [ ] 게임 로그인 성공
- [ ] 게임 플레이 정상 동작
- [ ] 게임 데이터 저장 성공
- [ ] 게임 매칭 정상 동작

## 에스컬레이션

### 30분 이내 해결되지 않은 경우
- [ ] 게임 개발팀 리드에게 연락
- [ ] 인프라팀 리드에게 연락
- [ ] 제품 관리팀에게 상황 보고

### 1시간 이내 해결되지 않은 경우
- [ ] CTO/기술 이사에게 에스컬레이션
- [ ] 고객 지원팀에 공지
- [ ] 상태페이지 업데이트

## 사후 조치

### 1. 인시던트 문서화
- [ ] 타임라인 작성
- [ ] 근본 원인 분석
- [ ] 교훈 및 개선점 정리
- [ ] 액션 아이템 추적

### 2. 재발 방지
- [ ] 모니터링 강화
- [ ] 알람 임계치 조정
- [ ] 자동화 스크립트 개선
- [ ] 문서 업데이트

### 3. 팀 학습
- [ ] 블레임리스 포스트모템 진행
- [ ] 팀 전체 공유
- [ ] 운영 절차 개선
- [ ] 교육 자료 업데이트

## 연락처

### 온콜 팀
- **주요 담당자**: game-sre-oncall@company.com
- **백업 담당자**: game-sre-backup@company.com
- **에스컬레이션**: game-sre-lead@company.com

### 게임 개발팀
- **팀 리드**: game-dev-lead@company.com
- **백엔드 개발자**: game-backend@company.com

### 인프라팀
- **팀 리드**: infra-lead@company.com
- **네트워크 엔지니어**: network@company.com

## 유용한 링크

- **게임 서비스 대시보드**: https://grafana.game-sre.com/d/game-service-overview
- **게임 서버 SLO 대시보드**: https://grafana.game-sre.com/d/game-server-slo
- **게임 서비스 로그**: https://logs.game-sre.com
- **게임 서비스 메트릭**: https://prometheus.game-sre.com
- **게임 서비스 문서**: https://docs.game-sre.com

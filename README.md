# Observaility - 모바일 게임 서비스 SRE 체계

모바일 게임 서비스의 신뢰성, 가용성, 성능을 체계적으로 향상시키는 SRE(Site Reliability Engineering) 프로젝트입니다.

## 🎯 핵심 목표

- **SLI/SLO 기반 운영**: 사용자 경험을 대표하는 지표 정의 및 목표 관리
- **관찰 가능성**: 메트릭, 로그, 트레이스 통합 스택으로 시스템 가시성 확보
- **인시던트 대응**: 빠른 감지, 신속 복구, 학습을 통한 지속적 개선
- **안전한 배포**: SLO 기반 가드레일과 자동 롤백으로 변경 위험 최소화

## 🏗️ 프로젝트 구조

```
├── sli-slo/           # SLI/SLO 정의 및 정책
├── monitoring/         # 모니터링 스택 구성
├── dashboards/         # Grafana 대시보드
├── alerting/          # 알람 규칙 및 정책
├── runbooks/          # 운영 절차서
├── chaos/             # 카오스 엔지니어링
└── docs/              # 문서 및 가이드
```

## 🚀 빠른 시작

1. SLI/SLO 정의: `sli-slo/game-service-slo.yaml`
2. 모니터링 설정: `monitoring/prometheus-values.yaml`
3. 대시보드: `dashboards/game-service-overview.json`
4. 알람 규칙: `alerting/slo-burn-rates.yaml`

## 📊 핵심 SLI

- **가용성**: 게임 서버 응답 성공률
- **지연시간**: 게임 액션 응답 속도
- **오류율**: 게임 플레이 중 오류 발생률
- **동시 접속자**: 동시 게임 세션 수
- **매칭 성공률**: 게임 매칭 시스템 성공률
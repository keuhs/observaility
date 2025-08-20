# 🚀 모바일 게임 서비스 SRE 체계 배포 가이드

## 개요
이 가이드는 모바일 게임 서비스 SRE 체계를 단계별로 배포하는 방법을 설명합니다.

## 사전 요구사항

### 1. 인프라 환경
- [ ] Kubernetes 클러스터 (v1.24+)
- [ ] Helm 3.8+
- [ ] kubectl 설정 완료
- [ ] 스토리지 클래스 설정 (fast-ssd)
- [ ] 인그레스 컨트롤러 설정

### 2. 도구 설치
```bash
# Helm 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Prometheus Operator 설치
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 3. 네임스페이스 생성
```bash
kubectl create namespace monitoring
kubectl create namespace game-production
kubectl create namespace game-sre
```

## 단계별 배포

### 단계 1: Prometheus Operator 설치

```bash
# Prometheus Operator 설치
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus-values.yaml

# 설치 상태 확인
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 단계 2: 게임 서비스 메트릭 수집기 설정

```bash
# 게임 서비스 메트릭 수집기 배포
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: game-metrics-exporter
  namespace: game-production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: game-metrics-exporter
  template:
    metadata:
      labels:
        app: game-metrics-exporter
    spec:
      containers:
      - name: metrics-exporter
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: game-metrics-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: game-metrics-config
  namespace: game-production
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'game-server'
      static_configs:
      - targets: ['game-server:8080']
    - job_name: 'matchmaking'
      static_configs:
      - targets: ['matchmaking:8080']
    - job_name: 'game-persistence'
      static_configs:
      - targets: ['game-persistence:8080']
EOF
```

### 단계 3: SLO 알람 규칙 적용

```bash
# SLO 알람 규칙 ConfigMap 생성
kubectl create configmap slo-alerts \
  --from-file=alerting/slo-burn-rates.yaml \
  -n monitoring

# Prometheus 규칙 업데이트
kubectl patch prometheusrule slo-error-budget-burn-rates \
  --patch-file alerting/slo-burn-rates.yaml \
  -n monitoring
```

### 단계 4: Grafana 대시보드 배포

```bash
# 게임 서비스 대시보드 ConfigMap 생성
kubectl create configmap game-service-dashboards \
  --from-file=dashboards/game-service-overview.json \
  -n monitoring

# Grafana 대시보드 프로바이더 설정
kubectl patch deployment grafana \
  --patch-file - <<EOF
spec:
  template:
    spec:
      containers:
      - name: grafana
        volumeMounts:
        - name: game-dashboards
          mountPath: /var/lib/grafana/dashboards/game-service
      volumes:
      - name: game-dashboards
        configMap:
          name: game-service-dashboards
EOF
```

### 단계 5: 게임 서비스 헬스체크 설정

```bash
# 게임 서비스 헬스체크 엔드포인트 설정
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: game-health-check
  namespace: game-production
spec:
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: game-server
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: game-health-check
  namespace: game-production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: health.game-sre.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: game-health-check
            port:
              number: 8080
EOF
```

### 단계 6: 모니터링 스택 검증

```bash
# Prometheus 상태 확인
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring

# Grafana 상태 확인
kubectl port-forward svc/grafana 3000:3000 -n monitoring

# AlertManager 상태 확인
kubectl port-forward svc/alertmanager-operated 9093:9093 -n monitoring
```

## 설정 검증

### 1. 메트릭 수집 확인
```bash
# 게임 서비스 메트릭 확인
curl -s "http://localhost:9090/api/v1/query?query=up{service=\"game-server\"}"

# SLO 메트릭 확인
curl -s "http://localhost:9090/api/v1/query?query=slo:error_budget_burn_rate:game_server_availability"
```

### 2. 알람 규칙 확인
```bash
# 알람 규칙 상태 확인
kubectl get prometheusrule -n monitoring

# 알람 규칙 상세 확인
kubectl describe prometheusrule slo-error-budget-burn-rates -n monitoring
```

### 3. 대시보드 확인
- Grafana 접속: http://localhost:3000
- 기본 계정: admin / game-sre-admin-2024!
- 게임 서비스 폴더에서 대시보드 확인

## 운영 체크리스트

### 일일 체크
- [ ] 게임 서비스 가용성 확인
- [ ] 에러 버짓 소진률 확인
- [ ] 알람 발생 현황 확인
- [ ] 대시보드 데이터 정상성 확인

### 주간 체크
- [ ] SLO 달성률 분석
- [ ] 에러 버짓 소모 패턴 분석
- [ ] 알람 임계치 조정 검토
- [ ] 대시보드 개선사항 검토

### 월간 체크
- [ ] SLO 목표 재검토
- [ ] 에러 버짓 정책 조정
- [ ] 모니터링 스택 업그레이드
- [ ] 팀 교육 및 문서 업데이트

## 문제 해결

### 일반적인 문제

#### 1. 메트릭 수집 안됨
```bash
# 게임 서비스 상태 확인
kubectl get pods -n game-production

# 메트릭 엔드포인트 확인
kubectl exec -it <game-server-pod> -- curl -s http://localhost:8080/metrics

# Prometheus 타겟 상태 확인
curl -s "http://localhost:9090/api/v1/targets"
```

#### 2. 알람이 발생하지 않음
```bash
# 알람 규칙 상태 확인
kubectl get prometheusrule -n monitoring

# AlertManager 설정 확인
kubectl get configmap alertmanager-config -n monitoring -o yaml

# 알람 규칙 테스트
curl -s "http://localhost:9090/api/v1/query?query=ALERTS"
```

#### 3. 대시보드 데이터 없음
```bash
# 데이터 소스 연결 확인
kubectl get configmap grafana-datasources -n monitoring -o yaml

# Prometheus 연결 테스트
curl -s "http://localhost:9090/api/v1/query?query=up"

# 대시보드 설정 확인
kubectl get configmap game-service-dashboards -n monitoring -o yaml
```

## 백업 및 복구

### 설정 백업
```bash
# 현재 설정 백업
kubectl get prometheusrule -n monitoring -o yaml > prometheus-rules-backup.yaml
kubectl get configmap -n monitoring -o yaml > configmaps-backup.yaml
kubectl get deployment -n monitoring -o yaml > deployments-backup.yaml
```

### 설정 복구
```bash
# 설정 복구
kubectl apply -f prometheus-rules-backup.yaml
kubectl apply -f configmaps-backup.yaml
kubectl apply -f deployments-backup.yaml
```

## 보안 고려사항

### 1. 접근 제어
- [ ] RBAC 설정으로 권한 제한
- [ ] 네트워크 정책으로 접근 제한
- [ ] 시크릿 관리로 민감 정보 보호

### 2. 모니터링
- [ ] 보안 이벤트 로깅
- [ ] 접근 로그 모니터링
- [ ] 정기 보안 점검

### 3. 업데이트
- [ ] 정기 보안 패치 적용
- [ ] 취약점 스캔 및 수정
- [ ] 보안 정책 업데이트

## 성능 최적화

### 1. 리소스 최적화
```bash
# 리소스 사용률 모니터링
kubectl top pods -n monitoring
kubectl top nodes

# 리소스 제한 설정
kubectl patch deployment prometheus -p '{"spec":{"template":{"spec":{"containers":[{"name":"prometheus","resources":{"limits":{"memory":"8Gi","cpu":"4"}}}]}}}}' -n monitoring
```

### 2. 스토리지 최적화
```bash
# 스토리지 사용률 확인
kubectl exec -it <prometheus-pod> -- df -h

# 데이터 보존 정책 조정
kubectl patch prometheus prometheus -p '{"spec":{"retention":"15d"}}' -n monitoring
```

## 연락처 및 지원

### 기술 지원
- **SRE 팀**: game-sre@company.com
- **인프라팀**: infra@company.com
- **게임 개발팀**: game-dev@company.com

### 문서 및 리소스
- **SRE 가이드**: https://docs.game-sre.com
- **모니터링 문서**: https://monitoring.game-sre.com
- **게임 서비스 문서**: https://game.game-sre.com

### 온콜 정보
- **주요 담당자**: game-sre-oncall@company.com
- **백업 담당자**: game-sre-backup@company.com
- **에스컬레이션**: game-sre-lead@company.com

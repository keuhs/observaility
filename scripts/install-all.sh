#!/bin/bash

# 모바일 게임 서비스 SRE 체계 전체 설치 스크립트
# 이 스크립트는 모니터링, 카오스 엔지니어링, 배포 파이프라인을 순차적으로 설치합니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info "SRE 체계 설치 시작"
log_info "프로젝트 루트: $PROJECT_ROOT"

# 필수 도구 확인
check_prerequisites() {
    log_info "필수 도구 확인 중..."

    local tools=("kubectl" "helm" "git")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "다음 도구가 설치되지 않았습니다: ${missing_tools[*]}"
        log_error "필수 도구를 설치한 후 다시 시도하세요."
        exit 1
    fi

    log_success "필수 도구 확인 완료"
}

# Kubernetes 연결 확인
check_kubernetes() {
    log_info "Kubernetes 연결 확인 중..."

    if ! kubectl cluster-info &> /dev/null; then
        log_error "Kubernetes 클러스터에 연결할 수 없습니다."
        log_error "kubectl 설정을 확인하고 다시 시도하세요."
        exit 1
    fi

    local context=$(kubectl config current-context)
    log_info "현재 Kubernetes 컨텍스트: $context"
    log_success "Kubernetes 연결 확인 완료"
}

# Helm 저장소 추가
setup_helm_repos() {
    log_info "Helm 저장소 설정 중..."

    # Prometheus Community 저장소
    if ! helm repo list | grep -q "prometheus-community"; then
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        log_info "Prometheus Community 저장소 추가됨"
    fi

    # Grafana 저장소
    if ! helm repo list | grep -q "grafana"; then
        helm repo add grafana https://grafana.github.io/helm-charts
        log_info "Grafana 저장소 추가됨"
    fi

    # Argo 저장소
    if ! helm repo list | grep -q "argo"; then
        helm repo add argo https://argoproj.github.io/argo-helm
        log_info "Argo 저장소 추가됨"
    fi

    helm repo update
    log_success "Helm 저장소 설정 완료"
}

# 네임스페이스 생성
create_namespaces() {
    log_info "필요한 네임스페이스 생성 중..."

    local namespaces=("monitoring" "chaos-engineering" "game-production" "game-staging" "game-development")

    for ns in "${namespaces[@]}"; do
        if ! kubectl get namespace "$ns" &> /dev/null; then
            kubectl create namespace "$ns"
            log_info "네임스페이스 '$ns' 생성됨"
        else
            log_info "네임스페이스 '$ns' 이미 존재함"
        fi

        # 공통 라벨 추가
        kubectl label namespace "$ns" \
            service=game-service \
            team=game-sre \
            environment=${ns#game-} \
            --overwrite
    done

    log_success "네임스페이스 생성 완료"
}

# 모니터링 스택 설치
install_monitoring() {
    log_info "모니터링 스택 설치 중..."

    cd "$PROJECT_ROOT/monitoring"

    # Helm 차트 설치
    if ! helm list -n monitoring | grep -q "game-monitoring"; then
        helm install game-monitoring . \
            --namespace monitoring \
            --create-namespace \
            --values values.yaml \
            --wait \
            --timeout 10m

        log_success "모니터링 스택 설치 완료"
    else
        log_info "모니터링 스택이 이미 설치되어 있음"
    fi

    # Prometheus 규칙 적용
    kubectl apply -f prometheus-rules.yaml -n monitoring

    # Grafana 대시보드 프로바이더 적용
    kubectl apply -f grafana-dashboard-provider.yaml -n monitoring

    cd "$PROJECT_ROOT"
}

# 카오스 엔지니어링 설치
install_chaos_engineering() {
    log_info "카오스 엔지니어링 설치 중..."

    # Litmus Chaos 설치
    kubectl apply -f "$PROJECT_ROOT/chaos-engineering/k8s/litmus-chaos-install.yaml"

    # 설치 완료 대기
    log_info "카오스 엔지니어링 설치 완료 대기 중..."
    kubectl wait --for=condition=available --timeout=300s deployment/litmus-chaos-operator -n chaos-engineering
    kubectl wait --for=condition=available --timeout=300s deployment/litmus-chaos-runner -n chaos-engineering
    kubectl wait --for=condition=available --timeout=300s deployment/litmus-chaos-exporter -n chaos-engineering

    log_success "카오스 엔지니어링 설치 완료"
}

# 배포 파이프라인 설치
install_deployment_pipeline() {
    log_info "배포 파이프라인 설치 중..."

    # ArgoCD 설치
    if ! helm list -n argocd | grep -q "argocd"; then
        helm install argocd argo/argo-cd \
            --namespace argocd \
            --create-namespace \
            --set server.ingress.enabled=true \
            --set server.ingress.hosts[0]=argocd.game-sre.local \
            --set server.extraArgs[0]=--insecure \
            --wait \
            --timeout 10m

        log_success "ArgoCD 설치 완료"
    else
        log_info "ArgoCD가 이미 설치되어 있음"
    fi

    # Argo Rollouts 설치
    if ! helm list -n argocd | grep -q "argo-rollouts"; then
        helm install argo-rollouts argo/argo-rollouts \
            --namespace argocd \
            --wait \
            --timeout 10m

        log_success "Argo Rollouts 설치 완료"
    else
        log_info "Argo Rollouts가 이미 설치되어 있음"
    fi

    # 게임 서비스 배포 매니페스트 적용
    kubectl apply -f "$PROJECT_ROOT/deployment/k8s/production/rollout.yaml"

    # 배포 파이프라인 모니터링 규칙 적용
    kubectl apply -f "$PROJECT_ROOT/deployment/monitoring/deployment-prometheus-rules.yaml" -n monitoring

    log_success "배포 파이프라인 설치 완료"
}

# SLI/SLO 설정 적용
apply_sli_slo() {
    log_info "SLI/SLO 설정 적용 중..."

    kubectl apply -f "$PROJECT_ROOT/sli-slo/game-service-slo.yaml"

    log_success "SLI/SLO 설정 적용 완료"
}

# 알람 규칙 적용
apply_alerting_rules() {
    log_info "알람 규칙 적용 중..."

    kubectl apply -f "$PROJECT_ROOT/alerting/slo-burn-rates.yaml" -n monitoring

    log_success "알람 규칙 적용 완료"
}

# 대시보드 적용
apply_dashboards() {
    log_info "Grafana 대시보드 적용 중..."

    # 대시보드 ConfigMap 생성
    kubectl create configmap game-service-dashboards \
        --from-file="$PROJECT_ROOT/dashboards/" \
        -n monitoring \
        --dry-run=client -o yaml | kubectl apply -f -

    log_success "Grafana 대시보드 적용 완료"
}

# 설치 검증
verify_installation() {
    log_info "설치 검증 중..."

    # 모니터링 스택 검증
    log_info "모니터링 스택 상태 확인..."
    kubectl get pods -n monitoring

    # 카오스 엔지니어링 검증
    log_info "카오스 엔지니어링 상태 확인..."
    kubectl get pods -n chaos-engineering

    # 배포 파이프라인 검증
    log_info "배포 파이프라인 상태 확인..."
    kubectl get pods -n argocd

    # 서비스 상태 확인
    log_info "서비스 상태 확인..."
    kubectl get svc -n monitoring
    kubectl get svc -n chaos-engineering
    kubectl get svc -n argocd

    log_success "설치 검증 완료"
}

# 접속 정보 출력
show_access_info() {
    log_info "=== 접속 정보 ==="
    echo

    # Grafana 접속 정보
    log_info "Grafana:"
    echo "  URL: http://localhost:3000"
    echo "  사용자: admin"
    echo "  비밀번호: game-sre-admin-2024!"
    echo

    # Prometheus 접속 정보
    log_info "Prometheus:"
    echo "  URL: http://localhost:9090"
    echo

    # AlertManager 접속 정보
    log_info "AlertManager:"
    echo "  URL: http://localhost:9093"
    echo

    # ArgoCD 접속 정보
    log_info "ArgoCD:"
    echo "  URL: http://localhost:8080"
    echo "  사용자: admin"
    echo "  비밀번호: admin"
    echo

    # 카오스 엔지니어링 접속 정보
    log_info "카오스 엔지니어링:"
    echo "  URL: http://chaos.game-sre.local"
    echo "  메트릭: http://chaos.game-sre.local/metrics"
    echo

    log_info "포트 포워딩 명령어:"
    echo "  kubectl port-forward -n monitoring svc/game-monitoring-grafana 3000:80"
    echo "  kubectl port-forward -n monitoring svc/game-monitoring-prometheus 9090:9090"
    echo "  kubectl port-forward -n monitoring svc/game-monitoring-alertmanager 9093:9093"
    echo "  kubectl port-forward -n argocd svc/argocd-server 8080:80"
}

# 메인 설치 프로세스
main() {
    log_info "모바일 게임 서비스 SRE 체계 설치 시작"
    echo

    # 1. 사전 조건 확인
    check_prerequisites
    check_kubernetes
    echo

    # 2. Helm 저장소 설정
    setup_helm_repos
    echo

    # 3. 네임스페이스 생성
    create_namespaces
    echo

    # 4. 모니터링 스택 설치
    install_monitoring
    echo

    # 5. 카오스 엔지니어링 설치
    install_chaos_engineering
    echo

    # 6. 배포 파이프라인 설치
    install_deployment_pipeline
    echo

    # 7. SLI/SLO 설정 적용
    apply_sli_slo
    echo

    # 8. 알람 규칙 적용
    apply_alerting_rules
    echo

    # 9. 대시보드 적용
    apply_dashboards
    echo

    # 10. 설치 검증
    verify_installation
    echo

    # 11. 접속 정보 출력
    show_access_info
    echo

    log_success "모바일 게임 서비스 SRE 체계 설치 완료!"
    log_info "설치된 구성 요소:"
    log_info "  - 모니터링 스택 (Prometheus, Grafana, AlertManager, Loki, Tempo)"
    log_info "  - 카오스 엔지니어링 (Litmus Chaos)"
    log_info "  - 배포 파이프라인 (ArgoCD, Argo Rollouts)"
    log_info "  - SLI/SLO 정의 및 알람 규칙"
    log_info "  - Grafana 대시보드"
    echo
    log_info "다음 단계:"
    log_info "  1. 포트 포워딩을 통해 서비스에 접속"
    log_info "  2. Grafana에서 대시보드 확인"
    log_info "  3. 카오스 실험 실행"
    log_info "  4. 배포 파이프라인 테스트"
}

# 스크립트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

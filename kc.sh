#!/bin/bash

# Script untuk mengelola deployment aplikasi di Google Kubernetes Engine (GKE)

# Fungsi untuk memeriksa apakah kubectl dikonfigurasi dengan benar
check_kubectl_config() {
    echo "Memeriksa konfigurasi kubectl..."
    if ! kubectl cluster-info &>/dev/null; then
        echo "kubectl tidak terkonfigurasi untuk terhubung ke klaster Kubernetes."
        echo "Pastikan Anda telah login ke gcloud dan mengatur konteks Kubernetes Anda."
        echo "Contoh: gcloud container clusters get-credentials YOUR_CLUSTER_NAME --zone YOUR_CLUSTER_ZONE"
        exit 1
    fi
    echo "kubectl terhubung ke klaster Kubernetes."
}

# Fungsi untuk menjalankan (deploy) aplikasi
run_app() {
    check_kubectl_config

    echo "Menerapkan resource dasar (Secrets, ConfigMaps, PVCs, Services)..."
    # Terapkan resource yang tidak bergantung pada NodePort dinamis atau deployment lainnya
    # Urutan penting untuk dependensi (misal: Secret sebelum Deployment yang menggunakannya)
    kubectl apply -f backend-secrets.yml
    kubectl apply -f db_backend-init-script-configmap.yml
    kubectl apply -f db_verifikator-init-script-configmap.yml
    kubectl apply -f db_backend-pvc.yml
    kubectl apply -f db_verifikator-pvc.yml
    kubectl apply -f backend-service.yml
    kubectl apply -f db_backend-service.yml
    kubectl apply -f db_verifikator-service.yml
    kubectl apply -f frontend-service.yml
    kubectl apply -f verifikator-service.yml

    echo "Menunggu sebentar agar services siap..."
    sleep 5 # Beri waktu sebentar agar service benar-benar terdaftar

    echo "Menerapkan Ingress Resources (hanya untuk Frontend)..."
    kubectl apply -f frontend-ingress.yml # Hanya frontend yang terekspos via Ingress

    echo "Menerapkan Deployment..."
    # Terapkan Deployments dalam urutan yang logis (misal: database dulu, lalu backend, frontend, verifikator)
    kubectl apply -f db_backend-deployment.yml
    kubectl apply -f db_verifikator-deployment.yml
    kubectl apply -f backend-deployment.yml
    kubectl apply -f frontend-deployment.yml
    kubectl apply -f verifikator-deployment.yml

    echo "Deployment selesai. Memeriksa status semua resource..."
    kubectl get all

    echo ""
    echo "Aplikasi Anda sekarang dapat diakses melalui Ingress (Frontend)."
    echo "Untuk mendapatkan IP eksternal Ingress, jalankan perintah berikut setelah beberapa saat:"
    echo "  kubectl get ingress frontend-ingress"
    echo "Kemudian akses frontend di browser Anda melalui IP eksternal yang ditampilkan."
    echo ""
    echo "Backend API diakses secara internal oleh frontend melalui: http://backend-service:8080"
    echo "Verifikator API diakses secara internal oleh frontend melalui: http://verifikator-service:8081"
}

# Fungsi untuk menghentikan (delete) aplikasi
stop_app() {
    check_kubectl_config

    echo "Menghapus semua resource Kubernetes..."
    kubectl delete -f .

    echo "Penghapusan selesai. Memeriksa status..."
    kubectl get all
}

# Fungsi untuk melihat log dari deployment tertentu
get_logs() {
    check_kubectl_config
    local deployment_name="$1"
    if [ -z "$deployment_name" ]; then
        echo "Penggunaan: --logs <nama_deployment>"
        echo "Contoh: --logs backend-deployment"
        exit 1
    fi
    echo "Melihat log untuk deployment: ${deployment_name}..."
    kubectl logs -f deployment/${deployment_name}
}

# Fungsi untuk mendapatkan URL frontend service
get_frontend_url() {
    check_kubectl_config
    echo "Mendapatkan informasi URL Ingress frontend..."

    INGRESS_IP=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -z "$INGRESS_IP" ]; then
        echo "Ingress frontend-ingress belum siap atau tidak memiliki IP eksternal."
        echo "Mungkin perlu waktu beberapa menit setelah deployment untuk IP dialokasikan."
        echo "Coba jalankan 'kubectl get ingress frontend-ingress' secara manual untuk melihat statusnya."
        exit 1
    fi

    echo "URL Frontend Service (melalui Ingress): http://${INGRESS_IP}"
    echo ""
    echo "Untuk akses, gunakan IP eksternal Ingress ini."
}

# Fungsi untuk mengeksekusi perintah di dalam container deployment tertentu
exec_command() {
    check_kubectl_config
    local deployment_name="$1"
    shift # Geser argumen pertama ($1)
    local command="$@" # Semua argumen sisanya adalah perintah

    if [ -z "$deployment_name" ] || [ -z "$command" ]; then
        echo "Penggunaan: --exec <nama_deployment> <perintah>"
        echo "Contoh: --exec backend-deployment bash"
        echo "Contoh: --exec db-backend-deployment psql -U postgres"
        exit 1
    fi

    echo "Mengeksekusi perintah '${command}' di deployment: ${deployment_name}..."
    # Dapatkan nama pod dari deployment
    POD_NAME=$(kubectl get pods -l app=${deployment_name%%-deployment*} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD_NAME" ]; then
        echo "Tidak dapat menemukan pod untuk deployment ${deployment_name}. Pastikan deployment berjalan."
        exit 1
    fi
    kubectl exec -it ${POD_NAME} -- ${command}
}

# Fungsi untuk melihat variabel lingkungan dari container deployment tertentu
get_env() {
    check_kubectl_config
    local deployment_name="$1"
    if [ -z "$deployment_name" ]; then
        echo "Penggunaan: --env <nama_deployment>"
        echo "Contoh: --env backend-deployment"
        exit 1
    fi
    echo "Melihat variabel lingkungan untuk deployment: ${deployment_name}..."
    # Dapatkan nama pod dari deployment
    POD_NAME=$(kubectl get pods -l app=${deployment_name%%-deployment*} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD_NAME" ]; then
        echo "Tidak dapat menemukan pod untuk deployment ${deployment_name}. Pastikan deployment berjalan."
        exit 1
    fi
    kubectl exec -it ${POD_NAME} -- env
}

get_pods() {
    check_kubectl_config
    echo "Mendapatkan daftar pods..."
    kubectl get pods
}

get_services() {
    check_kubectl_config
    echo "Mendapatkan daftar services..."
    kubectl get services
}


# Logika argumen
case "$1" in
    --run)
        run_app
        ;;
    --stop)
        stop_app
        ;;
    --logs)
        get_logs "$2"
        ;;
    --url)
        get_frontend_url
        ;;
    --exec)
        # Shift argumen pertama (--exec) dan teruskan sisanya
        shift
        exec_command "$@"
        ;;
    --env)
        get_env "$2"
        ;;
    --pods)
        get_pods
        ;;
    --services)
        get_services
        ;;
    *)
        echo "Penggunaan: $0 [--run | --stop | --logs <nama_deployment> | --url | --exec <nama_deployment> <perintah> | --env <nama_deployment> | --pods | --services]"
        echo "  --run : Menerapkan semua manifest Kubernetes (termasuk Ingress)."
        echo "  --stop: Menghapus semua resource Kubernetes."
        echo "  --logs <nama_deployment>: Melihat log dari deployment tertentu (misal: backend-deployment, frontend-deployment)."
        echo "  --url : Menampilkan URL Ingress frontend untuk diakses di browser."
        echo "  --exec <nama_deployment> <perintah>: Mengeksekusi perintah di dalam container deployment (misal: bash, ls -l)."
        echo "  --env <nama_deployment>: Menampilkan variabel lingkungan dari container deployment."
        echo "  --pods : Menampilkan daftar pods yang ada."
        echo "  --services : Menampilkan daftar services yang ada."
        echo "Contoh: $0 --run"
        echo "Contoh: $0 --logs backend-deployment"
        echo "Contoh: $0 --exec backend-deployment bash"
        echo "Contoh: $0 --env backend-deployment"
        echo "Contoh: $0 --pods"
        echo "Contoh: $0 --services"
        exit 1
        ;;
esac
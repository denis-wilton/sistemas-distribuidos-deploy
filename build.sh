#!/bin/bash

# Obtém os IPs de todos os nós do Swarm
SWARM_IPS=$(docker node ls -q | xargs -n1 docker node inspect --format '{{ .Status.Addr }}')

# Obtém o IP da máquina local
LOCAL_IP=$(hostname -I | awk '{print $1}')

USER="aluno"
PASS="123456"

REPOS=(
    "git@github.com:denis-wilton/sistemas-distribuidos-chat.git"
    "git@github.com:denis-wilton/sistemas-distribuidos-market-data.git"
    "git@github.com:denis-wilton/sistemas-distribuidos-frontend.git"
)

# Loop pelos IPs
for ip in $SWARM_IPS; do

    if [[ "$ip" == "$LOCAL_IP" ]]; then
        echo "==> Ignorando IP local ($ip)"
        continue
    fi

    echo "==> Conectando ao nó $ip"

    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$USER@$ip" bash -s <<EOF

# Define repositórios
REPOS=(${REPOS[@]})

# Atualiza ou clona os repositórios e builda as imagens
for repo in "\${REPOS[@]}"; do
    REPO_NAME=\$(basename "\$repo" .git)

    if [ -d "\$REPO_NAME" ]; then
        echo "==> Atualizando \$REPO_NAME..."
        (cd "\$REPO_NAME" && git pull)
    else
        echo "==> Clonando \$REPO_NAME..."
        git clone "\$repo"
    fi

    echo "==> Buildando imagem Docker: \$REPO_NAME..."
    cd "\$REPO_NAME"
    docker build -t "\$REPO_NAME" .
    cd ..
done

EOF

done

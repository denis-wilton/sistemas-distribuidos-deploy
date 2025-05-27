REPOS=(
    "git@github.com:denis-wilton/sistemas-distribuidos-chat.git"
    "git@github.com:denis-wilton/sistemas-distribuidos-market-data.git"
    "git@github.com:denis-wilton/sistemas-distribuidos-frontend.git"
)

while ! docker stack rm my-stack; do
    echo "Retrying stack rm..."
    sleep 2
done


for repo in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$repo" .git)
    if [ -d "$REPO_NAME" ]; then
        echo "Updating $REPO_NAME..."
        (cd "$REPO_NAME" && git pull)
    else
        echo "Cloning $REPO_NAME..."
        git clone "$repo"
    fi
done

# Build each image in parallel
for repo in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$repo" .git)
    echo "Building $REPO_NAME"
    (cd "$REPO_NAME" && docker build --no-cache -t "$REPO_NAME" .) &
done

# Wait for all builds to complete
wait

echo "All builds completed"



# wait 5s
sleep 5

while ! docker stack deploy --compose-file docker-compose.yml my-stack; do
    echo "Retrying stack deploy..."
    sleep 2
done


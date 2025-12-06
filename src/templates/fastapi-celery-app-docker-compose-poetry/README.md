

```bash
docker container prune --force \
&& docker compose down --volumes --remove-orphans \
&& docker compose up --build --detach=true --remove-orphans --force-recreate \
&& for i in {1..20}; do { curl -s -o /dev/null http://localhost:8000 && break; } ; sleep 0.1; done \
&& echo \
&& TASK_ID=$(curl -sX POST "http://localhost:8000/add/?a=5&b=7" | jq -r .task_id) \
&& echo \
&& for i in {1..20}; do { curl -s -o /dev/null "http://localhost:8000/result/$TASK_ID?timeout=0.1" && break; } ; sleep 0.1; done \
&& echo \
&& RESULT=$(curl "http://localhost:8000/result/$TASK_ID?timeout=3")\
&& echo $RESULT | grep '"result":12'

docker container prune --force \
&& docker compose down --volumes --remove-orphans
```


```bash
poetry config virtualenvs.in-project true \
&& poetry config virtualenvs.path . \
&& poetry show --tree
```

```bash
poetry \
    add \
    'fastapi==0.116.1' \
    'uvicorn[standard]==0.35.0' \
    'celery[redis]==5.5.3' \
&& poetry lock \
&& poetry show --tree
```

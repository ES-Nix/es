

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
python3 -m venv .venv \
&& source .venv/bin/activate \
&& pip install --requirement requirements.txt
```

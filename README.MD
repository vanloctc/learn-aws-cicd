# ⚡ Realtime Clock App — AWS ECS CI/CD
# 2026 04 13
# 2026 04 13
> Flask app hiển thị thời gian realtime
> Deploy lên **AWS ECS Fargate** qua **CodeBuild → CodeDeploy (Blue/Green) → CodePipeline**

---

## 📁 Cấu trúc Project

```
realtime-clock-app/
├── app.py                          # Flask application
├── requirements.txt                # Python deps
├── Dockerfile                      # Multi-stage build → ECS image
├── docker-compose.yml              # Test local
├── .dockerignore
│
├── buildspec.yml                   # ① CodeBuild: Docker build → ECR push
├── appspec.yml                     # ② CodeDeploy ECS Blue/Green
│
├── ecs/
│   ├── task-definition.json        # ECS Task Definition template
│   └── imageDefinitions.json       # Generated bởi CodeBuild
│
├── cloudformation/
│   └── pipeline.yml                # ③ Full stack: ECR+ECS+ALB+Pipeline
│
├── templates/index.html            # Realtime clock UI
└── tests/test_app.py               # 8 unit tests
```

---

## 🏗 Kiến trúc AWS

```
GitHub ──push──► CodePipeline
                    │
          ┌─────────┴──────────┐
          ▼                    ▼
      [Source]              [Build]                    [Deploy]
      GitHub                CodeBuild            CodeDeploy (ECS)
                         ┌──────────────┐       ┌──────────────────────┐
                         │ pytest       │       │ Blue/Green           │
                         │ docker build │──────►│                      │
                         │ ECR push     │       │ ALB :80  → Blue TG  │
                         └──────────────┘       │ ALB :8080→ Green TG │
                                                │                      │
                                                │ Shift traffic 100%  │
                                                │ Terminate Blue (5m) │
                                                └──────────────────────┘
                                                         │
                                                  ECS Fargate Cluster
                                                  (DesiredCount: 2)
```

---

## 🚀 Hướng dẫn triển khai

### 1. Test local
```bash
docker compose up --build
# http://localhost:8080
```

### 2. Deploy toàn bộ stack (1 lệnh)
```bash
aws cloudformation deploy \
  --template-file cloudformation/pipeline.yml \
  --stack-name realtime-clock \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      AppName=realtime-clock \
      GitHubOwner=YOUR_ORG \
      GitHubRepo=realtime-clock-app \
      GitHubBranch=main \
      GitHubOAuthToken=ghp_YOUR_TOKEN \
      VpcId=vpc-xxxxxxxxx \
      SubnetIds="subnet-aaa,subnet-bbb" \
      DesiredCount=2
```

### 3. Push code → Pipeline tự chạy
```bash
git add . && git commit -m "feat: update app" && git push origin main
# CodePipeline tự trigger → Build → Deploy Blue/Green
```

---

## ① CodeBuild — buildspec.yml

| Phase | Hành động |
|-------|-----------|
| `install` | Python 3.11, pip deps, pytest, flake8 |
| `pre_build` | Lint + Unit tests + **ECR Login** |
| `build` | `docker build` → `docker push` (tag: commit-sha + latest) |
| `post_build` | Tạo `imageDefinitions.json` + `imageDetail.json` |

> ⚠️ **Bắt buộc**: CodeBuild Environment phải bật `PrivilegedMode: true` để chạy Docker.

---

## ② CodeDeploy — appspec.yml (ECS Blue/Green)

```
Deployment flow:
  1. Tạo Green task set (version mới) → ALB :8080
  2. Smoke test qua Test Listener (port 8080)
  3. Chuyển 100% traffic sang Green (ALB :80)
  4. Chờ 5 phút → Terminate Blue tasks
  5. Auto Rollback nếu health check fail
```

---

## ③ CloudFormation — pipeline.yml

Tạo đầy đủ các resources:

| Resource | Mô tả |
|----------|-------|
| `AWS::ECR::Repository` | Lưu Docker images |
| `AWS::ECS::Cluster` | Fargate cluster (Container Insights ON) |
| `AWS::ECS::TaskDefinition` | 256 CPU / 512 MB RAM |
| `AWS::ECS::Service` | DesiredCount=2, DeploymentController=CODE_DEPLOY |
| `AWS::ElasticLoadBalancingV2::*` | ALB + Blue TG (port 80) + Green TG (port 8080) |
| `AWS::CodeDeploy::*` | Blue/Green, Auto Rollback ON |
| `AWS::CodeBuild::Project` | PrivilegedMode=true |
| `AWS::CodePipeline::Pipeline` | 3 stages: Source→Build→Deploy |

---

## 🌐 API Endpoints

| Endpoint | Mô tả |
|----------|-------|
| `GET /` | Trang clock realtime |
| `GET /api/time` | JSON: time, date, timezone |
| `GET /health` | ALB health check |
| `GET /version` | Build ID, commit SHA, env |

---

## 🔒 Security Best Practices

- Container chạy user non-root (`appuser`)
- `readonlyRootFilesystem` có thể bật cho production
- ECS Security Group chỉ nhận traffic từ ALB
- ECR `ScanOnPush: true` — tự động scan CVE
- Secrets → AWS Secrets Manager (không hardcode)
- GitHub token → AWS Secrets Manager (không dùng trực tiếp trong CFN)

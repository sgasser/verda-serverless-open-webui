# Verda Serverless Open WebUI

Deploy Open WebUI with Verda serverless GPU containers for cost-effective inference.

## Architecture

```
+-------------------------------------------------------+
|  CPU Server                                           |
|                                                       |
|  +-------------+  +-------------+  +-------------+    |
|  |  Open WebUI |  |  PostgreSQL |  |   SearXNG   |    |
|  |             |  |  + pgvector |  |             |    |
|  +------+------+  +-------------+  +-------------+    |
|         |                                             |
|  +------+------+  +-------------+                     |
|  |   LiteLLM   |  |    Caddy    |                     |
|  |   (Proxy)   |  |   (HTTPS)   |                     |
|  +------+------+  +-------------+                     |
+---------+---------------------------------------------+
          |
          v API Calls (pay-per-use)
+-------------------------------------------------------+
|  Verda Serverless Containers                          |
|                                                       |
|  +---------------------------+  +-----------------+   |
|  |  Embeddings + Reranking   |  |       LLM       |   |
|  |  Infinity (bge-m3 + rer.) |  | vLLM Ministral  |   |
|  |                           |  |  14B Instruct   |   |
|  |     RTX 4500 Ada          |  |    A100 80GB    |   |
|  +---------------------------+  +-----------------+   |
+-------------------------------------------------------+
```

## Quick Start

### 1. Deploy CPU Server

```bash
# On Verda CPU.8V.32G instance
curl -fsSL https://get.docker.com | sh

cd /opt
git clone https://github.com/sgasser/verda-serverless-open-webui.git
cd verda-serverless-open-webui

cp .env.example .env
# Edit .env with your secrets and domains
docker compose up -d
```

### 2. Create Verda Serverless Containers

Go to [Verda Console](https://console.verda.com) → Serverless Containers → Create

#### Infinity (Embeddings + Reranking)

| Setting | Value |
|---------|-------|
| Name | `infinity-embeddings` |
| Image | `michaelf34/infinity:0.0.77` |
| Port | `8080` |
| Entrypoint | (leave empty) |
| Start Command | `v2 --model-id BAAI/bge-m3 --model-id BAAI/bge-reranker-v2-m3 --port 8080` |
| GPU | RTX 4500 Ada (24GB) |
| Min Replicas | 0 |
| Max Replicas | 1 |
| Health Check | `/health` |

#### vLLM (LLM)

| Setting | Value |
|---------|-------|
| Name | `vllm-ministral` |
| Image | `vllm/vllm-openai:v0.11.2` |
| Port | `8000` |
| Entrypoint | (leave empty) |
| Start Command | `--model mistralai/Ministral-3-14B-Instruct-2512 --tokenizer_mode mistral --config_format mistral --load_format mistral --max-model-len 32768 --gpu-memory-utilization 0.9` |
| GPU | A100 80GB |
| Min Replicas | 0 |
| Max Replicas | 1 |
| Health Check | `/health` |

### 3. Create Verda Inference API Key

1. Go to [Verda Console](https://cloud.datacrunch.io) → **Keys** → **Inference API Keys**
2. Click **Create** and copy the generated key (starts with `dc_`)

### 4. Configure LiteLLM

1. Open LiteLLM UI: `https://your-litellm-domain/ui`
2. Login with `LITELLM_MASTER_KEY`
3. Go to **Models** → **Add Model**

| Setting | Value |
|---------|-------|
| Provider | `vLLM` |
| LiteLLM Model Name(s) | `hosted_vllm/mistralai/Ministral-3-14B-Instruct-2512` |
| Public Model Name | `ministral-14b-instruct` |
| API Base | `https://containers.datacrunch.io/YOUR-VLLM-CONTAINER/v1` |
| API Key | Your Verda Inference API Key (`dc_...`) |

### 5. Configure Open WebUI

1. Open `https://your-domain.com`
2. Login as admin
3. Go to **Admin Panel** → **Settings** → **Documents**

#### Embedding Configuration

| Setting | Value |
|---------|-------|
| Embedding Model Engine | `OpenAI` |
| API Base URL | `https://containers.datacrunch.io/YOUR-INFINITY-CONTAINER` |
| API Key | Your Verda Inference API Key (`dc_...`) |
| Embedding Model | `BAAI/bge-m3` |

#### Reranking Configuration

| Setting | Value |
|---------|-------|
| Hybrid Search | ✅ On |
| Reranking Engine | `External` |
| API URL | `https://containers.datacrunch.io/YOUR-INFINITY-CONTAINER/rerank` |
| API Key | Your Verda Inference API Key (`dc_...`) |
| Reranking Model | `BAAI/bge-reranker-v2-m3` |

## Configuration

### Environment Variables (.env)

```bash
# Domains
OPENWEBUI_DOMAIN=chat.example.com
LITELLM_DOMAIN=litellm.example.com

# LiteLLM (generate with: openssl rand -hex 32)
LITELLM_MASTER_KEY=sk-your-key
LITELLM_SALT_KEY=sk-your-salt

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password
LITELLM_DB_PASSWORD=your-db-password
OPENWEBUI_DB_PASSWORD=your-db-password

# SearXNG
SEARXNG_SECRET=your-secret
```

## Local Development

Create `docker-compose.override.yml` for local port mappings:

```yaml
services:
  open-webui:
    ports:
      - "3000:8080"
  litellm:
    ports:
      - "4000:4000"
```


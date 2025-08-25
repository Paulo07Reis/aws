# Integração API Gatway, Lambda e DynamoDB

## 🔧 Pré-requisitos

- Conta AWS ativa
- Tabela no DynamoDB: **`telemetria_http`**
    - **Partition key:** `deviceId` *(String)*
    - **Sort key:** `ts` *(Number)*

## 🖥️ Passo 1 — Criar a função Lambda

- **Runtime:** Python 3.12
- **Variáveis de ambiente:**
    - `TABLE_NAME=telemetria_http`

O script da lambda está no arquivo lambda_handler.py

## 🌐 Passo 2 — Criar a API Gateway (REST)

Acesse API Gateway → Create API → REST API (Build)

- Crie um recurso: /telemetria
- Adicione o método POST
- Configure a integração como Lambda proxy (selecione a função Lambda criada)
- Faça o deploy: Deploy API
- Stage: dev
- Copie o Invoke URL gerado

## 🧪 Passo 3 — Testar a API
Payload de exemplo

    {

        "deviceId": "edge-01",

        "temp": 25.1,

        "hum": 61

    }

### Teste com cURL
    curl -X POST "<INVOKE_URL>/telemetria" \
    -H "Content-Type: application/json" \
    -d '{"deviceId":"edge-01","temp":25.1,"hum":61}'

## ✅ Passo 4 — Validar o fluxo

No DynamoDB: 
- Verificar se os itens foram inseridos na tabela telemetria_http

No API Gateway:

- Consultar os logs de execução (se habilitados)

- Confirmar resposta HTTP 200 com {"status":"ok"}

## 🏁 Critérios de sucesso

- Inserção correta no DynamoDB com os campos esperados
- Resposta HTTP 200 confirmando o processamento
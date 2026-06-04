# 🗺️ Enterprise AI Gateway Platform: Evolution Roadmap | Ruta de Evolución de Plataforma AI Gateway

This document outlines the **6-Phase Evolution Roadmap (Epics)** and production-hardening strategies to transform this repository from an infrastructure demonstration into a fully-fledged, production-ready **Enterprise AI Consumption Platform**.

Este documento detalla el **Roadmap de Evolución de 6 Fases (Épicas)** y las estrategias de hardening para transformar este repositorio de una demostración de infraestructura a una **Plataforma de Consumo de IA Empresarial** lista para producción.

---

## 📐 Conceptual Architecture | Arquitectura Conceptual

```mermaid
graph TD
    ClientApp["Consumer App (Client/Developer)"] -->|1. OAuth2 Request| EntraID["Azure Entra ID (Auth)"]
    EntraID -->|2. JWT Token| ClientApp
    ClientApp -->|3. POST /chat (with Bearer Token)| APIM["Azure API Management Gateway"]
    
    subgraph Governance ["AI Governance & Security Layer"]
        DLP["Phase 5: DLP & PII Guardrails"]
        Route["Phase 3: Intelligent Model Router"]
        Budget["Phase 3: Dollar-based Budgets"]
    end
    
    APIM -->|Validate JWT Token| DLP
    DLP --> Route
    Route --> Budget
    
    subgraph Backends ["Multi-Model Backends (Phase 2)"]
        AOAI["Azure OpenAI (GPT-4o)"]
        Claude["Anthropic Claude (Sonnet/Haiku)"]
        Gemini["Google Gemini (Pro/Flash)"]
    end
    
    Budget -->|Route to Backend| AOAI
    Budget -->|Route to Backend| Claude
    Budget -->|Route to Backend| Gemini
    
    subgraph Telemetry ["Observability & FinOps (Phase 1)"]
        EventHub["Azure Event Hub / Log Analytics"]
        AppInsights["Azure Application Insights"]
        Workbook["Azure Workbook / Power BI"]
    end
    
    APIM -->|Asynchronous Stream| EventHub
    EventHub --> AppInsights
    AppInsights --> Workbook
    
    subgraph Security ["Enterprise Security & Hardening (Phase 5)"]
        MI["Managed Identity"]
        PE["Private Endpoints"]
        KV["Azure Key Vault"]
    end
    
    APIM -.->|Read Secrets via MI| KV
    APIM -.->|Secure Tunnel| PE
```

---

## 🛠️ The 6-Phase Evolution (Epics) | Las 6 Épicas de Evolución

### 🏗️ Phase 0: Current Foundation | Base Actual (IaC & Basic Limits)
The starting point of the platform, as defined in this repository.
*   **IaC:** Declarative resources in Terraform defining Azure API Management (APIM) and Key Vault.
*   **Security:** Static Key Vault key injection (Key Vault Linked Named Values).
*   **Controls:** Basic Rate Limiting (50 calls/min) and Quotas (10,000 requests/month) enforced at the APIM policy level.

---

### 📊 Phase 1: Token-Level Observability | Observabilidad a Nivel de Tokens
Currently, the platform logs basic HTTP traffic. This Epic focuses on capturing token counts (input/output) and exact costs per request for chargeback.

Esta Épica se enfoca en capturar el conteo de tokens (entrada/salida) y el costo exacto por petición para permitir el chargeback.

#### 1. Metric JSON Schema | Esquema JSON de Métricas
For every request, the gateway extracts metadata and token metrics:
```json
{
  "team": "finance",
  "model": "claude-3-5-sonnet",
  "input_tokens": 1200,
  "output_tokens": 450,
  "estimated_cost_usd": 0.023,
  "timestamp": "2026-06-04T13:55:00Z"
}
```

#### 2. APIM Implementation Strategy | Estrategia de Implementación en APIM
We use APIM's `<log-to-eventhub>` policy to asynchronously stream request and response payloads to Azure Event Hubs without impacting latency, which then routes them to Log Analytics and Application Insights:
```xml
<outbound>
    <base />
    <!-- Extract token counts and log details asynchronously -->
    <log-to-eventhub logger-id="finops-logger">
        @((string)context.Variables["finops-metric-payload"])
    </log-to-eventhub>
</outbound>
```

---

### 🌐 Phase 2: Multi-Model Routing & Entra ID | Enrutamiento Multi-Modelo y Autenticación Entra ID
Enterprise applications require vendor neutrality and secure, standardized authentication. The AI Gateway exposes a single, unified `/chat` endpoint.

Las aplicaciones empresariales requieren neutralidad de proveedor y autenticación segura y estandarizada. El AI Gateway expondrá un endpoint `/chat` unificado.

```text
User / App
  ├─ Authenticates against Azure Entra ID (OAuth2 Client Credentials Flow)
  ├─ Obtains JWT Access Token
  └─ Sends request to APIM: POST /chat (with Authorization: Bearer JWT)
```

Inside APIM:
*   **Validate JWT Token:** Enforces authentication and checks claims using `<validate-jwt>` policy.
*   **Routing Logic:** APIM inspects the request payload and forwards it:
    *   `team: finance` $\rightarrow$ Routes to **Azure OpenAI (GPT-4o)**
    *   `team: support` $\rightarrow$ Routes to **Anthropic Claude Haiku** (Cost-efficient)
    *   `team: engineering` $\rightarrow$ Routes to **Anthropic Claude Sonnet**

---

### 🧠 Phase 3: Budget Enforcement & Intelligent Routing | Presupuestos y Enrutamiento Inteligente
Transitioning from request counts to dollar-based budgets because token usage drives the actual API bill, combined with cost-optimization routing based on prompt sizes.

Transición de cuotas por llamadas a presupuestos basados en dólares, combinado con enrutamiento de optimización de costos según el tamaño del prompt.

#### 1. Dollar-based budgets:
*   **Marketing Budget:** $\$500$/month.
*   **Engineering Budget:** $\$3,000$/month.
*   **Finance Budget:** $\$1,000$/month.
*   **Throttling & Alerts Flow:** Webhook alerts sent to **Microsoft Teams** / **Slack** or **ServiceNow** at 80% consumption; APIM dynamically throttles requests with a `403 Forbidden (Budget Exhausted)` at 100% consumption.

#### 2. Intelligent Routing Logic:
```python
# Conceptual Gateway Routing
if prompt_tokens < 500:
    route_to("claude-3-haiku")      # Low-cost for simple queries
elif prompt_tokens < 5000:
    route_to("claude-3-5-sonnet")  # Balanced reasoning
else:
    route_to("claude-3-opus")       # Heavy reasoning
```

---

### 🚀 Phase 4: Self-Service Platform (Internal Developer Portal) | Plataforma Self-Service para Desarrolladores
To eliminate infrastructure bottlenecks, developer teams request AI credentials via a self-service portal (e.g., **Spotify Backstage** or Azure Developer CLI).

Para eliminar cuellos de botella, los equipos de desarrollo solicitan credenciales de IA a través de un portal self-service (ej. **Spotify Backstage**).

```text
Developer Request:
  - Team: Finance
  - Model Required: Claude 3.5 Sonnet
  - Environment: Production
```

Upon form approval, a GitOps pipeline automatically runs Terraform to provision:
1.  A dedicated **APIM Subscription**.
2.  A corresponding **APIM Product** configuration.
3.  An **Azure Key Vault Secret** configuration.
4.  Appropiate XML Policy attachment.

---

### 🛡️ Phase 5: Responsible AI & Network Hardening | IA Responsable y Hardening de Red
Securing the AI Gateway for highly regulated environments (SOC 2 Type II / SOX compliance) and protecting against PII leakage.

Asegurando el AI Gateway para entornos altamente regulados y protegiendo contra fugas de datos sensibles (PII).

*   **Managed Identity:** Eliminate static credentials. APIM is assigned a System-Assigned Managed Identity with the **Key Vault Secrets User** role to retrieve keys dynamically.
*   **Private Endpoints:** All traffic flows through private virtual networks using Private Endpoints, ensuring zero public internet exposure.
*   **DLP & Prompt Inspection:** APIM XML policies inspect the inbound payload and use Regex to detect/redact sensitive data (Credit Cards, SSN, tokens) before forwarding to LLM providers.

---

## 🏛️ Production Hardening (Consulting Grade) | Nivel de Consultoría Enterprise

To present this platform as a production-ready solution that large enterprises would invest in, we incorporate these core elements:

### 1. FinOps Cost Dashboard (Power BI / Azure Workbook)
A centralized dashboard connected to our Event Hub Log Stream, showing:
*   **Spend by Team:** Clear visualization for chargeback.
*   **Spend by Model:** Visualizing cost impact of Sonnet vs Haiku vs GPT-4o.
*   **Token Efficiency:** Tracks Cache Hit ratio vs Raw Token cost.
*   **Forecast Spend:** Linear extrapolation models indicating if any team is projected to exceed their monthly budget.

### 2. Log Analytics & Azure Policy
*   **Compliance Audit:** Enforce retention periods on Log Analytics for every prompt transaction (excluding redacted PII).
*   **Azure Policy:** Enforce that no APIM instances can be deployed without Private Endpoints, and require that Key Vault purge protection is enabled.

### 3. APIM Developer Portal
*   Provide interactive, self-updating API documentation.
*   Enable developers to test their API credentials against the `/chat` endpoint directly in the browser sandbox.

### 4. Modular Terraform (DRY)
*   Refactoring the monolithic Terraform structure into reusable modules:
    *   `modules/apim/` — Manages gateway, endpoints, and policies.
    *   `modules/keyvault/` — Manages secret storage and access policies.
    *   `modules/networking/` — Manages VNets, subnets, and Private Endpoints.
*   Enables multi-environment deployments (`dev`, `staging`, `prod`) using parameterized workspace variables.

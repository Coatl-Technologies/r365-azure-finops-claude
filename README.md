# R365 Azure FinOps para Claude AI

Bienvenido al repositorio de **Platform Engineering** enfocado en Gobernanza y FinOps para modelos de inteligencia artificial (LLMs).

Este repositorio fue diseñado para demostrar cómo aprovisionar infraestructura segura, auditable y financieramente controlada para que usuarios de negocio consuman **Claude AI (Anthropic)** sobre Microsoft Azure.

---

## 🎯 Resumen Ejecutivo (Executive Summary)

Las organizaciones buscan acelerar su adopción de IA Generativa. Sin embargo, dar acceso directo a las APIs de los LLMs genera riesgos operativos críticos:
1. **Riesgo Financiero:** Loops infinitos en código o uso desproporcionado que agota el presupuesto.
2. **Riesgo de Seguridad:** Credenciales dispersas y exposición de tráfico sin auditar.
3. **Complejidad de Plataforma:** Carga cognitiva alta para los desarrolladores.

### La Solución
Implementar **Azure API Management (APIM)** como el "AI Gateway" central. Todas las aplicaciones envían sus peticiones al APIM, el cual inyecta la clave maestra de Claude de forma segura desde **Azure Key Vault**, impone cuotas estrictas de tokens (Rate Limiting) y reporta la telemetría de costos a los dashboards de observabilidad (Datadog/Application Insights) para permitir el *Chargeback* entre equipos.

---

## 🏗️ Arquitectura de la Solución

1. **Infraestructura como Código (IaC):** `Terraform` para definir de manera inmutable todo el stack en Azure.
2. **CI/CD:** `Azure DevOps` Pipelines para automatizar el `plan` y `apply` con gates de aprobación.
3. **AI Gateway:** `Azure API Management` para enrutamiento, limits y FinOps.
4. **Almacenamiento de Secretos:** `Azure Key Vault` que evita la fuga de la API Key de Anthropic.

---

## 💰 Análisis de Costos (FinOps)

La configuración de este repositorio protege el presupuesto a través de tres pilares:

### 1. Hard Limits (Protección contra Bugs)
La política XML inyectada en el APIM restringe el consumo a un máximo de **50 peticiones por minuto por Suscripción de Equipo**. Si un usuario desencadena un "retry storm" o un bucle infinito, el API Gateway bloquea la petición (`429 Too Many Requests`) antes de llegar a los servidores de Claude, salvando miles de dólares.

### 2. Cuotas Mensuales (Budgeting)
Configurado para limitar el consumo a **10,000 llamadas al mes** por equipo, protegiendo contra scraping abusivo y garantizando distribución justa del presupuesto.

### 3. Caching y Enrutamiento Inteligente (Futuro)
*   **Prompt Caching:** En una fase 2, el APIM puede interceptar solicitudes similares y usar la caché de contexto para reducir el costo de "Input Tokens".
*   **Haiku vs Opus:** El gateway puede rutear peticiones simples a Claude 3 Haiku (más económico) y reservar Claude 3.5 Sonnet u Opus para cargas intensivas de razonamiento.

---

## 🚀 Guía Paso a Paso (Scaffolding)

### Estructura del Repositorio

```text
r365-azure-finops-claude/
├── pipelines/
│   └── azure-pipelines.yml      # CI/CD para Azure DevOps
├── terraform/
│   ├── main.tf                  # APIM y Key Vault resource definitions
│   ├── providers.tf             # Azure provider config
│   ├── variables.tf             # Variables parametrizables
│   └── policies/
│       └── apim-claude-policy.xml # Política FinOps y Rate Limiting
└── README.md                    # Esta documentación
```

### ¿Cómo Desplegar?

1. **Configurar el Service Connection:** En Azure DevOps, crea un Service Connection hacia tu suscripción de Azure y llámalo `coatl-azure-sc`.
2. **Crear el Pipeline:** En Azure DevOps, crea un nuevo pipeline apuntando al archivo `pipelines/azure-pipelines.yml` de este repositorio.
3. **Configurar el Backend de Terraform:** Crea un Storage Account en Azure llamado `tfstatestoragecoatl` dentro de un Resource Group `tfstate-rg` para guardar el estado.
4. **Push & Deploy:** Al hacer merge a `main`, el pipeline ejecutará el stage de `Plan`. Tras la revisión, se ejecutará el `Apply`.

---
*Diseñado con foco en Seguridad, Confiabilidad y FinOps.*

This document refines the original plan to a professional, long-term, globally scalable, and cost-efficient architecture. It adopts a Serverless SQL foundation (PostgreSQL in both regions), modern serverless/container hosting, and a phased rollout to reduce risk. It also incorporates tactical guidance on ingress, secrets management, and asynchronous data synchronization.

---

## **1\. Executive Summary**

* **Keep PostgreSQL** for flexibility, developer velocity, and professional maintainability.  
* **Replace always-on clusters** (EKS/ACK, RDS) with modern, scalable alternatives:  
  * **Compute**: AWS App Runner (global), Alibaba SAE or Function Compute (China).  
  * **Edge Ingress**: Cloudflare Workers (global thin proxy), Alibaba API Gateway (China).  
  * **Databases**: Neon (Serverless PostgreSQL, global) and ApsaraDB for PostgreSQL (China).  
  * **Data Sync**: Asynchronous, event-driven synchronization (SQS on AWS, MNS/RocketMQ on Alibaba).  
* **Formalize secrets management** with cloud-native Secrets Managers.  
* **Roll out in two phases**: Migrate the global stack first, then add the China region and synchronization.

---

## **2\. Phased Rollout Plan**

### **Phase 1: Migrate the Global Stack (AWS)**

* **Compute**:  
  * Deploy existing Go microservices (Auth, Catalog, Order, User) as containerized services on **AWS App Runner**.  
* **Database**:  
  * Use **Neon (Serverless PostgreSQL)** for the global database.  
  * Update service configuration to point to Neon, with credentials fetched via **AWS Secrets Manager** at runtime.  
* **Ingress**:  
  * Implement a **Cloudflare Worker** as a thin HTTPS proxy to the App Runner services (no business logic initially).  
* **Outcome**:  
  * EKS and RDS (global) are decommissioned.  
  * Lower operational cost, simpler ops, and the same business capabilities are maintained for non-China users.

### **Phase 2: Add China Region \+ Synchronization**

* **Compute**:  
  * Deploy the same Go services in Alibaba Cloud using **Serverless App Engine (SAE)** for long-running containers, or Function Compute (containers) if appropriate.  
* **Database**:  
  * Provision **ApsaraDB for PostgreSQL** (e.g., in cn-shanghai) and configure services.  
* **Ingress**:  
  * Use **Alibaba API Gateway** to route traffic to the SAE/Function Compute services.  
* **Synchronization**:  
  * Implement asynchronous, cross-region data sync:  
    * **AWS → CN**: SQS \+ a small "sync-out" worker → calls a CN API endpoint → upserts into ApsaraDB.  
    * **CN → AWS**: MNS/RocketMQ \+ a "sync-out" function → calls an AWS API endpoint → upserts into Neon.  
* **Outcome**:  
  * Region-local data is established for performance and compliance.  
  * Event-driven sync provides global data consistency.

---

## **3\. Definitive Technology Stack**

* **Frontend (Mobile App)**: Flutter (iOS/Android single codebase)  
* **Admin Panel**: React \+ MUI  
* **Backend Language/Framework**: Go (Gin), HTTP JSON APIs  
* **Containerization**: Docker  
* **Compute (Global)**: AWS App Runner  
* **Compute (China)**: Alibaba Serverless App Engine (SAE) or Function Compute (containers)  
* **Edge Ingress**:  
  * **Global**: Cloudflare Workers (thin proxy)  
  * **China**: Alibaba API Gateway (HTTPS)  
* **Databases (Relational SQL)**:  
  * **Global**: Neon (PostgreSQL)  
  * **China**: ApsaraDB for PostgreSQL  
* **Data Sync & Messaging**:  
  * **AWS**: SQS (Simple Queue Service)  
  * **Alibaba Cloud**: MNS (Message Service) or RocketMQ  
* **Secrets & Config**:  
  * **AWS**: AWS Secrets Manager (fetched via IAM role at runtime)  
  * **Alibaba Cloud**: KMS/Secrets Manager equivalent (fetched via RAM roles)  
* **Observability**:  
  * **AWS**: CloudWatch (Logs, Metrics), X-Ray (optional)  
  * **Alibaba**: Log Service (SLS), CloudMonitor  
  * **Cloudflare**: Request Logs & Analytics  
* **DNS & Routing**:  
  * AWS Route 53 with geolocation policies.  
* **CI/CD & IaC**:  
  * **CI/CD**: GitHub Actions (build, test, containerize, push, deploy)  
  * **IaC**: Terraform (AWS \+ Alibaba providers)

---

## **4\. Core Architecture**

### **4.1 Request Flow (Global)**

Client → Cloudflare Worker (HTTPS) → App Runner service (e.g., Catalog) → Neon (PostgreSQL)

* The worker acts as a thin, secure proxy.  
* App Runner scales automatically, removing cluster management overhead.

### **4.2 Request Flow (China)**

Client → Alibaba API Gateway (HTTPS) → SAE/Function Compute service → ApsaraDB for PostgreSQL

* SAE is recommended for service parity with App Runner's model.

### **4.3 Data Synchronization**

* **Event Source**: After a successful DB commit, the application publishes a minimal change event.  
* **AWS → CN**: Go service → SQS → Sync Worker (Lambda/App Runner) → Calls CN API → Writes to ApsaraDB.  
* **CN → AWS**: Go service → MNS/RocketMQ → Sync Worker (FC/SAE) → Calls AWS API → Writes to Neon.  
* **Conflict Resolution**: Use updated\_at timestamps (last-writer-wins) or domain-specific rules.

---

## **5\. Service Responsibilities**

* **Auth Service**: Manages passwordless flow, JWT issuance/validation.  
* **Catalog Service**: Manages categories, products, and store definitions.  
* **Order Service**: Manages carts and orders.  
* **Inventory/Notification Services**: As defined previously, scoped by region.

All services remain stateless HTTP JSON servers and use the region-local PostgreSQL repository. They are responsible for emitting events upon state changes to trigger synchronization.

---

## **6\. Secrets & Configuration**

* **Global (AWS)**: Store DB credentials in AWS Secrets Manager. App Runner services are granted an IAM role to retrieve secrets at runtime.  
* **China (Alibaba)**: Use Alibaba Secrets Manager with RAM roles for SAE/Function Compute. The same retrieval and short-term caching pattern applies.

---

## **7\. CI/CD and IaC**

* **IaC (Terraform)**: Define all infrastructure resources (App Runner, SQS, SAE, MNS, IAM/RAM roles, DNS) as code for consistency and repeatability.  
* **CI/CD (GitHub Actions)**: Create workflows to lint, test, build Go binaries, create Docker images, push to registries (ECR for AWS, ACR for Alibaba), and trigger deployments to App Runner and SAE.

---

## **8\. Observability & Reliability**

* **Logging**: Use structured JSON logs in all services for easier parsing and searching.  
* **Metrics**: Monitor basic endpoint metrics (latency, error rate, throughput) and key business metrics (e.g., orders per hour).  
* **Tracing**: Optionally implement distributed tracing (e.g., OpenTelemetry) and propagate correlation IDs through all services via headers.  
* **Health Checks**: Leverage built-in health checks from App Runner and SAE.  
* **Backups**: Configure automated backup policies for Neon and ApsaraDB.

---

## **9\. Security**

* **Transport**: Enforce HTTPS everywhere with HSTS at the edge.  
* **Authentication**: Continue using the JWT-based pattern.  
* **Authorization**: Implement role-based checks within services.  
* **Rate Limiting**: Use Cloudflare and Alibaba API Gateway for basic IP-based rate limiting.  
* **Secrets**: Strictly avoid plaintext secrets in code or environment variables. Always use a secrets manager.  
* **Database Access**: Restrict network access to the databases from only the necessary application sources.

---

## **10\. DNS & Routing**

* **Route 53**:  
  * device-api.madeinworld.com → Geolocation policy → Points to Cloudflare Worker (Global).  
  * device-api-cn.madeinworld.com → Geolocation policy (for China) → Points to Alibaba API Gateway.  
* **Client Configuration**: Clients in China should be configured to use the device-api-cn endpoint for optimal latency.

---

## **11\. Reference Code Snippets**

### **Thin Cloudflare Worker Proxy**

JavaScript

export default {  
  async fetch(request) {  
    const url \= new URL(request.url);  
    // Replace with your App Runner service hostname  
    url.hostname \= "your-app-runner-service.awsapprunner.com";

    // Attach a correlation ID for tracing  
    const headers \= new Headers(request.headers);  
    headers.set("x-correlation-id", crypto.randomUUID());

    return fetch(url.toString(), {  
      method: request.method,  
      headers,  
      body: request.body,  
      redirect: "follow",  
    });  
  }  
}

### **Publish Event to SQS (Go)**

Go

import (  
    "context"  
    "encoding/json"  
    "time"  
    "github.com/aws/aws-sdk-go-v2/service/sqs"  
    "github.com/aws/aws-sdk-go-v2/aws"  
)

type ProductUpdatedEvent struct {  
    ID        string    \`json:"id"\`  
    UpdatedAt time.Time \`json:"updated\_at"\`  
}

// publishProductUpdated sends an event to SQS after a successful DB write.  
func publishProductUpdated(ctx context.Context, sqsClient \*sqs.Client, queueURL string, event ProductUpdatedEvent) error {  
    body, err := json.Marshal(event)  
    if err \!= nil {  
        return err // Should not happen with this struct  
    }

    \_, err \= sqsClient.SendMessage(ctx, \&sqs.SendMessageInput{  
        QueueUrl:    aws.String(queueURL),  
        MessageBody: aws.String(string(body)),  
    })  
    return err  
}

---

## **12\. Migration Notes**

* **Database Schema**: Keep the existing schema; simply point services to the new Neon/ApsaraDB instances.  
* **Business Logic**: Do not move business logic into edge workers initially. Keep them as thin, reliable proxies.  
* **Rollout Order**: Finalize and stabilize the AWS global rollout before introducing the complexity of the China region and data synchronization.  
* **IaC First**: Adopt Terraform from the start to ensure all environments are reproducible and manageable.
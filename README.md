# MasterThesis_AccessControlModels

This project implements and evaluates three authorization models within a shared Zero Trust-style architecture:

- Role-Based Access Control (RBAC)
- Attribute-Based Access Control (ABAC)
- Relationship-Based Access Control (ReBAC)

The goal of the experiment is to compare the models under equivalent access control scenarios while keeping the surrounding architecture constant. All models are implemented using Open Policy Agent (OPA), and requests are enforced through Envoy using an external authorization adapter.

---

# Architecture

The experimental pipeline is:

```text
Client / k6 / curl
        |
        v
Envoy Proxy
        |
        v
Authorization Adapter
        |
        v
Open Policy Agent (OPA)
        |
        v
Allow / Deny decision
        |
        v
Protected Backend
```

The setup reflects a Zero Trust-inspired authorization architecture where every request must be explicitly evaluated before access is granted.

---

# Technologies Used

- Open Policy Agent (OPA)
- Envoy Proxy
- Python Flask
- Docker
- Docker Compose
- k6
- Rego Policy Language

---

# Project Structure

```text
.
├── adapter/                
|   ├── auth_server.py      # Flask authorization adapter
|   ├── Dockerfile
|   └── requirements.py
├── envoy.yaml              # Envoy configuration
├── docker-compose.yml      # Container orchestration
├── opa/
│   ├── policy.rego         # Authorization policies
│   └── data.json           # Scenario data
├── k6-level1.js            # k6 performance tests
├── k6-level2.js
├── k6-level3.js
├── k6-level3.js
├── measure-opa.ps1        # Automated measurement script
├── .env                    # Environment containing level and model
├── example-input.json
└── README.md
```

---

# Requirements

The following software is required:

- Docker
- Docker Compose
- k6
- PowerShell (Windows)

Example versions used in the thesis experiments:

- Docker v29.2.1
- Docker Compose v5.1.0
- Envoy v1.30.11
- OPA v1.5.1
- k6 v1.7.1

---

# Running the System

Start the full experimental environment using Docker Compose:

```powershell
docker compose up --build
```

The following services will start:

| Service | Port |
|---|---|
| Envoy | 10000 |
| Envoy Admin | 9901 |
| Authorization Adapter | 9000 |
| OPA | 8181 |

---

# Sending Test Requests

## Simple Request

Example allow request:

```powershell
curl.exe -i http://localhost:10000/anything `
  -H "x-user-id: anne" `
  -H "x-action: write" `
  -H "x-resource-id: doc1"
```

Example deny request:

```powershell
curl.exe -i http://localhost:10000/anything `
  -H "x-user-id: bob" `
  -H "x-action: write" `
  -H "x-resource-id: doc1"
```

---

# Context-Aware Requests (Level 4)

Level 4 introduces contextual constraints such as time and location.

Example valid request:

```powershell
curl.exe -i http://localhost:10000/anything `
  -H "x-user-id: managerAll" `
  -H "x-action: read" `
  -H "x-resource-id: docD4" `
  -H "x-time: 10:00" `
  -H "x-location: office"
```

Example invalid request:

```powershell
curl.exe -i http://localhost:10000/anything `
  -H "x-user-id: managerAll" `
  -H "x-action: read" `
  -H "x-resource-id: docD4" `
  -H "x-time: 20:00" `
  -H "x-location: home"
```

---

# Selecting Authorization Model

The active authorization model is selected using the `AUTH_MODE` environment variable.

Supported values:

- `rbac`
- `abac`
- `rebac`

Example:

```powershell
$env:AUTH_MODE="abac"
docker compose up --build
```

---

# Selecting Scenario Level

The active test scenario is selected using the `TEST_LEVEL` environment variable.

Supported values:

- `level1`
- `level2`
- `level3`
- `level4`

Example:

```powershell
$env:TEST_LEVEL="level4"
docker compose up --build
```

---

# Running k6 Performance Tests

Example:

```powershell
k6 run .\k6-level4.js
```

The tests send repeated authorization requests through the full pipeline and collect:

- Median latency
- P95 latency
- Throughput
- Success rate

---

# Running Policy Evaluation Measurements

The repository includes a PowerShell script for measuring OPA policy evaluation time directly. This script sends repeated requests to OPA with metrics enabled and reports the average, median, and P95 policy evaluation time.

## Example request

```powershell
.\measure-opa.ps1 `
  -User anne `
  -Action write `
  -Resource doc1 `
  -Model rbac `
  -Level level1 `
  -Iterations 100
```
---

# Experimental Design

The experiment compares equivalent authorization scenarios across all models while keeping these constant:

- The proxy
- The adapter
- The request format
- The backend
- The infrastructure

This ensures that observed differences are caused by the authorization model itself rather than unrelated system differences.

---

# Scenario Levels

## Level 1
Direct document permissions.

## Level 2
Project-scoped collaboration.

## Level 3
Cross-project managerial access.

## Level 4
Zero Trust-style least-privilege policies with:

- Classification levels
- Explicit exceptions
- Context-aware constraints
- Cross-project collaboration
- Restricted manager access

---

# Notes

- All authorization decisions are evaluated externally through OPA.
- Envoy acts as the Policy Enforcement Point (PEP).
- The Flask adapter acts as the translation layer between Envoy and OPA.
- The protected backend is intentionally simple to isolate authorization behavior.

---

# Appendix / Thesis Material

The repository contains:

- Full Rego policies
- Docker Compose configuration
- k6 test scripts
- Measurement automation scripts

---

# License

This repository was created as part of a Master's thesis project focused on authorization models and Zero Trust architectures.

# Document Processing Service

## Overview

The Document Processing Service is responsible for classifying and extracting data from uploaded documents using AWS Textract and regex-based classification. It uses [Temporal](https://temporal.io/) for workflow orchestration and is containerized using Docker for ease of deployment.

### Features

- **Document Upload and Classification**: Supports PDF, scanned PDFs,Excels,Csv and image formats.
- **OCR for Images**: Uses AWS Textract to extract text from image-based documents.
- **Deterministic Classification**: Uses pdftotext for text extraction and regex for document type classification.
- **Fallback to LLM**: For unknown document types, it sends extracted text to a language model (e.g., GPT) for classification.
- **Scalable Workflow Management**: Temporal is used to manage workflow execution, retries, and scalability.

## Technologies Used

- **Python**: Core logic for document processing and classification.
- **Temporal**: Workflow orchestration and management.
- **AWS Textract**: Extracts text from scanned PDFs or images.
- **Boto3**: Interface with AWS services such as S3 and Textract.
- **Docker**: Containerization of the service.
- **Kubernetes**: (Optional) To orchestrate and manage Docker containers in a scalable way.
- **Django Rest Framework**: for building REST API endpoints for interaction with the service.

## Prerequisites

1. Python 3.9+
2. Docker and Docker Compose
3. AWS Account with access to S3 and Textract (with `boto3` configured)
4. Temporal server running locally or in a cloud environment

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/document-processor-service.git
cd doc_processing_service
```

### 2. Install Dependencies
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Configure AWS Credentials
```bash
aws configure
```

### 4. Start the Temporal Server
```bash
docker run --rm -d -p 7233:7233 --name temporal-server --network=host temporalio/auto-setup:0.29.0
```

### 5. Start the Document Processing Service
```bash
python manage.py runserver
```

### 6. Start the Document Processing Service Temporal Worker
```bash
python manage.py start_temporal_worker
```

### 7. Test the Service
```bash
curl -X POST 'http://localhost:8000/upload/' \
--form 'file=' \
--form 'product="ITR"' \
--form 'scope="example_scope"' \
--form 'section="example_section"' \
--form 'password="example_password"'
```

### Docker Deployment

1. Build the Docker Image
```bash
docker compose build
```

2. Run Docker Compose
```bash
docker-compose up
```

### Accessing the Temporal Web UI

The Temporal Web UI can be accessed at http://localhost:8080, which helps track workflows and tasks.

## Workflow Execution Flow

1. **User Uploads Document**: The user uploads a document through an API or UI.
2. **Temporal Workflow Initiated**: Temporal manages the classification and processing workflow for the uploaded document.
3. **Document Classification**: The document is classified using pdftotext, regex, and fallback LLM models.
4. **Data Extraction**: AWS Textract is used for image-based documents or OCR-required PDFs.
5. **Result Notification**: The classification result and extracted data are stored and returned to the ITR service for further processing.
6. **AWS S3 and Textract Integration**
7. The service uploads documents to S3 and uses AWS Textract for OCR. Ensure that your AWS credentials have access to S3 and Textract.
8. **Kubernetes Deployment (Optional)**
9. To deploy the service using Kubernetes, use the provided deployment.yaml file in the k8s directory. Apply the file using kubectl:
```bash
kubectl apply -f k8s/deployment.yaml
```








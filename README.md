# EKS Infrastructure with Terraform

## 개요
Terraform을 사용하여 AWS EKS를 프로비저닝하고 Spring Boot 애플리케이션을 배포하는 프로젝트입니다.

## 주요 구성 요소

### 1. AWS 인프라스트럭처
- VPC 생성 및 설정
  - VPC 이름: jw-eks-vpc
  - CIDR: 10.21.0.0/16
  - AZ: ap-northeast-2a, ap-northeast-2c
  - 공용 서브넷: 10.21.0.0/24, 10.21.1.0/24
  - 프라이빗 서브넷: 10.21.32.0/24, 10.21.33.0/24
  - NAT Gateway 설정
  - DNS 설정
- EKS 클러스터
  - 클러스터 이름: jw-eks-cluster
  - Kubernetes 버전: 1.32
  - 멀티 AZ 구성
  - 관리형 노드 그룹
    - 인스턴스 타입: t3.medium
    - 노드 수: 2개 (min:2, max:2)
  - IAM 인증 설정

### 2. Spring Boot 애플리케이션 배포
- Docker 이미지
  - 저장소: [djdlzl/spring-repo](https://hub.docker.com/r/djdlzl/spring-repo)
  - 태그: latest
- Kubernetes Deployment
  - 2개의 복제본
  - AZ별 노드 선호도 설정
  - 리소스 제한
- Ingress 설정
  - ALB를 통한 외부 접근

## 요구사항
- Terraform 1.0 이상
- AWS CLI
- kubectl
- AWS 계정 권한

## 사용 방법

### 1. 환경 설정
```bash
# AWS 자격 증명 설정
aws configure

# Terraform 초기화
terraform init
```

### 2. 변수 설정
`variables.tf` 파일을 통해 다음 변수들을 설정해야 합니다:
- region
- vpc_name
- vpc_cidr
- availability_zones
- public_subnet_cidrs
- private_subnet_cidrs
- eks_cluster_name
- eks_cluster_version
- node_instance_type
- node_desired_size
- node_min_size
- node_max_size

### 3. 인프라 생성
```bash
terraform plan
terraform apply
```

### 4. Spring Boot 애플리케이션 배포
```bash
# kubectl 설정
aws eks update-kubeconfig --name <cluster-name>

# 애플리케이션 배포
kubectl apply -f *.yaml
```

## 참고사항
- NAT는 각 AZ에 1대씩, 총 2대 생성됩니다.
- Private Subnet은 각 AZ의 NAT를 통해 아웃바운드 통신이 가능합니다.
- EKS Node는 AZ에 1대씩 프로비저닝 됩니다.
- Spring Boot 애플리케이션은 각 AZ에 분산되어 배포됩니다.

## Destroy 시
- Ingress로 생성된 ALB, SG를 삭제 후 Terraform destroy 명령어를 실행해주세요.
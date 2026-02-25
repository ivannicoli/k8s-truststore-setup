# 🛡️ Teste de Certificados em Kubernetes (Java/WildFly)

Este projeto fornece um ambiente de teste controlado para validar a importação, consolidação e o uso de certificados SSL/TLS (Truststore) em aplicações Java rodando no Kubernetes.

---

## 🛠️ Pré-requisitos (Opcional: Minikube)

Se você não tem um cluster Kubernetes pronto, pode subir um localmente usando o Minikube:

```bash
# Baixar o binário
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64

# Instalar
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Iniciar o cluster
minikube start
```

---

## 📂 Estrutura do Projeto

A estrutura foi organizada seguindo boas práticas de infraestrutura como código (IaC):

```
.
├── certs/                      # Certificados brutos (não usados diretamente pelo K8s)
│   ├── base-truststore.jks     # JKS original base
│   ├── httpbin-org.pem         # Certificado PEM do httpbin.org
│   └── postman-echo-com.pem    # Certificado PEM do postman-echo.com
├── manifests/                  # Recursos do Kubernetes
│   ├── secret-truststore.yaml  # Secret contendo todos os certificados
│   └── pod-wildfly.yaml        # Pod de teste (WildFly)
├── scripts/                    # Automação
│   └── setup-truststore.sh     # Script que faz o merge dos certificados
└── README.md                   # Documentação
```

---

## 🚀 Passo a Passo para Execução

### 1. Preparar o Ambiente
Primeiro, crie o namespace e suba os recursos no Kubernetes:

```bash
# 1. Criar o namespace
kubectl create ns myns

# 2. Criar o Secret (contém os arquivos binários e PEMs)
kubectl apply -f manifests/secret-truststore.yaml

# 3. Criar o Pod do WildFly
kubectl apply -f manifests/pod-wildfly.yaml
```

### 2. Injetar e Executar o Script
O script `setup-truststore.sh` consolidará os certificados dentro do volume montado:

```bash
# Copiar o script para dentro do Pod
kubectl cp scripts/setup-truststore.sh myns/mypod:/tmp/setup-truststore.sh

# Acessar o pod e executar o merge
kubectl exec -it mypod -n myns -- sh
cd /tmp
sh setup-truststore.sh
```

---

## ⚙️ Como funciona a Consolidação?

O script `setup-truststore.sh` realiza os seguintes passos:

1.  **Isolamento:** Cria `/tmp/certsfinal` para trabalhar (o volume original `/tmp/certs` é Read-Only).
2.  **Base JKS:** Importa o `base-truststore.jks` (se existir no Secret) para a nova Truststore.
3.  **Merge Dinâmico:** Varre todos os arquivos `.pem` no volume, gera um alias amigável e os importa para o JKS final usando a senha padrão (`ChangeIt123!`).
4.  **Auditoria:** Lista todos os certificados presentes na Truststore final para validação.

---

## 🔍 O que está sendo validado?

*   ✅ **Mounting:** Verificação da correta montagem de arquivos binários e texto via Secrets.
*   ✅ **Keytool Compatibility:** Validação de que o Java Keytool consegue ler e mesclar os certificados injetados.
*   ✅ **Alias Sanitization:** Garantia de que nomes de arquivos com caracteres especiais não quebrem a importação.
*   ✅ **Trust Chain:** Preparação do ambiente para que a aplicação Java confie nas CAs fornecidas.

---

## 🛠️ Dicas de Depuração

### Verificar conteúdo do Secret:
```bash
kubectl get secret truststore.jks -n myns -o yaml
```

### Testar conexão HTTPS manual (dentro do pod):
```bash
kubectl exec -it mypod -n myns -- curl -v https://httpbin.org/get
```
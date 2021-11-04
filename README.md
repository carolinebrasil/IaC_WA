# IaC_WA

Pré-requisitos 

- Configurar as credenciais da conta AWS

```
export AWS_ACCESS_KEY_ID="Adicione a sua access key ID"
export AWS_SECRET_ACCESS_KEY="Adicione a sua secret key ID"
export AWS_REGION="Adicione a região de sua preferência nessa demo usaremos us-west-2" 
export AWS_DEFAULT_REGION="Adicione a região de sua preferência nessa demo usaremos us-west-2"
```


- Iniciando a configuração do backend do Terraform (arquivo de estado usado pelo TF para salvar os recursos configurados na AWS)

``` bash
cd backend
terraform init
```
- Montando o plano de configuração 

``` bash
terraform plan -out backend-demo-iac \
 -var="state_bucket_name=iac-wa-state-bucket" \
 -var="state_lock_table_name=iac-wa-tf-lock-table"
```
- Aplicando o plano de configuração 

``` bash
terraform apply "backend-demo-iac"
```

Arquitetura proposta

![lab](https://github.com/carolinebrasil/IaC_WA/blob/main/images/arch.jpeg?raw=true)

Iniciando a configuração com infra as code

``` bash
terraform init -backend=true -backend-config key="iac_wa.tfstate" -backend-config bucket="iac-wa-state-bucket" -backend-config dynamodb_table="iac-wa-tf-lock-table"
```

``` bash
terraform plan -out iac_wa

terraform apply "iac_wa"
```

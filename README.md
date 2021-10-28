# IaC_WA

Pré-requisitos 

- Configurar as credenciais da conta AWS

```
export AWS_ACCESS_KEY_ID="Adicione a sua access key ID"
export AWS_SECRET_ACCESS_KEY="Adicione a sua secret key ID"
export AWS_REGION="Adicione a região de sua preferência nessa demo usaremos us-east-1" 
export AWS_DEFAULT_REGION="Adicione a região de sua preferência nessa demo usaremos us-east-1"
```


- Iniciando a configuração do backend do Terraform (arquivo de estado usado pelo TF para salvar os recursos configurados na AWS)

``` bash
cd bootstrap
terraform init
```
- Montando o plano de configuração 

``` bash
terraform plan -out demo-iac \
 -var="state_bucket_name=demo-iac-state-bucket"
 -var="state_lock_table_name=demo-iac-tf-lock-table"
```
- Aplicando o plano de configuração 

``` bash
terraform apply "demo-iac"
```
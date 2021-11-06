# IaC_WA

### Pré-requisitos 

- Configure as suas credenciais da conta AWS e [SSH key](https://www.ssh.com/academy/ssh/keygen)

  ```
  export AWS_ACCESS_KEY_ID="Adicione a sua access key ID"
  export AWS_SECRET_ACCESS_KEY="Adicione a sua secret key ID"
  ```
  - Adicione a região de sua preferência, nesse exemplo usamos us-west-2
  
  ```
  export AWS_REGION="us-west-2" 
  export AWS_DEFAULT_REGION="us-west-2"
  ```

- Altere o caminho da sua chave pública no arquivo variable .tf
    ```
    variable "key_path" {
      description = "SSH key to access ec2 instances"
      default     = "/users/caroline/.ssh/id_rsa.pub"
    }
    ```
---
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

  -----


### Arquitetura proposta



  ![lab](https://github.com/carolinebrasil/IaC_WA/blob/main/images/arch.jpeg?raw=true)

- Iniciando a configuração com infra as code

  ``` bash
  terraform init \
  -backend=true -backend-config key="iac_wa.tfstate" \
  -backend-config bucket="iac-wa-state-bucket" \ 
  -backend-config dynamodb_table="iac-wa-tf-lock-table"
  ```
- Executando o plan e apply para implantação da infra

  ``` bash
  terraform plan -out iac_wa

  terraform apply "iac_wa"
  ```

# Atividade da trilha DevSecOps AWS/Docker

Atividade com a finalidade de fixar os conhecimentos de AWS (Amazon Web Services) e Docker, feita no programa de bolsas da Compass Uol e na trilha DevSecOps.

Atividade realizada por: [Maria Isadora](https://github.com/mariaisadora-github)

# Sobre a atividade
## Requisitos

- Instalação e configuração do DOCKER ou CONTAINERD no host EC2;
- Ponto adicional para o trabalho utilizar a instalação via script de Start Instance (user_data.sh)
- Efetuar Deploy de uma aplicação Wordpress com container de aplicação RDS database Mysql
- Configuração da utilização do serviço EFS AWS para estáticos do container de aplicação Wordpress
- Configuração do serviço de Load Balancer AWS para a aplicação Wordpress

## Pontos de atenção

- Não utilizar ip público para saída do serviços WP (Evitar publicar o serviço WP via IP Público)
- Sugestão para o tráfego de internet sair pelo LB (Load Balancer Classic)
- Pastas públicas e estáticos do wordpress sugestão de utilizar o EFS (Elastic File Sistem)
- Fica a critério de cada integrante (ou dupla) usar Dockerfile ou Dockercompose;
- Necessário demonstrar a aplicação wordpress funcionando (tela de login)
- Aplicação Wordpress precisa estar rodando na porta 80 ou 8080;
- Utilizar repositório git para versionamento;
- Criar documentação

# Configuração da VPC

+ Acesse o console da AWS e entre na sua conta, no painel de controle, clique em "Services" e selecione "VPC".
+ No painel de Navegação do lado esquerdo, clique em "Your VPCs", feito isso, clique em criar VPC.

## Subnets

+ Após criar a VPC, no painel de navegação, vá em "Subnets" e crie ao menos duas em pelo ou menos duas zonas distintas.
  + No caso, eu criei três subnets privadas e três subnets públicas. Sendo uma pública e uma privada em cada zona de disponiblidade. Então ficou da seguinte forma:
    + Subnets Privadas
      + `Nome: subnet-ativ02-private1`
        + `Zona de disponibilidade: us-east-1a`
      + `Nome: subnet-ativ02-private2`
        + `Zona de disponibilidade: us-east-1b`
      + `Nome: subnet-ativ02-private3`
        + `Zona de disponibilidade: us-east-1c`

    + Subnets Públicas
      + `Nome: subnet-ativ02-public1`
        + `Zona de disponibilidade: us-east-1a`
      + `Nome: subnet-ativ02-public2`
        + `Zona de disponibilidade: us-east-1b`
      + `Nome: subnet-ativ02-public3`
        + `Zona de disponibilidade: us-east-1c`

## Tabela de rotas

Crie duas tabelas de rotas, uma para as subnets privadas e outra para as subnets públicas.

+ No painel de navegação, vá em "Route tables" e crie as duas tabelas de rotas, vale ressaltar que as databelas de rotas devem ser criadas na VPC que foi criada anteriormente.
+ Após criar as tabelas de rotas deverá associas subnets as tabelas, para realizar isso, faça o seguinte passo:
  + Selecione a tabela de roteamento, siga para associações de subnets e selecione "Editar associações". Após isso, selecione as subnets privadas e clique "salvar".
  + Selecione a tabela de roteamento, siga para associações de subnets e selecione "Editar associações". Após isso, selecione as subnets públicas e clique "salvar".

Após criar as tabelas de rotas e associar as subnets a elas, deve-se criar os Gateways e depois associá-los as tabelas de rotas.

## Gateways

+ No painel de navegação, vá em "Internet gateways" e crie o mesmo.
+ No painel de navegação, vá em "NAT gatways" e crie o mesmo.

+ Após criar os gateways, volte para as tabelas de rotas e faça os seguintes passos:
  + Selecione a tabela de roteamento criada para as subnets públicas, siga para rotas e selecione "Editar rotas". Após isso, selecione "adicionar rotas" e preencha:
    
    Destino    | Alvo 
     ---       |  --- 
     0.0.0.0/0 | gateway da internet
  
    + Selecione a tabela de roteamento criada para as subnets públicas, siga para rotas e selecione "Editar rotas". Após isso, selecione "adicionar rotas" e preencha:

    Destino    | Alvo 
     ---       |  --- 
     0.0.0.0/0 | Nat gateway


## O mapeamento da minha VPC

<div align="center">
  <img src="/images/VPC.png" alt="VPC" width="850px">
   <p><em>Mapa da VPC </em></p>
</div>

# Configuração dos Security Groups

Configurei quatro grupos de segurança, sendo eles:

<div align="center">
  <img src="/images/SG.png" alt="security groups" width="850px">
   <p><em>Security Groups </em></p>
</div>

As portas de entrada estão configuradas da seguinte forma: 

+ `Um grupo de segurança para o bastion host e o ELB - SG-Public`
   Porta | Tipo | Protocolo | Origem
   --- | --- | --- | ---
   80  | HTTP | TCP | 0.0.0.0/0
   tudo  | ICMP | ICMP | 0.0.0.0/0
   22  | SSH | TCP | 0.0.0.0/0

+ `Um grupo de segurança para as instâncias - SG-Private`
   Porta | Tipo | Protocolo | Origem
   --- | --- | --- | ---
   80  | HTTP | TCP | SG-Public
   22  | SSH | TCP | SG-Public

+ `Um grupo de segurança para o RDS - SG_RDS`
   Porta | Tipo | Protocolo | Origem
   --- | --- | --- | ---
   3306  | MYSQL/Aurora | TCP | SG-Private

+ `Um grupo de segurança para o EFS`
   Porta | Tipo | Protocolo | Origem
   --- | --- | --- | ---
   2209  | NFS | TCP | SG-Private

# Configuração do Elastic Load Balancer

Navegue até o serviço EC2.

Inicialmente será criado o grupo de destino e posteriormente o load balancer.

## Grupo de Destino

+ Criação do grupo de destino
    + `Tipo: instância`
    + `Nome: GD-ativ02`
    + `VPC: VPC criada anteriormente`
    + `Protocolo: http`

<div align="center">
  <img src="/images/GD.png" alt="Grupo de destino" width="850px">
   <p><em>Grupo de Destino </em></p>
</div>

## Load Balancer

+ Foi criado um Aplication Load Balancer, o mesmo tem a seguinte criação:
  + `Nome: LB-ativ02`
  + `Esquema: voltado pra internet`
  + `Tipo de endereço IP: IPv4`
  + `VPC: VPC criada anteriormente`
  + `Mapeamento:`
    + `us-east-1a`
    + `us-east-1b`
    + `us-east-1c`
  + `Grupo de segurança: SG-Public`
  + `Listeners:`
    + `Protocolo: http`
    + `Porta: 80`
    + `Ação Padrão: GD-ativ02`

<div align="center">
  <img src="/images/LB.png" alt="Load balancer" width="850px">
   <p><em>Aplication Load Balancer </em></p>
</div>
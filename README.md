# Manage Oracle Cloud Infrastructure (Free Tier resources)

Manage OCI infrastructure free tier resources using Terraform/Tofu for automatic provsioning and Ansible for automatic configuration

## OCI Infra Provisioning

Using Terraform/Tofu Networking stack and Compute resources can be created
This configuration creates the following resources

-  Compartment
-  VCN
-  Internet Gateway
-  Public Subnet
-  Routing Table
-  Compute Resources

> **NOTE:**
>
> Free Tier Always free resources includes the following free compute resources
> - 2 AMD instances: 1 CPU/1GB RAM
> - Up to 4 CPUs/24GB RAM used across ARM instances
>   - 2 ARM instances with 2 CPUs /12 GB can be created

### Procedure

-   Clone repository
    ```shell
    git clone ricsanfre/oci-infra-provisioning
    ```
-   Install Terraform/Tofu

-   Move to terraform directory
    ```shell
    cd terraform
    ```
-   Configure OCI provider
    ```shell
    cp .env.tpl .env
    ```
    Edit .env file to add OCI oids and credentials

    ```
    # Export all variables to environment, so Terraform can use them
    set -a
    TF_VAR_tenancy_ocid=<your_tenancy_ocid>
    TF_VAR_user_ocid=<your_user_ocid>
    TF_VAR_fingerprint=<your_fingerprint>
    TF_VAR_private_key_path=<path_to_your_private_key>
    ```

-   Configure terraform variables. Editing `terraform/terraform.tfvars` file


    Default configuration:
    -   Creates `terraform` compartment
    -   Creates `vcn` VCN  10.0.0.0/16
    -   Creates `public` subnet 10.0.0.0/24
    -   Creates 4 compute instances: 2 AMD and 2 ARM all of them running Ubuntu-24.04 linux distribution 

    ```hcl
    compartment_name = "terraform"

    vcn_name       = "vcn"
    vcn_cidr_block = "10.0.0.0/16"

    subnet_config = {
      public = {
        cidr_block    = "10.0.0.0/24"
        public_subnet = true
        additional_tags = {
          Public = "True"
        }
      }
    }

    instances = {
      oci-arm-1 = {
        name          = "oci-arm-1"
        shape         = "VM.Standard.A1.Flex"
        ocpus         = 2
        memory_in_gbs = 12
        subnet_type   = "public"
        ssh_key_path  = "~/.ssh/id_rsa.pub"
      }
      oci-arm-2 = {
        name          = "oci-arm-2"
        shape         = "VM.Standard.A1.Flex"
        ocpus         = 2
        memory_in_gbs = 12
        subnet_type   = "public"
        ssh_key_path  = "~/.ssh/id_rsa.pub"
      }
      oci-amd-1 = {
        name          = "oci-amd-1"
        shape         = "VM.Standard.E2.1.Micro"
        ocpus         = 1
        memory_in_gbs = 1
        subnet_type   = "public"
        ssh_key_path  = "~/.ssh/id_rsa.pub"
      }
      oci-amd-2 = {
        name          = "oci-amd-2"
        shape         = "VM.Standard.E2.1.Micro"
        ocpus         = 1
        memory_in_gbs = 1
        subnet_type   = "public"
        ssh_key_path  = "~/.ssh/id_rsa.pub"
      }
    }
    ```

    > Note: It is assumed that private and public key have default names (id_rsa) and are located in default linux path "~/.ssh"

-   Before running any Tofu/Terraform command, load environment variables:

    ```shell
    source .env
    ```
    
-   Install and configure Terraform/Tofu OCI provider
    ```shell
    tofu init
    ```
-   Execute Plan
    ```shell
    tofu plan
    ```
-   Apply provisioning plan
    ```shell
    tofy apply
    ```

## OCI Compute Instances Configuration

Ansible is used to configure all servers running in OCI

### Procedure

-  Move to ansible directory
   ```
   cd ansible
   ```

-  Initialize ansible python virtual environment

   ```shell
   make init
   ```


## Configure Docker Swarm

### Enable Ingress traffic

By default all Linux OCI instances configures Iptables to allow only ssh Ingress traffic.

#### Default IPTable (fresh OCI instance)


```shell
ubuntu@oci-arm-1:~$ sudo iptables -L INPUT --line-numbers
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination         
1    ACCEPT     all  --  anywhere             anywhere             state RELATED,ESTABLISHED
2    ACCEPT     icmp --  anywhere             anywhere            
3    ACCEPT     all  --  anywhere             anywhere            
4    ACCEPT     tcp  --  anywhere             anywhere             state NEW tcp dpt:ssh
5    REJECT     all  --  anywhere             anywhere             reject-with icmp-host-prohibited
```

-   Only ingress traffic allowed is SSH.
-   New INPUT rules need to be placed before first REJECT rule (number 5)


#### Enable Docker Swarm traffic

##### Manual instructions

-  Edit file `/etc/iptables/rules.v4`

   Add following lines between line 4 (enabling ssh traffic) and 5 (rejecting icmp traffic)

   ```
   -A INPUT -p tcp -m tcp --dport 2376 -j ACCEPT
   -A INPUT -p tcp -m tcp --dport 2377 -j ACCEPT
   -A INPUT -p tcp -m tcp --dport 7946 -j ACCEPT
   -A INPUT -p udp -m udp --dport 7946 -j ACCEPT
   -A INPUT -p udp -m udp --dport 4789 -j ACCEPT
   ```

-  Apply the file

   ```shell
   sudo iptables-restore < /etc/iptables/rules.v4
   ```
##### Ansible automation

```shell
cd ansible
make configure-iptables
```


### Initialize Docker Swarm

-   Install Docker Engine in all servers

    ```shell
    cd ansible
    make configure-docker
    ```

-   Initialize Swarm cluster
   
    Connect to one of the servers:

    ```shell
    docker swarm init --advertise-addr <MANAGER-IP>
    ```

-   Join workers
    Connect to the other servers

    ```shell
    docker swarm join --token <token> <MANAGER-IP>:2377
    ```

### Create overlays networks

```shell
docker network create -d overlay --attachable frontend
docker network create -d overlay --attachable backend
```


## Docker Services

### Traefik

#### Deploy Traefik swarm

-   Connect to docker swarm manager node

-   Clone repository
    ```shell
    git clone ricsanfre/oci-infra-provisioning
    ```

-   Go to traefik stack directory

    ```shell
    cd docker-swarm/traefik
    ```

-   Deploy traefik stack service

    ```shell
    docker stack deploy -c compose.yaml traefik
    ```

-   Check docker stack services
    ```shell
    docker stack ps traefik
    ```

#### Real Client IP are not visible if using Swarm ingress network

Traefik need to listen on host ports without using Swarm ingress network
If not configured this way, real client IPs will not be visible to Traefik

See details in: https://community.traefik.io/t/how-to-obtain-the-real-ip-in-docker-swarm/27443

### MariaDB

#### Remote connection

Using another mariadb container

```shell
docker run -it --network backend --rm mariadb mariadb -h db --user=matomo --password=<password> matomo
```

#### MariaDB backup/restore

To backup
```shell
docker run -i --network backend --rm mariadb mariadb-dump -h db --user=matomo --password=<password> matomo > matomo-db-dump.sql
```

To restore

```shell
docker run -i --network backend --rm mariadb mariadb -h db --user=matomo --password=<password> matomo < matomo-db-dump.sql
```

### Traefik




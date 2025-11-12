# Manage Oracle Cloud Infrastructure (Free Tier resources)

Manage OCI infrastructure free tier resources using Terraform/Tofu for automatic provsioning and Ansible for automatic configuration

## OCI Resources Provisioning

Using Terraform/Tofu Networking stack and Compute resources can be created
This configuration creates the following resources

-  Compartment
-  VCN
-  Internet Gateway
-  Public Subnet
-  Routing Table
-  Compute Resources
   > Free Tier Always free resources includes
   > - 2 AMD instances
   > - Up to 4 CPUs/24GB RAM ARM instances
   >   - 2 ARM instance 2 CPUs /12 GB can be created


### Install procedure


-   Install Terraform/Tofu

-   Move to terraform directory
    ```shell
    cd terraform
    ```

-   Install and configure Terraform/Tofu OCI provider
    ```shell
    tofu init
    ```
-   Execute Plan
    ```shell
    tofu plan
    ```

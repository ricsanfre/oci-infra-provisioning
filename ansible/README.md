# OCI Provisioning Ansible

Applying configuration changes to OCI infrastructure


## Ansible virtual env installation procedure

-   Install UV package manager

-   Initialize ansible python virtual environmnet
    ```shell
    uv init
    ```
-   Install `ansible` package
    ```shell
    uv add ansible
    ```

##  Add ansible dependencies

-  Install ansible roles
   ```shell
   uv run ansible-galaxy role install -r requirements.yml --roles-path "./roles"
   ```

## Ansible playbook execution

-  Run ansible playbook
   ```shell
   uv run ansible-playbook <playbook_file>
   ```
Provision creates Ansible environment on `ansible-controller`. This environment is fully
functional with one exception: `/home/vagrant/host_vars/terraform.template` needs
to be renamed to `terraform.yml`. This is done intentionally to prevent accidental
damage to existing Terraform resources.

```shell
vagrant ssh ansible-controller
# [!!] Comment out unnecessary projects in terraform_projects variable.
#      (local_backend_path variable points to shared backend storage)
nano host_vars/terraform.template
# then rename vars file and double check the results
mv host_vars/terraform.template host_vars/terraform.yml
ansible -m debug -a "var=terraform_projects" terraform

ansible_playbook terraform_projects.yml -l terraform
```

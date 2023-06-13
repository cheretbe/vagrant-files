`local-config.yml` example:
```yaml
---

# Valid options are: "master", "develop", "local" (symlink to /host_home/projects/ansible-playbooks)
common_repo_source: develop # default is master

networks.client:
  - forwarded_port: {host: 8082, guest: 80}
  - forwarded_port: {host: 8083, guest: 443}
```

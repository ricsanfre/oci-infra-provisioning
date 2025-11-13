.PHONY: default os-upgrade init-virtualenv init-ansible configure-docker enable-https

init: init-ansible

init-virtualenv:
	uv sync

init-ansible: init-virtualenv
	uv run ansible-galaxy install -r requirements.yml -p roles/

os-upgrade:
	uv run ansible-playbook upgrade-os-packages.yml

enable-https:
	uv run ansible-playbook enable-incoming-https-traffic.yml

configure-docker:
	uv run ansible-playbook configure_docker.yml
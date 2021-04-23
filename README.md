# ambit-docker
This repo helps you test AMBIT on your machine or deploy it inside your organization. For more information on AMBIT and the eNanoMapper database, please see http://ambit.sourceforge.net/ and https://search.data.enanomapper.net/.


# Quick start
AMBIT with the freely available [NANoREG data](https://search.data.enanomapper.net/about/nanoreg/) in under 30 seconds:
1. [install Docker Compose](https://docs.docker.com/compose/install/) if you haven't already
1. `git clone https://github.com/ideaconsult/ambit-docker.git`
1. `cd ambit-docker`
1. `docker-compose up`
1. open http://127.0.0.1:8080/ambit
1. <kbd>Ctrl</kbd>+<kbd>C</kbd> in the console to stop it

# Possible problems
If you hit the Docker Hub pull limits, use [GitHub Container Registry](https://github.com/orgs/ideaconsult/packages). You'll need to edit the docker-compose files and prepend the `image` settings with `ghcr.io/`, e.g. `ideaconsult/ambit-db:latest` becomes `ghcr.io/ideaconsult/ambit-db:latest`.

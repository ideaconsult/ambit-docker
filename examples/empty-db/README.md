# Empty database
This example shows how to start AMBIT with an empty database, mainly for populating it with your own data or perhaps testing of the generic AMBIT functionality. Note that it also exposes the RDBMS port locally to allow, for example, importing data directly into the database.

# Quick Start
1. [Install Docker Compose](https://docs.docker.com/compose/install/) if you haven't already.
1. `git clone https://github.com/ideaconsult/ambit-docker.git`
1. `cd ambit-docker/examples/empty-db`
1. `docker-compose pull`
1. `docker-compose up`
1. Open http://127.0.0.1:8080/ambit in your browser.
1. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> in the console, where `docker-compose up` is running, to stop it.

See the main [README.md](../../README.md) for more information.
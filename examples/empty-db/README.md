# Empty database
This example shows how to start AMBIT with an empty database, with no data in it, mainly for populating the database with your own data or perhaps testing of the generic AMBIT functionality.

# Quick Start
1. [Install Docker Compose](https://docs.docker.com/compose/install/) if you haven't already.
1. `git clone https://github.com/ideaconsult/ambit-docker.git`
1. `cd ambit-docker/examples/empty-db`
1. `docker-compose pull`
1. `docker-compose up`
1. Open http://127.0.0.1:8080/ambit in your browser.
1. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> in the console, where `docker-compose up` is running, to stop it.

See the main [README.md](../../README.md) for more information.
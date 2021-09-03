# The Cefic-LRI cheminformatics tool
The [Cefic-LRI cheminformatics data management tool](http://cefic-lri.org/toolbox/ambit/). Note that **no data is included** and must be provided separately. If you are a Cefic member, you can download the data from the Cefic members extranet.

NB: The file containing the data is `echa_substance_food.sql.xz`.

# Quick Start
1. [Install Docker Compose](https://docs.docker.com/compose/install/) if you haven't already.
1. `git clone https://github.com/ideaconsult/ambit-docker.git`
1. `cd ambit-docker/examples/echa-reach`
1. Copy `echa_substance_food.sql.xz` to the `data_import` directory.
1. `docker-compose pull`
1. `docker-compose up`
1. Open http://127.0.0.1:8080/ambit in your browser.
1. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> in the console, where `docker-compose up` is running, to stop it.

See the main [README.md](../../README.md) for more information.
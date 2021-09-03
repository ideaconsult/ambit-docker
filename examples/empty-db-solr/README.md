# Empty database plus Solr
This builds upon the [empty database example](../empty-db/README.md) by adding a small [Apache Solr](https://solr.apache.org/) cluster for testing.

Add data in AMBIT at http://127.0.0.1:8080/ambit or directly import to the RDBMS, which is exposed on `127.0.0.1:3306`. Solr is accessible behind a [HAProxy](http://www.haproxy.org/) load balancer on http://127.0.0.1:8983/.

Consult the [Solr documentation](https://solr.apache.org/guide/about-this-guide.html) on how to upload data to Solr and send queries.

AMBIT specific documentation on working with Solr TBA.

# Quick Start
1. [Install Docker Compose](https://docs.docker.com/compose/install/) if you haven't already.
1. `git clone https://github.com/ideaconsult/ambit-docker.git`
1. `cd ambit-docker/examples/empty-db-solr`
1. `docker-compose pull`
1. `docker-compose up`
1. Open http://127.0.0.1:8080/ambit in your browser.
1. Open http://127.0.0.1:8983/ in your browser
1. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> in the console, where `docker-compose up` is running, to stop it.

See the main [README.md](../../README.md) for more information.
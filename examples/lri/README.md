# The Cefic-LRI cheminformatics tool
The [Cefic-LRI cheminformatics data management tool](http://cefic-lri.org/toolbox/ambit/). Note that **no data is included** and must be provided separately. If you are tasked with deploying the system, you will be provided with links to the required files.

## Quick Start
1. Make sure your Docker instance supports [Docker Compose](https://docs.docker.com/compose/install/).
1. `git clone https://github.com/ideaconsult/ambit-docker.git`
1. `cd ambit-docker/examples/lri`
1. Copy the provided data files to the `data_import` directory.
1. `docker compose pull`
1. `docker compose up`
1. The first run will require several minutes to initialize the databases. Wait for the message "LRI Solr is initialized successfully".
1. Open http://127.0.0.1:8080 in your browser.
1. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> in the console, where `docker-compose up` is running, to stop it.

See the main [README.md](../../README.md) for more information.

**NB**: If using older Docker versions, replace `docker compose` with `docker-compose`.

## Deployment notes

### Services

The following services, each running as a Docker container, comprise the complete system:
- `ui`: The web interface. Uses [Nginx](https://www.nginx.com/).
- `ambit`: The AMBIT application that handles the relevant API calls from the interface. Uses [Tomcat](https://tomcat.apache.org/).
- `toxpredict`: The Toxpredict application that handles the relevant API calls form the interface. Uses [GraalVM](https://www.graalvm.org/).
- `db`: The RDBMS backend. Uses [MariaDB](https://mariadb.org/).
- `solr{1,2,3}`: The free-text search engine. Uses [Solr](https://solr.apache.org/) in SolrCloud mode.
- `zk{1,2,3}`: The KV store for Solr configuration. Uses [ZooKeeper](https://zookeeper.apache.org/).
- `haproxy`: Handles all HTTP requests and redirects them to the appropriate backend. Uses [HAProxy](https://www.haproxy.org/).
- `solr-helper`: A helper service that runs only during the first startup to upload the necessary data to the Solr cluster.

### Data & backup

The system uses [named volumes](https://docs.docker.com/storage/volumes/) for persistent data:
- `db`: The RDBMS backend storage.
- `solr{1,2,3}`: The Solr persistent data.
- `zk{1,2,3}_*`: The ZooKeeper persistent data.
These volumes typically reside on UNIX systems in `/var/lib/docker/volumes`.

The Docker containers are, by themselves, stateless. All persistent data is recorded to the above volumes. This means that the containers can be removed or recreated at will and no data loss should occur as long as the volumes are kept intact. In particular, running `docker compose down` is safe. After the containers are recreated with `docker compose up`, the system should continue working as if no action had ever been taken.

If no data (e.g. user accounts, read across assessments) have been added or modified, running `docker compose down --volumes` or otherwise deleting the volumes is probably OK as well. In particular, the system can always be restored to its original, default, state by running `docker compose up` after all its previous containers and volumes have been removed. However, running `docker compose down --volumes` or otherwise deleting the service volumes will **DESTROY** all user data.

Different backup strategies can be used for the persistent data:
- The volumes typically reside on UNIX systems in `/var/lib/docker/volumes`. They are just directories, so any file backup solution should work on them. As usual, it's best to shut down all the services for the duration of the backup. This method should work universally for all services that use volumes.
- The RDBMS (MariaDB) can also be backed up with tools like `mysqldump`, e.g. `docker compose exec db mysqldump ...`. The databases that should be dumped are the ones from the `AMBIT_DATABASES` and `AMBIT_USERS_DB` variables in `ambit-config.env` (by default, these are `ambit_lri3` and `ambit_users`).
- The Solr and ZooKeeper data are not expected to change after deployment, so their backup is not critical, as they can always be restored to the original state.

**TL;DR**:
- The RDBMS is the key component that needs its data backed up.
- Either shut down the RDBMS and back up the directory of its volume or use tools like `mysqldump` to dump the databases.

In case the system needs to be recovered:
- Create the whole system anew (i.e. with all previous containers and volumes deleted) and wait for it to initialize fully.
- Depending on the backup method:
  - stop the RDBMS, copy back the `db` volume contents from backup, and start the RDBMS, or,
  - import the backed up databases to the RDBMS directly, e.g. `docker compose exec db mysql ambit_lri3 < backup_ambit_lri3.sql`.

**NB**: When running mysqldump or mysql with `docker exec`, you'll most likely need to provide appropriate credentials from `ambit-config.env`, e.g. `AMBIT_DB_USER` and `AMBIT_DB_PASS`.

### Configuration files and parameters

The main configuration file of the system is `ambit-config.env`. It is described in the main [README.md](../../README.md).

In a production deployment it is important to change `AMBIT_DB_PASS` and `MYSQL_ROOT_PASSWORD` from their default values **before the first run**. Changing these variables after the system has already been initialized will **not** automatically update the respective RDBMS passwords. If such change is required afterwards:
- update ambit-config.env
- recreate the `ambit` service container
- manually update the passwords in the RDBMS with e.g. https://mariadb.com/kb/en/set-password/

The Solr-specific options reside in `solr-config.env`. In production, the `AMBIT_SOLR_PASS` should be changed from the default **before the first run**. Changing this variable after the system has already been initialized will **not** automatically update the respective Solr password. If such change is required afterwards:
- update solr-config.env
- recreate the `ambit` service container
- restart the `toxpredict` service
- stop the solr* and zk* services, delete the solr* and zk* volumes, and recreate their containers

The ZooKeeper-specific options reside in `zoo-config.env`. These are provided for convenience and typically shouldn't need to be changed.

The HAProxy configuration resides in `haproxy.cfg`. It's the standard HAProxy configuration file that you may customize to suit your needs, but the default should work out of the box.

The Solr helper script config resides in `helper.conf`. No changes from default should be needed. For reference, the options are:
- `conf`: the name of the Solr configset used for the collection
- `col`: the name of the collection that **must** be the same as `AMBIT_COLLECTIONS` in solr-config.env
- `repl`: the number of replicas for the collection that should correspond to the number of solr* services (default is 3)
- `tmout`: number of seconds to wait for the Solr instances to become responsive during initialization
- `data_files`: an array containing the names of the compressed JSON files to import to Solr

**TL;DR**: Change `AMBIT_DB_PASS` and `MYSQL_ROOT_PASSWORD` in `ambit-config.env` and `AMBIT_SOLR_PASS` in `solr-config.env`. Do it **before the first run**!

### HTTPS

The default setup supports only plain (insecure) HTTP access to the web interface. If the system will be accessed from insecure networks, it is important to setup HTTPS access. There are many different ways to achieve this and a detailed explanation is beyond the scope of this document. The easiest way is to just use an existing HTTPS proxy. System-specific proxy can also be added, either by creating it from scratch (e.g. [1](https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71), [2](https://mindsers.blog/post/https-using-nginx-certbot-docker/), [3](https://www.programonaut.com/setup-ssl-with-docker-nginx-and-lets-encrypt/)) or by using pre-made solutions (e.g. [1](https://github.com/SteveLTN/https-portal), [2](https://github.com/evgeniy-khist/letsencrypt-docker-compose)).

### Updating

When newer versions of the services are released, you can fetch the new Docker images and update your instance with:
- `docker compose pull`
- `docker compose stop`
- `docker compose up --detach` (provided that you run the system detached from the terminal)

Typically, nothing else needs to be done. If any manual actions are needed, these will be specifically communicated together with the information about the update.

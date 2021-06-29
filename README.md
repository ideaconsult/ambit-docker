# ambit-docker
This repo helps you test AMBIT on your machine or deploy it inside your organization. For more information on AMBIT and the eNanoMapper database, please see http://ambit.sourceforge.net/ and https://search.data.enanomapper.net/.


# Quick start
AMBIT with the freely available [NANoREG data](https://search.data.enanomapper.net/projects/nanoreg/) and [NANoREG II data](https://search.data.enanomapper.net/projects/nanoreg2) in under 30 seconds:

1. [install Docker Compose](https://docs.docker.com/compose/install/) if you haven't already
1. `git clone https://github.com/ideaconsult/ambit-docker.git`
1. `cd ambit-docker`
1. `docker-compose up`
1. open http://127.0.0.1:8080/ambit (NANoREG) and http://127.0.0.1:8081/ambit (NANoREG II)
1. <kbd>Ctrl</kbd>+<kbd>C</kbd> in the console to stop it

**NOTE:**: These instances do **not** contain the data from the [eNanoMapper database](https://search.data.enanomapper.net/projects/enanomapper/).

# Other datasets
It is possible to set up AMBIT instances with other datasets as well.

1. Copy `docker-compose.yml` and `ambit-config.env` to a separate directory.
1. Create a `data_import` subdirectory within the new directory.
1. Set the options in the `ambit-config.env` file (or leave the defaults, especially if uncertain):
    1. `AMBIT_PROFILE`: Possible values: `enanomapper`, `lri`. Does **not** change the AMBIT behaviour or available features.
    1. `AMBIT_DATABASES`: Space-separated list of database names. For each name, there **must** be a corresponding [xz](https://en.wikipedia.org/wiki/XZ_Utils)-compressed SQL dump of the database placed in the `data_import` subdirectory, unless it's a publicly available database. For example, if this is set to `datasetA datasetB`, in the `data_import` subdirectory there must be files `datasetA.sql.xz` and `datasetB.sql.xz` containing the respective dumps. For publicly available datasets, you don't need to provide the SQL dumps yourself—they will be downloaded from the internet. Currently the following publicly available databases are recognized: `nanoreg1`, `nanoreg2`.
    1. AMBIT_AA_ENABLE: Possble values: `false`, `true`. Determines whether the web interface will require authentication. Note that unless you explicitly instruct Docker otherwise, the interface will be available only on your local system. So, authentication isn't strictly necessary if you are doing only testing and in these cases this setting can be left at `false`. If set to `true`, two default users are available in the web interface: `admin` and `guest` with their passwords the same as the username. This obviously is suitable only for testing and you should change the passwords if you plan to make the instance visible on the network or—even more so—on the internet. Note that these users and passwords are entirely **different** from the AMBIT_DB_USER and AMBIT_DB_PASS below. While the former are used by the users to access the web interface, the latter is an internal user that is used only by the system to connect to the database service.
    1. AMBIT_DB_HOST: DNS name of the database service. By default, it is set to the name of the database service from the `docker-compose.yml` file. You may provide the DNS name of an external RDBMS server, but please note that if you use such server, instead of the one run by Docker Compose, you will need to import all the databases and set all DB users manually (we may be able to provide custom support—for inquiries please write to support@ideaconsult.net).
    1. AMBIT_DB_USER: The name of the internal user that is used by the system to connect to the database service. For testing the default should be fine. In production environments, it may be advisable to change this to something more secure.
    1. AMBIT_DB_PASS: The password of the internal user that is used by the system to connect to the database service. For testing the default should be fine. In production environments, it is strongly advisable to change this to something more secure.
    1. AMBIT_USERS_DB: The name of the database holding the web interface users. There's probably little reason to change this from the default value, but it may be useful for custom RDBMS setups.
    1. MYSQL_ROOT_PASSWORD: The password for the root user of the RDBMS server run by Docker Compose. For testing the default should be fine. In production environments, it is strongly advisable to change this to something more secure. Use this password when connecting to the RDBMS server as root (see the section #Tips for more information). Note that the value of the option is irrelevant if using a custom RDBMS server.
1. For each database name in the `AMBIT_DATABASES` option above, add a new `api-<something>` section in the `docker-compose.yml` file. Use the existing `api-nanoreg1`, `api-nanoreg2` sections as an example. The `api-<something>` sections **must** be in sync with `AMBIT_DATABASES`. For example, if you have set the latter to `nanoreg1 datasetA datasetB`, `docker-compose.yml` must have and only have the `api-<something>` sections of `api-nanoreg1`, `api-datasetA`, and `api-datasetB`. You can actually use arbitrary names for these sections, but keeping the name of the dataset in the name keeps everything tidy. Note also that the `db` section must be present at all times, unless you opt to use a custom RDBMS server.
1. In each `api-<something>` section set the `AMBIT_DATABASE` environment variable to the corresponding database. Note the singular, unlike AMBIT_DATABASE**S**—the value must be a single database name.
1. In each `api-<something>` section set the `ports` option to a different host port (the one after `127.0.0.1`). With three datasets you may use, for example, `127.0.0.1:8080:8080`, `127.0.0.1:8081:8080`, and `127.0.0.1:8082:8080`. You may use any port numbers here (subject to OS permissions), just remember to open the same ports in your browser. For the service port (the last one), however, keep it at `8080`.
1. Run `sudo docker-compose up`.

Check also the `examples` directory for other examples.

# Tips
* You can connect to the RDBMS server by using this command from the **same** directory where the relevant `docker-compose.yml` is located: `sudo docker-compose exec db mysql -uroot -p`. When asked for a password, enter the password defined by `MYSQL_ROOT_PASSWORD` in `ambit-config.env`. Note that `db` here is the name of the RDBMS service in `docker-compose.yml`. If you have changed this name, update the command accordingly.
* When you make changes to `docker-compose.yml`, Docker Compose automatically recreates the containers for you. However, if you make changes to `ambit-config.env` and other files, these changes might not be picked up. In such cases it is advisable to run `sudo docker-compose down` before running `sudo docker-compose up` again. Do note, however, that even this command will not affect the databases. If you want to have the datases recreated, for example, if you have changed `AMBIT_DATABASES`, you should run `sudo docker-compose down -v`. **WARNING: The latter command will irreversibly destroy the existing databases! If you have entered custom data, make a dump before running the command!** One way of doing this could be `sudo docker-compose exec db mysqldump -uroot -p<value-of-MYSQL_ROOT_PASSWORD> --single-transaction --add-drop-database --databases --routines <database-name>`; redirect the output as needed, e.g. to a file.
* You can run the setup in background by using `sudo docker-compose up -d`. To stop, from the **same** directory, run `sudo docker-compose stop`.

# Supported tags

Container | Tags
--------- | ----
ambit-api | [ci/ambit-api/tags.txt](https://github.com/ideaconsult/ambit-docker/blob/master/ci/ambit-api/tags.txt)
ambit-db  | [ci/ambit-db/tags.txt](https://github.com/ideaconsult/ambit-docker/blob/master/ci/ambit-db/tags.txt)

## Notes on specific versions

* Java 11 is supported, but is much less tested than Java 8.
* MySQL 8 is *not* supported. Support is in the works.
* Tomcat 10 is *not* supported. We plan to move away from Tomcat.

# Possible problems
If you hit the Docker Hub pull limits, use [GitHub Container Registry](https://github.com/orgs/ideaconsult/packages). You'll need to edit the docker-compose files and prepend the `image` settings with `ghcr.io/`, e.g. `ideaconsult/ambit-db:latest` becomes `ghcr.io/ideaconsult/ambit-db:latest`.

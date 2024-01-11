# Guacamole Docker Deployment Script

Tested in:
- Ubuntu 22.04

Creates a docker group that includes everything needed to run Guacamole as a web client.

## Usage

To create a basic implementation, do the following:

1. Download [deploy.sh](./deploy.sh).
2. Save the script to the directory in which you want to store all files related to Guacamole.
3. Run `sudo bash deploy.sh`.
4. Follow the prompts.
5. Access guacamole from the web browser by opening port 8080 on the device that the script was run on.

If you want to change the default configuration, do the following:

1. clone or download this repository.
2. Edit [.env.template](./.env.template), [docker-compose.yaml](./docker-compose.yaml), and [docker-guacamole.service.template](./docker-guacamole.service.template) to your liking.
3. Run `sudo bash compile.sh`. This will update your deploy.sh.
4. Repeat the steps above for creating a basic implementation (excluding step #1).

If you want to start/stop guacamole use the commands `sudo systemctl start docker-guacamole.service` or `sudo systemctl stop docker-guacamole.service`.

~~You can also test the compiled script by running `sudo bash test.sh`.~~ Note that more tests need to be added. In the meantime, running test.sh will not be an adequate test of the compiled script.

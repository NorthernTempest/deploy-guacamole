# Guacamole Docker Deployment Script

Tested in:
- Ubuntu 22.04

Creates a docker group that includes everything needed to run Guacamole as a web client.

## Usage

To create a basic implementation, do the following:

1. Download [deploy.sh](./deploy.sh).
2. Run `sudo bash deploy.sh`.
3. Follow the prompts.

If you want to change the default configuration, do the following:

1. clone or download this repository.
2. Edit [.env.template](./.env.template), [docker-compose.yaml](./docker-compose.yaml), and [docker-guacamole.service.template](./docker-guacamole.service.template) to your liking.
3. Run `sudo bash compile.sh`.
4. Run `sudo bash deploy.sh`.

~~You can also test the build by running `sudo bash test.sh`.~~ Note that more tests need to be added. In the meantime, running test.sh will not be an adequate test of the compiled script.

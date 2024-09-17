# Mattermost Load Test Dockerized Shell

This containerized shell provides an easy-to-use environment for running Mattermost load testing with Terraform. It includes all necessary tools such as Terraform, Go, and bash to facilitate load testing.

See the [Terraform Load Test Documentation](https://github.com/mattermost/mattermost-load-test-ng/blob/master/docs/terraform_loadtest.md) for detailed usage details.

## Getting Started

1. **Run the Container:**

   ```bash
   docker run --rm -it --name mmlt -v $(pwd)/config:/mmlt/config -v mattermost-load-test-ng-data:/var/lib/mattermost-load-test-ng ghcr.io/maxwellpower/mm-loadtest-shell
   ```

   - The `/mmlt/config` directory is used to persist this configuration.

       - Mount a local direcory to store your configuration, license, and AWS credentials. Replace `$(pwd)` with the path to your local configuration directory, if needed.

### Using the Shell

- **Starting a Load Test:**

   Once the container and shell are started , you can use the interactive menu to perform various load testing tasks. To detach without stopping the container, use `CTRL+P` followed by `CTRL+Q`.

- **Launch a New Shell Session:**

   Start a new shell session if needed:

   ```bash
   docker exec -it mmlt bash
   ```

- **Run Commands Directly:**

   Execute any command directly within the container:

   ```bash
   docker exec -it mmlt <CMD>
   ```

### Handling AWS Credentials

To run Terraform commands, you must have AWS credentials set up. These credentials should be stored in a file located at `/mmlt/config/credentials` inside the container. The format of the credentials file should be as shown below. You may additionally need to include a session token as `aws_session_token`.

```ini
[mm-loadtest]
region=aws-region-id
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_KEY
```

**Important**: If you don't have this file in your container, the script will prompt you to create one.

### License File

The loadtest requires a valid Mattermost Enterprise License File.

It is suggested to save this file as `/mmlt/config/license` and point to it in your `deployer.json` file.

### Interactive Load Testing Menu

When you attach to the container, you are greeted with an interactive menu that allows you to manage your load testing deployment. Options include:

1. **Configure Load Test Settings**: Run the `mmltConfigure` script to customize deployment settings.
2. **Create a New Deployment**: Set up a new Mattermost deployment for load testing.
3. **Get Deployment Info**: Retrieve current deployment information.
4. **Sync Deployment**: Synchronize or reset the deployment.
5. **Destroy the Deployment**: Clean up and remove the current deployment.
6. **Start a Load Test**: Initiate a load test across the deployment.
7. **Get Load Test Status**: Check the current status of an ongoing load test.
8. **Stop the Load Test**: Stop an ongoing load test.
9. **SSH into a Host**: Access different hosts in your deployment via SSH.
10. **Drop to Bash Shell**: Open a bash shell session within the container.
11. **Exit Script**: Exit the script and stop the container.

### Manual SSH Access to Hosts

To SSH into the terraformed hosts, use the command line:

```bash
ltctl ssh <target>
```

Where `<target>` can be `coordinator`, `proxy`, `metrics`, or any instance name. You can list all hosts with

```bash
ltctl ssh list
```

## Manually build image

To build the image locally, clone this repository, then run docker build. The command below will overwrite the public image with your local build.

Dependencies are set at the top of the Dockerfile. Current defaults:

```bash
ARG MMLT_VERSION=master
ARG GO_VERSION=1.23
ARG DEBIAN_VERSION=bookworm
ARG TERRAFORM_VERSION=1.6.6
```

```bash
git clone https://github.com/maxwellpower/mm-loadtest-shell.git
cd mm-loadtest-shell
docker build . --tag ghcr.io/maxwellpower/mm-loadtest-shell
```

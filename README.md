# Mattermost Load Test Dockerized Shell

This containerized shell provides an easy-to-use environment for running Mattermost load testing with Terraform. It includes all necessary tools such as Terraform, Go, and bash to facilitate load testing.

## Getting Started

1. **Run the Container:**

   ```bash
   docker run --rm -dit --name mmlt ghcr.io/maxwellpower/mm-loadtest-shell
   ```

   This command runs the container in detached mode, allowing you to attach to it whenever you're ready to start load testing.

### Using the Shell

- **Attach to the Container:**

   The container starts with an interactive script by default. Attach to the running instance using:

   ```bash
   docker attach mmlt
   ```

   Once attached, you can use the interactive menu to perform various load testing tasks. To detach without stopping the container, use `CTRL+P` followed by `CTRL+Q`.

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

### Interactive Load Testing Menu

When you attach to the container, you are greeted with an interactive menu that allows you to manage your load testing deployment. Options include:

1. **Configure Load Test Settings**: Run the `configureLoadTest` script to customize deployment settings.
2. **Create a New Deployment**: Set up a new Mattermost deployment for load testing using `ltcreate`.
3. **Get Deployment Info**: Retrieve current deployment information using `ltinfo`.
4. **Sync Deployment**: Synchronize or reset the deployment using `ltreset`.
5. **Destroy the Deployment**: Clean up and remove the current deployment using `ltdestroy`.
6. **Start a Load Test**: Initiate a load test across the deployment using `ltstart`.
7. **Get Load Test Status**: Check the current status of an ongoing load test using `ltstatus`.
8. **Stop the Load Test**: Stop an ongoing load test using `ltstop`.
9. **SSH into a Host**: Access different hosts in your deployment via SSH.
10. **Drop to Bash Shell**: Open a bash shell session within the container.
11. **Exit Script**: Exit the script and stop the container.

### Configuration Files

The container uses a `/mmlt/config` volume for configuration files. To persist configurations across container restarts, mount a local directory:

```bash
docker run --rm -dit -v $(pwd)/config:/mmlt/config --name mmlt ghcr.io/maxwellpower/mm-loadtest-shell
```

Replace `$(pwd)` with your local configuration directory path.

### Automatic Configuration Handling

The entrypoint script handles the following:

1. **SSH Agent Setup**: Initializes and adds your SSH key if necessary.
2. **Configuration Checks**: Copies default configuration files to `/mmlt/config` if missing.
3. **AWS Credentials Setup**: Configures AWS credentials from environment variables or a credentials file.

### Running Load Tests with Aliases

The following aliases simplify running commands:

- **ltcreate**: Create a new deployment.
- **ltinfo**: Get deployment information.
- **ltsync**: Sync deployment.
- **ltdestroy**: Destroy the deployment.
- **ltstart**: Start a load test.
- **ltstatus**: Get the current load test status.
- **ltstop**: Stop the load test.
- **ltreset**: Reset the load test.
- **ltssh**: SSH into the terraformed hosts.

### SSH Access to Hosts

To SSH into the terraformed hosts, use:

```bash
ltssh <target>
```

Where `<target>` can be `coordinator`, `proxy`, `metrics`, or any instance name.

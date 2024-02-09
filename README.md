# Mattermost Load Test Dockerized Shell

This Dockerized shell provides an easy-to-use environment for running Mattermost load testing with Terraform. It encapsulates all necessary tools, including Terraform and a bash shell, to facilitate Mattermost load testing.

## Getting Started

1. **Run the Container:**
   ```sh
   docker run --rm -dit --name mmlt ghcr.io/maxwellpower/mm-loadtest-shell
   ```
   This command runs the container in detached mode, allowing you to attach to it whenever you're ready to start load testing.

2. **Attach to the Container:**
   ```sh
   docker attach mmlt
   ```
   Once attached, you can run Terraform commands and scripts for load testing. To detach without stopping the container, use `CTRL+P` followed by `CTRL+Q`.

## Configuration Files

The container uses a `/mmlt/config` volume for configuration files, which is not persisted across container restarts. To retain your configurations, mount a local directory to this volume:

```sh
docker run --rm -dit -v /path/to/your/config:/mmlt/config --name mmlt ghcr.io/maxwellpower/mm-loadtest-shell
```

Replace `/path/to/your/config` with the path to your local configuration directory. This setup allows you to modify and reuse your configurations easily.

## Customizing and Extending

Feel free to customize the Docker command with additional flags as needed for your testing environment. For advanced customization, consider building your own Docker image based on the provided Dockerfile, adjusting as necessary to fit your specific requirements.

This tool aims to simplify the process of load testing Mattermost installations, making it accessible even to those unfamiliar with Terraform or Docker.

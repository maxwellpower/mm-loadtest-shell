# Mattermost Load Test Dockerized Shell

This containerized shell provides an easy-to-use environment for running Mattermost load testing with Terraform. It encapsulates all necessary tools, including Terraform and a bash shell, to facilitate Mattermost load testing.

## Getting Started

1. **Run the Container:**

   ```bash
   docker run --rm -dit --name mmlt ghcr.io/maxwellpower/mm-loadtest-shell
   ```

This command runs the container in detached mode, allowing you to attach to it whenever you're ready to start load testing.

### Using the Shell

- **Attach to the Container:**

The container starts with a bash shell by default. You can attach to the running bash console using the command below.

   ```bash
   docker attach mmlt
   ```

   Once attached, you can run Terraform commands and scripts for load testing. To detach without stopping the container, use `CTRL+P` followed by `CTRL+Q`.

- **Lauch New Shell:**

Instead of attaching to the running shell, a new shell can be started.

   ```bash
   docker exec -it mmlt zsh
   ```

- **Run Direct Commands:**

Run any command directly.

   ```bash
   docker exec -it mmlt <CMD>
   ```

### Configuration Files

The container uses a `/mmlt/config` volume for configuration files, which is not persisted across container restarts. To retain your configurations, mount a local directory to this volume:

```bash
docker run --rm -dit -v $(pwd)/config:/mmlt/config --name mmlt ghcr.io/maxwellpower/mm-loadtest-shell
```

Replace `$(pwd)` with the path to your local configuration directory, if it is not in the current directory. This setup allows you to modify and reuse your configurations easily.

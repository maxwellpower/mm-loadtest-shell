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

## Environment Variables

### Default Editor

The defaut editor used in the shell is `nano` to use `vi` update your docker run command to add the `DEFAULT_EDITOR` variable.

- `-e DEFAULT_EDITOR=vi`

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

## AWS Load Testing Operations

The **AWS Load Testing Operations Tool** is a bash utility designed to assist in managing AWS resources specifically for load testing environments. It helps in tasks such as creating and restoring RDS snapshots, syncing S3 buckets, and checking the status of database backups and restores. This tool automates several AWS tasks that are required for preparing and managing infrastructure used in load testing.

### Usage

To run the helper script, choose the AWS Operations option from the shell.

Upon running, the script will display a menu that allows you to perform various AWS operations related to database snapshots, restores, S3 bucket operations, and more.

### Script Menu Options

The script presents a menu to select different AWS tasks. Below are the details for each option:

#### 1. List DB Clusters

This option lists all available RDS database clusters in your AWS account. You can use this information to identify the database cluster you want to snapshot or restore.

Example command (run by script):

```bash
aws rds describe-db-clusters | jq '.DBClusters[] | {DatabaseName: .DatabaseName, DBClusterIdentifier: .DBClusterIdentifier}'
```

#### 2. Create DB Snapshot

Creates a snapshot of the specified database cluster. The script will prompt for the database cluster identifier and a unique name for the snapshot.

Example command (run by script):

```bash
aws rds create-db-cluster-snapshot --db-cluster-identifier <cluster-id> --db-cluster-snapshot-identifier <snapshot-id>
```

#### 3. Monitor DB Snapshot

This option monitors the status of a specific DB snapshot and informs you once the snapshot creation is complete or if it has failed.

Example command (run by script):

```bash
aws rds describe-db-cluster-snapshots | jq '.DBClusterSnapshots[] | select(.DBClusterSnapshotIdentifier == "<snapshot-id>") | .Status'
```

#### 4. Share DB Snapshot with Another Account

Allows you to share the snapshot with another AWS account, typically for restoring the database in a different environment, such as a load testing AWS account.

Example command (run by script):

```bash
aws rds modify-db-cluster-snapshot-attribute --db-cluster-snapshot-identifier <snapshot-id> --attribute-name restore --values-to-add <destination-account-id>
```

#### 5. Restore DB from Snapshot

Restores a new RDS cluster from an existing snapshot. You will need to provide the snapshot identifier, a new DB cluster identifier, and the database engine.

Example command (run by script):

```bash
aws rds restore-db-cluster-from-snapshot --db-cluster-identifier <new-db-id> --snapshot-identifier <snapshot-id> --engine <db-engine>
```

#### 6. Monitor DB Restore

This option monitors the restore process of an RDS cluster. The script will continuously check the status of the restore operation and notify you when it’s complete.

Example command (run by script):

```bash
aws rds describe-db-clusters | jq '.DBClusters[] | select(.DBClusterIdentifier == "<db-cluster-id>") | .Status'
```

#### 7. Create S3 Bucket

Creates a new S3 bucket, which is often used for storing database snapshots, logs, or other load testing-related artifacts.

Example command (run by script):

```bash
aws s3api create-bucket --bucket <bucket-name>
```

#### 8. Sync S3 Buckets

This option allows you to sync data between two S3 buckets. Typically, this is used to copy data from a production environment to a load testing environment.

Example command (run by script):

```bash
aws s3 sync s3://<source-bucket> s3://<destination-bucket>
```

#### 9. Exit

Exits the script.

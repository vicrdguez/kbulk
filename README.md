# kbulk

A CLI that wraps kafka native CLIs to perform common operations in bulk mode, so you don't need to run commands one by 
one or create your own scripts for that.

```shell
kbulk - A kafka tool to perform different bulk actions

Usage:
  kbulk COMMAND
  kbulk [COMMAND] --help | -h
  kbulk --version | -v

Commands:
  replicas   Bulk change a topic replication factor

Options:
  --help, -h
    Show this help

  --version, -v
    Show version number
```

## Dependencies
This command depends on kafka-native clis like `kafka-reassign-partitios` and `kafka-topics`, so make sure you have them
in your `PATH`.

Appart from that there isn't any special Dependencies.

## Installation

Run the setup script:

```bash
curl -s https://raw.githubusercontent.com/vicrdguez/kbulk/main/setup | bash
```

Feel free to inspect the installation script. If you prefer you can download the `kbulk` executable manually from github 
and then add it to a directory in your `PATH`

## Bulked commands
### replicas
Changes topic replication factor

**Features**
- Generates replica assignment configuration and assigns randomn new replicas
- Leader replica is preserved with assignment changes
- Waits for assignments to complete before moving to the next topic
    - This can take quite a while if the size of your partition is big. In that case expect waiting times

**Usage:**
```shell
kbulk replicas - Bulk change a topic replication factor

Alias: r

Usage:
  kbulk replicas TOPICS TARGET [OPTIONS]
  kbulk replicas --help | -h

Options:
  --brokers, -n ID
    Comma separated list of broker nodes where to place the replicas instead of
    choosing the nodes randomly

  --bootstrap, -b SERVER (required)
    Kafka bootstrap server

  --config, -c PROPERTIES
    Kafka client configuration file (a .properties file)

  --help, -h
    Show this help

Arguments:
  TOPICS
    Text file with the list of topics to change

  TARGET
    Target number of replicas. If --brokers is not specified, the replicas will
    be placed in random nodes

Environment Variables:
  KBULK_BOOTSTRAP
    Set the Kafka bootstrap server to use

Examples:
  kbulk replicas topics.txt 4 --bootstrap localhost:9092 --config client.properties
  kbulk replicas topics.txt 3 --bootstrap localhost:9092 --config client.properties
  --brokers 1,2,3
```

## Contribution and support
The scripts is not perfect and might have some quirks. Do not hesitate to open an issue if you encounter any issue
or have any questions.

PRs and suggestions are always welcomed.

----

This tools are built using [bashly](https://github.com/DannyBen/bashly) as the CLI framework.



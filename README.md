# popi: PostgreSQL Performance on Pi

This project contains a suite of scripts and tools for testing and analyzing PostgreSQL performance, specifically targeted for Raspberry Pi environments (though applicable elsewhere). It automates the process of fetching commits, building PostgreSQL, running performance tests, and visualizing the results.

## Prerequisites

The following tools and libraries are required:

-   `datamash`
-   `gnuplot-x11`
-   `curl`
-   `git`

## Directory Structure

-   **`script/`**: Contains the core shell scripts and SQL files for running tests.
-   **`catalog/`**: Stores catalogs of commits to be tested (e.g., `q`, `q2`).
-   **`obs/`**: Observation directory where build and test artifacts are stored.
-   **`log/`**: Contains execution logs.
-   **`test/`**: Contains the actual performance test definitions.
-   **`stage/`**: Staging area for builds.

## Usage

The typical workflow involves fetching commits and then running the test suite.

### 1. Fetch Commits
Use `getcommits.sh` to populate the catalog with new commits to test.

```bash
./script/getcommits.sh
```

### 2. Run Tests
Use `runall.sh` to execute the tests. This script orchestrates the build and test process for the commits in the catalog.

```bash
./script/runall.sh
```

## Scripts

Key scripts in the `script/` directory include:

-   **`getcommits.sh`**: Fetches new commits from the PostgreSQL repository and populates `catalog/q` for processing.
-   **`runall.sh`**: The main entry point for running all tests. It triggers `run.sh` for each commit.
-   **`run.sh`**: Handles the lifecycle for a single commit: git checkout, install, start PostgreSQL, run tests (`runtests.sh`), and stop PostgreSQL.
-   **`runtests.sh`**: Executes the specific tests for a single installation (runs `pre.sql`, the test, and `post.sql`).
-   **`parseobs.sh`**: Parses observation data.
-   **`web.sh`**: Generates an HTML report of the results (`obs/results/index.html`).
-   **`misc.sh`**: Contains miscellaneous utility functions and cron job examples.
-   **`resultplot.gp`**: Gnuplot script for visualizing results.

## Automated Testing

The `test/` folder contains the test definitions. If no specific test is selected, a default one is used. The goal is to ensure performance metrics are tracked across the project's history.

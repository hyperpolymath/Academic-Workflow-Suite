# test-project

This directory has been initialized with Academic Workflow Suite.

## Directory Structure

- `.aws/` - AWS configuration and data
  - `config.yaml` - Project configuration
  - `submissions/` - Downloaded TMA submissions
  - `feedback/` - Generated feedback files
  - `logs/` - Application logs

## Quick Start

1. Start services:
   ```
   aws start
   ```

2. Check status:
   ```
   aws status
   ```

3. Mark a TMA:
   ```
   aws mark --interactive
   ```

4. View feedback:
   ```
   aws feedback <student-id>
   ```

For more information, run `aws --help`.

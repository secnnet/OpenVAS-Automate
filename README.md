# OpenVAS Automate Script

Automates OpenVAS scans with features like profile selection, report generation, and error handling. OpenVAS is an open-source vulnerability scanner.

### Configuration:
Set these in the script:
- `USER`, `PASS`: OpenVAS authentication.
- `HOST`, `PORT`: OpenVAS server details.
- `SCAN_PROFILES`, `REPORT_FORMATS`: Predefined scan profiles and report formats.
- `DEFAULT_SCAN_PROFILE`, `DEFAULT_REPORT_FORMAT`: Defaults if user doesn't select.
- `ALIVE_TEST`: Method for target availability.

### Usage:
1. `chmod +x openvas-automate.sh`
2. `./openvas-automate.sh <target_host>`
3. Follow prompts for scan profile and report format.
4. Monitor and get report file on completion.

### Notes:
- Ensure OpenVAS server configuration and `omp` tool availability.
- Scan duration depends on scan size/complexity.
- Script cleans up on abortion or error.

### License:
MIT

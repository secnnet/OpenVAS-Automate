# OpenVAS Automate Script

This script automates OpenVAS (Open Vulnerability Assessment System) scans by providing a convenient way to select scan profiles, generate reports, and handle errors. OpenVAS is an open-source vulnerability scanning and management tool.

## Features

- Authentication with OpenVAS server using provided credentials.
- Selection of scan profiles from a predefined list.
- Selection of report formats from a predefined list.
- Automatic creation of targets and tasks.
- Monitoring of task progress.
- Generation of reports in the specified format.
- Cleanup of targets and tasks after completion or error.

## Prerequisites

- Bash shell
- OpenVAS server
- OMP (OpenVAS Management Protocol) command-line tool (`omp`) installed and accessible from the command line.
- Properly configured OpenVAS authentication credentials.

## Configuration

Before running the script, ensure that you have correctly set the following configuration variables at the beginning of the script:

- `USER`: The username for authenticating with the OpenVAS server.
- `PASS`: The password for authenticating with the OpenVAS server.
- `HOST`: The IP address or domain name of the OpenVAS server.
- `PORT`: The port number used to connect to the OpenVAS server.
- `SCAN_PROFILES`: An associative array containing the available scan profiles and their corresponding numeric keys.
- `REPORT_FORMATS`: An associative array containing the available report formats and their corresponding numeric keys.
- `DEFAULT_SCAN_PROFILE`: The default scan profile if not selected by the user.
- `DEFAULT_REPORT_FORMAT`: The default report format if not selected by the user.
- `ALIVE_TEST`: The alive test method used to determine target availability.

## Usage

1. Ensure that the script has execution permission: `chmod +x openvas-automate.sh`
2. Run the script with the target host as an argument: `./openvas-automate.sh <target_host>`
3. Follow the on-screen prompts to select the scan profile and report format (if not already specified in the configuration).
4. Monitor the task progress until completion or abortion.
5. Once completed, the script will generate a report file with a name based on the target host and the current timestamp.

## Notes

- This script assumes that you have properly configured and authenticated your OpenVAS server before running the script.
- Ensure that the OMP command-line tool (`omp`) is installed and accessible from the command line.
- The script may take a while to complete, depending on the size and complexity of the scan.
- If the scan is aborted or encounters an error, the script will attempt to clean up any created targets and tasks.

## License

This script is provided under the [MIT License](LICENSE).

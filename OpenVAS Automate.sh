#!/bin/bash

trap ctrl_c INT

# --- CONFIGURATION ---

# Specify OpenVAS server credentials and connection details
USER="<USERNAME>"
PASS="<PASSWORD>"
HOST="127.0.0.1"
PORT="9390"

# Define available scan profiles
declare -A SCAN_PROFILES=(
  ["1"]="Discovery"
  ["2"]="Full and fast"
  ["3"]="Full and fast ultimate"
  ["4"]="Full and very deep"
  ["5"]="Full and very deep ultimate"
  ["6"]="Host Discovery"
  ["7"]="System Discovery"
)

# Define available report formats
declare -A REPORT_FORMATS=(
  ["1"]="ARF"
  ["2"]="CPE"
  ["3"]="HTML"
  ["4"]="ITG"
  ["5"]="NBE"
  ["6"]="PDF"
  ["7"]="TXT"
  ["8"]="XML"
)

# Specify the default scan profile and report format
DEFAULT_SCAN_PROFILE="Full and fast"
DEFAULT_REPORT_FORMAT="PDF"

# Specify the alive test method
ALIVE_TEST="ICMP, TCP-ACK Service & ARP Ping"

# --- END OF CONFIGURATION ---

# Function: Display script usage instructions
function usage {
  echo
  echo "Usage: $0 <host>"
  echo
  echo "  host  - IP address or domain name of the target host."
  echo
}

# Function: Execute an OpenVAS Management Protocol (OMP) command
function omp_cmd {
  local cmd="omp -u $USER -w '$PASS' -h $HOST -p $PORT $@"
  #>&2 echo "DBG: OMP cmd: \"$cmd\""
  eval $cmd 2>&1
}

# Function: Execute an OMP command and specify XML output format
function omp_cmd_xml {
  omp_cmd "--xml='$@'"
}

# Function: Clean up and exit the script
function end {
  echo "[>] Performing cleanup"
  
  if [ $able_to_clean -eq 1 ]; then
    omp_cmd -D $task_id
    omp_cmd -X '<delete_target target_id="'$target_id'"/>'
  fi
  
  exit 1
}

# Function: Handle Ctrl+C signal
function ctrl_c() {
  echo "[?] CTRL-C trapped."
  end
}

# Print script information
echo
echo " :: OpenVAS automation script."
echo "    mgeeky, 0.2"
echo

# Authenticate with the OpenVAS server
out=$(omp_cmd -g | grep -i "discovery")
if [ -z "$out" ]; then
  echo "Exiting due to OpenVAS authentication failure."
  exit 1
fi

echo "[+] OpenVAS authenticated."

# Prompt the user to select a scan profile if not specified in configuration
if [ -z "$SCAN_PROFILE" ]; then
  echo "[>] Please select a scan profile:"
  for key in "${!SCAN_PROFILES[@]}"; do
    echo -e "\t$key. ${SCAN_PROFILES[$key]}"
  done
  echo -e "\t0. Exit"
  echo
  echo "--------------------------------"

  read -p "Please select an option: " selection

  if [ "$selection" == "0" ]; then
    exit 0
  elif [ -n "${SCAN_PROFILES[$selection]}" ]; then
    SCAN_PROFILE="${SCAN_PROFILES[$selection]}"
  else
    echo "[!] Unknown profile selected."
    exit 1
  fi

  echo
fi

# Validate the selected scan profile
scan_profile_id=$(omp_cmd -g | grep "$SCAN_PROFILE" | awk '{ print $1 }')
if [ -z "$scan_profile_id" ]; then
  echo "[!] Unknown SCAN_PROFILE selected. Please change it in the script's settings."
  exit 1
fi

# Prompt the user to select a report format if not specified in configuration
if [ -z "$FORMAT" ]; then
  echo "[>] Please select a report format:"
  for key in "${!REPORT_FORMATS[@]}"; do
    echo -e "\t$key. ${REPORT_FORMATS[$key]}"
  done
  echo -e "\t0. Exit"
  echo
  echo "--------------------------------"

  read -p "Please select an option: " selection

  if [ "$selection" == "0" ]; then
    exit 0
  elif [ -n "${REPORT_FORMATS[$selection]}" ]; then
    FORMAT="${REPORT_FORMATS[$selection]}"
  else
    echo "[!] Unknown report format selected."
    exit 1
  fi

  echo
fi

# Validate the selected report format
format_id=$(omp_cmd -F | grep "$FORMAT" | awk '{ print $1 }')
if [ -z "$format_id" ]; then
  echo "[!] Unknown FORMAT selected. Please change it in the script's settings."
  exit 1
fi

# Check if a target host is specified as a command-line argument
if [ -z "$1" ]; then
  usage
  exit 1
fi

TARGET="$1"

# Check if the target host is available
if ! ping -c 1 "$TARGET" &> /dev/null; then
  echo "[!] Specified target host seems to be unavailable!"
  read -p "Are you sure you want to continue [Y/n]? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Create or reuse a target
echo "[+] Tasked: '$SCAN_PROFILE' scan against '$TARGET'"

target_id=$(omp_cmd -T | grep "$TARGET" | awk '{ print $1 }')

if [ -z "$target_id" ]; then
  echo "[>] Creating a target..."
  out=$(omp_cmd -u "$USER" -w "$PASS" -h "$HOST" -p "$PORT" --xml=\
"<create_target>\
<name>${TARGET}</name><hosts>$TARGET</hosts>\
<alive_tests>$ALIVE_TEST</alive_tests>\
</create_target>")
  target_id=$(echo "$out" | pcregrep -o1 'id="([^"]+)"')
else
  echo "[>] Reusing target..."
fi

if [ -z "$target_id" ]; then
  echo "[!] Something went wrong, couldn't acquire target's ID!"
  echo "$out"
  exit 1
else
  echo "[+] Target's ID: $target_id"
fi

# Create a task
echo "[>] Creating a task..."
task_id=$(omp_cmd -C -n "$TARGET" --target="$target_id" --config="$scan_profile_id")

if [ $? -ne 0 ]; then
  echo "[!] Could not create a task."
  end
fi

echo "[+] Task created successfully, ID: '$task_id'"

# Start the task
echo "[>] Starting the task..."
report_id=$(omp_cmd -S "$task_id")

if [ $? -ne 0 ]; then
  echo "[!] Could not start the task."
  end
fi

able_to_clean=0

echo "[+] Task started. Report ID: $report_id"
echo "[.] Awaiting completion. This may take a while..."
echo

aborted=0
while true; do
  running_jobs=$(omp_cmd -G | grep -m1 "$task_id")

  if [ $? -ne 0 ]; then
    echo "[!] Failed to query running jobs."
    end
  fi

  if [ -z "$running_jobs" ]; then
    break
  fi

  echo -ne "$running_jobs\r"
  if echo "$running_jobs" | grep -i -E "fail|stopped" > /dev/null; then
    aborted=1
    break
  fi

  sleep 1
done

if [ $aborted -eq 0 ]; then
  echo "[+] Job done, generating report..."

  FILENAME="openvas_$(echo "$TARGET" | sed -e 's/[^a-zA-Z0-9_\.\-]/_/g')_$(date +%s)"

  out=$(omp_cmd --get-report "$report_id" --format "$format_id" > "$FILENAME.$FORMAT")

  if [ $? -ne 0 ]; then
    echo "[!] Failed to get the report."
    echo "[!] Output: $out"
    #end
  fi

  echo "[+] Scanning done."
else
  echo "[?] Scan monitoring has been aborted. You're on your own now."
fi

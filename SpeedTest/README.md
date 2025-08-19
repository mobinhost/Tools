# SpeedTest Bash Script

A **Bash script** to test download speed from multiple URLs using popular download tools (`wget`, `wget2`, `axel`, `aria2c`) on Linux.
Supports **single and multi-connection tests**, shows **real-time progress, speed, and estimated remaining time**, and prints a **summary with averages** at the end.

---

## Features

* Works on **Ubuntu, AlmaLinux, Rocky Linux**.
* Supports tools: `wget`, `wget2`, `axel`, `aria2c`.
* Supports **single and multi-connection** modes.
* Automatically installs missing tools.
* Shows **live download progress and speed**.
* Generates **summary table** with final speed for each test.
* Calculates **average speed per tool and mode** across multiple URLs.
* Fully interactive: choose tools, modes, or run all automatically.

---

## Requirements

* Linux system (tested on Ubuntu 20+, AlmaLinux 8+, Rocky Linux 8+)
* Bash shell
* `sudo` access for installing missing tools
* Internet connection

---

## Installation

1. Clone the repository:

```bash
git clone https://github.com/mobinhost/Tools/SpeedTest.git
cd SpeedTest
```

2. Make the script executable:

```bash
chmod +x speedtest.sh
```

---

## Usage

Run the script:

```bash
./speedtest.sh
```

The script will:

1. Ask you to select download tools (e.g., `wget`, `aria2c`).
2. Ask you to select test modes (`Single connection`, `Multi connection`).
3. Download the test files while showing **real-time progress and speed**.
4. Generate a **summary table** with final speeds.
5. Calculate **average speed** per tool/mode.

---

### Example Interaction

```
Select tools (comma separated):
1) wget
2) wget2
3) axel
4) aria2c
Enter choice(s) [e.g. 2,3]:

Select test modes (comma separated):
1) Single connection
2) Multi connection
Enter choice(s) [e.g. 1,2]:
```

During download, progress bars with speed and estimated remaining time will be displayed.
After all tests, a **summary table** with averages is printed.

---

## Notes

* `wget` does **not support multi-connection**, so multi-mode will be skipped for it.
* `wget2`, `axel`, and `aria2c` support multi-connection downloads.
* Speeds are converted to **MB/s** for summary and average calculations.
* Temporary log files are used for parsing speeds and removed automatically.

---

## Example Summary Output

```
URL                                                    TOOL     MODE     SPEED
------------------------------------------------------- -------- -------- ---------------
https://nbg1-speed.hetzner.com/1GB.bin                 wget     Single   87.3 MB/s
https://nbg1-speed.hetzner.com/1GB.bin                 aria2c   Multi    130 MB/s
https://lon.speedtest.clouvider.net/1g.bin             wget     Single   85.2 MB/s
https://lon.speedtest.clouvider.net/1g.bin             aria2c   Multi    128 MB/s

Average Speeds (across all URLs):
TOOL     MODE     AVG SPEED
aria2c   Multi    129.00 MB/s
wget     Single   86.25 MB/s
```

---

## License

This project is licensed under the **MIT License**. See `LICENSE` for details.

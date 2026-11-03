# ssh-inhibit-sleep

A small systemd service that keeps a Linux machine from sleeping while any SSH connection is active.

It's useful for machines that auto-suspend to save power but are also used remotely. Interactive SSH sessions, `rsync`, `scp`, `sftp`, and `sshfs` all count as connections, so long-running transfers and remote jobs won't be cut off by a suspend. Once the last connection closes, normal sleep behavior resumes.

## Requirements

- A Linux system using systemd
- `bash`
- `ss` (part of `iproute2`, installed by default on most distros)
- An SSH server (`sshd`)
- That's p much it, literally 99% of linux distros have this stuff

## Installation

```bash
git clone https://github.com/ZackElramly/ssh-inhibit-sleep.git
cd ssh-inhibit-sleep
sudo ./install.sh
```

The installer copies the script to `/usr/local/bin/`, copies the unit file to `/etc/systemd/system/`, then enables and starts the service.
You can update the script by just running `git pull` then ruinning the install script again.

Re-running the installer replaces the installed files and restarts the service with the new version.

## Usage

Once installed, there's nothing to do. The service runs in the background and starts automatically at boot.

To check that it's running:

```bash
systemctl status ssh-inhibit-sleep.service
```

To see the active inhibitor while you're connected over SSH:

```bash
systemd-inhibit --list
```

To check the logs to see what IPs are using ssh sessions:

```bash
journalctl -u ssh-inhibit-sleep -f
```

## Configuration

Two settings are at the top of `ssh-inhibit-sleep.sh`:

| Variable         | Default | Description                                |
|------------------|---------|--------------------------------------------|
| `PORT`           | `22`    | The port `sshd` listens on                 |
| `CHECK_INTERVAL` | `30`    | Seconds between checks for SSH connections |

After changing either one, run `sudo ./install.sh` again to apply it.

## Uninstallation

```bash
sudo ./uninstall.sh
```

This stops and disables the service and removes the installed files. The cloned repository is left untouched.

## How it works

Every `CHECK_INTERVAL` seconds, the script uses `ss` to look for established TCP connections on the SSH port. When it finds one, it starts a background `systemd-inhibit` process that holds a `sleep:idle` block lock. When it finds none, it ends that process, which releases the lock. Each acquire and release is logged to the journal, along with the addresses of the connected clients.

## Notes

- If your desktop environment (GNOME, KDE, etc.) handles auto-suspend, its idle timer still counts down. When it tries to suspend, systemd refuses because of the inhibitor, so the machine stays awake. You may see a log entry or notice about the blocked suspend.
- You can force a suspend while connected, ignoring the inhibitor, with `sudo systemctl suspend -i`.
- Any established connection to the SSH port counts, including ones from other users.

## License

MIT. See [LICENSE](LICENSE).

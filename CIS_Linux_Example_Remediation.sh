#!/bin/bash
PROFILE=${1:-Level 1}

if [ "$PROFILE" = "Level 1" ] || [ "$PROFILE" = "Level 2" ]; then
  echo \*\*\*\* Executing Level 1 profile remediation

  # Create Separate Partition for /tmp
  echo
  echo \*\*\*\* Create\ Separate\ Partition\ for\ /tmp
  echo Create\ Separate\ Partition\ for\ /tmp not configured.

  # Set nodev option for /tmp Partition
  echo
  echo \*\*\*\* Set\ nodev\ option\ for\ /tmp\ Partition
  egrep -q "^(\s*\S+\s+)/tmp(\s+\S+\s+\S+)(\s+\S+\s+\S+)(\s*#.*)?\s*$" /etc/fstab && sed -ri "s/^(\s*\S+\s+)/tmp(\s+\S+\s+\S+)(\s+\S+\s+\S+)(\s*#.*)?\s*$/\1/tmp\2nodev\3\4/" /etc/fstab

  # Restrict Core Dumps
  echo
  echo \*\*\*\* Restrict\ Core\ Dumps
  egrep -q "^(\s*)\*\s+hard\s+core\s+\S+(\s*#.*)?\s*$" /etc/security/limits.conf && sed -ri "s/^(\s*)\*\s+hard\s+core\s+\S+(\s*#.*)?\s*$/\1* hard core 0\2/" /etc/security/limits.conf || echo "* hard core 0" >> /etc/security/limits.conf
  egrep -q "^(\s*)fs.suid_dumpable\s*=\s*\S+(\s*#.*)?\s*$" /etc/sysctl.conf && sed -ri "s/^(\s*)fs.suid_dumpable\s*=\s*\S+(\s*#.*)?\s*$/\1fs.suid_dumpable = 0\2/" /etc/sysctl.conf || echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf

  # Enable Randomized Virtual Memory Region Placement
  echo
  echo \*\*\*\* Enable\ Randomized\ Virtual\ Memory\ Region\ Placement
  egrep -q "^(\s*)kernel.randomize_va_space\s*=\s*\S+(\s*#.*)?\s*$" /etc/sysctl.conf && sed -ri "s/^(\s*)kernel.randomize_va_space\s*=\s*\S+(\s*#.*)?\s*$/\1kernel.randomize_va_space = 2\2/" /etc/sysctl.conf || echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf

  # Remove telnet-server
  echo
  echo \*\*\*\* Remove\ telnet-server
  rpm -q telnet-server && yum -y remove telnet-server

  # Disable tcpmux-server
  echo
  echo \*\*\*\* Disable\ tcpmux-server
  rpm -q xinetd && chkconfig tcpmux-server off

  # Disable Print Server - CUPS
  echo
  echo \*\*\*\* Disable\ Print\ Server\ -\ CUPS
  chkconfig cups off

  # Verify Permissions on /etc/hosts.allow
  echo
  echo \*\*\*\* Verify\ Permissions\ on\ /etc/hosts.allow
  chmod u+r+w-x,g+r-w-x,o+r-w-x /etc/hosts.allow

  # Disable SSH X11 Forwarding
  echo
  echo \*\*\*\* Disable\ SSH\ X11\ Forwarding
  egrep -q "^(\s*)X11Forwarding\s+\S+(\s*#.*)?\s*$" /etc/ssh/sshd_config && sed -ri "s/^(\s*)X11Forwarding\s+\S+(\s*#.*)?\s*$/\1X11Forwarding no\2/" /etc/ssh/sshd_config || echo "X11Forwarding no" >> /etc/ssh/sshd_config

  # Lock Inactive User Accounts
  echo
  echo \*\*\*\* Lock\ Inactive\ User\ Accounts
  useradd -D -f 35
fi

if [ "$PROFILE" = "Level 2" ]; then
  echo \*\*\*\* Executing Level 2 profile remediation

  # Install AIDE
  echo
  echo \*\*\*\* Install\ AIDE
  rpm -q aide || yum -y install aide

  # Implement Periodic Execution of File Integrity
  echo
  echo \*\*\*\* Implement\ Periodic\ Execution\ of\ File\ Integrity
  (crontab -u root -l; crontab -u root -l | egrep -q "^0 5 \* \* \* /usr/sbin/aide --check$" || echo "0 5 * * * /usr/sbin/aide --check" ) | crontab -u root -

  # Enable auditd Service
  echo
  echo \*\*\*\* Enable\ auditd\ Service
  chkconfig auditd on

  # Collect System Administrator Actions (sudolog)
  echo
  echo \*\*\*\* Collect\ System\ Administrator\ Actions\ \(sudolog\)
  egrep -q "^\s*-w\s+/var/log/sudo.log\s+-p\s+wa\s+-k\s+actions\s*(#.*)?$" /etc/audit/audit.rules || echo "-w /var/log/sudo.log -p wa -k actions" >> /etc/audit/audit.rules

fi

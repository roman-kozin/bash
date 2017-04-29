#!/bin/bash

USER='r.kozin'

useradd -m "$USER"
mkdir -p /home/"$USER"/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAxKB/rsLfFD+cRz6j5L14vquuhbwgcTsDnlz3xlz2I9+J0XbMP5L0xzWPQ04Ww/5ZJWyrgHJv1/i85kMhxzcfsyyRP5KowWWuc6ZJLrsHNngOLylDRIfGSUzKlHqz45XQj8t8Au8LvDZIOW5DoGqPFpZQJ6noiZMeT0E3Oy+PtE2AFcnLqA58OsVVmOdGaPKg7NmM7rrktxm1sP1mq3RXGViVlcdzCpDPnmYHppyeNeGowbL3+eIhS5zZzMAFWOQCCRPYhAWJ5HzJ+SZgeTZRfyQGlmpQAV1XCFKLKzJqWSbCmj457wxpkfFCGzWlxzRajseyl1mzfMXaUWd5FKf+8w== roman.kozin" >> /home/"$USER"/.ssh/authorized_keys
chown "$USER":"$USER" /home/"$USER" -R
chmod 600 /home/"$USER"/.ssh/authorized_keys
chmod 700 /home/"$USER"/.ssh
usermod -G sudo "$USER"
usermod -s /bin/bash "$USER"
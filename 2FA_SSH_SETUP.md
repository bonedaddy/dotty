# Overview

This will setup ssh so that both public key + 2fa are required for authentication

# Steps
Install google authenticator

```sh
$> sudo apt install libpam-google-authenticator
```

At the top of `/etc/pam.d/sshd`

```
# require 2fa ssh
auth required pam_google_authenticator.so
# (optional) change the above to the following to allow users who dont have 2fa setup
# auth required pam_google_authenticator.so nullok

# Standard Un*x authentication.
#@include common-auth
```

In `/etc/ssh/sshd_config`

* Set `UsePAM yes`
* Set `PubkeyAuthentication yes`
* Set `PasswordAuthentication no`
* Set `AuthenticationMethods publickey,keyboard-interactive`

* On holder hosts set `ChallengeResponseAuthentication yes`
* On newer hosts set `KbdInteractiveAuthentication yes`

Run `systemctl restart ssh`

# Harden SSH

```
HostKeyAlgorithms ssh-ed25519,ssh-rsa
PubkeyAcceptedAlgorithms ssh-ed25519,ssh-rsa
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
```

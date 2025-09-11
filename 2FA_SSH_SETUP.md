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

# Standard Un*x authentication.
#@include common-auth
```

In `/etc/ssh/sshd_config`

Set `UsePAM yes`
Set `PubkeyAuthentication yes`
Set `PasswordAuthentication no`
Set `AuthenticationMethods publickey,keyboard-interactive`

On holder hosts set `ChallengeResponseAuthentication yes`
On newer hosts set `KbdInteractiveAuthentication yes`

Run `systemctl restart ssh`

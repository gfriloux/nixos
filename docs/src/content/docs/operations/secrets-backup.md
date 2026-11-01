---
title: "Age key backup"
description: Editing with the YubiKey, the rescue key, checking the keys, recovering from a lost key.
---

The sops files live in git, harmless without the keys. What matters is the
**rescue key**: the only one tied to no device. Who opens what:
[Secrets](/nixos/architecture/secrets/).

## YubiKey

`sops` finds the YubiKey through `~/.config/sops/age/keys.txt`, a reference
file with no secret in it:

```text
#       Serial: 36644572, Slot: 1
#         Name: sops-master
#    Recipient: age1yubikey1qtsqgx98tq7d005aue4lqth3z5hgu67e9eee490mpf0phfx7znghqr8x67l
AGE-PLUGIN-YUBIKEY-1MSNZ7Q5ZKGQ5JCG67Q42J
```

| | |
|---|---|
| Plugin | `age-plugin-yubikey` in `PATH`, even to encrypt (relic `relics-yubikey-user`) |
| PIN | PIV, 6 to 8 characters, once per session. Not the GPG PIN; longer = `size error` |
| Touch | on every decryption, within ~15 s, otherwise `Failed to decrypt YubiKey stanza` |
| GnuPG | shares the card through pcscd, no need to stop `scdaemon` ([stc#111](https://github.com/gfriloux/stc/issues/111)) |

## Rescue key

Plain age key, generated 2026-10-25, offline, on no machine.
Public: `age1faz4m9gj9xyz4rm26gndwgjkwrwr9ppnzm48slcrne7uvf3afqcsxtv8hs`.

```bash
SOPS_AGE_KEY_FILE=/tmp/rescue.txt sops secrets/clochette.yaml
shred -u /tmp/rescue.txt
```

## Check

A few times a year. Nothing is printed in clear.

```bash
# YubiKey (or the rescue copy): opens all four
for f in kuri_exampleHost clochette RogueLeader skitarii; do
  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d secrets/$f.yaml > /dev/null && echo "$f OK"
done

# exampleHost boot key: its own file only
for f in kuri_exampleHost clochette RogueLeader skitarii; do
  SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops -d secrets/$f.yaml > /dev/null 2>&1 \
    && echo "$f: opened" || echo "$f: refused"
done
```

## Lost key

| Lost | Fix |
|---|---|
| exampleHost boot key | `age-keygen` to `/etc/sops/age/keys.txt`, new key in `&desktop_examplehost`, `sops updatekeys` (YubiKey), `just install`. No system left: [Reinstall exampleHost](/nixos/operations/reinstall-examplehost/) |
| A server's host key | Reinstall: [clochette](/nixos/operations/reinstall-clochette/), [RogueLeader](/nixos/operations/reinstall-rogueleader/), [skitarii](/nixos/operations/reinstall-skitarii/) |
| YubiKey | Rescue key; enroll a new YubiKey, put it in `&admin_yubikey`, `updatekeys` on all four files |
| Rescue key | Generate one, put it in `&admin_rescue`, `updatekeys` on all four files (YubiKey) |
| Both | Each machine still reads its own file: re-encrypt from there to new admin keys |

:::danger
YubiKey and rescue key lost together: no key opens every file any more. Keep
the rescue key away from the YubiKey, and test it.
:::

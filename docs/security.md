# Security baseline

**Binding.** Every rule here is checkable — a reviewer can point at a violation. If a
rule is too vague to catch someone breaking it, rewrite the rule.

## Why this matters here

These apps hold private things: trip plans, personal journals, scripture notes, health
records. Some of that is the kind of information people would be genuinely upset to have
leak. Local-first helps a lot — most of it never leaves the phone — but "most" is not
"all."

## In the apps

1. **Nothing secret in the code.** No API keys, passwords, or tokens in any file in this
   repository. They go in the Keychain on the device, or in GitHub's encrypted secrets
   for build-time values.

2. **Auth state never goes in UserDefaults.** Tokens, session identifiers and anything
   that proves who someone is go in the Keychain. UserDefaults is not encrypted and is
   readable from a device backup.

3. **HTTPS only.** No exceptions in `Info.plist` to allow insecure connections. If a
   service requires one, use a different service.

4. **Ask for permissions at the moment they make sense.** Never on launch. An app that
   demands location before showing anything gets refused, and iOS gives you one chance.
   Every permission needs a usage description that explains the benefit to the user in
   their words.

5. **CloudKit private database by default.** Shared records only where sharing is the
   actual feature, and the user chose it deliberately.

6. **No analytics on personal content.** Count that a journal entry was created. Never
   send what it said.

## In this repository

7. **Branch protection on `main`** — no direct pushes from anyone, including Dave. All
   changes arrive as reviewed proposals.

8. **Least privilege in every workflow.** Each GitHub Actions file declares exactly the
   permissions it needs. The default is far broader than any of these jobs require.

9. **Never `pull_request_target`.** It runs untrusted code with secrets in scope. This is
   the single most common way automated setups get compromised.

10. **Third-party actions pinned to a commit, not a tag.** Tags can be moved by whoever
    owns them; a commit cannot.

11. **Secret scanning with push protection, and Dependabot, both on.** Free, and they
    catch things a reviewing AI will not.

12. **Treat issue text as untrusted.** Anyone who can open an issue can write
    instructions to an AI. Dispatch only runs for people with write access — keep it that way.

## Operator checklist

These are Dave's to do, in GitHub's settings. **Unticked means not done.**

- [ ] Branch protection rule on `main`: no direct push, no force push, no deletion
- [ ] Required status checks: build and tests must pass before merge
- [ ] One approving review required; agents cannot approve
- [ ] Secret scanning + push protection enabled
- [ ] Dependabot alerts enabled
- [ ] Default workflow permissions set to read-only
- [ ] Spending caps set on GitHub Actions **and** on each AI account

The last one is not paranoia. An automated loop that misbehaves overnight is a bill, not
just a bug.

## When something involves money or personal data

It gets reviewed by a second seat, always, no matter how small the change looks. Payment
code and anything touching a user's private content are the two places where a quiet
mistake is expensive rather than annoying.

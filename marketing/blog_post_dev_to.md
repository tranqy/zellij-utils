# I Got Tired of Terminal Session Hell, So I Fixed It

*Tags: #zellij #terminal #productivity #shell #opensource*

## Terminal multiplexers are broken

You know the pain:
- Spend 5 minutes naming sessions 🙄
- "Was it `my-app` or `myapp`?" every. single. time.
- Manually set up the same 4-pane layout daily
- Lose everything when SSH drops

I was wasting more time managing [Zellij](https://github.com/zellij-org/zellij) than actually coding.

## So I automated the annoying parts

**zellij-utils** = smart session management that actually works.

### Auto-names sessions (finally)

```bash
cd ~/work/my-awesome-api && zj
# → session "my-awesome-api" ✨

cd ~/projects/portfolio-site && zj  
# → session "portfolio-site" ✨
```

Git repo? Uses repo name. Project directory? Uses folder name. It just works.

### Instant dev layouts

```bash
zjdev
# → Editor + terminal + git + logs
# In one command. No setup.
```

### Safe session cleanup

```bash
zjd                    # Pick sessions to delete (with fzf)
zjd old-project       # Delete specific (with confirmation)
zjd --all             # Nuclear option (except current)
```

## Why Zellij > tmux

tmux = memorizing weird keybinds  
Zellij = just works, looks modern, has sane defaults

## The remote dev flex 🔥

Start coding on laptop → close laptop → SSH from phone → everything's still there.

Perfect for:
- AI models that take hours to train
- Long-running processes
- Working from anywhere (literally anywhere with internet)

## Try it (30 seconds)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tranqy/zellij-utils/main/scripts/install.sh)
```

Restart terminal. Done.

## It's actually production-ready

- CI/CD tested on Ubuntu + Alpine
- Security audited (input validation, injection prevention)
- Works on Linux, macOS, WSL
- Won't break your existing setup

## What's your terminal setup?

Drop feedback, feature requests, or just roast my code:

**🔗 [GitHub: tranqy/zellij-utils](https://github.com/tranqy/zellij-utils)**  
**💬 [Discussions](https://github.com/tranqy/zellij-utils/discussions)**  
**⭐ [Star if it's useful](https://github.com/tranqy/zellij-utils)**

Still using tmux? Screen? Just raw terminals like a psychopath? Let me know in the comments what your workflow looks like.
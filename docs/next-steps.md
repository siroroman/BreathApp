# Breathnest: ďalšie kroky

Stav k 2026-11-08. Odovzdávací dokument medzi sessions. Hotové body maž, aby nezavádzal.

## Kde sme

- Hotové:
  - git konvencie, `commit-msg` hook a squash merge,
  - guardrails: hooky, ruleset s šiestimi povinnými checkami, review pred koncom draftu, coverage floor 80 % na súbor v Kite (`docs/guardrails-map.html`, ostáva len CodeQL a CODEOWNERS),
  - kostra `docs/agents/` a subagenti,
  - iOS feedback loop: XcodeGen, `BreathnestKit`, Makefile, simulátor na worktree (`docs/agents/commands.md`),
  - kontrola String Catalogu a základ UI testov s accessibility auditom (`make test-ui`),
  - ADR 0001 až 0003: logika v balíku bez UI, architektúra appky, ukladanie dát.
- Product brief, dizajn (`docs/product/phone-design.md`, `docs/product/watch-design.md`) a špecifikácia #22 sú hotové. Návrhy sú záväzné. Tickety sú pod #22: Kit (#23 až #26), iPhone (#28 až #36, #54 až #60), Watch (#38 až #51).
- Rozhodnuté: v1 len iPhone, iOS 26+, zadarmo, systém najprv v tomto repe.

## 1. Teraz (ty)

1. Rozhodni zvuky v #49 (platí pre Watch aj iPhone). Kit ju nepotrebuje, blokuje až zvukové časti.

## 2. Implementácia

Začni ticketom #23 (Kit). Prvý ticket ide s tebou (`start-task`) v čerstvej session, review robí `code-reviewer` v ďalšej čerstvej. Potom AFK cez agenta `implementer`, potom paralelné worktree. Poradie: Kit (#23 až #26), potom obrazovky (#28, #29), potom tvar, kruh a haptika (#30 až #32). Ďalšie iPhone časti (#54 až #60) idú po nich.

Pravidlá: jeden ticket na jednu session (približne 100K tokenov), reset namiesto compactu, odovzdanie cez ticket alebo ADR.

Malé tickety nabok, nič neblokujú: #145 (scopes commitov), #148 (ADR 0003, set-aside dáta), #142 (pozdrav na jednom mieste, zmizne s Kitom), #143 a #144 (skripty).

## 3. Po tracer bullete

Vytiahnuť znovupoužiteľné časti (skilly, hooky, `docs/agents/`, Makefile, CI) do šablóny alebo pluginu a overiť ich na prázdnom repe.

## 4. Rytmus údržby

- `/retro` po každej session, ktorá nešla hladko.
- `/improve-codebase-architecture` každých pár dní.
- `/observe <poznámka>` po míľnikoch.
- Zatvárať hotové špecy a mapy.

## 5. Známe drobnosti

- Prvý commit `Initial commit: .gitignore` nespĺňa konvenciu, históriu neprepisovať.
- `npx skills` nefunguje, kým nemáš Node ≥ 22.20.
- Headless observer (`claude -p`) potrebuje vlastné `claude auth login`, chyby sú v `.observer/log.txt` vo vaulte.
- Hooky odmietnu commit a push na `main` až po `make setup` na danom klone. Push na `main` odmietne GitHub každému vrátane admina.
- CI macOS minúty sa na súkromnom repe počítajú 10×, workflow držať štíhly.

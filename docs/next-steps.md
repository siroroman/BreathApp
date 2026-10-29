# Breathnest: ďalšie kroky

Stav k 2026-10-29. Odovzdávací dokument medzi sessions. Hotové body maž, aby nezavádzal.

## Kde sme

- Hotové:
  - git konvencie a `commit-msg` hook,
  - squash merge,
  - guardrails hook proti deštruktívnym git príkazom,
  - `/setup-matt-pocock-skills` (GitHub Issues, predvolené triage štítky, single-context),
  - kostra `docs/agents/` a subagentov.
- Product brief, prepis hlasovej poznámky a vizuálne referencie sú v `docs/product/`.
- Mapa (#8) a špecifikácia (#22) sú hotové. Tickety sú pod #22: Kit (#23 až #26), iPhone (#28 až #36, #54 až #60), Watch (#38 až #51).
- Rozhodnuté: v1 len iPhone, iOS 26+, zadarmo, systém najprv v tomto repe.
- Vizuál je hotový v Claude Design: `docs/product/phone-design.md` (iPhone) a `docs/product/watch-design.md` (Watch), zdroje v `docs/product/design/`. Návrhy sú záväzné.

## 1. Teraz (ty)

1. Skontroluj draft PR #61 (iPhone dizajn do docs) a zmerguj ho.
2. Rozhodni otvorené body dizajnu v #53. Najprv Safety note a light mode, blokujú #28. Potom slider vs 4-7-8, Settings, pravidlá Logu a pripomienok.
3. Rozhodni zvuky v #49 (platí pre Watch aj iPhone).
4. Spusti iOS feedback loop (sekcia 2). Bez neho sa nedá začať ani #23, ani #28.

## 2. Paralelne: iOS feedback loop (samostatná session)

Nezávisí od mapy, potrebuje len bundle ID (návrh `com.siroroman.breathnest`).

- XcodeGen `project.yml` (`.xcodeproj` je v `.gitignore`).
- Lokálny Swift package `BreathnestKit` len s Foundation, `swift test` bez simulátora.
- Makefile: `gen`, `build`, `test`, `lint`, `format`, `run`, výstup cez `xcbeautify --quiet`.
- Simulátor s pevným menom, klon na každý worktree.
- swiftformat hook, povolenia bezpečných príkazov, Stop hook `make lint test`.
- Vyplniť TODO v `docs/agents/{commands,ios,testing,definition-of-done,workflow}.md`.
- Doménovú logiku bez UI zapísať do ADR (kvôli Watch neskôr a AFK ticketom v cloude).

## 3. Po feedback loope

`/implement` na #23 (Kit). Prvý ticket ide HITL v čerstvej session, review v ďalšej čerstvej. Potom AFK pod dozorom, potom paralelné worktree. Poradie: Kit (#23 až #26), potom obrazovky (#28, #29), potom tvar, kruh a haptika (#30 až #32). Ďalšie iPhone časti (#54 až #60) idú až po #53.

Pravidlá: jeden ticket na jednu session (približne 100K tokenov), reset namiesto compactu, odovzdanie cez ticket alebo ADR.

## 4. Po tracer bullete

Vytiahnuť znovupoužiteľné časti (skilly, hooky, `docs/agents/`, Makefile, CI) do šablóny alebo pluginu a overiť ich na prázdnom repe.

## 5. Rytmus údržby

- `/retro` po každej session, ktorá nešla hladko.
- `/improve-codebase-architecture` každých pár dní.
- `/observe <poznámka>` po míľnikoch.
- Zatvárať hotové špecy a mapy.

## 6. Známe drobnosti

- Prvý commit `Initial commit: .gitignore` nespĺňa konvenciu, históriu neprepisovať.
- `npx skills` nefunguje, kým nemáš Node ≥ 22.20.
- Headless observer (`claude -p`) potrebuje vlastné `claude auth login`, chyby sú v `.observer/log.txt` vo vaulte.
- Zákaz commitov na `main` zatiaľ nie je vynútený.
- CI macOS minúty sa na súkromnom repe počítajú 10×, workflow držať štíhly.

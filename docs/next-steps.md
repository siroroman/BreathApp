# Breathnest: ďalšie kroky

Stav k 2026-10-23. Odovzdávací dokument medzi sessions. Hotové body maž, aby nezavádzal.

## Kde sme

- Hotové:
  - git konvencie a `commit-msg` hook,
  - squash merge,
  - guardrails hook proti deštruktívnym git príkazom,
  - `/setup-matt-pocock-skills` (GitHub Issues, predvolené triage štítky, single-context),
  - kostra `docs/agents/` a subagentov,
  - iOS feedback loop: XcodeGen, `BreathnestKit`, Makefile, simulátor na worktree, hooky (`docs/agents/commands.md`).
- Product brief, prepis hlasovej poznámky a vizuálne referencie sú v `docs/product/`.
- Rozhodnuté: v1 len iPhone, iOS 26+, zadarmo, systém najprv v tomto repe.
- Vizuál vznikne cez Claude Design až po špecifikácii.

## 1. Teraz (ty)

1. Skontroluj stĺpec „Take“ v `docs/product/references/README.md` a oprav, čo nesedí.
2. `/observe` s odkazom na sekciu „How the system is measured“ v `docs/product/brief.md`.
3. `/wayfinder` s destináciou: „Spec for the Breathnest tracer bullet (list → detail → breathing session), ready for `/to-tickets`.“
   - Do Notes: `swiftui-expert-skill`, `swift-concurrency-pro`, `domain-modeling`.
   - Mal by vzniknúť research ticket o technikách, prototype o pocite z kruhu a haptiky a grilling o rozsahu MVP.

## 3. Po mape

`/to-spec` → `/to-tickets` → `/implement`. Prvý ticket ide HITL v čerstvej session, review v ďalšej čerstvej. Potom AFK pod dozorom, potom paralelné worktree.

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

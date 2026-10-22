# BreathApp: ďalšie kroky

Stav k 2026-10-22. Odovzdávací dokument pred vyčistením kontextu. Po vyriešení bodov ho zmaž alebo zatvor, aby nezavádzal budúce sessions.

## Kde sme

- Repo: https://github.com/siroroman/BreathApp (súkromné), `main` obsahuje len `.gitignore`.
- PR #1 `docs: add git conventions and commit-msg check` (vetva `docs/git-conventions`) čaká na tvoj merge: https://github.com/siroroman/BreathApp/pull/1
- Vo vetve: `CLAUDE.md`, `docs/agents/git.md`, `scripts/check-commit-msg.sh`, `.githooks/commit-msg`.
- Rozhodnuté: GitHub flow, Conventional Commits, kontrola cez hook (nie cez skill), artefakty (GLOSSARY, ADR, tickety, kód) po anglicky.
- Pripravené: všetky Pocockove skilly sú nainštalované v `~/.claude/skills`, observer je zapnutý (`.claude/observer.json`, lokálne mimo gitu).
- Hotové poznámky o Pocockovi: `~/Desktop/Knowledge base/Agentic dev/Mat Pockock/`.

## 1. Hneď (ty)

1. Zmerguj PR #1 (squash), potom `git checkout main && git pull`.
2. V každom ďalšom klone: `git config core.hooksPath .githooks` (v tomto repe už zapnuté).
3. Spusti `/setup-matt-pocock-skills` (agent ho sám nespustí). Odporúčané odpovede: GitHub Issues, predvolené triage štítky, single-context. CLAUDE.md už existuje, skill do neho len doplní `## Agent skills`.
4. Nainštaluj `git-guardrails-claude-code` len pre tento projekt a nastav výnimku: povoliť `git push origin <vetva>`, blokovať force push, `reset --hard`, `clean`, `branch -D`. V pôvodnom nastavení blokuje každý push, takže by sa nedali otvárať PR.

## 2. Pred špecifikáciou (ty, približne hodina)

- **Hrubý brief vlastnými slovami:** pre koho appka je, čo je úspech, obmedzenia (offline, súkromie, cena), nápady aj veci, ktoré nechceš.
- **Priorita:** produkt alebo experiment s agentmi. Pri konflikte musí jedno vyhrať.
- **Vzory na vkus:** pár screenshotov appiek (Calm, Breathwrk, Oak, Apple Mindfulness) s poznámkou, čo sa páči a čo nie. Uložiť do repa.
- **Kandidát na prvý tracer bullet**, napr. „spustím box breathing, kruh animuje fázy, vidím záverečnú obrazovku“.
- **Hypotézy a metriky experimentu**, poslať cez `/observe`: koľko ticketov prejde bez tvojho zásahu, koľko zásahov na PR, kde sa agent zasekáva, chyby z QA, ktoré prešli cez zelené testy.
- **Rozhodnutia, ktoré agent nevie urobiť:** bundle ID, Apple Developer tím, minimálna verzia iOS (navrhnuté 26 alebo 27), schopnosti (HealthKit Mindful Minutes, notifikácie, Live Activities, Apple Watch).

## 3. Plánovanie (s agentom)

1. `/wayfinder` charting. Prirodzene vzniknú štyri typy ticketov:
   - research: dychové techniky (box, 4-7-8, coherent, physiological sigh), parametre, bezpečnostné upozornenia,
   - prototype: ako má dýchanie pôsobiť (animácia, haptika),
   - grilling: rozsah MVP,
   - task: Apple Developer, bundle ID, entitlementy.
2. Prechádzanie mapy: jedna session na jeden ticket, research tickety paralelne.
3. Keď je mapa prázdna: `/to-spec` → `/to-tickets` (AFK alebo HITL) → `/implement`.
4. `/grill-with-docs` vytvorí `GLOSSARY.md` a ADR. Do ADR patrí rozhodnutie, že doménová logika je Swift package závislý len od Foundation (beží aj na Linuxe, takže logické tickety môžu ísť AFK v cloude, UI tickety lokálne).

## 4. Autonómia (stupne)

1. Jeden ticket HITL v čerstvej session, review v ďalšej čerstvej.
2. Jeden AFK ticket opakovane pod dozorom, ladíš prompt a popis ticketu.
3. Paralelné worktree sessions alebo `/implement-spec`.
4. `chief-of-staff` ako koordinátor dlhodobého cieľa.

Pravidlá: jeden ticket na jednu session, približne 100K tokenov, reset namiesto compactu, odovzdanie cez ticket alebo ADR.

## 5. Rytmus údržby

- `/retro` po každej session, ktorá nešla hladko.
- `/improve-codebase-architecture` každých pár dní.
- `/observe <poznámka>` po míľnikoch.
- Zatvárať alebo mazať hotové špecy a mapy (doc rot).

## 6. Automatizácia gitu (zatiaľ nevynútené)

- CI (GitHub Actions, Ubuntu runner, lacný): kontrola názvu PR cez `printf '%s' "$PR_TITLE" | scripts/check-commit-msg.sh -`.
- Nastavenie repa: squash merge s názvom PR ako commit správou.
- Zákaz commitov na `main`: branch protection na súkromnom repe zadarmo nie je, alternatíva je lokálny `pre-commit` hook.
- Zoznam scopes doplniť po module mape.

## 7. Odložené (iOS, riešiť neskôr podľa tvojho rozhodnutia)

Štandardy kódu, nastavenie, hooky, MCP a skilly pre iOS vývoj:

- XcodeGen `project.yml` (`.xcodeproj` je v `.gitignore`),
- lokálny Swift package s logikou a `swift test`,
- Makefile (`gen`, `build`, `test`, `lint`, `format`, `run`), výstup cez `xcbeautify --quiet`,
- pevný simulátor a klon simulátora na worktree,
- hook so swiftformat, povolenia pre bezpečné príkazy, Stop hook `make lint test`,
- CI na macOS runneri (minúty na súkromnom repe sa počítajú 10×),
- skilly `swiftui-expert-skill`, `swift-concurrency-pro` sú nainštalované.

## 8. Známe drobnosti

- Prvý commit `Initial commit: .gitignore` nespĺňa konvenciu, je už na `main`, históriu neprepisovať.
- PR #1 nie je draft, hoci `git.md` hovorí „draft do `/code-review`“.
- `npx skills` nefunguje, kým nemáš Node ≥ 22.20 (máš 20.19).
- `resolving-merge-conflicts` z leaderboardu v `mattpocock/skills` neexistuje, neodporúčať.
- Headless observer (`claude -p`) potrebuje vlastné `claude auth login`. Chyby sú v `.observer/log.txt` vo vaulte.

## 9. Pôvodný návrh prípravy (10 bodov) so stavom

Vychádza z úvodnej analýzy prázdneho projektu. Nástroje sú pripravené: Xcode 27, simulátor s iOS 27, xcodegen, tuist, swiftlint, swiftformat, xcbeautify, `gh` (prihlásené). Hlavná myšlienka: agent pracuje dobre len vtedy, keď si vie výsledok svojej zmeny overiť sám, rýchlo a vždy rovnako, preto sa pred špecifikáciou oplatí pripraviť hlavne túto spätnú väzbu.

### Infraštruktúra (najväčší prínos)

1. **Git a GitHub repo hneď na začiatku.** Bez gitu nefungujú worktree pre paralelné sessions ani PR a ťažko sa vracajú zmeny. Observer číta git históriu. *Stav: hotové.*
2. **Xcode projekt v textovom súbore cez XcodeGen.** `project.pbxproj` je pre agentov nevhodný (konflikty pri paralelných vetvách, ručné UUID). `project.yml` v repe, `.xcodeproj` v `.gitignore` (už tam je). Tuist len pri viacerých moduloch a cache, XcodeGen je jednoduchší. *Stav: odložené (iOS).*
3. **Logika v lokálnom Swift package, ktorý beží aj na macOS.** `swift test` zbehne za pár sekúnd bez simulátora. Časovač dychových fáz (nádych, zadržanie, výdych, odpočet) sa hodí na TDD, ak sa hodiny podajú zvonka (cez `Clock`). *Stav: odložené (iOS), rozhodnutie zapísať do ADR.*
4. **Na každý typ kontroly jeden príkaz.** Makefile s cieľmi `gen`, `build`, `test`, `lint`, `format`, `run` (build, spustenie v simulátore, screenshot). Výstup cez `xcbeautify --quiet`. Simulátor s pevným menom, každý worktree s vlastným klonom simulátora, inak sa paralelné sessions budú biť o ten istý. *Stav: odložené (iOS).*

### Pravidlá pre agenta

5. **Krátky CLAUDE.md** s príkazmi, štruktúrou a konvenciami. Hlavne definícia „hotovo“: build, testy aj lint sú zelené a zmena UI je overená screenshotom. Nepísať dlhý vopred, nech rastie z retrospektív. *Stav: CLAUDE.md existuje so sekciou Git, definícia „hotovo“ chýba (doplniť po bode 4).*
6. **Ochranné pravidlá v `.claude/settings.json`:**
   - povolené bezpečné príkazy (`make`, `xcodebuild`, `git`, `gh`), menej žiadostí o povolenie znamená dlhšie samostatné behy,
   - hook, ktorý po každej úprave súboru spustí swiftformat,
   - skill `git-guardrails`, ktorý zablokuje `push --force` a `reset --hard`,
   - prípadne Stop hook, ktorý spustí `make lint test`, aby agent neskončil s červenými testami.

   *Stav: `git-guardrails` je v kroku 1.4, zvyšok odložený (iOS).*
7. **CI cez GitHub Actions na macOS runneri.** Vonkajšia slučka: aplikácia vie pri PR reagovať na padnuté CI aj komentáre z review. Pozor: macOS minúty sa pri súkromnom repe počítajú 10×, workflow držať štíhly. *Stav: nič zatiaľ, lacná kontrola názvu PR je v časti 6.*

### Pred špecifikáciou

8. **Rozhodnutia, ktoré agent za teba nespraví:** bundle ID a Apple Developer tím, minimálna verzia iOS (navrhnuté 26 alebo 27: najnovšie API, Liquid Glass, menej kódu kvôli kompatibilite), schopnosti (HealthKit Mindful Minutes, notifikácie, Live Activities, Apple Watch). Ovplyvnia architektúru aj entitlementy, preto patria pred špecifikáciu. *Stav: čaká na teba, pozri časť 2.*
9. **Dohodnutý postup práce:** `grill-me` → `domain-modeling` (GLOSSARY.md a ADR) → `to-spec` → `triage` do GitHub issues po malých kúskoch naprieč vrstvami → `implement-spec` alebo `tdd` pre každé issue v samostatnej worktree session → `code-review` → PR. Špecifikácia v repe (`docs/`), úlohy ako GitHub issues. *Stav: upresnené v častiach 3 a 4 (pridaný `wayfinder` a `to-tickets`).*
10. **Spôsob vyhodnotenia experimentu:** zapísať hypotézy vopred, aby ich mal observer s čím porovnať:
    - koľko úloh prejde celých bez tvojej úpravy kódu,
    - koľkokrát musíš zasiahnuť pri jednom PR,
    - kde sa agent zasekáva (typicky slabšie zvláda animácie, haptiku a pocit z UI, logiku zvláda dobre).

    Poslať ako poznámku cez `/observe`. *Stav: čaká na teba, pozri časť 2.*

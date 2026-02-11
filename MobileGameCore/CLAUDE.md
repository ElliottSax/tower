# MobileGameCore - Production Agent Instructions

## Mission
Transform MobileGameCore into a battle-tested, production-ready Unity package that ACCELERATES REVENUE across ALL mobile games.

## Current Status (v1.0.0)
- **17 Core Systems**: Complete extraction from Treasure Chase (6,500+ LOC)
- **Quality**: Production-ready code with XML docs, error handling
- **Gap**: Missing critical production infrastructure for Unity package publishing

## Priority Work (Revenue-First)

### CRITICAL: Missing Production Infrastructure
1. **Assembly Definition Files** (.asmdef)
   - Runtime assembly (MobileGameCore.Runtime.asmdef)
   - Editor assembly (MobileGameCore.Editor.asmdef)
   - Test assembly (MobileGameCore.Tests.asmdef)
   - Enables fast compilation, proper dependency management

2. **Unity IAP Integration** (HIGHEST REVENUE IMPACT)
   - IAPManager.cs - UnityIAP wrapper with product catalog
   - Consumables, non-consumables, subscriptions
   - Receipt validation (server-side ready)
   - Restore purchases (iOS requirement)
   - Product metadata caching
   - **WHY**: Direct revenue stream, required for premium features

3. **Remote Config System**
   - RemoteConfigManager.cs - Unity Remote Config integration
   - A/B testing support
   - Live economy tuning (prices, rewards)
   - Feature flags
   - **WHY**: Optimize monetization without app updates

4. **Enhanced Analytics**
   - Revenue events (IAP, ad impressions)
   - Funnel tracking (FTUE, conversion)
   - Retention metrics (D1, D7, D30)
   - **WHY**: Data-driven monetization optimization

### Production Packaging
- [ ] Unity meta files for all assets
- [ ] Package.json with proper dependencies
- [ ] CHANGELOG.md (semantic versioning)
- [ ] Installation guide with screenshots
- [ ] Example scenes (minimal test scenes)

### Testing & Quality
- [ ] Unit tests for core systems (SaveSystem, EconomyManager)
- [ ] Integration tests (IAP → Economy → Analytics flow)
- [ ] Performance benchmarks (mobile-specific)
- [ ] Memory leak detection

## Architecture Decisions

### Why Assembly Definitions?
- **Fast Iteration**: Only recompile changed assemblies
- **Clean Dependencies**: Prevent circular references
- **Package Distribution**: Required for UPM (Unity Package Manager)

### Why UnityIAP Focus?
- **Direct Revenue**: #1 monetization source for premium features
- **Universal**: Works across iOS, Android, Amazon
- **Required**: For premium currency, ad removal, VIP subscriptions

### Why Remote Config?
- **Live Tuning**: Change prices, rewards without app update
- **A/B Testing**: Optimize conversion rates
- **Kill Switches**: Disable buggy features remotely

## Integration Pattern (For Game Projects)

```csharp
// GameBootstrap.cs - Initialize in order
void Start() {
    // 1. Core
    SaveSystem.Instance.Initialize();

    // 2. Analytics (track everything)
    AnalyticsManager.Instance.Initialize();

    // 3. Remote Config (fetch latest values)
    RemoteConfigManager.Instance.FetchConfig(() => {
        // 4. Economy (use remote values)
        EconomyManager.Instance.Initialize();

        // 5. IAP (revenue!)
        IAPManager.Instance.Initialize();

        // 6. Ads (backup revenue)
        AdManager.Instance.Initialize();

        // Ready!
        StartGame();
    });
}
```

## Synergies with Other Projects

### MobileGameCore → Game Projects
- **LootStackMayhem**: IAP for premium loot boxes, ad removal
- **BlockBlastEvolved**: IAP for hero unlocks, power-ups
- **TreasureChase**: IAP for character skins, double coins
- **PetQuestLegends**: IAP for legendary pets, XP boosters

### Shared Patterns
- All games use same IAP setup → copy-paste integration
- All games use same analytics events → consistent tracking
- All games use same remote config → centralized control

## Revenue Impact Estimate

**Without MobileGameCore**:
- 20-40 hours per game to build monetization
- Custom IAP code (bugs, edge cases)
- No remote config (can't optimize)

**With MobileGameCore**:
- 2-4 hours integration per game
- Battle-tested IAP (no bugs)
- Live economy tuning
- **Time Saved**: 15-35 hours per game × 5 games = 75-175 hours

**Revenue Impact**:
- Faster to market → earlier revenue
- Tested IAP → fewer lost transactions
- Remote config → higher ARPU through optimization
- Consistent analytics → better decision-making

## Success Metrics
- [ ] Package installs in <5 minutes
- [ ] IAP transaction in <10 lines of code
- [ ] Zero compilation errors across platforms
- [ ] Published to GitHub/OpenUPM
- [ ] Used in production by 3+ games

## Next Session Priorities
1. Create assembly definitions (unblocks UPM)
2. Build IAPManager (highest revenue impact)
3. Add RemoteConfigManager (live tuning)
4. Write integration guide with code examples
5. Commit with conventional commits
6. Update status to .agent-bus/

## Notes
- Keep zero asset dependencies (runtime generation FTW)
- Mobile-first: test on actual devices
- Revenue-first: prioritize monetization features
- Documentation: every public API needs XML comments
- Testing: integration tests for revenue flows

---
Last Updated: 2026-02-10
Agent: mobilecore-agent
Version: 1.0.0 → 1.1.0 (targeting)

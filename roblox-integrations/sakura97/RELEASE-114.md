# Void scene revision 114

Reference: user-provided IMG_2257.jpeg. The player is shown from behind in the lower foreground, legs cropped off-screen, with swimming motion and messages behind the avatar. Prefer the character swim animation, then Roblox R15 default swim; procedural fallback remains for unavailable tracks/R6.

Messages: cuidado / não pule mais no void / já pensou como é a vida pós morte? / Volte…

Fourteen faint blue glow layers, one faint upper light and ten small bubble rings. No additional texture downloads. After messages, text and atmosphere fade for 1.6 seconds as the avatar moves upward and becomes smaller. Only then does Regenerar fade in and become active. Original requested music and click sound are retained. Server recovery timeout increased to 60 seconds.

Validation executes the actual client controller with real engine UI/avatar instances and adapters for local-player/client events. Covers phrase order, layer ordering, button gating, transition targets, effect hiding, finish/respawn cleanup and repeated starts. This is a headless structural/lifecycle test, not a rendered visual comparison or phone performance test.

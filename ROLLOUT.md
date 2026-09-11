# Yayılım durumu

Ölçüm tarihi: 2026-09-11. Her satır, o repoya `scripts/adopt.sh` ile
verilecek parametreleri taşır.

| Repo | Scheme | Proje | Hedef | XcodeGen | Test | Durum |
|---|---|---|---|---|---|---|
| FrameMate | FrameMate | VideoRecorder.xcodeproj | macOS | evet | 727 | **bağlandı (pilot)** |
| folio | Folio | Folio.xcodeproj | iOS Sim | evet | 67 dosya | bekliyor |
| memora-app | Memora | Memora.xcodeproj | iOS Sim | evet | 532 dosya | bekliyor |
| DeepFind | DeepFind | DeepFind.xcodeproj | macOS | evet | 139 dosya | bekliyor |
| tesbihim | Tesbihim | Tesbihim.xcodeproj | iOS Sim | evet | 23 dosya | bekliyor |
| VoiceMate | VoiceMate | VoiceMate.xcodeproj | iOS Sim | evet | 11 dosya | bekliyor |
| kelime-oyunu | KelimeOyunu | KelimeOyunu.xcodeproj | iOS Sim | evet | 6 dosya | bekliyor |
| kelimelerim | Kelimelerim | Kelimelerim/Kelimelerim.xcodeproj | iOS Sim | hayır | 6 dosya | bekliyor |
| OneDay | OneDay | OneDay.xcodeproj | iOS Sim | hayır | 2 dosya | bekliyor |
| EditMate | ? | ? | ? | ? | ? | yerelde klasörü yok |

Dokunulmayanlar (kod deposu değil): `memora`, `oneday-support`,
`folio-privacy`, `kelimelerim-legal`, `harfoni-privacy`, `voicemate-privacy`,
`oneday-privacy`, `deepfind-certificates`, `voicemate-certificates`.

## Yayılım mekanik değil — bilinen engeller

Workflow'u eklemek tek başına yetmiyor; bu repolarda CI zaten vardı ve
çürümüştü. Her birinde ayrıca çözülmesi gereken şeyler:

- **tesbihim** — 29 Temmuz'daki son koşuda gerçek test hataları var
  (simülatörde AudioConverter -302 ve LLDB hatası eşliğinde). Yeşile
  getirilmesi ayrı bir iş.
- **folio** — 25 Ağustos'tan beri kırmızı; başarısız adımın log'u boş
  döndü, ayrıca incelenmeli.
- **kelimelerim** — `ci.yml` var ama hiç koşmamış (0 run). XcodeGen yok,
  proje bir alt klasörde.
- **kelime-oyunu** — paylaşılan scheme yok; `project.yml` olduğu için
  `xcodegen generate` üretecek, ama doğrulanmalı.
- **OneDay** — XcodeGen yok, yalnız 2 test dosyası var. Muhtemelen
  `run-tests: false` ile yalnız derleme olarak başlamalı.
- **EditMate** — yerelde klasörü yok; önce klonlanmalı.

## Sıra

1. FrameMate (pilot) — bitti, doğrulanıyor.
2. DeepFind, memora-app, VoiceMate — CI'ı hiç olmayan, testi olan repolar.
   Kırılacak mevcut bir şey yok.
3. folio, tesbihim — mevcut kırmızı CI'ın sebebi önce çözülmeli.
4. kelimelerim, kelime-oyunu, OneDay — yapısal iş gerekiyor.
5. EditMate — klonlandıktan sonra.

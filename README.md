# apple-ci

Apple projelerinin ortak CI tanımı. Her proje kendi workflow mantığını
taşımak yerine buradaki workflow'u çağırır; düzeltme bir kez burada yapılır,
tüm projelere yayılır.

Bu depo herkese açıktır ve **hiçbir sır, anahtar veya sertifika içermez**.
Açık olmasının tek sebebi, private repoların onu `workflow_call` ile
sürtünmesiz çağırabilmesidir.

## Ne yapar

İki bağımsız job:

| Job | Runner | Fiyat | İçerik |
|---|---|---|---|
| Hızlı kontroller | `ubuntu-latest` | 1x | gitleaks sır taraması, depo hijyeni (sertifika/anahtar takip ediliyor mu), projeye özel script'ler |
| Derleme ve test | `macos-15` | 10x | XcodeGen, `xcodebuild test`, SwiftFormat, SwiftLint, hata halinde `.xcresult` artifact |

Job'lar birbirine bağlı **değildir**. Sır taramasının yanlış alarmı
testlerin koşmasını engellemez — bu, sistemin kurulma sebebiydi.

## Ne yapmaz

İmzalama, App Store yüklemesi, release, tag, notarization yok. Salt-okunur
bir kalite kapısıdır.

## Maliyet

Tüm projeler private; GitHub'da macOS runner dakikası **10x** çarpanla
faturalanır (2000 dk kota ≈ 200 macOS dakikası). Tasarım bunu üç yerde
kısıyor:

- Ucuz işler ubuntu'da (1x).
- `concurrency.cancel-in-progress` — üst üste push'ta eski koşu iptal.
- `paths-ignore` — yalnız dokümantasyon veya metadata değişince macOS job'u
  hiç başlamaz.
- Araçlar yalnız runner imajında yoksa kurulur (`brew install` her koşuda
  dakikalar yakıyordu).

Kota yine de yetmezse bir sonraki adım kendi Mac'inde self-hosted runner.

## Yeni projeye ekleme

```bash
scripts/adopt.sh /yol/proje --scheme Ad --project Ad.xcodeproj
```

Script `.github/workflows/ci.yml` ve `.github/dependabot.yml` dosyalarını
yazar; mevcut dosyanın üzerine yazmadan önce sorar.

## Girdiler

`.github/workflows/apple-ci.yml` içindeki `workflow_call.inputs` bölümü
kaynaktır. Sık kullanılanlar:

- `scheme` (zorunlu)
- `project` / `workspace`
- `destination` — macOS projeleri için `platform=macOS`
- `xcodegen` — `project.yml` kullanan projelerde `true`
- `run-tests` — test target'ı olmayan repolarda `false` (yalnız derler)
- `xcode-version` — `26.6` gibi; imaj güncellemesine karşı sabitler
- `extra-checks` / `extra-macos-checks` — projeye özel komutlar

## Yanlış alarm çıkarsa (gitleaks)

**`.gitleaksignore` kullanma.** Oradaki fingerprint'ler commit sha'sına
bağlıdır: dosya bir daha düzenlendiği anda fingerprint değişir ve istisna
sessizce geçersiz olur. FrameMate'te tam olarak bu oldu — `.gitleaksignore`
vardı, dosya sonradan düzenlendi, CI altı koşu boyunca kırmızı kaldı ve
kimse sebebini aramadı.

Bunun yerine projeye dar kapsamlı bir `.gitleaks.toml` ekle: `targetRules` +
`paths` + `regexes` ile yalnız o kalıbı serbest bırak. Sonra **aynı dosyaya
sahte bir sır koyup hâlâ yakalandığını doğrula** — istisnanın dar olduğunun
tek kanıtı budur. Örnek: FrameMate deposundaki `.gitleaks.toml`.

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
| Hızlı kontroller | `ubuntu-latest` (`checks-runs-on` ile değiştirilebilir) | 1x | gitleaks sır taraması, depo hijyeni (sertifika/anahtar takip ediliyor mu), projeye özel script'ler |
| Derleme ve test | `macos-15` | 10x | XcodeGen, `xcodebuild test`, SwiftFormat, SwiftLint, hata halinde `.xcresult` artifact |

Hızlı kontroller platformdan bağımsızdır; `checks-runs-on` ile self-hosted bir
Mac'e alınabilirler. Varsayılan ubuntu olmaya devam ediyor çünkü 1x fiyatlı ve
Mac kapalıyken de koşuyor — ama GitHub'ın barındırdığı runner'a hiç
erişilemeyen bir projede (kota dolmuş, harcama limiti sıfır) kontrollerin hiç
koşmaması yerine Mac'te koşması yeğdir.

`pre-build` girdisi, proje dosyasının başvurduğu ama depoya girmeyen yerel
dosyalar içindir (imza xcconfig'i gibi). Taze bir kopyada böyle bir dosyanın
yokluğu derlemeyi tek bir testi bile koşturmadan düşürür; komut checkout'tan
sonra, xcodegen'den önce koşar.

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

## Self-hosted runner (kendi Mac'inde)

macOS job'unu kendi makinende koşturmak icin caller'a `runs-on: self-hosted`
ekle. Kurulum: GitHub'in resmi runner'i, depo ayarlarindan alinan kayit
anahtariyla, `~/actions-runner/<proje>` altinda; `./svc.sh install && start`
ile servis olur.

Olculen fark (FrameMate): GitHub'in Mac'inde 201 sn, kendi Mac'inde 82 sn.
macOS faturalandirma kalemi tamamen kayboluyor.

**Kisit:** kisisel hesapta runner yalniz DEPO seviyesinde tanimlanabilir.
Tek runner'i birden cok repoda paylasmak icin ucretsiz bir organizasyon
kurup repolari oraya tasimak gerekir.

**Guvenlik:** yalniz private depolarda kullan. Public bir depoda herkes
fork acip pull request ile senin makinende kod calistirabilir.

### Self-hosted'a gecerken dikkat

Bu ikisi yalniz gercek bir kosuda ortaya cikti:

- **SPM onbellegi kapatilmali.** `DerivedData/**/SourcePackages` yolu
  GitHub'in tek kullanimlik makinesinde yalniz o projeyi kapsar; kendi
  Mac'inde daha once derledigin HER projeyi kapsar (olculdu: 468 MB, hicbiri
  test edilen projeye ait degil). Ortak workflow bunu `runs-on` self-hosted
  iceriyorsa otomatik atliyor.
- **`.env` icindeki LANG'e bak.** `config.sh` makinenin dilini yaziyor
  (`tr_TR.UTF-8`). Turkce locale'in noktasiz-i davranisi derlemede tuhaf
  hatalara yol acabiliyor; `en_US.UTF-8` birak ve tek satir oldugundan emin ol.
- **Izin pencereleri.** Servis arka planda kostugu icin macOS'un izin
  penceresini kimse tiklayamaz ve test sonsuza kadar bekler. Bir test suiti
  aciklanamayan sekilde donuyorsa once bunu supheli gor.

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

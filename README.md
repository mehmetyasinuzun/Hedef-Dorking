# Hedef Dorking

Google Dork sorgusu ureten Windows masaustu uygulamasi. OSINT (acik kaynak istihbarat) amacli kullanilir.

Kullanici dork listesinden secer, hedef domainini yazar, gerekirse gelismis filtreler ekler. Uygulama bu bilgileri birlestirip tarayicida Google aramasini acar.

## Nasil Calisir

```
Kullanici hedef + dork secer
    -> Flutter bu bilgilerden sorgu uretir
    -> Go backend'e { "sorgu": "..." } olarak yollar
    -> Go backend Google URL olusturur
    -> Varsayilan tarayicida arama acilir
```

Flutter tarafinda dork secimi, hedef domain isleme ve filtre birlestirme yapilir.
Go tarafinda sadece gelen sorguyu Google'da acma ve loglama vardir.

## Dizin Yapisi

```
Hedef-Dorking/
├── backend/
│   ├── main.go                 # Go backend kaynak kodu
│   └── go.mod                  # Go modul dosyasi
│
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart           # Uygulama giris noktasi
│   │   ├── home_screen.dart    # Ana ekran, sorgu uretimi
│   │   ├── dork_card.dart      # Dork kart widget'i
│   │   ├── api_service.dart    # Backend ile iletisim
│   │   ├── backend_launcher.dart  # Backend exe baslatma
│   │   ├── constants.dart      # Renkler ve sabitler
│   │   └── models.dart         # Dork veri modeli
│   │
│   ├── assets/backend/
│   │   ├── dorking.exe         # Derlenm. backend (build.bat uretir)
│   │   └── dorklar_45.json     # 45 adet dork verisi
│   │
│   ├── pubspec.yaml            # Flutter bagimliliklari
│   └── windows/                # Flutter Windows runner
│
├── tools/
│   └── new-portable-package.ps1  # Portable paketleyici
│
├── dist/
│   └── hedef_dorking_portable.exe  # Tek dosya portable surum
│
├── build.bat                   # Otomotik derleme
├── portable.bat                # Portable EXE uretme
└── .gitignore
```

## API

Tek endpoint vardir:

**POST /api/ara**

Istek:
```json
{
  "sorgu": "site:example.com intitle:admin filetype:pdf"
}
```

Basarili yanit (200):
```json
{
  "basarili": true,
  "veri": {
    "acilan_url": "https://www.google.com/search?q=..."
  }
}
```

Hata durumlari:
- 405: POST disinda bir method gonderilirse
- 400: Sorgu bos veya JSON hatali ise
- 500: Tarayici acilamazsa

## Gereksinimler

Asagidakilerin bilgisayarda kurulu olmasi gerekir:

| Arac           | Surum   | Neden Gerekli                  | Indirme Adresi                              |
|----------------|---------|--------------------------------|---------------------------------------------|
| Go             | 1.21+   | Backend derlemek icin          | https://go.dev/dl/                          |
| Flutter        | 3.x+    | Masaustu arayuz icin           | https://docs.flutter.dev/get-started/install |
| Visual Studio  | 2022    | Flutter Windows build icin (*) | https://visualstudio.microsoft.com/          |
| Git            | herhangi| Repo klonlamak icin            | https://git-scm.com/                         |

(*) Visual Studio kurulumunda "Desktop development with C++" is yukunu (workload) secmelisiniz.
Flutter Windows build'i bu C++ araclarini kullanir.

### Kurulum Kontrolu

Herseyin dogru kuruldugunu dogrulamak icin:

```
go version
flutter doctor
git --version
```

`flutter doctor` ciktisinda Windows Desktop satiri yesil tik olmali.

## Derleme (Adim Adim)

### Yontem 1: Otomatik (Tek Komut)

```bat
build.bat
```

Bu script sirasiyla su adimlari yapar:
1. Go backend'i derler (`backend/dorking.exe`)
2. Derlenen exe'yi Flutter assets klasorune kopyalar
3. `flutter pub get` ile Flutter bagimlilikalarini yukler
4. `flutter build windows --release` ile arayuzu derler
5. Derlenen uygulamayi acar

### Yontem 2: Manuel (Adim Adim)

Komut satirinda Hedef-Dorking klasorunun icine girin:

```bat
cd Hedef-Dorking
```

Go backend'i derleyin:

```bat
cd backend
go build -o dorking.exe .
cd ..
```

Derlenen exe'yi Flutter assets'e kopyalayin:

```bat
copy backend\dorking.exe flutter_app\assets\backend\dorking.exe
```

Flutter bagimlialarini yukleyin:

```bat
cd flutter_app
flutter pub get
```

Uygulamayi derleyin:

```bat
flutter build windows --release
```

Derlenen uygulamayi calistirin:

```bat
start build\windows\x64\runner\Release\hedef_dorking.exe
```

## Portable EXE Uretme

Derleme tamamlandiktan sonra, uygulamayi tek bir exe dosyasina paketlemek icin:

```bat
portable.bat
```

Cikti: `dist/hedef_dorking_portable.exe`

Bu exe calistiginda dosyalari gecici klasore acip uygulamayi baslatir.
Baska bilgisayarda Go veya Flutter kurulu olmasa bile calisir.

## Loglama

Backend her calistiginda yanina gunluk log dosyasi olusturur:

- Dosya adi: `dorking_YYYY-MM-DD.log`
- Konum: backend exe'nin bulundugu klasor
- Icerigi: baslatma, arama ve hata kayitlari

Ornek log:

```
2026-04-24 18:00:00 [BASLATMA] Sunucu calisiyor -> http://localhost:8080
2026-04-24 18:00:10 [ARA] sorgu="site:example.com intitle:admin"
```

## Hizli Test

Backend ayaktayken asagidaki komutla test edilebilir:

PowerShell:
```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:8080/api/ara" -ContentType "application/json" -Body '{"sorgu":"site:example.com intitle:admin"}'
```

curl:
```bash
curl -X POST "http://localhost:8080/api/ara" -H "Content-Type: application/json" -d "{\"sorgu\":\"site:example.com intitle:admin\"}"
```

Beklenen sonuc: varsayilan tarayici Google arama sayfasini acar.

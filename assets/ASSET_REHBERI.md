# BLACKOUT — Asset Yerleştirme Rehberi

## Sci-Fi Facility Asset Pack — Nereye Koyulur?

Oyun, asset dosyalarını otomatik olarak aşağıdaki yollardan yükler.
PNG dosyalarını belirtilen klasörlere koyduğun anda çalışır.

---

## 📁 Klasör Yapısı

```
assets/
├── sprites/
│   ├── player/
│   │   └── player.png          ← Oyuncu sprite'ı (tek frame veya sheet)
│   │
│   ├── enemies/
│   │   └── creature.png        ← Düşman sprite'ı
│   │
│   ├── tiles/
│   │   └── tileset.png         ← Zemin/duvar tile sheet'i (32x32 tiles)
│   │
│   ├── items/
│   │   ├── battery.png         ← Pil item sprite'ı
│   │   └── ammo.png            ← Mermi item sprite'ı
│   │
│   └── props/
│       └── (dekoratif objeler) ← İsteğe bağlı
│
└── audio/
    ├── sfx/
    │   ├── footstep_walk.wav   ← Yürüyüş sesi (birden fazla: footstep_walk_1.wav, ...)
    │   ├── footstep_run.wav    ← Koşma sesi
    │   ├── footstep_crouch.wav ← Sinme sesi
    │   ├── gunshot.wav         ← Ateş sesi
    │   └── monster_growl.wav   ← Yaratık sesi
    │
    └── music/
        └── ambient.ogg         ← Arka plan müziği
```

---

## ✅ Adım Adım Asset Yükleme (Godot 4)

### Sprite Yükleme (PNG)
1. PNG dosyasını yukarıdaki klasöre kopyala
2. Godot'u aç (FileSystem paneli otomatik güncellenir)
3. Sprite üzerinde sağ tıkla → **Import** → **Preset: 2D Pixel** seç → **Reimport**
4. **Hazır!** Oyun otomatik olarak bu dosyayı kullanır.

### Tileset Yükleme
Eğer tileset farklı tile boyutlarındaysa (16x16 gibi):
- `scripts/levels/level_01.gd` içinde `_tile_size = 16` yapın
- `tileset.png`'yi `assets/sprites/tiles/` içine koy

### Ses Yükleme (WAV / OGG)
1. Ses dosyasını `assets/audio/sfx/` içine koy
2. Dosya adı önemli! Adlandırma kuralları:
   - `footstep_walk.wav` → yürüyüş sesleri
   - `footstep_run.wav` → koşma sesleri  
   - `footstep_crouch.wav` → sinme sesleri
   - `gunshot.wav` → ateş sesi
3. Godot'ta Import → **Loop: off** (sfx için), **Loop: on** (müzik için)

---

## 🎮 Sci-Fi Facility Asset Pack için Öneri

Pack'inden almana gerek olanlar:
| Dosya Tipi | Oyunda Kullanım |
|---|---|
| Floor tiles (32x32) | `assets/sprites/tiles/tileset.png` |
| Character/soldier sprite | `assets/sprites/player/player.png` |
| Monster/alien sprite | `assets/sprites/enemies/creature.png` |
| Crate/locker props | `assets/sprites/props/` |

---

> **Not:** Eğer sprite sheet kullanacaksan (birden fazla frame tek PNG'de),
> bunu bana söyle — AnimatedSprite2D'ye geçiş ve frame tanımları için
> player.gd ve creature.gd'yi güncellerim.

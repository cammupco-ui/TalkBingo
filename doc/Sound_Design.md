# Sound Design & Mechanical Keyboard Concept

## 1. 배경음악 (BGM)
**음악 스타일:**
- 앰비언트(Ambient) / 뉴에이지(New Age) 장르
- BPM 60-80 사이의 느린 템포 (심박수 안정화)
- 멜로디보다는 텍스처 중심의 사운드스케이프
- 대화를 방해하지 않는 낮은 주파수 대역 활용

**추천 사운드 요소:**
```
┌─────────────────────────────┐
│ Layer 1: 화이트/핑크 노이즈  │  (뇌파 안정화)
│ Layer 2: 자연 소리           │  (바람, 물소리)
│ Layer 3: 부드러운 신스 패드  │  (감성적 분위기)
│ Layer 4: 미니멀 피아노       │  (선택적)
└─────────────────────────────┘
```

## 2. 효과음 (SFX)
**키보드 타건음 (Mechanical Keyboard):**
- **컨셉**: 아날로그 감성의 기계식 키보드 사운드 (갈축/적축 계열의 부드러운 도각거림)
- **목적**: 
  - 채팅 입력 시 명확한 청각적 피드백 제공 (ASMR 효과)
  - 디지털 환경에서 물리적 타자기의 감성 전달
  - 리듬감 있는 대화 유도

**주요 효과음 리스트 (Actual Assets):**
| 파일명 | 설명 | 매핑 (Trigger) |
|--------|------|----------------|
| `thock_mid.wav` / `typing_mid.wav` | 일반 키 입력음 (랜덤 재생) | 텍스트 입력 (a-z, 가-힣) |
| `thock_low.wav` | 묵직한 키 입력음 | 스페이스바, 엔터키 |
| `thock_high.wav` / `typing_high.wav` | 가벼운 키 입력음 | 백스페이스, 삭제 |
| `disabled.wav` | 비활성화/에러음 | 입력 불가, 한도 초과 |

## 3. 오디오 관리 서비스 (AudioService)

**기능 요구사항:**
- AudioPlayer 인스턴스 관리 (BGM용 1개, SFX용 Pool 관리)
- 배경음악 로딩/재생/정지
- 효과음(SFX) 즉시 재생 (Low Latency, `Soundpool` 또는 `AudioPlayer`의 Low Latency 모드 권장)
- 볼륨 조절 (BGM / SFX 개별 제어)
- 페이드 인/아웃 (BGM 전환 시)

**주요 메서드:**
| 메서드 | 설명 |
|--------|------|
| `initialize()` | 오디오 파일 preload |
| `playBgm()` | 배경음악 재생 (loop: true) |
| `playSfx(SfxType)` | 효과음 재생 (One-shot) |
| `pauseBgm()` | 배경음악 일시정지 (페이드아웃) |
| `resumeBgm()` | 배경음악 재개 (페이드인) |
| `setBgmVolume(double)` | BGM 볼륨 조절 (0.0~1.0) |
| `setSfxVolume(double)` | SFX 볼륨 조절 (0.0~1.0) |
| `dispose()` | 리소스 정리 |

## 4. UI 컨트롤 (설정)

**위젯 구조:**
- `Switch`: 배경음악 활성화/비활성화, 효과음 활성화/비활성화
- `Slider`: 볼륨 레벨 (0~100, 내부적으로 0.0~1.0)

**저장 데이터 (SharedPreferences):**
| 키 | 타입 | 기본값 | 설명 |
|----|------|--------|------|
| `bgm_enabled` | bool | true | 배경음악 활성화 여부 |
| `bgm_volume` | double | 0.3 | BGM 볼륨 레벨 (0.0~1.0) |
| `sfx_enabled` | bool | true | 효과음 활성화 여부 |
| `sfx_volume` | double | 0.5 | SFX 볼륨 레벨 (0.0~1.0) |

## 5. 파일 구조
```
app/
├── assets/
│   └── audio/
│       ├── disabled.wav
│       ├── thock_high.wav
│       ├── thock_low.wav
│       ├── thock_mid.wav
│       ├── typing_high.wav
│       └── typing_mid.wav
```

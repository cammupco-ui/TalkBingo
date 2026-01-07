# ⭐ Important - TalkBingo - 데이터베이스 스키마

## 📊 핵심 게임 DB 스키마

### User Table (사용자 정보)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| user_id (PK) | UUID | 사용자 고유 ID |
| email | VARCHAR | 로그인 이메일 |
| pw_hash | VARCHAR | 비밀번호 해시 |
| nick | VARCHAR | 닉네임 |
| profile_img | TEXT | 프로필 이미지 |
| plan | ENUM | free / premium |
| country | VARCHAR | 국가 코드 (KR, US, JP 등) |
| region | VARCHAR | 지역/시/도 정보 |
| timezone | VARCHAR | 시간대 (Asia/Seoul, America/New_York 등) |
| age | INT | (Removed) |
| gender | ENUM | 성별 (M/F) (호스트: Gender, 게스트: Guest Gender) |
| birthCity | VARCHAR | (Removed) |
| role | ENUM | 역할 (host/guest) |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |

**게스트 정보 구분:**
- `gender`: Guest Gender로 표시

### Game Table (게임 정보)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| game_id (PK) | UUID | 게임 고유 ID |
| mp_id (FK) | UUID | 방장(Main Player) |
| cp_id (FK) | UUID | 상대(Connected Player) |
| size | INT | 빙고판 크기 (3/4/5) |
| db_type | ENUM | S-DB (Supabase) |
| status | ENUM | waiting / playing / finished |
| created_at | DATETIME | 생성일 |

### Question Table (질문 데이터)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| id (PK) | UUID | 질문 고유 ID |
| type | TEXT | Balance / Truth |
| content | TEXT | 질문 내용 |
| details | JSONB | 답변, 선택지 등 타입별 상세 데이터 |
| code_names | TEXT[] | (Legacy) 타겟 코드네임 배열 |
| created_at | DATETIME | 생성일 |
| updated_at | DATETIME | 수정일 |
| source | VARCHAR | 데이터 출처 (CSV_IMPORT, WEB_ADMIN 등) |

### Response Table (응답 데이터)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| r_id (PK) | UUID | 응답 ID |
| game_id (FK) | UUID | 게임 ID |
| user_id (FK) | UUID | 응답자 |
| q_id (FK) | UUID | 질문 ID |
| txt | TEXT | T형 응답 |
| choice | ENUM | A / B |
| score | INT | M형 점수 |
| created_at | DATETIME | 생성일 |

### Reward Table (보상 시스템)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| reward_id (PK) | UUID | 보상 ID |
| user_id (FK) | UUID | 유저 ID |
| vp | INT | Victory Point |
| ap | INT | Activity Point |
| ep | INT | Experience Point |
| ts | FLOAT | Trust Score |
| updated_at | DATETIME | 갱신일 |

### Log Table (게임 로그)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| log_id (PK) | UUID | 로그 ID |
| game_id (FK) | UUID | 게임 ID |
| turn_no | INT | 턴 번호 |
| user_id (FK) | UUID | 행동 유저 |
| action | ENUM | select / response / agree / reject |
| detail | JSONB | 질문·응답·점수 상세 |
| created_at | DATETIME | 생성일 |

**로그 타입:**
- **L** = 게임 단위 기록 (Game)
- **PL** = 플레이 단위 기록 (질문/응답 묶음)
- **CL** = 채팅 로그

### FriendRelation Table (친구 관계)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| rel_id (PK) | UUID | 관계 ID |
| mp_id (FK) | UUID | 메인 유저 |
| cp_id (FK) | UUID | 친구 유저 |
| intimacy | ENUM | L1~L5 |
| play_cnt | INT | 누적 플레이 횟수 |
| last_played | DATETIME | 마지막 플레이 일시 |

### Holiday Table (연휴 정보)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| holiday_id (PK) | UUID | 연휴 ID |
| country | VARCHAR | 국가 코드 |
| name | VARCHAR | 연휴명 (한국어/영어) |
| date | DATE | 연휴 날짜 |
| type | ENUM | national / religious / cultural |
| is_weekend | BOOLEAN | 주말 여부 |
| created_at | DATETIME | 생성일 |

---

## 📊 인간관계 DB 스키마 (Relationship Schema)

### RelationType Table (관계 유형 정의)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| id (PK) | INT | 관계 유형 ID |
| code | VARCHAR | 약어 (ex. F-F-B-Dc) |
| label | VARCHAR | 관계명 (ex. 여성-여성-동네친구) |
| category | ENUM | Friend / Family / Love / Work 등 |
| description | TEXT | 관계 상세 설명 |

### Relation Table (개별 관계)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| rel_id (PK) | UUID | 개별 관계 ID |
| mp_id (FK) | UUID | 기준 유저(Main Player) |
| cp_id (FK) | UUID | 상대 유저(Connected Player) |
| rel_type_id (FK) | INT | 관계 유형 (RelationType 참조) |
| intimacy_lvl | ENUM | L1 ~ L5 (친밀도) |
| created_at | DATETIME | 관계 생성일 |
| updated_at | DATETIME | 관계 수정일 |

### IntimacyLevel Table (친밀도 정의)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| id (PK) | INT | 레벨 ID |
| code | VARCHAR | L1~L5 |
| label | VARCHAR | 친밀도 단계명 |
| description | TEXT | 친밀도 상세 정의 |
| min_play_cnt | INT | 최소 플레이 횟수 |

### RelationLog Table (관계 히스토리)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| rel_log_id (PK) | UUID | 관계 히스토리 로그 ID |
| rel_id (FK) | UUID | 관계 ID |
| game_id (FK) | UUID | 게임 ID |
| intimacy_change | INT | 친밀도 변화 (+1, 0, -1) |
| reason | TEXT | 변화 이유 (예: 반복 플레이, 신뢰도 상승, 신고 등) |
| created_at | DATETIME | 기록 일시 |

### TrustEval Table (신뢰 평가)
| 컬럼명 | 타입 | 설명 |
| --- | --- | --- |
| eval_id (PK) | UUID | 평가 ID |
| rel_id (FK) | UUID | 관계 ID |
| user_id (FK) | UUID | 평가자 ID |
| ts_score | INT | 1~5점 평가 |
| comment | TEXT | 평가 코멘트 |
| created_at | DATETIME | 평가 일시 |

---

## 🔗 테이블 관계도

```
User (1) ←→ (N) Game (1) ←→ (N) Response
  ↓                    ↓
Reward              Question (questions table)
  ↓                    ↓ (N:M)
FriendRelation ←→ Relation ←→ RelationType
  ↓                    ↓
IntimacyLevel    RelationLog
  ↓                    ↓
TrustEval        Log
```

---

## 📈 데이터베이스 활용 방안

### 1-1. 질문 타겟팅 시스템 (Relational Tagging)
- **핵심 설계:** 질문(Question) 테이블에는 질문 데이터가 하나만 존재하고, N:M 매핑 테이블을 통해 타겟 조건을 연결합니다.

#### 매핑 테이블
- `question_intimacy`: 질문-친밀도 연결
- `question_relations`: 질문-관계유형 연결
- `question_genders`: 질문-성별조합 연결

#### 게임 로직 (Game Logic)
- **5:5 비율**: 빙고 보드 생성 시 Balance Quiz와 Truth Quiz를 5:5 비율(약 12:13)로 배치합니다.
- **SQL 쿼리**: Join을 사용하여 조건에 맞는 질문을 효율적으로 필터링하고 랜덤 추출합니다.

---

## 🛠️ 개발 시 고려사항

### 성능 최적화
- **인덱스 설정:** 
  - user_id, game_id, rel_id 등 자주 조회되는 FK 컬럼
  - `question_intimacy`, `question_relations` 등 연결 테이블의 FK에 인덱스 필수
- **JSONB 인덱스:** `details` 컬럼 내 자주 조회하는 필드가 있다면 GIN 인덱스 고려

### 데이터 무결성
- **외래키 제약조건:** 모든 FK 관계 설정
- **체크 제약조건:** ENUM 값 검증 (Supabase Check Constraints)
- **RLS (Row Level Security):** 유저 데이터 접근 제어 필수

### 데이터 출처 관리
- **source 필드:** `CSV_IMPORT`, `WEB_ADMIN` 등으로 관리

### 질문 덮어쓰기 전략
- **Upsert 사용:** Supabase `upsert` 메서드를 사용하여 ID 충돌 시 업데이트 처리
- **updated_at 추적:** 자동 갱신


---

*TalkBingo - 체계적인 데이터 관리로 최적의 사용자 경험 제공*





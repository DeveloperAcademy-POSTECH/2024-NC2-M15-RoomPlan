# My Raum 2.0 — PRD (Product Requirements Document)

> **문서 목적**: Claude Code가 이 문서를 컨텍스트로 읽고 단계별 작업을 수행할 수 있도록 작성된 개발 요구사항 명세서.
> **작성 기준일**: 2026-08-22
> **대상 저장소**: `2024-NC2-M15-RoomPlan` (MyRaum.xcodeproj)
> **현재 버전**: 1.0.4 / **목표 버전**: 2.0.0

---

## 0. 프로젝트 개요

### 0.1 현재 앱 요약

My Raum은 RoomPlan으로 공간을 스캔하고, 스캔된 3D 모델을 **화면 캡처 → Vision 배경 제거(누끼)** 로 이미지화한 뒤 배경 사진·장소명·날짜·위치정보와 합쳐 "공간 카드"로 저장/공유하는 iOS 앱이다.

### 0.2 2.0의 방향성

| 축 | AS-IS | TO-BE |
|---|---|---|
| 모델 저장 | 누끼 이미지(PNG Data) | USDZ 3D 모델 파일 |
| 저장소 | 로컬 SwiftData only | 로컬 파일 + SwiftData + Supabase (신규 데이터 전량) |
| 카드 뷰 | 정적 이미지 | 회전 가능한 인터랙티브 3D |
| 스캔 UX | 4단계 화면 전환 | 인스타 스토리형 단일 편집 캔버스 |
| 메인 네비게이션 | NavigationLink + Bool 플래그 | 좌/우 사이드 드로어 |
| RoomPlan 활용 | 캡처 화면만 사용 | 가구 인식·치수·MultiRoom 데이터 활용 |
| 플랫폼 | iOS | iOS (visionOS 확장 여지만 확보) |

### 0.3 핵심 제약

- **기능 추가 전 리팩토링이 선행되어야 한다.** 현재 `RoomPlanView`가 4개 화면의 상태와 저장 로직을 모두 보유하고 있어, 기능을 추가할수록 결합도가 급격히 증가한다.
- **기존 사용자의 데이터는 절대 손실되면 안 된다.** 이미지 기반으로 저장된 기존 카드는 별도 페이지에서 계속 열람 가능해야 한다.
- **최소 배포 타겟은 iOS 18.0이다.** iOS 17 사용자는 2.0으로 업데이트할 수 없다 (§9 D-01).
- **2.0에서 스캔한 공간은 전부 Supabase에 저장된다. 레거시 이미지 카드는 로컬 전용으로 남는다** (§9 D-06).
- **공개 토글은 업로드 여부가 아니라 타인 공개 여부만 제어한다.** 기본값은 비공개.

---

## 1. 현재 코드베이스 진단

Claude Code가 리팩토링 시 우선적으로 다뤄야 할 문제점들.

### 1.1 God View — `MyRaum/View/SpaceScan/RoomPlanView.swift`

- `@State` 프로퍼티 12개가 한 View에 존재
- 4개 화면(`scan`/`scanResult`/`addInfo`/`finalResult`)을 `switch`로 분기하며 모두 같은 파일에 존재
- 저장 로직 `saveSpaceData()`가 View extension 안에 있음
- 날짜 포맷팅(`DateFormatter`) 로직이 `addInfoView`와 `saveSpaceData()` 두 곳에 중복

### 1.2 강제 언래핑 (크래시 위험)

| 위치 | 코드 |
|---|---|
| `MySpaceCardView.swift` | `UIImage(data: space.background)!`, `UIImage(data: space.model)!` |
| `MySpaceCellView.swift` | `UIImage(data: space.background)!` |
| `RoomPlanView.swift` | `model.pngData()!`, `background.pngData()!` |
| `ModelCaptureManager.swift` | `filter.outputImage!`, `fatalError()` 3곳 |

→ 손상된 데이터 1건으로 보관함 전체가 크래시된다.

### 1.3 의존성 주입 부재

`RoomPlanManager`, `LocationManager`, `ModelCaptureManager` 모두 프로토콜 없이 concrete class로 View 내부에서 직접 생성됨(`@State private var ... = XxxManager()`). 테스트 불가능하며, Supabase Repository 계층을 끼워 넣기 어렵다.

### 1.4 네비게이션 구조

`ContentView`가 `navigateToRoomPlanView`, `navigateToMySpaceView` 두 개의 Bool + `navigationDestination`으로 동작. 드로어 방식 전환 시 전면 교체 필요.

### 1.5 기타

- `UINavigationController+Extension.swift`에서 `viewDidLoad`를 override — Swift 6 및 향후 iOS 버전에서 위험. 제스처 처리 방식 재검토 필요.
- 프로젝트 배포 타겟 불일치: Project 레벨 `IPHONEOS_DEPLOYMENT_TARGET = 17.5`, Target 레벨 `17.0`.
- `Info.plist`가 빈 dict이고 모든 키가 빌드 설정(`INFOPLIST_KEY_*`)에 존재.

---

## 2. 목표 아키텍처

```
MyRaum/
├── MyRaumApp.swift
├── App/                       # 앱 진입, DI 컨테이너, 라우팅
│   ├── AppContainer.swift
│   └── AppRouter.swift
├── Core/                      # (2단계에서 Swift Package로 분리 → 플랫폼 비의존 유지)
│   ├── Model/
│   │   ├── SpaceData.swift            # SwiftData @Model (V2 스키마)
│   │   ├── SpaceSchemaV1.swift        # 마이그레이션용 레거시 스키마
│   │   ├── CapturedFurniture.swift    # 가구 인식 결과
│   │   └── RoomMetrics.swift          # 면적/치수
│   ├── Repository/
│   │   ├── SpaceRepository.swift      # protocol
│   │   ├── LocalSpaceRepository.swift
│   │   └── RemoteSpaceRepository.swift  # Supabase
│   ├── Storage/
│   │   ├── ModelFileStore.swift       # USDZ 파일 I/O
│   │   └── SyncQueue.swift            # 업로드 재시도 큐
│   └── Service/
│       ├── RoomScanService.swift      # protocol + 구현
│       ├── LocationService.swift      # protocol + 구현
│       ├── AuthService.swift          # protocol + Supabase Apple provider
│       └── ThumbnailRenderer.swift
├── Feature/
│   ├── Onboarding/            # 온보딩 · 로그인 게이트
│   ├── Home/                  # 사이드 드로어 컨테이너
│   ├── Scan/                  # 스토리형 스캔·편집
│   ├── Archive/               # 보관함(신규 3D 카드)
│   ├── LegacyArchive/         # 기존 이미지 카드 전용
│   ├── MapView/               # 지도에서 보기
│   └── Settings/              # 기존 MyPage
└── Shared/
    ├── Component/             # 기존 View/Component 이동
    ├── Extension/
    └── Enum/
```

**패턴**: MVVM + Repository. ViewModel은 `@Observable` 사용(기존 Manager들과 동일한 Observation 프레임워크 유지).

---

## 3. 개발 단계 (Phase)

Claude Code는 **Phase 순서대로** 작업하며, 각 Phase는 독립적으로 빌드·동작 가능해야 한다. Phase 완료 시 커밋을 분리한다.

### Phase 0 — 안전망 구축 (선행 필수)

**목표**: 리팩토링 중 회귀를 잡아낼 최소한의 기반 마련.

| # | 작업 | 완료 조건 |
|---|---|---|
| 0.1 | 강제 언래핑 전면 제거 | §1.2 표의 모든 위치를 `guard let`/`if let`/기본 이미지 fallback으로 교체 |
| 0.2 | 배포 타겟 상향·통일 | Project/Target 모두 `IPHONEOS_DEPLOYMENT_TARGET = 18.0` 으로 통일 |
| 0.3 | 테스트 타겟 추가 | `MyRaumTests` 유닛 테스트 타겟 생성, 빈 테스트 1개 통과 |
| 0.4 | 디렉토리 구조 재편 | §2 구조로 파일 이동 (`PBXFileSystemSynchronizedRootGroup` 사용 중이므로 폴더 이동만으로 반영됨) |

> ⚠️ 0.4 수행 시 `project.pbxproj`의 `fileSystemSynchronizedGroups` 목록을 새 폴더 기준으로 갱신해야 한다.

---

### Phase 1 — 코어 리팩토링

**목표**: 기능 변경 없이 구조만 개선. **이 Phase 종료 시 앱 동작은 1.0.4와 100% 동일해야 한다.**

| # | 작업 | 완료 조건 |
|---|---|---|
| 1.1 | Manager 프로토콜화 | `RoomScanning`, `LocationProviding`, `ModelCapturing` 프로토콜 정의 후 기존 클래스가 채택 |
| 1.2 | DI 컨테이너 | `AppContainer`가 서비스 인스턴스 소유, `.environment()`로 주입. View 내 직접 생성 제거 |
| 1.3 | `RoomPlanView` 분해 | 4개 화면을 개별 View 파일로 분리 + `ScanFlowViewModel`이 상태·전환 소유 |
| 1.4 | 저장 로직 이전 | `saveSpaceData()` → `SpaceRepository.save(_:)` 로 이동. `ModelContext` extension은 `LocalSpaceRepository` 내부로 흡수 |
| 1.5 | 날짜 포맷 통합 | `DateFormatter` 중복 제거, `Shared/Extension/Date+Format.swift`로 단일화 |
| 1.6 | 테스트 작성 | `SpaceRepository` 저장/삭제, `ScanFlowViewModel` 단계 전환 테스트 |

**Acceptance**: 스캔 → 배경 추가 → 장소 입력 → 미리보기 → 저장 → 보관함 조회 → 삭제 전 과정이 리팩토링 전과 동일하게 동작.

---

### Phase 2 — 데이터 모델 전환 (USDZ + 마이그레이션)

**목표**: 누끼 이미지 방식을 걷어내고 3D 모델 자체를 저장. **가장 리스크가 큰 Phase.**

#### 2.1 스키마 설계

```swift
// V2
@Model final class SpaceData {
    var id: UUID
    var createdAt: Date              // String → Date 로 변경 (정렬/필터 위해)
    var comment: String
    var latitude: Double
    var longitude: Double

    // 저장 방식 구분
    var storageKind: String          // "legacyImage" | "usdz"

    // legacyImage 전용 (기존 사용자)
    @Attribute(.externalStorage) var legacyModelImage: Data?
    @Attribute(.externalStorage) var background: Data?

    // usdz 전용 (신규)
    var modelFileName: String?       // Documents/Models/{uuid}.usdz  (.parametric 단독)
    @Attribute(.externalStorage) var thumbnail: Data?   // 지도 마커·목록용

    // MultiRoom (D-04) — 여러 방이 하나의 구조에 속할 수 있음
    var structureID: UUID?           // nil이면 단일 방
    var structureOrder: Int?         // 구조 내 순서

    // RoomPlan 파생 데이터
    var furnitureJSON: String?       // [CapturedFurniture] 직렬화
    var floorAreaSqM: Double?
    var roomTypeGuess: String?

    // 공개·동기화 상태 (D-06 — 신규 데이터는 전량 업로드, 토글은 공개 여부만 제어)
    var isPublic: Bool               // 기본 false (비공개). 업로드 여부와 무관
    var remoteID: String?
    var syncState: String            // "pending" | "synced" | "failed" | "localOnly"(레거시)
}
```

#### 2.2 마이그레이션

- `VersionedSchema` + `SchemaMigrationPlan`으로 V1 → V2 custom migration 구현
- 기존 레코드: `storageKind = "legacyImage"`, `model` → `legacyModelImage`, `date`(String "yyyy.MM.dd") → `createdAt`(Date) 파싱
- **파싱 실패 시 `Date.distantPast` 대신 원본 문자열을 별도 필드에 보존**하여 표시 깨짐 방지

#### 2.3 USDZ 저장 파이프라인

| # | 작업 |
|---|---|
| 2.3.1 | `RoomPlanManager`가 `CapturedRoom`을 보관하도록 수정 (현재 `finalResult`가 private이고 외부 접근 불가) |
| 2.3.2 | `capturedRoom.export(to:exportOptions: .parametric)` → `Documents/Models/{uuid}.usdz` |
| 2.3.4 | USDZ 로드 후 오프스크린 렌더로 썸네일 PNG 생성 (`ThumbnailRenderer`) |
| 2.3.5 | `ModelCaptureManager` / `UIView+Extension.snapshot(of:)` **삭제** (누끼 로직 제거) |

#### 2.4 RoomPlan 파생 데이터 추출

`CapturedRoom`에서 함께 추출하여 저장:

- **가구 목록**: `capturedRoom.objects`의 `category`, `dimensions`, `transform`, `confidence`
- **방 종류 추론**: 가구 카테고리 조합 기반 룰
  - `bed` 포함 → 침실 / `refrigerator|stove|dishwasher|sink` → 주방 / `sofa|television` → 거실 / `toilet|bathtub` → 욕실
- **면적**: `capturedRoom.floors` 또는 `walls`의 dimensions로 바닥 면적 산출
- **저신뢰 항목**: `confidence == .low` 개수 → 스캔 품질 지표로 활용

**Acceptance**: 신규 스캔 시 USDZ 파일이 생성되고, 기존 사용자 데이터가 손실 없이 V2로 마이그레이션되며, 기존 카드가 계속 렌더링됨.

---

### Phase 3 — 3D 카드 뷰 & 레거시 분리

#### 3.1 인터랙티브 3D 카드

- `RealityView` + `ModelEntity(contentsOf: usdzURL)` + `DragGesture`로 Y축 회전, 핀치로 스케일
- 최소 배포 타겟이 18.0이므로 **버전 분기 없이 단일 경로로 구현한다.** SceneKit 대체 구현은 작성하지 않는다.
- 회전 상태는 카드별로 유지하지 않고 진입 시 초기 각도로 리셋

#### 3.2 레거시 카드 전용 페이지

**정책(D-05)**: 기존 이미지 카드는 3D로 전환하지 않는다(이미지→3D 복원 불가). 조회 전용으로 영구 유지한다.

- 보관함을 `@Query(filter: #Predicate { $0.storageKind == "usdz" })` 기준으로 필터링
- 설정 또는 보관함 상단에 **"이전 카드 보기"** 진입점 추가
- `LegacyArchive` 피처에 기존 `MySpaceCardView`(앞면 이미지 / 뒷면 지도 + 탭 플립) 로직을 **그대로 이식**
- 레거시 카드는 읽기·이미지 저장·공유(ShareLink)만 지원, 신규 생성 불가
- **레거시 카드는 서버에 업로드하지 않는다** (D-06). 해당 기기의 로컬에만 존재하므로, 기기 변경 시 복원되지 않는다는 점을 안내한다

**Acceptance**: 기존 사용자가 업데이트 후 "이전 카드 보기"에서 과거 카드 전부를 열람·공유할 수 있음.

---

### Phase 4 — 홈 사이드 드로어

- `ContentView`를 `HomeContainerView`로 교체
- 구조: `ZStack` 기반 3-pane
  - 좌측 패널: 보관함 / 중앙: 홈 / 우측 패널: 공간 스캔
- 제스처: `DragGesture`로 좌우 슬라이드, `offset` + `withAnimation(.interactiveSpring)` 적용
- 기존 `ContentView.dragGesture`(우상단 코너 → 보관함)의 의도를 컨테이너 레벨 제스처로 승격
- 엣지 스와이프와 스캔 화면 내부 제스처 충돌 방지 (스캔 활성 시 드로어 제스처 비활성화)
- `UINavigationController+Extension` 의존 제거 검토

**Acceptance**: 좌/우 스와이프로 각 패널이 자연스럽게 열리고, 패널 열린 상태에서 탭·드래그로 닫힌다.

---

### Phase 5 — 스토리형 스캔·편집 UX

**목표**: 현재 `scan → scanResult → addInfo → finalResult` 4단계 화면 전환을 **단일 풀스크린 편집 캔버스**로 재구성.

- 스캔 완료 후 편집 캔버스 진입 → 카드가 항상 전체 화면 프리뷰로 존재
- 우측/하단 툴바 아이콘: 배경 선택 / 텍스트(장소명) / 날짜 토글 / 3D 각도 리셋
- 텍스트 입력은 모달(`CommentPopupView`) 대신 **인라인 오버레이 편집**
- 배경 위 요소(장소명, 날짜, 3D 모델)를 드래그로 위치 조정 가능하도록 확장 검토
- 상단 진행 인디케이터 또는 좌우 스와이프로 단계 이동
- **Custom ARSession** 지원을 활용해 스캔 화면에 커스텀 코칭 오버레이 적용
- `confidence == .low` 오브젝트가 있으면 "이 영역을 더 스캔해 보세요" 힌트 노출

**Acceptance**: 스캔 종료부터 저장까지 화면 전환 없이 하나의 캔버스에서 완료 가능.

---

### Phase 6 — 온보딩 · 인증 · Supabase 저장

#### 6-A. 온보딩 & 로그인 게이트

모든 신규 스캔이 서버에 저장되므로, **로그인은 앱 진입 조건**이다. 단, 레거시 데이터만 보려는 기존 사용자를 위한 우회 경로를 반드시 제공한다.

**앱 시작 시 분기 로직**

```
앱 실행
 ├─ hasCompletedOnboarding == false  → 온보딩 → 로그인 화면
 │                                      ├─ 로그인 성공        → 홈 (전체 기능)
 │                                      └─ "기존 데이터 보기"  → 레거시 전용 모드
 │                                          (레거시 데이터가 있을 때만 노출)
 └─ hasCompletedOnboarding == true
     ├─ 세션 유효      → 홈 (전체 기능)
     └─ 세션 없음/만료 → 로그인 화면 (온보딩은 다시 보여주지 않음)
```

- `hasCompletedOnboarding`은 `UserDefaults`에 저장한다. 기존 1.0.4 사용자는 이 키가 없으므로 **업데이트 후 첫 실행 시 온보딩을 보게 된다.** 이것이 의도된 동작이다.
- 세션 복원은 Supabase SDK의 저장된 세션을 사용한다. 재실행마다 로그인을 요구하지 않는다.

**작업 항목**

| # | 작업 |
|---|---|
| 6A.1 | `AppRouter`에 앱 상태 정의 — `.onboarding` / `.login` / `.authenticated` / `.legacyOnly` |
| 6A.2 | 온보딩 화면 — 2.0의 핵심 변화 소개(3D 모델 저장, 서버 저장, 공개 설정). **모든 스캔이 서버에 업로드된다는 점과 위치 정보가 함께 저장된다는 점을 여기서 고지한다** |
| 6A.3 | 로그인 화면 — Sign in with Apple 버튼. 온보딩 완료 시 `hasCompletedOnboarding = true` 기록 |
| 6A.4 | 로그인 화면 하단에 **"기존 데이터 보기"** 진입점 — 레거시 카드가 1건 이상 존재할 때만 노출 |
| 6A.5 | **레거시 전용 모드** 구현 (아래 상세) |
| 6A.6 | 설정에 로그아웃 + 계정 삭제. 로그아웃 시 `.login` 상태로 복귀 (온보딩은 재노출하지 않음) |

**레거시 전용 모드 (`.legacyOnly`) 상세**

로그인을 원하지 않고 예전 카드만 보려는 기존 사용자를 위한 제한 모드.

- **가능**: 레거시 카드 목록·상세 조회, 이미지 저장, 공유(ShareLink), 삭제
- **불가**: 신규 스캔, 3D 카드, 지도, 공개 설정 — 진입 시도 시 "로그인이 필요합니다" 안내 후 로그인 화면으로 유도
- 화면 상단에 현재 모드를 알리는 배너와 **언제든 로그인할 수 있는 진입점**을 상시 노출한다
- 이 모드에서 로그인하면 곧바로 `.authenticated`로 전환된다. 레거시 카드는 그대로 로컬에 남으며 업로드되지 않는다 (D-06)
- **레거시 데이터가 0건이면 이 모드로 진입할 수 없다.** 신규 사용자에게는 "기존 데이터 보기" 자체를 노출하지 않는다

**Acceptance**
- 신규 설치 → 온보딩 → 로그인 → 홈 진입
- 1.0.4에서 업데이트 → 온보딩 → 로그인 → 기존 카드가 "이전 카드 보기"에서 조회됨
- 1.0.4에서 업데이트 → 온보딩 → 로그인 화면에서 "기존 데이터 보기" → 레거시 카드 조회 가능, 스캔 시도 시 로그인 유도
- 앱 재실행 시 온보딩이 다시 뜨지 않음

#### 6-B. Supabase 백엔드

**정책(D-06)**
- 2.0에서 스캔한 공간은 **전부** Supabase에 저장한다 (업로드는 선택 사항이 아님).
- **레거시 이미지 카드는 업로드하지 않는다.** 로컬 전용으로 유지한다.
- 공개 토글(`isPublic`)은 업로드 여부가 아니라 **타인 공개 여부만** 제어한다. 기본값 비공개.

| # | 작업 |
|---|---|
| 6B.1 | Supabase Swift SDK(SPM) 추가 |
| 6B.2 | **Sign in with Apple** — Supabase Auth의 Apple provider 연동 (6-A에서 사용) |
| 6B.3 | Storage 버킷 `space-models` — USDZ + 썸네일 업로드 |
| 6B.4 | Postgres 테이블 `spaces` — 메타데이터(comment, created_at, lat/lng, furniture, area, structure_id, is_public, storage_path) |
| 6B.5 | **RLS 정책** — insert/update/delete는 본인 row만. select는 `owner = auth.uid() OR is_public = true` |
| 6B.6 | `SyncQueue` — 로컬 저장 완료 후 백그라운드 업로드, 실패 시 지수 백오프 재시도. 오프라인 시 `pending` 유지 |
| 6B.7 | 재로그인 시 원격 데이터 복원 — 기기 변경 후 로그인하면 서버의 공간을 로컬로 내려받는다 |
| 6B.8 | 카드 상세에 **공개 토글** + 동기화 상태(업로드 중 / 완료 / 실패) 표시 |
| 6B.9 | 공개 토글 변경 시 `is_public` 컬럼만 업데이트. **원격 데이터를 삭제하지 않는다** |
| 6B.10 | 레거시 카드는 업로드 대상에서 제외 — `SyncQueue`가 `storageKind == "legacyImage"` 를 필터링 |

**사용자 안내 필수**
- 2.0 이후 스캔한 공간은 서버에 저장되어 기기 변경 시 복원되지만, **레거시 카드는 복원되지 않는다.**
- 스캔한 모든 공간이 서버에 업로드된다는 점은 6A.2 온보딩에서 고지한다.

**개인정보 주의**: 공개 여부와 무관하게 **모든 신규 공간의 위치 좌표가 서버에 저장된다.** 기존 `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`의 "위치 데이터는 사용자만이 볼 수 있습니다" 문구는 더 이상 사실이 아니므로 반드시 갱신하고, 개인정보 처리방침 및 App Store 개인정보 라벨(데이터 수집 → 위치)을 업데이트해야 한다. 공개 토글을 켤 때는 **위치가 타인에게 노출된다는 점**을 별도로 경고한다.

> ⚠️ 공개된 공간을 다른 사용자가 열람하는 화면(둘러보기 피드 / 공개 지도)은 이 PRD 범위에 정의되어 있지 않다. §9 D-06 참고.

---

### Phase 7 — 지도에서 보기

- MapKit `Map` + 저장된 모든 공간을 어노테이션으로 표시
- 마커 아이콘: Phase 2.3.4에서 생성한 **썸네일 이미지** 사용
  → 마커마다 실시간 3D 렌더링은 성능 부담이 크므로 채택하지 않음. 탭 시 3D 상세뷰로 진입.
- 마커 클러스터링(동일 지역 다수 공간)
- 레거시 카드도 위경도를 보유하므로 함께 표시 (마커는 배경 이미지 썸네일 사용)

---

### Phase 8 — RoomPlan 심화 기능

최소 배포 타겟이 iOS 18이므로 아래 기능은 모두 버전 분기 없이 사용 가능하다.

| # | 기능 | 설명 | 포함 여부 |
|---|---|---|---|
| 8.1 | **MultiRoom 병합** | `CapturedStructure`로 여러 방 스캔을 하나의 구조로 병합 → "집 전체" 단위 기록 | **확정 도입 (D-04)** |
| 8.2 | 가구 목록 표시 | 카드 상세에 인식된 가구 리스트 노출 | 포함 |
| 8.3 | 공간 정보 배지 | 면적(m²), 방 종류 자동 태그를 카드에 표시 | 포함 |
| 8.4 | 2D 평면도 생성 | walls/doors/windows 좌표로 블루프린트 스타일 도면 렌더 | 선택 |
| 8.5 | VoiceOver | `RoomCaptureView` 내장 VoiceOver 지원 활용 | 포함 |

**MultiRoom 상세**
- Phase 2 스키마의 `structureID` / `structureOrder` 필드를 사용한다 (예약이 아니라 **처음부터 포함**).
- 스캔 플로우에 "방 추가하기" 진입점 필요 — 기존 구조에 이어붙일지, 새 공간으로 만들지 선택
- 보관함은 구조 단위로 묶어 표시하고, 하위 방들을 펼쳐볼 수 있게 한다
- 지도(Phase 7)에서는 구조 단위로 마커 1개만 표시한다 (대표 방 좌표 사용)

---

### (참고) 향후 확장 가능성 — visionOS

**이번 개발 범위에 포함되지 않는다.** 정식 Phase로 착수하지 않으며, 아래는 나중에 검토할 여지를 남겨두기 위한 메모다.

- Phase 1~2에서 `Core`를 Swift Package로 분리해두면, 이후 visionOS 타겟을 추가할 때 Model/Repository 계층을 그대로 재사용할 수 있다.
- 구현하게 될 경우의 대략적 형태: `WindowGroup`으로 보관함 목록, `Model3D` / `ImmersiveSpace`로 공간 모델을 실물 크기 배치, Supabase에 저장된 본인 공간을 열람.

> Claude Code는 이 항목에 대한 코드를 작성하지 않는다. Phase 1~2 설계 시 Core 계층이 플랫폼 의존적인 UIKit 코드에 묶이지 않도록만 유의하면 된다.

---

## 4. 기능 요구사항 요약 (FR)

| ID | 요구사항 | Phase | 우선순위 |
|---|---|---|---|
| FR-01 | 스캔 결과를 USDZ 3D 모델로 로컬 저장 | 2 | P0 |
| FR-02 | 기존 이미지 카드 데이터 무손실 마이그레이션 | 2 | P0 |
| FR-03 | 기존 카드를 별도 페이지에서 열람 | 3 | P0 |
| FR-04 | 카드에서 3D 모델 회전/확대 | 3 | P1 |
| FR-05 | 좌/우 사이드 드로어 홈 화면 | 4 | P1 |
| FR-06 | 스토리형 단일 캔버스 편집 | 5 | P1 |
| FR-07 | 온보딩 + Sign in with Apple 로그인 게이트 | 6-A | P0 |
| FR-08 | 미로그인 사용자를 위한 레거시 조회 전용 모드 | 6-A | P0 |
| FR-09 | 신규 공간 Supabase 자동 업로드 + 공간별 공개 토글 | 6-B | P1 |
| FR-10 | 지도에서 전체 공간 보기 | 7 | P2 |
| FR-11 | 가구 인식 목록 / 면적 / 방 종류 표시 | 8 | P2 |
| FR-12 | MultiRoom 병합 | 8 | P2 |

> visionOS 앱은 요구사항이 아닌 향후 확장 가능성으로만 남겨둔다 (§3 참고 항목).

---

## 5. 비기능 요구사항 (NFR)

- **NFR-01** 보관함 40개 카드 기준 스크롤 60fps 유지 (썸네일 사용, USDZ는 상세 진입 시에만 로드)
- **NFR-02** USDZ 파일당 목표 크기 10MB 이하 (parametric 기준)
- **NFR-03** 앱 콜드 스타트 2초 이내
- **NFR-04** 로그인 이후에는 네트워크 없이도 스캔·저장·열람이 동작한다. 업로드는 `pending` 상태로 큐에 적재 후 연결 복구 시 자동 재시도
- **NFR-08** 세션이 유효한 동안에는 재실행 시 로그인을 다시 요구하지 않는다. 오프라인 상태에서도 저장된 세션으로 앱에 진입할 수 있어야 한다
- **NFR-05** 강제 언래핑으로 인한 크래시 0건
- **NFR-06** 기존 다국어(ko/en) 지원 유지 — 신규 문자열은 모두 `Localizable.xcstrings`에 추가
- **NFR-07** 다크/라이트 모드 모두 지원

---

## 6. 데이터 마이그레이션 체크리스트

- [ ] V1 스키마 스냅샷을 `SpaceSchemaV1`로 보존
- [ ] `SchemaMigrationPlan`의 custom stage 구현
- [ ] 마이그레이션 전 SwiftData 스토어 백업
- [ ] `date: String` → `createdAt: Date` 파싱 실패 케이스 처리
- [ ] 마이그레이션 후 기존 카드 렌더링 검증
- [ ] 실기기에서 1.0.4 → 2.0.0 업그레이드 설치 시나리오 테스트
- [ ] 업그레이드 후 온보딩 → 로그인 경로와, 로그인 없이 레거시 조회로 빠지는 경로 모두 검증

---

## 7. 삭제 대상

Phase 2 완료 시 제거되는 코드:

- `MyRaum/Manager/ModelCaptureManager.swift` (전체)
- `MyRaum/Extension/UIView+Extension.swift` (`snapshot(of:)` — 누끼 전용)
- `RoomPlanView`의 `PhotosPicker.onChange` 내 `captureScreen()` / `createSticker()` 호출부
- `Vision`, `CoreImage.CIFilterBuiltins` import (해당 파일 한정)

`View+Extension.swift`의 `snapshot()`은 카드 이미지 공유 기능에서 계속 사용되므로 **유지**.

---

## 8. Claude Code 작업 규칙

1. **Phase 순서를 지킨다.** 앞 Phase가 빌드·동작 확인되기 전에 다음 Phase로 넘어가지 않는다.
2. **Phase 1은 동작 변경 금지.** 순수 구조 개선만 수행한다.
3. **파일 이동 시 `project.pbxproj`의 `fileSystemSynchronizedGroups` 갱신을 잊지 않는다.**
4. 신규 UI 문자열은 반드시 `Localizable.xcstrings`에 ko/en 쌍으로 추가한다.
5. 기존 코드의 한국어 주석 스타일(`//설명`)을 유지한다.
6. `@Observable` 매크로를 사용한다 (`ObservableObject` 신규 도입 금지 — 기존 코드와 일관성 유지).
7. 강제 언래핑(`!`)을 새로 도입하지 않는다.
8. Phase 단위로 커밋하고, 커밋 메시지에 Phase 번호를 포함한다.
9. §9의 확정 사항(D-01~D-06)을 전제로 작업하며, 이를 임의로 변경하지 않는다. 문서에 없는 새로운 설계 판단이 필요하면 사용자에게 확인을 요청한다.
10. iOS 18 최소 배포이므로 `if #available` 분기를 새로 추가하지 않는다. 기존 `ContentView`의 `if #available(iOS 18.0, *)` 분기도 Phase 4에서 정리한다.

---

## 9. 확정 사항 (Decisions)

아래 항목은 모두 확정되었다. Claude Code는 이 결정을 전제로 작업하며, 임의로 변경하지 않는다.

| # | 항목 | 결정 | 영향 |
|---|---|---|---|
| D-01 | **최소 배포 타겟** | **iOS 18.0으로 상향** | `RealityView` 직접 사용. SceneKit 대체 경로는 작성하지 않음 |
| D-02 | **인증 방식·시점** | **Sign in with Apple. 온보딩 직후 로그인이 앱 진입 조건** | Phase 6-A. 레거시 조회 전용 우회 경로 제공 |
| D-03 | **USDZ 저장 옵션** | **`.parametric` 단독** | `.mesh` 병행 저장하지 않음. 스키마에서 `meshFileName` 제외 |
| D-04 | **MultiRoom** | **도입** | Phase 2 스키마에 `structureID` 포함. Phase 8에서 병합 기능 구현 |
| D-05 | **기존 카드** | **3D 전환 없이 별도 조회 전용으로 영구 유지** | 레거시 카드는 읽기·이미지 저장·공유만 지원 |
| D-06 | **업로드·공개 정책** | **2.0에서 스캔한 공간은 전부 서버 저장. 레거시 카드는 로컬 전용. 토글은 업로드 여부가 아닌 "공개 여부"만 제어** | Phase 6 전면. 인증 시점이 앞당겨짐 |

### D-01 상세 — iOS 18.0 상향의 영향

- `RealityView` / `Model3D`를 조건부 분기 없이 사용 가능 → Phase 3 구현 단순화
- iOS 17에서 추가된 RoomPlan 기능(MultiRoom, Custom ARSession, VoiceOver)도 모두 무조건 사용 가능
- **트레이드오프**: iOS 17 사용자는 2.0으로 업데이트할 수 없다. 기존 사용자 이탈 가능성이 있으므로, App Store 릴리즈 노트와 업데이트 안내에 이를 명시할 것

### D-06 상세 — 전량 업로드 + 공개 토글

**업로드 정책 (무조건)**

- **2.0에서 새로 스캔한 공간은 예외 없이 전부 Supabase에 저장된다.** 업로드 여부는 사용자 선택 사항이 아니다.
- **레거시(이미지) 카드는 서버로 올리지 않는다.** 마이그레이션 대상이 아니며 해당 기기의 로컬에만 남는다.
- 저장 순서는 여전히 로컬 우선이다 — 로컬 저장 완료 후 `SyncQueue`가 백그라운드로 업로드하고, 실패 시 재시도한다. 오프라인에서도 스캔·저장·열람은 정상 동작해야 한다.
- 결과적으로 Supabase는 신규 데이터에 한해 **백업 겸 동기화 수단**이 된다. 기기를 변경해도 2.0 이후 스캔한 공간은 복원되지만, **레거시 카드는 복원되지 않는다.**

**공개 토글 (`isPublic`)**

- 토글은 업로드 여부가 아니라 **다른 사용자에게 공개할지 여부만** 제어한다.
- 기본값은 **비공개(false)**. 비공개 공간도 서버에는 저장되어 있으며 본인만 조회 가능하다.
- 토글을 꺼도 원격 데이터를 삭제하지 않는다. RLS의 select 정책만 달라진다.

**인증 시점 (D-02 보완)**

모든 신규 스캔이 업로드되므로 로그인을 뒤로 미룰 수 없다. **온보딩 직후 로그인**을 앱 진입 조건으로 둔다. 다만 레거시 데이터만 보려는 기존 사용자를 막지 않기 위해, 로그인 화면에서 **레거시 전용 모드**로 빠져나갈 수 있는 경로를 제공한다. 상세 플로우는 Phase 6-A 참조.

> ⚠️ **확인 필요**: "공개"된 공간을 다른 사용자가 **어디서 보는지**(둘러보기 피드, 공개 지도 등)는 이 PRD에 정의되어 있지 않다. 소비 화면이 없으면 공개 토글은 당장 사용자에게 의미가 없으므로, (a) 토글만 먼저 만들고 소비 화면은 이후 버전으로 미룰지 (b) Phase 7 지도에 "공개 공간 둘러보기"를 함께 넣을지 결정이 필요하다.

---

## 10. 참고

- RoomPlan `CapturedRoom` 구조: Surfaces(wall/opening/window/door) + Objects(sofa, bed, table, chair, storage, refrigerator, stove, sink, washerDryer, toilet, bathtub, oven, dishwasher, fireplace, television, stairs). 각 요소는 dimensions, transform, confidence(3단계), identifier를 보유.
- MultiRoom(`CapturedStructure`), Custom ARSession, RoomCaptureView VoiceOver 지원은 iOS 17에서 추가됨.
- `RealityView`는 iOS 18부터 iPhone/iPad에서 사용 가능 (그 이전에는 visionOS 전용). 최소 배포 타겟 18.0 확정으로 조건부 분기 없이 사용한다.
